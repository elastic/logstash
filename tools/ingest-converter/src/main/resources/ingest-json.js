var IngestJson = {
    has_json: function (processor) {
        return !!processor["json"];
    },
    json_hash: function (processor) {
        var json_data = processor["json"];
        var parts = [
            IngestConverter.create_field(
                "source",
                IngestConverter.quote_string(
                    IngestConverter.dots_to_square_brackets(json_data["field"])
                )
            )
        ];

        if (json_data["target_field"]) {
            parts.push(
                IngestConverter.create_field(
                    "target",
                    IngestConverter.quote_string(
                        IngestConverter.dots_to_square_brackets(json_data["target_field"])
                    )
                )
            );
        }

        return IngestConverter.join_hash_fields(parts);
    }
};

/**
 * Converts Ingest json processor to LS json filter.
 */
function ingest_json_to_logstash(json, append_stdio) {

    function map_processor(processor) {

        return IngestConverter.filter_hash(
            IngestConverter.create_hash("json", IngestJson.json_hash(processor))
        )
    }

    var filters_pipeline = JSON.parse(json)["processors"].map(map_processor);
    return IngestConverter.filters_to_file([
        IngestConverter.append_io_plugins(filters_pipeline, append_stdio)
        ]
    );
}
