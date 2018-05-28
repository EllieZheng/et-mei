
if [[ "$#" -eq "7" ]];then
    file="$1";extension="$2"; mempercpu="$3"; ntasks="$4"; basis="$5"; functional="$6"
    jobtype=""$7
    mem=$((${mempercpu}*8/10))

    # Generate .q file
    if [[ -s "${file}_${extension}.q" ]];then
        echo "File ${file}_${extension}.q exist. Move it to ${file}_${extension}_bak.q"
        mv ${file}_${extension}.q ${file}_${extension}_bak.q
    fi

    cat > ${file}_${extension}.q << endmsg1
#!/bin/bash  
#  
#SBATCH -p et3
#SBATCH -o ${file}_${extension}.%J.slurm
#SBATCH -e ${file}_${extension}.err
#SBATCH -J ${file}_${extension}
#SBATCH -t 15-00:00:00
#SBATCH -n ${ntasks}
#SBATCH -N 1
#SBATCH --mem-per-cpu=${mempercpu}

module load g16.A.03_newpgi
export TMPDIR="/scr/lz91/gau-\${SLURM_JOBID}"                                                                                                                    
export GAUSS_SCRDIR=\$TMPDIR
export jobname="${file}_${extension}"

mkdir -p \$TMPDIR
echo "Running on HOST \$HOSTNAME"  
echo "\${jobname} Start at " \`date\`

g16 \${jobname}.com  

wait
echo "\${jobname} End at " \`date\`
rm -rf \$TMPDIR
endmsg1

# Generate .com file
if [[ -s "${file}_${extension}.com" ]];then
    echo "File ${file}_${extension}.com exist. Move it to ${file}_${extension}_bak.com"
    mv ${file}_${extension}.com ${file}_${extension}_bak.com
fi
cat > ${file}_${extension}.com << endmsg2
%chk=${file}_${extension}.chk
%NprocShared=${ntasks}
%mem=${mem}mb
#P ${functional}/${basis} ${jobtype}

${file} using ${functional}/${basis}

0 1
endmsg2

cat ${file}.xyz >> ${file}_${extension}.com
echo -e "\n" >> ${file}_${extension}.com

vim ${file}_${extension}.com
vim ${file}_${extension}.q
#sbatch ${file}_${extension}.q

else
    echo "Usage: gauprepare.sh filename extension mem-per-cpu ntasks basis-set functional jobtype"
fi

