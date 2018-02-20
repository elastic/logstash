package org.logstash.elastiqueue;

import com.fasterxml.jackson.annotation.JsonGetter;
import com.fasterxml.jackson.annotation.JsonIgnore;
import com.fasterxml.jackson.annotation.JsonProperty;
import com.fasterxml.jackson.core.JsonFactory;
import com.fasterxml.jackson.core.JsonGenerator;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.elasticsearch.client.Response;
import org.elasticsearch.client.ResponseException;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.util.Collections;
import java.util.HashMap;
import java.util.Map;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;

public class ConsumerGroup implements AutoCloseable {
    private static ObjectMapper objectMapper = new ObjectMapper();

    private final long instantiatedAt;
    private final Thread partitionStateKeeper;
    private Topic topic;
    private final Elastiqueue elastiqueue;
    private final String name;
    private final Map<Partition, ConsumerGroupPartitionState> partitionStates;
    private final Map<Partition, Long> partitionStatesInternalClock = new ConcurrentHashMap<>();
    private final String consumerUUID;
    private volatile boolean shutdown = false;

    ConsumerGroup(Topic topic, String name) throws IOException {
        this.topic = topic;
        this.elastiqueue = topic.getElastiqueue();
        this.name = name;
        this.instantiatedAt = System.currentTimeMillis();
        this.consumerUUID = UUID.randomUUID().toString();
        ensureDocument();

        this.partitionStates = new HashMap<>();
        for (Partition partition : topic.getPartitions()) {
            ConsumerGroupPartitionState partitionState = new ConsumerGroupPartitionState(this, partition);
            partitionStates.put(partition, partitionState);
            partitionStatesInternalClock.put(partition, partitionState.getClock());
        }

        this.partitionStateKeeper = new Thread(() -> {
            while (!shutdown) {
                try {
                    Thread.sleep(1000);

                    for (Map.Entry<Partition, ConsumerGroupPartitionState> entry : partitionStates.entrySet()) {
                        Partition partition = entry.getKey();
                        ConsumerGroupPartitionState partitionState = entry.getValue();

                        partitionState.refresh();

                        Long internalClock = partitionStatesInternalClock.get(partition);
                        internalClock += 1;

                        // If already owned and in use
                        if (partitionState.getConsumerUUID().equals(this.getConsumerUUID())) {
                            if (partitionState.getTakeoverClock() != null && partitionState.getTakeoverClock() > 0 && partitionState.getTakeoverClock() < internalClock) {
                                System.out.println("Relinquishing control!" + partitionState);
                                partitionState.relinquishControl();
                            } else {
                                partitionState.updateRemote();
                            }
                        } else {
                            Long partClock = partitionState.getClock();
                            System.out.println("Internal clock compare" +  partClock + " | " + internalClock);
                            if (partClock == null || internalClock > (partClock + 10L)) {
                                System.out.println("Taking over!" + partitionState);
                                partitionState.executeTakeover();
                            }
                        }

                        partitionStatesInternalClock.put(partition, internalClock);
                    }
                } catch (InterruptedException e) {
                    e.printStackTrace();
                } catch (IOException e) {
                    e.printStackTrace();
                }
            }
        }, "Partition State Keeper " + this);
        this.partitionStateKeeper.start();
    }

    public String toString() {
        return "ConsumerGroup(" + this.getTopicName() + this.getName() + ")";
    }

    @JsonGetter("topic")
    public String getTopicName() {
        return this.topic.getName();
    }

    @JsonGetter("name")
    public String getName() {
        return this.name;
    }

    private void ensureDocument() throws IOException {
        //String body = objectMapper.writeValueAsString(newGroup);
        ConsumerGroup.ConsumerGroupDoc wrapped = new ConsumerGroup.ConsumerGroupDoc(this);
        String body = objectMapper.writeValueAsString(wrapped);
        // what if the create fails?
        try {
            Response createResp = elastiqueue.simpleRequest(
                    "post",
                    "/" + url() + "/_create",
                    body
            );
        } catch (ResponseException re) {
            // Not an error!
            if (re.getResponse().getStatusLine().getStatusCode() == 409) return;
            //throw new IOException(re);
        }
    }

    private String url() {
        return topic.getMetadataIndexName() + "/doc/consumer_group_" + this.name;
    }

    @JsonGetter("created_at")
    public long instantiatedAt() {
        return instantiatedAt;
    }

    public Topic getTopic() {
        return topic;
    }

    public String getConsumerUUID() {
        return consumerUUID;
    }

    @Override
    public void close() throws Exception {
        this.shutdown = true;
        this.partitionStateKeeper.join();
    }

    public void setOffset(Partition partition, long lastSeq) {
        this.partitionStates.get(partition).setOffset(lastSeq);
    }

    public boolean isPartitionLocallyActive(Partition partition) {
        return this.partitionStates.get(partition).isLocallyActive();
    }

    public Long getPrefetchOffsetFor(Partition partition) {
        return this.partitionStates.get(partition).getPrefetchOffset();
    }

    public void setPrefetchOffsetFor(Partition partition, Long offset) {
        this.partitionStates.get(partition).setPrefetchOffset(offset);
    }

    static class ConsumerGroupPartitionState {
        @JsonIgnore
        private final ConsumerGroup consumerGroup;
        private final Partition partition;
        private final String url;
        private String consumerUUID;
        @JsonIgnore
        private String consumerName;
        private volatile Long offset = -1L;
        @JsonIgnore
        private volatile Long prefetchOffset;
        private Long clock = 0L;
        private Long consumerLastUpdate = System.currentTimeMillis();
        private Long takeoverClock = null;
        private String takeoverBy;
        private Elastiqueue elastiqueue;

        public String getConsumerName() {
            return consumerName;
        }

        public void setConsumerName(String consumerName) {
            this.consumerName = consumerName;
        }

        ConsumerGroupPartitionState(ConsumerGroup group, Partition partition) throws IOException {
            this.consumerGroup = group;
            this.partition = partition;
            this.consumerName = consumerGroup.getName();
            this.consumerUUID = consumerGroup.getConsumerUUID();
            this.clock = 0L;
            this.url = consumerGroup.getTopic().getMetadataIndexName() +
                    "/doc/consumer_group_partition_" +
                    getPartitionNumber();

            ensureDocumentExists();
            refresh();
            stateTakeoverIntent();
        }

        public String toString() {
            String base =  "PartitionState(" + this.getPartitionNumber() + "@" + " " +
                    this.getOffset() + ") " +
                    this.consumerName + "<" + this.consumerUUID + "> ";

            if (this.takeoverBy != null) {
                return base + " TAKEOVER " +
                this.takeoverBy + "<" + this.takeoverClock + "> ";
            } else {
                return base;
            }
        }

        public void refresh() throws IOException {
            Response resp = elastiqueue.simpleRequest("GET", "/" + url + "/_source");
            Map<String, Map<String, Object>> deserialized = objectMapper.readValue(resp.getEntity().getContent(), HashMap.class);
            Map<String, Object> fields = deserialized.get("consumer_group_partition");
            this.consumerName = (String) fields.get("consumer_name");
            this.consumerUUID = (String) fields.get("consumer_uuid");

            // The authoritative offset is local in this case, ot remote
            if (!this.isLocallyActive()) {
                this.offset = fields.get("offset") != null ? ((Number) fields.get("offset")).longValue() : null;
                this.prefetchOffset = null;
                System.out.println("Not locally active, syncing offset" + this);
            } else {
                if (this.prefetchOffset == null) {
                    this.prefetchOffset = this.offset;
                }
            }

            this.clock = fields.get("clock") != null ? ((Number) fields.get("clock")).longValue() : null;
            this.consumerLastUpdate = fields.get("consumer_last_update") != null ? ((Number) fields.get("consumer_last_update")).longValue() : null;
            this.takeoverClock = fields.get("takeover_clock") != null ? ((Number) fields.get("takeover_clock")).longValue() : null;
            this.takeoverBy = (String) fields.get("takeover_uuid");
        }

        public void executeScript(String script) throws IOException {
            executeScript(script, null);
        }

        public void executeScript(String script, Map<String, Object> argParams) throws IOException {
            Map<String, Object> params = new HashMap<>();
            params.put("consumer_uuid", this.consumerGroup.getConsumerUUID());
            params.put("consumer_name", this.consumerGroup.getConsumerUUID());

            if (argParams != null) {
                params.putAll(argParams);
            }

            JsonFactory jsonFactory = new JsonFactory();
            byte[] requestSource;
            try (
                ByteArrayOutputStream baos = new ByteArrayOutputStream();
                JsonGenerator jsonGenerator = jsonFactory.createGenerator(baos);
            ) {
                jsonGenerator.writeStartObject();

                // Open script
                jsonGenerator.writeObjectFieldStart("script");

                jsonGenerator.writeStringField("source", script);
                jsonGenerator.writeStringField("lang", "painless");
                jsonGenerator.writeFieldName("params");
                objectMapper.writeValue(jsonGenerator, params);

                // Close script
                jsonGenerator.writeEndObject();

                // Close outer object
                jsonGenerator.writeEndObject();

                jsonGenerator.close();
                requestSource = baos.toByteArray();
            }
            String s = new String(requestSource);
            //System.out.println("Execute Script " + s);
            elastiqueue.simpleRequest("POST", "/" + url + "/_update", requestSource);
        }

        public void updateRemote() throws IOException {
            String script = "if (ctx._source.consumer_group_partition.consumer_uuid == params.consumer_uuid) { " +
                        "  ctx._source.consumer_group_partition.clock += 1; " +
                        "  ctx._source.consumer_group_partition.offset = params.offset; " +
                        "}";

            executeScript(script, Collections.singletonMap("offset", consumerGroup.partitionStates.get(partition).getOffset()));
        }

        public void stateTakeoverIntent() throws IOException {
           String script = "if (ctx._source.consumer_group_partition.consumer_uuid != params.consumer_uuid) { " +
                        "  ctx._source.consumer_group_partition.takeover_uuid = params.consumer_uuid; " +
                        "  ctx._source.consumer_group_partition.takeover_name = params.consumer_name; " +
                        "  ctx._source.consumer_group_partition.takeover_clock = ctx._source.consumer_group_partition.clock + 10L; " +
                        "}";

           executeScript(script);
        }

        public void executeTakeover() throws IOException {
            String script = "if (ctx._source.consumer_group_partition.consumer_uuid != params.consumer_uuid) {" +
                                // If this consumer is registered to takeover and the clock has counted up the original should be dead
                                "if ( ctx._source.consumer_group_partition.takeover_uuid == params.consumer_uuid) {" +
                                "  ctx._source.consumer_group_partition.consumer_uuid = params.consumer_uuid; " +
                                "  ctx._source.consumer_group_partition.consumer_name = params.consumer_name; " +
                                "  ctx._source.consumer_group_partition.takeover_uuid = null; " +
                                "  ctx._source.consumer_group_partition.takeover_name = null; " +
                                "  ctx._source.consumer_group_partition.takeover_clock = null; " +
                                // stake takeover intent if the consumer staging registered to execute the attempt has failed
                                "} else {" +
                                "  ctx._source.consumer_group_partition.takeover_uuid = params.consumer_uuid; " +
                                "  ctx._source.consumer_group_partition.takeover_name = params.consumer_name; " +
                                "  ctx._source.consumer_group_partition.takeover_clock = ctx._source.consumer_group_partition.clock + 10L; " +
                                "}" +
                            "}";
            executeScript(script);
        }

        public void relinquishControl() throws IOException {
            String script = "if (ctx._source.consumer_group_partition.takeover_uuid != null) {" +
                                "  ctx._source.consumer_group_partition.consumer_uuid = ctx._source.consumer_group_partition.takeover_uuid; " +
                                "  ctx._source.consumer_group_partition.consumer_name = ctx._source.consumer_group_partition.takeover_name; " +
                                "  ctx._source.consumer_group_partition.takeover_uuid = null; " +
                                "  ctx._source.consumer_group_partition.takeover_name = null; " +
                            "}";
            executeScript(script);
        }

        private void ensureDocumentExists() throws IOException {
            ConsumerGroupPartitionStateDoc wrapped = new ConsumerGroupPartitionStateDoc(this);
            this.elastiqueue = consumerGroup.getTopic().getElastiqueue();
            String json = objectMapper.writeValueAsString(wrapped);
            try {
                elastiqueue.simpleRequest("POST", "/" + url + "/_create", json);
            } catch (ResponseException e) {
                if (e.getResponse().getStatusLine().getStatusCode() == 409) return;
                throw e;
            }

        }


        @JsonGetter("topic")
        public String getTopicName() {
            return consumerGroup.getTopicName();
        }

        @JsonGetter("partition")
        public int getPartitionNumber() {
            return partition.getNumber();
        }

        @JsonGetter("consumer_group")
        public String getConsumerGroupName() {
            return consumerGroup.getName();
        }

        @JsonProperty("consumer_uuid")
        public String getConsumerUUID() {
            return this.consumerUUID;
        }

        @JsonProperty("consumer_uuid")
        public void setConsumerUUID(String consumerUUID) {
            this.consumerUUID = consumerUUID;
        }

        public ConsumerGroup getConsumerGroup() {
            return consumerGroup;
        }

        @JsonProperty("offset")
        public Long getOffset() {
            return offset;
        }

        @JsonProperty("offset")
        public void setOffset(long consumerOffset) {
            this.offset = consumerOffset;
        }

        @JsonProperty("clock")
        public Long getClock() {
            return clock;
        }

        @JsonProperty("clock")
        public void setClock(long clock) {
            this.clock = clock;
        }

        @JsonProperty("consumer_last_update")
        public Long getConsumerLastUpdate() {
            return consumerLastUpdate;
        }

        @JsonProperty("consumer_last_update")
        public void setConsumerLastUpdate(long consumerLastUpdate) {
            this.consumerLastUpdate = consumerLastUpdate;
        }

        @JsonProperty("takeover_clock")
        public Long getTakeoverClock() {
            return takeoverClock;
        }

        @JsonProperty("takeover_clock")
        public void setTakeoverClock(long takeoverClock) {
            this.takeoverClock = takeoverClock;
        }

        @JsonProperty("takeover_uuid")
        public String getTakeoverBy() {
            return takeoverBy;
        }

        @JsonProperty("takeover_uuid")
        public void setTakeoverBy(String takeoverBy) {
            this.takeoverBy = takeoverBy;
        }

        public boolean isLocallyActive() {
            return this.consumerUUID.equals(consumerGroup.consumerUUID);
        }

        public Long getPrefetchOffset() {
            return prefetchOffset;
        }

        public void setPrefetchOffset(Long prefetchOffset) {
            this.prefetchOffset = prefetchOffset;
        }


        public static class ConsumerGroupPartitionStateDoc {
            @JsonProperty("consumer_group_partition")
            public ConsumerGroupPartitionState consumerGroupPartitionState;

            ConsumerGroupPartitionStateDoc(ConsumerGroupPartitionState consumerGroupPartitionState) {
                this.consumerGroupPartitionState = consumerGroupPartitionState;
            }
        }
    }

    public static class ConsumerGroupDoc {
        @JsonProperty("consumer_group")
        public ConsumerGroup consumerGroup;

        ConsumerGroupDoc(ConsumerGroup consumerGroup) {
            this.consumerGroup = consumerGroup;
        }
    }
}
