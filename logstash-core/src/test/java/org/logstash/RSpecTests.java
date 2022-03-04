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

import java.nio.charset.StandardCharsets;
import java.nio.file.Path;
import java.util.Arrays;
import java.util.Collection;

import org.jruby.runtime.builtin.IRubyObject;
import org.junit.Assert;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.junit.runners.Parameterized;
import org.junit.runners.Parameterized.Parameter;
import org.junit.runners.Parameterized.Parameters;

/**
 * Runs the Logstash RSpec suit.
 */
@RunWith(Parameterized.class)
public class RSpecTests extends RubyTestBase {

    @Parameters(name="{0}")
    public static Collection<Object[]> data() {
        return Arrays.asList(new Object[][] {
                { "compliance", "spec/compliance/**/*_spec.rb" },
                { "core tests", "spec/unit/**/*_spec.rb" + ',' + "logstash-core/spec/**/*_spec.rb" }
        });
    }

    @Parameter(0)
    public String description;

    @Parameter(1)
    public String specGlob;

    @Test
    public void rspecTests() throws Exception {
        RubyUtil.RUBY.getENV().put("IS_JUNIT_RUN", "true");
        RubyUtil.RUBY.getGlobalVariables().set(
            "$JUNIT_ARGV",
            Rubyfier.deep(
                RubyUtil.RUBY, Arrays.asList(
                    "-fd", "--pattern", specGlob
                ))
        );
        final Path rspec = LS_HOME.resolve("lib").resolve("bootstrap").resolve("rspec.rb");
        final IRubyObject result = RubyUtil.RUBY.executeScript(
            new String(java.nio.file.Files.readAllBytes(rspec), StandardCharsets.UTF_8),
            rspec.toFile().getAbsolutePath()
        );
        if (!result.toJava(Long.class).equals(0L)) {
            Assert.fail(String.format("RSpec test suite `%s` saw at least one failure.", description));
        }
    }
}
