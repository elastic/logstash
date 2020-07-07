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
        assertThat("returns a valid config part", sut.iterator().next(), beSourceWithMetadata("string", "config_string", configString));
    }

    public static Matcher<SourceWithMetadata> beSourceWithMetadata(String protocol, String id, String text) {
        return new SourceWithMetadataMatcher(protocol, id, text);
    }

    private static class SourceWithMetadataMatcher extends TypeSafeMatcher<SourceWithMetadata> {
        private final String protocol;
        private final String id;
        private final String text;

        public SourceWithMetadataMatcher(String protocol, String id) {
            this(protocol, id, null);
        }

        public SourceWithMetadataMatcher(String protocol, String id, String text) {
            this.protocol = protocol;
            this.id = id;
            this.text = text;
        }

        @Override
        protected boolean matchesSafely(SourceWithMetadata swm) {
            if (!protocol.equals(swm.getProtocol())) {
                return false;
            }
            if (!id.equals(swm.getId())) {
                return false;
            }
            if (text != null) {
                return text.equals(swm.getText());
            }
            return true;
        }

        @Override
        public void describeTo(Description description) {

        }
    }
}



//    describe LogStash::Config::Source::Local::ConfigStringLoader do
//        subject { described_class }
//        let(:config_string) { "input { generator {} } output { stdout {} }"}
//
//        it "returns one config_parts" do
//            expect(subject.read(config_string).size).to eq(1)
//        end
//
//        it "returns a valid config part" do
//            config_part = subject.read(config_string).first
//            expect(config_part).to be_a_source_with_metadata("string", "config_string", config_string)
//        end
//    end