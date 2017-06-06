package org.logstash.ingest;

import javax.script.ScriptException;

public class Rename {
    private Rename() {
        // Utility Wrapper for JS Script.
    }

    public static void main(final String... args) throws ScriptException, NoSuchMethodException {
        JsUtil.convert(args, "ingest_rename_to_logstash");
    }
}
