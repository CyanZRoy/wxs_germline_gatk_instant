 task filter_vcf {
	File vcf
	File? bed
	String sample_id = basename(vcf,".vcf")
	String docker
	String cluster_config
	String disk_size
	
	command <<<

		cat ${vcf} | grep '#' > header
		cat ${vcf} | grep -v '#' > body
		cat body | grep -w '^chr1\|^chr2\|^chr3\|^chr4\|^chr5\|^chr6\|^chr7\|^chr8\|^chr9\|^chr10\|^chr11\|^chr12\|^chr13\|^chr14\|^chr15\|^chr16\|^chr17\|^chr18\|^chr19\|^chr20\|^chr21\|^chr22\|^chrX' > body.filtered
		cat header body.filtered > ${sample_id}.filtered.vcf
		if [ ${bed} ];then
			/opt/ccdg/bedtools-2.27.1/bin/bedtools intersect -a ${sample_id}.filtered.vcf -b ${bed} > body.bed.filtered
			cat header body.bed.filtered > ${sample_id}.target.filtered.vcf
		fi
	>>>

	runtime {
		docker:docker
		instanceTypes: [cluster_config]
		systemDisk: "cloud " + disk_size
	}
	output {
		File filtered_vcf = "${sample_id}.filtered.vcff"
		Array[File] filtered_bed = glob("${sample_id}.target.filtered.vcf")
	}
}