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
import org.jruby.RubyString;

public final class ObjectMappers {

    /**
     * We are using {@link AfterburnerModule} to improve the performance serialization performance.
     * It is important that it is registered after our custom serializers when setting up
     * {@link ObjectMappers#JSON_MAPPER} and {@link ObjectMappers#CBOR_MAPPER} to prevent it from
     * overriding them.
     */
    private static final AfterburnerModule AFTERBURNER_MODULE = new AfterburnerModule();

    private static final SimpleModule RUBY_STRING_SERIALIZER =
        new SimpleModule("RubyStringSerializer")
            .addSerializer(RubyString.class, new RubyStringSerializer())
            .addSerializer(Timestamp.class, new TimestampSerializer());

    public static final ObjectMapper JSON_MAPPER = new ObjectMapper()
        .registerModule(RUBY_STRING_SERIALIZER).registerModule(AFTERBURNER_MODULE);

    public static final ObjectMapper CBOR_MAPPER = new ObjectMapper(
        new CBORFactory().configure(CBORGenerator.Feature.WRITE_MINIMAL_INTS, false)
    ).registerModule(RUBY_STRING_SERIALIZER).registerModule(AFTERBURNER_MODULE);

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
     * Serializer for {@link Timestamp} since Jackson can't handle that type natively, so we
     * simply serialize it as if it were a {@link String} by formatting it according to ISO-8601.
     */
    private static final class TimestampSerializer extends NonTypedScalarSerializerBase<Timestamp> {

        TimestampSerializer() {
            super(Timestamp.class, true);
        }

        @Override
        public void serialize(final Timestamp value, final JsonGenerator generator,
            final SerializerProvider provider) throws IOException {
            generator.writeString(value.toString());
        }
    }
}
