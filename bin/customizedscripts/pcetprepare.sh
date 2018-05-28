#!/bin/bash

# This file is to generate .q(.sh)/.nw files for calculating the coupling
# Default is 6-31g*, b3lyp
# filename=$1, extension(method)=$2, memory=$3, nodes=$4 ntasks=$5 basis=$6 functional=$7

if [[ "$#" -eq "7" ]];then
    file="$1"; extension="$2"; memory="$3"; nodes="$4"; ntasks="$5"; basis="$6"; func="$7"
    memoryperprocess=$((${memory}*8/10));

    gs="${file}_${extension}_gs"
    is="${file}_${extension}_is"
    fs="${file}_${extension}_fs"

    cig="${file}_${extension}_cig"
    cfg="${file}_${extension}_cfg"
    cif="${file}_${extension}_cif"

#   line_no_i=$(wc -l < ${file}_i.xyz)
    line_no_f=$(wc -l < ${file}.xyz)
    line_no_i=$((${line_no_f}/2))

####################################
# Prepare the g/i/f  state nw file #
####################################
for state in ${gs} ${is} ${fs} ${cig} ${cfg} ${cif}
do
    if [[ -s ${state}.nw ]];then
        echo "File ${state}.nw exist. Move it to ${state}_bak.nw"
        mv ${state}.nw ${state}_bak.nw
    fi

   echo -e "echo
scratch_dir /scr/lz91/nwchem_scr/${state}
start ${state}
title \"${state}\"
memory ${memoryperprocess} mb

geometry system noautoz " >> ${state}.nw

    cat ${file}.xyz >> ${state}.nw

    echo "end

basis noprint
 * library ${basis}
end 

set geometry system                                   

charge 1
" >> ${state}.nw

done

####################################
# Prepare the ground state nw file #
####################################
    echo -e "dft
 XC ${func}
 disp vdw 3
 mult 2
 iterations 1500                          
#convergence energy 1e-8
 convergence density 1e-7
#convergence gradient 1e-7
 vectors input atomic output ${gs}.movecs
 direct                              
 noio                                                 
 adapt off
end                                                   

task dft" >> ${gs}.nw

#####################################
# Prepare the initial state nw file #
#####################################
    echo -e "dft
 XC ${func}
 convergence nolevelshifting
 disp vdw 3
 mult 2
 iterations 1500                          
#convergence energy 5e-8
 convergence density 5e-7
#convergence gradient 5e-7
 vectors input atomic output ${is}.movecs
 direct                              
 noio                                                 
 adapt off
 cdft 1 ${line_no_i} charge 1
end                                                   

task dft" >> ${is}.nw

###################################
# Prepare the final state nw file #
###################################
    echo -e "dft
 XC ${func}
 convergence nolevelshifting
 disp vdw 3
 mult 2
 iterations 1500                          
#convergence energy 5e-8
 convergence density 5e-7
#convergence gradient 5e-7
 vectors input atomic output ${fs}.movecs
 direct                              
 noio                                                 
 adapt off
 cdft $((${line_no_i}+1)) ${line_no_f} charge 1
end                                                   

task dft" >> ${fs}.nw

######################################
# Prepare the is/gs coupling nw file #
######################################
    echo -e "et
 vectors reactants ${is}.movecs
 vectors products ${gs}.movecs
end                                                   

task scf et" >> ${cig}.nw

######################################
# Prepare the fs/gs coupling nw file #
######################################
    echo -e "et
 vectors reactants ${fs}.movecs
 vectors products ${gs}.movecs
end                                                   

task scf et" >> ${cfg}.nw


######################################
# Prepare the is/fs coupling nw file #
######################################
    echo -e "et
 vectors reactants ${is}.movecs
 vectors products ${fs}.movecs
end                                                   

task scf et" >> ${cif}.nw

#######################################
# Prepare the g/i/f  state batch file #
#######################################

#for batchfile in "${gs}" "${is}" "${fs}";do
#    if [[ -s "${batchfile}.q" ]];then
#        echo "File ${batchfile}.q exist. Move it to ${batchfile}_bak.q"
#        mv ${batchfile}.q ${batchfile}_bak.q
#    fi
#
    echo "#!/bin/bash

#SBATCH -p et3
#SBATCH -N ${nodes}
#SBATCH -n ${ntasks}
#SBATCH --mem-per-cpu=1500
#SBATCH -t 7-00:00:00
#SBATCH --error=${batchfile}.err
#SBATCH -o ${batchfile}.slurm.%J

module load nwchem/openmpi/6.6-et2
export ARMCI_DEFAULT_SHMMAX=2000

scratchdir=\"/scr/lz91/nwchem_scr\"

srun echo "Running on HOST \$HOSTNAME"
for jobname in \"${gs}\" \"${is}\" \"${fs}\" \"${cig}\" \"${cfg}\" \"${cif}\";do
    echo "\${jobname} Start at \`date\`"
    
    srun mkdir -p \${scratchdir}/\${jobname}
    mpiexec nwchem ./\${jobname}.nw > ./\${jobname}.out
    wait
    srun rm -rf \${scratchdir}/\${jobname}

    echo "\${jobname} End at \`date\`"
done

" >> ${file}_${extension}_coupling.q

else
    echo "Insufficient arguments"
    echo "Syntex: pcetprepare.sh filename extension mem-per-cpu(mb) #nodes #cpu basis-set functional"
fi
