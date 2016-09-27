from __future__ import print_function
import sys
import os

print('This program generates sqm input files for quick minimization by PM3.')
if len(sys.argv) == 1:
	print('Insufficient argument.')
	print('Usage: python sqminp.py file1 file2 ...')
	exit()
fname = sys.argv[1:]
host = 'et1_old'
for mole in fname:
	try:
		fhand = open(mole)
	except:
		print('File cannot be opened: ',mole)
		continue
	outname = os.path.splitext(mole)[0]
	fout = open(outname+'.inp','w')
	fq = open(outname+'.q','w')
	print('Run semi-empirical minimization\n &qmmm\n  qmcharge=0,\n /',file=fout)
	for line in fhand:
		element = line.strip().split()[0]
		if element == 'C':
			print('  6 ',line.rstrip(),file=fout)
		elif element == 'H':
			print('  1 ',line.rstrip(),file=fout)
		elif element == 'N':
			print('  7 ',line.rstrip(),file=fout)
		elif element == 'O':
			print('  8 ',line.rstrip(),file=fout)
		elif element == 'F':
			print('  9 ',line.rstrip(),file=fout)
		elif element == 'Cl':
			print(' 17 ',line.rstrip(),file=fout)
		elif element == 'S':
			print(' 16 ',line.rstrip(),file=fout)
	print(outname+'.inp generated.')	
	print('#!/bin/bash\n',file=fq)
	print('#SBATCH -p',host,file=fq)
	print('#SBATCH -n 1',file=fq)
	print('#SBATCH --mem=1500',file=fq)
	print('#SBATCH -t 02:00:00',file=fq)
	#print('#SBATCH --error='+outname+'.err',file=fq)
	print('#SBATCH -o slurm.out',file=fq)
	print('\nmodule load amber14',file=fq)
	print('\nsqm -O -i '+outname+'.inp -o '+outname+'.out',file=fq)
	print(outname+'.q generated.')	
