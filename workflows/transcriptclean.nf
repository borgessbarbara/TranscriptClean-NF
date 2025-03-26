/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT MODULES / SUBWORKFLOWS / FUNCTIONS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
include { TRANSCRIPTCLEAN; EXTRACT_SPLICE_JUNCTIONS; GENERATE_REPORT } from '../modules/local/transcriptclean/main.nf'
include { paramsSummaryMap       } from 'plugin/nf-schema'
include { softwareVersionsToYAML } from '../subworkflows/nf-core/utils_nfcore_pipeline'
include { methodsDescriptionText } from '../subworkflows/local/utils_nfcore_transcriptclean_pipeline'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow RUN_TRANSCRIPTCLEAN {
    
    take:
    ch_samplesheet // channel: samplesheet read in from --input

    main:

    ch_versions = Channel.empty()

    Channel.fromPath(gtf).ifEmpty(null).set  { ch_gtf }
    Channel.fromPath(splice_junctions).ifEmpty(null).set { ch_sjs }
    Channel.fromPath(vcf).ifEmpty(null).set  { ch_vcf }

    if (params.extract_sjs && gtf && params.sj_correction){
        EXTRACT_SPLICE_JUNCTIONS(ch_gtf.combine(ch_samplesheet.map{it[1]})).set { ch_ex_sjs }
        TRANSCRIPTCLEAN(ch_samplesheet.combine(ch_ex_sjs.out.map{it})).set { ch_transcriptclean_res }
        GENERATE_REPORT(TRANSCRIPTCLEAN.out.map{it}).set { ch_report }
    } else if (params.extract_sjs && gtf && params.sj_correction && params.variant_aware && vcf) {
        EXTRACT_SPLICE_JUNCTIONS(ch_gtf.combine(ch_samplesheet.map{it[1]})).set { ch_ex_sjs }
        TRANSCRIPTCLEAN(ch_samplesheet.combine(ch_ex_sjs.out.map{it}, ch_vcf)).set { ch_transcriptclean_res }
        GENERATE_REPORT(TRANSCRIPTCLEAN.out.map{it}).set { ch_report }
    } else if (params.sj_correction && splice_junctions){
        TRANSCRIPTCLEAN(ch_samplesheet.combine(ch_sjs)).set { ch_transcriptclean_res }
        GENERATE_REPORT(TRANSCRIPTCLEAN.out.map{it}).set { ch_report }
    } else if (params.sj_correction && params.variant_aware && splice_junctions && vcf){
        TRANSCRIPTCLEAN(ch_samplesheet.combine(ch_sjs, ch_vcf)).set { ch_transcriptclean_res }
        GENERATE_REPORT(TRANSCRIPTCLEAN.out.map{it}).set { ch_report }
    } else if (params.variant_aware && vcf) {
        TRANSCRIPTCLEAN(ch_samplesheet.combine(ch_vcf)).set { ch_transcriptclean_res }
        GENERATE_REPORT(TRANSCRIPTCLEAN.out.map{it}).set { ch_report }
    } else {
        TRANSCRIPTCLEAN(ch_samplesheet).set { ch_transcriptclean_res }
        GENERATE_REPORT(TRANSCRIPTCLEAN.out.map{it}.set { ch_report })
    }

    //
    // Collate and save software versions
    //
    softwareVersionsToYAML(ch_versions)
        .collectFile(
            storeDir: "${params.outdir}/pipeline_info",
            name: 'nf_core_'  +  'transcriptclean_software_'  + 'versions.yml',
            sort: true,
            newLine: true
        ).set { ch_collated_versions }


    emit:
    extracted_sjs = ch_ex_sjs.out.ifEmpty(null)
    transcriptclean_results = ch_transcriptclean_res.OUT
    transcriptclean_report = ch_report.out
    versions       = ch_versions                 // channel: [ path(versions.yml) ]

}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
