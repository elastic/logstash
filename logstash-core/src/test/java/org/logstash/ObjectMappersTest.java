package org.logstash;

import com.fasterxml.jackson.databind.JavaType;
import com.fasterxml.jackson.databind.JsonSerializer;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.ser.BeanSerializerFactory;
import com.fasterxml.jackson.databind.ser.Serializers;
import com.fasterxml.jackson.databind.type.TypeFactory;
import org.jruby.RubyBasicObject;
import org.junit.Test;
import org.logstash.log.RubyBasicObjectSerializer;

import java.util.LinkedList;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatCode;
import static org.junit.Assert.assertNotNull;
import static org.junit.Assert.assertTrue;
import static org.logstash.ObjectMappers.RUBY_BASIC_OBJECT_SERIALIZERS_MODULE_ID;
import static org.logstash.ObjectMappers.RUBY_SERIALIZERS_MODULE_ID;

public class ObjectMappersTest {

    @Test
    public void testLog4jOMRegisterRubySerializersModule() {
        assertTrue(ObjectMappers.LOG4J_JSON_MAPPER.getRegisteredModuleIds().contains(RUBY_SERIALIZERS_MODULE_ID));
    }

    @Test
    public void testLog4jOMRegisterRubyBasicObjectSerializersModule() {
        assertTrue(ObjectMappers.LOG4J_JSON_MAPPER.getRegisteredModuleIds().contains(RUBY_BASIC_OBJECT_SERIALIZERS_MODULE_ID));
    }

    @Test
    public void testLog4jOMRegisterRubyBasicObjectSerializersFirst() {
        final ObjectMapper mapper = ObjectMappers.LOG4J_JSON_MAPPER;
        final BeanSerializerFactory factory = (BeanSerializerFactory) mapper.getSerializerFactory();

        final LinkedList<Serializers> list = new LinkedList<>();
        for (Serializers serializer : factory.getFactoryConfig().serializers()) {
            list.add(serializer);
        }

        // RubyBasicObjectSerializer + Log4jJsonModule + potentially other modules
        assertTrue(list.size() > 1);

        // Find the RubyBasicObjectSerializer among the registered serializers
        final JavaType valueType = TypeFactory.defaultInstance().constructType(RubyBasicObject.class);
        JsonSerializer<?> found = null;
        for (Serializers serializer : list) {
            JsonSerializer<?> candidate = serializer.findSerializer(mapper.getSerializationConfig(), valueType, null);
            if (candidate instanceof RubyBasicObjectSerializer) {
                found = candidate;
                break;
            }
        }

        assertNotNull("RubyBasicObjectSerializer must be registered", found);
        assertTrue("RubyBasicObjectSerializer must be registered", found instanceof RubyBasicObjectSerializer);
    }

    @Test
    public void testStreamReadConstraintsGlobalDefaults() {
        // if the statically-initialized stream read constraints are NOT the global default, then the
        // subsequently-initialized mappers themselves will not necessarily have the configured constraints.
        assertThatCode(ObjectMappers.CONFIGURED_STREAM_READ_CONSTRAINTS::validateIsGlobalDefault).doesNotThrowAnyException();
    }

    @Test
    public void testStreamReadConstraintsAppliedToCBORMapper() {
        assertThat(ObjectMappers.CBOR_MAPPER.getFactory().streamReadConstraints())
                .satisfies(ObjectMappers.CONFIGURED_STREAM_READ_CONSTRAINTS::validate);
    }

    @Test
    public void testStreamReadConstraintsAppliedToJSONMapper() {
        assertThat(ObjectMappers.JSON_MAPPER.getFactory().streamReadConstraints())
                .satisfies(ObjectMappers.CONFIGURED_STREAM_READ_CONSTRAINTS::validate);
    }
}