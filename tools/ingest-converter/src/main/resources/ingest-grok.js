var IngestGrok = {
    has_grok: function (processor) {
        return !!processor[this.get_name()];
    },
    get_name: function () {
        return "grok";
    },
    grok_hash: function (processor) {

        function create_hash_field(name, content) {
            return IngestConverter.create_field(
                name, IngestConverter.wrap_in_curly(content)
            );
        }

        function create_pattern_definition_hash(definitions) {
            var content = [];
            for (var key in definitions) {
                if (definitions.hasOwnProperty(key)) {
                    content.push(
                        IngestConverter.create_field(
                            IngestConverter.quote_string(key),
                            IngestConverter.quote_string(definitions[key]))
                    );
                }
            }
            return create_hash_field(
                "pattern_definitions", 
                content.map(IngestConverter.dots_to_square_brackets).join("\n")
            );
        }

        var grok_data = processor["grok"];
        var grok_contents = create_hash_field(
            "match",
            IngestConverter.create_field(
                IngestConverter.quote_string(grok_data["field"]),
                IngestConverter.create_pattern_array_or_field(grok_data["patterns"])
            )
        );
        if (grok_data["pattern_definitions"]) {
            grok_contents = IngestConverter.join_hash_fields([
                grok_contents,
                create_pattern_definition_hash(grok_data["pattern_definitions"])
            ])
        }
        return grok_contents;
    }
};

/**
 * Converts Ingest JSON to LS Grok.
 */
function ingest_to_logstash_grok(json, append_stdio) {

    function map_processor(processor) {

        return IngestConverter.filter_hash(
            IngestConverter.create_hash("grok", IngestGrok.grok_hash(processor))
        )
    }

    var filters_pipeline = JSON.parse(json)["processors"].map(map_processor);
    return IngestConverter.filters_to_file([
        IngestConverter.append_io_plugins(filters_pipeline, append_stdio)
        ]
    );
}
