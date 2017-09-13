package org.logstash.ackedqueue.io;

@FunctionalInterface
public interface PageIOFactory {
    PageIO build(int pageNum, int capacity, String dirPath);
}
