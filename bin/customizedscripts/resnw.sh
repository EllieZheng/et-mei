#!/bin/bash

# This file is to generate .q(.sh)/.nw files for restarting jobs
# filename=$1, extension=$2, memory=$3, nodes=$4 ntasks=$5

if [[ ! -z "$1" && ! -z "$2" ]];then
	if [[ -s "$1.nw" ]];then
	    file="$1"
	    extension="$2"
	    cp $file.db ${file}_${extension}.db
	    mv $file.movecs ${file}_${extension}.movecs
	    mv $file.out ${file}_${extension}.out
	    mv $file.err ${file}_${extension}.err
	    sed -i 's/start/restart/;s/rerestart/restart/;s/vectors input.*$/vectors input '${file}'_'${extension}'.movecs output '$file'.movecs/' $file.nw
	    if [[ ! -z "$3"  && ! -z "$4" && ! -z "$5" ]];then
            memory="$3"
            nodes="$4"  		
            ntasks="$5"
            memorysmall=$((${memory}/${nodes}))
            sed -i 's/memory.*$/memory '${memorysmall}' mb/' $file.nw
            if [[ -s "${file}.sh" ]];then
                cp $file.sh ${file}_${extension}.sh
                sed -i 's/SBATCH -n.*$/SBATCH -n '$nodes'/;s/--mem=.*$/'--mem="${memory}"'/;s/--ntasks-per-node=.*$/'--ntasks-per-node="$ntasks"'/' $file.sh
            elif [[ -s "${file}.q" ]];then
                cp $file.q ${file}_${extension}.q
                sed -i 's/SBATCH -n.*$/SBATCH -n '$nodes'/;s/--mem=.*$/'--mem="${memory}"'/;s/--ntasks-per-node=.*$/'--ntasks-per-node="$ntasks"'/' $file.q
            fi
        fi
	    vim $file.nw
#	    if [[ -s "${file}.sh" ]];then
#            vim $file.sh
#            sbatch $file.sh
#	    else
#            vim $file.q
#    		sbatch $file.q
#	    fi
    else
        echo "Files $1.nw do not exist."
    fi

else
	echo "Insufficient arguments"
	echo "Syntex: memnw.sh filename extension [memory(mb) #nodes ntasks-per-node]-optional"

fi

