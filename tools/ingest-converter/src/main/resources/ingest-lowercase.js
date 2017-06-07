var IngestLowercase = {
    has_lowercase: function (processor) {
        return !!processor["lowercase"];
    },
    lowercase_hash: function (processor) {
        return IngestConverter.create_field(
            "lowercase", 
            IngestConverter.quote_string(
                IngestConverter.dots_to_square_brackets(processor["lowercase"]["field"])
            )
        );
    }
};

/**
 * Converts Ingest Lowercase JSON to LS mutate filter.
 */
function ingest_lowercase_to_logstash(json) {

    function map_processor(processor) {

        return IngestConverter.filter_hash(
            IngestConverter.create_hash(
                "mutate", IngestLowercase.lowercase_hash(processor)
            )
        );
    }

    return IngestConverter.filters_to_file(JSON.parse(json)["processors"].map(map_processor));
}
