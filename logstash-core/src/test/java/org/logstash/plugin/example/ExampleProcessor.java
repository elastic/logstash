package org.logstash.plugin.example;

import org.logstash.Event;
import org.logstash.plugin.ConstructingObjectParser;
import org.logstash.plugin.Processor;

import java.util.Collection;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

public class ExampleProcessor implements Processor {
    static final ConstructingObjectParser<ExampleProcessor> EXAMPLE_PROCESSOR = new ConstructingObjectParser<>(args -> new ExampleProcessor((Pattern) args[0]));

    static {
        // Since we are using a non-default type "Pattern" we need to call declareConstructorArg
        // with a custom Function that returns a Pattern given an Object.
        EXAMPLE_PROCESSOR.declareConstructorArg("pattern", (object) -> Pattern.compile(ConstructingObjectParser.stringTransform(object)));
        EXAMPLE_PROCESSOR.string("source", ExampleProcessor::setSourceField);
    }

    private Pattern pattern;
    private String sourceField = "message";

    ExampleProcessor(Pattern pattern) {
        this.pattern = pattern;
    }

    void setSourceField(String sourceField) {
        this.sourceField = sourceField;
    }

    @Override
    public Collection<Event> process(Collection<Event> events) {
        for (Event event : events) {
            String value = (String) event.getField(sourceField);
            if (value != null) {
                Matcher matcher = pattern.matcher((String) event.getField(sourceField));
                event.setField("matches", matcher.matches());
            } else {
                event.setField("matches", false);
            }
        }

        return null;
    }
}
