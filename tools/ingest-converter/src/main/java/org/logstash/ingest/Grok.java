package org.logstash.ingest;

import javax.script.ScriptException;

/**
 * Ingest JSON DSL to Logstash Grok Transpiler.
 */
public final class Grok {

    private Grok() {
        // Utility Wrapper for JS Script.
    }

    public static void main(final String... args) throws ScriptException, NoSuchMethodException {
        JsUtil.convert(args, "ingest_to_logstash_grok");
    }
}
