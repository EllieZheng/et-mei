#!/bin/bash

if [[ $# -gt 0 ]];then
	if [[ -s "$1_A.pdb" && -s "$1_B.pdb"]];then
		filename=$1
        echo "package require psfgen
mkdir -p psfopt
set molename ${filename}
rm -f psfopt/${molename}.pdb psfopt/${molename}.psf

#topology /home/software/VMD.1.9.2/lib/vmd/plugins/noarch/tcl/readcharmmtop1.1/top_all27_prot_lipid_na.inp
topology /home/lz91/bin/topology/toppar/top_all36_prot.rtf
topology /home/lz91/bin/topology/toppar/top_all36_lipid.rtf
topology /home/lz91/bin/topology/toppar/top_all36_na.rtf

segment U {
 pdb ${molename}_A.pdb
 first NONE
 last NONE
 auto none
}
patch LINK U:8 U:1" > ${filename}.pgn
for i in ${@:2};do
    echo "patch LSN U:$i" >> ${filename}.pgn
done
echo "
coordpdb ${molename}_A.pdb U

segment V {
 pdb ${molename}_B.pdb
 first NONE
 last NONE
 auto none
}
patch LINK V:8 V:1" > ${filename}.pgn
for i in ${@:2};do
    echo "patch LSN V:$i" >> ${filename}.pgn
done
echo "
coordpdb ${molename}_B.pdb U

regenerate angles dihedrals
writepsf psfopt/${molename}.psf
writepdb psfopt/${molename}.pdb

exit
" >> ${filename}.pgn
        module load vmd/1.9.2
        vmd -dispdev text -e ${filename}.pgn
    else
        echo "File does not exist."
    fi

else
	echo "Insufficient arguments"
	echo "Syntex: psfgen-pgn.sh filename patch-res#1 patch-res#2 ..."
fi

