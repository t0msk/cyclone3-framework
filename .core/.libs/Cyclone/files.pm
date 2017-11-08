package Cyclone::files;
use open ':utf8', ':std';
use if $] < 5.018, 'encoding','utf8';
use utf8;
use strict;

=head1 NAME

Cyclone::files

=head1 DESCRIPTION

Správa súborov a adresárových štruktúr frameworku Cyclone

=cut

BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}


=head1 SYSTEM PRAV

Pre prava su pouzivani dvaja zakladni uzivatelia a dve zakladne skupiny. Uzivatel cyclone3, apache a groupy cyclone3 a www.

 cyclone3 = cyclone3;apache;{developers}
 www = apache

=cut



=head1 DEPENDS

knižnice:

 Fcntl

=cut

use Cyclone;
use Fcntl;
#use File::chmod;



=head1 VARIABLES

=head2 $user, $user_www, $group, $mediasrv_user, $mediasrv_group

Nastavenie uzivatela a skupiny Cyclone3, apache usera a taktiez prav adresarov pre mediaserver.

$user - uzivatel Cyclone3, defaultne "cyclone3", da sa prepisat v TOM.conf ako $TOM::user

$group - skupina uzivatelov Cyclone3, defaultne "cyclone3", da sa prepisat v TOM.conf ako $TOM::group. Pokial v danej instalacii pracuje viac uzivatelov (nielen uzivatel apache a cyclone3), potom je vhodne aby vsetci tito uzivatelia (okrem apache) mali default groupu rovnaku, inak dochadza ku konfliktom pri vytvarani suborov, na ktore ostatni ludia nemaju prava, prace so subversion, etc...

$user_www - uzivatel httpd servera pod ktorym je spustany, defaultne "apache", da sa prepisat v TOM.conf ako $TOM::user_www

$mediasrv_user, $mediasrv_group - Cyclone3 ma podporu pre pouzitie pracu s mediami na inom serveri. Toto je v hodne hlavne v pripade ak nechceme zatazovat aplikacny server servovanim statickych suborov. V takom pripade sa vytvori adresar /www/TOM/!media ktory je NFS adresarom na media server. Potom kazdy !media adresar v domene (eg. !example.tld/!media) je symlinkom dovnutra /www/TOM/!media/... V takomto pripade samozrejme kvoli NFS treba uplatnovat zvlastne prava na tieto adresare.

=cut

our $user      = $TOM::user       || "cyclone3";
our $user_www  = $TOM::user_www   || "apache";
our $group     = $TOM::group      || "cyclone3";

our $mediasrv_user  = $TOM::mediasrv_user  || $user_www;
our $mediasrv_group = $TOM::mediasrv_group || $group;

=head2 @setid_d

Zoznam regulárnych výrazov pre detekciu typu adresára + nastavenie práv

 ['regexp' ,"directory type name" ,"mod" ,"user:group"]

=cut

our @setit_D=
(
	['media.*\.svn'                     ,"media .svn directory"       ,"770","$mediasrv_user:$mediasrv_group"],
	['\.svn'                            ,".svn directory"             ,"570","$user_www:$group"],
	
	# exclude dirs
	['phprojekt'                       ,"phprojekt"                   ,"",""],
	['phpmyadmin'                      ,"phpmyadmin"                  ,"",""],
	['^\.admin'                        ,"global admin"                ,"",""],
	
	# global
	['^_addons'                        ,"global _addons"              ,"570","$user_www:$group"],
	['^_overlays'                      ,"global _overlays"            ,"570","$user_www:$group"],
	['^_data'                          ,"global _data"                ,"770","$user_www:$group"],
	['^_temp'                          ,"global _temp"                ,"770","$user_www:$group"],
	['^.symlinks$'                     ,"global .symlinks"            ,"570","$user_www:$group"],
	['^_config'                        ,"global _config"              ,"770","$user_www:$group"],
	['^\.core'                         ,"global .core"                ,"570","$user_www:$group"],
	['^_dsgn$'                         ,"global _dsgn"                ,"570","$user_www:$group"],
	['^_dsgn\/'                        ,"global _dsgn"                ,"570","$user_www:$group"],
	['^_type$'                         ,"global _type"                ,"570","$user_www:$group"],
	['^\.bin$'                         ,"global .bin"                 ,"770","$user:$group"],
	['^_logs'                          ,"global _logs"                ,"777","$user_www:$group"],
	['^!media'                         ,"global !media"               ,"775","$mediasrv_user:$mediasrv_group"],
	
	# local
	['\/_temp'                         ,"local _temp"                 ,"770","$user_www:$group"],
	['\/_addons'                       ,"local _addons"               ,"570","$user_www:$group"],
	['\/_mdl$'                         ,"local _mdl"                  ,"570","$user_www:$group"],
	['\/\.libs'                        ,"local libraries"             ,"570","$user_www:$group"],
	['\/_dsgn$'                        ,"local _dsgn"                 ,"770","$user_www:$group"],
	['\/_dsgn\/'                       ,"local _dsgn"                 ,"770","$user_www:$group"],
	['\/!www$'                         ,"local !www"                  ,"770","$user_www:$group"],
	['\/_type$'                        ,"local _type"                 ,"770","$user_www:$group"],
	['\/_data'                         ,"local _data"                 ,"770","$user_www:$group"],
	['\/_logs'                         ,"local _logs"                 ,"777","$user_www:$group"],
	['\/!?media'                        ,"local !media"                ,"770","$user_www:$group"],
	
	['![\w\.\-]+$'                     ,"domain"                      ,"770","$user_www:$group"],
	['\/!www'                          ,"document roots"              ,"770","$user_www:$group"],
	['![\w\.\-]+/[\w]+$'               ,"subdomain"                   ,"770","$user_www:$group"],
	
	['\.git'                           ,".git"                        ,"770","$user:$group"],
	
	['^\.'                             ,"unknown"                     ,"","$user:$group"],
);


=head2 @setid_F

Zoznam regulárnych výrazov pre detekciu typu suboru + nastavenie práv

 ['regexp' ,"directory type name" ,"mod" ,"user:group"]

=cut

our @setit_F=
(
	['\.svn'                           ,".svn files"                  ,"444",""],
	
	['fdetect'                         ,".svn files"                  ,"777",""],
	
	['^_temp/_Inline'                  ,"global Inline"               ,"777","$user_www:$group"],
	['_temp/.*?\.ttc2$'                ,"global _temp"                ,"666","$mediasrv_user:$group"],
	['^_temp'                          ,"global _temp"                ,"",""],
	
	['\/type.*?conf$'                  ,"service type.conf"           ,"660","$user_www:$group"],
	['\.(pwd)$'                        ,".pwd (password file)"        ,"660","$user_www:$group"],
	['\.tmpl$'                         ,".tmpl (template)"            ,"660","$user:$group"],
	['\.sql$'                          ,".sql (SQL file)"             ,"660","$user:$group"],
	
	# www:$mediasrv_group ak media su cez NFS na inom serveri
	['^!media\/'                       ,"!media"                      ,"664","$mediasrv_user:$mediasrv_group"],
	# $user_www:cyclone3 ak media su normalne lokalne
	['/!?media\/.*\.sh'                  ,"!media domain builder"     ,"755","$user_www:$group"],
	['/!?media\/'                        ,"!media domain"             ,"664","$user_www:$group"],
	['\.htaccess$'                     ,".htaccess"                   ,"460","$user_www:$group"],
	
	['_logs\/.*\.log$'                 ,"_logs cron .log"             ,"",""],
	['_logs\/httpd\/'                  ,"_logs httpd"                 ,"",""],
	['_logs\/'                         ,"_logs cron .log"             ,"",""],
	
	
	['\.pm'                            ,"perl library"                ,"660","$user_www:$group"],
	['\.job$'                          ,"job"                         ,"770","$user:$group"],
	['_addons'                         ,"addons file"                 ,"460","$user_www:$group"],
	
	
	['\.libs\/.*\.txt'                 ,"library inputs"       ,"660","$user_www:$group"],
	
	
	['\.bin\/'                         ,"core binary"                 ,"770","$user:$group"],
	
	
	['^_config\/'                      ,"_config"                     ,"660","$user_www:$group"],
	['^\.core\/_config\/'              ,".core config"                ,"460","$user_www:$group"],
	
	
	['^\.core\/.*pid$'                 ,".core .pid"                  ,"",""],
	
	['(^\.core\/(tom|cron|cyc|webclick|download|export|a540|test)|^core)'
	                                   ,".core engines","770","$user:$group"],
	
	['\.core\/.*\.so$'                 ,".core so"                    ,"660","$user_www:$group"],
	
	['\.(RFC|docbook|md)$'             ,"documentation files"         ,"660","$user_www:$group"],
	['\/master\.conf$'                 ,"master conf"                 ,"660","$user_www:$group"],
	['\/local\.conf$'                  ,"local conf"                  ,"660","$user_www:$group"],
	['\/rewrite.*?conf$'               ,"rewrite conf"                ,"660","$user_www:$group"],
	['\/301\.conf$'                    ,"301 conf"                    ,"660","$user_www:$group"],
	['\/job\.conf$'                    ,"job conf"                    ,"660","$user:$group"],
 
	['\/cron\..*?\.cml$'               ,"local cron cml"              ,"460","$user_www:$group"],
	
	
	['!www.*(tom|pl|fcgi|php|asp)$'    ,"!www executables"            ,"560","$user_www:$group"],
	['!www.*(css|html|wml|js|xml|txt|ppt|pdf|xls|xsl|doc|cvml)$'
	                                   ,"!www docs"                   ,"660","$user_www:$group"],
	['!www.*php\?'
	                                   ,"!www docs mirrored"          ,"660","$user_www:$group"],
	['\/!www\/.*(jpg|png|gif|wbmp|swf|svg|ico)$'
	                                   ,"!www graphix"                ,"660","$user_www:$group"],
	['\/!www\/.*(asf|avi)$'            ,"!www video"                  ,"660","$user_www:$group"],
	['\/!www\/.*(gz|bz2|tar|zip)$'     ,"!www archive"                ,"660","$user_www:$group"],
	['\/!www\/.*$'                     ,"!www unknown"                ,"660","$user_www:$group"],
	
	['_dsgn\/.*\.dsgn$'                ,"_dsgn dsgn"                  ,"660","$user_www:$group"],
	['_dsgn\/.*\.template$'            ,"_dsgn template"              ,"660","$user_www:$group"],
	['_dsgn\/.*\.body$'                ,"_dsgn body"                  ,"660","$user_www:$group"],
	['_dsgn\/.*\.header$'              ,"_dsgn header"                ,"660","$user_www:$group"],
	['_dsgn\/.*\.tpl$'                 ,"tpl file"                    ,"660","$user_www:$group"],
	['_dsgn\/.*\.tpl\.d\/'             ,"tpl.d file"                  ,"660","$user_www:$group"],
	
	['_dsgn\/.*\.L10n$'                ,"L10n"                        ,"660","$user_www:$group"],
	
	['_dsgn\/.*scss$'                  ,"SCSS"                        ,"660","$user_www:$group"],
	
	['_type\/.*\.type$'                ,"_type type"                  ,"660","$user_www:$group"],
	['_type\/.*\.cml_type$'            ,"_type cml_type"              ,"660","$user_www:$group"],
	['_type\/.*\.(cml_gen|inc)$'       ,"_type inc"                   ,"660","$user_www:$group"],
	
	['_mdl\/.*\.xlng$'                 ,"xlng"                        ,"660","$user_www:$group"],
	['_mdl.*\.xsgn$'                   ,"xsgn"                        ,"660","$user_www:$group"],
	['_mdl.*\.tpl$'                    ,"tpl"                         ,"660","$user_www:$group"],
	['_mdl\/.*mdl$'                    ,"?mdl"                        ,"660","$user_www:$group"],
	
	['_mdl\/.*cron$'                   ,"_mdl cron"                   ,"660","$user_www:$group"],
 
	['_data\/USRM\/.*'                 ,"local _data USRM"            ,"",""],
	['_data\/.*'                       ,"local _data"                 ,"660","$user_www:$group"],
	
	# old admin
	['!admin/.*\.mdl$'                 ,"local !admin *.mdl","460","$user_www:$group"],
	['!admin/.*\.pl$'                  ,"local !admin *.pl","570","$user_www:$group"],
	['!admin'                          ,"local !admin","460","$user_www:$group"],
	
	['^version\.[0-9]+$'               ,"version"                     ,"660","$user_www:$group"],
	['^version$'                       ,"version"                     ,"660","$user_www:$group"],
	
	['\.key$'                          ,"key file"                    ,"660","$user_www:$group"],
	
	['\.pl$'                           ,"*.pl"                        ,"570","$user_www:$group"],
	
	['_overlays'                       ,"overlay file"                ,"660","$user_www:$group"],
	
	['\.git'                           ,".git"                        ,"660","$user:$group"],
	['\.cron_ignore'                   ,".cron_ignore"                ,"660","$user:$group"],
	
	['^\.'                             ,"unknown"                     ,"","$user:$group"],
);


=head2 %rights

Zmena masky na cislo

 '---' => '0'

=cut

our %rights=
(
	'---'	=>	"0",
	'r--'	=>	"4",
	'-w-'	=>	"2",
	'--x'	=>	"1",
	'-wx'	=>	"3",
	'r-x'	=>	"5",
	'rw-'	=>	"6",
	'rwx'	=>	"7",
);



=head1 FUNCTIONS

=head2 chfile($file,)

Zisti o aky typ suboru ide a ...

=cut

sub chfile
{
	# prijmem nazov suboru
	my $file=shift;
	
	# checknem ci existuje
	if (not -e $file)
	{
		return undef;
	}
	
	# otestujem na Cyclone prefix
	# mozem checkovat len subor ktory sa nachadza v ramci
	# Cyclone struktury
	if (not $file=~s/^$Cyclone::PATH\///)
	{
		return undef;
	}
	
	
	if (-d $Cyclone::PATH.'/'.$file)
	{
		# directory
		
		my $i;
		my $check;
		foreach (@setit_D)
		{
			if ($file=~/$setit_D[$i][0]/)
			{
				main::_log("file '$file' is '$setit_D[$i][1]'");
				_chmod($file,$setit_D[$i][2]);
				_chown($file,$setit_D[$i][3]);
				#&setit3($Ffile,'D '.$regexp_D[$var][1],$regexp_D[$var][2],$regexp_D[$var][3]);$check=1;
				last;
			}
			$i++;
		}
		next if $check;
		
	}
	elsif (-l $file)
	{
		# symlink
		
	}
	else
	{
		# standard file
		
	}
	
}



=head2 _chmod($file,'mod')

Tato funkcia nesmie byt dostupna zvonku

=cut

sub _chmod
{
	my $file=shift;
	# zistim ake ma prava dany subor
	File::getmod($file);
}



=head2 _chown($file,'user:group')

Nezdokumentovane

=cut

sub _chown
{
	my $file=shift;
}


1;
=head1 AUTHOR

Roman Fordinal

=cut
