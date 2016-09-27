#!/bin/bash

# This file is to generate coordinates rotated from original coordinates, so that the x axis is along the polyene chain.

if [[ ! -z "$1" ]];then
	if [[ -s "$1" ]];then
		filename="$(readlink -f $1)"
		dir="$(pwd)"
		echo $filename
		sed '1 i\file="'$filename'";' /home/lz91/bin/customizedscripts/math_rotate.m > /home/lz91/bin/customizedscripts/math_rotate_tmp.m
		math < /home/lz91/bin/customizedscripts/math_rotate_tmp.m > /home/lz91/bin/customizedscripts/math_rotate_tmp.out
		wait
		rm /home/lz91/bin/customizedscripts/math_rotate_tmp.*
     else
        echo "Files $1 do not exist."
     fi

else
	echo "Insufficient arguments"
	echo "Syntex: memnw.sh filename extension [memory(mb) #nodes ntasks-per-node]-optional"
fi

