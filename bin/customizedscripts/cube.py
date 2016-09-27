from __future__ import print_function
import sys
import os

print('This program generates nwchem input files for MO plotting.')
if len(sys.argv) == 1:
    print('Insufficient argument.')
    print('Usage: python node.py filename orbital_number host')
    exit()
fname = sys.argv[1]
orbital = sys.argv[2]
host = sys.argv[3]
try:
    fhand = open(fname+'.nw')
except:
    print('File cannot be opened: ',fname+'.nw')
    exit()
outname = fname+'_v'+orbital
fout = open(outname+'.nw','w')
fq = open(outname+'.q','w')
margin = 3
grid = 8
flag = 0 # mark the geometry or basis module
max_x = max_y = max_z = min_x = min_y = min_z = 0
print('echo\nscratch_dir /scr/lz91/nwchem_scr/'+outname+'\nstart '+outname+'\ntitle "'+outname+'"\n',file=fout)
for line in fhand:
    strs = line.strip().split()
    if len(strs) < 1:
        continue
    if strs[0] == 'geometry':
        print(line.rstrip(),file=fout)
        flag = 1
        continue
    if ( strs[0] == 'end' and flag == 1 ):
        print(line, file=fout)
        flag = 0
        continue
    if flag == 1:
        print(line.rstrip(),file=fout)
        if strs[0] in ['C','H','O','N','F']:
            if int(round(float(strs[1]))) > max_x:
                max_x = int(round(float(strs[1])))
            if int(round(float(strs[2]))) > max_y:
                max_y = int(round(float(strs[2])))
            if int(round(float(strs[3]))) > max_z:
                max_z = int(round(float(strs[3])))
            if int(round(float(strs[1]))) < min_x:
                min_x = int(round(float(strs[1])))
            if int(round(float(strs[2]))) < min_y:
                min_y = int(round(float(strs[2])))
            if int(round(float(strs[3]))) < min_z:
                min_z = int(round(float(strs[3])))
    if strs[0] == 'basis':
        print(line.rstrip(),file=fout)
        flag = 2
        continue
    if flag == 2:
        print(line.rstrip(),file=fout)
    if ( strs[0] == 'end' and flag == 2 ):
        flag = 0
        break
print('set geometry system\ndplot',file=fout)
print(' vectors',fname+'.movecs',file=fout)
print(' gaussian',file=fout)
print(' output',outname+'.cube',file=fout)
print(' limitxyz',file=fout)
space_x = (max_x - min_x + 2*margin)*grid
space_y = (max_y - min_y + 2*margin)*grid
space_z = (max_z - min_z + 2*margin)*grid
print(' ', min_x - margin, max_x + margin, space_x, file=fout)
print(' ', min_y - margin, max_y + margin, space_y, file=fout)
print(' ', min_z - margin, max_z + margin, space_z, file=fout)
print(' orbitals view',file=fout)
print(' 1',file=fout)
print(' '+orbital,file=fout)    
print('end',file=fout)
print('task dplot',file=fout)

print(outname+'.nw generated.')    

# Generating .q file
print('#!/bin/bash\n',file=fq)
print('#SBATCH -p',host,file=fq)
print('#SBATCH -n 1',file=fq)
print('#SBATCH --mem=500',file=fq)
print('#SBATCH -t 05:00',file=fq)
#print('#SBATCH --error='+outname+'.err',file=fq)
print('#SBATCH -o slurm.out\n',file=fq)
print("export ARMCI_DEFAULT_SHMMAX=2000",file=fq)
if host == 'et1_old':
    print("module load nwchem/openmpi/6.5-et1_old_multinode",file=fq)
else:
    print('module load nwchem/openmpi/6.5-'+host,file=fq)
print("srun mkdir -p /scr/lz91/nwchem_scr/"+outname,file=fq)
print('srun echo "Running on HOST $HOSTNAME"',file=fq)
print("mpiexec nwchem ./"+outname+".nw >./"+outname+".out",file=fq)
print("wait",file=fq)
print("srun rm -rvf /scr/lz91/nwchem_scr/"+outname,file=fq)

print(outname+'.q generated.')    
