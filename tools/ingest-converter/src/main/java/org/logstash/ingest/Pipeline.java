package org.logstash.ingest;

import javax.script.ScriptException;

/**
 * Ingest Full DSL to Logstash DSL Transpiler.
 */
public final class Pipeline {

    private Pipeline() {
        // Utility Wrapper for JS Script.
    }

    public static void main(final String... args) throws ScriptException, NoSuchMethodException {
        JsUtil.convert(args, "ingest_pipeline_to_logstash");
    }
}
