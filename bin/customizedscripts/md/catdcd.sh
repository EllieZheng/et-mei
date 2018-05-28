#!/bin/bash

if [[ $# -gt 2 ]];then
    here=$(pwd)
    output=$1
    files=${@:2}
    echo -e "package require catdcd \ncatdcd -o ${output}.dcd ${files} \nexit" > ${here}/catdcd.tcl
    vmd -dispdev text -e ${here}/catdcd.tcl
else
	echo "Insufficient arguments"
	echo "Syntex: catdcd.sh outputname dcdfile1 dcdfile2 ..."
fi

