package org.logstash.plugin.example;

import org.logstash.plugin.ConstructingObjectParser;
import org.logstash.plugin.Input;
import org.logstash.plugin.Plugin;

public class ExamplePlugin implements Plugin {
    private static final ConstructingObjectParser<TLSContext> TLS = new ConstructingObjectParser<>(TLSContext::new);
    private static final ConstructingObjectParser<ExampleInput> EXAMPLE = new ConstructingObjectParser<>(ExampleInput::new);

    static {
        TLS.string("truststore", TLSContext::setTrustStore);
        //TLS.stringList("ciphers", TLSContext::setCiphers);
        //TLS.boolean("require client certificate", TLSContext::setClientCertificateRequired)

        EXAMPLE.integer("port", ExampleInput::setPort);

        /*
         * Have a single 'tls' setting that configures an object.
         *
         * The intent here is to be able to box a component (such as TLS) in a way that can be reused among plugins.
         *
         * In this example, we have 'example' input having a 'tls' setting, and this would look like this
         * in the Logstash config:
         *
         * input {
         *   example {
         *     port => 12345
         *     tls => {
         *       truststore => "/path/to/trust"
         *       key => "/path/to/private.key"
         *       certificate => "/path/to/server.crt"
         *       ciphers => [ "some", "specific", "ciphers" ]
         *     }
         *   }
         * }
         */
        EXAMPLE.object("tls", ExampleInput::setTLS, TLS);
    }

    public ConstructingObjectParser<? extends Input> getInputs() {
        return EXAMPLE;
    }

}
