task ANNOVAR {

  File vcf
  String basename = basename(vcf,".vcf")
  String hg
  File annovar_database
  String docker
  String cluster_config
  String disk_size


  command <<<
    set -o pipefail
    set -e
    nt=$(nproc)

    if [ ${hg} == "hg38" ]; then
    /installations/annovar/table_annovar.pl ${vcf} \
    ${annovar_database} -buildver ${hg} \
    -out ${basename} -remove \
    -protocol refGene,ensGene,knownGene,cytoBand,genomicSuperDups,esp6500siv2_all,ALL.sites.2015_08,AFR.sites.2015_08,AMR.sites.2015_08,EAS.sites.2015_08,EUR.sites.2015_08,SAS.sites.2015_08,avsnp147,dbnsfp33a,clinvar_20210501,gnomad_genome,dbscsnv11,dbnsfp31a_interpro \
    -operation g,g,g,r,r,f,f,f,f,f,f,f,f,f,f,f,f,f \
    -nastring . -vcfinput -thread $nt
    fi

    if [ ${hg} == "hg19" ]; then
    /installations/annovar/table_annovar.pl ${vcf} \
    ${annovar_database} -buildver ${hg} \
    -out ${basename} -remove \
    -protocol refGene,cytoBand,genomicSuperDups,ljb26_all,snp138,cosmic78,intervar_20170202,popfreq_all_20150413,clinvar_20190305 \
    -operation g,r,r,f,f,f,f,f,f \
    -nastring . -vcfinput -thread $nt
    fi
  >>>
  
  runtime {
    docker: docker
		instanceTypes: [cluster_config]
		systemDisk: "cloud " + disk_size
  }

  output {
    File avinput = "${basename}.avinput"
    File multianno_txt = "${basename}.${hg}_multianno.txt"
    File multianno_vcf = "${basename}.${hg}_multianno.vcf"
  }
}