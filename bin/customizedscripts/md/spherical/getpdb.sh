#!/bin/bash

if [[ "$#" -eq "2" ]];then

filename=$1
frame="$2"
postfix="frame_$frame"

here=$(pwd)
subdir="snapshots"
currDir=${here}
parDir=${currDir%/*}
targetDir=${parDir}/${subdir}

echo "creating tcl file for extracting pdb from dcd..."

mkdir -p ${targetDir}

cat > ${targetDir}/${filename}_${postfix}.tcl << endmsg

set filename ${filename}

mol new ${parDir}/psfopt/${filename%_*}.psf type psf
mol addfile ${currDir}/\${filename}.dcd type dcd first 0 last -1 step 1 filebonds 1 autobonds 1 waitfor all

#for { set i 0 } {\$i < \$nf } { incr i } { 
#        set sel [atomselect top protein frame $i] 
#            $sel writepdb $i.pdb 
#}
# set sel [atomselect top protein frame ${frame}]
set sel [atomselect top all frame ${frame}]
\$sel writepdb ${targetDir}/\${filename}_${postfix}.pdb 

exit
endmsg

echo "running ${targetDir}/${filename}_${postfix}.tcl ..."

vmd -dispdev text -e ${targetDir}/${filename}_${postfix}.tcl > ${targetDir}/${filename}_${postfix}.log

else
    echo "Make sure you're in the dir: mdrun"
    echo "Syntax: getpdb.sh filename frame(first, last, now, or non-negative number)"
fi
