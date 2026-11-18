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
	call_dir="$PWD"
	copy_task_logs() {
		cp -f "$call_dir/script" "$call_dir/script.txt" 2>/dev/null || true
		cp -f "$call_dir/stdout" "$call_dir/stdout.txt" 2>/dev/null || true
		cp -f "$call_dir/stderr" "$call_dir/stderr.txt" 2>/dev/null || true
	}
	trap copy_task_logs EXIT
	local_work=$(mktemp -d /tmp/annovar.XXXXXX)
	mkdir -p "$local_work/tmp"
	export TMPDIR="$local_work/tmp"
	cp -f ${vcf} "$local_work/input.vcf"
	cd "$local_work"

    if [ ${hg} == "hg38" ]; then
    /installations/annovar/table_annovar.pl input.vcf \
    ${annovar_database} -buildver ${hg} \
    -out ${basename} -remove \
    -protocol refGene,ensGene,knownGene,cytoBand,genomicSuperDups,esp6500siv2_all,ALL.sites.2015_08,AFR.sites.2015_08,AMR.sites.2015_08,EAS.sites.2015_08,EUR.sites.2015_08,SAS.sites.2015_08,avsnp150,dbnsfp42c,clinvar_20220320,gnomad30_genome,dbscsnv11,dbnsfp31a_interpro \
    -operation g,g,g,r,r,f,f,f,f,f,f,f,f,f,f,f,f,f \
    -nastring . -vcfinput -thread $nt
    fi

    if [ ${hg} == "hg19" ]; then
    /installations/annovar/table_annovar.pl input.vcf \
    ${annovar_database} -buildver ${hg} \
    -out ${basename} -remove \
    -protocol refGene,cytoBand,genomicSuperDups,dbnsfp42c,avsnp150,cosmic78,intervar_20180118,popfreq_all_20150413,clinvar_20240917 \
    -operation g,r,r,f,f,f,f,f,f \
    -nastring . -vcfinput -thread $nt
    fi
	cp -f ${basename}.avinput ${basename}.${hg}_multianno.txt ${basename}.${hg}_multianno.vcf "$call_dir/"
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
