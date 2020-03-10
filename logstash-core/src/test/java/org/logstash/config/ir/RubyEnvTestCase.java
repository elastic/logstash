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
import org.jruby.RubyHash;
import org.jruby.runtime.builtin.IRubyObject;
import org.jruby.runtime.load.LoadService;
import org.junit.BeforeClass;
import org.logstash.RubyUtil;

import static org.logstash.RubyUtil.RUBY;

public abstract class RubyEnvTestCase {

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
            final RubyHash environment = RubyUtil.RUBY.getENV();
            final Path root = Paths.get(
                System.getProperty("logstash.core.root.dir", "")
            ).toAbsolutePath();
            final String gems = root.getParent().resolve("vendor").resolve("bundle")
                .resolve("jruby").resolve("2.5.0").toFile().getAbsolutePath();
            environment.put("GEM_HOME", gems);
            environment.put("GEM_PATH", gems);
            loader.addPaths(root.resolve("lib").toFile().getAbsolutePath());
        }
    }
}
