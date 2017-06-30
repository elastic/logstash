package org.logstash.benchmark.cli;

import java.io.IOException;
import java.nio.file.Path;
import java.security.NoSuchAlgorithmException;
import org.logstash.benchmark.cli.util.LsBenchDownloader;

/**
 * JRuby Installation.
 */
public final class JRubyInstallation {

    private static final String JRUBY_DEFAULT_VERSION = "9.1.10.0";

    /**
     * Path of the `gem` executable.
     */
    private final Path gem;

    /**
     * Path of the `rake` executable.
     */
    private final Path rake;

    /**
     * Path of the `ruby` executable.
     */
    private final Path jruby;

    /**
     * Sets up a JRuby used to bootstrap a Logstash Installation.
     * @param pwd Cache Directory to work in
     * @return instance
     * @throws IOException On I/O Error during JRuby Download or Installation
     * @throws NoSuchAlgorithmException On SSL Issue during JRuby Download
     */
    public static JRubyInstallation bootstrapJruby(final Path pwd)
        throws IOException, NoSuchAlgorithmException {
        LsBenchDownloader.downloadDecompress(
            pwd.resolve("jruby").toFile(),
            String.format(
                "http://jruby.org.s3.amazonaws.com/downloads/%s/jruby-bin-%s.tar.gz",
                JRUBY_DEFAULT_VERSION, JRUBY_DEFAULT_VERSION
            ),
            false
        );
        return new JRubyInstallation(
            pwd.resolve("jruby").resolve(String.format("jruby-%s", JRUBY_DEFAULT_VERSION))
        );
    }

    private JRubyInstallation(final Path root) {
        final Path bin = root.resolve("bin");
        this.gem = bin.resolve("gem");
        this.jruby = bin.resolve("jruby");
        this.rake = bin.resolve("rake");
    }

    public String gem() {
        return gem.toAbsolutePath().toString();
    }

    public String rake() {
        return rake.toAbsolutePath().toString();
    }

    public String jruby() {
        return jruby.toAbsolutePath().toString();
    }
}
