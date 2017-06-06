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
 * Converts Ingest Append JSON to LS Date filter.
 */
function ingest_append_to_logstash(json) {

    function map_processor(processor) {

        return IngestConverter.filter_hash(
            IngestConverter.create_hash(
                "mutate", IngestAppend.append_hash(processor)
            )
        );
    }

    return IngestConverter.filters_to_file(JSON.parse(json)["processors"].map(map_processor));
}
