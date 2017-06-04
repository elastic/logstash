var IngestGeoIp = {
    has_geoip: function (processor) {
        return !!processor["geoip"];
    },
    geoip_hash: function (processor) {
        var geoip_data = processor["geoip"];
        var parts = [
            IngestConverter.create_field(
                "source",
                IngestConverter.quote_string(
                    IngestConverter.dots_to_square_brackets(geoip_data["field"])
                )
            ),
            IngestConverter.create_field(
                "target",
                IngestConverter.quote_string(
                    IngestConverter.dots_to_square_brackets(geoip_data["target_field"])
                )
            )
        ];
        if (geoip_data["properties"]) {
            parts.push(
                IngestConverter.create_field(
                    "fields",
                    IngestConverter.create_pattern_array(geoip_data["properties"])
                )
            );
        }
        return IngestConverter.join_hash_fields(parts);
    }
};

/**
 * Converts Ingest JSON to LS Grok.
 */
function ingest_to_logstash_geoip(json) {

    function map_processor(processor) {

        return IngestConverter.filter_hash(
            IngestConverter.create_hash("geoip", IngestGeoIp.geoip_hash(processor))
        )
    }

    return IngestConverter.filters_to_file(JSON.parse(json)["processors"].map(map_processor));
}
