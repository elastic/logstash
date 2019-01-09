package org.logstash.config.ir.compiler;

import org.jruby.RubyArray;
import org.logstash.Event;
import org.logstash.RubyUtil;
import org.logstash.StringInterpolation;
import org.logstash.ext.JrubyEventExtLibrary;

import java.io.IOException;
import java.util.List;
import java.util.Map;

/**
 * Implements common actions such as "add_field" and "tags" that can be specified
 * for various plugins.
 */
public class CommonActions {

    /**
     * Implements the {@code add_field} option for Logstash plugins.
     *
     * @param e           Event on which to add the fields.
     * @param fieldsToAdd The fields to be added to the event.
     */
    @SuppressWarnings("unchecked")
    public static void addField(JrubyEventExtLibrary.RubyEvent e, Map<String, Object> fieldsToAdd) {
        Event evt = e.getEvent();
        try {
            for (Map.Entry<String, Object> entry : fieldsToAdd.entrySet()) {
                String keyToSet = StringInterpolation.evaluate(evt, entry.getKey());
                Object val = evt.getField(keyToSet);
                Object valueToSet = entry.getValue();
                valueToSet = valueToSet instanceof String
                        ? StringInterpolation.evaluate(evt, (String) entry.getValue())
                        : entry.getValue();

                if (val == null) {
                    evt.setField(keyToSet, valueToSet);
                } else {
                    if (val instanceof List) {
                        ((List) val).add(valueToSet);
                        evt.setField(keyToSet, val);
                    } else {
                        RubyArray list = RubyArray.newArray(RubyUtil.RUBY, 2);
                        list.add(val);
                        list.add(valueToSet);
                        evt.setField(keyToSet, list);
                    }
                }
            }
        } catch (IOException ex) {
            throw new IllegalStateException(ex);
        }
    }

    /**
     * Implements the {@code add_tag} option for Logstash plugins.
     *
     * @param e    Event on which to add the tags.
     * @param tags The tags to be added to the event.
     */
    public static void addTag(JrubyEventExtLibrary.RubyEvent e, List<String> tags) {
        Event evt = e.getEvent();
        try {
            for (String t : tags) {
                String tagToAdd = StringInterpolation.evaluate(evt, t);
                evt.tag(tagToAdd);
            }
        } catch (IOException ex) {
            throw new IllegalStateException(ex);
        }
    }

    /**
     * Implements the {@code type} option for Logstash plugins.
     *
     * @param e    Event on which to set the type.
     * @param type The type to set on the event.
     */
    public static void addType(JrubyEventExtLibrary.RubyEvent e, String type) {
        Event evt = e.getEvent();
        if (evt.getField("type") == null) {
            evt.setField("type", type);
        }
    }

    /**
     * Implements the {@code remove_field} option for Logstash plugins.
     *
     * @param e              Event from which to remove the fields.
     * @param fieldsToRemove The fields to remove from the event.
     */
    public static void removeField(JrubyEventExtLibrary.RubyEvent e, List<String> fieldsToRemove) {
        Event evt = e.getEvent();
        try {
            for (String s : fieldsToRemove) {
                String fieldToRemove = StringInterpolation.evaluate(evt, s);
                evt.remove(fieldToRemove);
            }
        } catch (IOException ex) {
            throw new IllegalStateException(ex);
        }
    }

    /**
     * Implements the {@code remove_tag} option for Logstash plugins.
     *
     * @param e            Event from which to remove the tags.
     * @param tagsToRemove The tags to remove from the event.
     */
    @SuppressWarnings({"unchecked", "rawtypes"})
    public static void removeTag(JrubyEventExtLibrary.RubyEvent e, List<String> tagsToRemove) {
        Event evt = e.getEvent();
        Object o = evt.getField("tags");
        if (o instanceof List) {
            List tags = (List) o;
            if (tags.size() > 0) {
                try {
                    for (String s : tagsToRemove) {
                        String tagToRemove = StringInterpolation.evaluate(evt, s);
                        tags.remove(tagToRemove);
                    }
                    evt.setField("tags", tags);
                } catch (IOException ex) {
                    throw new IllegalStateException(ex);
                }
            }
        }
    }
}
