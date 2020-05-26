#!/bin/perl
package App::301::karma;
use open ':utf8', ':std';
use if $] < 5.018, 'encoding','utf8';
use utf8;
use strict;



=head1 NAME

App::301::karma

=head1 DESCRIPTION

Calculate karma for everyone user

=cut

BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}



=head1 DEPENDS

=over

=item *

L<App::301::_init|app/"301/_init.pm">

=item *

L<App::301::karma::dictionary|app/"301/karma/dictionary.pm">

=back

=cut

use App::301::_init;
use App::301::karma::dictionary;



sub increase
{
   my %env=@_;
   
   $env{'ID_user'}=$main::USRM{'ID_user'} unless $env{'ID_user'};
   return undef unless $env{'ID_user'};
   return undef unless $env{'karma'};
   
   $env{'date'}='CURDATE()';
   
   my $sql=qq{
      SELECT
         *
      FROM
         `$App::301::db_name`.a301_user_profile_karma
      WHERE
         ID_user='$env{'ID_user'}' AND
         date_event=$env{'date'}
      LIMIT 1;
   };
   my %sth0=TOM::Database::SQL::execute($sql,'quiet_'=>1,'-slave'=>1);
   my %db0_line=$sth0{'sth'}->fetchhash();
   
   my $karma=$db0_line{'karma'}+$env{'karma'};
   
   my $sql=qq{
      REPLACE INTO
      `$App::301::db_name`.a301_user_profile_karma
      (
         ID_user,
         date_event,
         karma
      )
      VALUES
      (
         '$env{'ID_user'}',
         $env{'date'},
         $karma
      )
   };
   TOM::Database::SQL::execute($sql);
   
}




=head1 AUTHORS

Comsultia, Ltd. (open@comsultia.com)

=cut


1;
