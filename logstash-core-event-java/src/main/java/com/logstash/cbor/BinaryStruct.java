package com.logstash.cbor;

import com.logstash.Event;

import java.util.HashMap;

public class BinaryStruct {
    private HashMap<String, Object> data;
    private HashMap<String, Object> metadata;

    public BinaryStruct(HashMap<String, Object> data, HashMap<String, Object> metadata) {
        this.data = data;
        this.metadata = metadata;
    }

    public BinaryStruct(Event e) {
        this.data = (HashMap) e.getData();
        this.metadata = (HashMap) e.getMetadata();
    }

    public HashMap<String, Object> getData() {
        return data;
    }

    public HashMap<String, Object> getMetadata() {
        return metadata;
    }
}
