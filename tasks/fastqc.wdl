task fastqc {
	File read1
	File read2
	String docker
	String sample_id
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
		nt=$(nproc)
		local_work=$(mktemp -d /tmp/fastqc.XXXXXX)
		cp -f ${read1} "$local_work/$(basename ${read1})"
		cp -f ${read2} "$local_work/$(basename ${read2})"
		cd "$local_work"
		fastqc -t $nt -o ./ "$(basename ${read1})"
		fastqc -t $nt -o ./ "$(basename ${read2})"
		cp -f *_fastqc.html *_fastqc.zip "$call_dir/"
	>>>

	runtime {
		docker:docker
		instanceTypes: [cluster_config]
		systemDisk: "cloud " + disk_size
	}
	output {
		File read1_html = sub(basename(read1), "\\.(fastq|fq)\\.gz$", "_fastqc.html")
		File read1_zip = sub(basename(read1), "\\.(fastq|fq)\\.gz$", "_fastqc.zip")
		File read2_html = sub(basename(read2), "\\.(fastq|fq)\\.gz$", "_fastqc.html")
		File read2_zip = sub(basename(read2), "\\.(fastq|fq)\\.gz$", "_fastqc.zip")
	}
}
