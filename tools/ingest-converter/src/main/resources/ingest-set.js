var IngestSet = {
    has_set: function (processor) {
        return !!processor["set"];
    },
    set_hash: function (processor) {
        var set_json = processor["set"];
        var value_contents;
        var value = set_json["value"];
        if (typeof value === 'string' || value instanceof String) {
            value_contents = IngestConverter.quote_string(value);
        } else {
            value_contents = value;
        }
        var mutate_contents = IngestConverter.create_field(
            IngestConverter.quote_string(IngestConverter.dots_to_square_brackets(set_json["field"])),
            value_contents);
        return IngestConverter.create_field("add_field", IngestConverter.wrap_in_curly(mutate_contents));
    }
};

/**
 * Converts Ingest Set JSON to LS mutate filter.
 */
function ingest_set_to_logstash(json, append_stdio) {

    function map_processor(processor) {

        return IngestConverter.filter_hash(
            IngestConverter.create_hash(
                "mutate", IngestSet.set_hash(processor)
            )
        );
    }

    var filters_pipeline = JSON.parse(json)["processors"].map(map_processor);
    return IngestConverter.filters_to_file([
        IngestConverter.append_io_plugins(filters_pipeline, append_stdio)
        ]
    );
}
