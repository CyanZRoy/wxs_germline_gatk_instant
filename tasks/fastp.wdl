task fastp {
    String sample_id
    File read1
    File read2
    String adapter_sequence
    String adapter_sequence_r2
    String docker
    String cluster
    String disk_size
    String umi_loc	
    Int trim_front1
    Int trim_tail1
    Int max_len1
    Int trim_front2
    Int trim_tail2
    Int max_len2
    Int disable_adapter_trimming
    Int length_required
    Int umi_len
    Int UMI
    Int qualified_quality_phred
    Int length_required1
    Int disable_quality_filtering
   
	command <<<
			set -e -o pipefail
			call_dir="$PWD"
			copy_task_logs() {
				cp -f "$call_dir/script" "$call_dir/script.txt" 2>/dev/null || true
				cp -f "$call_dir/stdout" "$call_dir/stdout.txt" 2>/dev/null || true
				cp -f "$call_dir/stderr" "$call_dir/stderr.txt" 2>/dev/null || true
			}
			trap copy_task_logs EXIT
			nt=$(nproc)
			local_work=$(mktemp -d /tmp/fastp.XXXXXX)
			export TMPDIR="$local_work"
			cp -f ${read1} "$local_work/read1.fastq.gz"
			cp -f ${read2} "$local_work/read2.fastq.gz"
			cd "$local_work"
					
			##1.Disable_quality_filtering
			if [ "${disable_quality_filtering}" == 0 ]
			then
			cp read1.fastq.gz ${sample_id}_R1.fastq.tmp1.gz
			cp read2.fastq.gz ${sample_id}_R2.fastq.tmp1.gz
			else
			fastp --thread $nt --trim_front1 ${trim_front1} --trim_tail1 ${trim_tail1} --max_len1 ${max_len1} --trim_front2 ${trim_front2} --trim_tail2 ${trim_tail2} --max_len2 ${max_len2} -i read1.fastq.gz -I read2.fastq.gz -o ${sample_id}_R1.fastq.tmp1.gz -O ${sample_id}_R2.fastq.tmp1.gz -j ${sample_id}.json -h ${sample_id}.html
			fi

			##2.UMI
			if [ "${UMI}" == 0 ]
			then
			cp ${sample_id}_R1.fastq.tmp1.gz ${sample_id}_R1.fastq.tmp2.gz
			cp ${sample_id}_R2.fastq.tmp1.gz ${sample_id}_R2.fastq.tmp2.gz
			else
			fastp --thread $nt -U --umi_loc=${umi_loc} --umi_len=${umi_len} --trim_front1 ${trim_front1} --trim_tail1 ${trim_tail1} --max_len1 ${max_len1} --trim_front2 ${trim_front2} --trim_tail2 ${trim_tail2} --max_len2 ${max_len2} -i ${sample_id}_R1.fastq.tmp1.gz -I ${sample_id}_R2.fastq.tmp1.gz -o ${sample_id}_R1.fastq.tmp2.gz -O ${sample_id}_R2.fastq.tmp2.gz -j ${sample_id}.json -h ${sample_id}.html
			fi

			##3.Trim
			if [ "${disable_adapter_trimming}" == 0 ]
			then
			fastp --thread $nt -l ${length_required} -q ${qualified_quality_phred} -u ${length_required1} --adapter_sequence ${adapter_sequence} --adapter_sequence_r2 ${adapter_sequence_r2} --detect_adapter_for_pe --trim_front1 ${trim_front1} --trim_tail1 ${trim_tail1} --max_len1 ${max_len1} --trim_front2 ${trim_front2} --trim_tail2 ${trim_tail2} --max_len2 ${max_len2} -i ${sample_id}_R1.fastq.tmp2.gz -I ${sample_id}_R2.fastq.tmp2.gz -o ${sample_id}_R1.fastq.gz -O ${sample_id}_R2.fastq.gz -j ${sample_id}.json -h ${sample_id}.html
			else
			cp ${sample_id}_R1.fastq.tmp2.gz ${sample_id}_R1.fastq.gz
			cp ${sample_id}_R2.fastq.tmp2.gz ${sample_id}_R2.fastq.gz
			fi
			cp -f ${sample_id}_R1.fastq.gz ${sample_id}_R2.fastq.gz "$call_dir/"
			cp -f ${sample_id}.json ${sample_id}.html "$call_dir/" 2>/dev/null || true
   >>>
   
   runtime { 
		docker: docker
		instanceTypes: [cluster]
		systemDisk: "cloud " + disk_size
   }

   output {
      File json = "${sample_id}.json"
      File report = "${sample_id}.html"
      File Trim_R1 = "${sample_id}_R1.fastq.gz"
      File Trim_R2 = "${sample_id}_R2.fastq.gz"
   }
}
