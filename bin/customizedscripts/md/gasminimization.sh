#!/bin/bash

if [[ "$#" -eq "4" ]];then

pardir=$1
filename=$2
radius=$3
# if the system is ionized or not
if [[ "$4" -eq "0"  ]];then
    ionized="_iond"
else
    ionized=""
fi

# MD parameters
steps="20000" # 10 ps
stepsize="1"     # 1 fs
dcdfreq="500"    # 0.5 ps
#msm="${radius}"
msm="30"

# file and directory
psfdir="psfopt"
mddir="mdrun"
postfix="min"
outputname="${filename}_ws_${radius}A${ionized}"


# get the center of the sphere
cx=$(grep "CENTER OF MASS OF SPHERE" ${pardir}/${psfdir}/${filename}_ws_${radius}A.log | awk '{print sprintf("%.12f", $7)}')
cy=$(grep "CENTER OF MASS OF SPHERE" ${pardir}/${psfdir}/${filename}_ws_${radius}A.log | awk '{print sprintf("%.12f", $8)}')
cz=$(grep "CENTER OF MASS OF SPHERE" ${pardir}/${psfdir}/${filename}_ws_${radius}A.log | awk '{print sprintf("%.12f", $9)}')


echo "creating config file for energy minimization..."

mkdir -p ${pardir}/${mddir}
cat << endmsg3 > ${pardir}/${mddir}/${outputname}_${postfix}.conf
#############################################################
## JOB DESCRIPTION                                         ##
#############################################################

# Energy Minimization of ${filename} in a Water Sphere
# Solvent only

#############################################################
## ADJUSTABLE PARAMETERS                                   ##
#############################################################

set pname          ${outputname}
set pardir         ${pardir}

structure          \${pardir}/${psfdir}/\${pname}.psf
coordinates        \${pardir}/${psfdir}/\${pname}.pdb

set outputname     \${pname}_${postfix}


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


# Force-Field Parameters
exclude             scaled1-4
1-4scaling          1.0
cutoff              12.0
switching           on
switchdist          10.0
pairlistdist        14.0


# Integrator Parameters
rigidBonds          water; # needed for 1 fs steps
fullElectFrequency  2  
stepspercycle       10


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
restartfreq         1000  ;# 1000steps = every 1ps
dcdfreq             ${dcdfreq}
outputEnergies      ${dcdfreq}


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
minimization        on
minimize            ${steps}

endmsg3

echo -e "minimization config file done.\n"

#vim  ${pardir}/${mddir}/${outputname}_${postfix}.conf

else
    echo "Syntax: gasminimization.sh pardir filename radius iond?(0:yes,1:no)"
fi
