package org.logstash;

import com.fasterxml.jackson.core.JsonGenerator;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.SerializerProvider;
import com.fasterxml.jackson.databind.module.SimpleModule;
import com.fasterxml.jackson.databind.ser.std.NonTypedScalarSerializerBase;
import com.fasterxml.jackson.dataformat.cbor.CBORFactory;
import com.fasterxml.jackson.dataformat.cbor.CBORGenerator;
import com.fasterxml.jackson.module.afterburner.AfterburnerModule;
import java.io.IOException;
import org.jruby.RubyFloat;
import org.jruby.RubyString;

public final class ObjectMappers {

    private static final SimpleModule RUBY_SERIALIZERS =
        new SimpleModule("RubyStringSerializer")
            .addSerializer(RubyString.class, new RubyStringSerializer())
            .addSerializer(RubyFloat.class, new RubyFloatSerializer());

    public static final ObjectMapper JSON_MAPPER = new ObjectMapper()
        .registerModule(new AfterburnerModule()).registerModule(RUBY_SERIALIZERS);

    public static final ObjectMapper CBOR_MAPPER = new ObjectMapper(
        new CBORFactory().configure(CBORGenerator.Feature.WRITE_MINIMAL_INTS, false)
    ).registerModule(new AfterburnerModule()).registerModule(RUBY_SERIALIZERS);

    private ObjectMappers() {
    }

    /**
     * Serializer for {@link RubyString} since Jackson can't handle that type natively, so we
     * simply serialize it as if it were a {@link String}.
     */
    private static final class RubyStringSerializer
        extends NonTypedScalarSerializerBase<RubyString> {

        RubyStringSerializer() {
            super(RubyString.class, true);
        }

        @Override
        public void serialize(final RubyString value, final JsonGenerator generator,
            final SerializerProvider provider)
            throws IOException {
            generator.writeString(value.asJavaString());
        }
    }

    /**
     * Serializer for {@link RubyFloat} since Jackson can't handle that type natively, so we
     * simply serialize it as if it were a {@code double}.
     */
    private static final class RubyFloatSerializer
        extends NonTypedScalarSerializerBase<RubyFloat> {

        RubyFloatSerializer() {
            super(RubyFloat.class, true);
        }

        @Override
        public void serialize(final RubyFloat value, final JsonGenerator generator,
            final SerializerProvider provider) throws IOException {
            generator.writeNumber(value.getDoubleValue());
        }
    }
}
