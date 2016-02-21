package com.logstash.pipeline.graph;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.JsonNodeType;
import com.fasterxml.jackson.dataformat.yaml.YAMLFactory;
import com.logstash.pipeline.Component;
import com.logstash.pipeline.ComponentProcessor;
import com.logstash.pipeline.PipelineGraph;

import java.io.IOException;
import java.util.*;

/**
 * Created by andrewvc on 2/20/16.
 */
public class ConfigFile {
    private final JsonNode graphElement;
    private final String source;
    private final JsonNode tree;
    private final Map<String, Vertex> vertices = new HashMap<>();

    private final PipelineGraph pipelineGraph;

    public static class InvalidGraphConfigFile extends Throwable {
        InvalidGraphConfigFile(String message) {
            super(message);
        }
    }

    public static ConfigFile fromString(String source, ComponentProcessor componentProcessor) throws IOException, InvalidGraphConfigFile {
        ObjectMapper mapper = new ObjectMapper(new YAMLFactory());
        JsonNode tree = mapper.readTree(source);
        return new ConfigFile(source, tree, componentProcessor);
    }

    public ConfigFile(String source, JsonNode tree, ComponentProcessor componentProcessor) throws InvalidGraphConfigFile {
        this.source = source;
        this.tree = tree;

        this.graphElement = tree.get("graph");
        buildVertices();
        connectVertices();
        this.pipelineGraph = new PipelineGraph(vertices, componentProcessor);
    }

    public PipelineGraph getPipelineGraph() {
        return pipelineGraph;
    }

    public String source() {
        return source;
    }

    public void buildVertices() throws InvalidGraphConfigFile {
        if (graphElement == null) {
            throw new InvalidGraphConfigFile("Missing vertices element in config: " + source);
        }

        // Use a for loop here since it's a little tricky with lambdas + exceptions
        for (Iterator<Map.Entry<String, JsonNode>> geFields = graphElement.fields(); geFields.hasNext();) {
            Map.Entry<String, JsonNode> e = geFields.next();

            JsonNode propsNode = e.getValue();
            String id = e.getKey();

            JsonNode componentNameNode = propsNode.get("component");
            if (componentNameNode == null) {
                throw new InvalidGraphConfigFile("Missing component declaration for: " + id);
            }
            String componentNameText = componentNameNode.asText();

            JsonNode optionsNode = propsNode.get("options");

            String optionsStr;
            if (optionsNode == null) {
                optionsStr = null;
            } else {
                optionsStr = optionsNode.toString();
            }

            Component component = new Component(id, componentNameText, optionsStr);
            vertices.put(id, new Vertex(id, component));
        }
    }

    private void connectVertices() throws InvalidGraphConfigFile {
        Iterator<Map.Entry<String, JsonNode>> geFields = graphElement.fields();
        while(geFields.hasNext()) {
            Map.Entry<String, JsonNode> field = geFields.next();
            String name = field.getKey();

            JsonNode propsNode = field.getValue();
            JsonNode toNode = propsNode.get("to");

            // blank to nodes are fine (that's a terminal node)
            if (toNode == null) {
                continue;
            } else {
                // non-array non-null nodes are a problem!
                checkNodeType(toNode, JsonNodeType.ARRAY, "The 'to' field must be a list of vertex names if specified!");
            }

            Vertex v = vertices.get(name);
            if (v == null) throw new IllegalArgumentException("Could not connect unknown vertex: " + name);

            Iterator<JsonNode> toNodeElements = toNode.elements();
            while (toNodeElements.hasNext()) {
                JsonNode toElem = toNodeElements.next();
                if (v.getComponent().getType() == Component.Type.PREDICATE) {
                    createPredicateToEdges(v, toElem);
                } else if (toElem.isTextual()) {
                    createStandardEdge(v, toElem);
                } else {
                    throw new IllegalArgumentException(("Non-textual 'out' vertex"));
                }
            };
        };
    }

    private void createStandardEdge(Vertex v, JsonNode toElem) throws InvalidGraphConfigFile {
        String toElemVertexName = toElem.asText();
        Vertex toElemVertex = vertices.get(toElemVertexName);
        if (toElemVertex == null) {
            throw new InvalidGraphConfigFile("Could not find vertex: " + toElemVertexName);
        }

        v.addOutEdge(toElemVertex);
    }

    private void createPredicateToEdges(Vertex v, JsonNode clauseNode) throws InvalidGraphConfigFile {
        checkNodeType(clauseNode, JsonNodeType.ARRAY, "Expected predicate clause to be an array!");

        Condition currentCondition;
        Iterator<JsonNode> cnElems = clauseNode.elements();

        if (!cnElems.hasNext()) {
            throw new InvalidGraphConfigFile("Expected predicate clause to have at least one element! Got: " + clauseNode);
        }

        JsonNode condElem = cnElems.next();
        checkNodeType(condElem, JsonNodeType.STRING, "Expected a textual condition element!");
        currentCondition = Condition.fromSource(condElem.asText());

        if (!cnElems.hasNext()) {
            throw new InvalidGraphConfigFile("Expected a list of vertices following the predicate clause!");
        }

        JsonNode condToElem = cnElems.next();
        checkNodeType(condToElem, JsonNodeType.ARRAY, "Predicate 'to' list must be a list of vertex names!");

        Iterator<JsonNode> condToElemNameElems = condToElem.elements();
        while(condToElemNameElems.hasNext()) {
            JsonNode condtoNameElem = condToElemNameElems.next();
            String condToVertexName = condtoNameElem.asText();
            Vertex condToVertex = vertices.get(condToVertexName);
            if (condToVertex == null) {
                throw new InvalidGraphConfigFile("Could not find vertex: " + condToVertexName);
            }
            v.addOutEdge(condToVertex, currentCondition);
        }
    }

    private void checkNodeType(JsonNode node, JsonNodeType type, String message) throws InvalidGraphConfigFile {
        JsonNodeType actualNodeType = node.getNodeType();
        if (actualNodeType != type) {
            message = String.format("%s / Expected a %s, got a %s (%s)!", message, type, actualNodeType, node.asText());
            throw new InvalidGraphConfigFile(message);
        }
    }
}
