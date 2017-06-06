package org.logstash.ingest;

import javax.script.ScriptException;

/**
 * Ingest Convert DSL to Logstash Date Transpiler.
 */
public final class Convert {

    private Convert() {
        // Utility Wrapper for JS Script.
    }

    public static void main(final String... args) throws ScriptException, NoSuchMethodException {
        JsUtil.convert(args, "ingest_convert_to_logstash");
    }
}
