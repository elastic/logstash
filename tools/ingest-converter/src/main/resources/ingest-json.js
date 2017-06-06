var IngestJson = {
    has_json: function (processor) {
        return !!processor["json"];
    },
    json_hash: function (processor) {
        var json_date = processor["json"];
        var parts = [
            IngestConverter.create_field(
                "source",
                IngestConverter.quote_string(
                    IngestConverter.dots_to_square_brackets(json_date["field"])
                )
            )
        ];

        if (json_date["target_field"]) {
            parts.push(
                IngestConverter.create_field(
                    "target",
                    IngestConverter.quote_string(
                        IngestConverter.dots_to_square_brackets(json_date["target_field"])
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
function ingest_json_to_logstash(json) {

    function map_processor(processor) {

        return IngestConverter.filter_hash(
            IngestConverter.create_hash("json", IngestJson.json_hash(processor))
        )
    }

    return IngestConverter.filters_to_file(JSON.parse(json)["processors"].map(map_processor));
}
