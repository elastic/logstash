package org.logstash.ackedqueue.io;

@FunctionalInterface
public interface CheckpointIOFactory {
    CheckpointIO build(String dirPath);
}
