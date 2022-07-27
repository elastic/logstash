package org.logstash.plugins.factory;

import co.elastic.logstash.api.Codec;
import co.elastic.logstash.api.Event;
import co.elastic.logstash.api.PluginConfigSpec;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.jruby.RubyArray;
import org.jruby.RubyClass;
import org.jruby.RubyString;
import org.jruby.runtime.Block;
import org.jruby.runtime.JavaInternalBlockBody;
import org.jruby.runtime.Signature;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;
import org.logstash.RubyUtil;
import org.logstash.ext.JrubyEventExtLibrary;

import java.io.IOException;
import java.io.OutputStream;
import java.nio.ByteBuffer;
import java.nio.charset.StandardCharsets;
import java.util.Collection;
import java.util.Map;
import java.util.function.Consumer;

public class RubyCodecDelegator implements Codec {

    private static final Logger LOGGER = LogManager.getLogger(RubyCodecDelegator.class);

    private final ThreadContext currentContext;
    private final IRubyObject pluginInstance;
    private final String wrappingId;

    public RubyCodecDelegator(ThreadContext currentContext, IRubyObject pluginInstance) {
        this.currentContext = currentContext;
        this.pluginInstance = pluginInstance;

        verifyCodecAncestry(pluginInstance);
        invokeRubyRegister(currentContext, pluginInstance);

        wrappingId = "jw-" + wrappedPluginId();
    }

    private String wrappedPluginId() {
        RubyString id = (RubyString) pluginInstance.callMethod(this.currentContext, "id");
        return id.toString();
    }

    private static void verifyCodecAncestry(IRubyObject pluginInstance) {
        if (!isRubyCodecSubclass(pluginInstance)) {
            throw new IllegalStateException("Ruby wrapped codec is expected to subclass LogStash::Codecs::Base");
        }
    }

    public static boolean isRubyCodecSubclass(IRubyObject pluginInstance) {
        final RubyClass codecBaseClass = RubyUtil.RUBY.getModule("LogStash").getModule("Codecs").getClass("Base");
        return pluginInstance.getType().hasModuleInHierarchy(codecBaseClass);
    }

    private void invokeRubyRegister(ThreadContext currentContext, IRubyObject pluginInstance) {
        pluginInstance.callMethod(currentContext, "register");
    }

    @Override
    public void decode(ByteBuffer buffer, Consumer<Map<String, Object>> eventConsumer) {
        // invoke Ruby's codec #decode(data, block) and use a Block to capture the yielded LogStash::Event to
        // back to Java and pass to the eventConsumer.
        if (buffer.remaining() == 0) {
            // no data to decode
            return;
        }

        // setup the block callback bridge to invoke eventConsumer
        final Block consumerWrapper = new Block(new JavaInternalBlockBody(currentContext.runtime, Signature.ONE_ARGUMENT) {
            @Override
            @SuppressWarnings("unchecked")
            public IRubyObject yield(ThreadContext context, IRubyObject[] args) {
                // Expect only one argument, the LogStash::Event instantiated by the Ruby codec
                final IRubyObject event = args[0];
                eventConsumer.accept( ((JrubyEventExtLibrary.RubyEvent) event).getEvent().getData() );
                return event;
            }
        });

        byte[] byteInput = new byte[buffer.remaining()];
        buffer.get(byteInput);
        final RubyString data = RubyUtil.RUBY.newString(new String(byteInput));
        IRubyObject[] methodParams = new IRubyObject[]{data};
        pluginInstance.callMethod(this.currentContext, "decode", methodParams, consumerWrapper);
    }

    @Override
    public void flush(ByteBuffer buffer, Consumer<Map<String, Object>> eventConsumer) {
        decode(buffer, eventConsumer);
    }

    @Override
    @SuppressWarnings({"uncheked", "rawtypes"})
    public void encode(Event event, OutputStream output) throws IOException {
        // convert co.elastic.logstash.api.Event to JrubyEventExtLibrary.RubyEvent
        if (!(event instanceof org.logstash.Event)) {
            throw new IllegalStateException("The object to encode must be of type org.logstash.Event");
        }

        final JrubyEventExtLibrary.RubyEvent rubyEvent = JrubyEventExtLibrary.RubyEvent.newRubyEvent(currentContext.runtime, (org.logstash.Event) event);
        final RubyArray param = RubyArray.newArray(currentContext.runtime, rubyEvent);
        final RubyArray encoded = (RubyArray) pluginInstance.callMethod(this.currentContext, "multi_encode", param);

        // method return an nested array, the outer contains just one element
        // while the inner contains the original event and encoded event in form of String
        final RubyString result = ((RubyArray) encoded.eltInternal(0)).eltInternal(1).convertToString();
        output.write(result.getByteList().getUnsafeBytes(), result.getByteList().getBegin(), result.getByteList().getRealSize());
    }

    @Override
    public Codec cloneCodec() {
        return new RubyCodecDelegator(this.currentContext, this.pluginInstance);
    }

    @Override
    public Collection<PluginConfigSpec<?>> configSchema() {
        // this method is invoked only for real java codecs, the one that are configured
        // in pipeline config that needs configuration validation. In this case the validation
        // is already done on the Ruby codec.
        return null;
    }

    @Override
    public String getId() {
        return wrappingId;
    }
}
