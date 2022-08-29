process NEAT {
    tag "Create artificial normal datasets"
    label 'process_high'

    input:
    val meta
    val rng
    val readlen
    val coverage
    path bed
    path fasta
    path neat_path
    path fraglenmodel
    path seqerrormodel
    path mutmodel
    path gcbiasmodel

    output:
    tuple val(meta), path("*.vcf.gz")     , emit: vcf
    tuple val(meta), path("*.tbi")        , emit: tbi
    tuple val(meta), path("*.bam")        , emit: bam
    val   rng                             , emit: rng
    path "versions.yml"                   , emit: versions
    

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "neat_"
    def version = '3.2' //VERSION IS HARDCODED

    """
    echo "TEST ${meta.samplename}" > "${params.outdir}/test.txt"
    


    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        ncsa/NEAT: 'Version $version'
        GC bias model: $gcbiasmodel
        Bed used: $bed
        Mutational model: $mutmodel
        Mutational rate: none   
        FASTA: $fasta
        Sequencing error model: $seqerrormodel
        Frag length model: $fraglenmodel
        Coverage: $coverage
        Read length: $readlen
        RNG: $rng
        META: $meta
    END_VERSIONS
     """

    stub:
    def prefix = task.ext.prefix ?: "neat"
    """
    touch ${prefix}.vcf.gz
    touch ${prefix}.vcf.gz.tbi
    touch ${prefix}.bam

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        ncsa/NEAT: 'Version $version'
        GC bias model: $gcbiasmodel
        Bed used: $bed
        Mutational model: $mutmodel
        Mutational rate: none   
        FASTA: $fasta
        Sequencing error model: $seqerrormodel
        Frag length model: $fraglenmodel
        Coverage: $coverage
        Read length: $readlen
    END_VERSIONS
    """
}
