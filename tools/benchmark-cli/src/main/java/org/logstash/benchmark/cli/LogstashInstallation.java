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


package org.logstash.benchmark.cli;

import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardCopyOption;
import java.nio.file.StandardOpenOption;
import java.security.NoSuchAlgorithmException;
import java.util.Map;
import org.apache.commons.io.IOUtils;
import org.logstash.benchmark.cli.ui.UserOutput;
import org.logstash.benchmark.cli.util.LsBenchDownloader;
import org.logstash.benchmark.cli.util.LsBenchFileUtil;

public interface LogstashInstallation {

    /**
     * Runs the Logstash Installation with the given configuration.
     * @param configuration Configuration as String
     * @throws IOException On I/O Exception
     * @throws InterruptedException Iff Interrupted
     */
    void execute(String configuration) throws IOException, InterruptedException;

    /**
     * Runs the Logstash Installation with the given configuration and given File piped to
     * standard input.
     * @param configuration Configuration as String
     * @param data Data file piped to standard input
     * @throws IOException On I/O Exception
     * @throws InterruptedException Iff Interrupted
     */
    void execute(String configuration, File data, int repeat) throws IOException, InterruptedException;

    /**
     * Returns the url under which the metrics from uri `_node/stats/?pretty` can be found.
     * @return Metrics URL
     */
    String metrics();

    /**
     * Temporarily (will be reverted after the benchmark execution finishes) overwrites the existing
     * logstash.yml configuration in this installation.
     * @param meta Benchmark settings
     */
    void configure(BenchmarkMeta meta);

    final class FromRelease implements LogstashInstallation {

        private final LogstashInstallation base;

        public FromRelease(final File pwd, final String version, final UserOutput output) {
            try {
                final Path basedir = pwd.toPath().resolve(String.format("logstash-%s", version));
                if (basedir.toFile().exists()) {
                    output.blue(String.format("Using Logstash %s from cache.", version));
                } else {
                    output.blue(String.format("Downloading Logstash %s.", version));
                    LogstashInstallation.FromRelease.download(pwd, version);
                    output.blue("Finished downloading Logstash.");
                }
                this.base = LogstashInstallation.FromRelease.setup(basedir);
            } catch (IOException | NoSuchAlgorithmException ex) {
                throw new IllegalStateException(ex);
            }
        }

        @Override
        public void execute(final String configuration) throws IOException, InterruptedException {
            base.execute(configuration);
        }

        @Override
        public void execute(final String configuration, final File data, final int repeat)
            throws IOException, InterruptedException {
            base.execute(configuration, data, repeat);
        }

        @Override
        public String metrics() {
            return base.metrics();
        }

        @Override
        public void configure(final BenchmarkMeta meta) {
            base.configure(meta);
        }

        private static void download(final File pwd, final String version)
            throws IOException, NoSuchAlgorithmException {

            final String arch = retrieveCPUArchitecture();
            final String os = retrieveOS();
            final String extension = "windows".equals(os) ? "zip" : "tar.gz";

            final String downloadUrl;
            if (compareVersions(version, "7.10.0") >= 0) {
                // version >= 7.10.0 url format
                downloadUrl = String.format(
                        "https://artifacts.elastic.co/downloads/logstash/logstash-%s-%s-%s.%s", version, os, arch, extension
                );
            } else {
                // version < 7.10.0 url format
                downloadUrl = String.format(
                        "https://artifacts.elastic.co/downloads/logstash/logstash-%s.%s", version, extension
                );
            }

            LsBenchDownloader.downloadDecompress(pwd, downloadUrl);
        }

        private static int compareVersions(String s, String t) {
            final String[] sSplits = s.split("\\.");
            final int sMajor = Integer.parseInt(sSplits[0]);
            final int sMinor = Integer.parseInt(sSplits[1]);
            final int sPatch = Integer.parseInt(sSplits[2]);

            final String[] tSplits = t.split("\\.");
            final int tMajor = Integer.parseInt(tSplits[0]);
            final int tMinor = Integer.parseInt(tSplits[1]);
            final int tPatch = Integer.parseInt(tSplits[2]);

            if (sMajor == tMajor) {
                if (sMinor == tMinor) {
                    return Integer.compare(sPatch, tPatch);
                } else {
                    return Integer.compare(sMinor, tMinor);
                }
            } else {
                return Integer.compare(sMajor, tMajor);
            }
        }

        private static String retrieveOS() {
            String osName = System.getProperty("os.name");
            if (osName.matches("Mac OS X")) {
                return "darwin";
            }
            if (osName.matches("[Ll]inux")) {
                return "linux";
            }
            if (osName.matches("Windows")) {
                return "windows";
            }
            throw new IllegalArgumentException("Unrecognized OS: " + osName);
        }

        private static String retrieveCPUArchitecture() {
            final String arch = System.getProperty("os.arch");
            switch (arch) {
                case "aarch64":
                    return "aarch64";
                case "amd64":
                    return "x86_64";
                default:
                    return arch;
            }
        }

        private static LogstashInstallation setup(final Path location) {
            return new LogstashInstallation.FromLocalPath(location.toAbsolutePath().toString());
        }
    }

    final class FromLocalPath implements LogstashInstallation {

        /**
         * Metrics URL.
         */
        private static final String METRICS_URL = "http://127.0.0.1:9600/_node/stats/?pretty";

        private final Path location;

        private final ProcessBuilder pbuilder;

        private final Path previousYml;
        
        private final Path logstashYml;

        public FromLocalPath(final String path) {
            this.location = Paths.get(path);
            this.pbuilder = new ProcessBuilder().directory(location.toFile());
            final Path jruby = location.resolve("vendor").resolve("jruby");
            LsBenchFileUtil.ensureExecutable(jruby.resolve("bin").resolve("jruby").toFile());
            final Map<String, String> env = pbuilder.environment();
            env.put("JRUBY_HOME", jruby.toString());
            env.put("JAVA_OPTS", "");
            logstashYml = location.resolve("config").resolve("logstash.yml");
            try {
                previousYml =
                    Files.copy(
                        logstashYml, logstashYml.getParent().resolve("logstash.yml.back"),
                        StandardCopyOption.REPLACE_EXISTING
                    );
            } catch (final IOException ex) {
                throw new IllegalStateException(ex);
            }
        }

        @Override
        public void execute(final String configuration) throws IOException, InterruptedException {
            execute(configuration, null, 1);
        }

        @Override
        public void execute(final String configuration, final File data, final int repeat)
            throws IOException, InterruptedException {
            final Path cfg = location.resolve("config.temp");
            Files.write(
                cfg,
                configuration.getBytes(StandardCharsets.UTF_8),
                StandardOpenOption.WRITE, StandardOpenOption.TRUNCATE_EXISTING,
                StandardOpenOption.CREATE
            );
            final Path lsbin = location.resolve("bin").resolve("logstash");
            LsBenchFileUtil.ensureExecutable(lsbin.toFile());
            final File output = Files.createTempFile(null, null).toFile();
            final Process process =
                pbuilder.command(lsbin.toString(), "-f", cfg.toString()
                ).redirectOutput(ProcessBuilder.Redirect.to(output)).start();
            if (data != null) {
                try (final OutputStream out = process.getOutputStream()) {
                    pipeRepeatedly(data, out, repeat);
                }
            }
            if (process.waitFor() != 0) {
                throw new IllegalStateException("Logstash failed to start!");
            }
            LsBenchFileUtil.ensureDeleted(cfg.toFile());
            Files.move(previousYml, logstashYml, StandardCopyOption.REPLACE_EXISTING);
            LsBenchFileUtil.ensureDeleted(output);
        }

        @Override
        public String metrics() {
            return METRICS_URL;
        }

        @Override
        public void configure(final BenchmarkMeta meta) {
            try {
                Files.write(
                    logstashYml, String.format(
                        "pipeline.workers: %d\npipeline.batch.size: %d", meta.getWorkers()
                        , meta.getBatchsize()
                    ).getBytes(StandardCharsets.UTF_8),
                    StandardOpenOption.WRITE, StandardOpenOption.TRUNCATE_EXISTING,
                    StandardOpenOption.CREATE
                );
            } catch (final IOException ex) {
                throw new IllegalStateException(ex);
            }
        }

        /**
         * Pipes the content of the given input {@link File} to the given {@link OutputStream}
         * repeatedly.
         * @param input Input File
         * @param out Output Stream
         * @param count Number of repeats
         * @throws IOException On Failure
         */
        private static void pipeRepeatedly(final File input, final OutputStream out,
            final int count) throws IOException {
            for (int i = 0; i < count; ++i) {
                try (final InputStream file = new FileInputStream(input)) {
                    IOUtils.copy(file, out, 16 * 4096);
                }
            }
        }
    }

    final class FromGithub implements LogstashInstallation {

        private final Path location;

        private final LogstashInstallation base;

        public FromGithub(final File pwd, final String hash, final JRubyInstallation jruby) {
            this(pwd, "elastic", hash, jruby);
        }

        public FromGithub(final File pwd, final String user, final String hash,
            final JRubyInstallation jruby) {
            this.location = pwd.toPath().resolve(String.format("logstash-%s", hash));
            try {
                LogstashInstallation.FromGithub.download(pwd, user, hash);
                this.base = LogstashInstallation.FromGithub.setup(jruby, this.location);
            } catch (IOException | InterruptedException | NoSuchAlgorithmException ex) {
                throw new IllegalStateException(ex);
            }
        }

        @Override
        public void execute(final String configuration) throws IOException, InterruptedException {
            base.execute(configuration);
        }

        @Override
        public void execute(final String configuration, final File data, final int repeat)
            throws IOException, InterruptedException {
            base.execute(configuration, data, repeat);
        }

        @Override
        public String metrics() {
            return base.metrics();
        }

        @Override
        public void configure(final BenchmarkMeta meta) {
            base.configure(meta);
        }

        private static void download(final File pwd, final String user, final String hash)
            throws IOException, NoSuchAlgorithmException {
            LsBenchDownloader.downloadDecompress(
                pwd, String.format("https://github.com/%s/logstash/archive/%s.zip", user, hash)
            );
        }

        private static LogstashInstallation setup(final JRubyInstallation ruby, final Path location)
            throws IOException, InterruptedException {
            final ProcessBuilder pbuilder = new ProcessBuilder().directory(location.toFile());
            final Map<String, String> env = pbuilder.environment();
            env.put("JRUBY_HOME", Paths.get(ruby.gem()).getParent().getParent().toString());
            env.put("JAVA_OPTS", "");
            final File gem = new File(ruby.gem());
            if (!gem.setExecutable(true) ||
                pbuilder.command(gem.getAbsolutePath(), "install", "rake").inheritIO()
                    .start().waitFor() != 0) {
                throw new IllegalStateException("Bootstrapping Rake Failed!");
            }
            for (final File exec : location.resolve("bin").toFile().listFiles()) {
                LsBenchFileUtil.ensureExecutable(exec);
            }
            final String rakepath = ruby.rake();
            final File rake = new File(rakepath);
            if (!location.resolve("gradlew").toFile().setExecutable(true) ||
                !new File(ruby.jruby()).setExecutable(true)
                || !rake.setExecutable(true)
                || pbuilder.command(rakepath, "bootstrap").inheritIO().start()
                .waitFor() != 0) {
                throw new IllegalStateException("Bootstrapping Logstash Failed!");
            }
            if (pbuilder.command(rakepath, "plugin:install-default").inheritIO().start()
                .waitFor() != 0) {
                throw new IllegalStateException("Bootstrapping Logstash Default Plugins Failed!");
            }
            return new LogstashInstallation.FromLocalPath(location.toAbsolutePath().toString());
        }
    }
}
