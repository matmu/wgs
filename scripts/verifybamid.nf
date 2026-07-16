nextflow.enable.dsl = 2

params.sample_id = null
params.alignment = null
params.alignment_index = null
params.reference = null
params.reference_index = null
params.svd_prefix = null
params.outdir = null

process VERIFYBAMID2 {
    tag "${meta.id}"

    label 'process_low'

    publishDir "${workflow.launchDir}/${params.outdir}",
        mode: 'copy',
        overwrite: true

    container "${workflow.containerEngine in ['singularity', 'apptainer']
        ? 'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/97/9700eb810dc7a72011c9149b8ab6cc7fa9d273795632ddd00af019ab32816811/data'
        : 'community.wave.seqera.io/library/verifybamid2:2.0.1--166cf392bec584ce'}"

    input:
    tuple val(meta), path(alignment), path(alignment_index)

    tuple path(svd_ud), path(svd_mu), path(svd_bed)

    path reference
    path reference_index

    output:
    tuple val(meta), path("${meta.id}.selfSM"),
        emit: self_sm

    tuple val(meta), path("${meta.id}.Ancestry"),
        optional: true,
        emit: ancestry

    tuple val(meta), path("${meta.id}.log"),
        emit: log

    path "versions.yml",
        emit: versions

    script:
    def svd_prefix = svd_ud.name.replaceFirst(/\.UD$/, '')

    """
    verifybamid2 \\
        --BamFile ${alignment} \\
        --Reference ${reference} \\
        --SVDPrefix ${svd_prefix} \\
        --NumThread ${task.cpus} \\
        --Output ${meta.id} \\
        > ${meta.id}.log 2>&1

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
      verifybamid2: \$(verifybamid2 --help 2>&1 | sed -n '3s/.*Version://p')
    END_VERSIONS
    """
}

workflow {
    if (!params.sample_id) {
        error "Missing parameter: --sample_id"
    }

    if (!params.alignment) {
        error "Missing parameter: --alignment"
    }

    if (!params.alignment_index) {
        error "Missing parameter: --alignment_index"
    }

    if (!params.reference) {
        error "Missing parameter: --reference"
    }

    if (!params.reference_index) {
        error "Missing parameter: --reference_index"
    }

    if (!params.svd_prefix) {
        error "Missing parameter: --svd_prefix"
    }

    if (!params.outdir) {
        error "Missing parameter: --outdir"
    }

    alignment = file(
        "${workflow.launchDir}/${params.alignment}",
        checkIfExists: true
    )

    alignment_index = file(
        "${workflow.launchDir}/${params.alignment_index}",
        checkIfExists: true
    )

    reference = file(
        "${workflow.launchDir}/${params.reference}",
        checkIfExists: true
    )

    reference_index = file(
        "${workflow.launchDir}/${params.reference_index}",
        checkIfExists: true
    )

    svd_ud = file(
        "${workflow.launchDir}/${params.svd_prefix}.UD",
        checkIfExists: true
    )

    svd_mu = file(
        "${workflow.launchDir}/${params.svd_prefix}.mu",
        checkIfExists: true
    )

    svd_bed = file(
        "${workflow.launchDir}/${params.svd_prefix}.bed",
        checkIfExists: true
    )

    alignment_ch = Channel.value(
        tuple(
            [id: params.sample_id],
            alignment,
            alignment_index
        )
    )

    svd_ch = Channel.value(
        tuple(
            svd_ud,
            svd_mu,
            svd_bed
        )
    )

    reference_ch = Channel.value(reference)
    reference_index_ch = Channel.value(reference_index)

    VERIFYBAMID2(
        alignment_ch,
        svd_ch,
        reference_ch,
        reference_index_ch
    )
}
