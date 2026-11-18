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
		call_dir="$PWD"
		copy_task_logs() {
			cp -f "$call_dir/script" "$call_dir/script.txt" 2>/dev/null || true
			cp -f "$call_dir/stdout" "$call_dir/stdout.txt" 2>/dev/null || true
			cp -f "$call_dir/stderr" "$call_dir/stderr.txt" 2>/dev/null || true
		}
		trap copy_task_logs EXIT
		local_work=$(mktemp -d /tmp/dedup.XXXXXX)
		mkdir -p "$local_work/tmp"
		export TMPDIR="$local_work/tmp"
		export _JAVA_OPTIONS="-Djava.io.tmpdir=$TMPDIR"
		cp -f ${sorted_bam} "$local_work/input.bam"
		cp -f ${sorted_bam_index} "$local_work/input.bam.bai"
		cd "$local_work"
		/usr/local/jdk-20.0.1/bin/java -jar /usr/local/picard.jar  MarkDuplicates \
					-I input.bam  \
					-O ${sample_id}.sorted.deduped.bam \
					-M ${sample_id}_dedup_metrics.txt \
					--REMOVE_DUPLICATES \
					--VALIDATION_STRINGENCY LENIENT
					
		/usr/local/samtools-1.17/bin/samtools index -@ $(nproc) -o  ${sample_id}.sorted.deduped.bam.bai  ${sample_id}.sorted.deduped.bam
		cp -f ${sample_id}.sorted.deduped.bam ${sample_id}.sorted.deduped.bam.bai ${sample_id}_dedup_metrics.txt "$call_dir/"
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






