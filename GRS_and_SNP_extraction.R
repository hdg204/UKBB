#------------------------------------------------------------------------------
# Script Name: GRS_DNA_Nexus
# Purpose: A function to calculate a genetic risk score on the DNA Nexus platform from the RStudio Workbench implementation
# Author: Dr. Harry Green, University of Exeter
# Date Created: 17/01/23
# Dependencies: depends on the package rbgen being installed. Use install.packages( "http://www.well.ox.ac.uk/~gav/resources/rbgen_v1.1.5.tgz", repos = NULL, type = "source" ) then library('rbgen') to ensure the correct version is installed
# Notes: file_in should be a tab separated file with the columns chromosome, bp, other, effect, weight, where other and effect are the allele codes. If the names are not consistent, they will be renamed, it's the order that matters
#------------------------------------------------------------------------------

generate_grs=function(file_in){
  
  
  # This function just creates a list of file names of bgen files in UKBB. This should be constant across all projects, I think
  create_filenames=function(){
    return(c(
      "../../mnt/project/Bulk/Imputation/UKB\ imputation\ from\ genotype/ukb22828_c1_b0_v3.bgen",
      "../../mnt/project/Bulk/Imputation/UKB\ imputation\ from\ genotype/ukb22828_c2_b0_v3.bgen",
      "../../mnt/project/Bulk/Imputation/UKB\ imputation\ from\ genotype/ukb22828_c3_b0_v3.bgen",
      "../../mnt/project/Bulk/Imputation/UKB\ imputation\ from\ genotype/ukb22828_c4_b0_v3.bgen",
      "../../mnt/project/Bulk/Imputation/UKB\ imputation\ from\ genotype/ukb22828_c5_b0_v3.bgen",
      "../../mnt/project/Bulk/Imputation/UKB\ imputation\ from\ genotype/ukb22828_c6_b0_v3.bgen",
      "../../mnt/project/Bulk/Imputation/UKB\ imputation\ from\ genotype/ukb22828_c7_b0_v3.bgen",
      "../../mnt/project/Bulk/Imputation/UKB\ imputation\ from\ genotype/ukb22828_c8_b0_v3.bgen",
      "../../mnt/project/Bulk/Imputation/UKB\ imputation\ from\ genotype/ukb22828_c9_b0_v3.bgen",
      "../../mnt/project/Bulk/Imputation/UKB\ imputation\ from\ genotype/ukb22828_c10_b0_v3.bgen",
      "../../mnt/project/Bulk/Imputation/UKB\ imputation\ from\ genotype/ukb22828_c11_b0_v3.bgen",
      "../../mnt/project/Bulk/Imputation/UKB\ imputation\ from\ genotype/ukb22828_c12_b0_v3.bgen",
      "../../mnt/project/Bulk/Imputation/UKB\ imputation\ from\ genotype/ukb22828_c13_b0_v3.bgen",
      "../../mnt/project/Bulk/Imputation/UKB\ imputation\ from\ genotype/ukb22828_c14_b0_v3.bgen",
      "../../mnt/project/Bulk/Imputation/UKB\ imputation\ from\ genotype/ukb22828_c15_b0_v3.bgen",
      "../../mnt/project/Bulk/Imputation/UKB\ imputation\ from\ genotype/ukb22828_c16_b0_v3.bgen",
      "../../mnt/project/Bulk/Imputation/UKB\ imputation\ from\ genotype/ukb22828_c17_b0_v3.bgen",
      "../../mnt/project/Bulk/Imputation/UKB\ imputation\ from\ genotype/ukb22828_c18_b0_v3.bgen",
      "../../mnt/project/Bulk/Imputation/UKB\ imputation\ from\ genotype/ukb22828_c19_b0_v3.bgen",
      "../../mnt/project/Bulk/Imputation/UKB\ imputation\ from\ genotype/ukb22828_c20_b0_v3.bgen",
      "../../mnt/project/Bulk/Imputation/UKB\ imputation\ from\ genotype/ukb22828_c21_b0_v3.bgen",
      "../../mnt/project/Bulk/Imputation/UKB\ imputation\ from\ genotype/ukb22828_c22_b0_v3.bgen"))
  }
  filenames=create_filenames()
  
  sample=read.table("../../mnt/project/Bulk/Imputation/UKB\ imputation\ from\ genotype/ukb22828_c1_b0_v3.sample",header=T) #this file has all the samples in it, but there's a dummy line at the start
  eid=sample$ID_1[2:nrow(sample)]
  
  grs_in=read.table(file_in,header=T)
  
  
  #preallocating a dosage matrix
  dosage_matrix=matrix(data=NA,nrow=length(eid),ncol=nrow(grs_in)+1)
  dosage_matrix[,1]=eid
  
  
  #people should be putting these headers on anyway, but in case they're wrong, I've relabelled them
  names(grs_in)=c('chr','bp', 'other','effect','weights')
  nsnps=nrow(grs_in)
  
  grs_in$index=1:nrow(grs_in) #index just goes 1 2 3 ... and helps me keep track of where the SNPs are if they are entered out of order
  
  for (i in 1:22){
    print(paste('extracting SNPs on chromosome',i))
    
    grs_chr_i=grs_in[grs_in$chr==i,] #trying not to use dplyr, but this is just the snps on chromosome i
    
    if (nrow(grs_chr_i)>0){ #if there's nothing on the chromosome just skip it
      #the rbgen package wants the chromosome in two digit form, e.g. '08'
      if (i<10){
        chr=paste('0',i,sep='')
      }else{
        chr=as.character(i)
      }
      
      #this tells rbgen where to look
      ranges = data.frame(
        chromosome = rep(chr,nrow(grs_chr_i)),
        start = grs_chr_i$bp,
        end = grs_chr_i$bp
      )
      data=bgen.load(filenames[i], ranges )# this pulls out the data for all snps on the chromosome. It has to be by chromosome because the dna nexus data is stored in one file per chromosome
      
      for (j in 1:nrow(grs_chr_i)){
        genotypes=rep(NA,length(eid))
        
        #if it doesn't find a variant it causes problems, so I need to match the base pair
        datavar=which(grs_chr_i$bp[j]==data$variants$position) #this is the row in the extracted data that corresponds to the variant j in grs_chr_i
        
        if (length(datavar>0)){ #so only if there's a matching base pair
          # as we loop through the reduced grs_in table for only one chromosome, index[j] will be used to link back to stuff in the original table
          mat=data$data[datavar,,] #the genetic data is in a 3 dimensional (a x b x 3) matrix, where the dimensions are snp (a), sample (b), probability of dosages. I only want the b x 3 bit)
          ref=data$variants[datavar,5] #reference according to bgen
          alt=data$variants[datavar,6] #alternate according to bgen
          eff=grs_chr_i$effect[j] #effect according to input
          oth=grs_chr_i$other[j] #effect according to input
          
          #if labelled the correct way round, then I want the expected genotype for the alt
          if ((alt==eff) & (ref==oth)){ 
            genotypes=as.numeric(mat[,2]+2*mat[,3])
          }
          #if the wrong way round, I want the expected genotype for the ref, because that's the effect allele
          if ((alt==oth) & (ref==eff)){
            genotypes=as.numeric(mat[,2]+2*mat[,1])
          }
          # if they don't match I just leave them all NA
          
          dosage_matrix[,1+grs_chr_i$index[j]]=genotypes
        }
      }
    }
  }
  
  a=dosage_matrix[,2:(nsnps+1)] #this makes a new matrix with only the columns for the genetic data
  b=matrix(grs_in$weights) 
  missing=which(is.na(a[1,]))
  a=a[,-missing]
  b=b[-missing]
  grs=a%*%b #this neat matrix multiplication just makes the GRS
  grs_df=data.frame(eid=eid,grs=grs)
  return(grs_df)
}
