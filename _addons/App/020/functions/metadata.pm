package App::020::functions::metadata;

=head1 NAME

App::020::functions::metadata

=cut

use open ':utf8', ':std';
use encoding 'utf8';
use utf8;
use strict;
BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}


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
	
	while ($metaindex=~s|<section name="(.*?)">(.*?)</section>||s)
	{
		my $section_name=$1;
		my $section_metaindex=$2;
		while ($section_metaindex=~s|<variable name="(.*?)">(.*?)</variable>||s)
		{
			my $variable_name=$1;
			my $variable_value=$2;
#			main::_log("$section_name :: variable_name='$variable_name' variable_value='$variable_value'");
			$hash{$section_name}{$variable_name}=$variable_value;
		}
	}
	
	return %hash;
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
			next unless $metadata{$section_name}{$variable_name};
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
					'$section_name',
					'$variable_name',
					'$metadata{$section_name}{$variable_name}',
					'Y'
				)
			},'quiet'=>1,'db_h'=>$env{'db_h'});
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