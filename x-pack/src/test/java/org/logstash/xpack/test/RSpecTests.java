/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */


package org.logstash.xpack.test;

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

    static final Path LS_HOME;

    static {
        Path root;
        if (System.getProperty("logstash.root.dir") == null) {
            // make sure we work from IDE as well as when run with Gradle
            root = Paths.get("").toAbsolutePath(); // LS_HOME/x-pack
            if (root.endsWith("x-pack")) root = root.getParent();
        } else {
            root = Paths.get(System.getProperty("logstash.root.dir")).toAbsolutePath();
        }

        if (!root.resolve("versions.yml").toFile().exists()) {
            throw new AssertionError("versions.yml not found is logstash root dir: " + root);
        }
        LS_HOME = root;

        initializeGlobalRuntime(root);
    }

    private static Ruby initializeGlobalRuntime(final Path root) {
        String[] args = new String[] { "--disable-did_you_mean" };
        Ruby runtime = Ruby.newInstance(Logstash.initRubyConfig(root, null /* qa/integration */, args));
        if (runtime != RubyUtil.RUBY) throw new AssertionError("runtime already initialized");
        return runtime;
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
        final Path rspec = LS_HOME.resolve("lib").resolve("bootstrap").resolve("rspec.rb");
        final IRubyObject result = RubyUtil.RUBY.executeScript(
            new String(Files.readAllBytes(rspec), StandardCharsets.UTF_8),
            rspec.toFile().getAbsolutePath()
        );
        if (!result.toJava(Long.class).equals(0L)) {
            Assert.fail("RSpec test suit saw at least one failure.");
        }
    }
}
