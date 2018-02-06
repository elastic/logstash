package org.logstash.elastiqueue;

import com.fasterxml.jackson.core.JsonFactory;
import com.fasterxml.jackson.core.JsonGenerator;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.apache.http.client.entity.EntityBuilder;
import org.elasticsearch.client.Response;
import org.logstash.Event;

import java.io.*;
import java.util.*;
import java.util.concurrent.ArrayBlockingQueue;
import java.util.concurrent.BlockingQueue;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.TimeUnit;
import java.util.stream.Stream;
import java.util.zip.GZIPInputStream;

public class Consumer {
    private final Elastiqueue elastiqueue;
    private final Topic topic;
    private final String consumerId;
    private final int prefetchAmount;
    private final Thread prefetchThread;
    private final ArrayBlockingQueue<Object> prefetchWakeup;
    private final ConsumerGroup consumerGroup;
    private volatile long offset;
    private Map<Partition,Long> partitionOffsets = new ConcurrentHashMap<>();
    private Map<String, Partition> partitionsByIndexName = new ConcurrentHashMap<>();
    private Map<Partition,Long> partitionLastPrefetchOffsets = new ConcurrentHashMap<>();
    private BlockingQueue<CompressedEventsWithSeq> topicPrefetch;

    Consumer(Elastiqueue elastiqueue, Topic topic, String consumerGroupName, String name) throws IOException {
        this.elastiqueue = elastiqueue;
        this.topic = topic;
        this.consumerId = name;
        this.offset = 0;
        this.prefetchAmount = 50;
        this.consumerGroup = new ConsumerGroup(topic, consumerGroupName);

        topic.getPartitions().forEach(p -> {
            topicPrefetch = new ArrayBlockingQueue<>(prefetchAmount*2);
            partitionOffsets.put(p, (long) 0);
            partitionLastPrefetchOffsets.put(p, (long) -1);
            partitionsByIndexName.put(p.getIndexName(), p);
        });

        this.prefetchWakeup = new ArrayBlockingQueue<>(1);

        this.prefetchThread = new Thread(new Runnable() {
            @Override
            public void run() {
                while(true) {
                    fillPrefetch();
                    try {
                        prefetchWakeup.poll(1000, TimeUnit.MILLISECONDS);
                    } catch(InterruptedException ex) {
                        // Shouldn't happen
                        ex.printStackTrace();
                    }
                }
            }
        }, "Consumer Prefetcher");
        prefetchThread.start();
    }

    public EventsWithSeq poll(int timeout) throws InterruptedException, IOException {
        prefetchWakeup.offer(new Object());
        CompressedEventsWithSeq compressedEvents = topicPrefetch.poll(timeout, TimeUnit.MILLISECONDS);
        if (compressedEvents != null) {
            return compressedEvents.deserialize();
        } else {
            return null;
        }
    }

    public ConsumerGroup getConsumerGroup() {
        return consumerGroup;
    }

    private class DocumentUrl {
        private final String indexName;
        private final String id;

        public DocumentUrl(String indexName, String id) {
            this.indexName = indexName;
            this.id = id;
        }

        public String getIndexName() {
            return indexName;
        }

        public String getType() {
            return "doc";
        }

        public String getId() {
            return id;
        }
    }

    private void fillPrefetch() {
        Map<DocumentUrl, Partition> docsToPartitions = new HashMap<>(prefetchAmount *topic.getNumPartitions());

        Collection<Partition> partitions = topic.getPartitions();
        List<Partition> shuffled = new ArrayList<>(partitions);
        Collections.shuffle(shuffled);
        for (Partition partition : shuffled) {
            if (!consumerGroup.isPartitionLocallyActive(partition)) {
                continue;
            }

            int neededPrefetches = prefetchAmount - topicPrefetch.size(); // .size is slow for juc, we should count ourselves
            List<DocumentUrl> docUrls = new ArrayList<>();
            for (long i = 0; i < neededPrefetches; i++) {
                Long lastPrefetch = consumerGroup.getPrefetchOffsetFor(partition);
                //System.out.println("LASTPREFETCH" + lastPrefetch);
                long nextPrefetch = lastPrefetch + i + 1;
                DocumentUrl docUrl = new DocumentUrl(partition.getIndexName(), Long.toString(nextPrefetch));
                docUrls.add(docUrl);
            }

            if (docUrls.isEmpty()) {
                continue;
            }

            prefetchDocumentUrls(docUrls);
        }
    }

    static ConcurrentHashMap<String, Long> seenSeqs = new ConcurrentHashMap<>();

    public void prefetchDocumentUrls(List<DocumentUrl> docUrls) {
        try(ByteArrayOutputStream baos = new ByteArrayOutputStream()) {
            JsonGenerator jg = new JsonFactory().createGenerator(baos);
            jg.writeStartObject();
            jg.writeFieldName("docs");
            jg.writeStartArray();
            for (DocumentUrl docUrl : docUrls) {
                jg.writeStartObject();
                jg.writeStringField("_index", docUrl.getIndexName());
                jg.writeStringField("_type", docUrl.getType());
                jg.writeStringField("_id", docUrl.getId());
                jg.writeEndObject();
            }
            jg.writeEndArray();
            jg.close();


            while (true) {
                Response resp = elastiqueue.simpleRequest(
                        "get",
                        "/_mget",
                        EntityBuilder.create().setBinary(baos.toByteArray()).setContentEncoding("UTF-8").build()
                );
                int responseCode = resp.getStatusLine().getStatusCode();
                if (responseCode == 200) {
                    InputStream is = resp.getEntity().getContent();
                    ObjectMapper om = new ObjectMapper();
                    HashMap<String,Object> parsed = om.readValue(is, HashMap.class);
                    List<Map<String, Object>> docs = (List) parsed.get("docs");
                    Stream<Map<String, Object>> foundDocs = docs.stream().
                            filter(d -> d.containsKey("_source"));
                    // We can't just assume that we can advance the reader because there could be a gap
                    // in the prefetch. For this stage we can ignore this, but this isn't prod quality
                    // we need to check we prefetched without gaps before advancing an offset
                    Base64.Decoder decoder = Base64.getDecoder();
                    //Ordered so we update the seqs monotonically later
                    foundDocs.forEach(doc -> {
                        Event[] events;
                        String index = (String) doc.get("_index");
                        Partition partition = partitionsByIndexName.get(index);
                        Long seq = Long.valueOf((String) doc.get("_id"));
                        Map<String,Object> source = (Map<String, Object>) doc.get("_source");
                        String eventsEncoded = (String) source.get("events");
                        byte[] compressedEvents = decoder.decode(eventsEncoded);

                        consumerGroup.setPrefetchOffsetFor(partition, seq);
                        try {
                            topicPrefetch.put(new CompressedEventsWithSeq(partition, seq, compressedEvents));
                        } catch (InterruptedException e) {
                            throw new RuntimeException(e);
                        }
                    });
                    break;
                } else if (responseCode != 429) {
                    break;
                }
            }

            //System.out.println(baos.toString("UTF-8"));
        } catch (IOException e) {
            // Never happens
            e.printStackTrace();
        }
    }


    private static byte[] gzipUncompress(byte[] compressedData) {
        byte[] result = new byte[]{};
        try (ByteArrayInputStream bis = new ByteArrayInputStream(compressedData);
             ByteArrayOutputStream bos = new ByteArrayOutputStream();
             GZIPInputStream gzipIS = new GZIPInputStream(bis)) {
            byte[] buffer = new byte[1024];
            int len;
            while ((len = gzipIS.read(buffer)) != -1) {
                bos.write(buffer, 0, len);
            }
            result = bos.toByteArray();
        } catch (IOException e) {
            e.printStackTrace();
        }
        return result;
    }

    public class EventsWithSeq {
        private final Partition partition;
        private final long lastSeq;
        private final Event[] events;

        EventsWithSeq(Partition partition, long lastSeq, Event[] events) {
            this.partition = partition;
            this.lastSeq = lastSeq;
            this.events = events;
        }

        public long getLastSeq() {
            return lastSeq;
        }

        public Event[] getEvents() {
            return events;
        }

        public void setOffset() {
            consumerGroup.setOffset(partition, lastSeq);
        }

        public Partition getPartition() {
            return partition;
        }
    }

    private class CompressedEventsWithSeq {
        private final byte[] compressedEvents;
        private final long lastSeq;
        private final Partition partition;

        CompressedEventsWithSeq(Partition partition, long lastSeq, byte[] compressedEvents) {
            this.partition = partition;
            this.lastSeq = lastSeq;
            this.compressedEvents = compressedEvents;
        }

        public EventsWithSeq deserialize() throws IOException {
            try (ByteArrayInputStream bis = new ByteArrayInputStream(compressedEvents);
                 ByteArrayOutputStream baos = new ByteArrayOutputStream();
                 GZIPInputStream gzipIS = new GZIPInputStream(bis)) {
                byte[] buffer = new byte[1024];
                int len;
                while ((len = gzipIS.read(buffer)) != -1) {
                    baos.write(buffer, 0, len);
                }
                bis.close();
                return new EventsWithSeq(partition, lastSeq, Event.deserializeMany(baos.toByteArray()));
            }
        }
    }
}
