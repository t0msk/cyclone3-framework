package TOM::Database::SQL::transaction;

=head1 NAME

TOM::Database::SQL

=cut

use open ':utf8', ':std';
use encoding 'utf8';
use utf8;
use strict;
BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}


our %handler;
our $debug=0;
our $quiet;$quiet=1 unless $debug;

=head1 FUNCTIONS

=head2 new()

Začiatok transakcie

=cut

sub new
{
	my $class=shift;
	my $self={};
	
	my %env=@_;
	
	$env{'db_h'}="main" unless $env{'db_h'};
	
	$self->{'db_h'}=$env{'db_h'};
	
	if ($handler{$self->{'db_h'}})
	{
		main::_log("<={SQL:$self->{'db_h'}} TRANSACTION STARTED IN TRANSACTION ($handler{$self->{'db_h'}}+)");
	}
	else
	{
		
		$self->{'version'}=TOM::Database::SQL::get_database_version($self->{'db_h'});
		$self->{'supported'}=1 if $self->{'version'} gt '4.0';
		
		main::_log("<={SQL:$self->{'db_h'}} START TRANSACTION");
		
		my $SQL="SET AUTOCOMMIT=0";
		my %eout=TOM::Database::SQL::execute($SQL,'db_h'=>$self->{'db_h'},'log'=>$debug,'quiet'=>$quiet) if $self->{'supported'};
		
		my $SQL="START TRANSACTION";
		my %eout=TOM::Database::SQL::execute($SQL,'db_h'=>$self->{'db_h'},'log'=>$debug,'quiet'=>$quiet) if $self->{'supported'};
		
	}
	
	$handler{$self->{'db_h'}}++;
	
	return bless $self, $class;
}


sub close
{
	my $self=shift;
	
	if (!$handler{$self->{'db_h'}})
	{
		main::_log("<={SQL:$self->{'db_h'}} CANCEL ENDING TRANSACTION");
		delete $self->{'db_h'};
		return undef;
	}
	
	$handler{$self->{'db_h'}}--;
	
	if (!$handler{$self->{'db_h'}})
	{
		main::_log("<={SQL:$self->{'db_h'}} END TRANSACTION");
		my $SQL="SET AUTOCOMMIT=1";
		my %eout=TOM::Database::SQL::execute($SQL,'db_h'=>$self->{'db_h'},'log'=>$debug,'quiet'=>$quiet) if $self->{'supported'};
	}
	else
	{
		main::_log("<={SQL:$self->{'db_h'}} CAN'T END TRANSACTION ($handler{$self->{'db_h'}}-)");
	}
	
	delete $self->{'db_h'};
	return undef;
}


sub rollback
{
	my $self=shift;
	main::_log("<={SQL:$self->{'db_h'}} ROLLBACK",1);
	
	undef $handler{$self->{'db_h'}};
	
	my $SQL="ROLLBACK";
	my %eout=TOM::Database::SQL::execute($SQL,'db_h'=>$self->{'db_h'},'log'=>$debug,'quiet'=>$quiet) if $self->{'supported'};
	
	my $SQL="SET AUTOCOMMIT=1";
	my %eout=TOM::Database::SQL::execute($SQL,'db_h'=>$self->{'db_h'},'log'=>$debug,'quiet'=>$quiet) if $self->{'supported'};
	
	delete $self->{'db_h'};
	return undef;
}


sub DESTROY
{
	my $self=shift;
	return undef unless $self->{'db_h'}; # return ak uz bol object zniceny
	return undef unless $handler{$self->{'db_h'}}; # return ak uz bol object zniceny vnutornou transakciou
	
	undef $handler{$self->{'db_h'}};
	
	main::_log("<={SQL:$self->{'db_h'}} DESTROY TRANSACTION",1);
	
	my $SQL="ROLLBACK";
	my %eout=TOM::Database::SQL::execute($SQL,'db_h'=>$self->{'db_h'},'log'=>$debug,'quiet'=>$quiet) if $self->{'supported'};
	
	my $SQL="SET AUTOCOMMIT=1";
	my %eout=TOM::Database::SQL::execute($SQL,'db_h'=>$self->{'db_h'},'log'=>$debug,'quiet'=>$quiet) if $self->{'supported'};
	
 	die "Not ended transaction on handler '$self->{'db_h'}'.";
	
	$self={};
	
	return undef;
}


1;
