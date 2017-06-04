/**
 * Converts Ingest JSON to LS Grok.
 */
function ingest_pipeline_to_logstash(json) {

    function map_processor(processor) {

        var filter_blocks = [];
        if (IngestGrok.has_grok(processor)) {
            filter_blocks.push(
                IngestConverter.create_hash("grok", IngestGrok.grok_hash(processor))
            )
        }
        if (IngestDate.has_date(processor)) {
            filter_blocks.push(
                IngestConverter.create_hash("date", IngestDate.date_hash(processor))
            )
        }
        if (IngestGeoIp.has_geoip(processor)) {
            filter_blocks.push(
                IngestConverter.create_hash("geoip", IngestGeoIp.geoip_hash(processor))
            )
        }
        return IngestConverter.join_hash_fields(filter_blocks);
    }

    return IngestConverter.filters_to_file([
            IngestConverter.filter_hash(
                IngestConverter.join_hash_fields(JSON.parse(json)["processors"].map(map_processor))
            )
        ]
    );
}
