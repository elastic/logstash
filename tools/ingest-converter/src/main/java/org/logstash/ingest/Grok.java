package org.logstash.ingest;

import java.io.IOException;
import java.io.InputStreamReader;
import java.io.Reader;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Paths;
import javax.script.Invocable;
import javax.script.ScriptEngine;
import javax.script.ScriptEngineManager;
import javax.script.ScriptException;

/**
 * Ingest JSON DSL to Logstash Grok Transpiler.
 */
public final class Grok {

    private Grok() {
        // Utility Wrapper for JS Script.
    }

    public static void main(final String... args) throws ScriptException, NoSuchMethodException {
        try (final Reader reader = new InputStreamReader(
                     Grok.class.getResourceAsStream("/ingest-to-grok.js")
             )
        ) {
            final ScriptEngine engine =
                new ScriptEngineManager().getEngineByName("nashorn");
            engine.eval(reader);
            Files.write(Paths.get(args[1]), ((String) ((Invocable) engine).invokeFunction(
                "json_to_grok",
                new String(
                    Files.readAllBytes(Paths.get(args[0])), StandardCharsets.UTF_8
                )
            )).getBytes(StandardCharsets.UTF_8));
        } catch (final IOException ex) {
            throw new IllegalStateException(ex);
        }
    }
}
