package org.logstash.config.ir;

public final class ConfigSourceSegment {

    private final String source;
    private final int offset;
    private final int length;

    public ConfigSourceSegment(String source, int offset, int length) {
        this.source = source;
        this.offset = offset;
        this.length = length;
    }

    public String getSource() {
        return source;
    }

    public int getLength() {
        return length;
    }

    public boolean contains(int lineNumber) {
        int rebased_line_number = lineNumber - this.offset;
        return 1 <= rebased_line_number && rebased_line_number <= this.length;
    }

    public int rebase(int lineNumber) {
        return lineNumber - this.offset;
    }

    @Override
    public String toString() {
        return "ConfigSourceSegment{source='" + source + "', offset=" + offset + ", length=" + length + '}';
    }
}