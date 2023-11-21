/*
 * Licensed to Elasticsearch B.V. under one or more contributor
 * license agreements. See the NOTICE file distributed with
 * this work for additional information regarding copyright
 * ownership. Elasticsearch B.V. licenses this file to you under
 * the Apache License, Version 2.0 (the "License"); you may
 * not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *	http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */

package org.logstash.log;

import com.fasterxml.jackson.core.JsonGenerator;
import com.fasterxml.jackson.databind.JsonMappingException;
import com.fasterxml.jackson.databind.JsonSerializer;
import com.fasterxml.jackson.databind.SerializerProvider;
import com.fasterxml.jackson.databind.ser.std.StdSerializer;
import com.fasterxml.jackson.databind.util.ClassUtil;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.jruby.RubyBasicObject;
import org.jruby.RubyMethod;
import org.jruby.RubyString;
import org.jruby.exceptions.NameError;
import org.logstash.RubyUtil;

import java.io.IOException;
import java.util.Optional;

/**
 * Default serializer for {@link org.jruby.RubyBasicObject} since Jackson can't handle that type natively.
 * Arrays, Collections and Maps are delegated to the default Jackson's serializer - which might end-up invoking this
 * serializer for its elements.
 * Values which inspect method is implemented and owned by the LogStash module will be serialized using this method return.
 * If none of the above conditions match, it gets the serialized value by invoking the Ruby's {@code to_s} method, falling back
 * to {@link RubyBasicObject#to_s()}  and {@link RubyBasicObject#anyToString()} in case of errors.
 */
public final class RubyBasicObjectSerializer extends StdSerializer<RubyBasicObject> {

    private static final long serialVersionUID = -5557562960691452054L;
    private static final Logger LOGGER = LogManager.getLogger(RubyBasicObjectSerializer.class);
    private static final String METHOD_INSPECT = "inspect";
    private static final String METHOD_TO_STRING = "to_s";

    public RubyBasicObjectSerializer() {
        super(RubyBasicObject.class);
    }

    @Override
    public void serialize(final RubyBasicObject value, final JsonGenerator gen, final SerializerProvider provider) throws IOException {
        final Optional<JsonSerializer<Object>> serializer = findTypeSerializer(value, provider);
        if (serializer.isPresent()) {
            try {
                serializer.get().serialize(value, gen, provider);
                return;
            } catch (IOException e) {
                LOGGER.debug("Failed to serialize value type {} using default serializer {}", value.getClass(), serializer.get().getClass(), e);
            }
        }

        if (isCustomInspectMethodDefined(value)) {
            try {
                gen.writeString(value.callMethod(METHOD_INSPECT).asJavaString());
                return;
            } catch (Exception e) {
                LOGGER.debug("Failed to serialize value type {} using the custom `inspect` method", value.getMetaClass(), e);
            }
        }

        try {
            gen.writeString(value.callMethod(METHOD_TO_STRING).asJavaString());
            return;
        } catch (Exception e) {
            LOGGER.debug("Failed to serialize value type {} using `to_s` method", value.getMetaClass(), e);
        }

        try {
            gen.writeString(value.to_s().asJavaString());
        } catch (Exception e) {
            LOGGER.debug("Failed to serialize value type {} using `RubyBasicObject#to_s()` method", value.getMetaClass(), e);
            gen.writeString(value.anyToString().asJavaString());
        }
    }

    private Optional<JsonSerializer<Object>> findTypeSerializer(final RubyBasicObject value, final SerializerProvider provider) {
        if (ClassUtil.isCollectionMapOrArray(value.getClass())) {
            try {
                // Delegates the serialization to the Jackson's default serializers, which might
                // end up using this serializer for its elements.
                return Optional.ofNullable(provider.findTypedValueSerializer(value.getJavaClass(), false, null));
            } catch (JsonMappingException e) {
                // Ignored
            }
        }

        return Optional.empty();
    }

    private boolean isCustomInspectMethodDefined(final RubyBasicObject value) {
        try {
            final Object candidate = value.method(RubyString.newString(RubyUtil.RUBY, METHOD_INSPECT));
            return candidate instanceof RubyMethod && ((RubyMethod) candidate).owner(RubyUtil.RUBY.getCurrentContext()).toString().toLowerCase().startsWith("logstash");
        } catch (NameError e) {
            return false;
        }
    }
}
