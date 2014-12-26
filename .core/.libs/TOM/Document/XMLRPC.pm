package TOM::Document;

use open ':utf8', ':std';
use if $] < 5.018, 'encoding','utf8';
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

our $content_type="text/xml";
our $type='xmlrpc';
my $tpl=new TOM::Template(
	'level' => "auto",
	'name' => "default",
	'content-type' => $type
);
our $err_page=$tpl->{'entity'}->{'page.error'};

sub new
{
	my $class=shift;
	my %env=@_;
	my $self={}; 
	%{$self->{ENV}}=%env;
	return bless $self,$class;
}


sub clone
{
	my $class=shift;
	my $self={};
	%{$self->{ENV}}=%{$class->{ENV}};
	%{$self->{OUT}}=%{$class->{OUT}};
	return bless $self;
}



sub prepare
{
	my $self=shift;
	
	$self->{'OUT'}{'HEADER'} = qq{<?xml version="1.0" encoding="<%CODEPAGE%>"?>\n};
	$self->{'OUT'}{'HEADER'} .= qq{<methodResponse>\n};
	
	$self->{'OUT'}{'BODY'} = qq{
	<params>
		<param>
			<struct>
				<member>
					<name>header</name>
					<value>
						<struct>
							<member>
								<name>generator</name>
								<value><string>Cyclone$TOM::core_version.$TOM::core_build (r$TOM::core_revision)</string></value>
							</member>
							<member>
								<name>hostname</name>
								<value><string>$TOM::hostname</string></value>
							</member>
							<member>
								<name>domain</name>
								<value><string>$tom::H</string></value>
							</member>
							<member>
								<name>process</name>
								<value><i4>$$</i4></value>
							</member>
							<member>
								<name>request_code</name>
								<value><string><\$main::request_code></string></value>
							</member>
							<member>
								<name>method</name>
								<value><string><\$main::FORM{'type'}></string></value>
							</member>
							<member>
								<name>TypeID</name>
								<value><string><\$main::FORM{'TID'}></string></value>
							</member>
						</struct>
					</value>
				</member>
<!TMP-OUTPUT!>
			</struct>
		</param>
	</params>
} unless $self->{'OUT'}{'BODY'};
	
	$self->{'OUT'}{'FOOTER'} .= qq{</methodResponse>};
	
	return 1;
}




sub prepare_last
{
	my $self=shift;
	my %env=@_;
	
	# aplikujem title
	$self->{'OUT'}{'HEADER'}=~s|<%HEADER-TITLE%>|$self->{env}{DOC_title}|;
	$self->{'OUT'}{'HEADER'}=~s|<%HEADER-LNG%>|$tom::lng|g;
	$self->{'OUT'}{'HEADER'}=~s|<%HEADER-CODE%>|$main::request_code|;
	
	return 1;
}



1;