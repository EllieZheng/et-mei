#!/bin/bash

# to execute it: ./calculatedos.sh c4h6_b_t_tda_field $lowlimit $uplimit $grid
dos () {
        awk '/'Root'/ {print $7}' $1 > $1.ene
        awk '/'Oscillator'/ {print $4}' $1 > $1.dos
        title="$1"
	paste $1.ene $1.dos | column -s $'\t' -t > $1.DOSD0
        IOS=0
	awk -F" " -v name="$title" 'BEGIN {print name; print "delta E(eV)\tOS\t\tIntegrated OS";}
		{IOS=IOS+$2;$(NF+1)=IOS;}1' OFS="\t\t" $1.DOSD0 > $1.DOSD
	rm -f $1.ene $1.dos $1.DOSD0
}
lowlimit="$2"
uplimit="$3"
grid="$4"
startpoint=$(($lowlimit-$grid))
touch joint_$1_$startpoint.DOSD
for(( i=$lowlimit; i<=$uplimit; i=i+$grid ));
	do
	dos $1_$i.out;
	j=$((i-$grid));
	paste joint_$1_$j.DOSD  $1_$i.out.DOSD | column -s $'\t' -t > joint_$1_$i.DOSD;
	rm joint_$1_$j.DOSD;
done

