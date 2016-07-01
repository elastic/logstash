package org.logstash.ackedqueue;

public class ElementFactory {

    public static Queueable deserialize(byte[] bytes) {
        return StringElement.deserialize(bytes);
    }
}
