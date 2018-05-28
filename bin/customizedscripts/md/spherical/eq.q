#!/bin/bash

#SBATCH -p et3
#SBATCH -N 1
#SBATCH -n 3
#SBATCH --mem-per-cpu=500
#SBATCH -t 5-00:00:00
#SBATCH --error=eq.err
#SBATCH -o slurm_%J_eq.out

export ARMCI_DEFAULT_SHMMAX=2000
module load nwchem/openmpi/6.5-et2

jobname="eq"
scratchdir="/scr/lz91/nwchem_scr"
echo Start at `date`
sleep 5d
wait
rm eq.err
rm slurm_%J_eq.out
echo End at `date`

