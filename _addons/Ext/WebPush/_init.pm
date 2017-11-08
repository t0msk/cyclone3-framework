#!/bin/perl
package Ext::WebPush;
use open ':utf8', ':std';
use if $] < 5.018, 'encoding','utf8';
use utf8;
use strict;

use Data::Dumper;
use LWP;

use Crypt::JWT qw(encode_jwt);
use Crypt::KeyDerivation qw(hkdf);
use Crypt::PK::ECC;
use MIME::Base64 qw(encode_base64 decode_base64url encode_base64url decode_base64);
use Bytes::Random::Secure qw(random_bytes);

use Crypt::AuthEnc::GCM qw(gcm_encrypt_authenticate gcm_decrypt_verify);

sub new {
	my $type = shift;
	my $env = shift;
	my $class = ref($type) || $type;
	my $self = {};
	bless $self, $class;

	if (!$env->{'server_public_key'}) {
		main::_log('error: missing public key');
		return 0;
	} elsif (!$env->{'server_private_key'}) {
		main::_log('error: missing server private key');
		return 0;
	}

	$self->{_server_public_key} = $env->{'server_public_key'};

	$self->{_server_private_key_string} = \do{$env->{'server_private_key'}};
	
	return($self);
}

sub send_notification {
	my $self = shift;
	my $env = shift;

	if (!$env->{'endpoint'}) {
		main::_log('error: missing endpoint');
		return 0;
	} elsif (!$env->{'vapid_subject'}) {
		main::_log('error: missing vapid_subject');
		return 0;
	}
	main::_log("going to send push notification to endpoint='$env->{'endpoint'}'");
	# main::_log('jwe token from notification='.$self->{'_jwe_token'});

	my $req = HTTP::Request->new('POST', $env->{'endpoint'});

	my $exp_timestamp = time + 12 * 60 * 60;

	# audience is source domain of endpoint - remove protocol and path
	(my $jwt_aud = $env->{'endpoint'}) =~ s/(https:\/\/[^\/]+)(\/.+)/$1/;
	#main::_log("jwt_aud='$jwt_aud'");
	my $data = {
		"aud" => $jwt_aud,
		"exp" => $exp_timestamp,
		"sub" => $env->{'vapid_subject'}
	};
	$self->{_jwe_token} = encode_jwt(payload=>$data, alg=>'ES256', key=>$self->{_server_private_key_string}, extra_headers=>{typ=>'JWT'});
	#main::_log("payload='$env->{'payload'}'; client_public_key='$env->{'client_public_key'}'; client_auth='$env->{'client_auth'}'");
	if ($env->{'payload'} && $env->{'client_public_key'} && $env->{'client_auth'}) {
		#main::_log("going to send payload='$env->{'payload'}'");
		# explicitly encode utf-8 as browser might send string in different encoding
		# $env->{'payload'} =~ s/^\s+|\s+$//g;
		$env->{'payload'} = Encode::encode_utf8($env->{'payload'});
		#main::_log("payload trimmed no padding='$env->{'payload'}'");
		# PAYLOAD encryption
		#my $client_public_key_b64 = '';
		my $client_public_key_b64 = $env->{'client_public_key'};
		my $client_public_key_raw = decode_base64url($client_public_key_b64);

		#my $auth = "Z_QscOCe8ZfjpXemy7mZwA==";
		my $auth = $env->{'client_auth'};
		my $client_secret = decode_base64url($auth);
		my $server_keys = Crypt::PK::ECC->new();
		$server_keys->generate_key('prime256v1');
		my $server_public_key_raw = $server_keys->export_key_raw('public');
		my $server_private_key_raw = $server_keys->export_key_raw('private');

		# uncomment lines below for testing purposes - use stable base64 encoded server keys to compare results
		# my $server_public_key_b64 = '';
		# $server_public_key_raw = decode_base64url($server_public_key_b64);
		# $server_keys->import_key_raw($server_public_key_raw,'prime256v1');
		# my $server_private_key_b64 = '';
		# $server_private_key_raw = decode_base64url($server_private_key_b64);
		# $server_keys->import_key_raw($server_private_key_raw,'prime256v1');

		#main::_log('server public key b64='.encode_base64url($server_public_key_raw));
		# main::_log('server private key b64='.encode_base64url($server_private_key_raw));

		my $client_public_key = Crypt::PK::ECC->new();
		$client_public_key->import_key_raw($client_public_key_raw,'prime256v1');

		my $shared_secret = $server_keys->shared_secret($client_public_key);
		#main::_log("shared_secret_b64(IKM)=".encode_base64url($shared_secret));
		
		my $salt = random_bytes(16);
		#main::_log("salt_b64=".encode_base64url($salt));
		my $auth_info = "Content-Encoding: auth\000";
		#main::_log("auth_info=".$auth_info);
		#main::_log("shared_secret=".$shared_secret);
		#main::_log("client_secret=".$client_secret);
		# pseudo-random key
		# main::_log("shared_secret='$shared_secret';client_secret=$client_secret;auth_info=$auth_info");
		my $prk = hkdf($shared_secret, $client_secret , 'SHA256', 32, $auth_info);
		# main::_log("prk_b64=".encode_base64url($prk));

		my $content_encryption_key_info = _create_info('aesgcm', $client_public_key_raw, $server_public_key_raw);
		#main::_log("CEK info b64=".encode_base64url($content_encryption_key_info));
		my $content_encryption_key = hkdf($prk, $salt, 'SHA256', 16, $content_encryption_key_info);
		#main::_log("CEK b64=".encode_base64url($content_encryption_key));

		my $nonce_info = _create_info('nonce', $client_public_key_raw, $server_public_key_raw);
		#main::_log("nonce info b64=".encode_base64url($nonce_info));
		my $nonce = hkdf($prk, $salt, 'sha256', 12, $nonce_info);
		#main::_log("nonce b64=".encode_base64url($nonce));
		
		# main::_log("content_encryption_key=$content_encryption_key");
		# main::_log("content_encryption_key length=".bytes::length($content_encryption_key));

		my $padded_payload = _pad_message($env->{'payload'});

		my ($ciphertext, $tag) = gcm_encrypt_authenticate('AES', $content_encryption_key, $nonce, '', $padded_payload);

		#main::_log("plaintext=".$plaintext);
		#main::_log("ciphertext=".$ciphertext);
		#main::_log("tag=".$tag);
		# main::_log("ciphertext_b64=".encode_base64url($ciphertext.$tag));
		# main::_log("tag_b64=".encode_base64url($tag));
		my $payload = $ciphertext.$tag;
		# main::_log("content length=".bytes::length($payload));

		#main::_log("cipher result b64=".encode_base64url($result));
		# request with payload
		$req->header(
			'TTL' => '60',
			'Authorization' => "WebPush $self->{'_jwe_token'}",
			'Crypto-Key' => "dh=".encode_base64url($server_public_key_raw)."; p256ecdsa=$self->{_server_public_key}",
			'Encryption' => "salt=".encode_base64url($salt),
			'Content-Length' => bytes::length($payload),
			'Content-Type' => 'application/octet-stream',
			'Content-Encoding' => 'aesgcm'
		);
		$req->content($payload);
	} else {
		# simple request without payload
		$req->header(
			'TTL' => '60',
			'Authorization' => "WebPush $self->{'_jwe_token'}",
			'Crypto-Key' => "p256ecdsa=$self->{_server_public_key}",
			'Content-Length' => 0,
		);
	}

	my $browser = LWP::UserAgent->new;
	my $response = $browser->request($req);
	my $response_code = $response->code();
	main::_log("response code=".$response_code);
	if ($response_code ne '201') {
		main::_log("response code other than 201 created, logging whole response=".$response->decoded_content,3);
		return 0;
	}
	#main::_log("response dump".Dumper(keys %{$response}));
	main::_log("response content=".$response->status_line);
	die 'Error getting url' unless $response->is_success;
	
	return 1
}

sub _create_info {
	
	my $type = shift;
	my $client_public_key = shift;
	my $server_public_key = shift;

	my $len = bytes::length($type);
	#main::_log("bytes length of string=$len");

	my $client_public_key_len = pack('n',bytes::length($client_public_key));
	#main::_log("bytes length of client key=$client_public_key_len");
	my $server_public_key_len = pack('n',bytes::length($server_public_key));
	#main::_log("bytes length of server key=$server_public_key_len");

	my $info = "Content-Encoding: $type\000P-256\000$client_public_key_len$client_public_key$server_public_key_len$server_public_key";
	#main::_log("info=$info");

	return $info;
}

sub _pad_message {
	use bytes;
	
	my($msg) = @_;
	my $maxlen = 3052; # compatibility safe payload length
	my $l = bytes::length($msg);
	my $padlen = $maxlen - $l;

	# append 1 bit followed by $k zero bits
	$msg = ("\0" x ($padlen)) . $msg;

	#main::_log("padded payload=$msg");
	return $msg;
}


1;

