#!/bin/perl
package conv;

BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}

sub conv
{
	local	$FROM=$_[0];
	local	$TO=$_[1];
	local	$DATA=$_[2];
	local $RET="";
	
	pipe	(INPUT,OUTPUT);
	local $pid=fork();
	
	if($pid!=0)
	{
		#	PARENT
		close OUTPUT;
		wait();
		while (<INPUT>)
		{
			$RET.=$_;
		}
		return $RET;
	}
	else
	{
		#	CHILD
		close (INPUT);
		
		pipe (INPUT2,OUTPUT2);
		local $pid2=fork();
		
		if ($pid2!=0)
		{
			#	CHILD/PARENT
			close (OUTPUT2);
						
			wait();
			open(STDIN, "<&INPUT2");
			open(STDOUT,">&OUTPUT");
			exec (("iconv","-f",$FROM,"-t",$TO,"-s","-c"));
			exit(0);
		}
		else
		{
			#	CHILD/CHILD
			close (INPUT2);
			
			print OUTPUT2 ($DATA);
			exit(0);
		}
	}
}    

1;
