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


package org.logstash.config.ir;

import com.fasterxml.jackson.core.JsonProcessingException;
import java.util.HashSet;
import java.util.Map;
import java.util.Objects;
import java.util.Set;
import org.logstash.ObjectMappers;
import org.logstash.common.SourceWithMetadata;

public final class PluginDefinition implements SourceComponent, HashableWithSource {

    @Override
    public String hashSource() {
        try {
            String serializedArgs =
                ObjectMappers.JSON_MAPPER.writeValueAsString(this.getArguments());
            return this.getClass().getCanonicalName() + "|" +
                    this.getType().toString() + "|" +
                    this.getName() + "|" +
                   serializedArgs;
        } catch (JsonProcessingException e) {
            throw new IllegalArgumentException("Could not serialize plugin args as JSON", e);
        }
    }

    public enum Type {
        INPUT,
        FILTER,
        OUTPUT,
        CODEC
    }

    private final Type type;
    private final String name;
    private final Map<String,Object> arguments;

    public Type getType() {
        return type;
    }

    public String getName() {
        return name;
    }

    public Map<String, Object> getArguments() {
        return arguments;
    }

    public PluginDefinition(Type type, String name, Map<String, Object> arguments) {
        this.type = type;
        this.name = name;
        this.arguments = arguments;
    }

    public String toString() {
        return type.toString().toLowerCase() + "-" + name + arguments;
    }

    public int hashCode() {
        return Objects.hash(type, name, arguments);
    }

    @Override
    public boolean equals(Object o) {
        if (o == null) return false;
        if (o instanceof PluginDefinition) {
            PluginDefinition oPlugin = (PluginDefinition) o;
            return type.equals(oPlugin.type) && name.equals(oPlugin.name) && arguments.equals(oPlugin.arguments);
        }
        return false;
    }

    @Override
    public boolean sourceComponentEquals(SourceComponent o) {
        if (o == null) return false;
        if (o instanceof PluginDefinition) {
            PluginDefinition oPluginDefinition = (PluginDefinition) o;

            Set<String> allArgs = new HashSet<>();
            allArgs.addAll(getArguments().keySet());
            allArgs.addAll(oPluginDefinition.getArguments().keySet());

            // Compare all arguments except the unique id
            boolean argsMatch = allArgs.stream().
                    filter(k -> !k.equals("id")).
                    allMatch(k -> Objects.equals(getArguments().get(k), oPluginDefinition.getArguments().get(k)));


            return argsMatch && type.equals(oPluginDefinition.type) && name.equals(oPluginDefinition.name);
        }
        return false;
    }

    @Override
    public SourceWithMetadata getSourceWithMetadata() {
        return null;
    }
}
