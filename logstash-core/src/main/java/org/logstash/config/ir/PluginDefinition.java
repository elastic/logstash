package org.logstash.config.ir;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;

import java.util.HashSet;
import java.util.Map;
import java.util.Objects;
import java.util.Set;

/**
 * Created by andrewvc on 9/20/16.
 */
public class PluginDefinition implements SourceComponent, Hashable {
    private static ObjectMapper om = new ObjectMapper();

    @Override
    public String hashSource() {
        try {
            String serializedArgs = om.writeValueAsString(this.getArguments());
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
    public SourceMetadata getMeta() {
        return null;
    }
}
