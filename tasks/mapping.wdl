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
		call_dir="$PWD"
		copy_task_logs() {
			cp -f "$call_dir/script" "$call_dir/script.txt" 2>/dev/null || true
			cp -f "$call_dir/stdout" "$call_dir/stdout.txt" 2>/dev/null || true
			cp -f "$call_dir/stderr" "$call_dir/stderr.txt" 2>/dev/null || true
		}
		trap copy_task_logs EXIT
		local_work=$(mktemp -d /tmp/mapping.XXXXXX)
		mkdir -p "$local_work/tmp"
		export TMPDIR="$local_work/tmp"
		cp -f ${fastq_1} "$local_work/read1.fq.gz"
		cp -f ${fastq_2} "$local_work/read2.fq.gz"
		cd "$local_work"
		bwa mem -M -R "@RG\tID:${sample_id}\tSM:${sample_id}\tPL:${pl}" -t $(nproc) -K 10000000 ${ref_dir}/${fasta} read1.fq.gz read2.fq.gz \
			| samtools view -bS -@ $(nproc) - \
			| samtools sort -@ $(nproc) -T "$TMPDIR/sort" -o ${sample_id}.sorted.bam -
		
		samtools index -@ $(nproc) \
						-o ${sample_id}.sorted.bam.bai  \
						${sample_id}.sorted.bam
		cp -f ${sample_id}.sorted.bam ${sample_id}.sorted.bam.bai "$call_dir/"
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
