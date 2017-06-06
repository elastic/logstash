package org.logstash.ingest;

import javax.script.ScriptException;

public final class GeoIp {

    private GeoIp() {
        // Utility Wrapper for JS Script.
    }
    
    public static void main(final String... args) throws ScriptException, NoSuchMethodException {
        JsUtil.convert(args, "ingest_to_logstash_geoip");
    }
}
