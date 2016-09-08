package org.logstash;


import java.io.IOException;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

public class StringInterpolation {
    static Pattern TEMPLATE_TAG = Pattern.compile("%\\{([^}]+)\\}");
    static Map cache;

    protected static class HoldCurrent {
        private static final StringInterpolation INSTANCE = new StringInterpolation();
    }

    private StringInterpolation() {
        // TODO:
        // This may need some tweaking for the concurrency level to get better memory usage.
        // The current implementation doesn't allow the keys to expire, I think under normal usage
        // the keys will converge to a fixed number.
        //
        // If this code make logstash goes OOM, we have the following options:
        //  - If the key doesn't contains a `%` do not cache it, this will reduce the key size at a performance cost.
        //  - Use some kind LRU cache
        //  - Create a new data structure that use weakref or use Google Guava for the cache https://code.google.com/p/guava-libraries/
        this.cache = new ConcurrentHashMap<>();
    }

    public void clearCache() {
        this.cache.clear();
    }

    public int cacheSize() {
        return this.cache.size();
    }

    public String evaluate(Event event, String template) throws IOException {
        TemplateNode compiledTemplate = (TemplateNode) this.cache.get(template);

        if (compiledTemplate == null) {
            compiledTemplate = this.compile(template);
            this.cache.put(template, compiledTemplate);
        }

        return compiledTemplate.evaluate(event);
    }

    public TemplateNode compile(String template) {
        Template compiledTemplate = new Template();

        if (template.indexOf('%') == -1) {
            // Move the nodes to a custom instance
            // so we can remove the iterator and do one `.evaluate`
            compiledTemplate.add(new StaticNode(template));
        } else {
            Matcher matcher = TEMPLATE_TAG.matcher(template);
            String tag;
            int pos = 0;

            while (matcher.find()) {
                if (matcher.start() > 0) {
                    compiledTemplate.add(new StaticNode(template.substring(pos, matcher.start())));
                }

                tag = matcher.group(1);
                compiledTemplate.add(identifyTag(tag));
                pos = matcher.end();
            }

            if(pos <= template.length() - 1) {
                compiledTemplate.add(new StaticNode(template.substring(pos)));
            }
        }

        // if we only have one node return the node directly
        // and remove the need to loop.
        if(compiledTemplate.size() == 1) {
            return compiledTemplate.get(0);
        } else {
            return compiledTemplate;
        }
    }

    public TemplateNode identifyTag(String tag) {
        if(tag.equals("+%s")) {
            return new EpochNode();
        } else if(tag.charAt(0) == '+') {
                return new DateNode(tag.substring(1));

        } else {
            return new KeyNode(tag);
        }
    }

    static StringInterpolation getInstance() {
        return HoldCurrent.INSTANCE;
    }
}