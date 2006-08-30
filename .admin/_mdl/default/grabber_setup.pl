#!/bin/perl
# USE UTF-8 !!!
use Text::Iconv;
use Time::Local;
use Mysql;

$T_SRV="192.168.1.20";
$S_SRV="192.168.1.20";

$T_DB="markiza";
$S_DB="markiza_sk";

$S_USR="TOM";
$S_PWD="kulume";

$T_USR="webcom";
$T_PWD="plaque";

# CONNECT TARGET
$T_DBase=Mysql->Connect($T_SRV,$T_DB,$T_USR,$T_PWD);
$T_DBase->SelectDB($T_DB);
print "Connected to T\n";
# CONNECT SOURCE
$S_DBase=Mysql->Connect($S_SRV,$S_DB,$S_USR,$S_PWD);
$S_DBase->SelectDB($S_DB);
print "Connected to S\n";

# Delete sheduled grabs !
if (1)	# BLOCK COMMENT !!!!
{
print "DELETING SHEDULED GRABS !!!\n";
	$time=time;
# markiza.tv_archiv clear
	$T_DBase->Query('DELETE FROM tv_archiv WHERE id_event<"5000"');
# markiza.event clear
	$T_DBase->Query('DELETE FROM event WHERE id_event<"5000"');
# markiza_sk.a020_archiv clear
	$S_DBase->Query('DELETE FROM a020_archiv WHERE time_from>"'.$time.'"');
}


# GET Archive data from a020,a021 considering a020.rec_live
$Res = $S_DBase->Query('SELECT p.ID_cat,p.start_stamp,p.end_stamp,c.short,c.name,substring(c.rec_live,p.day,1) as live FROM a021_program as p, a020_cat as c
	WHERE p.start_stamp>"'.time().'" AND c.ID=p.ID_cat AND substring(c.rec_live,p.day,1)>"0" ORDER BY p.start_stamp');

# Set grabber !
$cnt=1;
if (1)
{
print "SHEDULING NEW GRABS !!!\n";
	while (%Line = $Res->FetchHash)
	{
		@TIME = localtime($Line{start_stamp});
		@TIME_TO = localtime($Line{end_stamp}+60*5);
		$Time=sprintf("_%02d_%02d_%04d.asf",$TIME[3],$TIME[4],$TIME[5]+1900);
		$file=$Line{short}.$Time;
		$file="live.asf" if ($Line{live}>1);
		$Line{ID_cat}=1 if ($Line{live}>1);

		print "CAT=$Line{ID_cat}, ST=$Line{start_stamp}, SE=$Line{end_stamp}, SHORT=$Line{short}, NAME=$Line{name}, FILE=$file, LIVE=$Line{live}\n";

# a020_arch zaznam na markiza_sk
		$S_DBase->Query('INSERT INTO a020_archiv (ID_cat, video_file, time_from, time_to,description,ID_old) VALUES
			("'.$Line{ID_cat}.'","'.$file.'","'.$Line{start_stamp}.'","'.$Line{end_stamp}.'","'.$Line{name}.'","'.$cnt.'")') or print "ERROR: a020_archiv";

# FAKE tv_archiv v starej DB
#		$T_DBase->Query('INSERT INTO tv_archiv (id_event,id_category,id_relacie,file_asf,datetime_from,datetime_to) VALUES
#			("'.$cnt.'","1","1","'.$file.'","'.$Line{start_stamp}.'","'.($Line{end_stamp}+60*5).'")') or print "ERROR: tv_archiv";

# FAKE event v starej DB
#		$T_DBase->Query('INSERT INTO event (id_event, id_type_event, id_org, name,date_from,date_to,time_from,time_to,description,archiv) VALUES
#			("'.$cnt.'","1","1","WebCom Grab","'.sprintf("%04d-%02d-%02d",$TIME[5]+1900,$TIME[4],$TIME[3]).'","'.sprintf("%04d-%02d-%02d",$TIME_TO[5]+1900,$TIME_TO[4],$TIME_TO[3]).'","'.sprintf("%02d:%02d:00",$TIME[2],$TIME[1]).'","'.sprintf("%02d:%02d:00",$TIME_TO[2],$TIME_TO[1]).'","","1")') or print "ERROR: event";

# Count dava ID-cka do starej DB (moze byt 0-5000 kedze autoincrement tam bezi od ~6400)
		$cnt++;
	}
}
