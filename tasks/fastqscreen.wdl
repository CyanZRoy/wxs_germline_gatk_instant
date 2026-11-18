task fastq_screen {
	File read1
	File read2
	File screen_ref_dir
	File fastq_screen_conf
	String read1name = basename(basename(read1, ".fastq.gz"), ".fq.gz")
	String read2name = basename(basename(read2, ".fastq.gz"), ".fq.gz")
	String docker
	String sample_id
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
		local_work=$(mktemp -d /tmp/fastqscreen.XXXXXX)
		mkdir -p "$local_work/tmp"
		export TMPDIR="$local_work/tmp"
		cp -f ${read1} "$local_work/$(basename ${read1})"
		cp -f ${read2} "$local_work/$(basename ${read2})"
		sed "s#/cromwell_root/tmp/fastq_screen_reference#${screen_ref_dir}#g" \
			${fastq_screen_conf} > "$local_work/fastq_screen.conf"
		cd "$local_work"
		fastq_screen --aligner bowtie2 --conf fastq_screen.conf --subset 1000000 --threads $nt "$(basename ${read1})"
		fastq_screen --aligner bowtie2 --conf fastq_screen.conf --subset 1000000 --threads $nt "$(basename ${read2})"
		cp -f *_screen.png *_screen.txt *_screen.html "$call_dir/"
	>>>

	runtime {
		docker:docker
		instanceTypes: [cluster_config]
		systemDisk: "cloud " + disk_size
	}
	
	output {
		File png1 = "${read1name}_screen.png"
		File txt1 = "${read1name}_screen.txt"
		File html1 = "${read1name}_screen.html"
		File png2 = "${read2name}_screen.png"
		File txt2 = "${read2name}_screen.txt"
		File html2 = "${read2name}_screen.html"
	}
}
