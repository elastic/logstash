/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */


package org.logstash.xpack.test;

import java.io.File;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.Arrays;
import java.util.List;

import org.jruby.Ruby;
import org.jruby.runtime.builtin.IRubyObject;
import org.junit.Assert;
import org.junit.Test;
import org.logstash.Logstash;
import org.logstash.RubyUtil;
import org.logstash.Rubyfier;

public class RSpecTests {

    private static final String LS_HOME;

    static {
        final File cwd = org.assertj.core.util.Files.currentFolder();
        final String root = cwd.getParent(); // CWD: x-pack
        // initialize global (RubyUtil.RUBY) runtime :
        Ruby.newInstance(Logstash.initRubyConfig(Paths.get(root), cwd.getAbsolutePath(), new String[0]));
        LS_HOME = root;
    }

    protected List<String> rspecArgs() {
        return Arrays.asList("-fd", "--pattern", "spec/**/*_spec.rb");
    }

    @Test
    public void rspecTests() throws Exception {
        RubyUtil.RUBY.getENV().put("IS_JUNIT_RUN", "true");
        RubyUtil.RUBY.getGlobalVariables().set(
            "$JUNIT_ARGV", Rubyfier.deep(RubyUtil.RUBY, rspecArgs())
        );
        final Path rspec = Paths.get(LS_HOME, "lib/bootstrap/rspec.rb");
        final IRubyObject result = RubyUtil.RUBY.executeScript(
            new String(Files.readAllBytes(rspec), StandardCharsets.UTF_8),
            rspec.toFile().getAbsolutePath()
        );
        if (!result.toJava(Long.class).equals(0L)) {
            Assert.fail("RSpec test suit saw at least one failure.");
        }
    }
}
