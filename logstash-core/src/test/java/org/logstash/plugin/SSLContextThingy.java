package org.logstash.plugin;

import org.logstash.common.parser.Field;
import org.logstash.common.parser.ObjectFactory;

import javax.net.ssl.SSLContext;

public class SSLContextThingy {
    final static ObjectFactory<SSLContext> SSL_CONTEXT_OBJECT_FACTORY = new ObjectFactory<>(SSLContextThingy::initSSLContext,
            Field.declareString("certificate-authorities")
    );


    private static SSLContext initSSLContext(String capath) {
        return null;
    }

}
