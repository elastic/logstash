package org.logstash.benchmark.cli.util;

import java.io.File;
import java.nio.file.Paths;
import org.logstash.benchmark.cli.JRubyInstallation;
import org.logstash.benchmark.cli.LogstashInstallation;
import org.logstash.benchmark.cli.ui.LsVersionType;

public final class LsBenchLsSetup {

    private LsBenchLsSetup() {
    }

    public static LogstashInstallation logstashFromGit(final String pwd, final String version,
        final JRubyInstallation jruby) {
        final File lsdir = Paths.get(pwd, "logstash").toFile();
        final LogstashInstallation logstash;
        if (version.contains("#")) {
            final String[] parts = version.split("#");
            logstash = new LogstashInstallation.FromGithub(lsdir, parts[0], parts[1], jruby);
        } else {
            logstash = new LogstashInstallation.FromGithub(lsdir, version, jruby);
        }
        return logstash;
    }

    public static LogstashInstallation setupLS(final String pwd, final String version,
        final LsVersionType type) {
        final LogstashInstallation logstash;
        if (type == LsVersionType.LOCAL) {
            logstash = new LogstashInstallation.FromLocalPath(version);
        } else {
            logstash = new LogstashInstallation.FromRelease(
                Paths.get(pwd, String.format("ls-release-%s", version)).toFile(), version
            );
        }
        return logstash;
    }
}
