#!/bin/bash

if [[ "$#" -eq "5" ]];then

pardir=$1
filename=$2
radius=$3
msm=$5
# if the system is ionized or not
if [[ "$4" -eq "0"  ]];then
    ionized="_iond"
else
    ionized=""
fi

# MD parameters
steps="10000"
stepsize="1"     # 1 fs
dcdfreq="500"    # 0.1 ps

# file and directory
psfdir="psfopt"
mddir="mdrun"
postfix="min"
restartfix="solventmin"
outputname="${filename}_ws_${radius}A${ionized}"

# get the center of the sphere
cx=$(grep "CENTER OF MASS OF SPHERE" ${pardir}/${psfdir}/${filename}_ws_${radius}A.log | awk '{print sprintf("%.12f", $7)}')
cy=$(grep "CENTER OF MASS OF SPHERE" ${pardir}/${psfdir}/${filename}_ws_${radius}A.log | awk '{print sprintf("%.12f", $8)}')
cz=$(grep "CENTER OF MASS OF SPHERE" ${pardir}/${psfdir}/${filename}_ws_${radius}A.log | awk '{print sprintf("%.12f", $9)}')

# check if the solvent minimization file exist
if [[ -s ${pardir}/${mddir}/${outputname}_${restartfix}.conf ]];then

echo "creating config file for energy minimization of the whole system..."

mkdir -p ${pardir}/${mddir}
cat << endmsg3 > ${pardir}/${mddir}/${outputname}_${postfix}.conf
#############################################################
## JOB DESCRIPTION                                         ##
#############################################################

# Energy Minimization of ${filename} in a Water Sphere

#############################################################
## ADJUSTABLE PARAMETERS                                   ##
#############################################################

set pname          ${outputname}
set pardir         ${pardir}

structure          \${pardir}/${psfdir}/\${pname}.psf
coordinates        \${pardir}/${psfdir}/\${pname}.pdb

set outputname     \${pname}_${postfix}


#############################################################
## RESTART                                                 ##
#############################################################

set restartname    \${pardir}/${mddir}/\${pname}_${restartfix}
binCoordinates     \${restartname}.restart.coor 
#binVelocities      \${restartname}.restart.vel 
extendedSystem     \${restartname}.restart.xsc 


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

echo -e "system minimization config file done.\n"

#vim  ${pardir}/${mddir}/${outputname}_${postfix}.conf

    else
        echo "Solvent minimization does not exist. Run sol-minimization first."
    fi
else
    echo "Syntax: all-minimization.sh pardir filename radius iond?(0:yes,1:no) box-radius"
fi
