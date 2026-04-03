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
    	cluster: cluster_config
    	systemDisk: "cloud_ssd 40"
    	dataDisk: "cloud_ssd " + disk_size + " /cromwell_root/"
	}

	output {
		File vcf = "${sample_id}_hc.vcf"
	}
}


