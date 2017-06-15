var IngestAppend = {
    has_append: function (processor) {
        return !!processor["append"];
    },
    append_hash: function (processor) {
        var append_json = processor["append"];
        var value_contents;
        var value = append_json["value"];
        if (Array.isArray(value)) {
            value_contents = IngestConverter.create_array(value);
        } else {
            value_contents = IngestConverter.quote_string(value);
        }
        var mutate_contents = IngestConverter.create_field(
            IngestConverter.quote_string(IngestConverter.dots_to_square_brackets(append_json["field"])),
            value_contents);
        return IngestConverter.create_field("add_field", IngestConverter.wrap_in_curly(mutate_contents));
    }
};

/**
 * Converts Ingest Append JSON to LS mutate filter.
 */
function ingest_append_to_logstash(json, append_stdio) {

    function map_processor(processor) {

        return IngestConverter.filter_hash(
            IngestConverter.create_hash(
                "mutate", IngestAppend.append_hash(processor)
            )
        );
    }

    var filters_pipeline = JSON.parse(json)["processors"].map(map_processor);
    return IngestConverter.filters_to_file([
        IngestConverter.append_io_plugins(filters_pipeline, append_stdio)
        ]
    );
}
