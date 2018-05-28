#!/bin/bash

if [[ "$#" -eq "6" ]];then

filename=$1
here=$(pwd)
subdir="hbonds"
postfix="water-hbonds"
length="3.0"
angle="30"

firstframe=$4
lastframe=$5
step=$6

donorN=""
for index in $2;do
    donorN="${donorN} index ${index} or"
done
donorN=${donorN::-3}

acceptorN=""
for index in $3;do
    acceptorN="${acceptorN} index ${index} or"
done
acceptorN=${acceptorN::-3}

water="water"

currDir=${here}
parDir=${currDir%/*}
topParDir=${parDir%/*}

echo "creating tcl file for finding water-mediated hydrogen bonds between donor ${donorN} and acceptor ${acceptorN} with length < ${length} and angle < ${angle}"
echo "output format: frame  number-of-hbonds(0 or 1 or 2)  ND-index  OB-index  HD-index  NA-index   HB-index  R(OB-HD)  R(NA-HB)  R(ND-HD)  R(OB-HB)"

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

set donorN [atomselect top "${donorN}"]
set acceptorN [atomselect top "${acceptorN}"]
set water [atomselect top "${water}"]

set numframes [molinfo top get numframes]
set numDBA 0
for {set i 0} {\$i < \$numframes} {incr i} {
    # Advance to frame \$i 
    animate goto \$i
    display update
    set ND_OB_hbondList [measure hbonds \${length} \${angle} \$donorN \$water] 
    set ND_OB_numHbonds [llength [lindex \$ND_OB_hbondList 0]]
    if {\$ND_OB_numHbonds == 1} {
        # hbond exists between donorN and the water bridge
        set NDindex [lindex [lindex \$ND_OB_hbondList 0] 0]
        set OBindex [lindex [lindex \$ND_OB_hbondList 1] 0]
        set HDindex [lindex [lindex \$ND_OB_hbondList 2] 0]
        # see if hbond exists between the bridgeO and the acceptorN
        set bridgeO [atomselect top "index \${OBindex}"]
        set OB_NA_hbondList [measure hbonds \${length} \${angle} \${bridgeO} \$acceptorN] 
        set OB_NA_numHbonds [llength [lindex \$OB_NA_hbondList 0]]
        # if water-mediated hbonds was found
        if {\$OB_NA_numHbonds == 1} {
            incr numDBA
            set OBindex [lindex [lindex \$OB_NA_hbondList 0] 0]
            set NAindex [lindex [lindex \$OB_NA_hbondList 1] 0]
            set HBindex [lindex [lindex \$OB_NA_hbondList 2] 0]
            # calculate the distance between OB and HD
            set OBatoms [atomselect top "index \${OBindex}"]
            set HDatoms [atomselect top "index \${HDindex}"]
            foreach OBatom [\${OBatoms} list] {
                foreach HDatom [\${HDatoms} list] {
                    set R_OB_HD [measure bond [list \$OBatom \$HDatom]]
                }
            }
            # calculate the distance between NA and HB
            set NAatoms [atomselect top "index \${NAindex}"]
            set HBatoms [atomselect top "index \${HBindex}"]
            foreach NAatom [\${NAatoms} list] {
                foreach HBatom [\${HBatoms} list] {
                    set R_NA_HB [measure bond [list \$NAatom \$HBatom]]
                }
            }
            # calculate the distance between ND and HD
            set NDatoms [atomselect top "index \${NDindex}"]
            set HDatoms [atomselect top "index \${HDindex}"]
            foreach NDatom [\${NDatoms} list] {
                foreach HDatom [\${HDatoms} list] {
                    set R_ND_HD [measure bond [list \$NDatom \$HDatom]]
                }
            }
            # calculate the distance between OB and HB
            set OBatoms [atomselect top "index \${OBindex}"]
            set HBatoms [atomselect top "index \${HBindex}"]
            foreach OBatom [\${OBatoms} list] {
                foreach HBatom [\${HBatoms} list] {
                    set R_OB_HB [measure bond [list \$OBatom \$HBatom]]
                }
            }

# output format: frame  number-of-hbonds   ND-index  OB-index  HD-index  NA-index   HB-index  R(OB-HD)  R(NA-HB)  R(ND-HD)  R(OB-HB)"
            puts \${outputfile} "\$i\t2\t\$NDindex\t\$OBindex\t\$HDindex\t\$NAindex\t\$HBindex\t\${R_OB_HD}\t\${R_NA_HB}\t\${R_ND_HD}\t\${R_OB_HB} "
            puts \${detailsoutputfile} "\$i\t2\t\$NDindex\t\$OBindex\t\$HDindex\t\$NAindex\t\$HBindex\t\${R_OB_HD}\t\${R_NA_HB}\t\${R_ND_HD}\t\${R_OB_HB}  "
        } else {
            puts \${detailsoutputfile} "\$i\t1\t\$NDindex\t\$OBindex\t\$HDindex "
        }
    } else {
        puts \${detailsoutputfile} "\$i\t0"
    }
}
set percentage [expr {double(\${numDBA})*100/\${numframes}}]
puts "number of water-mediated hbonds occurrance = \${numDBA} = \${percentage}%"

close \${outputfile}
close \${detailsoutputfile}

exit
endmsg

echo "running ${filename}_${postfix}.tcl ..."

vmd -dispdev text -e ${currDir}/${filename}_${postfix}.tcl > ${currDir}/${filename}_${postfix}.log

grep "number of water-mediated hbonds occurrance" ${currDir}/${filename}_${postfix}.log
#cat ${currDir}/${filename}_${postfix}-details.dat

else
    echo "Make sure you're in the subdir of ~/mdrun"
    echo "Syntax: water-hbonds.sh filename donor_N_indices(\"index1 index2 ...\") acceptor_N_indices(\"index1 index2 ...\") firstframe lastframe step"
fi
