#!/bin/bash

# This file is to generate .q(.sh)/.nw files for geometry optimization 
# Default is pvtz, b3lyp
# filename=$1, extension(method)=$2, memory=$3, nodes=$4 ntasks=$5 -p=$6

if [[ "$#" -eq "4" ]];then
    file=$1
    extension=$2
    np=$3
    mem=$4
    here=$(pwd)
    bakfilename="${file}_${extension}"
    if [[ -s "${bakfilename}.conf"  ]];then
        echo "File ${bakfilename}.conf exist. Move it to ${bakfilename}_bak.conf"
        mv ${bakfilename}.conf ${bakfilename}_bak.conf
    fi
    mv ${file}.dcd ${bakfilename}.dcd
    if [[ -s "${file}.coor" ]];then
        mv ${file}.coor ${bakfilename}.coor
    fi
    if [[ -s "${file}.vel" ]];then
        mv ${file}.vel ${bakfilename}.vel
    fi
    if [[ -s "${file}.xsc" ]];then
        mv ${file}.xsc ${bakfilename}.xsc
    fi
    mv ${file}.log ${bakfilename}.log
    cp ${file}.conf ${bakfilename}.conf
    cp run_${file%_*}.q ${bakfilename}.q

    # change .conf file
    oldrestartname=$(grep "set restartname" ${file}.conf | awk '{print $3}')
    oldrestartname=${oldrestartname//\$/\\\$}
    oldrestartname=${oldrestartname//\//\\\/}
    oldfirsttime=$(grep "firsttimestep" ${file}.conf | awk '{print $2}')
    laststep=$(tail -50 ${bakfilename}.log | awk '/WRITING VELOCITIES TO RESTART FILE/ {print $8}' | tail -1)
    oldsteps=$(grep "run " ${file}.conf | awk '{print $2}')
    totalsteps=80000000
    #newsteps=$((${totalsteps}-${laststep}))
    newsteps=$((${oldsteps}-${laststep}))
    echo "restart $file from $laststep for another $newsteps steps"
    sed -i -e "s/set restartname    ${oldrestartname}/set restartname    ${file}/" ${file}.conf
    sed -i "s/firsttimestep      ${oldfirsttime}/firsttimestep      ${laststep}/" ${file}.conf
    sed -i "s/run ${oldsteps}/run ${newsteps}/" ${file}.conf

    # change .q file

cat << endmsg4 > run_${file}.q
#!/bin/bash
  
#SBATCH -p et3
#SBATCH -N 1
#SBATCH -n $np
#SBATCH --mem-per-cpu=1500
#SBATCH -t 30-00:00:00
#SBATCH -J ${file}
#SBATCH --error=run_${file}.err
#SBATCH -o run_${file}.slurm

jobname="${file}"
dir=${here}

module load namd/2.11b1-infiniband
NAMD=/home/software/NAMD/NAMD_2.11b1_Linux-x86_64-ibverbs/

scratchdir="/scr/lz91/vmd_scr"
srun mkdir -p \${scratchdir}/\${jobname}

echo Running on HOST \$HOSTNAME

echo "\$step start at \`date\`"
charmrun +p$np ++mpiexec \$NAMD/namd2 \${dir}/\${jobname}.conf > \${dir}/\${jobname}.log
#namd2 \${dir}/\${jobname}.conf > \${dir}/\${jobname}.log
wait
echo "\$step end at \`date\`"
srun rm -rf \${scratchdir}/\${jobname}
endmsg4
vim run_${file}.q
vim ${file}.conf
sbatch run_${file}.q

else
    echo "Syntax: resmd.sh oldfilename extension ntasks mem-per-cpu"
fi
