
process DEVIDER {
    tag "$meta.id"
    label 'process_medium'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/devider:0.0.1--ha6fb395_2':
        'biocontainers/devider:0.0.1--ha6fb395_2' }"

    input:
    tuple val(meta),    path(fastq) // Long reads
    tuple val(meta2),   path(fasta) // Ref

    output:
    tuple val(meta),    path("snp_haplotypes.fasta"),              emit: snp_haplotypes
    tuple val(meta),    path( "majority_vote_haplotypes.fasta"),   emit: majority_vote_haplotypes
    tuple val(meta),    path( "ids.txt"),                          emit: ids
    tuple val(meta),    path( "hap_info.txt"),                     emit: hap_info
    tuple val(meta),    path( "*.bam"),                            emit: bam
    tuple val(meta),    path( "*.bai"),                            emit: bai
    tuple val(meta),    path( "*.vcf.gz"),                         emit: vcf
    tuple val(meta),    path( "*.vcf.gz.tbi"),                     emit: tbi
    tuple val(meta),    path( "*.tagged.bam"),                     emit: tagged_bam, optional: true
    tuple val(meta),    path( "*.tagged.bai"),                     emit: tagged_bai, optional: true
    path "versions.yml",                                           emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args            = task.ext.args ?: ''
    def prefix          = task.ext.prefix ?: "${meta.id}"
    def haplotagging    = task.ext.skip_haplotagging ? '' : "haplotag_bam ${prefix}/pipeline_files/mapping.bam -i ${prefix}/ids.txt"

    // Adding the haplotags to the alignments comes with almost no run-time overhead and there is no practical reason to not do it.
    """
    run_devider_pipeline \\
        -i $fastq \\
        -r $fasta \\
        -t $task.cpus \\
        -o ${prefix} \\
        $args \\

    ${haplotagging}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        devider: \$( echo \$(devider --version 2>&1) | sed 's/^devider //')
    END_VERSIONS
    """

    stub:
    def prefix          = task.ext.prefix ?: "${meta.id}"
    def haplotagging    = task.ext.skip_haplotagging ? '' : "touch ${prefix}/pipeline_files/mapping.bam.tagged.bam; touch ${prefix}/pipeline_files/mapping.bam.tagged.bai"
    """
    mkdir -p ${prefix}/pipeline_files/

    touch ${prefix}/snp_haplotypes.fasta
    touch ${prefix}/majority_vote_haplotypes.fasta
    touch ${prefix}/ids.txt
    touch ${prefix}/hap_info.txt
    touch ${prefix}/pipeline_files/mapping.bam
    touch ${prefix}/pipeline_files/mapping.bam.bai
    touch ${prefix}/pipeline_files/lofreq.vcf.gz
    touch ${prefix}/pipeline_files/lofreq.vcf.gz.tbi

    ${haplotagging}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        devider: \$( echo \$(devider --version 2>&1) | sed 's/^devider //')
    END_VERSIONS
    """
}
