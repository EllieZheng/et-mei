#!/bin/bash

# This file is to generate xyz files for vmd

if [[ ! -z "$1" ]];then
	if [[ -s "$1" ]];then
     		python ~/bin/customizedscripts/vmdxyz.py $@
	else
		echo "Files $1 do not exist."
	fi

else
	echo "Insufficient arguments"
	echo "Syntex: vmdxyz.sh filename1 filename2 ..."
fi

