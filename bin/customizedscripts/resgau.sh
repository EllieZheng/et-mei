#!/bin/bash

# This file is to generate .q/.inp files for restart Gaussian jobs
# filename=$1, extension=$2 memory=$3, nodes=$4 ntasks=$5

if [[ ! -z "$1" && ! -z "$2"  && ! -z "$3"  && ! -z "$4"  && ! -z "$5" ]];then
	if [[ -s "$1.inp"  && -s "$1.q"  && -s "$1.chk" ]];then
		file="$1"
		extension="$2"
		memory="$3"
		nodes="$4"
		ntasks="$5"

		cp $file.inp ${file}_${extension}.inp
		cp $file.q ${file}_${extension}.q
		if [[ -s "$file.err" ]];then
			mv $file.err ${file}_${extension}.err
		fi
		if [[ -s "$file.out" ]];then
			mv $file.out ${file}_${extension}.out
		fi

		#sed 's/%NprocShared=.*$/'%NprocShared="$nodes"'/;s/%mem.*$/'%mem="${memory}"GB'/;s/([^)]*)/Restart/g' ${file}_${extension}.inp > $file.inp
		sed 's/%NprocShared=.*$/'%NprocShared="$nodes"'/;s/%mem.*$/'%mem="${memory}"GB'/' ${file}_${extension}.inp > $file.inp
		sed 's/SBATCH -n.*$/SBATCH -n '$nodes'/;s/--mem=.*$/'--mem="${memory}"GB'/;s/--ntasks-per-node=.*$/'--ntasks-per-node="$ntasks"'/' ${file}_${extension}.q > $file.q
		#sed '/%mem\|%NprocShared\|#P/d' $file.inp > $file.inp.tmp
		#sed -e '1i%mem=${memory}GB' -e '2i%NprocShared=${nodes}' -e '2i#P Restart' $file.inp.tmp > $file.inp
		#rm $file.inp.tmp
		#sed '/#SBATCH -n\|#SBATCH --mem=\|#SBATCH --ntasks-per-node/d' $file.q > $file.q.tmp
		#sed -e "6i#SBATCH -n ${nodes}" -e "6i#SBATCH --mem=${memory}GB" -e "6i#SBATCH --ntasks-per-node=${ntasks}" $file.q.tmp > $file.q
		#rm $file.q.tmp
		
		vi $file.inp
		vi $file.q
		sbatch $file.q	
	else
                echo "Files: $1.inp,  $1.q,  $1.chk do not exist."
        fi

else
	echo "No full argument supplied: resgau.sh filename extension memory(GB) #nodes ntasks-per-node"
fi

