#!/bin/bash
process_chromosome() {
    i=$1
    input_file=$2
    grep -w "^$i" $input_file | awk '{print $2,$3,$4}' > bp_alleles${i}
    grep -wFf  bp_alleles${i} "/mnt/project/Bulk/Imputation/UKB imputation from genotype/ukb22828_c${i}_b0_v3.mfi.txt" | awk '{print $2}' > ids${i}
    ./bgenix -g "/mnt/project/Bulk/Imputation/UKB imputation from genotype/ukb22828_c${i}_b0_v3.bgen" -incl-rsids ids${i} | ./qctool -g - -filetype bgen -og chr${i}.bed
}

target_directory=$(find . -type d -name 'parallel-202*' -print -quit)
cd "$target_directory"

./configure --prefix=$HOME/.local
make
make install
export PATH=$HOME/.local/bin:$PATH
cd $home

alias bgenix='bgen_v1.1.4-Ubuntu16.04-x86_64/bgenix'
alias qctool='qctool_v2.0.8-CentOS\ Linux7.6.1810-x86_64/qctool'
alias plink='./plink'


export -f process_chromosome

input_file=$1
seq 1 22 | parallel -j 4 process_chromosome {} $1

process_chromosome X $1
process_chromosome XY $1

rm mergelist.txt
for i in `seq 1 22`
do
    if [ -f chr${i}.bim ]; then
        echo chr${i} >> mergelist.txt
    fi
done

if [ -f chrX.bim ]; then
    echo chrX >> mergelist.txt
fi

if [ -f chrXY.bim ]; then
    echo chrXY >> mergelist.txt
fi

./plink --merge-list mergelist.txt --make-bed --out merged_dataset
awk 'NR>2 {print $1, $1, 0, 0, 0, 0}' "/mnt/project/Bulk/Imputation/UKB imputation from genotype/ukb22828_c1_b0_v3.sample" > merged_dataset.fam

./plink2 --bfile merged_dataset --set-all-var-ids @_# --make-bed --out merged_dataset_2
awk 'NR>1 {print $1"_"$2,$4,$5}' $1 > plink_score
./plink --bfile merged_dataset_2 --score plink_score 1 2 3 --out score
