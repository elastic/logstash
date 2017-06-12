package org.logstash.ingest;

import javax.script.ScriptException;

/**
 * Ingest Set DSL to Logstash mutate Transpiler.
 */
public class Set {
    private Set() {
        // Utility Wrapper for JS Script.
    }

    public static void main(final String... args) throws ScriptException, NoSuchMethodException {
        JsUtil.convert(args, "ingest_set_to_logstash");
    }
}
