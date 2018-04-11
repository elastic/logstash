package org.logstash.execution.codecs;

import org.junit.Before;
import org.junit.Test;
import org.logstash.execution.Codec;
import org.logstash.execution.LsConfiguration;
import org.logstash.execution.LsContext;

import java.util.Collections;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertNotNull;
import static org.junit.Assert.assertNull;

public class CodecFactoryTest {

    private CodecFactory codecFactory;

    @Before
    public void setup() {
        // shouldn't be necessary once DiscoverPlugins is fully implemented
        codecFactory = CodecFactory.getInstance();
        codecFactory.addCodec("line", Line.class);
    }

    @Test
    public void testBasicLookups() {
        LsConfiguration config = new LsConfiguration(Collections.EMPTY_MAP);
        LsContext context = new LsContext();
        Codec c = codecFactory.getCodec("line", config, context);
        assertNotNull(c);
        assertEquals(Line.class, c.getClass());

        c = codecFactory.getCodec(null, config, context);
        assertNull(c);
    }
}
