#!/bin/bash

if [[ "$#" -eq "2" ]];then

filename=$1
radius=$2
here=$(pwd)
np=20 
msm=$2

psfdir="psfopt"
mddir="mdrun"

solminfix="solventmin"
minfix="min"
eqfix="eq"
mdfix="md"

neutral="0"
#neutral=$3
if [[ "$neutral" -eq "0"  ]];then
    ionized="_iond"
else
    ionized=""
fi

outputname="${filename}_ws_${radius}A${ionized}"

# solvation: add water sphere
add-water-sphere.sh ${here}/${psfdir} ${filename} ${radius}

# solvation: add counter-ion to neutralize the system
if [[ "$neutral" -eq "0"  ]];then
    add-ions.sh ${here}/${psfdir} ${filename} ${radius}
fi

# minimization 1: solvent only
sol-minimization.sh ${here} ${filename} ${radius} $neutral ${msm}

# minimization 2: the whole system
all-minimization.sh ${here} ${filename} ${radius} $neutral ${msm}

# equilibration
equilibration.sh ${here} ${filename} ${radius} $neutral ${msm}

# production dynamics
dynamics.sh ${here} ${filename} ${radius} $neutral  ${msm}


cat << endmsg4 > ${here}/${mddir}/run_${outputname}.q
#!/bin/bash
  
#SBATCH -p et3,et4a
#SBATCH -N 1
#SBATCH -n $np
#SBATCH --mem-per-cpu=1500
#SBATCH -t 30-00:00:00
#SBATCH -J ${outputname}
#SBATCH --error=run_${outputname}.err
#SBATCH -o run_${outputname}.slurm

module load namd/2.11b1-infiniband
NAMD=/home/software/NAMD/NAMD_2.11b1_Linux-x86_64-ibverbs/

jobname="${outputname}"
dir="${here}/${mddir}"
scratchdir="/scr/lz91/vmd_scr"
srun mkdir -p \${scratchdir}/\${jobname}

echo Running on HOST \$HOSTNAME
for step in "$solminfix" "$minfix" "$eqfix" "$mdfix";do
    echo "\$step start at \`date\`"
    charmrun +p$np ++mpiexec \$NAMD/namd2 \${dir}/\${jobname}_\${step}.conf > \${dir}/\${jobname}_\${step}.log
#   namd2 \${dir}/\${jobname}_\${step}.conf > \${dir}/\${jobname}_\${step}.log
    wait
    echo "\$step end at \`date\`"
done
srun rm -rf \${scratchdir}/\${jobname}
endmsg4

#vim run_${here}/${mddir}/${outputname}.q
#sbatch ${here}/${mddir}/${outputname}_eq.q

else
    echo "Insufficient argument. Make sure you are in the parent directory."
    echo "namdmd.sh filename radius(=sphere-radius)"
fi
