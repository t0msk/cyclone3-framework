package App::020::functions::metadata;

=head1 NAME

App::020::functions::metadata

=cut

use open ':utf8', ':std';
use encoding 'utf8';
use utf8;
use strict;

our $ixhash;

BEGIN {
	eval{main::_log("<={LIB} ".__PACKAGE__);};
	eval {require Tie::IxHash;};
	if ($@)
	{
		main::_log("<={LIB} Tie::IxHash not available",1);
	}
	else
	{
		main::_log("<={LIB:dist} Tie::IxHash");
		$ixhash=1;
	}
}

sub ixhash_ref
{
	tie my %hash, 'Tie::IxHash', @_;
	return \%hash;
}

=head1 FUNCTIONS

=head2 parse

 $metadata=qq{
  <metatree>
   <section name="section">
	 <variable name="variable">value</variable>
	</section>
  </metatree>
 };
 %hash=App::020::functions::metadata::parse($metadata);

=cut

sub parse
{
	my $metaindex=shift;
	utf8::decode($metaindex) unless utf8::is_utf8($metaindex);
	my %hash;
	if($ixhash)
	{
		tie %hash, 'Tie::IxHash';
	}
	
	if (not $metaindex =~/<\/metatree>/)
	{
		return %hash;
	}
	
	while ($metaindex =~ /<section name="(.*?)"\ ?(\/?)>/)
	{
		my $section_name=$1;
		if($ixhash)
		{
			$hash{$section_name} = ixhash_ref();
		}
		else
		{
			$hash{$section_name} = {};
		}
		
		if ($2)
		{	
			# empty section
			$metaindex =~ s/<section name="(.*?)"\ ?\/>//;	
		}
		else
		{
			# section with vars
			$metaindex=~s|<section name="(.*?)">(.*?)</section>||s;
			
			my $section_metaindex = $2;

			while ($section_metaindex=~s/<variable name="(.*?)" ?\/?>([^<]*)(<\/variable>)?//s)
			{
				my $variable_name=$1;	
				my $variable_value=$2;
				$variable_value = undef if (!$3);
				
				$hash{$section_name}{$variable_name}=$variable_value;
			}
		}
	}
	
	return %hash;
}

=head2 parse_array

 $metadata=qq{
  <metatree>
   <section name="section">
	 <variable name="variable">value</variable>
	</section>
  </metatree>
 };
 @list=App::020::functions::metadata::parse_array($metadata);


@list = ( {'name' => 'section_name', 'variables' => [ {'name' => 'variable_name', 'value' => 'variable_value'}, ... ] )

=cut

sub parse_array
{
	my $metaindex=shift;
	utf8::decode($metaindex) unless utf8::is_utf8($metaindex);
	my @list;
	
	while ($metaindex =~ /<section name="(.*?)"\ ?(\/?)>/)
	{
		my $section_name=$1;
		my $section = {'name' => $section_name};

		if ($2)
		{	
			# empty section
			$metaindex =~ s/<section name="(.*?)"\ ?\/>//;	
		} else
		{
			# section with vars
			$metaindex=~s|<section name="(.*?)">(.*?)</section>||s;
			
			my $section_metaindex = $2;
			
			my @variables;

			while ($section_metaindex=~s/<variable name="(.*?)" ?\/?>([^<]*)(<\/variable>)?//s)
			{
				my $variable_name=$1;	
				my $variable_value=$2;
				$variable_value = undef if (!$3);
	
				push(@variables, { 'name' => $variable_name, 'value' => $variable_value});
			}

			$section ->{'variables'} = [ @variables ];
		}
		push(@list, $section);
	}
	return @list;
}


sub metaindex_set
{
	my %env=@_;
	my %metadata=%{$env{'metadata'}};
	$env{'db_h'}='main' unless $env{'db_h'};
	return unless $env{'db_name'};
	return unless $env{'tb_name'};
	return unless $env{'ID'};
	
	TOM::Database::SQL::execute(qq{
		UPDATE `$env{'db_name'}`.`$env{'tb_name'}_metaindex`
		SET status='N' WHERE ID='$env{'ID'}'
	},'quiet'=>1,'db_h'=>$env{'db_h'});

	foreach my $section_name (keys %metadata)
	{
		foreach my $variable_name (keys %{$metadata{$section_name}})
		{
			next if ((!$metadata{$section_name}{$variable_name})&&($metadata{$section_name}{$variable_name} ne "0"));
			main::_log("re-set '$section_name\::$variable_name'='$metadata{$section_name}{$variable_name}'");
			#next;
			TOM::Database::SQL::execute(qq{
				REPLACE INTO `$env{'db_name'}`.`$env{'tb_name'}_metaindex`
				(
					ID,
					meta_section,
					meta_variable,
					meta_value,
					status
				)
				VALUES
				(
					'$env{'ID'}',
					?,
					?,
					?,
					'Y'
				)
			},
			'bind' => [
				$section_name,
				$variable_name,
				$metadata{$section_name}{$variable_name}
			],
			'quiet'=>1,'db_h'=>$env{'db_h'});
		}
	}
	
	TOM::Database::SQL::execute(qq{
		DELETE FROM `$env{'db_name'}`.`$env{'tb_name'}_metaindex`
		WHERE status='N'
	},'quiet'=>1,'db_h'=>$env{'db_h'});
	
}

sub serialize
{
	my %metadata=@_;
	my $text="<metatree>\n";
	
	foreach my $section (keys %metadata)
	{
		$text.="<section name=\"$section\">\n";
		foreach my $variable(keys %{$metadata{$section}})
		{
			$text.="<variable name=\"$variable\">$metadata{$section}{$variable}</variable>\n";
		}
		$text.="</section>";
	}
	
	$text.="</metatree>";
	
	return $text;
}

1;