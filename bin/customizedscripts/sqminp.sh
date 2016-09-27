#!/bin/bash

# This file is to generate sqm input files for quick PM3 optimization

if [[ ! -z "$1" ]];then
	if [[ -s "$1" ]];then
     		python ~/bin/customizedscripts/sqminp.py $@
	else
		echo "Files $1 do not exist."
	fi

else
	echo "Insufficient arguments"
	echo "Syntex: sqminp.sh filename1 filename2 ..."
fi

