package org.logstash.ingest;

import javax.script.ScriptException;

/**
 * Ingest JSON processor DSL to Logstash json Transpiler.
 */
public class Json {
    private Json() {
        // Utility Wrapper for JS Script.
    }

    public static void main(final String... args) throws ScriptException, NoSuchMethodException {
        JsUtil.convert(args, "ingest_json_to_logstash");
    }
}
