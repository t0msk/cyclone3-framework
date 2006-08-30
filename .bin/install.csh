#! /bin/csh -f
# AUTO LINK SCRIPT :)
# by Taker 25.7.2003

# Logging
echo "Auto Linking ..."

# Test Destination DIR
set TO = "/usr/bin"
if (! -d "$TO") then
	echo "Destination directory NOT found !"
	exit
endif

# Test Source DIR
set FROM = "$cwd"
if (! -d "$FROM") then
	echo "Source directory NOT found !"
	exit
endif

# Get ALL filez
set filez = `find "$FROM" -type f`


# Get ALL linkz
set linkz = `find "$TO" -type l`

# REMOVES BROKEN LINKZ :)
foreach link ($linkz)
	if ( ! -e "$link" ) then
		echo "REMOVED: $link << BROKEN LINK!"
		rm -f "$link"
	endif
end

# LOOP
foreach file ($filez)

	if (  -x "$file" && $file:t != $0:t) then 

		if ( -e "$TO/$file:t" ) then
			echo "SKIPED: $file => $TO/$file:t << LINK EXISTS!" 
			continue 
		endif
	
		ln -s "$file" "$TO/$file:t"#  >&! install.log
		
		if ( ! -e "$TO/$file:t" ) then 
			echo "FAILED: $file => $TO/$file:t << ERROR!"
			continue 
		endif
		
		echo "LINKED: $file => $TO/$file:t << OK!"
	endif
	
end

# ALL OK
echo "DONE."
