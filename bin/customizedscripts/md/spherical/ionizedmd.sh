#!/bin/bash

if [[ "$#" -gt "1" ]];then

filename=$1
radius=$2
here=$(pwd)
subdir="psfopt"
mddir="mdrun"
np="3"
steps="500000"
stepsize="1"
msm="${radius}"
#msm="15"

cx=$(grep "CENTER OF MASS OF SPHERE" ${here}/${subdir}/${filename}_ws_${radius}A.log | awk '{print sprintf("%.12f", $7)}')
cy=$(grep "CENTER OF MASS OF SPHERE" ${here}/${subdir}/${filename}_ws_${radius}A.log | awk '{print sprintf("%.12f", $8)}')
cz=$(grep "CENTER OF MASS OF SPHERE" ${here}/${subdir}/${filename}_ws_${radius}A.log | awk '{print sprintf("%.12f", $9)}')

echo "center of mass: ${cx}, ${cy}, ${cz}"

echo "creating config file for ionized md..."

cat << endmsg3 > ${here}/${mddir}/${filename}_ws_${radius}A_iond_eq.conf
#############################################################
## JOB DESCRIPTION                                         ##
#############################################################

# Minimization and Equilibration of 
# ${filename} in a Water Sphere


#############################################################
## ADJUSTABLE PARAMETERS                                   ##
#############################################################

set pname ${filename}_ws_${radius}A_iond

structure          ${here}/${subdir}/\${pname}.psf
coordinates        ${here}/${subdir}/\${pname}.pdb

set temperature    298
set outputname     \${pname}_eq

firsttimestep      0


#############################################################
## SIMULATION PARAMETERS                                   ##
#############################################################

# Input
paraTypeCharmm	    on
parameters          /home/lz91/bin/topology/toppar/par_all36_prot.prm 
#mergeCrossterms     yes
parameters          /home/lz91/bin/topology/toppar/par_all36_carb.prm
parameters          /home/lz91/bin/topology/toppar/par_all36_lipid.prm
parameters          /home/lz91/bin/topology/toppar/par_all36_na.prm
parameters          /home/lz91/bin/topology/toppar/par_all36_cgenff.prm
parameters          /home/lz91/bin/topology/toppar/toppar_water_ions_namd.str
temperature         \$temperature


# Force-Field Parameters
exclude             scaled1-4
1-4scaling          1.0
cutoff              12.0
switching           on
switchdist          10.0
pairlistdist        14.0


# Integrator Parameters
timestep            ${stepsize} ;# 1 fs/step
rigidBonds          water;# needed for 0.5 fs steps
nonbondedFreq       1
fullElectFrequency  2  
stepspercycle       10


# Constant Temperature Control
langevin            on   ;# do langevin dynamics
langevinDamping     1    ;# damping coefficient (gamma) of 1/ps
langevinTemp        \$temperature
langevinHydrogen    on   ;# couple langevin bath to hydrogens

# Electrostatic Force Evaluation
MSM                 on
MSMGridSpacing      2.5  ;# very sensitive to performance, use this default
MSMxmin            -${msm}
MSMxmax             ${msm}
MSMymin            -${msm}
MSMymax             ${msm}
MSMzmin            -${msm}
MSMzmax             ${msm}

# Output
outputName          \$outputname

restartfreq         200  ;# 200steps = every 0.2ps
dcdfreq             10
outputEnergies      10


#############################################################
## EXTRA PARAMETERS                                        ##
#############################################################

# Spherical boundary conditions
sphericalBC         on
sphericalBCcenter   ${cx}, ${cy}, ${cz}
sphericalBCr1       ${msm}
sphericalBCk1       10
sphericalBCexp1     2


#############################################################
## EXECUTION SCRIPT                                        ##
#############################################################

# Minimization
minimize            200
reinitvels          \$temperature

run ${steps}     ;# 1 fs*500000 = 500 ps
endmsg3

echo "done."

cat << endmsg4 > ${here}/${mddir}/${filename}_ws_${radius}A_iond_eq.q
#!/bin/bash
  
#SBATCH -p et3
#SBATCH -N 1
#SBATCH -n $np
#SBATCH --mem-per-cpu=1500
#SBATCH -t 5-00:00:00
#SBATCH --error=${filename}_ws_${radius}A_iond_eq.err
#SBATCH -o slurm_%J_${filename}_ws_${radius}A_iond.out

module load namd/2.11b1-infiniband
NAMD=/home/software/NAMD/NAMD_2.11b1_Linux-x86_64-ibverbs/

jobname="${filename}_ws_${radius}A_iond_eq"
scratchdir="/scr/lz91/vmd_scr"
srun mkdir -p \${scratchdir}/\${jobname}
echo Running on HOST \$HOSTNAME
echo Start at \`date\`

charmrun +p$np ++mpiexec \$NAMD/namd2 ${here}/${mddir}/\${jobname}.conf > ${here}/${mddir}/\${jobname}.log
#namd2 ${here}/${mddir}/\${jobname}.conf > ${here}/${mddir}/\${jobname}.log
wait
echo End at \`date\`
srun rm -rf \${scratchdir}/\${jobname}
endmsg4

vim ${here}/${mddir}/${filename}_ws_${radius}A_iond_eq.conf
vim ${here}/${mddir}/${filename}_ws_${radius}A_iond_eq.q
sbatch ${here}/${mddir}/${filename}_ws_${radius}A_iond_eq.q

else
    echo "Insufficient argument"
    echo "namdmd.sh filename radius"
fi
