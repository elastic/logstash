/*
 * Licensed to Elasticsearch B.V. under one or more contributor
 * license agreements. See the NOTICE file distributed with
 * this work for additional information regarding copyright
 * ownership. Elasticsearch B.V. licenses this file to you under
 * the Apache License, Version 2.0 (the "License"); you may
 * not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *	http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */


package org.logstash.config.ir.compiler;

import co.elastic.logstash.api.Event;
import org.jruby.RubyArray;
import org.logstash.RubyUtil;
import org.logstash.StringInterpolation;

import java.io.IOException;
import java.util.List;
import java.util.Map;
import java.util.function.Consumer;
import java.util.function.Function;

import static co.elastic.logstash.api.PluginHelper.ADD_FIELD_CONFIG;
import static co.elastic.logstash.api.PluginHelper.ADD_TAG_CONFIG;
import static co.elastic.logstash.api.PluginHelper.REMOVE_FIELD_CONFIG;
import static co.elastic.logstash.api.PluginHelper.REMOVE_TAG_CONFIG;
import static co.elastic.logstash.api.PluginHelper.TAGS_CONFIG;
import static co.elastic.logstash.api.PluginHelper.TYPE_CONFIG;

/**
 * Implements common actions such as "add_field" and "tags" that can be specified
 * for various plugins.
 */
class CommonActions {

    @SuppressWarnings("unchecked")
    static Consumer<Event> getFilterAction(Map.Entry<String, Object> actionDefinition) {
        String actionName = actionDefinition.getKey();
        if (actionName.equals(ADD_FIELD_CONFIG.name())) {
            return x -> addField(x, (Map<String, Object>) actionDefinition.getValue());
        }
        if (actionName.equals(ADD_TAG_CONFIG.name())) {
            return x -> addTag(x, (List<Object>) actionDefinition.getValue());
        }
        if (actionName.equals(REMOVE_FIELD_CONFIG.name())) {
            return x -> removeField(x, (List<String>) actionDefinition.getValue());
        }
        if (actionName.equals(REMOVE_TAG_CONFIG.name())) {
            return x -> removeTag(x, (List<String>) actionDefinition.getValue());
        }
        return null;
    }

    @SuppressWarnings("unchecked")
    static Function<Map<String, Object>, Map<String, Object>> getInputAction(
            Map.Entry<String, Object> actionDefinition) {
        String actionName = actionDefinition.getKey();
        if (actionName.equals(ADD_FIELD_CONFIG.name())) {
            return x -> addField(x, (Map<String, Object>) actionDefinition.getValue());
        }
        if (actionName.equals(TAGS_CONFIG.name())) {
            return x -> addTag(x, (List<Object>) actionDefinition.getValue());
        }
        if (actionName.equals(TYPE_CONFIG.name())) {
            return x -> addType(x, (String) actionDefinition.getValue());
        }
        return null;
    }


    /**
     * Implements the {@code add_field} option for Logstash inputs.
     *
     * @param event       Event on which to add the fields.
     * @param fieldsToAdd The fields to be added to the event.
     * @return Updated event.
     */
    static Map<String, Object> addField(Map<String, Object> event, Map<String, Object> fieldsToAdd) {
        Event tempEvent = new org.logstash.Event(event);
        addField(tempEvent, fieldsToAdd);
        return tempEvent.getData();
    }

    /**
     * Implements the {@code add_field} option for Logstash filters.
     *
     * @param evt         Event on which to add the fields.
     * @param fieldsToAdd The fields to be added to the event.
     */
    @SuppressWarnings("unchecked")
    static void addField(Event evt, Map<String, Object> fieldsToAdd) {
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
                        @SuppressWarnings("rawtypes") RubyArray list = RubyArray.newArray(RubyUtil.RUBY, 2);
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
     * Implements the {@code tags} option for Logstash inputs.
     *
     * @param e    Event on which to add the tags.
     * @param tags The tags to be added to the event.
     * @return Updated event.
     */
    static Map<String, Object> addTag(Map<String, Object> e, List<Object> tags) {
        Event tempEvent = new org.logstash.Event(e);
        addTag(tempEvent, tags);
        return tempEvent.getData();
    }

    /**
     * Implements the {@code add_tag} option for Logstash filters.
     *
     * @param evt  Event on which to add the tags.
     * @param tags The tags to be added to the event.
     */
    static void addTag(Event evt, List<Object> tags) {
        try {
            for (Object o : tags) {
                String tagToAdd = StringInterpolation.evaluate(evt, o.toString());
                evt.tag(tagToAdd);
            }
        } catch (IOException ex) {
            throw new IllegalStateException(ex);
        }
    }

    /**
     * Implements the {@code type} option for Logstash inputs.
     *
     * @param event Event on which to set the type.
     * @param type  The type to set on the event.
     * @return Updated event.
     */
    static Map<String, Object> addType(Map<String, Object> event, String type) {
        event.putIfAbsent("type", type);
        return event;
    }

    /**
     * Implements the {@code remove_field} option for Logstash filters.
     *
     * @param evt            Event from which to remove the fields.
     * @param fieldsToRemove The fields to remove from the event.
     */
    static void removeField(Event evt, List<String> fieldsToRemove) {
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
     * Implements the {@code remove_tag} option for Logstash filters.
     *
     * @param evt          Event from which to remove the tags.
     * @param tagsToRemove The tags to remove from the event.
     */
    @SuppressWarnings({"unchecked", "rawtypes"})
    static void removeTag(Event evt, List<String> tagsToRemove) {
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
