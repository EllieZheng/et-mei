#!/bin/bash

if [[ "$#" -eq "3" ]];then

dir=$1
filename=$2
radius=$3
postfix="iond"
outputname="${filename}_ws_${radius}A_${postfix}"

echo "creating and running ionization tcl file..."

cat << endmsg2 > ${dir}/${outputname}.tcl
package require autoionize

set dir ${dir}
set molename ${filename}_ws_${radius}A
cp \${dir}/\${molename}.psf \${dir}/\${molename}_ion.psf
cp \${dir}/\${molename}.pdb \${dir}/\${molename}_ion.pdb
autoionize -psf \${dir}/\${molename}_ion.psf -pdb \${dir}/\${molename}_ion.pdb -neutralize -o \${dir}/${outputname}
#autoionize -psf \${dir}/\${molename}_ion.psf -pdb \${dir}/\${molename}_ion.pdb -nions {{CLA 1}}
rm \${dir}/\${molename}_ion.psf \${dir}/\${molename}_ion.pdb
exit
endmsg2

vmd -dispdev text -e ${dir}/${outputname}.tcl > ${dir}/${outputname}.log

if [[ -s ${dir}/${filename}_ws_${radius}A_ion.psf ]];then
    echo "WARNING: Fail to add ions."
    rm ${dir}/${filename}_ws_${radius}A_ion.psf ${dir}/${filename}_ws_${radius}A_ion.pdb
fi

echo -e "ionization done.\n"
else
    echo "Syntax: add-ions.sh parent-dir filename radius"
fi
