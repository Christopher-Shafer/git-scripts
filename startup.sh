#!/bin/bash

# This is my custom script to run commands on system boot.
# Written by Chris Shafer - Christopher.Shafer@cwu.edu

# Changelog
# 23-1-2023: Added comments, changed MUSH su to be more modular

version=1.01

# This modifies the MOTD to verify the script is running
echo "\nLast reboot time: $(date)" > /etc/mod

# This command executes the MUSH
#su -c '~/pennmush-master/game/restart' daknit
