package org.logstash.plugin;

import org.jruby.Ruby;
import org.jruby.RubyModule;
import org.jruby.RubyObject;
import org.jruby.embed.ScriptingContainer;
import org.junit.Before;
import org.junit.Test;
import org.logstash.Event;

import java.io.IOException;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.Arrays;
import java.util.Map;

import static org.junit.Assert.assertEquals;

public class RubyProcessorTest {
    private ScriptingContainer container = new ScriptingContainer();
    private Ruby ruby = container.getProvider().getRuntime();

    @Before
    public void setup() throws IOException {
        Path root = Paths.get("..").toRealPath();

        // Setup the load path.
        // XXX: I did this before with ScriptContainer.getLoadPath + setLoadPath but it wasn't working correctly...
        // XXX: So I choose to modify $: instead.
        Object loadPath = container.runScriptlet("$:");
        container.callMethod(loadPath, "<<", root.resolve("lib").toString());
        container.callMethod(loadPath, "<<", root.resolve("logstash-core/lib").toString());
        container.callMethod(loadPath, "<<", root.resolve("logstash-core/src/test/resources/org/logstash/plugin/lib/").toString());

        Map env = container.getEnvironment();
        env.put("GEM_HOME", root.resolve("vendor/bundle/jruby/2.3.0").toString());
        env.put("GEM_PATH", root.resolve("vendor/bundle/jruby/2.3.0").toString());
        env.put("GEM_SPEC_CACHE", root.resolve("vendor/bundle/jruby/2.3.0/specifications").toString());
        container.setEnvironment(env);

        RubyModule kernel = ruby.getKernel();
        container.runScriptlet("p :pwd => Dir.pwd");
        container.callMethod(kernel, "require", "bootstrap/environment");
        container.runScriptlet("LogStash::Bundler.setup!({:without => [:build, :development]})");
        container.callMethod(kernel, "require", "logstash/plugin");
    }

    @Test
    public void testRubyFilter() throws IOException {
        RubyObject plugin = (RubyObject) container.runScriptlet("LogStash::Plugin.lookup('filter', 'test').new({}).tap(&:register)");
        RubyProcessor processor = new RubyProcessor(plugin);

        ProcessorBatch batch = new BatchImpl(Arrays.asList(new Event()));
        processor.process(batch);

        for (Event event : batch) {
            assertEquals(1L, event.getField("test"));
        }

    }
}