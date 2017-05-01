package org.logstash.common;

import java.util.Objects;

/**
 * Created by andrewvc on 9/6/16.
 */
public class SourceWithMetadata {
    // Either 'file' or something else
    private final String protocol;
    // A Unique identifier for the source within the given protocol
    // For a file, this is its path
    private final String id;
    private final Integer line;
    private final Integer column;
    private final String text;

    public String getProtocol() {
        return this.protocol;
    }

    public String getId() {
        return id;
    }

    public Integer getLine() {
        return line;
    }

    public Integer getColumn() {
        return column;
    }

    public String getText() {
        return text;
    }

    public SourceWithMetadata(String protocol, String id, Integer line, Integer column, String text) {
        this.protocol = protocol;
        this.id = id;
        this.line = line;
        this.column = column;
        this.text = text;
    }

    // Convenience method for dealing with files
    public SourceWithMetadata(String path, Integer line, Integer column, String text) {
        this("file", path, line, column, text);
    }

    public SourceWithMetadata(String protocol, String id, String text) {
        this(protocol, id, 1, 1, text);
    }

    public SourceWithMetadata() {
        this(null, null, null, null, null);
    }

    public int hashCode() {
        return Objects.hash(this.id, this.line, this.column, this.text);
    }

    public String toString() {
        return "[protocol]" + id + ":" + line + ":" + column + ":```\n" + text + "\n```";
    }
}
