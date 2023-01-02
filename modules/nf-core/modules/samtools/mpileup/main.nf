process SAMTOOLS_MPILEUP {
    tag "Creation of VarScan input mpileup for sample ${meta.sample_name}"
    label 'process_low'

    conda (params.enable_conda ? "bioconda::samtools=1.13" : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/samtools:1.13--h8c37831_0' :
        'quay.io/biocontainers/samtools:1.13--h8c37831_0' }"
    
    input:
    tuple val(meta), val(tumor_only)
    tuple val(meta), path(normal_bam), path(normal_bai), path(tumor_bam), path(tumor_bai)

    path  fasta

    output:
    tuple val(meta), path("*.mpileup")              , emit: mpileup
    path  "versions.yml"                            , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "mpileup"
    def bam = ( normal && tumor ) ? "${normal_bam} ${tumor_bam}" : "${tumor.tumor_bam}"

    """
    samtools mpileup \\
        -f $fasta \\
        --output ${prefix}.mpileup \\
        $bam

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        samtools: \$(echo \$(samtools --version 2>&1) | sed 's/^.*samtools //; s/Using.*\$//')
    END_VERSIONS
    """
}
