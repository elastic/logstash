package com.logstash;

/**
 * Created by ph on 15-05-22.
 */
public class StaticNode implements TemplateNode {
    private String content;

    public StaticNode(String content) {
        this.content = content;
    }

    @Override
    public String evaluate(Event event) {
        return this.content;
    }
}