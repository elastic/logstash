package org.logstash.ackedqueue;

import java.util.function.Function;

/**
 * In its simplest form a {@code BoxedQueueable} is a box around a {@link Queueable},
 * which can be useful for passing a mixture of live references and to-be-deserialized
 * byte arrays. it is an internal implementation detail of the acked queue.
 */
interface BoxedQueueable {
    Queueable unbox();

    static BoxedQueueable fromLiveReference(final Queueable queueable) {
        return new LiveReference(queueable);
    }

    static BoxedQueueable fromSerializedBytes(final byte[] bytes, Function<byte[], Queueable> deserializer) {
        return new SerializedBytes(bytes, deserializer);
    }

    /**
     * A {@code BoxedQueueable.LiveReference} is an implementation of {@link BoxedQueueable} that
     * wraps a live object
     */
    class LiveReference implements BoxedQueueable {
        private final Queueable boxed;

        public LiveReference(Queueable boxed) {
            this.boxed = boxed;
        }

        @Override
        public Queueable unbox() {
            return this.boxed;
        }
    }

    /**
     * A {@code BoxedQueueable.SerializedBytes} is an implementation of {@link BoxedQueueable} that
     * wraps bytes and a deserializer
     */
    class SerializedBytes implements BoxedQueueable {
        private final byte[] bytes;
        private final Function<byte[], Queueable> deserializer;

        public SerializedBytes(byte[] bytes, Function<byte[], Queueable> deserializer) {
            this.bytes = bytes;
            this.deserializer = deserializer;
        }

        @Override
        public Queueable unbox() {
            return deserializer.apply(bytes);
        }
    }
}
