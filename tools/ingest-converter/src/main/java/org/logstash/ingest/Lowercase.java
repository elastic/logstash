package org.logstash.ingest;

import javax.script.ScriptException;

/**
 * Ingest Lowercase DSL to Logstash mutate Transpiler.
 */
public final class Lowercase {

    private Lowercase() {
        // Utility Wrapper for JS Script.
    }

    public static void main(final String... args) throws ScriptException, NoSuchMethodException {
        JsUtil.convert(args, "ingest_lowercase_to_logstash");
    }
}
