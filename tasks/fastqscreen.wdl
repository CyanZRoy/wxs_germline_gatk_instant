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
		mkdir -p /cromwell_root/tmp
		cp -r ${screen_ref_dir} /cromwell_root/tmp/
		fastq_screen --aligner bowtie2 --conf ${fastq_screen_conf} --subset 1000000 --threads $nt ${read1}
		fastq_screen --aligner bowtie2 --conf ${fastq_screen_conf} --subset 1000000 --threads $nt ${read2}
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