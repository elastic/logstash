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


package org.logstash;

import java.io.IOError;
import java.io.IOException;
import java.io.InputStream;
import java.io.PrintStream;
import java.nio.file.Path;
import java.nio.file.Paths;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.jruby.Ruby;
import org.jruby.RubyClass;
import org.jruby.RubyException;
import org.jruby.RubyInstanceConfig;
import org.jruby.RubyStandardError;
import org.jruby.RubySystemExit;
import org.jruby.exceptions.RaiseException;
import org.jruby.runtime.builtin.IRubyObject;

import javax.annotation.Nullable;

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
        installGlobalUncaughtExceptionHandler();

        final Path home = Paths.get(lsHome).toAbsolutePath();
        try (
                final Logstash logstash = new Logstash(home, args, System.out, System.err, System.in)
        ) {
            logstash.run();
        } catch (final IllegalStateException e) {
            Throwable t = e;
            String message = e.getMessage();
            if (message != null) {
                if (message.startsWith(UNCLEAN_SHUTDOWN_PREFIX) ||
                    message.startsWith(MUTATED_GEMFILE_ERROR)) {
                    t = e.getCause(); // be less verbose with uncleanShutdown's wrapping exception
                } else if (message.contains("Could not load FFI Provider")) {
                    message =
                            "Error accessing temp directory: " + System.getProperty("java.io.tmpdir") +
                                    " this often occurs because the temp directory has been mounted with NOEXEC or" +
                                    " the Logstash user has insufficient permissions on the directory. \n" +
                                    "Possible workarounds include setting the -Djava.io.tmpdir property in the jvm.options" +
                                    "file to an alternate directory or correcting the Logstash user's permissions.";
                }
            }
            handleFatalError(message, t);
        } catch (final Throwable t) {
            handleFatalError("", t);
        }

        System.exit(0);
    }

    private static void installGlobalUncaughtExceptionHandler() {
        Thread.setDefaultUncaughtExceptionHandler((thread, e) -> {
            if (e instanceof Error) {
                handleFatalError("uncaught error (in thread " + thread.getName() + ")",  e);
            } else {
                LOGGER.error("uncaught exception (in thread " + thread.getName() + ")", e);
            }
        });
    }

    private static void handleFatalError(String message, Throwable t) {
        LOGGER.fatal(message, t);

        if (t instanceof InternalError) {
            halt(128);
        } else if (t instanceof OutOfMemoryError) {
            halt(127);
        } else if (t instanceof StackOverflowError) {
            halt(126);
        } else if (t instanceof UnknownError) {
            halt(125);
        } else if (t instanceof IOError) {
            halt(124);
        } else if (t instanceof LinkageError) {
            halt(123);
        } else if (t instanceof Error) {
            halt(120);
        }

        System.exit(1);
    }

    private static void halt(final int status) {
        // we halt to prevent shutdown hooks from running
        Runtime.getRuntime().halt(status);
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
            final RubyException re = ex.getException();

            // If this is a production error this signifies an issue with the Gemfile, likely
            // that a logstash developer has made changes to their local Gemfile for plugin
            // development, etc. If this is the case, exit with a warning giving remediating
            // information for Logstash devs.
            if (isProductionError(re)){
                bundlerStartupError(ex);
            }

            if (re instanceof RubySystemExit) {
                IRubyObject success = ((RubySystemExit) re).success_p();
                if (!success.isTrue()) {
                    uncleanShutdown(ex);
                }
            } else {
                uncleanShutdown(ex);
            }
        } catch (final IOException ex) {
            uncleanShutdown(ex);
        }
    }

    // Tests whether the RubyException is of type `Bundler::ProductionError`
    private boolean isProductionError(RubyException re){
        if (re instanceof RubyStandardError){
            RubyClass metaClass = re.getMetaClass();
            return (metaClass.getName().equals("Bundler::ProductionError"));
        }
        return false;
    }

    @Override
    public void close() {
        ruby.tearDown(false);
    }

    /**
     * Initialize a runtime configuration.
     * @param lsHome the LOGSTASH_HOME
     * @param args extra arguments (ARGV) to process
     * @return a runtime configuration instance
     */
    public static RubyInstanceConfig initRubyConfig(final Path lsHome,
                                                    final String... args) {
        return initRubyConfigImpl(lsHome, safePath(lsHome, "vendor", "jruby"), args);
    }

    /**
     * Initialize a runtime configuration.
     * @param lsHome the LOGSTASH_HOME
     * @param args extra arguments (ARGV) to process
     * @return a runtime configuration instance
     */
    public static RubyInstanceConfig initRubyConfig(final Path lsHome,
                                                    final Path currentDir,
                                                    final String... args) {

        return initRubyConfigImpl(currentDir, safePath(lsHome, "vendor", "jruby"), args);
    }

    private static RubyInstanceConfig initRubyConfigImpl(@Nullable final Path currentDir,
                                                     final String jrubyHome,
                                                     final String[] args) {
        final RubyInstanceConfig config = new RubyInstanceConfig();
        if (currentDir != null) config.setCurrentDirectory(currentDir.toString());
        config.setJRubyHome(jrubyHome);
        config.processArguments(args);
        return config;
    }

    /**
     * Sets up the correct {@link RubyInstanceConfig} for a given Logstash installation and set of
     * CLI arguments.
     * @param home Logstash Root Path
     * @param args Commandline Arguments Passed to Logstash
     * @return RubyInstanceConfig
     */
    private static RubyInstanceConfig buildConfig(final Path home, final String[] args) {
        final String[] arguments = new String[args.length + 1];
        System.arraycopy(args, 0, arguments, 1, args.length);
        arguments[0] = safePath(home, "lib", "bootstrap", "environment.rb");
        return initRubyConfig(home, arguments);
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

    private static final String UNCLEAN_SHUTDOWN_PREFIX = "Logstash stopped processing because of an error: ";
    private static final String MUTATED_GEMFILE_ERROR = "Logstash was unable to start due to an unexpected Gemfile change.\n" +
            "If you are a user, this is a bug.\n" +
            "If you are a logstash developer, please try restarting logstash with the " +
            "`--enable-local-plugin-development` flag set.";

    private static void bundlerStartupError(final Exception ex){
        throw new IllegalStateException(MUTATED_GEMFILE_ERROR);
    }

    private static void uncleanShutdown(final Exception ex) {
        throw new IllegalStateException(UNCLEAN_SHUTDOWN_PREFIX + ex.getMessage(), ex);
    }

}
