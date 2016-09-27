#!/bin/bash

# This file is to modify .q/.inp files with memory and nodes
# filename=$1, memory=$2, nodes=$3 ntasks=$4

if [[ ! -z "$1" && ! -z "$2"  && ! -z "$3"  && ! -z "$4" ]];then
	if [[ -s "$1.inp"  && -s "$1.q" ]];then
		file="$1"
		memory="$2"
		nodes="$3"
		ntasks="$4"

		sed -i 's/%NprocShared=.*$/%NprocShared='$nodes'/;s/%mem.*$/'%mem="${memory}"GB'/' $file.inp
		sed -i 's/SBATCH -n.*$/SBATCH -n '$nodes'/;s/--mem=.*$/'--mem="${memory}"GB'/;s/--ntasks-per-node=.*$/'--ntasks-per-node="$ntasks"'/' $file.q
		vi $file.inp
		vi $file.q
		sbatch $file.q	
	else
                echo "Files $1.inp $1.q do not exist."
        fi

else
	echo "No full argument supplied: memgau.sh filename memory(GB) #nodes ntasks-per-node"
fi

