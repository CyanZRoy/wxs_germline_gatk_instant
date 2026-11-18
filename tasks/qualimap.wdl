task qualimap {
	File bam
	File bai
	File? bed
	String sample_id = basename(bam,".bam")
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
		local_work=$(mktemp -d /tmp/qualimap.XXXXXX)
		mkdir -p "$local_work/tmp"
		export TMPDIR="$local_work/tmp"
		cp -f ${bam} "$local_work/input.bam"
		cp -f ${bai} "$local_work/input.bam.bai"
		cd "$local_work"

		if [ ${bed} ]; then
			awk 'BEGIN{OFS="\t"}{sub("\r","",$3);print $1,$2,$3,"",0,"."}' ${bed} > new.bed
			INTERVAL="-gff new.bed"
		else
			INTERVAL=""
		fi

		
		/opt/qualimap/qualimap bamqc -bam input.bam $INTERVAL -outformat PDF:HTML -nt $nt -outdir ${sample_id} --java-mem-size=60G

		tar -zcvf ${sample_id}_qualimap.tar.gz ${sample_id}
		cp -f ${sample_id}_qualimap.tar.gz "$call_dir/"
	>>>

	runtime {
		docker:docker
		instanceTypes: [cluster_config]
		systemDisk: "cloud " + disk_size
	}

	output {
		File zip = "${sample_id}_qualimap.tar.gz"
	}
}
