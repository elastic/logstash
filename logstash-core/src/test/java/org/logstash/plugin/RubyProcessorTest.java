package org.logstash.plugin;

import org.jruby.Ruby;
import org.jruby.RubyModule;
import org.jruby.embed.ScriptingContainer;
import org.junit.Test;

import java.io.IOException;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.List;
import java.util.Map;

public class RubyProcessorTest {
    private ScriptingContainer container = new ScriptingContainer();
    private Ruby ruby = container.getProvider().getRuntime();

    @Test
    public void testRubyFilter() throws IOException {
        Path root = Paths.get("..").toRealPath();

        List<String> loadPaths = container.getLoadPaths();
        loadPaths.add(root.resolve("lib").toString());
        loadPaths.add(root.resolve("lib/logstash-core").toString());
        container.setLoadPaths(loadPaths);

        Map env = container.getEnvironment();
        env.put("GEM_HOME", root.resolve("vendor/bundle/jruby/2.3.0").toString());
        env.put("GEM_PATH", root.resolve("vendor/bundle/jruby/2.3.0").toString());
        env.put("GEM_SPEC_CACHE", root.resolve("vendor/bundle/jruby/2.3.0/specifications").toString());
        container.setEnvironment(env);

        env.forEach((key, value) -> {
            if (((String) key).matches(".*GEM.*")) {
                System.out.println(key + ": " + value);
            }
        });

        for (String p : loadPaths) {
            System.out.println(p);
        }
        RubyModule kernel = ruby.getKernel();
        container.callMethod(kernel, "require", "../lib/bootstrap/environment");

        container.runScriptlet("Gem::Specification.all.map { |x| p x.name }");

        System.out.println("Bundler: " + container.runScriptlet("LogStash::Bundler.setup!({:without => [:build, :development]})"));
    }
}