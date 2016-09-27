#!/bin/bash

# This file is to generate input files for orbital plotting

if [[ ! -z "$1" ]];then
	if [[ -s "$1.nw" ]];then
		python ~/bin/customizedscripts/cube.py $@
	else
		echo "File $1.nw do not exist."
	fi
	if [[ ! -s "$1.movecs" ]];then
		echo "File $1.movecs do not exit. Please copy this file to the current folder."
	else
#		vim $1_v$2.q
#		vim $1_v$2.nw
		sbatch $1_v$2.q
	fi
else
	echo "Insufficient arguments"
	echo "Syntex: cube.sh filename orbital host"
fi

