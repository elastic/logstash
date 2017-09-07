package org.logstash.plugin;

import org.jruby.Ruby;
import org.jruby.RubyClass;
import org.jruby.RubyHash;
import org.jruby.RubyModule;
import org.jruby.embed.ScriptingContainer;
import org.jruby.runtime.Block;
import org.jruby.runtime.builtin.IRubyObject;
import org.junit.Before;
import org.junit.Test;
import org.logstash.Event;

import java.io.IOException;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.Arrays;
import java.util.Collection;
import java.util.Map;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertTrue;

public class RubyProcessorTest {
    private ScriptingContainer container = new ScriptingContainer();
    private Ruby ruby = container.getProvider().getRuntime();

    static {
        //setupRuby();
    }

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
        container.callMethod(kernel, "require", "bootstrap/environment");
        long n = System.nanoTime();
        container.runScriptlet("LogStash::Bundler.setup!({:without => [:build, :development]})");
        System.out.println("Bundler setup took: " + (System.nanoTime() - n) / 1000000 + "ms");
        container.callMethod(kernel, "require", "logstash/plugin");
    }

    private IRubyObject plugin(String type, String name, Map<String, Object> config) {
        RubyHash hash = new RubyHash(ruby);
        if (config != null) {
            hash.putAll(config);
        }
        RubyClass pluginClass = (RubyClass) container.runScriptlet("LogStash::Plugin.lookup('filter', 'test')");
        IRubyObject plugin = pluginClass.newInstance(ruby.getCurrentContext(), hash, Block.NULL_BLOCK);
        plugin.callMethod(ruby.getCurrentContext(), "register");

        return plugin;
    }

    @Test
    public void testRubyFilter() throws IOException {
        IRubyObject plugin = plugin("filter", "test", null);

        RubyProcessor processor = new RubyProcessor(plugin);

        Collection<Event> events = Arrays.asList(new Event());
        Collection<Event> newEvents = processor.process(events);

        for (Event event : events) {
            assertEquals(1L, event.getField("test"));
        }

        assertTrue("The test filter should return null and not create any additional events", newEvents.isEmpty());
    }
}