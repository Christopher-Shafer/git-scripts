#!/bin/bash

# This script runs necessary updates and cleanups including logs to track changes.
# Must be run as root.
# Script by Chris Shafer - Christopher.Shafer@cwu.edu

version=1.41
vDate=$(date "+%d%m%Y")
vUpdate=$vDate"autoupdate.log"
vUpgrade=$vDate"autoupgrade.log"
vRemove=$vDate"autoremove.log"
vClean=$vDate"autoclean.log"

echo -e "$(date "+%d-%m-%Y") --- $(date "+%T"): Starting Maintenance\n"

echo -e "\n$(date "+%d-%m-%Y") --- $(date "+%T"): Update Start\n\n" >> /logs/$vUpdate
apt-get update >> /logs/$vUpdate
echo -e "\n$(date "+%T"):\t Update Complete" >> /logs/$vUpdate
cat /logs/$vUpdate

echo -e "\n$(date "+%d-%m-%Y") --- $(date "+%T"): Upgrade Start\n\n" >> /logs/$vUpgrade
apt-get -y upgrade >> /logs/$vUpgrade
echo -e "\n$(date "+%T"):\t Upgrade Complete" >> /logs/$vUpgrade
cat /logs/$vUpgrade

echo -e "\n$(date "+%d-%m-%Y") --- $(date "+%T"): Autoremove Start\n\n" >> /logs/$vRemove
apt-get -y autoremove >> /logs/$vRemove
echo -e "\n$(date "+%T"):\t Auto Remove Complete" >> /logs/$vRemove
cat /logs/$vRemove

echo -e "\n$(date "+%d-%m-%Y") --- $(date "+%T"): Auto Clean Start\n\n" >> /logs/$vClean
apt-get autoclean >> /logs/$vClean
echo -e "\n$(date "+%T"):\t Auto Clean Complete" >> /logs/$vClean
cat /logs/$vClean

echo -e "$(date "+%T"):\t Maintenance Complete"
