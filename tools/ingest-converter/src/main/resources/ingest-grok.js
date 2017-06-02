/**
 * Converts Ingest JSON to LS Grok.
 */
function ingest_to_logstash_grok(json) {

    function map_processor(processor) {

        function create_hash_field(name, content) {
            return IngestConverter.create_field(
                name, IngestConverter.wrap_in_curly(content)
            );
        }

        function grok_hash(processor) {
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
                return create_hash_field("pattern_definitions", content);
            }

            var grok_data = processor["grok"];
            var grok_contents = create_hash_field(
                "match",
                IngestConverter.create_field(
                    IngestConverter.quote_string(grok_data["field"]),
                    IngestConverter.create_pattern_array(grok_data["patterns"])
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

        return IngestConverter.fix_indent(
            IngestConverter.create_hash(
                "filter",
                IngestConverter.create_hash(
                    "grok", grok_hash(processor)
                )
            )
        )
    }

    return JSON.parse(json)["processors"].map(map_processor).join("\n\n") + "\n";
}
