package Utils::vars;

BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}

use strict;

our @WCHAR=qw/0 1 2 3 4 5 6 7 8 9 A B C D E F G H I J K L M N O P Q R S T U V W X Y Z a b c d e f g h i j k l m n o p q r s t u v w x y z/;
our @NUCHAR=qw/0 1 2 3 4 5 6 7 8 9 A B C D E F G H I J K L M N O P Q R S T U V W X Y Z/;
our @NCHAR=qw/0 1 2 3 4 5 6 7 8 9/;
our @UCHAR=qw/A B C D E F G H I J K L M N O P Q R S T U V W X Y Z/;
our @LCHAR=qw/a b c d e f g h i j k l m n o p q r s t u v w x y z/;
our $debug=0;

# na nahodne generovanie hashu
# s vyuzitim WCHAR
sub genhash
{my $var;
 for (1..$_[0]){$var.=$WCHAR[int(rand(61))];}
 return $var;}

sub genhash_NU
{my $var;
 for (1..$_[0]){$var.=$NUCHAR[int(rand(35))];}
 return $var;}
 
sub genhash_N
{my $var;
 for (1..$_[0]){$var.=$NCHAR[int(rand(10))];}
 return $var;}


sub replace # toto sa naozaj este pouziva!!! a dost casto!
{
 #no strict;
 
 #print "robim replace\n" if $main::debug;
 
 for (@_)
 {
  while ($_=~s/<\$(.{2,100}?)>/<!TMP!>/) # MAXIMALNE 100 znakova premmenna
  {
   my $value;#=$$1;
   my $var=$1;
   
   #print "var $var $value\n" if $main::debug;

   if ($var=~/(sub\{|do\{|&|\+|\-|\*|\/|=|"|\||;)/)
   #if ($var=~/(sub|do|&)/)
   {
    main::_log("VAZNY PRIENIK ZAMENY PREMENNEJ \"".
	$var.
	"\" z $main::ENV{'REMOTE_ADDR'} s $main::ENV{'QUERY_STRING'} ",1,"secure");
    $var="***";
    # TUTO POSLAT OZNAMENIE O TOMTO ERRORE!!
   }
   
   #print ">var $var $value\n" if $main::debug;
   eval "\$value=\$$var;";
   #print "<var $var $value\n" if $main::debug;
   
   $_=~s|<!TMP!>|$value|;
  }
 }
 #use strict;
}

=head1
sub replace_long
{
 no strict;
 for (@_)
 {
  while ($_=~s/<\$(.*?)>/<!TMP!>/)
  {
   my $value=$$1;
   #eval "\$value=\$$var;";
   $_=~s|<!TMP!>|$value|;
  }
 }
 use strict;
}
=cut





sub cHash
{
	my $hash=shift;
	my $where=shift;
	my $what;#=shift;
	
	
	return undef if $where=~/[^\w\d\[\]\{\}]/;
	
#=head1
	my $where_p=$where;
	while (1)
	{
		print "	+control $where_p\n" if $debug;
		last unless $where_p=~s/(.*)(\{.*?\}|\[.*?\])$/$1/;	
		eval "if (not ref(\${\$hash}$where_p)){undef \${$hash}$where_p;}";
		last unless $@;
	}
#=cut
	
	my $where_p=$where;
	while ($where_p=~s/(.*)(\{.*?\}|\[.*?\])$/$1/)
	{
		my $deleted=$2;
		
		last unless $where_p;
		
		print "	+ control $where_p/$deleted\n" if $debug;
		$deleted=do{($deleted=~/]$/)?'ARRAY':'HASH'};
		print "	 + i need $deleted\n" if $debug;
		#print "	+control $where_p/$deleted, mame tu ".$deleted."\n";
		
		my $original;eval "\$original=ref(\${\$hash}$where_p)";
		print "	 + have $original\n" if $debug;
		
		#last unless $where_p;
		#next unless $original;
		
		if ($original ne $deleted)
		{
			print "undef \${\$hash}$where_p;\n" if $debug;
			eval "undef \${\$hash}$where_p;";
			die $@ if $@;
		}
	}
}








1;
