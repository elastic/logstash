package org.logstash.ingest;

import javax.script.ScriptException;

/**
 * Ingest Append DSL to Logstash mutate Transpiler.
 */
public final class Append {

    private Append() {
        // Utility Wrapper for JS Script.
    }

    public static void main(final String... args) throws ScriptException, NoSuchMethodException {
        JsUtil.convert(args, "ingest_append_to_logstash");
    }
}
