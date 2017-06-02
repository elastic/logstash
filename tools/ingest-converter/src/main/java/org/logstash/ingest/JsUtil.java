package org.logstash.ingest;

import java.io.IOException;
import java.io.InputStreamReader;
import java.io.Reader;
import javax.script.ScriptEngine;
import javax.script.ScriptEngineManager;
import javax.script.ScriptException;

final class JsUtil {

    private JsUtil() {
        // Utility Class
    }

    /**
     * Sets up a {@link ScriptEngine} for a given file loaded after `ingest-shared.js`.
     * @param file File to set up {@link ScriptEngine} for
     * @return {@link ScriptEngine} for file
     */
    public static ScriptEngine engine(final String file) {
        final ScriptEngine engine =
            new ScriptEngineManager().getEngineByName("nashorn");
        try (
            final Reader shared = reader("/ingest-shared.js");
            final Reader reader = reader(file)
        ) {
            engine.eval(shared);
            engine.eval(reader);
        } catch (final IOException | ScriptException ex) {
            throw new IllegalStateException(ex);
        }
        return engine;
    }

    private static Reader reader(final String file) {
        return new InputStreamReader(JsUtil.class.getResourceAsStream(file));
    }
}
