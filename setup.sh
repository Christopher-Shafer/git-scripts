#!/bin/bash

# This script will download and install my scripts. This command must be run as root.
# v1.1.1
# Written by Chris Shafer - Christopher.Shafer@cwu.edu
#
# Syntax: sudo bash setup.sh <directory where scripts will live>
# ex sudo bash setup.sh /home/daknit/scripts daknit

# We'll store the entered arguments. Eventually I will need to transfer that info to
# the other files when they are created instead of hardcoding my file paths and username.
#
# 25/1/2023: Added hash verification and more comments.
# 27/1/2023: Now uses github so we can get off the intranet.

# In order to make the other scripts more modular, we're making a script.config file which
# the other scripts can loop through to get their path and user variables.

path=$1
user=$2

# If they are installing my scripts anyways, they'll get sys-maint, so we will run that
# quickly just to make sure everything is ready before we start.

echo "Running updates and upgrades. This process may take several minutes."
apt-get -y update
apt-get -y upgrade
apt-get -y autoremove
apt-get -y autoclean
apt-get install -y plocate
echo "System is ready."

mkdir $path
chown $user $path

# Get the scripts and MD5 hashes file
echo "Downloading scripts."

wget -q http://daknit.github.io/git-scripts/startup.sh
wget -q http://daknit.github.io/git-scripts/sys-maint.sh
wget -q http://daknit.github.io/git-scripts/get-updates.sh
wget -q http://daknit.github.io/git-scripts/md5-hashes
echo "Downloads complete."
# Move everything that we just downloaded where our user specified and cleanup the
# originals.

# Here we're going to make the config file so we can move it in bulk with the rest.
# I'm a dumb though and the way I made this, it will be created where needed and so we
# can skip moving it. Oh well.
echo "Generating config file."

str=$path"/script.config"
touch $str
echo "$path" >> $str
echo "$user" >> $str

echo "Config file ready."


# Since the file has to be run by root, we'll change each file to be owned by the user
# specified during execution of the script. We'll also change some to be executable.
echo "Twiddling with the files"

chown $user startup.sh
chmod u+x startup.sh
chown $user sys-maint.sh
chmod u+x sys-maint.sh
chown $user get-updates.sh
chown $user md5-hashes
str=$path"/script.config"
chown $user $str

echo "Mmm, thats some good twiddling!"

# Now we move the scripts to their homes.
echo "Moving scripts to specified location"
mv startup.sh $path
mv sys-maint.sh $path
mv get-updates.sh $path
mv md5-hashes $path
echo "Files moved successfully!"

# Now we need to deal with scheduling the update and system maintenance plus the startup script.
echo "Setting up the cron"

crontab -l > mycron
str=$path"/get-updates.sh"
echo "59 23 * * * bash $str" >> mycron
str=$path"/sys-maint.sh"
echo "0 0 * * * bash $str" >> mycron
crontab mycron
rm mycron

echo "Time has been successfully altered."

# The startup script isn't so easy. I decided on rc.local but kali linux does not have this
# enabled by default, while Ubuntu does. Therefore, we'll check if the file exists. If it
# isn't enabled, there is probably not a file. If this assumption is wrong, strange behavior
# could result.

# Does the rc.local file exist? If so, we'll add our script execution in before exit 0.
# If not, we're going to have to make it, populate it, and activate the server.

echo "Setting up startup file to launch on system boot."
if test -f "/etc/rc.local";then
str=$path"/startup.sh"
	sed -i -e '$i \bash '$str'\n' /etc/rc.local
else
# Make the file.
	touch /etc/rc.local
str=$path"/startup.sh"
# Populate the file.
	echo "#!/bin/bash" >> /etc/rc.local
	echo "" >> /etc/rc.local
	echo "bash $str" >> /etc/rc.local
	echo "" >> /etc/rc.local
	echo "exit 0" >> /etc/rc.local
# Now we'll set up the service.
	echo "[Unit]" >> /etc/systemd/system/rc-local.service
	echo "Description=/etc/rc.local Compatibility" >> /etc/systemd/system/rc-local.service
	echo "ConditionPathExists=/etc/rc.local" >> /etc/systemd/system/rc-local.service
	echo "" >> /etc/systemd/system/rc-local.service
	echo "[Service]" >> /etc/systemd/system/rc-local.service
	echo "Type=forking" >> /etc/systemd/system/rc-local.service
	echo "ExecStart=/etc/rc.local start" >> /etc/systemd/system/rc-local.service
	echo "TimeoutSec=0" >> /etc/systemd/system/rc-local.service
	echo "StandardOutput=tty" >> /etc/systemd/system/rc-local.service
	echo "RemainAfterExit=yes" >> /etc/systemd/system/rc-local.service
	echo "SysVStartPriority=99" >> /etc/systemd/system/rc-local.service
	echo "" >> /etc/systemd/system/rc-local.service
	echo "[Install]" >> /etc/systemd/system/rc-local.service
	echo "WantedBy=multi-user.target" >> /etc/systemd/system/rc-local.service
# Now we turn everything on.
	chmod +x /etc/rc.local
	systemctl enable rc-local
	systemctl start rc-local.service
fi
echo "Setup file complete!"

# Let's check that everything is kosher before clean-up. We grabbed the hash file,
# Let's use it.

echo "Hashing."
str=$path"/md5-hashes"
counter=0
while read -r line; do
	declare hash$counter=$line
	((counter++))
done < "$str"

# Let's grab the hashes of our files
str=$path"/get-updates.sh"
hashupdate=$(md5sum $str | cut -f 1 -d " ")
str=$path"/startup.sh"
hashstartup=$(md5sum $str | cut -f 1 -d " ")
str=$path"/sys-maint.sh"
hashsysmaint=$(md5sum $str | cut -f 1 -d " ")

# Now we compare. If something doesn't match we can flag it to deal with later.
error=0
if [[ $hash0 != $hashupdate ]]; then
	declare error=1
	echo "These files don't match. Better let someone know."
fi

if [[ $hash2 != $hashstartup ]]; then
	declare error=1
	echo "These files don't match. Better let someone know."
fi

if [[ $hash3 != $hashsysmaint ]]; then
	declare error=1
	echo "These files don't match. Better let someoen know."
fi

# If we hit an error we need to do something. For now, we'll put it in the MOTD.
if [[ $error == 1 ]]; then
	cat /etc/motd >> tmp
	rm /etc/motd
	touch /etc/motd
	cat tmp >> /etc/motd
	echo "Invalid files found during installation." >> /etc/motd
	rm tmp
fi

# And we finish by cleaning up the install file.
echo "Removing the evidence."
rm setup.sh
updatedb
echo "Setup complete!"
