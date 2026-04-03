task deduped_Metrics {

    File ref_dir
    File? bed
	String fasta
	File Dedup_bam
	File Dedup_bam_index
	File? interval_list
	String sample_id = basename(Dedup_bam,".sorted.deduped.bam")
	String docker
	String cluster_config
	String disk_size


	command <<<
		set -o pipefail
		set -e
		nt=$(nproc)
		/usr/local/jdk-20.0.1/bin/java -jar /usr/local/picard.jar CollectAlignmentSummaryMetrics \
			-I ${Dedup_bam} \
			-O ${sample_id}_deduped_aln_metrics.txt \
			-R ${ref_dir}/${fasta} \
			--VALIDATION_STRINGENCY LENIENT
		/usr/local/jdk-20.0.1/bin/java -jar /usr/local/picard.jar CollectInsertSizeMetrics \
			-I ${Dedup_bam} \
			-O ${sample_id}_deduped_is_metrics.txt \
			-H ${sample_id}_deduped_is_metrics.pdf
		/usr/local/jdk-20.0.1/bin/java -jar /usr/local/picard.jar CollectQualityYieldMetrics \
			-I ${Dedup_bam} \
			-O ${sample_id}_deduped_QualityYield.txt
		/usr/local/jdk-20.0.1/bin/java -jar /usr/local/picard.jar CollectWgsMetrics \
			-I ${Dedup_bam} \
			-O ${sample_id}_deduped_WgsMetricsAlgo.txt \
			-R ${ref_dir}/${fasta} \
			--VALIDATION_STRINGENCY LENIENT
		
		if [ ${bed} ]; then
		/usr/local/jdk-20.0.1/bin/java -jar /usr/local/picard.jar CollectHsMetrics \
			-I ${Dedup_bam} \
			-O ${sample_id}_deduped_HsMetricAlgo.txt \
			--TARGET_INTERVALS ${interval_list} \
			--BAIT_INTERVALS ${interval_list}
		fi

	>>>

	runtime {
		docker:docker
		instanceTypes: [cluster_config]
		systemDisk: "cloud " + disk_size
	}

	output {
		File dedeuped_aln_metrics = "${sample_id}_deduped_aln_metrics.txt"
		File deduped_is_metrics = "${sample_id}_deduped_is_metrics.txt"
		File deduped_QualityYield = "${sample_id}_deduped_QualityYield.txt"
		File deduped_wgsmetrics = "${sample_id}_deduped_WgsMetricsAlgo.txt"
		File deduped_hsmetrics = "${sample_id}_deduped_HsMetricAlgo.txt"
	}
}