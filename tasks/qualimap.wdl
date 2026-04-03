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

		if [ ${bed} ]; then
			awk 'BEGIN{OFS="\t"}{sub("\r","",$3);print $1,$2,$3,"",0,"."}' ${bed} > new.bed
			INTERVAL="-gff new.bed"
		else
			INTERVAL=""
		fi

		
		/opt/qualimap/qualimap bamqc -bam ${bam} $INTERVAL -outformat PDF:HTML -nt $nt -outdir ${sample_id} --java-mem-size=60G

		tar -zcvf ${sample_id}_qualimap.tar.gz ${sample_id}
	>>>

	runtime {
		docker:docker
		cluster:cluster_config
		systemDisk:"cloud_ssd 40"
		dataDisk:"cloud_ssd " + disk_size + " /cromwell_root/"
	}

	output {
		File zip = "${sample_id}_qualimap.tar.gz"
	}
}
