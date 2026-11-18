 task filter_vcf {
	File vcf
	File? bed
	String sample_id = basename(vcf,".vcf")
	String docker
	String cluster_config
	String disk_size
	
	command <<<
		set -e -o pipefail
		call_dir="$PWD"
		copy_task_logs() {
			cp -f "$call_dir/script" "$call_dir/script.txt" 2>/dev/null || true
			cp -f "$call_dir/stdout" "$call_dir/stdout.txt" 2>/dev/null || true
			cp -f "$call_dir/stderr" "$call_dir/stderr.txt" 2>/dev/null || true
		}
		trap copy_task_logs EXIT
		local_work=$(mktemp -d /tmp/filtervcf.XXXXXX)
		cp -f ${vcf} "$local_work/input.vcf"
		if [ ${bed} ]; then cp -f ${bed} "$local_work/input.bed"; fi
		cd "$local_work"
		grep '^#' input.vcf > header
		# DeepVariant marks reference calls in the FILTER column.
		awk -F '\t' '!/^#/ && $7 !~ /(^|;)RefCall(;|$)/' input.vcf > body
		grep -w '^chr1\|^chr2\|^chr3\|^chr4\|^chr5\|^chr6\|^chr7\|^chr8\|^chr9\|^chr10\|^chr11\|^chr12\|^chr13\|^chr14\|^chr15\|^chr16\|^chr17\|^chr18\|^chr19\|^chr20\|^chr21\|^chr22\|^chrX' body > body.filtered || true
		cat header body.filtered > ${sample_id}.filtered.vcf
		if [ ${bed} ];then
			/opt/ccdg/bedtools-2.27.1/bin/bedtools intersect -a ${sample_id}.filtered.vcf -b input.bed > body.bed.filtered
			cat header body.bed.filtered > ${sample_id}.target.filtered.vcf
		fi
		cp -f ${sample_id}.filtered.vcf "$call_dir/"
		if [ ${bed} ]; then cp -f ${sample_id}.target.filtered.vcf "$call_dir/"; fi
	>>>

	runtime {
		docker:docker
		instanceTypes: [cluster_config]
		systemDisk: "cloud " + disk_size
	}
	output {
		File filtered_vcf = "${sample_id}.filtered.vcf"
		Array[File] filtered_bed = glob("${sample_id}.target.filtered.vcf")
	}
}
