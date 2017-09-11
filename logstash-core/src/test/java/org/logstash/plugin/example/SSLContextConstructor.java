package org.logstash.plugin.example;

import org.logstash.plugin.ConstructingObjectParser;

import javax.net.ssl.KeyManagerFactory;
import javax.net.ssl.SSLContext;
import javax.net.ssl.TrustManager;
import javax.net.ssl.TrustManagerFactory;
import java.security.KeyManagementException;
import java.security.NoSuchAlgorithmException;

public final class SSLContextConstructor {
    public static final ConstructingObjectParser<SSLContext> TLS = new ConstructingObjectParser<>(args -> getInstance());
    private static final String keyManagerAlgorithm = KeyManagerFactory.getDefaultAlgorithm();
    private static final String trustManagerAlgorithm = TrustManagerFactory.getDefaultAlgorithm();

    static {
        // What would TLS configuration look like?
        // Need to configure:
        // * key manager
        // * trust manager

        // XXX: Use KeyStoreBuilder from tealess for this.
        // XXX: Defer KeyStoreBuidler.build() until all parameters have been processed.
        //      - this will allow users to specify passwords to their trust store, perhaps?
        TLS.declareConstructorArg("truststore", SSLContextConstructor::loadTrustStore);
        //TLS.declareConstructorArg("truststore", SSLContextConstructor::loadKeyStore);
        //TLS.string("keystore");
        //TLS.string("truststore");
        //TLS.stringList("ciphers", TLSContext::setCiphers);
        //TLS.boolean("require client certificate", TLSContext::setClientCertificateRequired)

    }

    private static SSLContext getInstance() {
        try {
            SSLContext ctx = SSLContext.getInstance("TLS");
            ctx.init(null, null, null);
            return ctx;
        } catch (NoSuchAlgorithmException | KeyManagementException e) {
            throw new IllegalArgumentException("Failure creating SSLContext for TLS", e);
        }
    }

    private static TrustManager[] loadTrustStore(Object value) {
        // XXX: value may be a string or perhaps an array of strings?
        String path = ConstructingObjectParser.stringTransform(value);

        try {
            TrustManagerFactory tmf = TrustManagerFactory.getInstance(trustManagerAlgorithm);
        } catch (NoSuchAlgorithmException e) {
            throw new IllegalArgumentException("Failed to create a TrustManagerFactory instance", e);
        }
        return null; // XXX: IMPLEMENT
    }

}
