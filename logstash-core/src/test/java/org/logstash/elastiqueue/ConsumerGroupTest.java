package org.logstash.elastiqueue;

import org.apache.http.HttpHost;
import org.junit.Test;

import java.io.IOException;

import static org.junit.Assert.*;

public class ConsumerGroupTest {
    @Test
    void testMacro() throws IOException {
        Elastiqueue elastiqueue = new Elastiqueue(HttpHost.create("http://localhost:9200"));
        Topic topic = elastiqueue.topic("test", 10);
    }

}