package org.logstash;

import java.io.IOException;
import java.io.InputStream;
import java.io.PrintStream;
import java.nio.file.Path;
import java.nio.file.Paths;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.jruby.Ruby;
import org.jruby.RubyException;
import org.jruby.RubyInstanceConfig;
import org.jruby.RubyNumeric;
import org.jruby.exceptions.RaiseException;
import org.jruby.runtime.builtin.IRubyObject;

/**
 * Logstash Main Entrypoint.
 */
public final class Logstash implements Runnable, AutoCloseable {

    private static final Logger LOGGER = LogManager.getLogger(Logstash.class);

    /**
     * JRuby Runtime Environment.
     */
    private final Ruby ruby;

    /**
     * Main Entrypoint.
     * Requires environment {@code "LS_HOME"} to be set to the Logstash root directory.
     * @param args Logstash CLI Arguments
     */
    public static void main(final String... args) {
        final String lsHome = System.getenv("LS_HOME");
        if (lsHome == null) {
            throw new IllegalStateException(
                "LS_HOME environment variable must be set. This is likely a bug that should be reported."
            );
        }
        final Path home = Paths.get(lsHome).toAbsolutePath();
        try (
            final Logstash logstash = new Logstash(home, args, System.out, System.err, System.in)
        ) {
            logstash.run();
        } catch (final Throwable t) {
            LOGGER.error("Logstash encountered an unexpected fatal error!", t);
            System.exit(1);
        }
        System.exit(0);
    }

    /**
     * Ctor.
     * @param home Logstash Root Directory
     * @param args Commandline Arguments
     * @param output Output Stream Capturing StdOut
     * @param error Output Stream Capturing StdErr
     * @param input Input Stream Capturing StdIn
     */
    Logstash(final Path home, final String[] args, final PrintStream output,
        final PrintStream error, final InputStream input) {
        final RubyInstanceConfig config = buildConfig(home, args);
        config.setOutput(output);
        config.setError(error);
        config.setInput(input);
        ruby = Ruby.newInstance(config);
    }

    @Override
    public void run() {
        // @todo: Refactor codebase to not rely on global constant for Ruby Runtime
        if (RubyUtil.RUBY != ruby) {
            throw new IllegalStateException(
                "More than one JRuby Runtime detected in the current JVM!"
            );
        }
        final RubyInstanceConfig config = ruby.getInstanceConfig();
        try (InputStream script = config.getScriptSource()) {
            Thread.currentThread().setContextClassLoader(ruby.getJRubyClassLoader());
            ruby.runFromMain(script, config.displayedFileName());
        } catch (final RaiseException ex) {
            final RubyException rexep = ex.getException();
            if (ruby.getSystemExit().isInstance(rexep)) {
                final IRubyObject status =
                    rexep.callMethod(ruby.getCurrentContext(), "status");
                if (status != null && !status.isNil() && RubyNumeric.fix2int(status) != 0) {
                    uncleanShutdown(ex);
                }
            } else {
                uncleanShutdown(ex);
            }
        } catch (final IOException ex) {
            uncleanShutdown(ex);
        }
    }

    @Override
    public void close() {
        ruby.tearDown(false);
    }

    /**
     * Sets up the correct {@link RubyInstanceConfig} for a given Logstash installation and set of
     * CLI arguments.
     * @param home Logstash Root Path
     * @param args Commandline Arguments Passed to Logstash
     * @return RubyInstanceConfig
     */
    private static RubyInstanceConfig buildConfig(final Path home, final String[] args) {
        final String[] arguments = new String[args.length + 2];
        System.arraycopy(args, 0, arguments, 2, args.length);
        arguments[0] = safePath(home, "lib", "bootstrap", "environment.rb");
        arguments[1] = safePath(home, "logstash-core", "lib", "logstash", "runner.rb");
        final RubyInstanceConfig config = new RubyInstanceConfig();
        config.processArguments(arguments);
        return config;
    }

    /**
     * Builds the correct path for a file under the given Logstash root and defined by its sub path
     * elements relative to the Logstash root.
     * Ensures that the file exists and throws an exception of it's missing.
     * This is done to avoid hard to interpret errors thrown by JRuby that could result from missing
     * Ruby bootstrap scripts.
     * @param home Logstash Root Path
     * @param subs Path elements relative to {@code home}
     * @return Absolute Path a File under the Logstash Root.
     */
    private static String safePath(final Path home, final String... subs) {
        Path resolved = home;
        for (final String element : subs) {
            resolved = resolved.resolve(element);
        }
        if (!resolved.toFile().exists()) {
            throw new IllegalArgumentException(String.format("Missing: %s.", resolved));
        }
        return resolved.toString();
    }

    private static void uncleanShutdown(final Exception ex) {
        throw new IllegalStateException("Logstash stopped processing because of an error: " + ex.getMessage(), ex);
    }
}
