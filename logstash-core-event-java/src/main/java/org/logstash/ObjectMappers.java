package org.logstash;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.dataformat.cbor.CBORFactory;
import com.fasterxml.jackson.dataformat.cbor.CBORGenerator;
import com.fasterxml.jackson.module.afterburner.AfterburnerModule;

public class ObjectMappers {
    public static final ObjectMapper JSON_MAPPER = new ObjectMapper();
    public static final ObjectMapper CBOR_MAPPER = new ObjectMapper(new CBORFactory());

    static {
        JSON_MAPPER.registerModule(new AfterburnerModule());

        CBORFactory cborf = (CBORFactory) CBOR_MAPPER.getFactory();
        cborf.configure(CBORGenerator.Feature.WRITE_MINIMAL_INTS, false);
        CBOR_MAPPER.registerModule(new AfterburnerModule());
    }
}
