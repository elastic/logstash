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


package org.logstash.integration;

import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.Arrays;

import org.jruby.Ruby;
import org.jruby.runtime.builtin.IRubyObject;
import org.junit.Assert;
import org.junit.Test;
import org.logstash.Logstash;
import org.logstash.RubyUtil;
import org.logstash.Rubyfier;

/**
 * JUnit Wrapper for RSpec Integration Tests.
 */
public final class RSpecTests {

    static {
        Path root;
        if (System.getProperty("logstash.root.dir") == null) {
            // make sure we work from IDE as well as when run with Gradle
            root = Paths.get("").toAbsolutePath(); // LS_HOME/qa/integration
            if (root.endsWith("integration")) root = root.getParent().getParent();
        } else {
            root = Paths.get(System.getProperty("logstash.root.dir")).toAbsolutePath();
        }

        if (!root.resolve("versions.yml").toFile().exists()) {
            throw new AssertionError("versions.yml not found is logstash root dir: " + root);
        }

        initializeGlobalRuntime(root);
    }

    private static Ruby initializeGlobalRuntime(final Path root) {
        String[] args = new String[] { "--disable-did_you_mean" };
        Ruby runtime = Ruby.newInstance(Logstash.initRubyConfig(root, null /* qa/integration */, args));
        if (runtime != RubyUtil.RUBY) throw new AssertionError("runtime already initialized");
        return runtime;
    }

    @Test
    public void rspecTests() throws Exception {
        RubyUtil.RUBY.getGlobalVariables().set(
            "$JUNIT_ARGV", Rubyfier.deep(RubyUtil.RUBY, Arrays.asList(
                "-fd", "--pattern", System.getProperty("org.logstash.integration.specs", "specs/**/*_spec.rb")
            ))
        );
        final Path rspec = Paths.get("rspec.rb"); // qa/integration/rspec.rb
        final IRubyObject result = RubyUtil.RUBY.executeScript(
            new String(Files.readAllBytes(rspec), StandardCharsets.UTF_8),
            rspec.toFile().getAbsolutePath()
        );
        if (!result.toJava(Long.class).equals(0L)) {
            Assert.fail("RSpec test suit saw at least one failure.");
        }
    }
}
