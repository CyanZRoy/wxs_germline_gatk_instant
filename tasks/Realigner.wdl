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
	call_dir="$PWD"
	copy_task_logs() {
		cp -f "$call_dir/script" "$call_dir/script.txt" 2>/dev/null || true
		cp -f "$call_dir/stdout" "$call_dir/stdout.txt" 2>/dev/null || true
		cp -f "$call_dir/stderr" "$call_dir/stderr.txt" 2>/dev/null || true
	}
	trap copy_task_logs EXIT
	local_work=$(mktemp -d /tmp/realigner.XXXXXX)
	mkdir -p "$local_work/tmp"
	export TMPDIR="$local_work/tmp"
	export _JAVA_OPTIONS="-Djava.io.tmpdir=$TMPDIR"
	cp -f ${Dedup_bam} "$local_work/input.bam"
	cp -f ${Dedup_bam_index} "$local_work/input.bam.bai"
	cd "$local_work"
	/usr/local/jdk-1.8.0/bin/java -jar /usr/local/GenomeAnalysisTK.jar \
		-T RealignerTargetCreator -R ${ref_dir}/${fasta} \
		-nt $nt -I input.bam -known ${dbmills_dir}/${db_mills} \
		-o ${sample_id}.IndelRealigner.intervals
	/usr/local/jdk-1.8.0/bin/java -jar /usr/local/GenomeAnalysisTK.jar \
		-T IndelRealigner -R ${ref_dir}/${fasta} -I input.bam \
		--targetIntervals ${sample_id}.IndelRealigner.intervals \
		-o ${sample_id}.sorted.deduped.realigned.bam
	/usr/local/samtools-1.17/bin/samtools index -@ $(nproc) \
		-o  ${sample_id}.sorted.deduped.realigned.bam.bai  ${sample_id}.sorted.deduped.realigned.bam
	cp -f ${sample_id}.sorted.deduped.realigned.bam ${sample_id}.sorted.deduped.realigned.bam.bai "$call_dir/"
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


