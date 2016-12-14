package org.logstash.config.ir;

import java.util.Objects;

/**
 * Created by andrewvc on 9/6/16.
 */
public class SourceMetadata {
    private final String sourceFile;

    public String getSourceFile() {
        return sourceFile;
    }

    public Integer getSourceLine() {
        return sourceLine;
    }

    public Integer getSourceColumn() {
        return sourceColumn;
    }

    public String getSourceText() {
        return sourceText;
    }

    private final Integer sourceLine;
    private final Integer sourceColumn;
    private final String sourceText;

    public SourceMetadata(String sourceFile, Integer sourceLine, Integer sourceChar, String sourceText) {
        this.sourceFile = sourceFile;
        this.sourceLine = sourceLine;
        this.sourceColumn = sourceChar;
        this.sourceText = sourceText;
    }

    public SourceMetadata() {
        this.sourceFile = null;
        this.sourceLine = null;
        this.sourceColumn = null;
        this.sourceText = null;
    }

    public int hashCode() {
        return Objects.hash(this.sourceFile, this.sourceLine, this.sourceColumn, this.sourceText);
    }

    public String toString() {
        return sourceFile + ":" + sourceLine + ":" + sourceColumn + ":```\n" + sourceText + "\n```";
    }
}
