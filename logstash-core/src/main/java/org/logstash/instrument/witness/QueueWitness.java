package org.logstash.instrument.witness;

import com.fasterxml.jackson.core.JsonGenerator;
import com.fasterxml.jackson.databind.SerializerProvider;
import com.fasterxml.jackson.databind.annotation.JsonSerialize;
import com.fasterxml.jackson.databind.ser.std.StdSerializer;
import org.logstash.instrument.metrics.Metric;
import org.logstash.instrument.metrics.gauge.LongGauge;
import org.logstash.instrument.metrics.gauge.TextGauge;

import java.io.IOException;

/**
 * Witness for the queue.
 */
@JsonSerialize(using = QueueWitness.Serializer.class)
final public class QueueWitness implements SerializableWitness {

    private final TextGauge type;
    private final LongGauge events; // note this is NOT an EventsWitness
    private final Snitch snitch;
    private final CapacityWitness capacity;
    private final DataWitness data;
    private final static String KEY = "queue";
    private static final Serializer SERIALIZER = new Serializer();

    /**
     * Constructor.
     */
    public QueueWitness() {
        type = new TextGauge("type");
        events = new LongGauge("events");
        snitch = new Snitch(this);
        capacity = new CapacityWitness();
        data = new DataWitness();
    }

    /**
     * The number of events currently in the queue.
     *
     * @param count the count of events currently in the queue
     */
    public void events(long count) {
        events.set(count);
    }

    /**
     * Get the capacity witness for this queue.
     *
     * @return the associated {@link CapacityWitness}
     */
    public CapacityWitness capacity() {
        return capacity;
    }

    /**
     * Get the data witness for this queue.
     *
     * @return the associated {@link DataWitness}
     */
    public DataWitness data() {
        return data;
    }

    /**
     * Get a reference to associated snitch to get discrete metric values.
     *
     * @return the associate {@link Snitch}
     */
    public Snitch snitch() {
        return snitch;
    }

    /**
     * Sets the type of the queue.
     *
     * @param type The type of the queue.
     */
    public void type(String type) {
        this.type.set(type);
    }

    @Override
    public void genJson(JsonGenerator gen, SerializerProvider provider) throws IOException {
        SERIALIZER.innerSerialize(this, gen, provider);
    }

    /**
     * Inner witness for the queue capacity
     */
    public class CapacityWitness {

        private final LongGauge queueSizeInBytes;
        private final LongGauge pageCapacityInBytes;
        private final LongGauge maxQueueSizeInBytes;
        private final LongGauge maxUnreadEvents;
        private final Snitch snitch;
        private final static String KEY = "capacity";


        private CapacityWitness() {
            queueSizeInBytes = new LongGauge("queue_size_in_bytes");
            pageCapacityInBytes = new LongGauge("page_capacity_in_bytes");
            maxQueueSizeInBytes = new LongGauge("max_queue_size_in_bytes");
            maxUnreadEvents = new LongGauge("max_unread_events");
            snitch = new Snitch(this);
        }

        /**
         * Set the queue size for this queue, represented in bytes
         *
         * @param size the byte size of this queue
         */
        public void queueSizeInBytes(long size) {
            queueSizeInBytes.set(size);
        }

        /**
         * Set the page capacity for this queue, represented in bytes.
         *
         * @param capacity the byte capacity of this queue.
         */
        public void pageCapacityInBytes(long capacity) {
            pageCapacityInBytes.set(capacity);
        }

        /**
         * Set the max queue size, represented in bytes.
         *
         * @param max the max queue size of this queue.
         */
        public void maxQueueSizeInBytes(long max) {
            maxQueueSizeInBytes.set(max);
        }

        /**
         * Set the max unread events count.
         *
         * @param max the max unread events.
         */
        public void maxUnreadEvents(long max) {
            maxUnreadEvents.set(max);
        }

        /**
         * Get a reference to associated snitch to get discrete metric values.
         *
         * @return the associate {@link Snitch}
         */
        public Snitch snitch() {
            return snitch;
        }

        /**
         * Snitch for queue capacity. Provides discrete metric values.
         */
        public class Snitch {

            private final CapacityWitness witness;

            private Snitch(CapacityWitness witness) {
                this.witness = witness;
            }

            /**
             * Gets the queue size in bytes
             *
             * @return the queue size in bytes. May be {@code null}
             */
            public Long queueSizeInBytes() {
                return witness.queueSizeInBytes.getValue();
            }

            /**
             * Gets the page queue capacity in bytes.
             *
             * @return the page queue capacity.
             */
            public Long pageCapacityInBytes() {
                return witness.pageCapacityInBytes.getValue();
            }

            /**
             * Gets the max queue size in bytes.
             *
             * @return the max queue size.
             */
            public Long maxQueueSizeInBytes() {
                return witness.maxQueueSizeInBytes.getValue();
            }

            /**
             * Get the max unread events from this queue.
             *
             * @return the max unread events.
             */
            public Long maxUnreadEvents() {
                return witness.maxUnreadEvents.getValue();
            }

        }
    }

    /**
     * Inner witness for the queue data
     */
    public class DataWitness {

        private final TextGauge path;
        private final LongGauge freeSpaceInBytes;
        private final TextGauge storageType;
        private final Snitch snitch;
        private final static String KEY = "data";


        private DataWitness() {
            path = new TextGauge("path");
            freeSpaceInBytes = new LongGauge("free_space_in_bytes");
            storageType = new TextGauge("storage_type");
            snitch = new Snitch(this);
        }

        /**
         * Set the free space for this queue, represented in bytes
         *
         * @param space the free byte size for this queue
         */
        public void freeSpaceInBytes(long space) {
            freeSpaceInBytes.set(space);
        }

        /**
         * Set the path for this persistent queue.
         *
         * @param path the path to the persistent queue
         */
        public void path(String path) {
            this.path.set(path);
        }

        /**
         * Set the storage type for this queue.
         *
         * @param storageType the storage type for this queue.
         */
        public void storageType(String storageType) {
            this.storageType.set(storageType);
        }

        /**
         * Get a reference to associated snitch to get discrete metric values.
         *
         * @return the associate {@link Snitch}
         */
        public Snitch snitch() {
            return snitch;
        }

        /**
         * Snitch for queue capacity. Provides discrete metric values.
         */
        public class Snitch {

            private final DataWitness witness;

            private Snitch(DataWitness witness) {
                this.witness = witness;
            }

            /**
             * Gets the path of this persistent queue.
             *
             * @return the path to the persistent queue. May be {@code null}
             */
            public String path() {
                return witness.path.getValue();
            }

            /**
             * Gets the free space of the queue in bytes.
             *
             * @return the free space of the queue
             */
            public Long freeSpaceInBytes() {
                return witness.freeSpaceInBytes.getValue();
            }

            /**
             * Gets the storage type of the queue.
             *
             * @return the storage type.
             */
            public String storageType() {
                return witness.storageType.getValue();
            }
        }

    }

    /**
     * The Jackson serializer.
     */
    static class Serializer extends StdSerializer<QueueWitness> {
        /**
         * Default constructor - required for Jackson
         */
        public Serializer() {
            this(QueueWitness.class);
        }

        /**
         * Constructor
         *
         * @param t the type to serialize
         */
        protected Serializer(Class<QueueWitness> t) {
            super(t);
        }

        @Override
        public void serialize(QueueWitness witness, JsonGenerator gen, SerializerProvider provider) throws IOException {
            gen.writeStartObject();
            innerSerialize(witness, gen, provider);
            gen.writeEndObject();
        }

        void innerSerialize(QueueWitness witness, JsonGenerator gen, SerializerProvider provider) throws IOException {
            gen.writeObjectFieldStart(KEY);
            MetricSerializer<Metric<Long>> longSerializer = MetricSerializer.Get.longSerializer(gen);
            MetricSerializer<Metric<String>> stringSerializer = MetricSerializer.Get.stringSerializer(gen);
            stringSerializer.serialize(witness.type);
            if ("persisted".equals(witness.type.getValue())) {
                longSerializer.serialize(witness.events);
                //capacity
                gen.writeObjectFieldStart(CapacityWitness.KEY);
                longSerializer.serialize(witness.capacity.queueSizeInBytes);
                longSerializer.serialize(witness.capacity.pageCapacityInBytes);
                longSerializer.serialize(witness.capacity.maxQueueSizeInBytes);
                longSerializer.serialize(witness.capacity.maxUnreadEvents);
                gen.writeEndObject();
                //data
                gen.writeObjectFieldStart(DataWitness.KEY);
                stringSerializer.serialize(witness.data.path);
                longSerializer.serialize(witness.data.freeSpaceInBytes);
                stringSerializer.serialize(witness.data.storageType);
                gen.writeEndObject();
            }
            gen.writeEndObject();
        }
    }

    /**
     * Snitch for queue. Provides discrete metric values.
     */
    public class Snitch {

        private final QueueWitness witness;

        private Snitch(QueueWitness witness) {
            this.witness = witness;
        }

        /**
         * Gets the type of queue
         *
         * @return the queue type. May be {@code null}
         */
        public String type() {
            return witness.type.getValue();
        }


        /**
         * Gets the number of events currently in the queue
         *
         * @return the count of events in the queue. {@code null}
         */
        public Long events() {
            return witness.events.getValue();
        }
    }
}
