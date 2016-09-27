#!/bin/bash

# This file is to modify .q(.sh)/.nw files with memory and nodes
# filename=$1, memory=$2, nodes=$3 ntasks=$4

if [[ ! -z "$1" && ! -z "$2"  && ! -z "$3"  && ! -z "$4" ]];then
	if [[ -s "$1.nw" ]];then
		file="$1"
		memory="$2"
		nodes="$3"
		ntasks="$4"
		
		sed -i 's/memory.*$/memory '${memory}' mb/' $file.nw
	        vi $file.nw
	
		if [[ -s "${file}.sh" ]];then
			sed -i 's/SBATCH -n.*$/SBATCH -n '$nodes'/;s/--mem=.*$/'--mem="${memory}"'/;s/--ntasks-per-node=.*$/'--ntasks-per-node="$ntasks"'/' $file.sh
			vi $file.sh
			sbatch $file.sh
		else
			sed -i 's/SBATCH -n.*$/SBATCH -n '$nodes'/;s/--mem=.*$/'--mem="${memory}"'/;s/--ntasks-per-node=.*$/'--ntasks-per-node="$ntasks"'/' $file.q
			vi $file.q
			sbatch $file.q
		fi
	else
                echo "Files $1.nw do not exist."
        fi

else
	echo "Insufficient arguments"
	echo "Syntex: memnw.sh filename memory(mb) #nodes ntasks-per-node"
fi

