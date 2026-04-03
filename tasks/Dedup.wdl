task Dedup {
	File sorted_bam
	File sorted_bam_index
	String sample_id = basename(sorted_bam,".sorted.bam")
	String docker
	String cluster_config
	String disk_size


	command <<<
		set -o pipefail
		set -e

		/usr/local/jdk-20.0.1/bin/java -jar /usr/local/picard.jar  MarkDuplicates \
					-I ${sorted_bam}  \
					-O ${sample_id}.sorted.deduped.bam \
					-M ${sample_id}_dedup_metrics.txt \
					--REMOVE_DUPLICATES \
					--VALIDATION_STRINGENCY LENIENT
					
		/usr/local/samtools-1.17/bin/samtools index -@ $(nproc) -o  ${sample_id}.sorted.deduped.bam.bai  ${sample_id}.sorted.deduped.bam
	>>>
	runtime {
		docker:docker
		instanceTypes: [cluster_config]
		systemDisk: "cloud " + disk_size
	}

	output {
		File Dedup_bam = "${sample_id}.sorted.deduped.bam"
		File Dedup_bam_index = "${sample_id}.sorted.deduped.bam.bai"
		File dedup_metrics_file = "${sample_id}_dedup_metrics.txt"
	}
}






