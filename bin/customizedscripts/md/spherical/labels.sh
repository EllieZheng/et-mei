#!/bin/bash

if [[ "$#" -eq "3" ]];then

filename=$1
here=$(pwd)
subdir="hbonds"
postfix="labels"
Nindex=$2
Hindices=$3

Natoms="index ${Nindex}"

protons=""
for index in ${Hindices};do
    protons="${protons} index ${index} or"
done
protons=${protons::-3}

currDir=${here}
parDir=${currDir%/*}
topParDir=${parDir%/*}

echo "creating tcl file for calculating the distance between the N atom ${Natoms} and protons ${protons}"

mkdir -p ${currDir}

cat > ${currDir}/${filename}_${postfix}.tcl << endmsg
set filename ${filename}

set postfix ${postfix} 
set iframe 0
set fframe 50019
set protonIndex {${Hindices}}

mol new ${topParDir}/psfopt/\${filename}.psf type psf
mol addfile ${parDir}/\${filename}_eq.dcd type dcd first 0 last -1 step 1 filebonds 1 autobonds 1 waitfor all

label delete Atoms all 

set Natoms [atomselect 0 "$Natoms"]
set protons [atomselect 0 "${protons}"]

set i 0
foreach Natom [\${Natoms} list] {
    foreach proton [\${protons} list] {
        label add Bonds 0/\${Natom} 0/\${proton}
        label graph Bonds 0 ${currDir}/\${filename}_\${postfix}_${Nindex}-[lindex \${protonIndex} \$i].dat
        label delete Bonds all
        incr i
    }
}

exit
endmsg

echo "running ${filename}_${postfix}.tcl ..."

vmd -dispdev text -e ${currDir}/${filename}_${postfix}.tcl > ${currDir}/${filename}_${postfix}.log

else
    echo "Make sure you're in the subdir of ~/mdrun"
    echo "Syntax: labels.sh filename N_index protons_indices(\"index1 index2 ...\")"
fi
