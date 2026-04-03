task Realigner {

    File ref_dir
    File dbmills_dir

	String fasta

	File Dedup_bam
	File Dedup_bam_index
	String sample_id = basename(Dedup_bam,".sorted.deduped.bam")
	String db_mills
	String docker	
	String cluster_config
	String disk_size


	command <<<
	set -o pipefail
	set -e
	nt=$(nproc)
	/usr/local/jdk-1.8.0/bin/java -jar /usr/local/GenomeAnalysisTK.jar \
		-T RealignerTargetCreator -R ${ref_dir}/${fasta} \
		-nt $nt -I ${Dedup_bam} -known ${dbmills_dir}/${db_mills} \
		-o ${sample_id}.IndelRealigner.intervals
	/usr/local/jdk-1.8.0/bin/java -jar /usr/local/GenomeAnalysisTK.jar \
		-T IndelRealigner -R ${ref_dir}/${fasta} -I ${Dedup_bam} \
		--targetIntervals ${sample_id}.IndelRealigner.intervals \
		-o ${sample_id}.sorted.deduped.realigned.bam
	/usr/local/samtools-1.17/bin/samtools index -@ $(nproc) \
		-o  ${sample_id}.sorted.deduped.realigned.bam.bai  ${sample_id}.sorted.deduped.realigned.bam
	>>>

	runtime {
		docker:docker
		instanceTypes: [cluster_config]
		systemDisk: "cloud " + disk_size
	}

	output {
		File realigner_bam = "${sample_id}.sorted.deduped.realigned.bam"
		File realigner_bam_index = "${sample_id}.sorted.deduped.realigned.bam.bai"

	}
}


