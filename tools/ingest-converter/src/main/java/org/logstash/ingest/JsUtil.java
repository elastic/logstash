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

final class JsUtil {

    /**
     * Script names used by the converter in correct load order.
     */

    private static final String[] SCRIPTS =
        {"shared", "date", "grok", "geoip", "gsub", "pipeline", "convert", "append", "json"};

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

    /**
     * Converts the given files from ingest to LS conf using the javascript function
     * @param args
     * @param jsFunc
     * @throws ScriptException
     * @throws NoSuchMethodException
     */
    public static void convert(final String[] args, final String jsFunc) throws ScriptException, NoSuchMethodException {
        try {
            final ScriptEngine engine = JsUtil.engine();
            Files.write(Paths.get(args[1]), ((String) ((Invocable) engine).invokeFunction(
                jsFunc, new String(
                    Files.readAllBytes(Paths.get(args[0])), StandardCharsets.UTF_8
                )
            )).getBytes(StandardCharsets.UTF_8));
        } catch (final IOException ex) {
            throw new IllegalStateException(ex);
        }
    }

    private static void add(final ScriptEngine engine, final String file)
        throws IOException, ScriptException {
        try (final Reader reader =
                 new InputStreamReader(JsUtil.class.getResourceAsStream(file))) {
            engine.eval(reader);
        }
    }
}
