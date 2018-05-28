#!/bin/bash

if [[ "$#" -eq "6" ]];then

filename=$1
here=$(pwd)
subdir="hbonds"
currDir=${here}
hbondsPost="water-hbonds"
NDindex=$2
NAindex=$3

firstframe=$4
lastframe=$5
step=$6

hbondsDat=${currDir}/${filename}_${hbondsPost}.dat
hbondsAllDat=${currDir}/${filename}_${hbondsPost}-details.dat
SHbonds=${currDir}/${filename}_water_overlap-hbonds.dat
#coeff=-4.041673749
coeff=-4.2395179

## check if ~hbonds.dat files exist
if [[ ! -s ${hbondsDat} ]];then
    echo "calculating water-mediated hbonds..."
    water-hbonds.sh ${filename} "${NDindex}" "${NAindex}" $firstframe $lastframe $step 
fi
echo "water-mediated hbonds dat done."
echo -e "\nData analysis begin...\n"

## data analysis 

# calculate a typical N-H bond and O-H bond length in the system
# hbondsDat output format: frame  number-of-hbonds   ND-index  OB-index  HD-index  NA-index   HB-index  R(OB-HD)  R(NA-HB)  R(ND-HD)  R(OB-HB)"
avgOHbond=$(awk '{ total += $11 } END { print sprintf("%0.6f", total/NR) }' ${hbondsDat})
avgNHbond=$(awk '{ total += $10 } END { print sprintf("%0.6f", total/NR) }' ${hbondsDat})

echo "calculating overlaps..."

# Using the D-A distances
# output format: frame  r(ND-OB)  r^2(ND-OB)  S(ND-OB)  S^2(OB-NA)  r(OB-NA)  r^2(OB-NA)  S(OB-NA)  S^2(OB-NA) S^2(IF)"
awk '{print sprintf("%6d\t %.6f\t %.6f\t %.6E\t %.6E\t %.6f\t %.6f\t %.6E\t %.6E\t %.6E", $1, 
    $8-avgOHbond, ($8-avgOHbond)^2, exp( coeff*($8-avgOHbond)^2 ), exp( coeff*2*($8-avgOHbond)^2 ),   
    $9-avgNHbond, ($9-avgNHbond)^2, exp( coeff*($9-avgNHbond)^2 ), exp( coeff*2*($9-avgNHbond)^2 ),
    exp(coeff*2*($9-avgNHbond)^2)*exp(coeff*2*($8-avgOHbond)^2)/(exp(coeff*2*($9-avgNHbond)^2) + exp(coeff*2*($8-avgOHbond)^2)) )}' avgOHbond=${avgOHbond} avgOHbond=${avgOHbond} coeff=${coeff} ${hbondsDat} > ${SHbonds} 2> /dev/null

echo "calculating average overlaps..."

# Calculate the average of the D-A distance and the overlap, for all the snapshots and for h-bonds only
avgRDBhbonds=$(awk '{ total += $2 } END { print sprintf("%.6f", total/NR) }' ${SHbonds})
avgRDB2hbonds=$(awk '{ total += $3 } END { print sprintf("%.6f", total/NR) }' ${SHbonds})
avgSDBhbonds=$(awk '{ total += $4 } END { print sprintf("%.6E", total/NR) }' ${SHbonds})
avgSDB2hbonds=$(awk '{ total += $5 } END { print sprintf("%.6E", total/NR) }' ${SHbonds})
avgRBAhbonds=$(awk '{ total += $6 } END { print sprintf("%.6f", total/NR) }' ${SHbonds})
avgRBA2hbonds=$(awk '{ total += $7 } END { print sprintf("%.6f", total/NR) }' ${SHbonds})
avgSBAhbonds=$(awk '{ total += $8 } END { print sprintf("%.6E", total/NR) }' ${SHbonds})
avgSBA2hbonds=$(awk '{ total += $9 } END { print sprintf("%.6E", total/NR) }' ${SHbonds})
avgS2hbonds=$(awk '{ total += $10 } END { print sprintf("%.6E", total/NR) }' ${SHbonds})

echo "Generating outputs..."
# Calculate the fraction of H-Bond occurrances
NHbonds=$(wc -l < ${hbondsDat})
NAll=$(wc -l < ${hbondsAllDat})
hbondOcc=$(awk -v NHbonds=${NHbonds} -v NAll=${NAll} 'BEGIN{ print NHbonds/NAll }')
weightedS2=$(awk -v hbondOcc=${hbondOcc} -v avgS2hbonds=${avgS2hbonds} 'BEGIN{ print hbondOcc*avgS2hbonds }')

# Results output
cat > ${currDir}/${filename}_water.results << endmsg
MD default: 
    stepsize = 1 fs, Nsteps = 40,000,000 = 40 ns, dcd frequency = 50, sphericalBck = 30 A
    firstframe = ${firstframe}, lastframe = ${lastframe}, framestep = ${step} = $(($step/2)) ps
H-bonds defined by: 
    length < 3.0 A && angle < 30 degree
    Donor = indices ${NDindex}, Acceptor = index ${NAindex} 
D-A distance defined by:
    r(ND-OB) = R(OB-HD) - avg R(OB-HB) (${avgOHbond} A)
    r(OB-NA) = R(NA-HB) - avg R(ND-HD) (${avgNHbond} A)
total overlap defined by:
    1/S^2(IF) = 1/S^(ND-OB) + 1/S^(OB-NA)

#########################################
    For molecule: ${filename}
#########################################
Hbonds only:
   <R_DB>   = ${avgRDBhbonds} A 
   <R_DB^2> = ${avgRDB2hbonds} A^2 
   <S_DB>   = ${avgSDBhbonds} 
   <S_DB^2> = ${avgSDB2hbonds} 
   <R_BA>   = ${avgRBAhbonds} A 
   <R_BA^2> = ${avgRBA2hbonds} A^2
   <S_BA>   = ${avgSBAhbonds} 
   <S_BA^2> = ${avgSBA2hbonds} 
   <S_IF^2> = ${avgS2hbonds} 
   H-bond occurance = ${hbondOcc}
   weighted <S^2> = ${weightedS2}

#########################################
${filename} ${avgRDBhbonds} ${avgRDB2hbonds} ${avgSDBhbonds} ${avgSDB2hbonds} ${avgRBAhbonds} ${avgRBA2hbonds} ${avgSBAhbonds} ${avgSBA2hbonds} ${avgS2hbonds} ${hbondOcc} ${weightedS2}
endmsg

cat ${currDir}/${filename}_water.results

else
    echo "Make sure you're in the subdir of ~/mdrun"
    echo "Syntax: water-protonoverlap.sh filename donor_N_indices(\"index1 index2 ...\")  acceptor_N_index firstframe lastframe step"
fi
