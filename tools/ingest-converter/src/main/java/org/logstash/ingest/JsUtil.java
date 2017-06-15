package org.logstash.ingest;

import java.io.IOException;
import java.io.InputStreamReader;
import java.io.Reader;
import java.net.URI;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Paths;
import javax.script.Invocable;
import javax.script.ScriptEngine;
import javax.script.ScriptEngineManager;
import javax.script.ScriptException;
import joptsimple.OptionException;
import joptsimple.OptionParser;
import joptsimple.OptionSet;
import joptsimple.OptionSpec;

final class JsUtil {

    /**
     * Script names used by the converter in correct load order.
     */

    private static final String[] SCRIPTS = {
        "shared", "date", "grok", "geoip", "gsub", "pipeline", "convert", "append", "json",
        "rename", "lowercase", "set"
    };

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
     * @param args CLI Arguments
     * @param jsFunc JS function to call
     * @throws ScriptException
     * @throws NoSuchMethodException
     */
    public static void convert(final String[] args, final String jsFunc)
        throws ScriptException, NoSuchMethodException {
        final OptionParser parser = new OptionParser();
        final OptionSpec<URI> input = parser.accepts(
            "input",
            "Input JSON file location URI. Only supports 'file://' as URI schema."
        ).withRequiredArg().ofType(URI.class).required().forHelp();
        final OptionSpec<URI> output = parser.accepts(
            "output",
            "Output Logstash DSL file location URI. Only supports 'file://' as URI schema."
        ).withRequiredArg().ofType(URI.class).required().forHelp();
        final OptionSpec<Void> appendStdio = parser.accepts(
            "append-stdio",
            "Flag to append stdin and stdout as outputs instead of the default ES output."
        ).forHelp();
        try {
            final OptionSet options;
            try {
                options = parser.parse(args);
            } catch (final OptionException ex) {
                parser.printHelpOn(System.out);
                throw ex;
            }
            final ScriptEngine engine = JsUtil.engine();
            Files.write(
                Paths.get(options.valueOf(output)),
                ((String) ((Invocable) engine).invokeFunction(
                    jsFunc, input(options.valueOf(input)), options.has(appendStdio)
                )).getBytes(StandardCharsets.UTF_8)
            );
        } catch (final IOException ex) {
            throw new IllegalStateException(ex);
        }
    }

    /**
     * Retrieves the input Ingest JSON from a given {@link URI}.
     * @param uri {@link URI} of Ingest JSON
     * @return Json String
     * @throws IOException On failure to load Ingest JSON
     */
    private static String input(final URI uri) throws IOException {
        if ("file".equals(uri.getScheme())) {
            return new String(
                Files.readAllBytes(Paths.get(uri)), StandardCharsets.UTF_8
            );
        }
        throw new IllegalArgumentException("--input must be of schema file://");
    }

    private static void add(final ScriptEngine engine, final String file)
        throws IOException, ScriptException {
        try (final Reader reader =
                 new InputStreamReader(JsUtil.class.getResourceAsStream(file))) {
            engine.eval(reader);
        }
    }
}
