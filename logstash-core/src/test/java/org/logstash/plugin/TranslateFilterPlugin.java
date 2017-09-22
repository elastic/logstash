package org.logstash.plugin;

import org.logstash.Event;
import org.logstash.common.parser.ConstructingObjectParser;
import org.logstash.common.parser.Field;
import org.logstash.common.parser.ObjectTransforms;

import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.Arrays;
import java.util.Collection;
import java.util.Map;
import java.util.function.Function;

class TranslateFilterPlugin {
    private final static ConstructingObjectParser<TranslateFilter> TRANSLATE_MAP = new ConstructingObjectParser<>(
            TranslateFilter::new, Field.declareString("field"), Field.declareMap("dictionary"));
    private final static ConstructingObjectParser<FileBackedTranslateFilter> TRANSLATE_FILE = new ConstructingObjectParser<>(
            FileBackedTranslateFilter::new, Field.declareString("field"), Field.declareField("dictionary_path", TranslateFilterPlugin::parsePath));

    /**
     * The translate filter (as written in Ruby) is currently bimodal. There are two modes:
     * <p>
     * 1) A hand-written dictionary `dictionary => { "key" => value, ... }
     * 2) A file-backed dictionary `dictionary_path => "/some/path.yml"`
     * <p>
     * Because of these, provide a custom Function to call the correct implementation (file or static)
     */
    final static Function<Map<String, Object>, TranslateFilter> BUILDER = TranslateFilterPlugin::newFilter;

    static {
        // Apply most settings to both Translate Filter modes.
        for (ConstructingObjectParser<? extends TranslateFilter> builder : Arrays.asList(TRANSLATE_MAP, TRANSLATE_FILE)) {
            builder.declareString("destination", TranslateFilter::setDestination);
            builder.declareBoolean("exact", TranslateFilter::setExact);
            builder.declareBoolean("override", TranslateFilter::setOverride);
            builder.declareBoolean("regex", TranslateFilter::setRegex);
            builder.declareString("fallback", TranslateFilter::setFallback);
        }

        // File-backed mode gets a special `refresh_interval` setting.
        TRANSLATE_FILE.declareInteger("refresh_interval", FileBackedTranslateFilter::setRefreshInterval);
    }

    private static Path parsePath(Object input) {
        Path path = Paths.get(ObjectTransforms.transformString(input));

        if (!path.toFile().exists()) {
            throw new IllegalArgumentException("The given path does not exist: " + path);
        }

        return path;
    }

    private static TranslateFilter newFilter(Map<String, Object> config) {
        if (config.containsKey("dictionary") && config.containsKey("dictionary_path")) {
            throw new IllegalArgumentException("You must specify either dictionary or dictionary_path, not both. Both are set.");
        }

        if (config.containsKey("dictionary")) {
            // "dictionary" field was set, so args[1] is a map.
            return TRANSLATE_MAP.apply(config);
        } else {
            // dictionary_path set, so let's use a file-backed translate filter.
            return TRANSLATE_FILE.apply(config);
        }
    }

    // Processor interface will be defined in another PR, so this exists as a placeholder;
    private interface Processor extends Function<Collection<Event>, Collection<Event>> {
    }

    public static class TranslateFilter implements Processor {
        Map<String, Object> map;
        private String source;
        private String target = "translation";
        private String fallback;
        private boolean exact = true;
        private boolean override = false;
        private boolean regex = false;

        TranslateFilter(String source, Map<String, Object> map, Path path) { /* ... */ }

        TranslateFilter(String source, Map<String, Object> map) {
            this(source);
            this.map = map;
        }

        TranslateFilter(String source) {
            this.source = source;
        }

        void setDestination(String target) {
            this.target = target;
        }

        private Object translate(Object input) {
            if (input instanceof String) {
                return map.get(input);
            } else {
                return null;
            }
        }

        @Override
        public Collection<Event> apply(Collection<Event> events) {
            // This implementation is incomplete. This test implementation primarily exists to demonstrate
            // the usage of the ConstructingObjectParser with a real plugin.
            for (Event event : events) {
                Object input = event.getField(source);
                if (input == null && fallback != null) {
                    event.setField(target, fallback);
                } else {
                    Object output = translate(input);
                    if (output != null) {
                        event.setField(target, output);
                    }
                }
            }
            return null;
        }

        void setExact(boolean exact) {
            this.exact = exact;
        }

        void setOverride(boolean flag) {
            this.override = flag;
        }

        void setFallback(String fallback) {
            this.fallback = fallback;
        }

        void setRegex(boolean flag) {
            this.regex = flag;

        }
    }

    static class FileBackedTranslateFilter extends TranslateFilter {
        private final Path path;
        private int refresh;

        FileBackedTranslateFilter(String source, Path path) {
            super(source);
            this.path = path;
            // start a thread to read the Path and update the Map periodically.
            // implementation left as an exercise, since this is just a demo code :)
        }

        private void setRefreshInterval(int refresh) {
            this.refresh = refresh;

        }
    }
}
