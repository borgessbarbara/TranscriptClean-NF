// TranscriptClean module

process EXTRACT_SPLICE_JUNCTIONS {
    tag "Extract splice junctions from GTF file"
    label 'process_high'

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'biocontainers/transcriptclean:v2.0.2_cv1':
        'biocontainers/transcriptclean:v2.0.2_cv1' }"

    input:
    tuple val(meta), path(gtf), path(fasta)

    output:
    tuple val(meta), path("${prefix}_spliceJns.txt"), emit: txt
    path  "versions.yml",                            emit: versions

    script:
    args = task.ext.args ?: ''
    prefix = task.ext.prefix ?: "${meta.id}"
    // test if it is actually transcriptclean --version
    """
    python home/biodocker/TranscriptClean-2.0.2/accessory_scripts/get_SJs_from_gtf.py \\
        --f ${gtf} \\
        --g ${fasta} \\
        --o ${prefix}_spliceJns.txt \\
        $args

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        transcriptclean: \$(echo \$(transcriptclean --version 2>&1) | sed 's/^.*transcriptclean //; s/Using.*\$//' ))
    END_VERSIONS
    """
    stub:
    args = task.ext.args ?: ''
    prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch "${prefix}"_spliceJns.txt

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        transcriptclean: \$(echo \$(transcriptclean --version 2>&1) | sed 's/^.*transcriptclean //; s/Using.*\$//' ))
    END_VERSIONS
    """
}

process TRANSCRIPTCLEAN {
    tag "TranscriptClean"
    label 'process_high'

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'biocontainers/transcriptclean:v2.0.2_cv1':
        'biocontainers/transcriptclean:v2.0.2_cv1' }"

    input:
    tuple val(meta), path(sam), path(fasta), path(vcf), path(splice_junctions), val(params)

    output:
    tuple val(meta), path("*_TranscriptClean.sam"), emit: sam
    tuple val(meta), path("*_TranscriptClean.fasta"), emit: fasta
    tuple val(meta), path("*_TranscriptClean.TE.log"), emit: log
    tuple val(meta), path("*_TranscriptClean.log"), emit: log
    path  "versions.yml",           emit: versions

    when:
    params.variant_aware || params.splice_junction_correction

    script:
    args = task.ext.args ?: ''
    prefix = task.ext.prefix ?: "${meta.id}"
    def variant_flag = params.variant_aware && vcf ? "--variants ${vcf}" : ''
    def splice_flag = params.splice_junction_correction && splice_junctions ? "--spliceJns ${splice_junctions}" : ''
    def other_params = params.other_params ? params.other_params : ''
    // test if it is actually transcriptclean --version
    """
    python home/biodocker/TranscriptClean-2.0.2/TranscriptClean.py \\
        --SAM ${sam} \\
        --genome ${fasta} \\
        ${variant_flag} \\
        ${splice_flag} \\
        ${other_params} \\
        --outprefix "${prefix}" \\
        $args
    
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        transcriptclean: \$(echo \$(transcriptclean --version 2>&1) | sed 's/^.*transcriptclean //; s/Using.*\$//' ))
    END_VERSIONS
    """

    stub:
    args = task.ext.args ?: ''
    prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch "${prefix}"_transcriptClean.sam
    touch "${prefix}"_transcriptClean.fasta
    touch "${prefix}"_transcriptClean.TE.log
    touch "${prefix}"_transcriptClean.log

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        transcriptclean: \$(echo \$(transcriptclean --version 2>&1) | sed 's/^.*transcriptclean //; s/Using.*\$//' ))
    END_VERSIONS
    """
}

// Add process to generate report later :(

/* process GENERATE_REPORT {
    
} */