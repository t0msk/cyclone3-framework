package Net::DOC;

use open ':utf8', ':std';
use encoding 'utf8';
use utf8;
use strict;

our @ISA=("Net::DOC::base");

use TOM::Template;

BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}

our (
	undef,
	undef,
	undef,
	undef,
	undef,
	$year,
	undef,
	undef,
	undef) = localtime(time);$year+=1900;

our $content_type="text/vnd.wap.wml";
our $type='wml';
my $tpl=new TOM::Template(
	'level' => "auto",
	'name' => "default",
	'content-type' => $type
);

# special mode
#$pub::engine_disabling=0;

our $err_page=$tpl->{'entity'}->{'page.error'};
our $warn_page=$tpl->{'entity'}->{'page.warning'};
our $err_mdl=$tpl->{'entity'}->{'box.error'};
our $notfound_page=$tpl->{'entity'}->{'body.notfound'};


sub new
{
	my $class=shift;
	my %env=@_;
	my $self={};
	%{$self->{'ENV'}}=%env;
	return bless $self,$class;
}


sub clone
{
	my $class=shift;
	my $self={};
	%{$self->{'ENV'}}=%{$class->{'ENV'}};
	%{$self->{'env'}}=%{$class->{'env'}};
	%{$self->{'OUT'}}=%{$class->{'OUT'}};
	return bless $self;
}

sub message {return 1;}

sub prepare
{
	my $self=shift;
	
	$self->{'ENV'}{'DOCTYPE'} = "<!DOCTYPE wml PUBLIC \"-//WAPFORUM//DTD WML 1.1//EN\" \"http://www.wapforum.org/DTD/wml_1.1.xml\">" unless $self->{'ENV'}{'DOCTYPE'};
	
	$self->{'OUT'}{'HEADER'} .= "<?xml version=\"1.0\" encoding=\"<%CODEPAGE%>\"?>\n";
	
	$self->{'OUT'}{'HEADER'} .= $self->{'ENV'}{'DOCTYPE'}."\n";
	
	$self->{'OUT'}{'HEADER'} .= "<wml>\n";
	
	$self->{'OUT'}{'HEADER'} .= "<card id=\"main\" title=\"<%TITLE%>\">";
	
	$self->{'env'}{'DOC_title'}=$self->{'ENV'}{'HEAD'}{'TITLE'};
	$self->{'env'}{'DOC_title'}=$tom::H unless $self->{'env'}{'DOC_title'};
	
	$self->{'OUT'}{'FOOTER'} = "</card>\n</wml>\n";
 
	return 1;
}


sub prepare_last
{
	my $self=shift;
	
	$self->{'OUT'}{'HEADER'}=~s|<%TITLE%>|$self->{'env'}{'DOC_title'}|;
	
	return 1;
}


sub add_DOC_css_link {return 1}

1;