package com.logstash;


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
        // TODO: this may need some tweaking for the concurrency level to get better memory usage.
        this.cache = new ConcurrentHashMap<>();
    }

    public String evaluate(Event event, String template) {
        TemplateNode compiledTemplate = (TemplateNode) this.cache.get(template);

        if(compiledTemplate == null) {
            compiledTemplate = this.compile(template);
            TemplateNode set = (TemplateNode) this.cache.putIfAbsent(template, compiledTemplate);
            compiledTemplate = (set != null) ? set : compiledTemplate;
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
                    pos = matcher.end();
                }

                tag = matcher.group(1);
                compiledTemplate.add(identifyTag(tag));
            }

            if(pos < template.length() - 1) {
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

    // TODO: add support for array, hash, float and epoch
    public TemplateNode identifyTag(String tag) {
        // Doesnt support parsing the float yet
        if(tag.charAt(0) == '+') {
            return new DateNode(tag.substring(1));
        } else {
            return new KeyNode(tag);
        }
    }

    static StringInterpolation getInstance() {
        return HoldCurrent.INSTANCE;
    }
}