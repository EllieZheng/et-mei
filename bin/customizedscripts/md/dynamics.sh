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
firsttime="5000000"
steps="100000000" # 100 ns
stepsize="1"      # 1 fs
dcdfreq="1000"    # 1 ps
#msm="${radius}"

# file and directory
psfdir="psfopt"
mddir="mdrun"
postfix="md"
restartfix="eq"
outputname="${filename}_ws_${radius}A${ionized}"

# get the center of the sphere
cx=$(grep "CENTER OF MASS OF SPHERE" ${pardir}/${psfdir}/${filename}_ws_${radius}A.log | awk '{print sprintf("%.12f", $7)}')
cy=$(grep "CENTER OF MASS OF SPHERE" ${pardir}/${psfdir}/${filename}_ws_${radius}A.log | awk '{print sprintf("%.12f", $8)}')
cz=$(grep "CENTER OF MASS OF SPHERE" ${pardir}/${psfdir}/${filename}_ws_${radius}A.log | awk '{print sprintf("%.12f", $9)}')

mkdir -p ${pardir}/${mddir}

# check if the solvent minimization file exist
if [[ -s ${pardir}/${mddir}/${outputname}_${restartfix}.conf ]];then

echo "creating config file for dynamics..."

cat << endmsg3 > ${pardir}/${mddir}/${outputname}_${postfix}.conf
#############################################################
## JOB DESCRIPTION                                         ##
#############################################################

# Dynamics of ${filename} in a Water Sphere

#############################################################
## ADJUSTABLE PARAMETERS                                   ##
#############################################################

set pname          ${outputname}
set pardir         ${pardir}

structure          \${pardir}/${psfdir}/\${pname}.psf
coordinates        \${pardir}/${psfdir}/\${pname}.pdb

set temperature    298.15
set outputname     \${pname}_${postfix}


#############################################################
## RESTART FROM MINIMIZATION                               ##
#############################################################

set restartname    \${pardir}/${mddir}/\${pname}_${restartfix}
binCoordinates     \${restartname}.restart.coor 
#binVelocities      \${restartname}.restart.vel 
extendedSystem     \${restartname}.restart.xsc 

#firsttimestep      ${firsttime}
#firsttimestep      $(tail ${pardir}/${mddir}/${outputname}_${restartfix}.log | awk '/RESTART FILE/ {print $8}')


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
rigidBonds          water; # needed for 1 fs steps
nonbondedFreq       1
fullElectFrequency  2  
stepspercycle       20


# Constant Temperature Control
langevin            on   ;# do langevin dynamics
langevinDamping     1    ;# damping coefficient (gamma) of 1/ps
langevinTemp        \$temperature
langevinHydrogen    on   ;# couple langevin bath to hydrogens

#LangevinPiston                on              ;# barostat
#LangevinPistonTarget          1.01325         ;# atmospheric pressure at sea level
#LangevinPistonPeriod          200.0           ;# resonable choice
#LangevinPistonDecay           100.0           ;# resonable choice
#LangevinPistonTemp            \$temperature   ;# = tCoupleTemp  


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

run ${steps}     ;# ${stepsize} fs * ${steps} = $((${stepsize}*${steps})) ps

endmsg3

echo -e "dynamics config file done.\n"

    else
        echo "Equilibration does not exist. Run equilibration first."
    fi
else
    echo "Syntax: dynamics.sh pardir filename water-radius iond?(0:yes,1:no) box-radius"
fi
