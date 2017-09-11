package org.logstash;

import com.fasterxml.jackson.core.JsonGenerator;
import com.fasterxml.jackson.databind.JavaType;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.SerializerProvider;
import com.fasterxml.jackson.databind.module.SimpleModule;
import com.fasterxml.jackson.databind.ser.std.NonTypedScalarSerializerBase;
import com.fasterxml.jackson.dataformat.cbor.CBORFactory;
import com.fasterxml.jackson.dataformat.cbor.CBORGenerator;
import java.io.IOException;
import java.util.HashMap;
import org.jruby.RubyBoolean;
import org.jruby.RubyFixnum;
import org.jruby.RubyFloat;
import org.jruby.RubyString;
import org.jruby.RubySymbol;

public final class ObjectMappers {

    private static final SimpleModule RUBY_SERIALIZERS =
        new SimpleModule("RubySerializers")
            .addSerializer(RubyString.class, new RubyStringSerializer())
            .addSerializer(RubySymbol.class, new RubySymbolSerializer())
            .addSerializer(RubyFloat.class, new RubyFloatSerializer())
            .addSerializer(RubyBoolean.class, new RubyBooleanSerializer())
            .addSerializer(RubyFixnum.class, new RubyFixnumSerializer());

    public static final ObjectMapper JSON_MAPPER = 
        new ObjectMapper().registerModule(RUBY_SERIALIZERS);

    public static final ObjectMapper CBOR_MAPPER = new ObjectMapper(
        new CBORFactory().configure(CBORGenerator.Feature.WRITE_MINIMAL_INTS, false)
    ).registerModule(RUBY_SERIALIZERS);

    /**
     * {@link JavaType} for the {@link HashMap} that {@link Event} is serialized as.
     */
    public static final JavaType EVENT_MAP_TYPE =
        CBOR_MAPPER.getTypeFactory().constructMapType(HashMap.class, String.class, Object.class);

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
     * Serializer for {@link RubySymbol} since Jackson can't handle that type natively, so we
     * simply serialize it as if it were a {@link String}.
     */
    private static final class RubySymbolSerializer
        extends NonTypedScalarSerializerBase<RubySymbol> {

        RubySymbolSerializer() {
            super(RubySymbol.class, true);
        }

        @Override
        public void serialize(final RubySymbol value, final JsonGenerator generator,
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

    /**
     * Serializer for {@link RubyBoolean} since Jackson can't handle that type natively, so we
     * simply serialize it as if it were a {@code boolean}.
     */
    private static final class RubyBooleanSerializer
        extends NonTypedScalarSerializerBase<RubyBoolean> {

        RubyBooleanSerializer() {
            super(RubyBoolean.class, true);
        }

        @Override
        public void serialize(final RubyBoolean value, final JsonGenerator generator,
            final SerializerProvider provider) throws IOException {
            generator.writeBoolean(value.isTrue());
        }
    }

    /**
     * Serializer for {@link RubyFixnum} since Jackson can't handle that type natively, so we
     * simply serialize it as if it were a {@code long}.
     */
    private static final class RubyFixnumSerializer
        extends NonTypedScalarSerializerBase<RubyFixnum> {

        RubyFixnumSerializer() {
            super(RubyFixnum.class, true);
        }

        @Override
        public void serialize(final RubyFixnum value, final JsonGenerator generator,
            final SerializerProvider provider) throws IOException {
            generator.writeNumber(value.getLongValue());
        }
    }
}
