#!/bin/bash

# This script is to generate and run tcl files for calculating the RMSD in VMD

if [[ "$#" -gt "2" ]];then

rootdir=$1
psfdir="psfopt"
mddir="mdrun"
rmsddir="rmsd"
molname=$2
extension=$3 # for example, "md"
inputname="${molname}_${extension}"
outputname="${molname}_rmsd"

if [[ "$4" -eq "10" ]];then
    chain="all chain D or chain E"
else
    chain="all chain C or chain D"
fi

firstframe="0"
lastframe="-1"
step="1"

echo "creating tcl file for calculating the RMSD..."

mkdir -p ${rootdir}/${rmsddir}

cat > ${rootdir}/${rmsddir}/${outputname}.tcl << endmsg1
set molname ${molname}
set psfdir ${rootdir}/${psfdir}
set mddir ${rootdir}/${mddir}
set dcdname ${inputname}
set outputfile1 [open "${rootdir}/${rmsddir}/${outputname}_protein.dat" w]
set outputfile2 [open "${rootdir}/${rmsddir}/${outputname}_all.dat" w]
set outputfile3 [open "${rootdir}/${rmsddir}/${outputname}_middle.dat" w]
set firstframe ${firstframe}
set lastframe ${lastframe}
set step ${step}

put "loading dcd..."
mol new \${psfdir}/\${molname}.psf type psf
mol addfile \${mddir}/\${dcdname}.dcd type dcd first \${firstframe} last \${lastframe} step \${step} filebonds 1 autobonds 1 waitfor all
put "dcd loaded."
set numframes [molinfo top get numframes]



put "calculating rmsd for the protein only"

set sel [atomselect top protein]
set frame0 [atomselect top protein frame 0]

### run rmsd calculation loop for the protein
for {set i 0} {\$i < \$numframes} {incr i} {
    \$sel frame \$i
    \$sel move [measure fit \$sel \$frame0]
    puts \$outputfile1 "[measure rmsd \$sel \$frame0]"
}



put "calculating rmsd for the whole system"

set sel [atomselect top all]
set frame0 [atomselect top all frame 0]

### run rmsd calculation loop for the whole system
for {set i 0} {\$i < \$numframes} {incr i} {
    \$sel frame \$i
    \$sel move [measure fit \$sel \$frame0]
    puts \$outputfile2 "[measure rmsd \$sel \$frame0]"
}



put "calculating rmsd for the middle two peptides"

set sel [atomselect top "$chain"]
set frame0 [atomselect top "$chain" frame 0]

### run rmsd calculation loop for the middle two peptides
for {set i 0} {\$i < \$numframes} {incr i} {
    \$sel frame \$i
    \$sel move [measure fit \$sel \$frame0]
    puts \$outputfile3 "[measure rmsd \$sel \$frame0]"
}


close \$outputfile1
close \$outputfile2
close \$outputfile3

exit
endmsg1

echo "creating sbatch file for calculating the RMSD..."

cat > ${rootdir}/${rmsddir}/${outputname}.q << endmsg2
#!/bin/bash
  
#SBATCH -p et3,et4a
#SBATCH -x et021,et033
#SBATCH -N 1
#SBATCH -n 10
#SBATCH --mem-per-cpu=1500
#SBATCH -t 1-00:00:00

filename="${rootdir}/${rmsddir}/${outputname}"
echo "==================================================================" >> \${filename}.log
echo "Start at \`date\`" >> \${filename}.log
vmd -dispdev text -e \${filename}.tcl >> \${filename}.log
echo "End at \`date\`" >> \${filename}.log
echo "==================================================================" >> \${filename}.log >> \${filename}.log

endmsg2

vim ${rootdir}/${rmsddir}/${outputname}.q
sbatch ${rootdir}/${rmsddir}/${outputname}.q

else
    echo "Make sure you are in the root directory. The output files will be in the /rmsd directory."
    echo "Syntax: rmsd.sh parent-dir(e.g., \$(pwd)) molname extension(e.g., md) num-of-peptides(default:6)"
fi
