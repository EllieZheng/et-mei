#!/bin/bash

if [[ "$#" -eq "5" ]];then

filename=$1
here=$(pwd)
subdir="hbonds"
currDir=${here}
labelsPost="labels"
hbondsPost="hbonds"
NAindex=$2
NDindex=$3
array=($NDindex); defaultND=${array[0]}
Hindices=$4
Hindex=$5

hbondsDat=${currDir}/${filename}_${hbondsPost}.dat
NHbondDat=${currDir}/${filename}_${labelsPost}_${defaultND}-${Hindex}.dat
DAbondDatList=""
for index in ${Hindices};do
    DAbondDatList="${DAbondDatList} ${currDir}/${filename}_${labelsPost}_${NAindex}-${index}.dat"
done
DAbondDatMerge=${currDir}/${filename}_DAbonds.dat
DAbondMin=${currDir}/${filename}_DAbonds-minimum.dat
RDA=${currDir}/${filename}_RDA.dat
SAll=${currDir}/${filename}_overlap-all.dat
SHbonds=${currDir}/${filename}_overlap-hbonds.dat
coeff=-4.041673749

## check if ~hbonds.dat files exist
if [[ ! -s ${hbondsDat} ]];then
    echo "calculating hbonds..."
    hbonds.sh ${filename} ${NAindex} "${NDindex}"
fi
echo "hbonds dat done."
## check if a typial N-H bond length ~labels.dat files exist
if [[ ! -s ${NHbondDat} ]];then
    echo "calculating NH bond length..."
    labels.sh ${filename} ${defaultND} ${Hindex}
fi
echo "NH bond dat done."

## check if ~D-A distance ~labels.dat files exist.
notfound=0
for dat in ${DAbondDatList};do if [[ ! -s ${dat} ]]; then notfound=1; fi; done
if [[ ${notfound} -eq 1 ]];then
    echo "calculating D-A distances..."
    labels.sh ${filename} ${NAindex} "${Hindices}"
fi
echo "D-A distance dat done."

echo -e "\nData collected."
echo -e "\nData analysis begin...\n\n"

## data analysis 

# calculate a typical N-H bond length in the system
avgNHbond=$(awk '{ total += $2 } END { print sprintf("%0.6f", total/NR) }' ${NHbondDat})

# concatenate N(acceptor)-H length files of donor N and transferring protons
if [[ -s ${DAbondDatMerge} ]];then mv ${DAbondDatMerge} ${DAbondDatMerge}_bak;fi
touch ${DAbondDatMerge}
for dat in ${DAbondDatList};do 
    awk  '{print $2}' ${dat} > ${dat}.tmp
    paste ${DAbondDatMerge} ${dat}.tmp | column -s $'\t' -t  > ${DAbondDatMerge}_tmp
    mv ${DAbondDatMerge}_tmp ${DAbondDatMerge}
    rm ${dat}.tmp
done
# find out which proton could be transferred, by finding the minimum N-H length
awk '{min=$1; for(i=2;i<=NF;i++){ if($i<min){min=$i} }; $(NF+1)=min}1' OFS="\t" ${DAbondDatMerge} | awk '{print $NF}' > ${DAbondMin}

# Using the minimum N-H length to calculate the D-A distance
awk '{print sprintf("%.6f\t%.6f\t%.6E\t%.6E", $1-avg, ($1-avg)^2, exp( coeff*($1-avg)^2 ), exp( coeff*2*($1-avg)^2 ) )}' avg=${avgNHbond} coeff=${coeff} ${DAbondMin} > ${RDA} 2> /dev/null
paste ${hbondsDat} ${RDA} | column -s $'\t' -t  > ${SAll}
rm ${RDA}

# Only save the data where there is H-Bond
awk '/ 1 / {print sprintf("%6d\t%.6f\t%.6f\t%.6E\t%.6E", $1, $3, $4, $5, $6)}' ${SAll} > ${SHbonds}

# Calculate the average of the D-A distance and the overlap, for all the snapshots and for h-bonds only
avgRall=$(awk '{ total += $3 } END { print sprintf("%.6f", total/NR) }' ${SAll})
avgR2all=$(awk '{ total += $4 } END { print sprintf("%.6f", total/NR) }' ${SAll})
avgSall=$(awk '{ total += $5 } END { print sprintf("%.6E", total/NR) }' ${SAll})
avgS2all=$(awk '{ total += $6 } END { print sprintf("%.6E", total/NR) }' ${SAll})

avgRhbonds=$(awk '{ total += $2 } END { print sprintf("%.6f", total/NR) }' ${SHbonds})
avgR2hbonds=$(awk '{ total += $3 } END { print sprintf("%.6f", total/NR) }' ${SHbonds})
avgShbonds=$(awk '{ total += $4 } END { print sprintf("%.6E", total/NR) }' ${SHbonds})
avgS2hbonds=$(awk '{ total += $5 } END { print sprintf("%.6E", total/NR) }' ${SHbonds})

# Calculate the fraction of H-Bond occurrances
NHbonds=$(wc -l < ${SHbonds})
NAll=$(wc -l < ${SAll})
hbondOcc=$(awk -v NHbonds=${NHbonds} -v NAll=${NAll} 'BEGIN{ print NHbonds/NAll }')
weightedS2=$(awk -v hbondOcc=${hbondOcc} -v avgS2hbonds=${avgS2hbonds} 'BEGIN{ print hbondOcc*avgS2hbonds }')

# Results output
cat > ${currDir}/${filename}.results << endmsg
MD default: 
    stepsize = 1 fs, Nsteps = 500000 = 500 ps, dcd step = 10, sphericalBck = 15 A
H-bonds defined by: 
    length < 3.0 A && angle < 30 degree
    Acceptor = index ${NAindex}, Donor = indices ${NDindex} 
Transferred proton could be any of the following:
    indices ${Hindices}
D-A distance defined by:
    the minimum of N(acceptor)-H distances - ${avgNHbond} A (the average bond length of N${defaultND}-H${Hindex})

#########################################
    For molecule: ${filename}
#########################################

All snapshots:
   <R>   = ${avgRall} A 
   <R^2> = ${avgR2all} A 
   <S>   = ${avgSall} 
   <S^2> = ${avgS2all} 

Hbonds only:
   <R>   = ${avgRhbonds} A 
   <R^2> = ${avgR2hbonds} A 
   <S>   = ${avgShbonds} 
   <S^2> = ${avgS2hbonds} 
   H-bond occurance = ${hbondOcc}
   weighted <S^2> = ${weightedS2}
endmsg

cat ${currDir}/${filename}.results

else
    echo "Make sure you're in the subdir of ~/mdrun"
    echo "Syntax: protonoverlap.sh filename acceptor_N_index donor_N_indices(\"index1 index2 ...\") protons_indices(\"index1 index2 ...\") proton_index_for_avgNHbond"
fi
