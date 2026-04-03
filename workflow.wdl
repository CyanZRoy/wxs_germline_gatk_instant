import "./tasks/mapping.wdl" as mapping
import "./tasks/Dedup.wdl" as Dedup
import "./tasks/qualimap.wdl" as qualimap
import "./tasks/deduped_Metrics.wdl" as deduped_Metrics
import "./tasks/Realigner.wdl" as Realigner
import "./tasks/BQSR.wdl" as BQSR
import "./tasks/Haplotyper.wdl" as Haplotyper
import "./tasks/fastqc.wdl" as fastqc
import "./tasks/fastqscreen.wdl" as fastqscreen
import "./tasks/filter_vcf.wdl" as filter_vcf
import "./tasks/bed_to_interval_list.wdl" as bed_to_interval_list
import "./tasks/ANNOVAR.wdl" as ANNOVAR

workflow {{ project_name }} {

	File fastq_1
	File fastq_2
	File? bed

	String REPLACE_SENTIEON_DOCKER
	String DEEPVARIANT_DOCKER
	String FASTQCdocker
	String FASTQSCREENdocker
	String QUALIMAPdocker
	String BEDTOOLSdocker
	String PICARDdocker
	String annovar_docker

	String fasta
	File ref_dir
	File dbmills_dir
	String db_mills
	File dbsnp_dir
	String dbsnp
	String pl
	File reference_bed_dict
	File annovar_database

	File screen_ref_dir
	File fastq_screen_conf

	String sample_id
	String hg
	String interval_padding

	String disk_size
	String BIGcluster_config
	String MEDcluster_config
	String SMALLcluster_config

	
	if (bed!= "") {
		call bed_to_interval_list.bed_to_interval_list as bed_to_interval_list {
			input:
			bed=bed,
			ref_dir=ref_dir,
			fasta=fasta,
			interval_list_name=sample_id,
			reference_bed_dict=reference_bed_dict,
			docker=PICARDdocker,
			cluster_config=SMALLcluster_config,
			disk_size=disk_size
		}
	}

	call mapping.mapping as mapping {
		input: 
		pl=pl,
		fasta=fasta,
		ref_dir=ref_dir,
		fastq_1=fastq_1,
		fastq_2=fastq_2,
		sample_id=sample_id,
		docker=REPLACE_SENTIEON_DOCKER,
		disk_size=disk_size,
		cluster_config=BIGcluster_config
	}

	call fastqc.fastqc as fastqc {
		input:
		read1=fastq_1,
		read2=fastq_2,
		sample_id=sample_id,
		docker=FASTQCdocker,
		cluster_config=MEDcluster_config,
		disk_size=disk_size
	}

	call fastqscreen.fastq_screen as fastqscreen {
		input:
		read1=fastq_1,
		read2=fastq_2,
		sample_id=sample_id,
		screen_ref_dir=screen_ref_dir,
		fastq_screen_conf=fastq_screen_conf,
		docker=FASTQSCREENdocker,
		cluster_config=MEDcluster_config,
		disk_size=disk_size
	}

	call Dedup.Dedup as Dedup {
		input:
		sorted_bam=mapping.sorted_bam,
		sorted_bam_index=mapping.sorted_bam_index,
		docker=REPLACE_SENTIEON_DOCKER,
		disk_size=disk_size,
		cluster_config=MEDcluster_config
	}

	call qualimap.qualimap as qualimap {
		input:
		bam=Dedup.Dedup_bam,
		bai=Dedup.Dedup_bam_index,
		bed=bed,
		docker=QUALIMAPdocker,
		disk_size=disk_size,
		cluster_config=MEDcluster_config
	}		

	call deduped_Metrics.deduped_Metrics as deduped_Metrics {
		input:
		fasta=fasta,
		ref_dir=ref_dir,
		bed=bed,
		Dedup_bam=Dedup.Dedup_bam,
		Dedup_bam_index=Dedup.Dedup_bam_index,
		docker=REPLACE_SENTIEON_DOCKER,
		interval_list=bed_to_interval_list.interval_list,
		disk_size=disk_size,
		cluster_config=MEDcluster_config
	}

	## Bam realignment doesn't support in GATK 4
	call Realigner.Realigner as Realigner {
		input:
		fasta=fasta,
		ref_dir=ref_dir,
		Dedup_bam=Dedup.Dedup_bam,
		Dedup_bam_index=Dedup.Dedup_bam_index,
		db_mills=db_mills,
		dbmills_dir=dbmills_dir,
		docker=REPLACE_SENTIEON_DOCKER,
		disk_size=disk_size,
		cluster_config=MEDcluster_config
	}

	call BQSR.BQSR as BQSR{
		input:
		fasta=fasta,
		ref_dir=ref_dir,
		realigned_bam=Realigner.realigner_bam,
		realigned_bam_index=Realigner.realigner_bam_index,
		bed=bed,
		interval_padding=interval_padding,
		db_mills=db_mills,
		dbmills_dir=dbmills_dir,
		dbsnp=dbsnp,
		dbsnp_dir=dbsnp_dir,
		docker=REPLACE_SENTIEON_DOCKER,
		disk_size=disk_size,
		cluster_config=MEDcluster_config
	}

	call Haplotyper.Haplotyper as Haplotyper {
		input:
		fasta=fasta,
		ref_dir=ref_dir,
		recaled_bam=BQSR.recaled_bam,
		recaled_bam_index=BQSR.recaled_bam_index,
		bed=bed,
		docker=DEEPVARIANT_DOCKER,
		disk_size=disk_size,
		cluster_config=MEDcluster_config
	}


	call ANNOVAR.ANNOVAR as ANNOVAR {
		input:
		vcf=Haplotyper.vcf,
		hg=hg,
		annovar_database=annovar_database,
		docker=annovar_docker,
		cluster_config=SMALLcluster_config,
		disk_size=disk_size
	}

	if (bed!= "") {
		call filter_vcf.filter_vcf as filter_vcf {
			input:
			vcf=ANNOVAR.multianno_vcf,
			docker=BEDTOOLSdocker,
			bed=bed,
			cluster_config=SMALLcluster_config,
			disk_size=disk_size			
		}
	}
}