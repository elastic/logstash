package org.logstash.plugin.example;

import org.logstash.plugin.ConstructingObjectParser;
import org.logstash.plugin.Input;
import org.logstash.plugin.Plugin;
import org.logstash.plugin.Processor;

import java.util.Collections;
import java.util.Map;

public class ExamplePlugin implements Plugin {
    private static final ConstructingObjectParser<TLSContext> TLS = new ConstructingObjectParser<>(args -> new TLSContext());
    private static final ConstructingObjectParser<ExampleInput> EXAMPLE = new ConstructingObjectParser<>(args -> new ExampleInput((int) args[0]));

    static {
        TLS.string("truststore", TLSContext::setTrustStore);
        //TLS.stringList("ciphers", TLSContext::setCiphers);
        //TLS.boolean("require client certificate", TLSContext::setClientCertificateRequired)

        EXAMPLE.integer("port");
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

    public Map<String, ConstructingObjectParser<? extends Input>> getInputs() {
        return Collections.singletonMap("example", EXAMPLE);
    }

    public Map<String, ConstructingObjectParser<? extends Processor>> getProcessors() {
        return Collections.singletonMap("example", ExampleProcessor.EXAMPLE_PROCESSOR);
    }

}
