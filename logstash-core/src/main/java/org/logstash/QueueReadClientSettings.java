package org.logstash;

import java.util.ArrayList;
import java.util.List;
import java.util.function.Consumer;

public record QueueReadClientSettings(
        int batchSize,
        int batchDelay
) {

    public QueueReadClientSettings {
        final List<String> errors = new ArrayList<>();

        if (batchSize <= 0) {
            errors.add("batchSize must be greater than 0");
        }
        if (batchDelay <= 0) {
            errors.add("batchDelay must be greater than 0");
        }

        if (!errors.isEmpty()) {
            throw new RuntimeException(String.format("Invalid settings: %s", errors));
        }
    }

    public static QueueReadClientSettings build(Consumer<Builder> builderConsumer) {
        final Builder builder = new Builder();
        builderConsumer.accept(builder);
        return builder.build();
    }

    public static class Builder {
        int batchSize = 125;
        int batchDelay = 50;

        private Builder() {}

        public Builder setBatchSize(int batchSize) {
            this.batchSize = batchSize;
            return this;
        }

        public Builder setBatchDelay(int batchDelay) {
            this.batchDelay = batchDelay;
            return this;
        }

        QueueReadClientSettings build() {
            return new QueueReadClientSettings(batchSize, batchDelay);
        }
    }
}
