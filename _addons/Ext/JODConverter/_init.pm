#!/bin/perl

#########################################################################
# LOAD JAR FILES
#########################################################################

package main;
use open ':utf8', ':std';
use if $] < 5.018, 'encoding','utf8';
use utf8;
use strict;

BEGIN
{
	main::_log("<={jclass} java.io.File");
	main::_log("<={jclass} com.artofsolving.jodconverter.DocumentConverter");
	main::_log("<={jclass} com.artofsolving.jodconverter.openoffice.converter.OpenOfficeDocumentConverter");
	main::_log("<={jclass} com.artofsolving.jodconverter.openoffice.connection.PipeOpenOfficeConnection");
	main::_log("<={jclass} com.artofsolving.jodconverter.openoffice.connection.SocketOpenOfficeConnection");
	my $DIR=(__FILE__=~/^(.*)\//)[0];
	# overriding CLASSPATH to import jar class
	my $JAR_CLASSPATH=`echo $DIR/lib/*.jar | tr ' ' ':'`;
	#main::_log("<={CLASSPATH} $JAR_CLASSPATH");
	$main::ENV{'CLASSPATH'}=$JAR_CLASSPATH;
}


# 		com.artofsolving.jodconverter.OpenOfficeDocumentConverter

use Inline
	Java => 'STUDY',
	STUDY => [ qw(
		java.io.File
		com.artofsolving.jodconverter.DocumentConverter
		com.artofsolving.jodconverter.openoffice.converter.OpenOfficeDocumentConverter
		com.artofsolving.jodconverter.openoffice.connection.PipeOpenOfficeConnection
		com.artofsolving.jodconverter.openoffice.connection.SocketOpenOfficeConnection
	) ],
	AUTOSTUDY => 1;


#########################################################################
# PERL LIBRARY
#########################################################################

package Ext::JODConverter;
use open ':utf8', ':std';
use if $] < 5.018, 'encoding','utf8';
use utf8;
use strict;

=head1 NAME

Extension to java JODConverter

=head1 DESCRIPTION

Extension that supports document conversions in OpenOffice.org via java library

=cut

our $DIR;
BEGIN
{
	main::_log("<={LIB} ".__PACKAGE__);
	$DIR=(__FILE__=~/^(.*)\//)[0];
}


use Proc::ProcessTable;

our $hostname=$Ext::JODConverter::hostname || 'localhost';
our $port=$Ext::JODConverter::port || '8100';
our $display=5;
our $connection;

=head1 FUNCTIONS

=cut

=head2 connect()

Connect to service

=cut

sub connect
{
	my $t=track TOM::Debug(__PACKAGE__."::connect('$hostname',$port)");
	
	$connection=new com::artofsolving::jodconverter::openoffice::connection::SocketOpenOfficeConnection($hostname,$port);
	# connect
	eval
	{
		$connection->connect();
	};
	if ($@)
	{
		$t->close();
		main::_log("can't connect because: ".$@->getMessage,1);
		return undef;
	}
	
	$t->close();
	return 1;
}



=head2 convert('file1:/','file2:/')

Convert file to file

When in file2 is defined only extension, same filename as in file1 is used but with this extension.

=cut

sub convert
{
	my $file1=shift;
	my $file2=shift;
	
	my $t=track TOM::Debug(__PACKAGE__."::convert('$file1','$file2')");
	
	if (length($file2)<=4)
	{
		my $file=$file1;
		$file=~s|^(.*)\.(.*?)$|\1.|;
		$file2=~s|\.||;
		$file=$file1.$file2;
		main::_log("file2='$file2'");
	}
	
	if (!$connection)
	{
		return undef unless Ext::JODConverter::connect();
	}
	
	my $file1_h=new java::io::File($file1);
	my $file2_h=new java::io::File($file2);
	
	eval
	{
		my $converter=new com::artofsolving::jodconverter::openoffice::converter::OpenOfficeDocumentConverter($connection);
		# conversion
		$converter->convert($file1_h, $file2_h);
	};
	if ($@)
	{
		$t->close();
		main::_log("can't convert because: ".$@->getMessage,1);
		return undef;
	}
	
#	old way
#	my $cmd="java -jar $DIR/lib/jooconverter-2.1.0.jar $file1 $file2";
#	open(CNV,"$cmd 2>/dev/null|");
	
	$t->close();
	return 1;
}


=head2 OpenOffice2Service_check()

Checks if OpenOffice.org is running as service

OpenOffice.org must be running under user cyclone3

=cut

sub OpenOffice2Service_check
{
	my $t=track TOM::Debug(__PACKAGE__."::OpenOffice2Service_check()");
	
	# checking if the OpenOffice is running and listening to connections
	my $service_running=0;
	my $pt = new Proc::ProcessTable;
	foreach my $p (@{$pt->table} )
	{
		my $cmd=$p->cmndline;
		if ($cmd=~/soffice\.bin.*?-headless -accept/)
		{
			$service_running=1;
			last;
		}
	}
	
	$t->close();
	return $service_running;
}


=head2 OpenOffice2Service_start()

 vncserver :5
 DISPLAY=:5 ooffice2 -display localhost:5.0 -headless -accept="socket,port=8100;urp;"

=cut

sub OpenOffice2Service_start
{
	my $t=track TOM::Debug(__PACKAGE__."::OpenOffice2Service_start()");
	
	my $service_running=OpenOffice2Service_check();
	
	main::_log("service_running=$service_running");
	
	if (!$service_running)
	{
		main::_log("starting VNC service");
		my $cmd='vncserver :'.$display;
		`$cmd`;
		main::_log("starting service");
		my $cmd='DISPLAY=:'.$display.' ooffice2 -display localhost:'.$display.'.0 -headless -accept="socket,port=8100;urp;"';
		`$cmd`;
	}
	
	$t->close();
	return 1;
}


=head1 why JODConvert in Perl?

Because Java can kiss my ass

=cut


1;
