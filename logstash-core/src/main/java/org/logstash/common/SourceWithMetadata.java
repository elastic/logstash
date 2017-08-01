package org.logstash.common;

import org.logstash.config.ir.HashableWithSource;

import java.util.Arrays;
import java.util.Collection;
import java.util.List;
import java.util.Objects;
import java.util.regex.Pattern;
import java.util.stream.Collectors;
import java.util.stream.Stream;

/**
 * Created by andrewvc on 9/6/16.
 */
public class SourceWithMetadata implements HashableWithSource {
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

    private static final Pattern emptyString = Pattern.compile("^\\s*$");

    public SourceWithMetadata(String protocol, String id, Integer line, Integer column, String text) throws IncompleteSourceWithMetadataException {
        this.protocol = protocol;
        this.id = id;
        this.line = line;
        this.column = column;
        this.text = text;

        List<Object> badAttributes = this.attributes().stream().filter(a -> {
            if (a == null) return true;
            if (a instanceof String) {
                return emptyString.matcher((String) a).matches();
            }
            return false;
        }).collect(Collectors.toList());

        if (!(this.getText() instanceof String)) {
          badAttributes.add(this.getText());
        }

        if (!badAttributes.isEmpty()){
            String message = "Missing attributes in SourceWithMetadata: (" + badAttributes + ") "
                    + this.toString();
            throw new IncompleteSourceWithMetadataException(message);
        }
    }

    public SourceWithMetadata(String protocol, String id, String text) throws IncompleteSourceWithMetadataException {
        this(protocol, id, 0, 0, text);
    }

    public int hashCode() {
        return Objects.hash(hashableAttributes().toArray());
    }

    public String toString() {
        return "[" + protocol + "]" + id + ":" + line + ":" + column + ":```\n" + text + "\n```";
    }

    @Override
    public String hashSource() {
        return hashableAttributes().stream().map(Object::toString).collect(Collectors.joining("|"));
    }

    // Fields checked for being not null and non empty String
    private Collection<Object> attributes() {
        return Arrays.asList(this.getId(), this.getProtocol(), this.getLine(), this.getColumn());
    }

    // Fields used in the hashSource and hashCode methods to ensure uniqueness
    private Collection<Object> hashableAttributes() {
        return Arrays.asList(this.getId(), this.getProtocol(), this.getLine(), this.getColumn(), this.getText());
    }
}
