package com.logstash.kyro;

import com.esotericsoftware.kryo.Kryo;
import com.esotericsoftware.kryo.io.ByteBufferInput;
import com.esotericsoftware.kryo.io.ByteBufferOutput;
import com.esotericsoftware.kryo.pool.KryoFactory;
import com.esotericsoftware.kryo.pool.KryoPool;
import com.esotericsoftware.kryo.serializers.MapSerializer;
import com.logstash.Timestamp;

import java.util.HashMap;

public class KryoInstances {

    private static KryoFactory factory = () -> {
        Kryo kryo = new Kryo();
        // add customisation here
        kryo.register(Timestamp.class, new TimestampSerializer(), 201);
        MapSerializer serializer = new MapSerializer();
        serializer.setKeyClass(String.class, kryo.getSerializer(String.class));
        kryo.register(HashMap.class, serializer, 202);
        KryoInputOutput kio = new KryoInputOutput(new ByteBufferInput(), new ByteBufferOutput(512, -1));
        kryo.getContext().put("kio", kio);
        return kryo;
    };

    private static KryoPool pool = new KryoPool.Builder(factory).softReferences().build();

    public static Kryo get() {
        return pool.borrow();
    }

    public static void release(Kryo instance) {
        pool.release(instance);
    }
}

