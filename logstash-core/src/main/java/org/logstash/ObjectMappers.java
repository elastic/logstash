package org.logstash;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.dataformat.cbor.CBORFactory;
import com.fasterxml.jackson.dataformat.cbor.CBORGenerator;
import com.fasterxml.jackson.module.afterburner.AfterburnerModule;

public final class ObjectMappers {

    public static final ObjectMapper JSON_MAPPER = new ObjectMapper()
        .registerModule(new AfterburnerModule());

    public static final ObjectMapper CBOR_MAPPER = new ObjectMapper(
        new CBORFactory().configure(CBORGenerator.Feature.WRITE_MINIMAL_INTS, false)
    ).registerModule(new AfterburnerModule());

    private ObjectMappers() {
    }
}
