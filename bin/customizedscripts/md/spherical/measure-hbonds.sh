#!/bin/bash

if [[ "$#" -eq "6" ]];then

filename=$1
here=$(pwd)
subdir="hbonds"
postfix="hbonds"
length="3.0"
angle="30"

firstframe=$4
lastframe=$5
step=$6

sel1=""
for index in $2;do
    sel1="${sel1} index ${index} or"
done
sel1=${sel1::-3}

sel2=""
for index in $3;do
    sel2="${sel2} index ${index} or"
done
sel2=${sel2::-3}


currDir=${here}
parDir=${currDir%/*}
topParDir=${parDir%/*}

echo "creating tcl file for finding hydrogen bonds between donor ${sel1} and acceptor ${sel2} with length < ${length} and angle < ${angle}"
echo "output format: frame  number-of-hbonds   donor-index   acceptor-index    proton-index   R(NA-HD)   R(ND-HD)"

mkdir -p ${currDir}

cat > ${currDir}/${filename}_${postfix}.tcl << endmsg

set filename ${filename}
set postfix ${postfix} 
set length ${length}
set angle ${angle}
set detailsoutputfile [open "${currDir}/${filename}_${postfix}-details.dat" w]
set outputfile [open "${currDir}/${filename}_${postfix}.dat" w]
set firstframe ${firstframe}
set lastframe ${lastframe}
set step ${step}

mol new ${topParDir}/psfopt/\${filename}.psf type psf
mol addfile ${parDir}/\${filename}_md.dcd type dcd first \${firstframe} last \${lastframe} step \${step} filebonds 1 autobonds 1 waitfor all

set sel1 [atomselect top "${sel1}"]
set sel2 [atomselect top "${sel2}"]

set firstFrame 0
set numframes [molinfo top get numframes]
for {set i 0} {\$i < \$numframes} {incr i} {
    # Advance to frame \$i 
    animate goto \$i
    display update
    set hbondList [measure hbonds \${length} \${angle} \$sel1 \$sel2] 
    set numHbonds [llength [lindex \$hbondList 0]]
    if {\$numHbonds == 1} {
        set donorIndex [lindex [lindex \$hbondList 0] 0]
        set acceptorIndex [lindex [lindex \$hbondList 1] 0]
        set protonIndex [lindex [lindex \$hbondList 2] 0]
        # calculate the distance between ND and HD
        set NDatoms [atomselect top "index \${donorIndex}"]
        set NAatoms [atomselect top "index \${acceptorIndex}"]
        set HDatoms [atomselect top "index \${protonIndex}"]
        foreach HDatom [\${HDatoms} list] {
            foreach NAatom [\${NAatoms} list] {
                set R_NA_HD [measure bond [list \$NAatom \$HDatom]]
            }
            foreach NDatom [\${NDatoms} list] {
                set R_ND_HD [measure bond [list \$NDatom \$HDatom]]
            }
        }
# output "frame number-of-hbonds donor-index acceptor-index proton-index R(NA-HD) R(ND-HD)"
        puts \${outputfile} "\$i\t\$numHbonds\t\$donorIndex\t\$acceptorIndex\t\$protonIndex\t\${R_NA_HD}\t\${R_ND_HD} "
        puts \${detailsoutputfile} "\$i\t\$numHbonds\t\$donorIndex\t\$acceptorIndex\t\$protonIndex\t\${R_NA_HD}\t\${R_ND_HD}  "
    } else {
        puts \${detailsoutputfile} "\$i\t\$numHbonds"
    }
}
close \${outputfile}
close \${detailsoutputfile}

exit
endmsg

echo "running ${filename}_${postfix}.tcl ..."

vmd -dispdev text -e ${currDir}/${filename}_${postfix}.tcl > ${currDir}/${filename}_${postfix}.log

#cat ${currDir}/${filename}_${postfix}-details.dat

else
    echo "Make sure you're in the subdir of ~/mdrun"
    echo "Syntax: measure-hbonds.sh filename donor_N_indices(\"index1 index2 ...\") acceptor_N_indices(\"index1 index2 ...\") firstframe lastframe step "
fi
