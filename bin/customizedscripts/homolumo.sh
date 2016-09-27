#!/bin/bash

# to execute it: ./homolumo.sh c4h6_b_t_tda_field $lowlimit $uplimit $grid $n_homo $n_lumo

lowlimit="$2"
uplimit="$3"
grid="$4"
cc="$5"
virt="$6"
if [[ ! -z "$2" && ! -z "$3" && ! -z "$4" && ! -z "$5" && ! -z "$6" ]];then
	awk 'BEGIN {printf("HOMO-LUMO transitions\n")}' > joint_$1_from_$2_to_$3.homolumo
	echo "point calculation begins."
	for(( i=$lowlimit; i<=$uplimit; i=i+$grid));
		do
		echo "\n\n========Field=$i========" >> joint_$1_from_$2_to_$3.homolumo
	#	awk -v name="$1" 'BEGIN {print name}' >> joint_$1_from_$2_to_$3.homolumo
		grep -B 10 "cc.   $5  a'  ---  Virt.   $6  a'" $1_$i.out >> joint_$1_from_$2_to_$3.homolumo
		echo "$1_$i done."
	done
else
	echo "Not enough suffix provided."
fi

