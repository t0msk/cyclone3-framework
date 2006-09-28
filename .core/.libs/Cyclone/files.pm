package Cyclone::files;
use open ':utf8', ':std';
use encoding 'utf8';
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

=head2 @setid_d

Zoznam regulárnych výrazov pre detekciu typu adresára + nastavenie práv

 ['regexp' ,"directory type name" ,"mod" ,"user:group"]

=cut

our @setit_D=
(
	['media.*\.svn'                     ,"media .svn directory"        ,"770","www:www"],
	['\.svn'                            ,".svn directory"              ,"570","apache:cyclone3"],
	
	# exclude dirs
	['phprojekt'                       ,"phprojekt"                   ,"",""],
	['phpmyadmin'                      ,"phpmyadmin"                  ,"",""],
	['^\.admin'                        ,"global admin"                ,"",""],
	
	# global
	['^_data'                          ,"global _data"                ,"570","apache:cyclone3"],
	['^_temp'                          ,"global _temp"                ,"770","apache:cyclone3"],
	['^.symlinks$'                     ,"global .symlinks"            ,"570","apache:cyclone3"],
	['^_mdl'                           ,"global _mdl"                 ,"570","apache:cyclone3"],
	['^\.core'                         ,"global .core"                ,"570","apache:cyclone3"],
	['^_dsgn$'                         ,"global _dsgn"                ,"570","apache:cyclone3"],
	['^_type$'                         ,"global _type"                ,"570","apache:cyclone3"],
	['^\.bin$'                         ,"global .bin"                 ,"770","cyclone3:cyclone3"],
	['^_logs'                          ,"global _logs"                ,"770","apache:cyclone3"],
	['^!media'                         ,"global !media"               ,"775","www:www"],
	['^_trash'                         ,"global _trash"               ,"777","cyclone3:cyclone3"],
	
	# local
	['\/_mdl$'                         ,"local _mdl"                  ,"570","apache:cyclone3"],
	['\/\.libs'                        ,"local libraries"             ,"570","apache:cyclone3"],
 	['\/_dsgn$'                        ,"local _dsgn"                 ,"770","apache:cyclone3"],
	['\/!www$'                         ,"local !www"                  ,"770","apache:cyclone3"],
	['\/_type$'                        ,"local _type"                 ,"770","apache:cyclone3"],
	['\/_data'                         ,"local _data"                 ,"770","apache:cyclone3"],
	['\/_logs'                         ,"local _logs"                 ,"770","apache:cyclone3"],
	['\/!media'                        ,"local !media symlink"        ,"",""],
	
	['![\w\.\-]+$'                     ,"domain"                      ,"770","apache:cyclone3"],
	['\/!www'                          ,"document roots"              ,"770","apache:cyclone3"],
	['![\w\.\-]+/[\w]+$'               ,"subdomain"                   ,"770","apache:cyclone3"],
);


=head2 @setid_F

Zoznam regulárnych výrazov pre detekciu typu suboru + nastavenie práv

 ['regexp' ,"directory type name" ,"mod" ,"user:group"]

=cut

our @setit_F=
(
	['\.svn'                           ,".svn files"                  ,"444",""],
	
	['phprojekt'                       ,"phprojekt"                   ,"",""],
	['!nc'                             ,"new Cyclone"                 ,"",""],
	['phpmyadmin'                      ,"phpmyadmin"                  ,"",""],
	
	['_trash'                          ,"_trash"                      ,"660","apache:cyclone3"],
	['^_temp/_Inline'                  ,"global Inline"               ,"777","apache:cyclone3"],
	['^_temp'                          ,"global _temp"                ,"",""],
 
	['\.(pwd)$'                        ,".pwd (password file)"        ,"660","apache:cyclone3"],
	['\.tmpl$'                         ,".tmpl (template)"            ,"660","cyclone3:cyclone3"],
	['\.sql$'                          ,".sql (SQL queries)"          ,"660","cyclone3:cyclone3"],
	
	# www:www ak media su cez NFS na inom serveri
	['^!media\/'                       ,"!media"                      ,"664","www:www"],
	# apache:cyclone3 ak media su normalne lokalne
	['!media\/'                        ,"!media domain"               ,"664","apache:cyclone3"],
	['\.htaccess$'                     ,".htaccess"                   ,"460","apache:cyclone3"],
	
	['_logs\/.*\.log$'                 ,"_logs cron .log"             ,"",""],
	['_logs\/httpd\/'                  ,"_logs httpd"                 ,"",""],
	['_logs\/'                         ,"_logs cron .log"             ,"",""],
 
	['\.libs\/.*\.pm'                  ,"library"              ,"460","apache:cyclone3"],
	['\.libs\/.*\.txt'                 ,"library inputs"       ,"660","apache:cyclone3"],
	
	
	['\.bin\/'                         ,"core binary"                 ,"770","cyclone3:cyclone3"],
	
	['^\.core\/_config\/httpd\.virtual\.conf',"HTTPD virtual conf"    ,"460","apache:cyclone3"],
	['^\.core\/_config\/TOM.conf'      ,".core TOM.conf"              ,"460","apache:cyclone3"],
	['^\.core\/_config\/'              ,".core conf"                  ,"460","apache:cyclone3"],
	
	['^\.core\/_config\.sg\/httpd\.conf',"HTTPD virtual conf"         ,"460","apache:cyclone3"],
	['^\.core\/_config\.sg\/TOM.conf'  ,".core TOM.conf"              ,"460","apache:cyclone3"],
	
	
	['^\.core\/.*pid$'                 ,".core .pid"                  ,"",""],
	
	['(^\.core\/(tom|cron|cyc|webclick|download|export|a540|test)|^core)'
	                                   ,".core engines","770","cyclone3:cyclone3"],
	
	['\.core\/.*\.so$'                 ,".core so"                    ,"660","apache:cyclone3"],
	
	['\.RFC$'                          ,"RFC files"                   ,"660","apache:cyclone3"],
	['\/master\.conf$'                 ,"master conf"                 ,"660","apache:cyclone3"],
	['\/local\.conf$'                  ,"local conf"                  ,"660","apache:cyclone3"],
	['\/type\.conf$'                   ,"type conf"                   ,"660","apache:cyclone3"],
	['\/rewrite\.conf$'                ,"rewrite conf"                ,"660","apache:cyclone3"],
	['\/301\.conf$'                    ,"301 conf"                    ,"660","apache:cyclone3"],
 
	['\/cron\..*?\.cml$'               ,"local cron cml"              ,"460","apache:cyclone3"],
	
	
	['!www.*(tom|pl|fcgi|php|asp)$'    ,"!www executables"            ,"560","apache:cyclone3"],
	['!www.*(css|html|wml|js|xml|txt|ppt|pdf|xls|xsl|doc|cvml)$'
	                                   ,"!www docs"                   ,"660","apache:cyclone3"],
	['!www.*php\?'
	                                   ,"!www docs mirrored"          ,"660","apache:cyclone3"],
	['\/!www\/.*(jpg|png|gif|wbmp|swf|svg|ico)$'
	                                   ,"!www graphix"                ,"660","apache:cyclone3"],
	['\/!www\/.*(asf|avi)$'            ,"!www video"                  ,"660","apache:cyclone3"],
	['\/!www\/.*(gz|bz2|tar|zip)$'     ,"!www archive"                ,"660","apache:cyclone3"],
	['\/!www\/.*$'                     ,"!www unknown"                ,"660","apache:cyclone3"],
	
	
	['_dsgn\/.*\.dsgn$'                ,"_dsgn dsgn"                  ,"660","apache:cyclone3"],
	['_type\/.*\.type$'                ,"_type type"                  ,"660","apache:cyclone3"],
	['_type\/.*\.cml_type$'            ,"_type cml_type"              ,"660","apache:cyclone3"],
	['_type\/.*\.cml_gen$'             ,"_type cml_gen"               ,"660","apache:cyclone3"],
	
	['_mdl\/.*\.xlng$'                 ,"xlng"                        ,"660","apache:cyclone3"],
	['_mdl.*\.xsgn$'                   ,"xsgn"                        ,"660","apache:cyclone3"],
	['_mdl\/.*mdl$'                    ,"?mdl"                        ,"660","apache:cyclone3"],
	
	['_mdl\/.*cron$'                   ,"_mdl cron"                   ,"660","apache:cyclone3"],
 
	['_data\/USRM\/.*'                 ,"local _data USRM"            ,"",""],
	['_data\/.*'                       ,"local _data"                 ,"660","apache:cyclone3"],
	
	# old admin
	['!admin/.*\.mdl$'                 ,"local !admin *.mdl","460","apache:cyclone3"],
	['!admin/.*\.pl$'                  ,"local !admin *.pl","570","apache:cyclone3"],
	['!admin'                          ,"local !admin","460","apache:cyclone3"],
	
	['^version\.[0-9]+$'               ,"version"                     ,"660","apache:cyclone3"],
	['^version$'                       ,"version"                     ,"660","apache:cyclone3"],
	
	['\.key$'                          ,"key file"                    ,"660","apache:cyclone3"],
 
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