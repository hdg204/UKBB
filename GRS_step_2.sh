#!/bin/bash
process_chromosome() {
    i=$1
    input_file=$2
    grep -w "^$i" $input_file | awk '{print $2}' > bp${i}
    grep -wFf bp${i} "/mnt/project/Bulk/Imputation/UKB imputation from genotype/ukb22828_c${i}_b0_v3.mfi.txt" | awk '{print $2}' > ids${i}
    ./bgenix -g "/mnt/project/Bulk/Imputation/UKB imputation from genotype/ukb22828_c${i}_b0_v3.bgen" -incl-rsids ids${i} | ./qctool -g - -filetype bgen -og chr${i}.bed
}

export -f process_chromosome

input_file=$1
seq 1 22 | parallel -j 4 process_chromosome {} $1

process_chromosome X $1
process_chromosome XY $1

rm mergelist.txt
for i in `seq 1 22`
do
    echo chr${i} >> mergelist.txt
done

echo chrX >> mergelist.txt
echo chrXY >> mergelist.txt

./plink --merge-list mergelist.txt --make-bed --out merged_dataset
awk 'NR>2 {print $1, $1, 0, 0, 0, 0}' "/mnt/project/Bulk/Imputation/UKB imputation from genotype/ukb22828_c1_b0_v3.sample" > merged_dataset.fam

./plink2 --bfile merged_dataset --set-all-var-ids @_# --make-bed --out merged_dataset_2
awk 'NR>1 {print $1"_"$2,$4,$5}' $1 > plink_score
./plink --bfile merged_dataset_2 --score plink_score 1 2 3 --out score
