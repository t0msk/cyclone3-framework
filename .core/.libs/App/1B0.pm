#!/bin/perl
package App::1B0;
use open ':utf8', ':std';
use encoding 'utf8';
use utf8;
use strict;

=head1 NAME

App::1B0

=head1 DESCRIPTION

Banning užívateľov

=cut

BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}

=head1 SYNOPSIS

 my ($ID,$msg)=App::1B0::IsBanned(
   IP => "192.168.0.1",
   a300 => "NyJsqrmgh",
   -type => "app",
   -what => "820",
 );
 if ($ID)
 {
  print "$msg\n";
 }

=cut

sub IsBanned
{
	my $t=track TOM::Debug(__PACKAGE__."::IsBanned()");
	my %env=@_;
	
	my $sel=qq{
		SELECT
			ban.ID,
			msg.about
		FROM TOM.a1B0_banned AS ban
		LEFT JOIN TOM.a1B0_message AS msg ON
		(
			ban.IDmessage = msg.ID
		)
		WHERE
			(ban.domain IS NULL OR ban.domain='$tom::Hm')
			AND (ban.domain_sub IS NULL OR ban.domain_sub='$tom::H')
			AND ban.time_start<=$main::time_current
			AND (ban.time_end IS NULL OR ban.time_end>=$main::time_current)
			AND ban.active='Y'
			<%WHO%>
			AND ban.Atype='$env{-type}'
			AND ban.Awhat='$env{-what}'
			AND ban.Awhat_action='$env{-what_action}'
	LIMIT 1};
	
	foreach (keys %env)
	{
		next if $_=~/^-/;
		my $sel0=$sel;
		$sel0=~s|<%WHO%>|AND ban.Btype='$_' AND ban.Bwho='$env{$_}'|;
		my $db0=$main::DB{'sys'}->Query($sel0);
		if (my %db0_line=$db0->fetchhash())
		{
			$main::DB{'sys'}->Query("UPDATE TOM.a1B0_banned SET banned=banned+1 WHERE ID=$db0_line{ID} LIMIT 1");
			main::_log("is banned");
			$t->close();
			return $db0_line{ID},$db0_line{about};
		}
	}
	
	$t->close();
	return undef;
}



1;