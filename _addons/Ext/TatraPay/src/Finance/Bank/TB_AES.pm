##############################################################################
#                                                                            #
#  Copyright (c) 2000,2001 Jan 'Kozo' Vajda <Jan.Vajda@alert.sk>             #
#  All rights reserved.                                                      #
#                                                                            #
##############################################################################

package Finance::Bank::TB_AES;
require Exporter;

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;
use Digest::SHA1;
use Crypt::DES 2.03;
use Crypt::AES::CTR;
use Crypt::Rijndael;
use Crypt::ECB;

### my initial version was 0.11
$VERSION = '0.24';

@ISA = qw(Exporter);

# Items to export into callers namespace by default
@EXPORT =	qw();

# Other items we are prepared to export if requested
@EXPORT_OK =	qw();


=head1 NAME

Finance::Bank::TB - Perl extension for B<TatraPay> and B<CardPay> of
Tatrabanka and B<EliotPay> of .eliot.

=head1 VERSION

  0.24

=head1 SYNOPSIS

  use Finance::Bank::TB;

  $tb_obj = Finance::Bank::TB->new($mid,$key);

  $tb_obj->configure(
	      cs	=> $cs,
	      vs	=> $vs,
	      amt	=> $amt,
	      rurl	=> $rurl,
	      name	=> $uname,
	      ipc	=> $ip_of_client,
	      image_src => '/PICS/tatrapay_logo.gif',
  );

  my $send_sign = $tb_obj->get_send_sign();
  my $recv_sign = $tb_obj->get_recv_sign();
  my $new_cs = $tb_obj->cs($cs);
 
or

  use Finance::Bank::TB;

  $tb_obj = Finance::Bank::TB->new($mid,$key);

  $tb_obj->configure(
	      cs	=> $cs,
	      vs	=> $vs,
	      amt	=> $amt,
	      rurl	=> $rurl,
	      desc	=> $description,
	      rsms	=> $mobilephonenumber,
	      rem	=> $remote_mail,
	      name	=> $uname,
	      ipc	=> $ip_of_client,
	      image_src => '/PICS/tatrapay_logo.gif',
  );

  print $tb_obj->pay_form("TatraPay");

=head1 DESCRIPTION

Module for generating signatures and pay forms for B<TatraPay> and
B<CardPay> of Tatra Banka ( http://www.tatrabanka.sk/ ) and for B<EliotPay> of
.eliot.  ( http://www.eliot.sk/ )

The current version of Finance::Bank::TB is available at

  http://rodney.alert.sk/perl/


=head1 USE

=head2 Functions ( or Methods ? )

=item new

  $tb_obj  = Finance::Bank::TB->new($mid,$key);

This creates a new Finance::Bank::TB object using $mid as a MID ( MerchantID ) and
$key as a DES PassPhrase.

=cut


sub new {
	my $type = shift;
	my $class = ref($type) || $type;
	croak "Usage $class->new (MID, KEY)" if ( @_ != 2 ) ;
	my $self = {};
	bless $self, $class;

	$self->{'mid'} = shift;
	$self->{'tbkey'} = shift;
	$self->{'aredir'} = 0;

#	croak "KEY must be 8 chars" if ( length($self->tbkey) != 8 );
	
	$self->_init;

	return($self);
}

sub _init {
  my $self = shift;

  ### default values
  $self->{'action_url'} = "https://moja.tatrabanka.sk/cgi-bin/e-commerce/start/e-commerce.jsp";
  $self->{'image_src'} = '/PICS/tatrapay_logo.gif';

  return($self);
}


=item configure

	$tb_obj->configure(
		cs        => $cs,
		vs        => $vs,
		amt       => $amt,
		rurl      => $rurl,
		image_src => '/PICS/tatrapay_logo.gif',
	);

 
Set correct values to object.
Possible parameters is:
        cs => Constant Symbol
        vs => Variable Symbol
       amt => Amount
      rurl => Redirect URL
 image_src => Path to image ( relative to DocumentRoot )
      desc => Description
      rsms => Mobile Number for SMS notification
       rem => E-mail address for email notification
       ipc => IP address of Client
      name => Name of client
       res => Result Code of transaction
        ac => Approval Code
           
Possible but default correct parameters is:
 
  action_url => default action URL
  default:
    https://moja.tatrabanka.sk/cgi-bin/e-commerce/start/e-commerce.jsp

  image_src => Path to image ( relative to DocumentRoot )
  default:
    /PICS/tatrapay_logo.gif


=cut

sub configure {
	my $self = shift;
	my (%arg) = @_;

	### normalization
	foreach (keys %arg) {
		### konvert name to lowercase
		$self->{"\L$_"} = $arg{$_};
	}
	return($self);
}

=item calculate_signatures

  $tb_obj->calculate_signatures();
  print $tb_obj->send_sign;
  print $tb_obj->recv_sign;

Calculate Send and Receive Signature from parameters of  object and
set send_sign and recv_sign.

=cut

sub calculate_signatures {
  my $self =shift;
  
  $self->get_send_sign();
  $self->get_recv_sign();
  
}

=item get_send_sign

  print $tb_obj->get_send_sign();
  
Calculate and return send signature.  Set $tb_obj->send_sign.

=cut


sub get_send_sign
{
	my $self =shift;
	
	my $key = $self->tbkey;
	main::_log("key='$key'");
	main::_log("joining mid:".$self->mid." amt:".$self->amt." vs:".$self->vs." curr:".$self->curr." cs:".$self->cs." rurl:".$self->rurl." ipc:".$self->ipc." name:".$self->name,3,"debug");
	
  # make string from incoming values
  my $initstr = join('',$self->mid,
			$self->amt,
			$self->curr,
			$self->vs,
#			$self->cs,
			$self->rurl,
			$self->ipc,
			$self->name
		);
	
	main::_log("initstr='$initstr'",3,"debug");
	return($self->send_sign(_make_sign($key,$initstr)));
}

=item get_recv_sign

  print $tb_obj->get_send_sign();
  
Calculate and return receive signature. Set $tb_obj->recv_sign.

=cut

sub get_recv_sign {

  my $self =shift;

  my $key = $self->tbkey;

  # make string from incoming values
  my $initstr = join('',$self->vs,
			$self->res,
			$self->ac
		);

  return($self->recv_sign(_make_sign($key,$initstr)));
}

=item pay_form

  print $tb_obj->pay_form($type,$generic);

Type is "TatraPay", "EliotPay", "CardPay" or null. Default is null (user
must select type by hand). If defined $generic form will be with input
type=submit instead input type=image ( and image_src will be ignored )
  
Return HTML FORM.

=cut

sub pay_form {
  my $self =shift;
  ### Pay Type
  my $type = shift;
  ### Submit type
  my $generic = shift;
  
  my $action;
  my $submit;
  my $pt = "";
  
  if ( defined $generic ) {
    $submit = qq|<input type=submit value="Suhlasim">|;
  } else {
    $submit = qq|<input type=image src="$self->{image_src}" border=0>|;
  }

  ### detection of Pay Type
  ### default null ( user select )
  
  if ( $type =~ /eliot/i ) {
    $pt = "EliotPay";
  } elsif ( $type =~ /card/i ){
    $pt = "CardPay";
  } elsif ($type =~ /tatra/i ) {
    $pt = "TatraPay";
  }

  $action = $self->{action_url};

  my $sign = $self->get_send_sign();

my $tb_form = <<EOM;
<!-- TatraPay & EliotPay & CardPay form start -->
<form action="$action" method=POST>
<input type=hidden name=PT value="$pt">
<input type=hidden name=MID value="$self->{mid}">
<input type=hidden name=AMT value="$self->{amt}">
<input type=hidden name=VS value="$self->{vs}">
<input type=hidden name=CURR value="$self->{curr}">
<input type=hidden name=RURL value="$self->{rurl}">
<input type=hidden name=DESC value="$self->{desc}">
<input type=hidden name=REM value="$self->{rem}">
<input type=hidden name=IPC value="$self->{ipc}">
<input type=hidden name=AREDIR value="$self->{aredir}">
<input type=hidden name=NAME value="$self->{name}">
<input type=hidden name=SIGN value="$sign">
$submit
</form>
<!-- TatraPay & EliotPay & CardPay form  end -->
EOM
#<input type=hidden name=CS value="$self->{cs}">
#<input type=hidden name=RSMS value="$self->{rsms}">
  return($tb_form);
}

=item pay_link

  print $tb_obj->pay_link($type);

Type is "TatraPay", "EliotPay", "CardPay" or null. Default is null.
  
Return URL for payment.

=cut

sub pay_link {
  my $self =shift;
  my $type = shift;
  my $action;
  my $pt = "";

  ### detection of Pay Type
  ### default null ( user select )
  
  if ( $type =~ /eliot/i ) {
    $pt = "EliotPay";
  } elsif ( $type =~ /card/i ){
    $pt = "CardPay";
  } elsif ($type =~ /tatra/i ) {
    $pt = "TatraPay";
  }

  $action = $self->{action_url};

  my $sign = $self->get_send_sign();
	
	use URI::Escape;
	my $rurl=uri_escape($self->{'rurl'});
	
	
my $tb_form = <<EOM;
$action ?
PT=$pt &
MID=$self->{mid} & 
AMT=$self->{amt} & 
VS=$self->{vs} &
CURR=$self->{curr} & 
CS=$self->{cs} & 
RURL=$rurl & 
DESC=$self->{desc} & 
RSMS=$self->{rsms} & 
REM=$self->{rem} & 
IPC=$self->{ipc} & 
NAME=$self->{name} & 
AREDIR=$self->{aredir} & 
SIGN=$sign 
EOM

$tb_form =~ s/\n//og;
$tb_form =~ s/\s+//og;

  return($tb_form);
}

sub _make_sign {
  my $key = shift;
  my $initstr = shift;
	
#	main::_log("inistr='$initstr' key='$key'");
	
	### make SHA hash
	my $context = new Digest::SHA1;
	$context->add($initstr);
	
	my $tb_hash_bytes = $context->digest;
	$tb_hash_bytes = substr($tb_hash_bytes,0,16);
	
#	main::_log("hash='".unpack("H*",$tb_hash_bytes)."'");
	
	my $key_bytes=pack("H*",$key);
	
	my $crypt = Crypt::Rijndael->new( $key_bytes, Crypt::Rijndael::MODE_ECB() );
	my $tb_des = $crypt->encrypt($tb_hash_bytes);
	
	main::_log("sign='".uc(unpack("H*",$tb_des))."'");
	
#	return("\U$tb_des");
	
	return uc(unpack("H*",$tb_des));
	
  ### first 16 bytes
#  my $tb_hash_part = substr($tb_hash,0,8);
#	main::_log("tb_hash_part=".unpack("H*", $tb_hash));
  ### crypting by DES
#  my $cipher = Crypt::DES->new($key);
#  my $tb_des = $cipher->encrypt($tb_hash_part);
	
	#my $cipher = unpack("H16", $tb_hash_part);
#	utf8::encode($tb_hash_part);
#	utf8::encode($key);
#	main::_log("sign '$tb_hash_part' '$key'='".length($key)."'");
	
#	my $sign_key=pack("H*",$key);
#	print $sign_key;
#	utf8::encode($sign_key);
#	main::_log("sign_key length='".length($sign_key)."'");

#	my $crypt = Crypt::Rijndael->new( $sign_key, Crypt::Rijndael::MODE_ECB() );
#	my $tb_des = $crypt->encrypt($tb_hash_part);
#	my $tb_des = Crypt::AES::CTR::encrypt($tb_hash_part, $sign_key,256);
	
  ### to hex
 # my $tb_hash_hex = unpack("H16", $tb_des);

  ### convert to upper case and return
 # main::_log("$tb_hash_hex");
 # return("\U$tb_hash_hex");
}

sub AUTOLOAD {
  my $self = shift;
  my $value = shift;
  my ($name) = $AUTOLOAD;

  ($name) = ( $name =~ /^.*::(.*)/);

  $self->{$name} = $value if ( defined $value );

  return($self->{$name});
 
}

sub DESTROY {
  ### bye bye 
}

1;

__END__

=head1 EXAMPLES

Look at B<SYNOPSIS>, B<t/*>, B<examples/*> and use the source.
(lookin for a volunteer for writing documentation and man pages)

=head1 AUTHOR INFORMATION

Copyright 2000 Jan ' Kozo ' Vajda, Jan.Vajda@alert.sk. All rights reserved.
This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself, but I do request that this copyright
notice remain attached to the file. You may modify this module as you wish,
but if you redistribute a modified version, please attach a note listing the
modifications you have made.

Address bug reports and comments to:
Jan.Vajda@alert.sk

=head1 CREDITS

Thanks very much to:

=over 4

=item my wife Erika & kozliatko

for patience and love

=item Gildir ( gildir@alert.sk ) 

for debugging

=item M. Sulik from TatraBanka

for documentation, C examples and mail helpdesk.

=back

=head1 SEE ALSO

  perl(1),Digest::SHA1(1),Crypt::DES(1).

=cut

