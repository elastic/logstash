package org.logstash.elastiqueue;

import com.fasterxml.jackson.core.JsonFactory;
import com.fasterxml.jackson.core.JsonGenerator;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.apache.http.client.entity.EntityBuilder;
import org.elasticsearch.client.Response;
import org.jruby.RubyArray;
import org.jruby.RubyObject;
import org.logstash.Event;
import org.logstash.RubyUtil;
import org.logstash.ext.JrubyEventExtLibrary;

import java.io.*;
import java.util.*;
import java.util.concurrent.*;
import java.util.function.Function;
import java.util.stream.Stream;
import java.util.zip.GZIPInputStream;

public class Consumer implements AutoCloseable {
    private final Elastiqueue elastiqueue;
    private final Topic topic;
    private final String consumerId;
    private final int prefetchAmount;
    private final Thread prefetchThread;
    private final ArrayBlockingQueue<Object> prefetchWakeup;
    private final ConsumerGroup consumerGroup;
    private final List<Thread> consumerThreads;
    private volatile long offset;
    private Map<Partition,Long> partitionOffsets = new ConcurrentHashMap<>();
    private Map<String, Partition> partitionsByIndexName = new ConcurrentHashMap<>();
    private Map<Partition,Long> partitionLastPrefetchOffsets = new ConcurrentHashMap<>();
    private Map<Partition, BlockingQueue<CompressedEventsWithSeq>> topicPrefetch;
    private volatile boolean running = true;

    Consumer(Elastiqueue elastiqueue, Topic topic, String consumerGroupName, String name) throws IOException {
        this.elastiqueue = elastiqueue;
        this.topic = topic;
        this.consumerId = name;
        this.offset = 0;
        this.prefetchAmount = 10000;
        this.consumerGroup = new ConsumerGroup(topic, consumerGroupName);
        this.topicPrefetch = new HashMap<>();

        topic.getPartitions().forEach(p -> {
            topicPrefetch.put(p, new ArrayBlockingQueue<>(prefetchAmount / topic.getNumPartitions()));
            partitionOffsets.put(p, (long) 0);
            partitionLastPrefetchOffsets.put(p, (long) -1);
            partitionsByIndexName.put(p.getIndexName(), p);
        });

        this.prefetchWakeup = new ArrayBlockingQueue<>(1);

        this.prefetchThread = new Thread(new Runnable() {
            @Override
            public void run() {
                while(running) {
                    fillPrefetch();
                    try {
                        prefetchWakeup.poll(100, TimeUnit.MILLISECONDS);
                    } catch(InterruptedException ex) {
                        // Shouldn't happen
                        ex.printStackTrace();
                    }
                }
            }
        }, "Consumer Prefetcher");

        this.consumerThreads = new ArrayList<Thread>(topic.getNumPartitions());
        prefetchThread.start();
    }

    public void consumePartitions(java.util.function.Consumer<EventsWithSeq> func) {
        for (Partition p : this.partitionsByIndexName.values()) {
            Thread t = new Thread(new Runnable() {
                @Override
                public void run() {
                    BlockingQueue<CompressedEventsWithSeq> prefetchQueue = topicPrefetch.get(p);
                    while (running) {
                        try {
                            CompressedEventsWithSeq polled = prefetchQueue.poll(100, TimeUnit.MILLISECONDS);
                            if (polled != null) {
                                EventsWithSeq deserialized = polled.deserialize();
                                //System.out.println("Consumed" + deserialized.getLastSeq());
                                func.accept(deserialized);
                                deserialized.setOffset();
                            }
                        } catch (InterruptedException | IOException e) {
                            throw new RuntimeException(e);
                        }
                    }
                }
            }, "Partition Consumer " + this.topic.getName() + "/" + this.getConsumerGroup().getName() + "/" + p.getNumber());
            this.consumerThreads.add(t);
            t.start();
        }
    }

    public void rubyConsumePartitions(Function<RubyArray, RubyObject> func) {
        consumePartitions(eventsWithSeq -> func.apply(eventsWithSeq.getRubyEvents()));
    }

    public ConsumerGroup getConsumerGroup() {
        return consumerGroup;
    }

    @Override
    public void close() throws Exception {
        this.running = false;
        this.consumerGroup.close();
        this.prefetchThread.join();
        for (Thread t : this.consumerThreads) {
            t.join();
        }
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

        public String toString() {
            return "DocUrl<" + getIndexName() + "/" + getType() + "/" + getId() + ">";
        }
    }

    private void fillPrefetch() {
        Map<DocumentUrl, Partition> docsToPartitions = new HashMap<>(prefetchAmount *topic.getNumPartitions());

        Collection<Partition> partitions = topic.getPartitions();
        List<Partition> shuffled = new ArrayList<>(partitions);
        Collections.shuffle(shuffled);
        for (Partition partition : shuffled) {
            BlockingQueue<CompressedEventsWithSeq> partitionPrefetch = topicPrefetch.get(partition);
            if (!consumerGroup.isPartitionLocallyActive(partition)) {
                continue;
            }

            int neededPrefetches = prefetchAmount - partitionPrefetch.size(); // .size is slow for juc, we should count ourselves
            List<DocumentUrl> docUrls = new ArrayList<>();
            for (long i = 0; i < neededPrefetches; i++) {
                Long lastPrefetch = consumerGroup.getPrefetchOffsetFor(partition);
                //System.out.println("LASTPREFETCH" + lastPrefetch);
                long nextPrefetch = lastPrefetch + i;
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
                //System.out.println(docUrl);
                jg.writeStartObject();
                jg.writeStringField("_index", docUrl.getIndexName());
                jg.writeStringField("_type", docUrl.getType());
                jg.writeStringField("_id", docUrl.getId());
                jg.writeEndObject();
            }
            jg.writeEndArray();
            jg.close();

            Map<Partition,List<CompressedEventsWithSeq>> resultsByPartition = new HashMap<>();
            while (true) {
                Response resp = elastiqueue.simpleRequest(
                        "get",
                        "/_mget",
                        EntityBuilder.create().setBinary(baos.toByteArray()).setContentEncoding("UTF-8").build()
                );
                int responseCode = resp.getStatusLine().getStatusCode();
                if (responseCode == 200) {
                    //System.out.println("GOT 200");
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
                    //System.out.println("FOUND DOCS" + docs.stream().filter(d -> d.containsKey("_source")).count());
                    foundDocs.forEach(doc -> {
                        Event[] events;
                        String index = (String) doc.get("_index");
                        Partition partition = partitionsByIndexName.get(index);
                        Long seq = Long.valueOf((String) doc.get("_id"));
                        Map<String,Object> source = (Map<String, Object>) doc.get("_source");
                        String eventsEncoded = (String) source.get("events");
                        byte[] compressedEvents = decoder.decode(eventsEncoded);

                        resultsByPartition.computeIfAbsent(partition, k -> new LinkedList<>());
                        //System.out.println("ADD DOC" + seq);
                        resultsByPartition.get(partition).add(new CompressedEventsWithSeq(partition, seq, compressedEvents));
                    });

                    for (Map.Entry<Partition, List<CompressedEventsWithSeq>> entry : resultsByPartition.entrySet()) {
                        Partition partition = entry.getKey();
                        List<CompressedEventsWithSeq> cewsList = entry.getValue();
                        cewsList.sort(Comparator.comparingLong(o -> o.seq));
                        BlockingQueue<CompressedEventsWithSeq> partitionPrefetch = topicPrefetch.get(partition);
                        long fetchLastSeq = -1L;
                        for (CompressedEventsWithSeq cews : cewsList) {
                            if ((fetchLastSeq == -1L) || (cews.seq == (fetchLastSeq + 1))) {
                                fetchLastSeq = cews.seq;
                                partitionPrefetch.put(cews);
                                System.out.println("PREFETCH" + partition + cews.seq);
                                consumerGroup.setPrefetchOffsetFor(partition, cews.seq);
                            } else {
                                System.err.println("OUT OF ORDER PREFETCH");
                                // We are out of order, read from an out of sync replica? We'll refetch
                                break;
                            }
                        }
                    }
                    break;
                } else if (responseCode != 429) {
                    break;
                }
            }
        } catch (IOException e) {
            throw new RuntimeException(e);
        } catch (InterruptedException e) {
            throw new RuntimeException(e);
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

        public RubyArray getRubyEvents() {
            RubyArray arr = RubyArray.newArray(RubyUtil.RUBY, events.length);
            for (Event e : events) {
                JrubyEventExtLibrary.RubyEvent re = JrubyEventExtLibrary.RubyEvent.newRubyEvent(RubyUtil.RUBY, e);
                arr.add(re);
            }
            return arr;
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
        private final long seq;
        private final Partition partition;

        CompressedEventsWithSeq(Partition partition, long seq, byte[] compressedEvents) {
            this.partition = partition;
            this.seq = seq;
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
                return new EventsWithSeq(partition, seq, Event.deserializeMany(baos.toByteArray()));
            }
        }
    }
}
