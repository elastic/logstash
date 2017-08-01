package org.logstash.common;

import org.junit.Test;
import org.junit.runner.RunWith;
import org.junit.runners.Parameterized;

import java.util.Arrays;
import java.util.Collection;

/**
 * Created by andrewvc on 6/12/17.
 */
@RunWith(Parameterized.class)
public class SourceWithMetadataTest {
    private final ParameterGroup parameterGroup;

    public static class ParameterGroup {
        public final String protocol;
        public final String path;
        public final Integer line;
        public final Integer column;
        public final String text;

        public ParameterGroup(String protocol, String path, Integer line, Integer column, String text) {
            this.protocol = protocol;
            this.path = path;
            this.line = line;
            this.column = column;
            this.text = text;
        }
    }

    @Parameterized.Parameters
    public static Iterable<ParameterGroup> data() {
        return Arrays.asList(
            new ParameterGroup(null, "path", 1, 1, "foo"),
            new ParameterGroup("proto", null, 1, 1, "foo"),
            new ParameterGroup("proto", "path", null, 1, "foo"),
            new ParameterGroup("proto", "path", 1, null, "foo"),
            new ParameterGroup("proto", "path", 1, 1, null),
            new ParameterGroup("", "path", 1, 1, "foo"),
            new ParameterGroup("proto", "", 1, 1, "foo"),
            new ParameterGroup(" ", "path", 1, 1, "foo"),
            new ParameterGroup("proto", "  ", 1, 1, "foo")
        );
    }

    public SourceWithMetadataTest(ParameterGroup parameterGroup) {
        this.parameterGroup = parameterGroup;
    }

    // So, this really isn't parameterized, but it isn't worth making a separate class for this
    @Test
    public void itShouldInstantiateCleanlyWhenParamsAreGood() throws IncompleteSourceWithMetadataException {
        new SourceWithMetadata("proto", "path", 1, 1, "text");
    }

    @Test(expected = IncompleteSourceWithMetadataException.class)
    public void itShouldThrowWhenMissingAField() throws IncompleteSourceWithMetadataException {
        new SourceWithMetadata(parameterGroup.protocol, parameterGroup.path, parameterGroup.line, parameterGroup.column, parameterGroup.text);
    }
}