#!/bin/bash                                                                                                                                                        

# This file is to generate .sh/.nw files with different applied fields
# e.g., to execute it: ./duplicate.sh c4h6_b_t_tda_field 100 10 160 10
echo "This is to generate .q/.nw files with applied fields. Unit: 1e-3 a.u."
if [[ "$#" -eq "5" ]];then
    lowlimit="$3"
    uplimit="$4"
    grid="$5"
    for(( i=lowlimit; i<=uplimit; i=i+grid));
    do
        q=$((i*80));
        # E=2q/r^2, r=400au, so E=1E-3 a.u. ~ q = 80e
        # E=2q/r^2, r=4000au, so E=1E-3 a.u. ~ q = 8000e
        qo=$(($2*80));
        #   rm -f $1_$i.sh $1_$i.nw $1_$i.db;
#        sed 's/'"$1_$2"'/'"$1"_$i'/g' $1_$2.q > $1_$i.q;
        sed 's/'"$1_$2"'/'"$1"_$i'/g;s/'"$qo"'/'"$q"'/g;s/'"$2"E-03a.u.'/'"$i"E-03a.u.'/g;s/atomic/'"$1"_$((i-grid)).movecs'/g'  $1_$2.nw > $1_$i.nw;
        #   if [ ! -s $1_$i.db ];then
        #       cp butadiene_b_t_tddft.db $1_$i.db; 
        #   fi
    done
else
    echo "Insufficient arguments"
    echo "Syntex example: duplicate.sh c4h6_b_t_tda_field 10 0 9 1 (duplicate c4h6_b_t_tda_field_10 to files from c4h6_b_t_tda_field_0 to c4h6_b_t_tda_field_9 with grid 1)"
fi
