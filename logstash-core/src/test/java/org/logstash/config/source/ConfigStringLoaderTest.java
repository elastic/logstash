package org.logstash.config.source;

import org.hamcrest.Description;
import org.hamcrest.Matcher;
import org.hamcrest.TypeSafeMatcher;
import org.junit.Test;
import org.logstash.common.IncompleteSourceWithMetadataException;
import org.logstash.common.SourceWithMetadata;

import java.util.List;

import static org.junit.Assert.*;

public class ConfigStringLoaderTest {

    @Test
    public void testRead() throws IncompleteSourceWithMetadataException {
        String configString = "input { generator {} } output { stdout {} }";

        final List<SourceWithMetadata> sut = ConfigStringLoader.read(configString);

        assertEquals("returns one config_parts", 1, sut.size());
        assertThat("returns a valid config part", sut.iterator().next(), MatcherUtils.beSourceWithMetadata("string", "config_string", configString));
    }
}
