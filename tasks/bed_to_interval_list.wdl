task bed_to_interval_list {

	File reference_bed_dict
    File? bed
    File ref_dir
	String fasta
	String interval_list_name
	String docker
	String cluster_config
	String disk_size


	command <<<
	       set -e
	       call_dir="$PWD"
	       copy_task_logs() {
	           cp -f "$call_dir/script" "$call_dir/script.txt" 2>/dev/null || true
	           cp -f "$call_dir/stdout" "$call_dir/stdout.txt" 2>/dev/null || true
	           cp -f "$call_dir/stderr" "$call_dir/stderr.txt" 2>/dev/null || true
	       }
	       trap copy_task_logs EXIT
	       local_work=$(mktemp -d /tmp/bedinterval.XXXXXX)
	       cp -f ${bed} "$local_work/input.bed"
	       cd "$local_work"
                  
       java -jar /usr/picard/picard.jar BedToIntervalList \
	       I=input.bed \
       O=${interval_list_name}.txt \
	       SD=${reference_bed_dict}
	       cp -f ${interval_list_name}.txt "$call_dir/"
	>>>

	runtime {
		docker:docker
		instanceTypes: [cluster_config]
		systemDisk: "cloud " + disk_size
	}

	output {
		File interval_list = "${interval_list_name}.txt"
	}
}
