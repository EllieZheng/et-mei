#!/bin/bash

if [[ "$#" -eq "3" ]];then

dir=$1
filename=$2
goalnum=$3
radius=32
padding=10
outputname="${filename}_ws_${goalnum}A"

echo "creating tcl file for adding water sphere so that num-water = ${goalnum}..."

cat > ${dir}/${outputname}.tcl << endmsg1
set molname ${filename}
set dir ${dir}

mol new \${dir}/\${molname}.psf
mol addfile \${dir}/\${molname}.pdb

### Determine the center of mass of the molecule and store the coordinates
set cen [measure center [atomselect top all] weight mass]
set x1 [lindex \$cen 0]
set y1 [lindex \$cen 1]
set z1 [lindex \$cen 2]
set defaultRad ${radius}
set padding ${padding}
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

# The default radius is ${radius}A, but if there's not enough padding for this radius,
# we will put a warning message. (it will not be set to the new radius)
set rad \${defaultRad} 
if {[expr \${maxdist}+\${padding}] > \${defaultRad}} {
#    set rad [expr \${maxdist}+\${padding}]
    puts "*********WARNING: WATER SPHERE IS NOT LARGE ENOUGH***********"
}

mol delete top

### Solvate the molecule in a water box with enough padding (${padding} A).
### One could alternatively align the molecule such that the vector 
### from the center of mass to the farthest atom is aligned with an axis,
### and then use no padding
package require solvate
solvate \${dir}/\${molname}.psf \${dir}/\${molname}.pdb -t  [expr \${rad}-\${maxdist} ] -o \${dir}/del_water

resetpsf
package require psfgen
mol new \${dir}/del_water.psf
mol addfile \${dir}/del_water.pdb
readpsf \${dir}/del_water.psf
coordpdb \${dir}/del_water.pdb

### Determine which water molecules need to be deleted and use a for loop
### to delete them
set wat [atomselect top "same residue as {water and ((x-\$x1)*(x-\$x1) + (y-\$y1)*(y-\$y1) + (z-\$z1)*(z-\$z1))<(\$rad*\$rad)}"]
set del [atomselect top "water and not same residue as {water and ((x-\$x1)*(x-\$x1) + (y-\$y1)*(y-\$y1) + (z-\$z1)*(z-\$z1))<(\$rad*\$rad)}"]
set seg [\$del get segid]
set res [\$del get resid]
set name [\$del get name]
for {set i 0} {\$i < [llength \$seg]} {incr i} {
  delatom [lindex \$seg \$i] [lindex \$res \$i] [lindex \$name \$i] 
}
writepsf \${dir}/\${molname}_\${rad}A.psf
writepdb \${dir}/\${molname}_\${rad}A.pdb

mol delete top

### To add a desired number of water molecules, 
### find the water radius and delete the rest of them
resetpsf
package require psfgen
mol new \${dir}/\${molname}_\${rad}A.psf
mol addfile \${dir}/\${molname}_\${rad}A.pdb
readpsf \${dir}/\${molname}_\${rad}A.psf
coordpdb \${dir}/\${molname}_\${rad}A.pdb

set cen [measure center [atomselect top all] weight mass]
set x1 [lindex \$cen 0]
set y1 [lindex \$cen 1]
set z1 [lindex \$cen 2]

set goalnum ${goalnum}
set zero 2

set wat [atomselect top "same residue as {water and ((x-\$x1)*(x-\$x1) + (y-\$y1)*(y-\$y1) + (z-\$z1)*(z-\$z1))<(\$rad*\$rad)}"]
set numwat [expr ([\$wat num])/3]
set currrad \$rad
set minrad 0
set maxrad \$currrad
set oldrad \$rad

while { [expr {[expr abs(\$numwat-\$goalnum)] > \$zero} && {[expr abs(\$maxrad-\$minrad)] > 1}] } {
    puts "current radius: \$currrad"
    puts "current number of water molecules: \$numwat"

    if {\$numwat > \$goalnum} { 
        set oldrad \$currrad
        set maxrad \$currrad 
    } else { 
        set oldrad \$maxrad
        set minrad \$currrad 
    }

    set currrad [expr (\$minrad+\$maxrad)/2]
    set wat [atomselect top "same residue as {water and ((x-\$x1)*(x-\$x1) + (y-\$y1)*(y-\$y1) + (z-\$z1)*(z-\$z1))<(\$currrad*\$currrad)}"]
    set numwat [expr ([\$wat num])/3]
}
set currrad \$oldrad

set del [atomselect top "water and not same residue as {water and ((x-\$x1)*(x-\$x1) + (y-\$y1)*(y-\$y1) + (z-\$z1)*(z-\$z1))<(\$currrad*\$currrad)}"]
set seg [\$del get segid]
set res [\$del get resid]
set name [\$del get name]
for {set i 0} {\$i < [llength \$seg]} {incr i} {
  delatom [lindex \$seg \$i] [lindex \$res \$i] [lindex \$name \$i] 
}

set wat [atomselect top "same residue as {water and ((x-\$x1)*(x-\$x1) + (y-\$y1)*(y-\$y1) + (z-\$z1)*(z-\$z1))<(\$currrad*\$currrad)}"]
set numwat [expr ([\$wat num])/3]

puts "NUMBER OF WATER: \$numwat"
puts "WATER SPHERE RADIUS: \$currrad"

set seg [\$wat get segid]
set res [\$wat get resid]
set name [\$wat get name]
set i 0
while {\$numwat > \$goalnum} {
  delatom [lindex \$seg \$i] [lindex \$res \$i] [lindex \$name \$i] 
  incr i
  delatom [lindex \$seg \$i] [lindex \$res \$i] [lindex \$name \$i] 
  incr i
  delatom [lindex \$seg \$i] [lindex \$res \$i] [lindex \$name \$i] 
  incr i
  incr numwat -1
}

puts "CENTER OF MASS OF SPHERE IS: [measure center [atomselect top all] weight mass]"
puts "RADIUS OF SPHERE IS: \$rad"
puts "FARTHEST ATOM: \$maxdist"

puts "CURRENT NUM OF WATER MOLECULES: \$numwat"
writepsf \${dir}/\${molname}_ws_\${goalnum}A.psf
writepdb \${dir}/\${molname}_ws_\${goalnum}A.pdb

mol delete top

exit
endmsg1

echo "running wat_sphere.tcl for num-water = ${goalnum}..."

vmd -dispdev text -e ${dir}/${outputname}.tcl > ${dir}/${outputname}.log

mv ${dir}/del_water.log  ${dir}/${outputname}_del_water.log
rm ${dir}/del_water.p*
rm ${dir}/${filename}_${radius}A.*
echo -e "adding water sphere for num-water = ${goalnum} done.\n"

else
    echo "Syntax: add-water-by-number.sh parent-dir filename number-of-water"
fi
