task BQSR {
	
    File ref_dir
    File dbsnp_dir
    File dbmills_dir
	String fasta
	String dbsnp
	String db_mills
	File realigned_bam
	File realigned_bam_index
	File? bed
    String interval_padding
	String sample_id = basename(realigned_bam,".sorted.deduped.realigned.bam")
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
		local_work=$(mktemp -d /tmp/bqsr.XXXXXX)
		mkdir -p "$local_work/tmp"
		export TMPDIR="$local_work/tmp"
		export _JAVA_OPTIONS="-Djava.io.tmpdir=$TMPDIR"
		cp -f ${realigned_bam} "$local_work/input.bam"
		cp -f ${realigned_bam_index} "$local_work/input.bam.bai"
		cp -f ${dbsnp_dir}/${dbsnp}* "$local_work/"
		cp -f ${dbmills_dir}/${db_mills}* "$local_work/"
		cd "$local_work"
		if [ ${bed} ]; then
			cp -f ${bed} intervals.bed
			INTERVAL="--intervals intervals.bed --interval-padding ${interval_padding}"
        else
            INTERVAL=""
        fi

        /usr/local/gatk-4.4.0.0/gatk BaseRecalibrator \
            -R ${ref_dir}/${fasta} \
            -I input.bam \
			$INTERVAL \
            --known-sites ${dbsnp} \
            --known-sites ${db_mills} \
            -O ${sample_id}_recal_data.table

        /usr/local/gatk-4.4.0.0/gatk ApplyBQSR \
            -R ${ref_dir}/${fasta} \
            -I input.bam \
			$INTERVAL \
            -bqsr ${sample_id}_recal_data.table \
            -O ${sample_id}.sorted.deduped.realigned.recaled.bam

        /usr/local/samtools-1.17/bin/samtools index -@ $(nproc) -o ${sample_id}.sorted.deduped.realigned.recaled.bam.bai ${sample_id}.sorted.deduped.realigned.recaled.bam
		cp -f ${sample_id}.sorted.deduped.realigned.recaled.bam ${sample_id}.sorted.deduped.realigned.recaled.bam.bai "$call_dir/"
	>>>
	runtime {
		docker:docker
		instanceTypes: [cluster_config]
		systemDisk: "cloud " + disk_size
	}

	output {
		File recaled_bam = "${sample_id}.sorted.deduped.realigned.recaled.bam"
		File recaled_bam_index = "${sample_id}.sorted.deduped.realigned.recaled.bam.bai"
	}
}
