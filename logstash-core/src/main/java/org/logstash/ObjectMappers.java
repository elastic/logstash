package org.logstash;

import com.fasterxml.jackson.core.JsonGenerator;
import com.fasterxml.jackson.core.JsonParser;
import com.fasterxml.jackson.core.JsonToken;
import com.fasterxml.jackson.core.type.WritableTypeId;
import com.fasterxml.jackson.databind.DeserializationContext;
import com.fasterxml.jackson.databind.JavaType;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.SerializerProvider;
import com.fasterxml.jackson.databind.deser.std.StdDeserializer;
import com.fasterxml.jackson.databind.jsontype.TypeSerializer;
import com.fasterxml.jackson.databind.module.SimpleModule;
import com.fasterxml.jackson.databind.ser.std.StdScalarSerializer;
import com.fasterxml.jackson.databind.ser.std.StdSerializer;
import com.fasterxml.jackson.dataformat.cbor.CBORFactory;
import com.fasterxml.jackson.dataformat.cbor.CBORGenerator;
import java.io.IOException;
import java.math.BigDecimal;
import java.math.BigInteger;
import java.util.HashMap;
import org.jruby.RubyBignum;
import org.jruby.RubyBoolean;
import org.jruby.RubyFixnum;
import org.jruby.RubyFloat;
import org.jruby.RubyNil;
import org.jruby.RubyString;
import org.jruby.RubySymbol;
import org.jruby.ext.bigdecimal.RubyBigDecimal;
import org.logstash.ext.JrubyTimestampExtLibrary;

public final class ObjectMappers {

    private static final SimpleModule RUBY_SERIALIZERS =
        new SimpleModule("RubySerializers")
            .addSerializer(RubyString.class, new RubyStringSerializer())
            .addSerializer(RubySymbol.class, new RubySymbolSerializer())
            .addSerializer(RubyFloat.class, new RubyFloatSerializer())
            .addSerializer(RubyBoolean.class, new RubyBooleanSerializer())
            .addSerializer(RubyFixnum.class, new RubyFixnumSerializer())
            .addSerializer(RubyBigDecimal.class, new RubyBigDecimalSerializer())
            .addSerializer(RubyBignum.class, new RubyBignumSerializer())
            .addSerializer(RubyNil.class, new RubyNilSerializer());

    private static final SimpleModule CBOR_DESERIALIZERS =
        new SimpleModule("CborRubyDeserializers")
            .addDeserializer(RubyString.class, new RubyStringDeserializer())
            .addDeserializer(RubyNil.class, new RubyNilDeserializer());

    public static final ObjectMapper JSON_MAPPER =
        new ObjectMapper().registerModule(RUBY_SERIALIZERS);

    public static final ObjectMapper CBOR_MAPPER = new ObjectMapper(
        new CBORFactory().configure(CBORGenerator.Feature.WRITE_MINIMAL_INTS, false)
    ).registerModules(RUBY_SERIALIZERS, CBOR_DESERIALIZERS)
        .enableDefaultTyping(ObjectMapper.DefaultTyping.NON_FINAL);

    /**
     * {@link JavaType} for the {@link HashMap} that {@link Event} is serialized as.
     */
    public static final JavaType EVENT_MAP_TYPE =
        CBOR_MAPPER.getTypeFactory().constructMapType(HashMap.class, String.class, Object.class);

    private ObjectMappers() {
    }

    /**
     * Serializer for scalar types that does not write type information when called via
     * {@link ObjectMappers.NonTypedScalarSerializer#serializeWithType(Object, JsonGenerator, SerializerProvider, TypeSerializer)}.
     * @param <T> Scalar Type
     */
    private abstract static class NonTypedScalarSerializer<T> extends StdScalarSerializer<T> {

        NonTypedScalarSerializer(final Class<T> t) {
            super(t);
        }

        @Override
        public final void serializeWithType(final T value, final JsonGenerator gen,
            final SerializerProvider provider, final TypeSerializer typeSer) throws IOException {
            serialize(value, gen, provider);
        }
    }

    /**
     * Serializer for {@link RubyString} since Jackson can't handle that type natively, so we
     * simply serialize it as if it were a {@link String}.
     */
    private static final class RubyStringSerializer extends StdSerializer<RubyString> {

        RubyStringSerializer() {
            super(RubyString.class);
        }

        @Override
        public void serialize(final RubyString value, final JsonGenerator generator,
            final SerializerProvider provider)
            throws IOException {
            generator.writeString(value.asJavaString());
        }

        @Override
        public void serializeWithType(final RubyString value, final JsonGenerator jgen,
            final SerializerProvider serializers, final TypeSerializer typeSer) throws IOException {
            final WritableTypeId typeId =
                typeSer.typeId(value, RubyString.class, JsonToken.VALUE_STRING);
            typeSer.writeTypePrefix(jgen, typeId);
            jgen.writeString(value.asJavaString());
            typeSer.writeTypeSuffix(jgen, typeId);
        }
    }

    public static final class RubyStringDeserializer extends StdDeserializer<RubyString> {

        RubyStringDeserializer() {
            super(RubyString.class);
        }

        @Override
        public RubyString deserialize(final JsonParser p, final DeserializationContext ctxt)
            throws IOException {
            return RubyString.newString(RubyUtil.RUBY, p.getValueAsString());
        }
    }

    /**
     * Serializer for {@link RubySymbol} since Jackson can't handle that type natively, so we
     * simply serialize it as if it were a {@link String}.
     */
    private static final class RubySymbolSerializer
        extends ObjectMappers.NonTypedScalarSerializer<RubySymbol> {

        RubySymbolSerializer() {
            super(RubySymbol.class);
        }

        @Override
        public void serialize(final RubySymbol value, final JsonGenerator generator,
            final SerializerProvider provider) throws IOException {
            generator.writeString(value.asJavaString());
        }
    }

    /**
     * Serializer for {@link RubyFloat} since Jackson can't handle that type natively, so we
     * simply serialize it as if it were a {@code double}.
     */
    private static final class RubyFloatSerializer
        extends ObjectMappers.NonTypedScalarSerializer<RubyFloat> {

        RubyFloatSerializer() {
            super(RubyFloat.class);
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
        extends ObjectMappers.NonTypedScalarSerializer<RubyBoolean> {

        RubyBooleanSerializer() {
            super(RubyBoolean.class);
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
        extends ObjectMappers.NonTypedScalarSerializer<RubyFixnum> {

        RubyFixnumSerializer() {
            super(RubyFixnum.class);
        }

        @Override
        public void serialize(final RubyFixnum value, final JsonGenerator generator,
            final SerializerProvider provider) throws IOException {
            generator.writeNumber(value.getLongValue());
        }
    }

    /**
     * Serializer for {@link Timestamp} since Jackson can't handle that type natively, so we
     * simply serialize it as if it were a {@code String} and wrap it in type arguments, so that
     * deserialization happens via {@link ObjectMappers.TimestampDeserializer}.
     */
    public static final class TimestampSerializer extends StdSerializer<Timestamp> {

        TimestampSerializer() {
            super(Timestamp.class);
        }

        @Override
        public void serialize(final Timestamp value, final JsonGenerator jgen,
            final SerializerProvider provider) throws IOException {
            jgen.writeString(value.toString());
        }

        @Override
        public void serializeWithType(final Timestamp value, final JsonGenerator jgen,
            final SerializerProvider serializers, final TypeSerializer typeSer) throws IOException {
            final WritableTypeId typeId =
                typeSer.typeId(value, Timestamp.class, JsonToken.VALUE_STRING);
            typeSer.writeTypePrefix(jgen, typeId);
            jgen.writeString(value.toString());
            typeSer.writeTypeSuffix(jgen, typeId);
        }
    }

    public static final class TimestampDeserializer extends StdDeserializer<Timestamp> {

        TimestampDeserializer() {
            super(Timestamp.class);
        }

        @Override
        public Timestamp deserialize(final JsonParser p, final DeserializationContext ctxt)
            throws IOException {
            return new Timestamp(p.getText());
        }
    }

    /**
     * Serializer for {@link RubyBignum} since Jackson can't handle that type natively, so we
     * simply serialize it as if it were a {@link BigInteger}.
     */
    private static final class RubyBignumSerializer
        extends ObjectMappers.NonTypedScalarSerializer<RubyBignum> {

        RubyBignumSerializer() {
            super(RubyBignum.class);
        }

        @Override
        public void serialize(final RubyBignum value, final JsonGenerator jgen,
            final SerializerProvider provider) throws IOException {
            jgen.writeNumber(value.getBigIntegerValue());
        }
    }

    /**
     * Serializer for {@link BigDecimal} since Jackson can't handle that type natively, so we
     * simply serialize it as if it were a {@link BigDecimal}.
     */
    private static final class RubyBigDecimalSerializer
        extends ObjectMappers.NonTypedScalarSerializer<RubyBigDecimal> {

        RubyBigDecimalSerializer() {
            super(RubyBigDecimal.class);
        }

        @Override
        public void serialize(final RubyBigDecimal value, final JsonGenerator jgen,
            final SerializerProvider provider) throws IOException {
            jgen.writeNumber(value.getBigDecimalValue());
        }
    }

    /**
     * Serializer for {@link JrubyTimestampExtLibrary.RubyTimestamp} that serializes it exactly the
     * same way {@link ObjectMappers.TimestampSerializer} serializes
     * {@link Timestamp} to ensure consistent serialization across Java and Ruby
     * representation of {@link Timestamp}.
     */
    public static final class RubyTimestampSerializer
        extends StdSerializer<JrubyTimestampExtLibrary.RubyTimestamp> {

        RubyTimestampSerializer() {
            super(JrubyTimestampExtLibrary.RubyTimestamp.class);
        }

        @Override
        public void serialize(final JrubyTimestampExtLibrary.RubyTimestamp value,
            final JsonGenerator jgen, final SerializerProvider provider) throws IOException {
            jgen.writeString(value.getTimestamp().toString());
        }

        @Override
        public void serializeWithType(final JrubyTimestampExtLibrary.RubyTimestamp value,
            final JsonGenerator jgen, final SerializerProvider serializers,
            final TypeSerializer typeSer)
            throws IOException {
            final WritableTypeId typeId =
                typeSer.typeId(value, Timestamp.class, JsonToken.VALUE_STRING);
            typeSer.writeTypePrefix(jgen, typeId);
            jgen.writeObject(value.getTimestamp());
            typeSer.writeTypeSuffix(jgen, typeId);
        }
    }

    /**
     * Serializer for {@link RubyNil} that serializes it to as an empty {@link String} for JSON
     * serialization and as a typed {@link RubyNil} for CBOR.
     */
    private static final class RubyNilSerializer extends StdSerializer<RubyNil> {

        RubyNilSerializer() {
            super(RubyNil.class);
        }

        @Override
        public void serialize(final RubyNil value, final JsonGenerator jgen,
            final SerializerProvider provider) throws IOException {
            jgen.writeNull();
        }

        @Override
        public void serializeWithType(final RubyNil value, final JsonGenerator jgen,
            final SerializerProvider serializers, final TypeSerializer typeSer) throws IOException {
            final WritableTypeId typeId =
                typeSer.typeId(value, RubyNil.class, JsonToken.VALUE_NULL);
            typeSer.writeTypePrefix(jgen, typeId);
            jgen.writeNull();
            typeSer.writeTypeSuffix(jgen, typeId);
        }
    }

    private static final class RubyNilDeserializer extends StdDeserializer<RubyNil> {

        RubyNilDeserializer() {
            super(RubyNil.class);
        }

        @Override
        public RubyNil deserialize(final JsonParser p, final DeserializationContext ctxt) {
            return (RubyNil) RubyUtil.RUBY.getNil();
        }
    }
}
