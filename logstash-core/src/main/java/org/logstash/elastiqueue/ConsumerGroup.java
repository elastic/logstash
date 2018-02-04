package org.logstash.elastiqueue;

import com.fasterxml.jackson.annotation.JsonGetter;
import com.fasterxml.jackson.annotation.JsonIgnore;
import com.fasterxml.jackson.annotation.JsonProperty;
import com.fasterxml.jackson.core.JsonFactory;
import com.fasterxml.jackson.core.JsonGenerator;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.annotation.JsonDeserialize;
import org.elasticsearch.client.Response;
import org.elasticsearch.client.ResponseException;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.util.HashMap;
import java.util.Map;
import java.util.UUID;

public class ConsumerGroup implements AutoCloseable {
    private static ObjectMapper objectMapper = new ObjectMapper();

    private final long instantiatedAt;
    private final Thread partitionStateKeeper;
    private Topic topic;
    private final Elastiqueue elastiqueue;
    private final String name;
    private final Map<Partition, ConsumerGroupPartitionState> partitionStates;
    private final Map<Partition, Long> partitionStatesInternalClock = new HashMap<>();
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
                            if (partitionState.getTakeoverClock() > internalClock) {
                                partitionState.relinquishControl();
                            }
                        } else {
                            if (internalClock > (partitionState.getClock() + 10L)) {
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
                    url() + "/_create",
                    body
            );
        } catch (ResponseException re) {
            // Not an error!
            if (re.getResponse().getStatusLine().getStatusCode() == 409) return;
            throw new IOException(re);
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

    static class ConsumerGroupPartitionState {
        @JsonIgnore
        private final ConsumerGroup consumerGroup;
        private final Partition partition;
        private final String url;
        private String consumerUUID;
        @JsonIgnore
        private String consumerName;
        private long consumerOffset;
        private long clock = 0;
        private long consumerLastUpdate = System.currentTimeMillis();
        private long takeoverClock = -1;
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
            takeover();
        }

        public void refresh() throws IOException {
            Response resp = elastiqueue.simpleRequest("GET", url + "/_source");
            Map<String, Map<String, Object>> deserialized = objectMapper.readValue(resp.getEntity().getContent(), HashMap.class);
            Map<String, Object> fields = deserialized.get("consumer_group_partition");
            this.consumerName = (String) fields.get("consumer_name");
            this.consumerUUID = (String) fields.get("consumer_uuid");
            this.consumerOffset = ((Number) fields.get("consumer_offset")).longValue();
            this.clock = ((Number) fields.get("clock")).longValue();
            this.consumerLastUpdate = ((Number) fields.get("consumer_last_update")).longValue();
            this.takeoverClock = ((Number) fields.get("takeover_clock")).longValue();
            this.takeoverBy = (String) fields.get("takeover_by");
        }

        public void takeover() throws IOException {
            JsonFactory jsonFactory = new JsonFactory();
            byte[] requestSource;
            try (
                ByteArrayOutputStream baos = new ByteArrayOutputStream();
                JsonGenerator jsonGenerator = jsonFactory.createGenerator(baos);
            ) {
                jsonGenerator.writeStartObject();
                jsonGenerator.writeObjectFieldStart("script");
                String script = "if (ctx._source.consumer_group_partition.consumer_uuid != params.consumer_uuid) { " +
                        "  ctx._source.consumer_group_partition.takeover_by = params.consumer_uuid; " +
                        "  ctx._source.consumer_group_partition.takeover_clock += 10L; " +
                        "}";
                jsonGenerator.writeStringField("source", script);
                jsonGenerator.writeStringField("lang", "painless");
                jsonGenerator.writeObjectFieldStart("params");
                jsonGenerator.writeStringField("consumer_uuid", this.consumerGroup.consumerUUID);
                jsonGenerator.writeEndObject();
                jsonGenerator.writeEndObject();
                jsonGenerator.close();
                requestSource = baos.toByteArray();
            }
            String s = new String(requestSource);
            System.out.println("HELLO" + s);
            elastiqueue.simpleRequest("POST", url + "/_update", requestSource);
        }


        private void ensureDocumentExists() throws IOException {
            ConsumerGroupPartitionStateDoc wrapped = new ConsumerGroupPartitionStateDoc(this);
            this.elastiqueue = consumerGroup.getTopic().getElastiqueue();
            String json = objectMapper.writeValueAsString(wrapped);
            try {
                elastiqueue.simpleRequest("POST", url + "/_create", json);
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

        @JsonProperty("consumer_offset")
        public long getConsumerOffset() {
            return consumerOffset;
        }

        @JsonProperty("consumer_offset")
        public void setConsumerOffset(long consumerOffset) {
            this.consumerOffset = consumerOffset;
        }

        @JsonProperty("clock")
        public long getClock() {
            return clock;
        }

        @JsonProperty("clock")
        public void setClock(long clock) {
            this.clock = clock;
        }

        @JsonProperty("consumer_last_update")
        public long getConsumerLastUpdate() {
            return consumerLastUpdate;
        }

        @JsonProperty("consumer_last_update")
        public void setConsumerLastUpdate(long consumerLastUpdate) {
            this.consumerLastUpdate = consumerLastUpdate;
        }

        @JsonProperty("takeover_clock")
        public long getTakeoverClock() {
            return takeoverClock;
        }

        @JsonProperty("takeover_clock")
        public void setTakeoverClock(long takeoverClock) {
            this.takeoverClock = takeoverClock;
        }

        @JsonProperty("takeover_by")
        public String getTakeoverBy() {
            return takeoverBy;
        }

        @JsonProperty("takeover_by")
        public void setTakeoverBy(String takeoverBy) {
            this.takeoverBy = takeoverBy;
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
