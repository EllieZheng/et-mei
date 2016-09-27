from __future__ import print_function
import sys
import os

print('This program generates vmd input xyz files.')
if len(sys.argv) == 1:
	print('Insufficient argument.')
	print('Usage: python vmdxyz.py file1 file2 ...')
	exit()
fname = sys.argv[1:]
for mole in fname:
	try:
		fhand = open(mole)
	except:
		print('File cannot be opened: ',mole)
		continue
	outname = os.path.splitext(mole)[0]
	fout = open(outname+'_vmd.xyz','w')
	atom = 0
	for line in fhand:
		atom += 1
	fhand.seek(0)
	print(atom,'\n',file=fout)
	for line in fhand:
		print(line.rstrip(),file=fout)

