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


package org.logstash.config.ir;

import java.nio.file.Path;
import java.nio.file.Paths;

import org.assertj.core.util.Files;
import org.jruby.Ruby;
import org.jruby.RubyHash;
import org.jruby.runtime.load.LoadService;
import org.junit.BeforeClass;
import org.logstash.Logstash;
import org.logstash.RubyUtil;

public abstract class RubyEnvTestCase {

    private static final Path LS_HOME;

    static {
        Path root;
        if (System.getProperty("logstash.core.root.dir") == null) {
            // make sure we work from IDE as well as when run with Gradle
            root = Paths.get("");
        } else {
            root = Paths.get(System.getProperty("logstash.core.root.dir"));
        }
        if (root.endsWith("logstash-core")) { // ./gradlew
            root = root.getParent();
        }
        LS_HOME = root;

        final String cwd = Files.currentFolder().toString(); // keep work-dir as is
        // initialize global (RubyUtil.RUBY) runtime :
        Ruby.newInstance(Logstash.initRubyConfig(root.toAbsolutePath(), cwd, new String[0]));
    }

    @BeforeClass
    public static void before() {
        ensureLoadpath();
    }

    /**
     * Loads the logstash-core/lib path if the load service can't find {@code logstash/compiler}
     * because {@code environment.rb} hasn't been loaded yet.
     */
    private static void ensureLoadpath() {
        final LoadService loader = RubyUtil.RUBY.getLoadService();
        if (loader.findFileForLoad("logstash/compiler").library == null) {
            final String gems = LS_HOME.
                    resolve("vendor").resolve("bundle").resolve("jruby").resolve("2.5.0").
                    toFile().getAbsolutePath();
            final RubyHash environment = RubyUtil.RUBY.getENV();
            environment.put("GEM_HOME", gems);
            environment.put("GEM_PATH", gems);
            Path logstashCore = LS_HOME.resolve("logstash-core");
            loader.addPaths(logstashCore.resolve("lib").toFile().getAbsolutePath());
        }
    }
}
