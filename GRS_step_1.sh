#!/bin/bash

curl https://www.chg.ox.ac.uk/~gav/resources/bgen_v1.1.4-Ubuntu16.04-x86_64.tgz > bgen.tgz
curl https://www.chg.ox.ac.uk/~gav/resources/qctool_v2.0.8-CentOS_Linux7.6.1810-x86_64.tgz > qctool.tgz
curl https://s3.amazonaws.com/plink1-assets/plink_linux_x86_64_20231211.zip > plink.zip


curl -s https://s3.amazonaws.com/plink2-assets/ > plinkweb
grep -oP 'plink2_linux_x86_64_\d{8}.zip' plinkweb | sort | tail -n 1 > plinkfile
curl -o plink2.zip $(paste -d "" <(echo -n "https://s3.amazonaws.com/plink2-assets/") plinkfile)

curl https://s3.amazonaws.com/plink2-assets/plink2_linux_x86_64_20240806.zip > herpderp

tar -xvzf bgen.tgz
tar -xvzf qctool.tgz
unzip -o plink.zip
unzip -o plink2.zip

curl https://ftp.gnu.org/gnu/parallel/parallel-latest.tar.bz2 > parallel-latest.tar.bz2
tar -xjf parallel-latest.tar.bz2

dx download file-Gb53yZjJj59bVvzJZy28zK7V

cp bgen_v1.1.4-Ubuntu16.04-x86_64/bgenix bgenix
cp qctool_v2.0.8-CentOS\ Linux7.6.1810-x86_64/qctool qctool
