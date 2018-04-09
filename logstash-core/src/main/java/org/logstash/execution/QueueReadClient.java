package org.logstash.execution;

import java.io.IOException;

public interface QueueReadClient {
    QueueBatch readBatch() throws InterruptedException;
    QueueBatch newBatch();
    void startMetrics(QueueBatch batch);
    void addOutputMetrics(int filteredSize);
    void addFilteredMetrics(int filteredSize);
    void closeBatch(QueueBatch batch) throws IOException;
    boolean isEmpty();
}
