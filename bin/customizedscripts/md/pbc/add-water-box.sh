#!/bin/bash

if [[ "$#" -eq "3" ]];then

dir=$1
filename=$2
padding=$3
outputname="${filename}_wb_${padding}A"

echo "creating tcl file for adding water box..."

cat > ${dir}/${outputname}.tcl << endmsg1
package require solvate

set molname ${filename}
set dir ${dir}
set output ${outputname}

solvate \${dir}/\${molname}.psf \${dir}/\${molname}.pdb -t ${padding} -o \${dir}/\${output}

exit
endmsg1

echo "running ${outputname}.tcl..."

vmd -dispdev text -e ${dir}/${outputname}.tcl > ${dir}/${outputname}.log

echo -e "adding water box done.\n"

else
    echo "Syntax: add-water-box.sh parent-dir filename padding"
fi
