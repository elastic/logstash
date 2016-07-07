package org.logstash.common.io;

public interface CheckpointIOFactory {
    CheckpointIO build(String dirPath);
}
