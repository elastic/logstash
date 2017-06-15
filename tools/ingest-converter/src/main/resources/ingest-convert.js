var IngestConvert = {
    has_convert: function (processor) {
        return !!processor["convert"];
    },
    convert_hash: function (processor) {
        var convert_json = processor["convert"];
        var mutate_contents = IngestConverter.create_field(
            IngestConverter.quote_string(IngestConverter.dots_to_square_brackets(convert_json["field"])),
            IngestConverter.quote_string(convert_json["type"])
        );
        return IngestConverter.create_field("convert", IngestConverter.wrap_in_curly(mutate_contents));
    }
};

/**
 * Converts Ingest Convert JSON to LS Date filter.
 */
function ingest_convert_to_logstash(json, append_stdio) {

    function map_processor(processor) {

        return IngestConverter.filter_hash(
            IngestConverter.create_hash(
                "mutate", IngestConvert.convert_hash(processor)
            )
        );
    }

    var filters_pipeline = JSON.parse(json)["processors"].map(map_processor);
    return IngestConverter.filters_to_file([
        IngestConverter.append_io_plugins(filters_pipeline, append_stdio)
        ]
    );
}
