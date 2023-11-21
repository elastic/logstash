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

        // RubyBasicObjectSerializer + Log4jJsonModule
        assertTrue(list.size() > 1);

        final Serializers rubyBasicObjectSerializer = list.get(list.size() - 2);
        final JavaType valueType = TypeFactory.defaultInstance().constructType(RubyBasicObject.class);
        final JsonSerializer<?> found = rubyBasicObjectSerializer.findSerializer(mapper.getSerializationConfig(), valueType, null);

        assertNotNull(found);
        assertTrue("RubyBasicObjectSerializer must be registered before others non-default serializers", found instanceof RubyBasicObjectSerializer);
    }
}