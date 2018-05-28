#!/bin/bash

if [[ "$#" -eq "3" ]];then

dir=$1
filename=$2
goalnum=$3
padding=15
outputname="${filename}_wb_${goalnum}N"

echo "creating tcl file for adding water sphere so that num-water = ${goalnum}..."

cat > ${dir}/${outputname}.tcl << endmsg1
package require solvate

set molname ${filename}
set dir ${dir}
set padding ${padding}
set output ${filename}_${padding}A_tmp

solvate \${dir}/\${molname}.psf \${dir}/\${molname}.pdb -t \${padding} -o \${dir}/\${output}

### To add a desired number of water molecules, 
### find the water box size and delete the rest of them
package require psfgen


mol new \${dir}/\${output}.psf
mol addfile \${dir}/\${output}.pdb
readpsf \${dir}/\${output}.psf
coordpdb \${dir}/\${output}.pdb

### Determine the dimensions of the molecule
set all [atomselect top all] 
set minmax [measure minmax \$all] 
set xmin [lindex [lindex \$minmax 0] 0] 
set ymin [lindex [lindex \$minmax 0] 1] 
set zmin [lindex [lindex \$minmax 0] 2] 
set xmax [lindex [lindex \$minmax 1] 0] 
set ymax [lindex [lindex \$minmax 1] 1] 
set zmax [lindex [lindex \$minmax 1] 2] 
set center [measure center \$all] 

set goalnum ${goalnum}
set zero 2

set currpadding \$padding
set wat [atomselect top "same residue as {water and x < (\$xmax+\${currpadding}) and y < (\$ymax+\${currpadding})  and z < (\$zmax+\${currpadding})y  and x > (\$xmin-\${currpadding}) and y > (\$ymin-\${currpadding}) and z > (\$zmin-\${currpadding})}"]
set numwat [expr ([\$wat num])/3]
set minpadding 0
set maxpadding \$currpadding
set oldpadding \$padding

while { [expr {[expr abs(\$numwat-\$goalnum)] > \$zero} && {[expr abs(\$maxpadding-\$minpadding)] > 1}] } {
    puts "current paddingius: \$currpadding"
    puts "current number of water molecules: \$numwat"

    if {\$numwat > \$goalnum} { 
        set oldpadding \$currpadding
        set maxpadding \$currpadding 
    } else { 
        set oldpadding \$maxpadding
        set minpadding \$currpadding 
    }

    set currpadding [expr (\$minpadding+\$maxpadding)/2]
    set wat [atomselect top "same residue as {water and x < (\$xmax+\${currpadding}) and y < (\$ymax+\${currpadding})  and z < (\$zmax+\${currpadding})y  and x > (\$xmin-\${currpadding}) and y > (\$ymin-\${currpadding}) and z > (\$zmin-\${currpadding})}"]
    set numwat [expr ([\$wat num])/3]
}
set currpadding \$oldpadding

mol delete top

solvate \${dir}/\${molname}.psf \${dir}/\${molname}.pdb -t \${currpadding} -o \${dir}/\${molname}_\${currpadding}A_tmp

resetpsf
mol new \${dir}/\${molname}_\${currpadding}A_tmp.psf
mol addfile \${dir}/\${molname}_\${currpadding}A_tmp.pdb
readpsf \${dir}/\${molname}_\${currpadding}A_tmp.psf
coordpdb \${dir}/\${molname}_\${currpadding}A_tmp.pdb

set wat [atomselect top "water"]
set numwat [expr ([\$wat num])/3]

puts "NUMBER OF WATER: \$numwat"
puts "WATER BOX PADDING: \$currpadding"

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

set wat [atomselect top "water"]
set numwat [expr ([\$wat num])/3]

### Determine the dimensions of the molecule
set all [atomselect top all] 
set minmax [measure minmax \$all] 
set vec [vecsub [lindex \$minmax 1] [lindex \$minmax 0]] 
set center [measure center \$all] 

puts "Xmax [lindex \$vec 0]" 
puts "Ymax [lindex \$vec 1]" 
puts "Zmax [lindex \$vec 2]" 
puts "cellOrigin \$center" 
puts "CURRENT NUM OF WATER MOLECULES: \$numwat"

writepsf \${dir}/\${molname}_wb_\${goalnum}N.psf
writepdb \${dir}/\${molname}_wb_\${goalnum}N.pdb

mol delete top

exit
endmsg1

echo "running add-water-by-number.tcl for num-water = ${goalnum}..."

vmd -dispdev text -e ${dir}/${outputname}.tcl > ${dir}/${outputname}.log

rm ${dir}/*tmp*

echo -e "adding water sphere for num-water = ${goalnum} done.\n"

else
    echo "Syntax: add-water-by-number.sh parent-dir filename number-of-water"
fi
