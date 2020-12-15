/*
 * Licensed to Elasticsearch B.V. under one or more contributor
 * license agreements. See the NOTICE file distributed with
 * this work for additional information regarding copyright
 * ownership. Elasticsearch B.V. licenses this file to you under
 * the Apache License, Version 2.0 (the "License"); you may
 * not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *	http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */


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
            switch (jsFunc) {
                case "ingest_append_to_logstash":
                    Files.write(
                            Paths.get(options.valueOf(output)),
                            IngestAppend.toLogstash(input(options.valueOf(input)), options.has(appendStdio)).getBytes(StandardCharsets.UTF_8)
                    );
                    break;
                case "ingest_convert_to_logstash":
                    Files.write(
                            Paths.get(options.valueOf(output)),
                            IngestConvert.toLogstash(input(options.valueOf(input)), options.has(appendStdio)).getBytes(StandardCharsets.UTF_8)
                    );
                    break;
                case "ingest_to_logstash_date":
                    Files.write(
                            Paths.get(options.valueOf(output)),
                            IngestDate.toLogstash(input(options.valueOf(input)), options.has(appendStdio)).getBytes(StandardCharsets.UTF_8)
                    );
                    break;
                case "ingest_to_logstash_geoip":
                    Files.write(
                            Paths.get(options.valueOf(output)),
                            IngestGeoIp.toLogstash(input(options.valueOf(input)), options.has(appendStdio)).getBytes(StandardCharsets.UTF_8)
                    );
                    break;
                case "ingest_to_logstash_grok":
                    Files.write(
                            Paths.get(options.valueOf(output)),
                            IngestGrok.toLogstash(input(options.valueOf(input)), options.has(appendStdio)).getBytes(StandardCharsets.UTF_8)
                    );
                    break;
                case "ingest_to_logstash_gsub":
                    Files.write(
                            Paths.get(options.valueOf(output)),
                            IngestGsub.toLogstash(input(options.valueOf(input)), options.has(appendStdio)).getBytes(StandardCharsets.UTF_8)
                    );
                    break;
                case "ingest_json_to_logstash":
                    Files.write(
                            Paths.get(options.valueOf(output)),
                            IngestJson.toLogstash(input(options.valueOf(input)), options.has(appendStdio)).getBytes(StandardCharsets.UTF_8)
                    );
                    break;
                case "ingest_lowercase_to_logstash":
                    Files.write(
                            Paths.get(options.valueOf(output)),
                            IngestLowercase.toLogstash(input(options.valueOf(input)), options.has(appendStdio)).getBytes(StandardCharsets.UTF_8)
                    );
                    break;
                case "ingest_rename_to_logstash":
                    Files.write(
                            Paths.get(options.valueOf(output)),
                            IngestRename.toLogstash(input(options.valueOf(input)), options.has(appendStdio)).getBytes(StandardCharsets.UTF_8)
                    );
                    break;
                case "ingest_set_to_logstash":
                    Files.write(
                            Paths.get(options.valueOf(output)),
                            IngestSet.toLogstash(input(options.valueOf(input)), options.has(appendStdio)).getBytes(StandardCharsets.UTF_8)
                    );
                    break;
                case "ingest_pipeline_to_logstash":
                    Files.write(
                            Paths.get(options.valueOf(output)),
                            IngestPipeline.toLogstash(input(options.valueOf(input)), options.has(appendStdio)).getBytes(StandardCharsets.UTF_8)
                    );
                    break;

                default: {
                    throw new IllegalArgumentException("Can't recognize " + jsFunc + " processor");
                }
            }

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

    /***
     * Not empty check with nullability
     * @param s string to check
     * @return true iff s in not null and not empty
     */
    static boolean isNotEmpty(String s) {
        return s != null && !s.isEmpty();
    }
}
