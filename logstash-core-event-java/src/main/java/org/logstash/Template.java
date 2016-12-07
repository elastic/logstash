package org.logstash;

import java.io.IOException;
import java.util.ArrayList;
import java.util.List;

public class Template implements TemplateNode {
    public List nodes = new ArrayList<>();
    public Template() {}

    public void add(TemplateNode node) {
        nodes.add(node);
    }

    public int size() {
        return nodes.size();
    }

    public TemplateNode get(int index) {
        return (TemplateNode) nodes.get(index);
    }

    @Override
    public String evaluate(Event event) throws IOException {
        String nodeResult;
        StringBuffer results = new StringBuffer();

        for (int i = 0; i < nodes.size(); i++) {
            nodeResult = ((TemplateNode) nodes.get(i)).evaluate(event);
            if (nodeResult == null) {
                return null; // if one node fails to evaluate, abort everything
            } else {
                results.append(nodeResult);
            }
        }
        return results.toString();
    }
}