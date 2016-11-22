package org.logstash.config.ir;

import java.util.HashSet;
import java.util.Map;
import java.util.Objects;
import java.util.Set;

/**
 * Created by andrewvc on 9/20/16.
 */
public class PluginDefinition implements ISourceComponent {
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

    public String getId() {
        return (String) arguments.get("id");
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
    public boolean sourceComponentEquals(ISourceComponent o) {
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
