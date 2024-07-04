curl https://www.chg.ox.ac.uk/~gav/resources/bgen_v1.1.4-Ubuntu16.04-x86_64.tgz > bgen.tgz
curl https://www.chg.ox.ac.uk/~gav/resources/qctool_v2.0.8-CentOS_Linux7.6.1810-x86_64.tgz > qctool.tgz
curl https://s3.amazonaws.com/plink1-assets/plink_linux_x86_64_20231211.zip > plink.zip
curl https://s3.amazonaws.com/plink2-assets/plink2_linux_i686_20240625.zip > plink2.zip

tar -xvzf bgen.tgz
tar -xvzf qctool.tgz
unzip -o plink.zip
unzip -o plink2.zip

curl https://ftp.gnu.org/gnu/parallel/parallel-latest.tar.bz2 > parallel-latest.tar.bz2
tar -xjf parallel-latest.tar.bz2
cd parallel-20240622
pwd
./configure --prefix=$HOME/.local
make
make install
export PATH=$HOME/.local/bin:$PATH
cd $home

dx download file-Gb53yZjJj59bVvzJZy28zK7V

alias bgenix='bgen_v1.1.4-Ubuntu16.04-x86_64/bgenix'
alias qctool='qctool_v2.0.8-CentOS\ Linux7.6.1810-x86_64/qctool'
alias plink='./plink'

cp bgen_v1.1.4-Ubuntu16.04-x86_64/bgenix bgenix
cp qctool_v2.0.8-CentOS\ Linux7.6.1810-x86_64 qctool


process_chromosome() {
    i=$1
    grep -w "^$i" Prostate_Cancer_Conti_Score | awk '{print $2}' > bp${i}
    grep -wFf bp${i} "/mnt/project/Bulk/Imputation/UKB imputation from genotype/ukb22828_c${i}_b0_v3.mfi.txt" | awk '{print $2}' > ids${i}
    ./bgenix -g "/mnt/project/Bulk/Imputation/UKB imputation from genotype/ukb22828_c${i}_b0_v3.bgen" -incl-rsids ids${i} | ./qctool -g - -filetype bgen -og chr${i}.bed
}

export -f process_chromosome

seq 1 22 | parallel -j 4 process_chromosome

rm mergelist.txt
for i in `seq 1 22`
do
	echo chr${i} >> mergelist.txt
done

./plink --merge-list mergelist.txt --make-bed --out merged_dataset
awk 'NR>2 {print $1, $1, 0, 0, 0, 0}' "/mnt/project/Bulk/Imputation/UKB imputation from genotype/ukb22828_c1_b0_v3.sample" > merged_dataset.fam

./plink2 --bfile merged_dataset --set-all-var-ids @_# --make-bed --out merged_dataset_2
awk 'NR>1 {print $1"_"$2,$4,$5}' Prostate_Cancer_Conti_Score > plink_score
./plink --bfile merged_dataset_2 --score plink_score 1 2 3 --out score
