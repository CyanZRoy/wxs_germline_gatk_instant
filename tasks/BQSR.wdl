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
		if [ ${bed} ]; then
            INTERVAL="--intervals ${bed} --interval-padding ${interval_padding}"
        else
            INTERVAL=""
        fi

        /usr/local/gatk-4.4.0.0/gatk BaseRecalibrator \
            -R ${ref_dir}/${fasta} \
            -I ${realigned_bam} \
			$INTERVAL \
            --known-sites ${dbsnp_dir}/${dbsnp} \
            --known-sites ${dbmills_dir}/${db_mills} \
            -O ${sample_id}_recal_data.table

        /usr/local/gatk-4.4.0.0/gatk ApplyBQSR \
            -R ${ref_dir}/${fasta} \
            -I ${realigned_bam} \
			$INTERVAL \
            -bqsr ${sample_id}_recal_data.table \
            -O ${sample_id}.sorted.deduped.realigned.recaled.bam

        /usr/local/samtools-1.17/bin/samtools index -@ $(nproc) -o ${sample_id}.sorted.deduped.realigned.recaled.bam.bai ${sample_id}.sorted.deduped.realigned.recaled.bam
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
