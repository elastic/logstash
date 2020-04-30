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


package org.logstash.benchmark.cli.util;

import java.io.File;
import java.nio.file.Paths;
import org.logstash.benchmark.cli.JRubyInstallation;
import org.logstash.benchmark.cli.LogstashInstallation;
import org.logstash.benchmark.cli.ui.LsVersionType;
import org.logstash.benchmark.cli.ui.UserOutput;

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
        final LsVersionType type, final UserOutput output) {
        final LogstashInstallation logstash;
        if (type == LsVersionType.LOCAL) {
            logstash = new LogstashInstallation.FromLocalPath(version);
        } else {
            logstash = new LogstashInstallation.FromRelease(
                Paths.get(pwd, String.format("ls-release-%s", version)).toFile(), version, output
            );
        }
        return logstash;
    }
}
