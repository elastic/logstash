package com.logstash.kyro;

import com.esotericsoftware.kryo.Kryo;
import com.esotericsoftware.kryo.Serializer;
import com.esotericsoftware.kryo.io.Input;
import com.esotericsoftware.kryo.io.Output;
import com.logstash.Timestamp;

public class TimestampSerializer extends Serializer<Timestamp> {

    public void write (Kryo kryo, Output output, Timestamp t) {
        output.writeLong(t.msec());
    }

    public Timestamp read (Kryo kryo, Input input, Class<Timestamp> type) {
        return new Timestamp(input.readLong());
    }
}
