task mapping {

    File ref_dir
    String fasta
	File fastq_1
	File fastq_2

	String sample_id
	String pl
	String docker
	String cluster_config
	String disk_size

	command <<<
		set -o pipefail
		set -e	
		bwa mem -M -R "@RG\tID:${sample_id}\tSM:${sample_id}\tPL:${pl}" -t $(nproc) -K 10000000 ${ref_dir}/${fasta} ${fastq_1} ${fastq_2} \
			| samtools view -bS -@ $(nproc) - \
			| samtools sort -@ $(nproc) -o ${sample_id}.sorted.bam -
		
		samtools index -@ $(nproc) \
						-o ${sample_id}.sorted.bam.bai  \
						${sample_id}.sorted.bam
	>>>

	runtime {
		docker:docker
		instanceTypes: [cluster_config]
		systemDisk: "cloud " + disk_size
	}
	output {
		File sorted_bam = "${sample_id}.sorted.bam"
		File sorted_bam_index = "${sample_id}.sorted.bam.bai"
	}
}
