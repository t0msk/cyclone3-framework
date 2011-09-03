package TOM::Document;

use open ':utf8', ':std';
use encoding 'utf8';
use utf8;
use strict;

our @ISA=("TOM::Document::base");

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

our $content_type="text/html";
our $type='xhtml';
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
	
	$self->{'OUT'}{'HEADER'} .= "\n" if ($self->{'OUT'}{'HEADER'});
	
	$self->{'OUT'}{'BODY'} = qq{<!TMP-OUTPUT!>} unless $self->{'OUT'}{'BODY'};
	
	$self->{'env'}{'DOC_title'}="$tom::H";
	
	$self->{'OUT'}{'FOOTER'} = "\n";
	
	return 1;
}


sub prepare_last
{
	my $self=shift;
	
#	$self->{'OUT'}{'HEADER'}=~s|<%TITLE%>|$self->{'env'}{'DOC_title'}|;
	
	return 1;
}


sub add_DOC_css_link {return 1}
sub change_DOC_robots {return 1}

1;