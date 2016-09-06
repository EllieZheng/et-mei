# .bashrc

# Source global definitions
if [ -f /etc/bashrc ]; then
    . /etc/bashrc
fi

# User specific aliases and functions

export TERM=xterm-256color
# don't put duplicate lines or lines starting with space in the history.
# See bash(1) for more options
HISTCONTROL=ignoreboth

# append to the history file, don't overwrite it
shopt -s histappend

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE=1000
HISTFILESIZE=2000

# some more ls aliases
alias la='ls -alh --color=auto'
alias ll='ls -CFlh --color=auto'

# Add an "alert" alias for long running commands.  Use like so:
#   sleep 10; alert
alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'

# slurm commands
alias sqlz='squeue -o "%.9i %.9P %.40j %.8u %.2t %.10M %.6D %R" -u lz91'
alias sqet='squeue -o "%.9i %.9P %.40j %.8u %.2t %.10M %.6D %R" -p et2,et1_old,et1_new,et2fast'
alias etmem='scontrol -o show nodes | awk '"'"' {print $1,"\t", $4,"\t", $6,"\t", $14,"\t", $15,"\t", $18}'"'"' | grep "et"'
export dnb03='lz91@dnb03.chem.duke.edu'
export dscr='lz91@dscr-slogin-01.oit.duke.edu'

# Applications 
export PATH=$HOME/bin:$PATH
export PATH="$HOME/bin/Mathematica/10.4/Executables":$PATH
export PATH="$HOME/bin/customizedscripts":$PATH
#export PATH="/home/software/nwchem-6.5/bin":$PATH
#export PATH="/home/software/nwchem-6.5-et1-old/bin":$PATH
#export PATH="/home/software/openmpi-1.8.6/bin":$PATH
#source /usr/local/bin/compilervars.sh intel64
module load g09
module load matlab
module load ghemical
module load amber14
module load pqs

# use "up 4" instead of cd ../../../..
up (){
        local d=""
        limit=$1
        for ((i=1; i<=limit; i++))
            do
                d=$d/..
            done
        d=$(echo $d | sed 's/^\///')
        if [ -z "$d" ]; then
            d=..
        fi
        cd $d
}

# extract archives
extract () {
     if [ -f $1 ] ; then
         case $1 in
             *.tar.bz2)   tar xjf $1        ;;
             *.tar.gz)    tar xzf $1     ;;
             *.bz2)       bunzip2 $1       ;;
             *.rar)       rar x $1     ;;
             *.gz)        gunzip $1     ;;
             *.tar)       tar xf $1        ;;
             *.tbz2)      tar xjf $1      ;;
             *.tgz)       tar xzf $1       ;;
             *.zip)       unzip $1     ;;
             *.Z)         uncompress $1  ;;
             *.7z)        7z x $1    ;;
             *)           echo "'$1' cannot be extracted via extract()" ;;
         esac
     else
         echo "'$1' is not a valid file"
     fi
}

# cd into the last changed directory
cl()
{
        last_dir="$(ls -Frt | grep '/$' | tail -n1)"
        if [ -d "$last_dir" ]; then
                cd "$last_dir"
        fi
}

# remove all empty files
rmempty()
{
        for i in *; do [ ! -s $i ] && rm -rf $i; done
}

# generate correct geometry format from Chem3D output .xyz file
chemdrawxyz(){
    if [[ "$#" -eq "1" ]];then
        tail -n+2 $1 | awk '{printf(" %3s \t%14s \t%14s \t%14s\n",$2,$3,$4,$5)}' > $1.tmp
        mv $1.tmp $1
    else
        echo "Insufficient arguments"
        echo "Syntex: chemdrawxyz filename"

    fi
}
# extract the coordinates from NWChem geometry optimization files
coordinates(){
    if [[ ! -z "$1" ]];then
        awk '/Output coordinate/{r=""};/Output coordinate/,/Atomic Mass/{r=(r=="")? $0 : r RS $0};END{print r}' $1 | head -n-2 | tail -n+5 | awk '{printf(" %3s \t%14s \t%14s \t%14s\n",$2,$4,$5,$6)}' > ${1%.*}.xyz
    else
        echo "Insufficient arguments: coordinates filename"
    fi
}
# extract the coordinates from sqm geometry optimization files
sqmcoordinates(){
    if [[ ! -z "$1" ]];then
        awk '/Final Structure/{r=""};/Final Structure/,/Calculation Completed/{r=(r=="")? $0 : r RS $0};END{print r}' $1 | head -n-2 | tail -n+5 | awk '{printf(" %3s \t%14s \t%14s \t%14s\n",$4,$5,$6,$7)}' > ${1%.*}_sqm.xyz
    else
        echo "Insufficient arguments"
    fi
}
# extract the orbitals from NWChem output files
orbitals(){
    if [[ ! -z "$1" ]];then
        awk '/DFT Final Molecular Orbital Analysis/{r=""};/DFT Final Molecular Orbital Analysis/,/center of mass/{r=(r=="")? $0 : r RS $0};END{print r}' $1 > $1.fullorbene
        awk '/DFT Final Molecular Orbital Analysis/{r=""};/DFT Final Molecular Orbital Analysis/,/center of mass/{r=(r=="")? $0 : r RS $0};END{print r}' $1 | grep 'Vector' > $1.fullorb
        cut -c 35-48 $1.fullorb | sed 's/D/E/' | awk '{ print sprintf("%.8f", $1); }' > $1.orb2.tmp
        awk '{print $2}' $1.fullorb > $1.orb1.tmp
        paste $1.orb1.tmp $1.orb2.tmp | column -s $'\t' -t > $1.orb.tmp
            awk -F" " -v name="Energy levels  $1" 'BEGIN {print name; print "level\tEnergy (a.u.)\tEnergy (eV)";}
                    {$(NF+1)=sprintf("%.7f", $2*27.21138505);}1' OFS="\t" $1.orb.tmp > $1.orb
        rm -f $1.orb1.tmp $1.orb2.tmp $1.orb.tmp
        awk '/2.000000/{a=$0};/0.000000/{print a;print $0;exit}' $1.fullorb > $1.hl
        cut -c 35-48 $1.hl | sed 's/D/E/' | awk '{ print sprintf("%.8f", $1); }' > $1.hl.tmp
            awk -F" " -v name="HOMO/LUMO  $1" 'BEGIN {print name; print "Energy (a.u.)\tEnergy (eV)";}
                    {$(NF+1)=sprintf("%.7f", $1*27.21138505);}1' OFS="\t" $1.hl.tmp > $1.hl
        rm $1.hl.tmp
    else
        echo "Insufficient arguments"
    fi
}
# grep the energy and oscillator strength data from the NWChem TDDFT output files, and calculate the integrated OS
dos () {
    if [[ ! -z "$1" ]];then
        awk '/'Root'/ {print $7}' $1 > $1.ene
        awk '/'Oscillator'/ {print $4}' $1 > $1.dos
        title="$1"
        paste $1.ene $1.dos | column -s $'\t' -t > $1.DOSD0
        IOS=0
        awk -F" " -v name="$title" 'BEGIN {print name; print "delta E(eV)\tOS\t\tIntegrated OS";}
                {IOS=IOS+$2;$(NF+1)=IOS;}1' OFS="\t\t" $1.DOSD0 > $1.DOSD
        rm -f $1.ene $1.dos $1.DOSD0
     else
        echo "Insufficient arguments"
     fi
}
# grep the energy and oscillator strength data from the Gaussian TDDFT output files, and calculate the integrated OS
dosgau () {
    if [[ ! -z "$1" ]];then
        awk '/'"Excited State"'/ {print $5}' $1 > $1.ene
        awk '/'"Excited State"'/ {print $9}' $1 | cut -f2 -d"="> $1.dos
        title="$1"
        paste $1.ene $1.dos | column -s $'\t' -t > $1.DOSD0
        IOS=0
        awk -F" " -v name="$title" 'BEGIN {print name; print "delta E(eV)\tOS\t\tIntegrated OS";}
                {IOS=IOS+$2;$(NF+1)=IOS;}1' OFS="\t\t" $1.DOSD0 > $1.DOSD
        rm -f $1.ene $1.dos $1.DOSD0
     else
        echo "No argument supplied"
     fi
}


# for atom: grep the energy and oscillator strength data from the NWChem TDDFT output files, and calculate the integrated OS
dosatom () {
    if [[ ! -z "$1" ]];then
        awk '/'Root'/ {print $6}' $1 > $1.ene
        awk '/'Oscillator'/ {print $4}' $1 > $1.dos
        title="$1"
        paste $1.ene $1.dos | column -s $'\t' -t > $1.DOSD0
        IOS=0
        awk -F" " -v name="$title" 'BEGIN {print name; print "delta E(eV)\tOS\t\tIntegrated OS";}
                {IOS=IOS+$2;$(NF+1)=IOS;}1' OFS="\t\t" $1.DOSD0 > $1.DOSD
        rm -f $1.ene $1.dos $1.DOSD0
     else
        echo "Insufficient arguments"
     fi
}
# grep the orbital energies from the NWChem TDDFT output files
ene () {
    if [[ ! -z "$1" ]];then
        awk '/'Vector'/ {print $2 $3 $4}' $1 > $1.ene
    else
        echo "Insufficient arguments"
    fi
}


# to find the integrated os data point at certain excitation energy
findpoint () {
   if [[ ! -z "$1" && ! -z "$2" ]];then
        limit="$2"
#       awk -F"\t\t" -v point="$limit" '$1<=point{print $1, $3)}' OFS="   " $1.DOSD > $1.point0
        awk -F"\t\t" -v point="$limit" '$1<=point{printf("%7.4f   %7.5f\n", $1, $3)}' $1.DOSD > $1.point0
        if [ -s $1.point0 ];then
                tail -1 $1.point0 >> $1.point
        else
                awk -v point="$limit" 'BEGIN{printf("%7.4f   %7.5f\n", point, 0)}' >> $1.point
        fi
    else
        echo "Insufficient arguments"
    fi
}
# duplicate the files for restarting a job
res(){  
        if [ -z "$2" ];then
                echo "No suffix for existing job supplied"
        else    
                cp $1.nw $1_$2.nw
                cp $1.db $1_$2.db
                mv $1.movecs $1_$2.movecs
                mv $1.out $1_$2.out
                mv $1.err $1_$2.err
                vi $1.nw
        fi
}
# duplicate the nw files that are similar to each other except for some minor parameters
dup (){
   if [[ ! -z "$1" && ! -z "$2" ]];then
        if [ -s $1.sh ];then
                sed 's/'"$1"'/'"$2"'/g' $1.sh > $2.sh
                vi $2.sh
        else
                sed 's/'"$1"'/'"$2"'/g' $1.q > $2.q
                vi $2.q
        fi
        if [ -s $1.nw ];then
                sed 's/'"$1"'/'"$2"'/g' $1.nw > $2.nw
                vi $2.nw
        else
                sed 's/'"$1"'/'"$2"'/g' $1.inp > $2.inp
                vi $2.inp
        fi
   else
        echo "Insufficient arguments"
   fi
}
# change nodes
to_et1_old(){
    if [[ -s "$1.sh" ]];then
        sed -i 's/SBATCH -p et2/SBATCH -p et1_old/g;s/6.5-et2/6.5-et1_old_multinode/g' $1.sh 
        vi $1.sh
    else
        echo "File $1.sh does not exist."
    fi
}
to_et2(){
    if [[ -s "$1.sh" ]];then
        sed -i 's/SBATCH -p et1_old/SBATCH -p et2/g;s/6.5-et1_old_multinode/6.5-et2/g' $1.sh
        vi $1.sh
    else
        echo "File $1.sh does not exist."
    fi
}

# submit jobs in batch
sbatchfiles(){
    if [[ ! -z "$1" && ! -z "$2" && ! -z "$3" && ! -z "$4" ]];then
        lowlimit="$2"
        uplimit="$3"
        grid="$4"
        for((i=lowlimit;i<=uplimit;i=i+grid));do
                if [[ -s $1_$i.sh ]];then
                        sbatch $1_$i.sh
                fi
                if [[ -s $1_$i.q ]];then
                        sbatch $1_$i.q
                fi
        done
    else
        echo "Insufficient arguments"
    fi
}
# gcc compiler
gccp(){
    if [[ -s $1 ]];then
        gcc -o ${1%.*} $1 -lm
    fi
}
