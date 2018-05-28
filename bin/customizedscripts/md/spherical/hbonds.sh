#!/bin/bash

if [[ "$#" -eq "3" ]];then

filename=$1
here=$(pwd)
subdir="hbonds"
postfix="hbonds"
length="3.0"
angle="30"

sel1="index $2" 
sel2=""
for index in $3;do
    sel2="${sel2} index ${index} or"
done
sel2=${sel2::-3}


currDir=${here}
parDir=${currDir%/*}
topParDir=${parDir%/*}

echo "creating tcl file for finding hydrogen bonds with length < ${length} and angle < ${angle}"

mkdir -p ${currDir}

cat > ${currDir}/${filename}_${postfix}.tcl << endmsg
package require hbonds

set filename ${filename}
set postfix ${postfix} 
set length ${length}
set angle ${angle}

mol new ${topParDir}/psfopt/\${filename}.psf type psf
mol addfile ${parDir}/\${filename}_eq.dcd type dcd first 0 last -1 step 1 filebonds 1 autobonds 1 waitfor all

set sel1 [atomselect top "${sel1}"]
set sel2 [atomselect top "${sel2}"]
hbonds -sel1 \${sel1} -sel2 \${sel2} -dist \${length} -ang \${angle} -frames all -writefile yes -outfile ${currDir}/\${filename}_\${postfix}.dat -polar no -DA both -type pair -detailout ${currDir}/\${filename}_\${postfix}-details.dat

exit
endmsg

echo "running ${filename}_${postfix}.tcl ..."

vmd -dispdev text -e ${currDir}/${filename}_${postfix}.tcl > ${currDir}/${filename}_${postfix}.log

cat ${currDir}/${filename}_${postfix}-details.dat

else
    echo "Make sure you're in the subdir of ~/mdrun"
    echo "Syntax: hbonds.sh filename acceptor_N_index donor_N_indices(\"index1 index2 ...\")"
fi
