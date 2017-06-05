package org.logstash.ingest;

import java.io.IOException;
import java.io.InputStreamReader;
import java.io.Reader;
import javax.script.ScriptEngine;
import javax.script.ScriptEngineManager;
import javax.script.ScriptException;

final class JsUtil {

    /**
     * Script names used by the converter in correct load order.
     */
    private static final String[] SCRIPTS = {"shared", "date", "grok", "geoip", "pipeline", "convert"};

    private JsUtil() {
        // Utility Class
    }

    /**
     * Sets up a {@link ScriptEngine} with all Ingest to LS DSL Converter JS scripts loaded.
     * @return {@link ScriptEngine} for Ingest to LS DSL Converter
     */
    public static ScriptEngine engine() {
        final ScriptEngine engine =
            new ScriptEngineManager().getEngineByName("nashorn");
        try {
            for (final String file : SCRIPTS) {
                add(engine, String.format("/ingest-%s.js", file));
            }
        } catch (final IOException | ScriptException ex) {
            throw new IllegalStateException(ex);
        }
        return engine;
    }

    private static void add(final ScriptEngine engine, final String file)
        throws IOException, ScriptException {
        try (final Reader reader =
                 new InputStreamReader(JsUtil.class.getResourceAsStream(file))) {
            engine.eval(reader);
        }
    }
}
