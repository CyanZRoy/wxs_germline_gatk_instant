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

		if [ ${bed} ]; then
			MODELTYPE="WES"
		else
			MODELTYPE="WGS"
		fi

		/opt/deepvariant/bin/run_deepvariant \
			--model_type=$MODELTYPE \
			--ref=${ref_dir}/${fasta} \
			--reads=${recaled_bam} \
			--output_vcf=${sample_id}_hc.vcf \
			--num_shards=$(nproc) 
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


