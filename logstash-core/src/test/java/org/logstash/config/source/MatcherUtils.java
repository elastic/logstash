package org.logstash.config.source;

import org.hamcrest.Description;
import org.hamcrest.Matcher;
import org.hamcrest.TypeSafeMatcher;
import org.logstash.common.SourceWithMetadata;

class MatcherUtils {

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
