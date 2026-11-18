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
		call_dir="$PWD"
		copy_task_logs() {
			cp -f "$call_dir/script" "$call_dir/script.txt" 2>/dev/null || true
			cp -f "$call_dir/stdout" "$call_dir/stdout.txt" 2>/dev/null || true
			cp -f "$call_dir/stderr" "$call_dir/stderr.txt" 2>/dev/null || true
		}
		trap copy_task_logs EXIT
		local_work=$(mktemp -d /tmp/metrics.XXXXXX)
		mkdir -p "$local_work/tmp"
		export TMPDIR="$local_work/tmp"
		export _JAVA_OPTIONS="-Djava.io.tmpdir=$TMPDIR"
		cp -f ${Dedup_bam} "$local_work/input.bam"
		cp -f ${Dedup_bam_index} "$local_work/input.bam.bai"
		cd "$local_work"
		/usr/local/jdk-20.0.1/bin/java -jar /usr/local/picard.jar CollectAlignmentSummaryMetrics \
			-I input.bam \
			-O ${sample_id}_deduped_aln_metrics.txt \
			-R ${ref_dir}/${fasta} \
			--VALIDATION_STRINGENCY LENIENT
		/usr/local/jdk-20.0.1/bin/java -jar /usr/local/picard.jar CollectInsertSizeMetrics \
			-I input.bam \
			-O ${sample_id}_deduped_is_metrics.txt \
			-H ${sample_id}_deduped_is_metrics.pdf
		/usr/local/jdk-20.0.1/bin/java -jar /usr/local/picard.jar CollectQualityYieldMetrics \
			-I input.bam \
			-O ${sample_id}_deduped_QualityYield.txt
		/usr/local/jdk-20.0.1/bin/java -jar /usr/local/picard.jar CollectWgsMetrics \
			-I input.bam \
			-O ${sample_id}_deduped_WgsMetricsAlgo.txt \
			-R ${ref_dir}/${fasta} \
			--VALIDATION_STRINGENCY LENIENT
		
		if [ ${bed} ]; then
		cp -f ${interval_list} interval_list.txt
		/usr/local/jdk-20.0.1/bin/java -jar /usr/local/picard.jar CollectHsMetrics \
			-I input.bam \
			-O ${sample_id}_deduped_HsMetricAlgo.txt \
			--TARGET_INTERVALS interval_list.txt \
			--BAIT_INTERVALS interval_list.txt
		fi
		cp -f ${sample_id}_deduped_*.txt "$call_dir/"

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
