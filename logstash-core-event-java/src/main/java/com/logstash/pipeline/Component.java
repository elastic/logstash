package com.logstash.pipeline;

/**
 * Created by andrewvc on 2/22/16.
 */
public class Component {
    public enum Type { INPUT, QUEUE, FILTER, OUTPUT, PREDICATE }

    private final Type type;
    private final String id;
    private final String componentName;
    private final String optionsStr;

    public Component(String id, String componentName, String optionsStr) {
        this.id = id;
        this.componentName = componentName;
        this.type = extractTypeFromComponentName(componentName);
        this.optionsStr = optionsStr;
    }

    private Type extractTypeFromComponentName(String componentName) {
        String[] componentParts = componentName.split("-", 2);
        return Type.valueOf(componentParts[0].toUpperCase());
    }

    public Type getType() {
        return type;
    }

    public String getId() {
        return id;
    }

    public String getComponentName() {
        return componentName;
    }

    public String getOptionsStr() { return optionsStr; }

    public String toString() {
        return this.getId();
    }
}
