package org.logstash.ingest;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Paths;
import javax.script.Invocable;
import javax.script.ScriptEngine;
import javax.script.ScriptException;

/**
 * Ingest Date DSL to Logstash Date Transpiler.
 */
public final class Date {

    private Date() {
        // Utility Wrapper for JS Script.
    }

    public static void main(final String... args) throws ScriptException, NoSuchMethodException {
        try {
            final ScriptEngine engine = JsUtil.engine("/ingest-date.js");
            Files.write(Paths.get(args[1]), ((String) ((Invocable) engine).invokeFunction(
                "ingest_to_logstash_date",
                new String(
                    Files.readAllBytes(Paths.get(args[0])), StandardCharsets.UTF_8
                )
            )).getBytes(StandardCharsets.UTF_8));
        } catch (final IOException ex) {
            throw new IllegalStateException(ex);
        }
    }
}
