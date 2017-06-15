var IngestGsub = {
    has_gsub: function (processor) {
        return !!processor["gsub"];
    },
    gsub_hash: function (processor) {
        var gsub_data = processor["gsub"];
        return IngestConverter.create_field(
            "gsub",
            "[\n" + [IngestConverter.dots_to_square_brackets(gsub_data["field"]),
                gsub_data["pattern"], gsub_data["replacement"]].map(IngestConverter.quote_string)
                .join(", ") + "\n]"
        );
    }
};

/**
 * Converts Ingest JSON to LS Grok.
 */
function ingest_to_logstash_gsub(json, append_stdio) {

    function map_processor(processor) {

        return IngestConverter.filter_hash(
            IngestConverter.create_hash("mutate", IngestGsub.gsub_hash(processor))
        )
    }

    var filters_pipeline = JSON.parse(json)["processors"].map(map_processor);
    return IngestConverter.filters_to_file([
        IngestConverter.append_io_plugins(filters_pipeline, append_stdio)
        ]
    );
}
