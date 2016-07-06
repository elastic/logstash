package org.logstash.ackedqueue;

import org.logstash.common.io.ReadElementValue;

public class ElementFactory {

    public static Queueable deserialize(byte[] bytes) {
        return StringElement.deserialize(bytes);
    }

    public static Queueable build(ReadElementValue value) {
        StringElement ele = StringElement.deserialize(value.getBinaryValue());
        ele.setSeqNum(value.getSeqNum());
        return ele;
    }
}
