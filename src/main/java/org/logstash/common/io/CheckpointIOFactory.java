package org.logstash.common.io;

@FunctionalInterface
public interface CheckpointIOFactory {
    CheckpointIO build(String dirPath);
}
