process GATK4_MUTECT2 {
    tag "Variant calling using Mutect2 on BAMSurgeon spiked-in sample: ${meta.sample_name}"
    label 'process_low'

    conda (params.enable_conda ? "bioconda::gatk4-4.2.3.0-1" : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/gatk4:4.2.3.0--hdfd78af_1':
        'quay.io/biocontainers/gatk4:4.2.3.0--hdfd78af_1' }"

    input:
    tuple val(meta), val(tumor_only)
    tuple val(meta), val(normal), val(tumor)
    path panel_of_normals
    path germline_resource
    val fasta
    path bed


    output:
    tuple val(meta), path("*.vcf")        , emit: vcf_mutect
    tuple val(meta), path("*.idx")        , emit: idx_mutect
    tuple val(meta), path("*.stats")      , emit: stats_mutect
    tuple val(meta), path("*.f1r2.tar.gz"), optional:true, emit: f1r2
    path "versions.yml"                   , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "mutect2"
    //def inputs = input.collect{ "--input $it"}.join(" ")
    def bam = (normal && tumor)
               ? "-I ${meta.sample_name}_tumor.bam -I ${meta.sample_name}_normal.bam -normal ${meta.sample_name}_normal"
               : "-I {tumor_only.tumor_bam}"
    //def interval_command = intervals ? "--intervals $intervals" : ""
    def pon_command = panel_of_normals ? "--panel-of-normals $panel_of_normals" : ""
    def gr_command = germline_resource ? "--germline-resource $germline_resource" : ""

    def avail_mem = 3
    if (!task.memory) {
        log.info '[GATK Mutect2] Available memory not known - defaulting to 3GB. Specify process memory requirements to change this.'
    } else {
        avail_mem = task.memory.giga
    }

    if (normal && tumor){

    """
    java -jar ${params.picardjar} \\
        AddOrReplaceReadGroups I=${normal.normal_bam} \
        O=${meta.sample_name}_normal.bam \\
        VALIDATION_STRINGENCY=LENIENT \\
        RGID=${meta.sample_name}_normal \\
        RGLB=${meta.sample_name}_normal \\
        RGPL=${meta.sample_name}_normal \\
        RGPU=${meta.sample_name}_normal \\
        RGSM=${meta.sample_name}_normal

    java -jar ${params.picardjar} \\
        AddOrReplaceReadGroups I=${tumor.tumor_bam} \
        O=${meta.sample_name}_tumor.bam \\
        VALIDATION_STRINGENCY=LENIENT \\
        RGID=${meta.sample_name}_tumor \\
        RGLB=${meta.sample_name}_tumor \\
        RGPL=${meta.sample_name}_tumor \\
        RGPU=${meta.sample_name}_tumor \\
        RGSM=${meta.sample_name}_tumor
    """
    }
    if (params.high_sensitivity){
    """
    gatk --java-options "-Xmx${avail_mem}g" Mutect2 \\
        $bam \\
        --reference $fasta \\
        $pon_command \\
        $gr_command \\
        -L $bed \\
        $args \\
        -O ${prefix}.vcf

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        gatk4: \$(echo \$(gatk --version 2>&1) | sed 's/^.*(GATK) v//; s/ .*\$//')
    END_VERSIONS
    """
    }

    if (!params.high_sensitivity){
    """
        gatk --java-options "-Xmx${avail_mem}g" Mutect2 \\
        $bam \\
        --reference $fasta \\
        $pon_command \\
        $gr_command \\
        -L $bed \\
        -O ${prefix}.vcf

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        gatk4: \$(echo \$(gatk --version 2>&1) | sed 's/^.*(GATK) v//; s/ .*\$//')
    END_VERSIONS

    """
    }

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}.vcf.gz
    touch ${prefix}.vcf.gz.tbi
    touch ${prefix}.vcf.gz.stats
    touch ${prefix}.f1r2.tar.gz

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        gatk4: \$(echo \$(gatk --version 2>&1) | sed 's/^.*(GATK) v//; s/ .*\$//')
    END_VERSIONS
    """
}
