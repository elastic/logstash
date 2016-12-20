package org.logstash.ackedqueue;

import java.io.IOException;

public interface Queueable {

    byte[] serialize() throws IOException;

    static Object deserialize(byte[] bytes) { throw new RuntimeException("please implement deserialize"); };
}
