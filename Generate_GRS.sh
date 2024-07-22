#!/bin/bash

# Download and extract required tools
curl -o bgen.tgz https://www.chg.ox.ac.uk/~gav/resources/bgen_v1.1.4-Ubuntu16.04-x86_64.tgz
curl -o qctool.tgz https://www.chg.ox.ac.uk/~gav/resources/qctool_v2.0.8-CentOS_Linux7.6.1810-x86_64.tgz
curl -o plink.zip https://s3.amazonaws.com/plink1-assets/plink_linux_x86_64_20231211.zip
curl -o plink2.zip https://s3.amazonaws.com/plink2-assets/plink2_linux_i686_20240625.zip

tar -xvzf bgen.tgz
tar -xvzf qctool.tgz
unzip plink.zip
unzip plink2.zip

curl -o parallel-latest.tar.bz2 https://ftp.gnu.org/gnu/parallel/parallel-latest.tar.bz2
tar -xjf parallel-latest.tar.bz2
cd parallel-*
./configure --prefix=$HOME/.local
make
make install
export PATH=$HOME/.local/bin:$PATH
cd ..

# Create aliases for tools
alias bgenix='bgen_v1.1.4-Ubuntu16.04-x86_64/bgenix'
alias qctool='qctool_v2.0.8-CentOS\ Linux7.6.1810-x86_64/qctool'
alias plink='./plink'
alias plink2='./plink2'

# Define the function to process each chromosome file
process_chromosome() {
    i=$1
    input_file=$2
    
    grep -w "^$i" "$input_file" | awk '{print $2}' > bp${i}
    grep -wFf bp${i} "/mnt/project/Bulk/Imputation/UKB imputation from genotype/ukb22828_c${i}_b0_v3.mfi.txt" | awk '{print $2}' > ids${i}
    bgenix -g "/mnt/project/Bulk/Imputation/UKB imputation from genotype/ukb22828_c${i}_b0_v3.bgen" -incl-rsids ids${i} | qctool -g - -filetype bgen -og chr${i}.bed
}

export -f process_chromosome

# Ensure input file is provided
if [ -z "$1" ]; then
    echo "Usage: $0 <input_file>"
    exit 1
fi

input_file=$1

# Use GNU parallel to run the function for each chromosome concurrently
seq 1 22 | parallel -j 4 process_chromosome {} $input_file

# Create the merge list
rm -f mergelist.txt
for i in $(seq 1 22); do
    echo chr${i} >> mergelist.txt
done

# Merge the PLINK files
plink --merge-list mergelist.txt --make-bed --out merged_dataset

# Create .fam file
awk 'NR>2 {print $1, $1, 0, 0, 0, 0}' "/mnt/project/Bulk/Imputation/UKB imputation from genotype/ukb22828_c1_b0_v3.sample" > merged_dataset.fam

# Set all variant IDs and make a new binary file
plink2 --bfile merged_dataset --set-all-var-ids @_# --make-bed --out merged_dataset_2

# Generate PLINK score file
awk 'NR>1 {print $1"_"$2,$4,$5}' "$input_file" > plink_score

# Calculate the score
plink --bfile merged_dataset_2 --score plink_score 1 2 3 --out score

