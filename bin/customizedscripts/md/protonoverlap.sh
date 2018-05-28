#!/bin/bash

if [[ "$#" -eq "6" ]];then

filename=$1
here=$(pwd)
subdir="hbonds"
currDir=${here}
hbondsPost="hbonds"
NDindex=$2
NAindex=$3

firstframe=$4
lastframe=$5
step=$6

hbondsDat=${currDir}/${filename}_${hbondsPost}.dat
hbondsAllDat=${currDir}/${filename}_${hbondsPost}-details.dat
SHbonds=${currDir}/${filename}_overlap-hbonds.dat
coeff=-4.041673749
#coeff=-4.2395179

## check if ~hbonds.dat files exist
if [[ ! -s ${hbondsDat} ]];then
    echo "calculating direct hbonds..."
    measure-hbonds.sh ${filename} "${NDindex}" "${NAindex}" $firstframe $lastframe $step 
fi
echo "direct hbonds dat done."
echo -e "\nData analysis begin...\n"

## data analysis 

# calculate a typical N-H bond and O-H bond length in the system
# hbondsDat output format: frame  number-of-hbonds   ND-index  OB-index  HD-index  NA-index   HB-index  R(OB-HD)  R(NA-HB)  R(ND-HD)  R(OB-HB)"
avgNHbond=$(awk '{ total += $7 } END { print sprintf("%0.6f", total/NR) }' ${hbondsDat})

echo "calculating overlaps..."

# Using the D-A distances
# output format: frame  r(ND-OB)  r^2(ND-OB)  S(ND-OB)  S^2(OB-NA)  r(OB-NA)  r^2(OB-NA)  S(OB-NA)  S^2(OB-NA) S^2(IF)"
awk '{print sprintf("%6d\t %.6f\t %.6f\t %.6E\t %.6E", $1, $6-avgNHbond, ($6-avgNHbond)^2, exp( coeff*($6-avgNHbond)^2 ), exp( coeff*2*($6-avgNHbond)^2 ) )}' avgOHbond=${avgOHbond} coeff=${coeff} ${hbondsDat} > ${SHbonds} 2> /dev/null

echo "calculating average overlaps..."

# Calculate the average of the D-A distance and the overlap, for all the snapshots and for h-bonds only
avgRhbonds=$(awk '{ total += $2 } END { print sprintf("%.6f", total/NR) }' ${SHbonds})
avgR2hbonds=$(awk '{ total += $3 } END { print sprintf("%.6f", total/NR) }' ${SHbonds})
avgShbonds=$(awk '{ total += $4 } END { print sprintf("%.6E", total/NR) }' ${SHbonds})
avgS2hbonds=$(awk '{ total += $5 } END { print sprintf("%.6E", total/NR) }' ${SHbonds})


echo "Generating outputs..."
# Calculate the fraction of H-Bond occurrances
NHbonds=$(wc -l < ${hbondsDat})
NAll=$(wc -l < ${hbondsAllDat})
hbondOcc=$(awk -v NHbonds=${NHbonds} -v NAll=${NAll} 'BEGIN{ print NHbonds/NAll }')
weightedS2=$(awk -v hbondOcc=${hbondOcc} -v avgS2hbonds=${avgS2hbonds} 'BEGIN{ print hbondOcc*avgS2hbonds }')

# Results output
cat > ${currDir}/${filename}.results << endmsg
MD default: 
    stepsize = 1 fs, Nsteps = 40,000,000 = 40 ns, dcd frequency = 500 = 0.5 ps, sphericalBck = 30 A
    firstframe = ${firstframe}, lastframe = ${lastframe}, framestep = ${step} = $(($step/2)) ps
H-bonds defined by: 
    length < 3.0 A && angle < 30 degree
    Donor = indices ${NDindex}, Acceptor = index ${NAindex} 
D-A distance defined by:
    r(ND-NA) = R(NA-HD) - avg R(ND-HD) (${avgNHbond} A)

#########################################
    For molecule: ${filename}
#########################################
Hbonds only:
Hbonds only:
   <R>   = ${avgRhbonds} A 
   <R^2> = ${avgR2hbonds} A 
   <S>   = ${avgShbonds} 
   <S^2> = ${avgS2hbonds} 
   H-bond occurance = ${hbondOcc}
   weighted <S^2> = ${weightedS2}
 
#########################################
${filename} ${avgRhbonds} ${avgR2hbonds} ${avgShbonds} ${avgS2hbonds} ${hbondOcc} ${weightedS2}
endmsg

cat ${currDir}/${filename}.results

else
    echo "Make sure you're in the subdir of ~/mdrun"
    echo "Syntax: protonoverlap.sh filename donor_N_indices(\"index1 index2 ...\")  acceptor_N_index firstframe lastframe step"
fi
