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
			nt=$(nproc)
			mkdir -p /cromwell_root/tmp/fastp/
					
			##1.Disable_quality_filtering
			if [ "${disable_quality_filtering}" == 0 ]
			then
			cp ${read1} /cromwell_root/tmp/fastp/{sample_id}_R1.fastq.tmp1.gz
			cp ${read2} /cromwell_root/tmp/fastp/{sample_id}_R2.fastq.tmp1.gz
			else
			fastp --thread $nt --trim_front1 ${trim_front1} --trim_tail1 ${trim_tail1} --max_len1 ${max_len1} --trim_front2 ${trim_front2} --trim_tail2 ${trim_tail2} --max_len2 ${max_len2} -i ${read1} -I ${read2} -o /cromwell_root/tmp/fastp/${sample_id}_R1.fastq.tmp1.gz -O /cromwell_root/tmp/fastp/${sample_id}_R2.fastq.tmp1.gz -j ${sample_id}.json -h ${sample_id}.html
			fi

			##2.UMI
			if [ "${UMI}" == 0 ]
			then
			cp /cromwell_root/tmp/fastp/${sample_id}_R1.fastq.tmp1.gz /cromwell_root/tmp/fastp/${sample_id}_R1.fastq.tmp2.gz
			cp /cromwell_root/tmp/fastp/${sample_id}_R2.fastq.tmp1.gz /cromwell_root/tmp/fastp/${sample_id}_R2.fastq.tmp2.gz
			else
			fastp --thread $nt -U --umi_loc=${umi_loc} --umi_len=${umi_len} --trim_front1 ${trim_front1} --trim_tail1 ${trim_tail1} --max_len1 ${max_len1} --trim_front2 ${trim_front2} --trim_tail2 ${trim_tail2} --max_len2 ${max_len2} -i /cromwell_root/tmp/fastp/${sample_id}_R1.fastq.tmp1.gz -I /cromwell_root/tmp/fastp/${sample_id}_R2.fastq.tmp1.gz -o /cromwell_root/tmp/fastp/${sample_id}_R1.fastq.tmp2.gz -O /cromwell_root/tmp/fastp/${sample_id}_R2.fastq.tmp2.gz -j ${sample_id}.json -h ${sample_id}.html
			fi

			##3.Trim
			if [ "${disable_adapter_trimming}" == 0 ]
			then
			fastp --thread $nt -l ${length_required} -q ${qualified_quality_phred} -u ${length_required1} --adapter_sequence ${adapter_sequence} --adapter_sequence_r2 ${adapter_sequence_r2} --detect_adapter_for_pe --trim_front1 ${trim_front1} --trim_tail1 ${trim_tail1} --max_len1 ${max_len1} --trim_front2 ${trim_front2} --trim_tail2 ${trim_tail2} --max_len2 ${max_len2} -i /cromwell_root/tmp/fastp/${sample_id}_R1.fastq.tmp2.gz -I /cromwell_root/tmp/fastp/${sample_id}_R2.fastq.tmp2.gz -o ${sample_id}_R1.fastq.gz -O ${sample_id}_R2.fastq.gz -j ${sample_id}.json -h ${sample_id}.html
			else
			cp /cromwell_root/tmp/fastp/${sample_id}_R1.fastq.tmp2.gz ${sample_id}_R1.fastq.gz
			cp /cromwell_root/tmp/fastp/${sample_id}_R2.fastq.tmp2.gz ${sample_id}_R2.fastq.gz
			fi
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