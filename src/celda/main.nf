nextflow.preview.dsl=2

// Should be set in case this pipeline is run with other pipelines (e.g.: single_sample)

include {
    getDataChannel;
} from './../channels/channels.nf' addParams(off : "sce_rds")
include {
    SC__FILE_CONVERTER;
} from './../utils/processes/utils' params(params)
include {
    PUBLISH;
} from "./../utils/workflows/utils" params(params)

//////////////////////////////////////////////////////
//  Import sub-workflows from the modules:

include {
    DECONTX_FILTER;
    DECONTX_CORRECT;
} from "./workflows/decontX" params(params)

//////////////////////////////////////////////////////
// Define the workflow

// run decontx
workflow decontx {

    main:
        data = getDataChannel \
            | SC__FILE_CONVERTER

        if(params.sc.celda.decontx.strategy == "filter") {
            out = DECONTX_FILTER ( data )
            processed = out.decontx_filtered
        } else if (params.sc.celda.decontx.strategy == "correct") {
            out = DECONTX_CORRECT ( data )
            processed = out.decontx_corrected
        } else {
            throw new Exception("VSN ERROR: The given strategy in params.sc.celda.decontx is not valid. Choose: filter or correct.")
        }

        if(params.utils.containsKey("publish")) {
            PUBLISH(
                processed,
                "CELDA_DECONTX_"+ params.sc.celda.decontx.strategy.toUpperCase(),
                "h5ad",
                null,
                false
            )
        }
        
    emit:
        decontx_processed = processed
        outlier_table = out.outlier_table

}