package org.logstash.common.io;

import java.io.IOException;

public interface PageIOFactory {
    PageIO build(int capacity, String dirPath) throws IOException;
}
