#!/bin/bash

if [[ "$#" -eq "2" ]];then

dir=$1
filename=$2
radius=0
padding=10
outputname="${filename}_minmax"

echo "creating tcl file for finding the center of mass..."

cat > ${dir}/${outputname}.tcl << endmsg1
set molname ${filename}
set dir ${dir}

mol new \${dir}/\${molname}.psf
mol addfile \${dir}/\${molname}.pdb

### Determine the dimensions of the molecule
set all [atomselect top all] 
set minmax [measure minmax \$all] 
set vec [vecsub [lindex \$minmax 1] [lindex \$minmax 0]] 
set center [measure center \$all] 

### Determine the center of mass of the molecule and store the coordinates
set cen [measure center \$all weight mass]
set x1 [lindex \$cen 0]
set y1 [lindex \$cen 1]
set z1 [lindex \$cen 2]
set maxdist 0

### Determine the distance of the farthest atom from the center of mass
foreach atom [[atomselect top all] get index] {
  set pos [lindex [[atomselect top "index \$atom"] get {x y z}] 0]
  set x2 [lindex \$pos 0]
  set y2 [lindex \$pos 1]
  set z2 [lindex \$pos 2]
  set dist [expr pow((\$x2-\$x1)*(\$x2-\$x1) + (\$y2-\$y1)*(\$y2-\$y1) + (\$z2-\$z1)*(\$z2-\$z1),0.5)]
  if {\$dist > \$maxdist} {set maxdist \$dist}
}

puts "Xmax [lindex \$vec 0]" 
puts "Ymax [lindex \$vec 1]" 
puts "Zmax [lindex \$vec 2]" 
puts "cellOrigin \$center" 
puts "farthestAtom: \$maxdist"

mol delete top
exit
endmsg1

echo "finding the dimensions of the molecule..."

vmd -dispdev text -e ${dir}/${outputname}.tcl > ${dir}/${outputname}.log

echo -e "done calculating the dimensions.\n"

else
    echo "Syntax: minmax.sh parent-dir filename"
fi
