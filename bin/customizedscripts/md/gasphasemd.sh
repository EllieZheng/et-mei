#!/bin/bash

if [[ "$#" -eq "1" ]];then

filename=$1
radius=0
here=$(pwd)
np=20

psfdir="psfopt"
mddir="mdrun"

solminfix="solventmin"
minfix="min"
eqfix="eq"
mdfix="md"

neutral="1"
#neutral=$3
if [[ "$neutral" -eq "0"  ]];then
    ionized="_iond"
else
    ionized=""
fi

outputname="${filename}_ws_${radius}A${ionized}"
cp ${here}/${psfdir}/${filename}.pdb ${here}/${psfdir}/${outputname}.pdb
cp ${here}/${psfdir}/${filename}.psf ${here}/${psfdir}/${outputname}.psf

# calculate the center of mass
center-of-mass.sh ${here}/${psfdir} ${filename}

# minimization 2: the whole system
gasminimization.sh ${here} ${filename} ${radius} $neutral

# equilibration
gasequilibration.sh ${here} ${filename} ${radius} $neutral

# production dynamics
gasdynamics.sh ${here} ${filename} ${radius} $neutral 


cat << endmsg4 > ${here}/${mddir}/run_${outputname}.q
#!/bin/bash
  
#SBATCH -p et3
#SBATCH -N 1
#SBATCH -n $np
#SBATCH --mem-per-cpu=1500
#SBATCH -t 15-00:00:00
#SBATCH -J ${outputname}
#SBATCH --error=run_${outputname}.err
#SBATCH -o run_${outputname}.slurm

module load namd/2.11b1-infiniband
NAMD=/home/software/NAMD/NAMD_2.11b1_Linux-x86_64-ibverbs/

jobname="${outputname}"
scratchdir="/scr/lz91/vmd_scr"
srun mkdir -p \${scratchdir}/\${jobname}

echo Running on HOST \$HOSTNAME
for step in "$minfix" "$eqfix" "$mdfix";do
    echo "\$step start at \`date\`"
    charmrun +p$np ++mpiexec \$NAMD/namd2 ${here}/${mddir}/\${jobname}_\${step}.conf > ${here}/${mddir}/\${jobname}_\${step}.log
#   namd2 ${here}/${mddir}/\${jobname}_\${step}.conf > ${here}/${mddir}/\${jobname}_\${step}.log
    wait
    echo "\$step end at \`date\`"
done
srun rm -rf \${scratchdir}/\${jobname}
endmsg4

#vim run_${here}/${mddir}/${outputname}.q
#sbatch ${here}/${mddir}/${outputname}_eq.q

else
    echo "Insufficient argument. Make sure you are in the parent directory."
    echo "gasphasemd.sh filename"
fi
