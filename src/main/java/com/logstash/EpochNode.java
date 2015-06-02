package com.logstash;

/**
 * Created by ph on 15-05-22.
 */
public class EpochNode implements TemplateNode {
    public EpochNode(){ }

    @Override
    public String evaluate(Event event) {
        // TODO: Change this for the right call
        Long epoch = 1L;
        return String.valueOf(epoch);
    }
}