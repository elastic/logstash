package org.logstash.elastiqueue;

import com.fasterxml.jackson.core.JsonEncoding;
import com.fasterxml.jackson.core.JsonFactory;
import com.fasterxml.jackson.core.JsonGenerator;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.apache.http.HttpEntity;
import org.apache.http.client.entity.EntityBuilder;
import org.apache.http.entity.BasicHttpEntity;
import org.elasticsearch.client.Response;
import org.logstash.Event;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.time.Instant;
import java.time.ZoneOffset;
import java.time.format.DateTimeFormatter;
import java.util.*;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.atomic.AtomicLong;
import java.util.zip.GZIPOutputStream;

public class Producer {
    private final Elastiqueue elastiqueue;
    private final Topic topic;
    private final String producerId;
    private final static DateTimeFormatter dateFormatter = DateTimeFormatter.ofPattern("yyyy-MM-dd'T'HH:mmX")
            .withZone(ZoneOffset.UTC);
    private final AtomicLong writeOps;

    public Producer(Elastiqueue elastiqueue, Topic topic, String producerId) {
        this.elastiqueue = elastiqueue;
        this.topic = topic;
        this.producerId = producerId;
        this.writeOps = new AtomicLong();
    }

    public long write(Event... events) throws IOException, InterruptedException {
        try (Partition partition = topic.getWritablePartition();
             ByteArrayOutputStream baos = new ByteArrayOutputStream();
             JsonGenerator jf = new JsonFactory().createGenerator(baos, JsonEncoding.UTF8)) {

            jf.writeStartObject();

            jf.writeStringField("@timestamp", dateFormatter.format(Instant.now()));
            final long seq = partition.getSeq()+1;
            jf.writeNumberField("seq", seq);
            jf.writeNumberField("event_count", events.length);

            jf.writeBinaryField("events", gzipCompress(Event.serializeMany(events)));

            jf.writeEndObject();

            jf.close();

            while (true) {
                HttpEntity body = EntityBuilder.create().setBinary(baos.toByteArray()).build();
                String docUrl = String.format("/%s/doc/%d", partition.getIndexName(), seq);

                //System.out.println("DOC URL " + docUrl);
                Response response = elastiqueue.simpleRequest("put", docUrl, body);
                //System.out.println(writeOps.incrementAndGet());
                int code = response.getStatusLine().getStatusCode();
                //System.out.println("DOC RESP" + response.getStatusLine().getStatusCode());
                if (code != 201 && code != 200) {
                    System.out.println("CODE" + code);
                }
                if (code != 429) {
                    break;
                }
                Thread.sleep(100);
            }

            // Only set once we're done writing do we increment
            partition.setSeq(seq);

            return seq;
        }
    }

    private static byte[] gzipCompress(byte[] uncompressedData) {
        byte[] result = new byte[]{};
        try (ByteArrayOutputStream bos = new ByteArrayOutputStream(uncompressedData.length);
             GZIPOutputStream gzipOS = new GZIPOutputStream(bos)) {
            gzipOS.write(uncompressedData);
            gzipOS.close();
            result = bos.toByteArray();
        } catch (IOException e) {
            e.printStackTrace();
        }
        return result;
    }
}
