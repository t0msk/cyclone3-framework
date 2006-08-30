#!/bin/perl
# USE UTF-8 !!!
use Text::Iconv;
use Time::Local;
use Mysql;

sub SetGrab
{
	my $ID=$_[0];
	my $T_SRV="192.168.1.20";
	my $S_SRV="192.168.1.20";

	my $T_DB="markiza";
	my $S_DB="markiza_sk";

	my $S_USR="TOM";
	my $S_PWD="kulume";

	my $T_USR="webcom";
	my $T_PWD="plaque";

	# CONNECT TARGET
	my $T_DBase=Mysql->Connect($T_SRV,$T_DB,$T_USR,$T_PWD);
	$T_DBase->SelectDB($T_DB);

	# CONNECT SOURCE
	my $S_DBase=Mysql->Connect($S_SRV,$S_DB,$S_USR,$S_PWD);
	$S_DBase->SelectDB($S_DB);

	# GET ALL INFO
	my $Res=$S_DBase->Query('SELECT * FROM a020_archiv WHERE ID='.$ID);
	while (my %Line=$Res->FetchHash)
	{
		# FAKE tv_archiv v starej DB
		my $file=$Line{video_file};
#		$file=~s|(.*?)_(.*?)_(.*?)_(.*?)|$1_$3_$2_$4|; # GRABBER KAZI DATUM !!!

          #-----------------------------------------------adding 5 more minutes
		#$T_DBase->Query('REPLACE INTO tv_archiv (id_event,id_category,id_relacie,file_asf,datetime_from,datetime_to) VALUES
		#	("'.$ID.'","1","1","'.$file.'","'.$Line{time_from}.'","'.($Line{time_to}+60*5).'")');
		$T_DBase->Query('REPLACE INTO tv_archiv (id_event,id_category,id_relacie,file_asf,datetime_from,datetime_to) VALUES
			("'.$ID.'","1","1","'.$file.'","'.$Line{time_from}.'","'.($Line{time_to}).'")');

		# FAKE event v starej DB
		@TIME = localtime($Line{time_from});
          #-----------------------------------------------adding 5 more minutes
		#@TIME_TO = localtime($Line{time_to}+60*5);
          @TIME_TO = localtime($Line{time_to});
		$T_DBase->Query('REPLACE INTO event (id_event, id_type_event, id_org, name,date_from,date_to,time_from,time_to,description,archiv) VALUES
			("'.$ID.'","1","1","WebCom Grab","'.sprintf("%04d-%02d-%02d",$TIME[5]+1900,$TIME[4]+1,$TIME[3]).'","'.sprintf("%04d-%02d-%02d",$TIME_TO[5]+1900,$TIME_TO[4]+1,$TIME_TO[3]).'","'.sprintf("%02d:%02d:00",$TIME[2],$TIME[1]).'","'.sprintf("%02d:%02d:00",$TIME_TO[2],$TIME_TO[1]).'","","1")');
	}
}

sub RmGrab
{
	my $ID=$_[0];
	my $T_SRV="192.168.1.20";
	my $S_SRV="192.168.1.20";

	my $T_DB="markiza";
	my $S_DB="markiza_sk";

	my $S_USR="TOM";
	my $S_PWD="kulume";

	my $T_USR="webcom";
	my $T_PWD="plaque";

	# CONNECT TARGET
	my $T_DBase=Mysql->Connect($T_SRV,$T_DB,$T_USR,$T_PWD);
	$T_DBase->SelectDB($T_DB);

	# CONNECT SOURCE
	my $S_DBase=Mysql->Connect($S_SRV,$S_DB,$S_USR,$S_PWD);
	$S_DBase->SelectDB($S_DB);

	# REMOVE
	$S_DBase->Query('DELETE FROM a020_archiv WHERE ID='.$ID);
	$T_DBase->Query('DELETE FROM event WHERE id_event='.$ID);
	$T_DBase->Query('DELETE FROM tv_archiv WHERE id_event='.$ID);
}

# Zmaze vsetky zaznamy v graberi od casu vescieho ako argument
sub DelGrabsFrom
{
	my $From=$_[0];
	my $To=$_[1];

	if ($From < time) { return; }

	# DB SETUP
	my $T_SRV="192.168.1.20";
	my $S_SRV="192.168.1.20";
	my $T_DB="markiza";
	my $S_DB="markiza_sk";
	my $S_USR="TOM";
	my $S_PWD="kulume";
	my $T_USR="webcom";
	my $T_PWD="plaque";
	my $T_DBase=Mysql->Connect($T_SRV,$T_DB,$T_USR,$T_PWD);
	$T_DBase->SelectDB($T_DB);
	my $S_DBase=Mysql->Connect($S_SRV,$S_DB,$S_USR,$S_PWD);
	$S_DBase->SelectDB($S_DB);
	my $Res;

     if ($To) { $Res=$S_DBase->Query('SELECT ID FROM a020_archiv WHERE time_from>'.$From . ' AND time_to <'.$To); }
	else     { $Res=$S_DBase->Query('SELECT ID FROM a020_archiv WHERE time_from>'.$From); }

	# DELETE ALL PRESET GRABS !
	#$Res=$S_DBase->Query('SELECT ID FROM a020_archiv WHERE time_from>'.$From);
	while (my %Line=$Res->FetchHash)
	{
		#print("DEL >> $Line{ID}\n");
		RmGrab($Line{ID});
	}
}

# Automaticky naplni grabber od casu (timestamp) , ktory ma ako argument
sub ScheduleGrabs
{
	my $From=$_[0];

	if ($From < time) { return; }

	# DB SETUP
	my $T_SRV="192.168.1.20";
	my $S_SRV="192.168.1.20";
	my $T_DB="markiza";
	my $S_DB="markiza_sk";
	my $S_USR="TOM";
	my $S_PWD="kulume";
	my $T_USR="webcom";#
	my $T_PWD="plaque";
	my $T_DBase=Mysql->Connect($T_SRV,$T_DB,$T_USR,$T_PWD);
	$T_DBase->SelectDB($T_DB);
	my $S_DBase=Mysql->Connect($S_SRV,$S_DB,$S_USR,$S_PWD);
	$S_DBase->SelectDB($S_DB);
	my $Res;

	# DELETE ALL PRESET GRABS !
	DelGrabsFrom($From);

	# GET DATA
	$Res = $S_DBase->Query('SELECT p.ID_cat,p.start_stamp,p.end_stamp,p.midnight,c.short,c.name,substring(c.rec_live,p.day,1) as live
		FROM a021_program as p, a020_cat as c	WHERE p.start_stamp>"'.$From.'" AND c.ID=p.ID_cat AND substring(c.rec_live,p.day,1)>"0"
		ORDER BY p.start_stamp');

	while (%Line = $Res->FetchHash)
	{
		#my @TIME = localtime($Line{start_stamp});

		my @TIME;
		if ($Line{midnight} eq "Y") { @TIME = localtime($Line{start_stamp}-86400); } else { @TIME = localtime($Line{start_stamp}); }
		my $Time=sprintf("_%02d_%02d_%04d.asf",$TIME[3],$TIME[4]+1,$TIME[5]+1900);

		my $file=$Line{short}.$Time;
		$file="live-$Line{start_stamp}.asf" if ($Line{live}>1);
		$Line{ID_cat}=0 if ($Line{live}>1);
		#print "CAT=$Line{ID_cat}, ST=$Line{start_stamp}, SE=$Line{end_stamp}, SHORT=$Line{short}, NAME=$Line{name}, FILE=$file, LIVE=$Line{live}: TIME=".sprintf("%02d:%02d:00",$TIME[2],$TIME[1])."\n";

		my $Res2=$S_DBase->Query('INSERT INTO a020_archiv (ID,ID_cat, video_file, time_from, time_to, midnight, description) VALUES
			("","'.$Line{ID_cat}.'","'.$file.'","'.$Line{start_stamp}.'","'.$Line{end_stamp}.'","'.$Line{midnight}.'","'.$Line{name}.'")') or print "ERROR: a020_archiv";
		my $id = $Res2->insert_id;
		SetGrab($id);
#		@TIME = localtime($Line{start_stamp});
#		$Time=sprintf("_%02d_%02d_%04d.asf",$TIME[3],$TIME[4]+1,$TIME[5]+1900);

		# po polnoci len live !!
#		$Line{live}=2 if ($Line{midnight}=="Y" && $Line{live}==1);

#		$file=$Line{short}.$Time;
#		$file="live.asf" if ($Line{live}>1);
#		$Line{ID_cat}=0 if ($Line{live}>1);
		#print "CAT=$Line{ID_cat}, ST=$Line{start_stamp}, SE=$Line{end_stamp}, SHORT=$Line{short}, NAME=$Line{name}, FILE=$file, LIVE=$Line{live}: TIME=".sprintf("%02d:%02d:00",$TIME[2],$TIME[1])."\n";

#		$Res2=$S_DBase->Query('INSERT INTO a020_archiv (ID,ID_cat, video_file, time_from, time_to,description) VALUES
#			("","'.$Line{ID_cat}.'","'.$file.'","'.$Line{start_stamp}.'","'.$Line{end_stamp}.'","'.$Line{name}.'")') or print "ERROR: a020_archiv";
#		$id = $Res2->insert_id;
#		SetGrab($id);
	}
}

sub ScheduleGrabsFromTo
{
	my $From=$_[0];
	my $To=$_[1];

	if (($From < time) || ($To < time) || ($From > $To)) { return; }

	# DB SETUP
	my $T_SRV="192.168.1.20";
	my $S_SRV="192.168.1.20";
	my $T_DB="markiza";
	my $S_DB="markiza_sk";
	my $S_USR="TOM";
	my $S_PWD="kulume";
	my $T_USR="webcom";
	my $T_PWD="plaque";
	my $T_DBase=Mysql->Connect($T_SRV,$T_DB,$T_USR,$T_PWD);
	$T_DBase->SelectDB($T_DB);
	my $S_DBase=Mysql->Connect($S_SRV,$S_DB,$S_USR,$S_PWD);
	$S_DBase->SelectDB($S_DB);
	my $Res;

	open ($log,">/var/www/TOM/!markiza.sk/!spravy/!admin/grabber.log");
	print ($log,"G1: $From-$To");

	# DELETE ALL PRESET GRABS !
	DelGrabsFrom($From,$To);

	print ($log,"G2: $From-$To");

	# GET DATA
	$Res = $S_DBase->Query('SELECT p.ID_cat,p.start_stamp,p.end_stamp,p.day,p.midnight,c.short,c.name,c.rec_live,substring(c.rec_live,p.day,1) as live
		FROM a021_program as p, a020_cat as c	WHERE p.start_stamp>"'.$From.'" AND p.start_stamp<"'.$To.'" AND c.ID=p.ID_cat AND substring(c.rec_live,p.day,1)>"0"
		ORDER BY p.start_stamp');

	while (my %Line = $Res->FetchHash)
	{
		#my @TIME = localtime($Line{start_stamp});

		my @TIME;
		if ($Line{midnight} eq "Y") { @TIME = localtime($Line{start_stamp}-86400); $Line{live}=substr $Line{rec_live},($Line{day}-1),1; } else { @TIME = localtime($Line{start_stamp}); }
		my $Time=sprintf("_%02d_%02d_%04d.asf",$TIME[3],$TIME[4]+1,$TIME[5]+1900);

		my $Time=sprintf("_%02d_%02d_%04d.asf",$TIME[3],$TIME[4]+1,$TIME[5]+1900);

		my $file=$Line{short}.$Time;
		$file="live-$Line{start_stamp}.asf" if ($Line{live}>1);
		$Line{ID_cat}=0 if ($Line{live}>1);
		#print "CAT=$Line{ID_cat}, ST=$Line{start_stamp}, SE=$Line{end_stamp}, SHORT=$Line{short}, NAME=$Line{name}, FILE=$file, LIVE=$Line{live}: TIME=".sprintf("%02d:%02d:00",$TIME[2],$TIME[1])."\n";

		my $Res2=$S_DBase->Query('INSERT INTO a020_archiv (ID,ID_cat, video_file, time_from, time_to, midnight, description) VALUES
			("","'.$Line{ID_cat}.'","'.$file.'","'.$Line{start_stamp}.'","'.$Line{end_stamp}.'","'.$Line{midnight}.'","'.$Line{name}.'")') or print "ERROR: a020_archiv";
		my $id = $Res2->insert_id;
		SetGrab($id);
	}
}

our $Video_Path="/disk/video/";

# dostava cas do kedy ma robit upravy
sub CheckArch
{
	my $From=$_[0];
	# DB SETUP
	my $S_SRV="192.168.1.20";
	my $S_DB="markiza_sk";
	my $S_USR="TOM";
	my $S_PWD="kulume";

	my $S_DBase=Mysql->Connect($S_SRV,$S_DB,$S_USR,$S_PWD);
	#$S_DBase->SelectDB($S_DB);
	my $Res;

	# GET DATA
	$Res = $S_DBase->Query('SELECT * FROM a020_archiv WHERE time_to <'.$From.' AND active ="Y"');

	while (%Line = $Res->FetchHash)
	{
		if (-e $Video_Path.$Line{video_file})
		{
#			print "$Line{video_file} >> OK\n";
               if ($Line{active} eq 'N')
			{ $S_DBase->Query('UPDATE `a020_archiv` SET active="Y" WHERE ID="'.$Line{ID}.'" LIMIT 1'); }
		}
		else
		{
#			print "$Line{video_file} >> NOT FOUND! >> DEACTIVATING\n";
			$S_DBase->Query('UPDATE `a020_archiv` SET active="N" WHERE ID="'.$Line{ID}.'" LIMIT 1');

		}
	}
     return 1;
}

1;
