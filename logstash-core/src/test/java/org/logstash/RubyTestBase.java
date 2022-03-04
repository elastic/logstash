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

import org.jruby.Ruby;

import java.nio.file.Path;
import java.nio.file.Paths;

/**
 * The point of this testing base is to initialize the global runtime.
 * This is necessary as LS relies on a static RubyUtil.RUBY to be the runtime used by LS.
 *
 * Any test using the org.jruby API directly or indirectly should depend on this class.
 */
public abstract class RubyTestBase {

    public static final Path LS_HOME;

    static {
        Path root;
        if (System.getProperty("logstash.root.dir") == null) {
            // make sure we work from IDE as well as when run with Gradle
            root = Paths.get("").toAbsolutePath();
            if (root.endsWith("logstash-core")) root = root.getParent();
        } else {
            root = Paths.get(System.getProperty("logstash.root.dir")).toAbsolutePath();
        }

        if (!root.resolve("versions.yml").toFile().exists()) {
            throw new AssertionError("versions.yml not found is logstash root dir: " + root);
        }
        LS_HOME = root;

        initializeGlobalRuntime(LS_HOME);
    }

    static Ruby initializeGlobalRuntime(final Path currentDir) {
        String[] args = new String[] { "--disable-did_you_mean" };
        Ruby runtime = Ruby.newInstance(Logstash.initRubyConfig(LS_HOME, currentDir, args));
        if (runtime != RubyUtil.RUBY) throw new AssertionError("runtime already initialized. perhaps a Test class isn't subclassing RubyTestBase as it should?");
        return runtime;
    }

}
