#!/bin/bash

# This file is to generate .q(.sh)/.nw files for geometry optimization 
# Default is pvtz, b3lyp
# filename=$1, extension(method)=$2, memory=$3, nodes=$4 ntasks=$5 -p=$6

if [[ "$#" -eq "7" ]];then
	file="$1";extension="$2"; memory="$3"; nodes="$4"; ntasks="$5"; host="$6";basis="$7";
	memoryperprocess=$((${memory}*8/10));
# Generate .nw file from .xyz geometry
	if [[ -s "${file}_${extension}.nw" ]];then
		echo "File ${file}_${extension}.nw exist. Move it to ${file}_${extension}_bak.nw"
		mv ${file}_${extension}.nw ${file}_${extension}_bak.nw
	fi
	echo "echo" >> ${file}_${extension}.nw
	echo "scratch_dir /scr/lz91/nwchem_scr/${file}_${extension} " >> ${file}_${extension}.nw
	echo "start ${file}_${extension}" >> ${file}_${extension}.nw
	echo "title \"${file}_${extension}\"" >> ${file}_${extension}.nw 
	echo "memory ${memoryperprocess} mb" >> ${file}_${extension}.nw
	echo "" >> ${file}_${extension}.nw
	echo "geometry system " >> ${file}_${extension}.nw
	cat ${file}.xyz >> ${file}_${extension}.nw
    
    echo "end

basis noprint
 * library ${basis}
end 

set geometry system                                   
dft
 XC b3lyp" >> ${file}_${extension}.nw  

    if [ ${extension} == "tddft" ];then
        echo " CS00" >> ${file}_${extension}.nw
    fi                                                

    lines2=" iterations 2000                          
 convergence density 1e-6"                            
    echo "${lines2}" >> ${file}_${extension}.nw       

    echo " vectors input atomic output ${file}_${extension}.movecs" >> ${file}_${extension}.nw
    linessrelax=" direct                              
    noio                                                 
end                                                   

driver                                                
 maxiter 1000                                         
end                                                  

task dft optimize"
	linesstddft=" direct
 noio
end
tddft
 nroots 100
 maxiter 1000
 notriplet
end
task tddft"

	if [ ${extension} == "tddft" ];then
		echo "${linesstddft}" >> ${file}_${extension}.nw
	else
		echo "${linessrelax}" >> ${file}_${extension}.nw
	fi


# Generate .q file
	if [[ -s "${file}_${extension}.q" ]];then
		echo "File ${file}_${extension}.q exist. Move it to ${file}_${extension}_bak.q"
		mv ${file}_${extension}.q ${file}_${extension}_bak.q
	fi

	echo "#!/bin/bash" >> ${file}_${extension}.q
	echo " " >> ${file}_${extension}.q
	echo "#SBATCH -p ${host}" >> ${file}_${extension}.q
	echo "#SBATCH -N ${nodes}" >> ${file}_${extension}.q
	echo "#SBATCH -n ${ntasks}" >> ${file}_${extension}.q
	echo "#SBATCH --mem-per-cpu=${memory}" >> ${file}_${extension}.q
    echo "#SBATCH -t 7-00:00:00" >> ${file}_${extension}.q
	echo "#SBATCH --error=${file}_${extension}.err" >> ${file}_${extension}.q
	echo "#SBATCH -o slurm_%J_${file}_${extension}.out" >> ${file}_${extension}.q
	echo " " >> ${file}_${extension}.q
	echo "export ARMCI_DEFAULT_SHMMAX=2000" >> ${file}_${extension}.q
	if [ ${host} == "et1_old" ];then
		echo "module load nwchem/openmpi/6.5-et1_old_multinode" >> ${file}_${extension}.q
    elif [ ${host} == "et3" ];then
		echo "module load nwchem/openmpi/6.6-et2" >> ${file}_${extension}.q
    else
		echo "module load nwchem/openmpi/6.5-${host}" >> ${file}_${extension}.q
	fi
    echo "jobname=\"${file}_${extension}\"" >> ${file}_${extension}.q
    echo "scratchdir=\"/scr/lz91/nwchem_scr\"" >> ${file}_${extension}.q
	echo "srun mkdir -p \${scratchdir}/\${jobname}" >> ${file}_${extension}.q
	echo "srun echo "Running on HOST \$HOSTNAME"" >> ${file}_${extension}.q
	echo "echo "Start at \`date\`"" >> ${file}_${extension}.q
	echo "mpiexec nwchem ./\${jobname}.nw > ./\${jobname}.out" >> ${file}_${extension}.q
	echo "wait" >> ${file}_${extension}.q
	echo "echo "End at \`date\`"" >> ${file}_${extension}.q
	echo "srun rm -rf \${scratchdir}/\${jobname}" >> ${file}_${extension}.q

	vim ${file}_${extension}.q
	vim ${file}_${extension}.nw
	#sbatch ${file}_${extension}.q
else
	echo "Insufficient arguments"
	echo "Syntex: prepare.sh filename method(relax/tddft) mem-per-cpu(mb) #nodes #cpu host basis-set"

fi

