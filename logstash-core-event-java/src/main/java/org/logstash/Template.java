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
        StringBuffer results = new StringBuffer();

        for (int i = 0; i < nodes.size(); i++) {
            results.append(((TemplateNode) nodes.get(i)).evaluate(event));
        }
        return results.toString();
    }
}