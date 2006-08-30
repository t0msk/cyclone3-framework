#!/bin/perl
# áéíóú - USE UTF-8 !!!
package App::B00;
use strict;

BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}

our $debug=0;

sub GetWords
{
	my $sentence=shift;
	##utf8::decode($sentence) unless utf8::is_utf8($sentence);
	
	my @words;
	my $end=' ';
	while ($sentence=~s/(.*?)[$end]//)
	{
		my $word=$1;
		push @words,$word;
	}
	
	push @words,$sentence;
	return @words;
}


sub GetSentences
{
	my $text=shift;
	
	#utf8::decode($text); # convertnem text do utf8;
	##utf8::decode($text) unless utf8::is_utf8($text);
	
	$text.="\n" unless $text=~/\n$/s;
	my @sentences;
	
	my $sentence;
	while ($text=~s/(.*?)([\W+])//)
	{
		#print "->$1/$2\n";# if $debug;
		my $word=$1;
		my $splitter=$2;
   
		$sentence.=$word.$splitter;;# if $word;
		#$veta.=$splitter;# if $splitter;
 
		my $end='[\.\?!\(\)\n,":;“”/\']';
		if ($splitter=~/$end/)
		{
			# ide o cislo, tak nekoncim vetu...
			if (($text=~/^\d/)&&($word=~/\d$/))
			{
			 next;
			}
			
			if (($splitter eq "'")&&($text=~/^\w/)&&($word=~/\w$/))
			{
			 next;
			}
			
			# ide o skratku!
			
			$sentence=~s|$end$||;
			push @sentences,[$sentence,$splitter];
			
			#print "=>$sentence/\\x".ord($splitter)."/\n";
			#print ":>";foreach (split(' ',$veta)){print $_.";";}print "\n";  
			$sentence="";
		}
	}
	
	#push @sentences,[$sentence,"\n"];
	return @sentences;
}











sub Phrase_translate
{
 my @words;
 my $word=shift; # for translation
 return @words if ($word=~/ $/ || !$word);
 
 ##utf8::decode($word) unless utf8::is_utf8($word);
 my $phrase=do{($word=~/ /) ? "AND phrase='Y'" : "AND phrase='N'"};
 
 my %env=@_;
 my $limit=do{($env{limit}) ? "LIMIT ".$env{limit} : undef};
 my $lng_from=$env{from};
 my $lng_to=$env{to}; 
 return undef unless $env{from};
 return undef unless $env{to};

 $word=~s|\'|\\'|g;

 main::_log("finding phrase {$word}") if $debug;
 
 # najdem toto slovo v slovniku
 # prve je to najrelevantnejsie vzhladom k domene
 my $db0=$main::DB{main}->Query("
	SELECT *
	FROM TOM_clone.aB00_phrase
	WHERE 	word='$word'
			AND (lng='$lng_from' OR lng='')
			$phrase
			AND (domain='' OR (domain='$tom::Hm' AND (domain_sub ='' OR domain_sub='$tom::H')))
	ORDER BY domain DESC,domain_sub DESC,lng DESC
	LIMIT 1");
 if (my %db0_line=$db0->fetchhash())
 {

 	main::_log("founded phrase {$word}[$db0_line{ID}]") if $debug;
 
	my $count;
        my $db2=$main::DB{main}->Query("
	SELECT	phrase.ID AS IDphrase,
			phrase.word,
			translation.ID AS IDtranslation,
			translation.weight,
			translation.correct,
			translation.domain AS Tdomain,
			translation.domain_sub AS Tdomain_sub,
			phrase.lng AS lng_to
	FROM TOM_clone.aB00_translation AS translation
	LEFT JOIN TOM_clone.aB00_phrase AS phrase
		ON	(
			phrase.ID=translation.IDword_to
			AND (phrase.lng='$lng_to' OR phrase.lng ='')
			AND (phrase.domain ='' OR (phrase.domain='$tom::Hm' AND (phrase.domain_sub ='' OR phrase.domain_sub='$tom::H')))
			)
	WHERE	translation.IDword_from='$db0_line{ID}'
			AND (translation.domain ='' OR (translation.domain='$tom::Hm' AND (translation.domain_sub ='' OR translation.domain_sub='$tom::H')))
			AND phrase.ID
	ORDER BY translation.correct DESC,
			translation.weight DESC,
			translation.domain DESC,
			translation.domain_sub DESC
	$limit");
	while (my %db2_line=$db2->fetchhash())
	{
	 	main::_log("found {$db2_line{word}}") if $debug;
		$count++;
		$db2_line{lng_from}=$db0_line{lng};
	 	push @words,{%db2_line};
	}

	# SLOVO EXISTUJE, ale nema preklad
	# mozno ide o univerzalne slovo/skratku/meno,
	# to mi prezradi ak nottranslated=1 a !$lng_from
	if (!$count)
	{
		my %out=
		(
			word			=>	"$word",
			IDphrase		=>	$db0_line{ID},
			lng_from		=>	$db0_line{lng},
			nottranslated	=>	1,
		);
		push @words,{%out};
	}
 

 }
 else
 {
  	#return undef;
 }

 return @words;
}
 
 
 



sub Phrase_translate_reverse
{
 my @words;
 my $word=shift; # for translation
 return @words if ($word=~/ $/ || !$word);
 
 ##utf8::decode($word) unless utf8::is_utf8($word);
 my $phrase=do{($word=~/ /) ? "AND phrase='Y'" : "AND phrase='N'"};
 
 my %env=@_;
 my $limit=do{($env{limit}) ? "LIMIT ".$env{limit} : undef};
 my $lng_from=$env{from};
 my $lng_to=$env{to}; 
 return undef unless $env{from};
 return undef unless $env{to};
 
 $word=~s|\'|\\'|g;
 
 main::_log("finding phrase_reverse {$word}") if $debug;

 # najdem toto slovo v slovniku
 # prve je to najrelevantnejsie vzhladom k domene
 my $db0=$main::DB{main}->Query("
	SELECT *
	FROM TOM_clone.aB00_phrase
	WHERE 	word='$word'
			AND (lng='$lng_from' OR lng='')
			$phrase
			AND (domain='' OR (domain='$tom::Hm' AND (domain_sub ='' OR domain_sub='$tom::H')))
	ORDER BY domain DESC,domain_sub DESC,lng DESC
	LIMIT 1");
 if (my %db0_line=$db0->fetchhash())
 {

 	main::_log("founded {$word}[$db0_line{ID}]") if $debug;
 
	my $count;
	my $var="
	SELECT	phrase.ID AS IDphrase,
			phrase.word,
			translation.ID AS IDtranslation,
			translation.weight,
			translation.correct,
			translation.domain AS Tdomain,
			translation.domain_sub AS Tdomain_sub,
			phrase.lng AS lng_to
	FROM TOM_clone.aB00_translation AS translation
	LEFT JOIN TOM_clone.aB00_phrase AS phrase
		ON	(
			phrase.ID=translation.IDword_from
			AND (phrase.lng='$lng_to' OR phrase.lng ='')
			AND (phrase.domain ='' OR (phrase.domain='$tom::Hm' AND (phrase.domain_sub ='' OR phrase.domain_sub='$tom::H')))
			)
	WHERE	translation.IDword_to='$db0_line{ID}'
			AND (translation.domain ='' OR (translation.domain='$tom::Hm' AND (translation.domain_sub ='' OR translation.domain_sub='$tom::H')))
			AND phrase.ID
	ORDER BY translation.correct DESC,
			translation.weight DESC,
			translation.domain DESC,
			translation.domain_sub DESC
	$limit";
	#main::_log($var);
        my $db2=$main::DB{main}->Query($var);
	while (my %db2_line=$db2->fetchhash())
	{
		main::_log("found {$db2_line{word}}") if $debug;
		$count++;
		$db2_line{lng_from}=$db0_line{lng};
		$db2_line{reverse}=1;
	 	push @words,{%db2_line};
	}

	# SLOVO EXISTUJE, ale nema preklad
	# mozno ide o univerzalne slovo/skratku/meno,
	# to mi prezradi ak nottranslated=1 a !$lng_from
	if (!$count)
	{
		my %out=
		(
			word			=>	"$word",
			IDphrase		=>	$db0_line{ID},
			lng_from		=>	$db0_line{lng},
			nottranslated	=>	1,
		);
		push @words,{%out};
	}
 

 }

 return @words;
}








sub Phrase_translate_guess
{
 my @words;
 my $word=shift; # for translation
 return @words if ($word=~/ $/ || !$word);
 ##utf8::decode($word) unless utf8::is_utf8($word);
 my $phrase=do{($word=~/ /) ? "AND phrase='Y'" : "AND phrase='N'"};
 
 my %env=@_;
 my $limit_sql=do{($env{limit}) ? "LIMIT ".$env{limit} : "LIMIT 100"};
 my $limit=$env{limit};$limit=100 unless $limit;
 my $lng_from=$env{from};
 my $lng_to=$env{to}; 
 return undef unless $env{from};
 return undef unless $env{to};
 
 
 my %word_keys;
 
 my $count;

 $word=~s|\'|\\'|g;

 
 main::_log("finding phrase_guess {$word}") if $debug;
 
 # najdem toto slovo v slovniku
 # prve je to najrelevantnejsie vzhladom k domene
 my $db0=$main::DB{main}->Query("
	SELECT *
	FROM TOM_clone.aB00_phrase
	WHERE 	word='$word'
			AND (lng='$lng_from' OR lng='')
			$phrase
			AND (domain='' OR (domain='$tom::Hm' AND (domain_sub ='' OR domain_sub='$tom::H')))
	ORDER BY domain DESC,domain_sub DESC,lng DESC
	LIMIT 1");
 if (my %db0_line=$db0->fetchhash())
 {

	main::_log("founded phrase {$word}[$db0_line{ID}]") if $debug;
	#main::_log(9,"found word $word $db0_line{ID}");
	my $var="
	SELECT	phrase.ID AS IDphrase,
			phrase.word,
			translation.ID AS IDtranslation,
			translation.weight,
			translation.correct,
			translation.domain AS Tdomain,
			translation.domain_sub AS Tdomain_sub,
			phrase.lng AS lng_to
	FROM TOM_clone.aB00_translation AS translation
	LEFT JOIN TOM_clone.aB00_phrase AS phrase
	ON	(
		phrase.ID=translation.IDword_to
		AND (phrase.domain ='' OR (phrase.domain='$tom::Hm' AND (phrase.domain_sub ='' OR phrase.domain_sub='$tom::H')))
		)
	WHERE	translation.IDword_from='$db0_line{ID}'
			AND (translation.domain ='' OR (translation.domain='$tom::Hm' AND (translation.domain_sub ='' OR translation.domain_sub='$tom::H')))
			AND phrase.ID
	ORDER BY	translation.correct DESC,
			translation.weight DESC,
			translation.domain DESC,
			translation.domain_sub DESC
	$limit_sql";
			
	#main::_log(9,$var);
	my $db1=$main::DB{main}->Query($var);

	while (my %db1_line=$db1->fetchhash())
	{
		last if $limit<=$count;
		
		#main::_log(9,"found translation $db1_line{IDtranslation} $db1_line{word} $db1_line{lng_to}");
		main::_log("founded trans0 {$db1_line{word}} $db1_line{lng_to}") if $debug;
		
	        my $db2=$main::DB{main}->Query("
		SELECT	phrase.ID AS IDphrase,
				phrase.word,
				translation.ID AS IDtranslation,
				translation.weight,
				translation.correct,
				translation.domain AS Tdomain,
				translation.domain_sub AS Tdomain_sub,
				phrase.lng AS lng_to
		FROM TOM_clone.aB00_translation AS translation
		LEFT JOIN TOM_clone.aB00_phrase AS phrase
		ON	(
			phrase.ID=translation.IDword_to
			AND (phrase.lng='$lng_to' OR phrase.lng ='')
			AND (phrase.domain ='' OR (phrase.domain='$tom::Hm' AND (phrase.domain_sub ='' OR phrase.domain_sub='$tom::H')))
			)
		WHERE	translation.IDword_from='$db1_line{IDphrase}'
				AND (translation.domain ='' OR (translation.domain='$tom::Hm' AND (translation.domain_sub ='' OR translation.domain_sub='$tom::H')))
				AND phrase.ID
		ORDER BY	translation.correct DESC,
				translation.weight DESC,
				translation.domain DESC,
				translation.domain_sub DESC
		$limit_sql");
		while (my %db2_line=$db2->fetchhash())
		{
			main::_log("founded trans1 {$db2_line{word}} $db2_line{lng_to}") if $debug;
			
			next if $word_keys{$db2_line{word}};
			$word_keys{$db2_line{word}}++;
			
			$count++;
			$db2_line{guess}=1;
			$db2_line{lng_cross}=$db1_line{lng_to};
			$db2_line{lng_from}=$db0_line{lng};
			#$db2_line{lng_cross}=$db1_line{lng_to};
			
			last if $limit<=$count;
			push @words,{%db2_line};
			
			
		}
		
	}

	
	if (!$count)
	{
		my %out=
		(
			word			=>	"$word",
			IDphrase		=>	$db0_line{ID},
			lng_from		=>	$db0_line{lng},
			nottranslated	=>	1,
		);
		push @words,{%out};
	}

}

 return @words;
}















 
 
sub Word_find
{
 my $word=shift; # for translation
 return undef unless $word;
 ##utf8::decode($word) unless utf8::is_utf8($word);
 
 my %env=@_;
 my $lng_from=$env{lng};
 return undef unless $env{lng};
 
 my $limit=do{($env{limit}) ? "LIMIT ".$env{limit} : undef};
 
 my @words;

 $word=~s|\'|\\'|g;

 my $count;
 # najdem toto slovo v slovniku
 # prve je to najrelevantnejsie vzhladom k domene
 my $db0=$main::DB{main}->Query("
	SELECT *
	FROM TOM_clone.aB00_phrase
	WHERE 	word='$word'
			AND (lng='$lng_from' OR lng ='')
			AND (domain ='' OR (domain='$tom::Hm' AND (domain_sub ='' OR domain_sub='$tom::H')))
	ORDER BY domain DESC,domain_sub DESC,lng DESC
	$limit");
 while (my %db0_line=$db0->fetchhash())
 {
 	$count++;
	push @words,{%db0_line};
 }
 
#=head1
 if (!$count)
 {
	my %out=
	(
		ID			=>	0,
		notfound		=>	1,
	);
	push @words,{%out};
 }
#=cut
 
 return @words}







 
 
 
 
 
sub Correction
{
 my $sequence=shift; # for translation
 #return undef unless $sequence; 
 return undef unless $sequence=~/;/;
 my %env=@_;
 my $lng=$env{lng}; 
 return undef unless $env{lng};
 
 my @words;
 my $count;

 
 main::_log("finding Correction [$sequence]") if $debug;
 
 
 # najdem toto slovo v slovniku
 # prve je to najrelevantnejsie vzhladom k domene
 my $db0=$main::DB{main}->Query("
	SELECT *
	FROM TOM_clone.aB00_correction
	WHERE 	phrase='$sequence'
			AND (translation_lng='$lng' OR translation_lng ='')
			AND (domain ='' OR (domain='$tom::Hm' AND (domain_sub ='' OR domain_sub='$tom::H')))
	ORDER BY domain DESC,domain_sub DESC,correct DESC, weight DESC");
 while (my %db0_line=$db0->fetchhash())
 {
  	$count++;
  	push @words,{%db0_line};
 }

 return @words;
}
 
 
 
 
 
 
 
 
 








1;