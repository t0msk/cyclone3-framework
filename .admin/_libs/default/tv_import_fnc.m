#!/bin/perl
# USE UTF-8 !!!

## Deboot :
##	Check	17 => treba zistit aky je :( char v utf8 ... (mal som len cp1250 takze to neviem)
##		160-167 => Input
##		287 => Output

#package Tomahawk::module;
#use Text::Iconv;
#use Time::Local;
#use Mysql;

# Character before rating score ;)
$RATING_CHAR='L';

# DB SETUP
my $SRV="192.168.1.20";
my $DB="markiza_sk";
my $USR="TOM";
my $PWD="kulume";

my $DBase=Mysql->Connect($SRV,$DB,$USR,$PWD);
$DBase->SelectDB($DB);

# Convert DayOfWeek 2 Number index
sub DOW2NUM
{
my $day=$_[0];
if($day=~/PON/i){return 1;}
if($day=~/UTO/i){return 2;}
if($day=~/STR/i){return 3;}
if($day=~/RTOK/i){return 4;}
if($day=~/PIAT/i){return 5;}
if($day=~/SOBO/i){return 6;}
if($day=~/NEDE/i){return 7;}
return -1;
}

# Find Station ID
sub FINDSTATIONID
{
	my $Res=$DBase->Query("SELECT * FROM a021_tv");
	while (my %Line = $Res->FetchHash)
	{
		if (($Line{short}=~/$_[0]/) || ($Line{search}=~/$_[0]/) || ($Line{name}=~/$_[0]/))
		{
			return $Line{ID};
		}
	}
	return -1;
}

# Dump Station Data for given day :)
sub DUMPSTATION
{
	# Input
	my $DATE_STAMP=$_[0];
	my $STATION_ID=$_[1];

	# Execute
	my $Res=$DBase->Query("DELETE FROM a021_program_old WHERE ID_tv='$STATION_ID' AND datestamp='$DATE_STAMP'");
}

# Find ok make new category 4 ID_TV=0000 !
sub FINDMAKECAT
{
	my $CAT_NAME=PREP($_[0]);
	# Fook counts
	$CAT_NAME=~s| (.*?)/(.*?) ||g;
#	$CAT_NAME=~s| \w\w?\w? ||g;

	my $Res=$DBase->Query("SELECT * FROM a020_cat WHERE name LIKE '$CAT_NAME' OR keywords LIKE '$CAT_NAME' OR short LIKE '$CAT_NAME' LIMIT 1");
	while (my %Line = $Res->FetchHash)
	{
		return $Line{ID};
	}
	$Res=$DBase->Query("INSERT INTO a020_cat ( name, short, keywords ) VALUES ( '$CAT_NAME', '$CAT_NAME', '$CAT_NAME')");
	return $Res->insert_id;

}


# Prepare string before insert
sub PREP
{
	my $RET=$_[0];
	$RET=~s/'/\\'/g;
	$RET=~s|\s| |g;
	$RET=~s|\s$||;
	$RET=~s|^\s||;
	$RET=~s/<#NL#>/ /g;
	return $RET;
}

# Insert new TV event
sub INSERTEVENT
{
	# Input
	my $ID_TV=$_[0];
	my $NAME=$_[1];
	my $HOUR=$_[2];
	my $MIN=$_[3];
	my $END_HOUR=$_[4];
	my $END_MIN=$_[5];
	my $DESCR=$_[6];
	my $RATING=$_[7];
	my $MIDNIGHT=$_[8];
	my $RATING=$_[9];
	my $DAY=$_[10];
	my $DATE_STAMP=$_[11];
	my $SOUND=$_[12];

	# Deduction
	my $ID_CAT=0;
	my $IS_THERE='N';
	if ($HOUR>$END_HOUR) { $END_HOUR+=24; }
	my $LENGTH=($END_HOUR-$HOUR)*60+($END_MIN-$MIN);
	my $START_STAMP=$DATE_STAMP+$HOUR*3600+$MIN*60;
	my $END_STAMP=$START_STAMP+$LENGTH*60;
	if ($MIDNIGHT) { $MIDNIGHT='Y'; $START_STAMP+=24*3600; $END_STAMP+=24*3600} else { $MIDNIGHT=''; }

	# Find CAT 4 markiza !
	if ($ID_TV=="0000") { $ID_CAT = FINDMAKECAT($NAME); }

	# Insert
	my $Res=$DBase->Query("INSERT INTO a021_program
				(ID_tv
				,ID_cat
				,name
				,isthere
				,sound
				,day
				,datestamp
				,start_hour
				,start_min
				,description
				,rating
				,midnight
				,start_stamp
				,end_stamp
				,length)
				VALUES
				('$ID_TV'
				,'$ID_CAT'
				,'".PREP($NAME)."'
				,'$IS_THERE'
				,'".PREP($SOUND)."'
				,'$DAY'
				,'$DATE_STAMP'
				,'$HOUR'
				,'$MIN'
				,'".PREP($DESCR)."'
				,'$RATING'
				,'$MIDNIGHT'
				,'$START_STAMP'
				,'$END_STAMP'
				,'$LENGTH')");
}
