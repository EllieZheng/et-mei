#!/bin/bash

if [[ "$#" -ge "4" ]];then

pardir=$1
filename=$2
padding=$3
# if the system is ionized or not
if [[ "$4" -eq "0"  ]];then
    ionized="_iond"
else
    ionized=""
fi

# MD parameters
steps="10000" # 10 ps
stepsize="1"     # 1 fs
dcdfreq="500"    # 0.5 ps
#msm="40"

# file and directory
psfdir="psfopt"
mddir="mdrun"
postfix="solventmin"
fixpdbpostfix="fixprotein"
outputname="${filename}_wb_${padding}A${ionized}"

center=$(grep "cellOrigin" ${pardir}/${psfdir}/${filename}_minmax.log | awk '{print sprintf("%.12f,%.12f,%.12f", $2,$3,$4)}')

if [[ ! -z "$5" && ! -z "$6"  && ! -z "$7" ]];then
    xvec=$5
    yvec=$6
    zvec=$7
else
    # get the center of the box 
    xmax=$(grep "Xmax" ${pardir}/${psfdir}/${filename}_minmax.log | awk '{print sprintf("%.6f", $2)}')
    ymax=$(grep "Ymax" ${pardir}/${psfdir}/${filename}_minmax.log | awk '{print sprintf("%.6f", $2)}')
    zmax=$(grep "Zmax" ${pardir}/${psfdir}/${filename}_minmax.log | awk '{print sprintf("%.6f", $2)}')
    xvec=$(awk -v xmax=${xmax} -v padding=${padding} 'BEGIN{ print sprintf("%.1f", xmax+2*padding) }')
    yvec=$(awk -v ymax=${ymax} -v padding=${padding} 'BEGIN{ print sprintf("%.1f", ymax+2*padding) }')
    zvec=$(awk -v zmax=${zmax} -v padding=${padding} 'BEGIN{ print sprintf("%.1f", zmax+2*padding) }')
fi


echo "creating the pdb file for fixed protein and flexible solvent..."

mkdir -p ${pardir}/${psfdir}
cat << endmsg1 > ${pardir}/${psfdir}/${outputname}_${fixpdbpostfix}.tcl
# fix the protein
mol new ${pardir}/${psfdir}/${outputname}.psf
mol addfile ${pardir}/${psfdir}/${outputname}.pdb

set all [atomselect top all] 
set fixatom [atomselect top "not protein"] 

# 1 for fixed or constraint atoms, 0 for unaffected atoms
\$all set beta 1
\$fixatom set beta 0
\$all writepdb ${pardir}/${psfdir}/${outputname}_${fixpdbpostfix}.pdb 
#mol detele top
exit
endmsg1

vmd -dispdev text -e ${pardir}/${psfdir}/${outputname}_${fixpdbpostfix}.tcl > ${pardir}/${psfdir}/${outputname}_${fixpdbpostfix}.log

echo "creating config file for energy minimization with fixed protein..."

mkdir -p ${pardir}/${mddir}
cat << endmsg3 > ${pardir}/${mddir}/${outputname}_${postfix}.conf
#############################################################
## JOB DESCRIPTION                                         ##
#############################################################

# Energy Minimization of ${filename} in a Water Box
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

# Output
outputName          \$outputname
restartfreq         1000  ;# 1000steps = every 1ps
dcdfreq             ${dcdfreq}
outputEnergies      ${dcdfreq}


#############################################################
## EXTRA PARAMETERS                                        ##
#############################################################

# Periodic Boundary Conditions
cellBasisVector1    ${xvec}  0.0  0.0
cellBasisVector2    0.0  ${yvec}  0.0
cellBasisVector3    0.0  0.0  ${zvec}
cellOrigin          ${center}
wrapAll             on

# PME (for full-system periodic electrostatics)
PME                 yes
PMEGridSpacing      1.0


# Fixed solvent
fixedAtoms          on
fixedAtomsForces    off
fixedAtomsFile      \${pardir}/${psfdir}/\${pname}_${fixpdbpostfix}.pdb
fixedAtomsCol       B


#############################################################
## EXECUTION SCRIPT                                        ##
#############################################################

# Minimization
minimization        on
minimize            ${steps}

endmsg3

echo -e "solvent minimization config file done.\n"

#vim  ${pardir}/${mddir}/${outputname}_${postfix}.conf

else
    echo "Syntax: sol-minimization.sh pardir filename padding iond?(0:yes,1:no) [optional] box-x box-y box-z"
fi
