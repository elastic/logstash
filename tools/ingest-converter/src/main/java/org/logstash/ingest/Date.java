package org.logstash.ingest;

import javax.script.ScriptException;

/**
 * Ingest Date DSL to Logstash Date Transpiler.
 */
public final class Date {

    private Date() {
        // Utility Wrapper for JS Script.
    }

    public static void main(final String... args) throws ScriptException, NoSuchMethodException {
        JsUtil.convert(args, "ingest_to_logstash_date");
    }
}
