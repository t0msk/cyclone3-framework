#!/bin/perl
package App::180::Crawler;

=head1 NAME

App::180::Crawler

=head1 DESCRIPTION

A universal class for Crawler objects

=cut

use open ':utf8', ':std';
use if $] < 5.018, 'encoding','utf8';
use utf8;
use strict;
BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}


=head1 DEPENDS

=over

=item *

L<App::180::_init|app/"180/_init.pm">

=item *

L<TOM::Security::form|lib/"TOM/Security/form.pm">

=back

=cut

use App::180::_init;
use App::020::functions::metadata;

use TOM::Security::form;

use Time::HiRes qw(usleep);
use WWW::Mechanize;
use HTTP::Cookies;
use Module::Load;
use Digest::MD5 qw(md5 md5_hex md5_base64);
use Encode qw(encode);

use Data::Dumper;

our $debug=0;
our $quiet; $quiet=1 unless $debug;

=head1 AUTHORS

Comsultia, Ltd. (open@comsultia.com)

=cut



=head2

Instantiation of a new object of class App::180::Crawler.

my $crawler_object = new App::180::Crawler( 'domain_name');

The "domain_name" variable is supposed to be found in the %domain_config object. This can be either in _init.pm or 
local.conf or overridden elsewhere. Example domain config here:

%App::180::domain_config=(

	'www.thomann.de' => {

		'revisit' => 24*3, 		# re-visit a page after this period (at least) of hours
		'maxpages' => 5,		# maximum number of pages to browse
		'processor_lib' => 'Thomann',	# a processing lib (default location Domain/_addons/Ext/Crawler/Lib.pm);
		'start_page' => '/cz'		# starting page
	}
);

=cut


sub new
{
	my $class = shift;
	my $domain = shift;

	main::_log(__PACKAGE__.'::new()');

	unless ($App::180::domain_config{$domain})
	{
		main::_log('ERROR: Missing parameter (domain) or domain not present in %App::180::domain_config hash');
		return;
	}

	my %domain_config = %{$App::180::domain_config{$domain}};

	my $self = {
	
		'mech' => WWW::Mechanize->new(),
		'domain_config' => { %domain_config },
		'domain' => $domain,
	};


	# set default user agent, unless specified for the domain
	if (exists $domain_config{'agent'})
	{
		$self ->{'mech'} ->agent( $domain_config{'agent'} );
	} else
	{
		$self ->{'mech'} ->agent('Mozilla/5.0 (Windows; U; MSIE 7.0; Windows NT 6.0; sk-SK');
	}
	
	# initiate cookie jar
	$self ->{'mech'} ->cookie_jar(HTTP::Cookies->new);

	# set default headers 
	$self ->{'mech'} ->default_header(

		'Accept-Charset' => "utf-8;q=0.7,*;q=0.7",
		'Accept-Encoding' => "gzip,deflate"
	);

	# set max sleep

	if (exists $domain_config{'sleep_max'}) 
	{
		$self ->{'sleep_max'} = $domain_config{'sleep_max'};
	} else
	{
		$self ->{'sleep_max'} = 5;
	}

	# set recursion level

	if (exists $domain_config{'max_recursion_level'}) 
	{
		$self ->{'recursion_level'} = $domain_config{'max_recursion_level'};
	} else
	{
		$self ->{'recursion_level'} = 40;
	}

	# set maximum number of pages to browse

	if (exists $domain_config{'maxpages'}) 
	{
		$self ->{'maxpages'} = $domain_config{'maxpages'};
	} else
	{
		$self ->{'maxpages'} = 100;
	}

	# also specify a processor lib for this site

	if (exists $domain_config{'processor_lib'})
	{
		my $lib_location = $tom::P . '/_addons/Ext/Crawler/'.$domain_config{'processor_lib'}.'.pm';
		my $lib_name = 'Ext::Crawler';

		if ( -e "$lib_location")
		{
			# lib file exists, let's load it
			
			load "$lib_location";

			# our mechanize browser will hold a reference to an execute function. Supply environment variables
			# to it and receive a hashref of results to parse them. Create a reference to this function for later use

			no strict;

				my $function_process = $lib_name.'::'.$domain_config{'processor_lib'}.'::process';
				my $function_ignore = $lib_name.'::'.$domain_config{'processor_lib'}.'::ignore';

				$self ->{'process_function'} = \&$function_process;
				$self ->{'ignore_function'} = \&$function_ignore;

			use strict;
		}
	} else
	{
		main::_log('ERROR: Processor for this domain not found');
	}



	bless($self, $class);
	main::_log('Returning a blessed crawler object.');

	return $self
}

=head2

$crawler_object ->wait();

Wait for a random number of seconds according to sleep_max. (to pretend we are a human using a browser)

=cut

sub wait
{
	my $self = shift;

	main::_log(__PACKAGE__.'::wait()');

	my $maxwait = int(rand($self->{'sleep_max'}));

	main::_log("Sleep for $maxwait");
	sleep($maxwait); 
}

=head2

$crawler_object ->process();

Process results of the last get request. Act as a forwarder for a local processing package.

=cut

sub process
{
	my $self = shift;

	main::_log(__PACKAGE__.'::process()');

	my $result_hashref;
	
	no strict;

		# call the process function in the external lib with a reference to the mech object (mech) attribute
		# first and then just copy all my other params

		$result_hashref = $self->{'process_function'} ->('mech' => $self->{'mech'}, @_);

	use strict;

	return $result_hashref;
}

sub shouldIIgnoreURL
{	
	my $self = shift;
	my $url = shift;

	main::_log(__PACKAGE__.'::shouldIIgnoreURL()');
	
	my $result_hashref;

	no strict;

		# call the ignore function in the external lib with the url as a parameter
		
		$result_hashref = $self->{'ignore_function'} ->('url' => $url);

		print "should i ignore: ".Dumper($result_hashref)."\n";

	use strict;

	return $result_hashref;
}


sub visitPageRecursively
{
	my $self = shift;
	my $url = shift;
	my $recursion_stage = shift;

	main::_log(__PACKAGE__.'::visitPageRecursively()');

	$recursion_stage--;
	
	if ($self ->{'maxpages'} <= 0)
	{
		main::_log('I have reached the max number of browsed pages.');
		return 0;
	}
	print "After 0 we should not be here\n";

	$self ->{'maxpages'}--;
	print ('Pages left for this object: ' . $self ->{'maxpages'}, "\n");

	# check if this page was ever visited 

	main::_log('Visit page. Checking if page was visited URL='.$url);

	

	$self ->wait();

	my %page_results = $self ->visitOnePageAndSaveResults($url);


	# # follow links of this page, but test each link - compare it to the ignore list and also check score


=head1

my %results =
	(
		'ID_page' => $results_hashref{'ID'},
		'page_links' => $results_hashref{'links'},
		'page_status' => $results_hashref{'result_status'}
	);

=cut

	#my $should_i_ignore_this_page = $self ->shouldIIgnoreURL($url);	

	

	my @links = @{ $page_results{'page_links'} };

	my $revisit_hour = 20; #in hours


	main::_log('Looping over link items:');
	foreach my $link_item (@links)
	{
		# should I ignore this?
		

		my $uri = $link_item->URI()->abs;
		my $domain = $self ->{'domain'};
		



		$uri =~ s/^.*?$domain//;

		print('Processing link: '.$uri, "\n");		

		my $results_hashref = $self ->shouldIIgnoreURL($uri);

		print('after ignore', "\n");
		print('result: '.$results_hashref->{'result'});

		if ($results_hashref->{'result'})
		{
			# ignore
			print "IGNORE\n";
			main::_log('Ignoring URL: '.$uri);
			next;
		}

		# check if I have visited this link yak - len skontrolovat, ci som to uz nedavno nenavstivil
		
		main::_log('Looking for URL in database: '.$uri.' not visited later than '.$revisit_hour.' hours ago');

		my $sql = qq{
	
			SELECT * FROM
			
				`$App::180::db_name`.a180_page
			WHERE
				reply = 200 AND
				domain = ? AND 
				url = ? AND
				( datetime_create > DATE_SUB(NOW(), INTERVAL ? HOUR) OR weight = 100 )
			LIMIT 1
		};
		my %sth0=TOM::Database::SQL::execute($sql,'log'=>1,'-slave'=>1, '-quiet'=>0, 
			'bind' => [ $self ->{'domain'}, $uri, $revisit_hour ] );

		if (my %db_page=$sth0{'sth'}->fetchhash())
		{
			# nasiel som ju, nejdem
			main::_log('Page recently visited, ignoring');
			next;
		
		} else
		{
			# nenasiel som,browsujem
			main::_log('ok, browsing '.$uri);
		}


		main::_log('Recursion stage: '.$recursion_stage);
		
		# if not, visit this link recursively, unless we should ignore this
		if ($recursion_stage)
		{
			my $retval = $self ->visitPageRecursively($uri, $recursion_stage);

			# if visitPageRecursively returns 0 => page limit exceeded, exit
			return 0 unless ($retval);
		} else
		{
			
		}
	}


	return 1;
}

=head1
	Visits a page, tries to find results and returns them as a hash reference

	The hash is returned in this form (every library has to conform to this standard:)

	$return_ref ->{'results'} =
	[					# array of individual results (can be more than 1 per page)
		{
			'id' => $product_name,		# the string that the unique identifier will be calculated from

			'catalog' => 'products',	# name of the catalog (arbitrary)

			'object' =>	{		# object that can be serialized to cyclone3-compatible metadata
						'product' => {
							'name' => $product_name,
							'price_eur' => $product_price,
							'category1' => $product_categories[0],
							'category2' => $product_categories[1]
						}
					}
		}
	];
=cut

sub visitPageTest
{
	my $self = shift;
	my $url = shift;

	main::_log(__PACKAGE__.'::visitPageTest()');

	main::_log('Visit page. No url check, no recursion, no waiting. just analyze and dump results. '.$url);
	

	my $fq_uri = 'http://' . $self ->{'domain'}.$url;

	main::_log('Getting page..'.$fq_uri);

	eval { $self ->{'mech'} ->get($fq_uri) };

	my $result_status = $self ->{'mech'} -> status;

	if ($result_status == 200)
	{
		

		my @links = $self ->{'mech'} -> links();

		# analyze page
	
		my $result_hashref = $self ->process();


		# are there any results? dump them

		print Dumper $result_hashref;

		# return all results for further use

		return $result_hashref;

	} else
	{
		main::_log('Did not get page. Result status: '.$result_status);

		return undef;
	}
}

sub visitPage
{
	my $self = shift;
	my $url = shift;

	main::_log(__PACKAGE__.'::visitPage()');

	main::_log('Visit page. Record it in the database. Process results. Record results in the database. No recursion. No ignore. '.$url);

	my $sql = qq{
	
		SELECT * FROM
		
			`$App::180::db_name`.a180_page
		WHERE
			url = ?
		LIMIT 1
	};
	my %sth0=TOM::Database::SQL::execute($sql,'log'=>0,'-slave'=>1, '-quiet'=>1, 'bind' => [ $url ] );

	my %db_page;

	if (%db_page=$sth0{'sth'}->fetchhash())
	{
	
	} else
	{
	
	}


	my $fq_uri = 'http://' . $self ->{'domain'}.$url;

	main::_log('Getting page..'.$fq_uri);

	eval { $self ->{'mech'} ->get($fq_uri) };

	my $result_status = $self ->{'mech'} -> status;

	# prepare %page_columns for update
	my %page_columns;
	$page_columns{'reply'}="'".TOM::Security::form::sql_escape($result_status)."'";
	$page_columns{'url'}="'".TOM::Security::form::sql_escape($url)."'";
	$page_columns{'domain'}="'".TOM::Security::form::sql_escape($self->{'domain'})."'";
	$page_columns{'status'}="'Y'";


	my $result_hashref;
	my @links;

	if ($result_status == 200)
	{
		

		@links = $self ->{'mech'} -> links();

		# analyze page	
		$result_hashref = $self ->process();

	} else
	{
		main::_log('Did not get page. Result status: '.$result_status);
	}

	

	# record page score
	if ($db_page{'ID'})
	{
		# page already exists in the database - update

		App::020::SQL::functions::update(
			'ID' => $db_page{'ID'},
			'db_h' => "main",
			'db_name' => $App::180::db_name,
			'tb_name' => "a180_page",
			'columns' => {%page_columns},
			'-journalize' => 0
		);

	} else
	{
		# there is no record in the database - add

		$db_page{'ID'}=App::020::SQL::functions::new(
			'db_h' => "main",
			'db_name' => $App::180::db_name,
			'tb_name' => "a180_page",
			'columns' =>
			{
				%page_columns,
			},
			'-journalize' => 0
		);
	} 

	$result_hashref ->{'page'} = {

		'ID' => $db_page{'ID'},
		'links' => [ @links ],
		'result_status' => $result_status
		
	};


	return $result_hashref;

}

sub visitOnePageAndSaveResults
{
	my $self = shift;
	my $url = shift;

	main::_log(__PACKAGE__.'::visitOnePageAndSaveResults()');

	main::_log('Visit a page and if valuable data found, record it in the database');

	my $results_hashref = $self ->visitPage($url);

	# there must be results and they must come from a recorded page, otherwise there is
	# nothing to save or we would be saving orphans with no page

	if ($results_hashref ->{'results'} && $results_hashref ->{'page'} ->{'ID'})
	{
		# the array of result objects 
		my @results = @{$results_hashref ->{'results'}};

		foreach my $result_item (@results)
		{
			# does the object have a unique identifier?
			if ($result_item ->{'id'})
			{

				# serialize this object to metadata string
				my $metadata_string = App::020::functions::metadata::serialize( %{$result_item ->{'object'}} );	

				# create an identifier hash
				
				
				my $text_id = $result_item ->{'id'};
				
				my $identifier = md5_base64(encode("UTF-8", "$text_id"));

				# prepare update columns
				my %object_columns;

				$object_columns{'metadata'}="'".TOM::Security::form::sql_escape($metadata_string)."'";
				$object_columns{'catalog'}="'".TOM::Security::form::sql_escape($result_item ->{'catalog'})."'";
				$object_columns{'identifier'}="'".TOM::Security::form::sql_escape($identifier)."'";
				$object_columns{'status'}="'Y'";
				$object_columns{'ID_page'}=$results_hashref ->{'page'} ->{'ID'};

				# look for the record by unique identitifier, insert or update record

				# domain is also a part of uniqueness of a record - not yet!

				my $sql = qq{
				
					SELECT 
						object.*, 
						page.ID_entity 
					FROM
					
						`$App::180::db_name`.a180_object AS object

					LEFT JOIN `$App::180::db_name`.a180_page AS page 
					ON (object.ID_page = page.ID)

					WHERE
						object.identifier = ? AND
						object.catalog = ? AND
						page.domain = ?
					LIMIT 1
				};
			
				my %sth0=TOM::Database::SQL::execute($sql,'log'=>0,'-slave'=>1, '-quiet'=>1,
					'bind' => [ 
							$identifier,
							$result_item ->{'catalog'},
							$self ->{'domain'}
					]);

				my %db_object;

				if (%db_object=$sth0{'sth'}->fetchhash())
				{
					App::020::SQL::functions::update(
						'ID' => $db_object{'ID'},
						'db_h' => "main",
						'db_name' => $App::180::db_name,
						'tb_name' => "a180_object",
						'columns' => {%object_columns},
						'-journalize' => 1
					);

				} else
				{
					$db_object{'ID'} = App::020::SQL::functions::new(
						'db_h' => "main",
						'db_name' => $App::180::db_name,
						'tb_name' => "a180_object",
						'columns' =>
						{
							%object_columns,
						},
						'-journalize' => 1
					);
				}
				
				# also set metaindex for this item
				
				App::020::functions::metadata::metaindex_set(
					'db_h' => 'main',
					'db_name' => $App::180::db_name,
					'tb_name' => 'a180_object',
					'ID' => $db_object{'ID'},
					'metadata' => {App::020::functions::metadata::parse($object_columns{'metadata'})}
				);


			}
		}
	} else
	{
		main::_log("results_hashref ->{'results'} or results_hashref ->{'page'} ->{'ID'} missing, probably page ID=".$results_hashref ->{'page'} ->{'ID'});
	}


	# return a hash with page browsing results, score and links, so we can browse some more, oh yeah baby!

	my %results =
	(
		'ID_page' => $results_hashref ->{'ID'},
		'page_links' => $results_hashref ->{'page'}->{'links'},
		'page_status' => $results_hashref ->{'result_status'}
	);

	

	

}





=head1
	Browse domain automatically - from the last page visited or from start (visited with status of 200)
=cut

sub browseAuto
{
	my $self = shift;

	my $recursion_stage = $self ->{'recursion_level'};

	main::_log(__PACKAGE__.'::browseAuto()');

	# get the most recent page with status of 200 and use that to kick off

	my $sql = qq{
	
		SELECT * FROM
		
			`$App::180::db_name`.a180_page
		WHERE
			status = 200 AND
			domain = ?

		ORDER BY
			datetime_create DESC	

		LIMIT 1
	};

	my %sth0=TOM::Database::SQL::execute($sql,'log'=>0,'-slave'=>1, '-quiet'=>1, 'bind' => [ $self ->{'domain'} ] );

	if (my %db_page=$sth0{'sth'}->fetchhash())
	{
		if ($db_page{'url'})
		{
			$self ->visitPageRecursively($db_page{'url'}, $recursion_stage);
		}
	} else
	{
		$self ->browseAutoFromStart();
	}

}



=head1
	Browse domain automatically - but start from the first page if specified in the domain config. If not, try /.
=cut

sub browseAutoFromStart
{
	my $self = shift;

	my $recursion_stage = $self ->{'recursion_level'};

	main::_log(__PACKAGE__.'::browseAutoFromStart()');

	my $page_url;

	if (exists $self ->{'domain_config'} ->{'start_page'})
	{
		# start with the preset default page url

		$page_url = $self ->{'domain_config'} ->{'start_page'};
	} else
	{
		# use a default value for page_url /

		$page_url = '/';
	}

	my $result = $self ->visitPageRecursively($page_url, $recursion_stage);
}

1;
