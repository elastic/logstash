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
import java.nio.file.StandardOpenOption;
import java.security.NoSuchAlgorithmException;
import java.util.Map;
import org.apache.commons.io.IOUtils;
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
    void execute(String configuration, File data) throws IOException, InterruptedException;

    /**
     * Returns the url under which the metrics from uri `_node/stats/?pretty` can be found.
     * @return Metrics URL
     */
    String metrics();

    final class FromRelease implements LogstashInstallation {

        private final LogstashInstallation base;

        public FromRelease(final File pwd, final String version) {
            try {
                LogstashInstallation.FromRelease.download(pwd, version);
                this.base = LogstashInstallation.FromRelease.setup(
                    pwd.toPath().resolve(String.format("logstash-%s", version))
                );
            } catch (IOException | NoSuchAlgorithmException ex) {
                throw new IllegalStateException(ex);
            }
        }

        @Override
        public void execute(final String configuration) throws IOException, InterruptedException {
            base.execute(configuration);
        }

        @Override
        public void execute(final String configuration, final File data)
            throws IOException, InterruptedException {
            base.execute(configuration, data);
        }

        @Override
        public String metrics() {
            return base.metrics();
        }

        private static void download(final File pwd, final String version)
            throws IOException, NoSuchAlgorithmException {
            LsBenchDownloader.downloadDecompress(
                pwd,
                String.format(
                    "https://artifacts.elastic.co/downloads/logstash/logstash-%s.zip",
                    version
                ), true
            );
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

        public FromLocalPath(final String path) {
            this.location = Paths.get(path);
            this.pbuilder = new ProcessBuilder().directory(location.toFile());
            final Path jruby = location.resolve("vendor").resolve("jruby");
            LsBenchFileUtil.ensureExecutable(jruby.resolve("bin").resolve("jruby").toFile());
            final Map<String, String> env = pbuilder.environment();
            env.put("JRUBY_HOME", jruby.toString());
            env.put("JAVA_OPTS", "");
        }

        @Override
        public void execute(final String configuration) throws IOException, InterruptedException {
            execute(configuration, null);
        }

        @Override
        public void execute(final String configuration, final File data)
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
            final Process process = pbuilder.command(lsbin.toString(), "-w", "2", "-f", cfg.toString()).redirectOutput(
                ProcessBuilder.Redirect.to(output)
            ).start();
            if (data != null) {
                try (final InputStream file = new FileInputStream(data);
                     final OutputStream out = process.getOutputStream()) {
                    IOUtils.copy(file, out, 16 * 4096);
                }
            }
            if (process.waitFor() != 0) {
                throw new IllegalStateException("Logstash failed to start!");
            }
            LsBenchFileUtil.ensureDeleted(cfg.toFile());
            LsBenchFileUtil.ensureDeleted(output);
        }

        @Override
        public String metrics() {
            return METRICS_URL;
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
        public void execute(final String configuration, final File data)
            throws IOException, InterruptedException {
            base.execute(configuration, data);
        }

        @Override
        public String metrics() {
            return base.metrics();
        }

        private static void download(final File pwd, final String user, final String hash)
            throws IOException, NoSuchAlgorithmException {
            LsBenchDownloader.downloadDecompress(
                pwd, String.format("https://github.com/%s/logstash/archive/%s.zip", user, hash),
                true
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
