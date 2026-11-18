task Haplotyper {
    File ref_dir
	String fasta
	File recaled_bam
	File recaled_bam_index
	File? bed
	String sample_id = basename(recaled_bam,".sorted.deduped.realigned.recaled.bam")
	String docker
	String cluster_config
	String disk_size

command <<<
		set -o pipefail
		set -e
		call_dir="$PWD"
		copy_task_logs() {
			cp -f "$call_dir/script" "$call_dir/script.txt" 2>/dev/null || true
			cp -f "$call_dir/stdout" "$call_dir/stdout.txt" 2>/dev/null || true
			cp -f "$call_dir/stderr" "$call_dir/stderr.txt" 2>/dev/null || true
		}
		trap copy_task_logs EXIT
		local_work=$(mktemp -d /tmp/haplotyper.XXXXXX)
		mkdir -p "$local_work/tmp"
		export TMPDIR="$local_work/tmp"
		cp -f ${recaled_bam} "$local_work/input.bam"
		cp -f ${recaled_bam_index} "$local_work/input.bam.bai"
		cd "$local_work"

		if [ ${bed} ]; then
			MODELTYPE="WES"
		else
			MODELTYPE="WGS"
		fi

		/opt/deepvariant/bin/run_deepvariant \
			--model_type=$MODELTYPE \
			--ref=${ref_dir}/${fasta} \
			--reads=input.bam \
			--output_vcf=${sample_id}_hc.vcf \
			--num_shards=$(nproc) 
		cp -f ${sample_id}_hc.vcf "$call_dir/"
	>>>
	
	runtime {
		docker:docker
		instanceTypes: [cluster_config]
		systemDisk: "cloud " + disk_size
	}

	output {
		File vcf = "${sample_id}_hc.vcf"
	}
}


