#!/bin/bash

# This script will download any new updates from the web space and replace older versions.
# v1.0.3
# Written by Chris Shafer - Christopher.Shafer@cwu.edu

# Changelog
# 24/1/2023: added -q to wget and removed unnecessary rms.
# 25/1/2023: added variable path support for setup script.
# 26/1/2023: Added more complex modular support and hash checking.
#
# Note to self: I need to add hash support to this so that we check files on updates.

# Adding support in for script.config.
counter=0
declare filename=$(locate script.config)
while read -r line;do
	if [[ $counter == 0 ]];then
		declare path=$line
		((counter++))
	else
		declare user=$line
	fi
done < "$filename"

cd $path

# Remove previous files.
rm ./sys-maint.sh
rm ./startup.sh
rm ./get-updates.sh
rm ./md5-hashes

# Aquire new files
wget -q http://192.168.1.54/sys-maint.sh
wget -q http://192.168.1.54/startup.sh
wget -q http://192.168.1.54/get-updates.sh
wget -q http://192.168.1.54/md5-hashes

# Change ownership to get it away from root
chown "$user" sys-maint.sh
chown "$user" startup.sh
chown "$user" get-updates.sh
chown "$user" md5-hashes

# Change permissions to get it to match the originals in all ways. Technically
# I might only need to do this on startup.sh as sys-maint.sh is activated via
# the cron.
chmod u+x sys-maint.sh
chmod u+x startup.sh

echo "Scripts updated successfully."

# It seems to me that I have to redeclare the str variable a lot. I should consider
# reworking the organization to be by file instead of by function. It would run faster
# if I did.

# Now we should grab the MD5's to make sure everything is kosher and alert the admins if not.
str=$path"/get-updates.sh"
hashupdate=$(md5sum $str | cut -f 1 -d " ")
str=$path"/startup.sh"
hashstartup=$(md5sum $str | cut -f 1 -d " ")
str=$path"/sys-maint.sh"
hashsysmaint=$(md5sum $str | cut -f 1 -d " ")

# Now we'll loop through our md5 hash file and make sure everything matches. If not, we need
# to alert the admins.
counter=0
str=$path"/md5-hashes"
while read -r line;do
	declare hash$counter=$line
	((counter++))
done < "$str"

# Compare and contrast the results. We only need to respond to something if it is wrong.
error=0

if [[ $hash0 != $hashupdate ]]; then
	declare error=1
fi

if [[ $hash2 != $hashstartup ]]; then
	declare error=1
fi

if [[ $hash3 != $hashsysmaint ]]; then
	declare error=1
fi

# Now at last, we alert the admins. Until I learn more, we're going to throw it in the MOTD
# where it should be hard to miss.
if [[ $error == 1 ]]; then
	echo "Something went wrong updating Daknit's scripts! (Hash Mismatch)" >> /etc/motd
fi

cd /
