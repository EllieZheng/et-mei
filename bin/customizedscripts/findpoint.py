from __future__ import print_function
import sys
import numpy
import os

print('This program calculates the integrated OS below a certain cutoff excitation energy')
if len(sys.argv) < 8:
    print('Insufficient argument.')
    print('Usage: findpoint c4h6_b_t_tda_field $lowlimit $uplimit $grid $min $max $interval')
    exit()
outputfile = sys.argv[1]
lowlimit = int(sys.argv[2])
uplimit = int(sys.argv[3])
grid = int(sys.argv[4])
minene = float(sys.argv[5])
maxene = float(sys.argv[6])
interval = float(sys.argv[7])
moleculename = os.path.splitext(outputfile)[0]
fout = open('joint_'+moleculename+'_from_'+sys.argv[2]+'_to_'+sys.argv[3]+'.point','w')

#print the title, i.e., the cutoff energies
print('field   ',file=fout, end="")
for ene in numpy.arange(minene, maxene, interval):
    print('%.5f   ' % ene,file=fout, end="")
print('\n',file=fout, end="")

#Loop through all the files, i.e., field strength
for field in range(lowlimit, uplimit+grid, grid):
    print(field, file=fout, end="")
    filename = moleculename+'_'+str(field)
    try:
        fdos = open(filename+'.out.DOSD')
    except:
        print('File cannot be opened: ',fdos)
        exit()
    fpoint = open(filename+'.out.point','w')
    #skip the headers
    next(fdos)
    next(fdos)
    #Loop through all the interested points
    for cutoff in numpy.arange(minene, maxene, interval):
        status = 0
        lastene = 0
        lastios = 0
        for line in fdos:
            energy = float(line.strip().split()[0])
            if energy > cutoff:
                print('%.5f  '%lastene+lastios,file=fpoint)
                print('    '+lastios, file=fout, end="")
                status = 1
                break
            lastene = energy
            lastios = line.strip().split()[2]
        if status == 0:
            print('%.5f  0'%energy,file=fpoint)
            print('    0', file=fout, end="")
    print('\n', file=fout, end="")
    print(filename, 'done.')
