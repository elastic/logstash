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

import org.jruby.RubyHash;
import org.jruby.runtime.builtin.IRubyObject;
import org.jruby.runtime.load.LibrarySearcher;
import org.jruby.runtime.load.LoadService;
import org.junit.BeforeClass;
import org.logstash.RubyTestBase;
import org.logstash.RubyUtil;

public abstract class RubyEnvTestCase extends RubyTestBase {

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
        final LibrarySearcher librarySearcher = new LibrarySearcher(loader);
        if (librarySearcher.findLibraryForLoad("logstash/compiler") == null) {
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
