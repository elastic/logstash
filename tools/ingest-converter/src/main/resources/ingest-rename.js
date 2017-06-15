var IngestRename = {
    has_rename: function (processor) {
        return !!processor["rename"];
    },
    rename_hash: function (processor) {
        var rename_json = processor["rename"];
        var mutate_contents = IngestConverter.create_field(
            IngestConverter.quote_string(IngestConverter.dots_to_square_brackets(rename_json["field"])),
            IngestConverter.quote_string(IngestConverter.dots_to_square_brackets(rename_json["target_field"]))
        );
        return IngestConverter.create_field("rename", IngestConverter.wrap_in_curly(mutate_contents));
    }
};

/**
 * Converts Ingest Rename JSON to LS mutate filter.
 */
function ingest_rename_to_logstash(json, append_stdio) {

    function map_processor(processor) {

        return IngestConverter.filter_hash(
            IngestConverter.create_hash(
                "mutate", IngestRename.rename_hash(processor)
            )
        );
    }

    var filters_pipeline = JSON.parse(json)["processors"].map(map_processor);
    return IngestConverter.filters_to_file([
        IngestConverter.append_io_plugins(filters_pipeline, append_stdio)
        ]
    );
}
