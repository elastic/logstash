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

import org.junit.Assert;
import org.junit.Test;
import org.logstash.Event;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collections;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

public class CommonActionsTest {

    private static final String TAGS = "tags";

    @Test
    public void testAddField() {
        // add field to empty event
        Event e = new Event();
        String testField = "test_field";
        String testStringValue = "test_value";
        CommonActions.addField(e, Collections.singletonMap(testField, testStringValue));
        Assert.assertEquals(testStringValue, e.getField(testField));

        // add to existing field and convert to array value
        e = new Event(Collections.singletonMap(testField, testStringValue));
        CommonActions.addField(e, Collections.singletonMap(testField, testStringValue));
        Object value = e.getField(testField);
        Assert.assertTrue(value instanceof List);
        Assert.assertEquals(2, ((List) value).size());
        Assert.assertEquals(testStringValue, ((List) value).get(0));
        Assert.assertEquals(testStringValue, ((List) value).get(1));

        // add to existing array field
        String testStringValue2 = "test_value2";
        List<String> stringVals = Arrays.asList(testStringValue, testStringValue2);
        e = new Event(Collections.singletonMap(testField, stringVals));
        CommonActions.addField(e, Collections.singletonMap(testField, testStringValue));
        value = e.getField(testField);
        Assert.assertTrue(value instanceof List);
        Assert.assertEquals(3, ((List) value).size());
        Assert.assertEquals(testStringValue, ((List) value).get(0));
        Assert.assertEquals(testStringValue2, ((List) value).get(1));
        Assert.assertEquals(testStringValue, ((List) value).get(2));

        // add non-string value to empty event
        Long testLongValue = 42L;
        e = new Event();
        CommonActions.addField(e, Collections.singletonMap(testField, testLongValue));
        Assert.assertEquals(testLongValue, e.getField(testField));

        // add non-string value to existing field
        e = new Event(Collections.singletonMap(testField, testStringValue));
        CommonActions.addField(e, Collections.singletonMap(testField, testLongValue));
        value = e.getField(testField);
        Assert.assertTrue(value instanceof List);
        Assert.assertEquals(2, ((List) value).size());
        Assert.assertEquals(testStringValue, ((List) value).get(0));
        Assert.assertEquals(testLongValue, ((List) value).get(1));

        // add non-string value to existing array field
        e = new Event(Collections.singletonMap(testField, stringVals));
        CommonActions.addField(e, Collections.singletonMap(testField, testLongValue));
        value = e.getField(testField);
        Assert.assertTrue(value instanceof List);
        Assert.assertEquals(3, ((List) value).size());
        Assert.assertEquals(testStringValue, ((List) value).get(0));
        Assert.assertEquals(testStringValue2, ((List) value).get(1));
        Assert.assertEquals(testLongValue, ((List) value).get(2));

        // add field/value with dynamic values
        e = new Event(Collections.singletonMap(testField, testStringValue));
        String newField = "%{" + testField + "}_field";
        String newValue = "%{" + testField + "}_value";
        CommonActions.addField(e, Collections.singletonMap(newField, newValue));
        Assert.assertEquals(testStringValue + "_value", e.getField(testStringValue + "_field"));
    }

    @Test
    public void testAddTag() {

        // add tag to empty event
        Event e = new Event();
        String testTag = "test_tag";
        CommonActions.addTag(e, Collections.singletonList(testTag));
        Object value = e.getField(TAGS);
        Assert.assertTrue(value instanceof List);
        Assert.assertEquals(1, ((List) value).size());
        Assert.assertEquals(testTag, ((List) value).get(0));

        // add two tags to empty event
        e = new Event();
        String testTag2 = "test_tag2";
        CommonActions.addTag(e, Arrays.asList(testTag, testTag2));
        value = e.getField(TAGS);
        Assert.assertTrue(value instanceof List);
        Assert.assertEquals(2, ((List) value).size());
        Assert.assertEquals(testTag, ((List) value).get(0));
        Assert.assertEquals(testTag2, ((List) value).get(1));

        // add duplicate tag
        e = new Event();
        e.tag(testTag);
        CommonActions.addTag(e, Collections.singletonList(testTag));
        value = e.getField(TAGS);
        Assert.assertTrue(value instanceof List);
        Assert.assertEquals(1, ((List) value).size());
        Assert.assertEquals(testTag, ((List) value).get(0));

        // add dynamically-named tag
        e = new Event(Collections.singletonMap(testTag, testTag2));
        CommonActions.addTag(e, Collections.singletonList("%{" + testTag + "}_foo"));
        value = e.getField(TAGS);
        Assert.assertTrue(value instanceof List);
        Assert.assertEquals(1, ((List) value).size());
        Assert.assertEquals(testTag2 + "_foo", ((List) value).get(0));

        // add non-string tag
        e = new Event();
        Long nonStringTag = 42L;
        CommonActions.addTag(e, Collections.singletonList(nonStringTag));
        value = e.getField(TAGS);
        Assert.assertTrue(value instanceof List);
        Assert.assertEquals(1, ((List) value).size());
        Assert.assertEquals(nonStringTag.toString(), ((List) value).get(0));
    }

    @Test
    public void testAddType() {
        // add tag to empty event
        Map<String, Object> e = new HashMap<>();
        String testType = "test_type";
        Map<String, Object> e2 = CommonActions.addType(e, testType);
        Assert.assertEquals(testType, e2.get("type"));

        // add type to already-typed event
        e = new HashMap<>();
        String existingType = "existing_type";
        e.put("type", existingType);
        e2 = CommonActions.addType(e, testType);
        Assert.assertEquals(existingType, e2.get("type"));
    }

    @Test
    public void testRemoveField() {
        // remove a field
        Event e = new Event();
        String testField = "test_field";
        String testValue = "test_value";
        e.setField(testField, testValue);
        CommonActions.removeField(e, Collections.singletonList(testField));
        Assert.assertFalse(e.getData().keySet().contains(testField));

        // remove non-existent field
        e = new Event();
        String testField2 = "test_field2";
        e.setField(testField2, testValue);
        CommonActions.removeField(e, Collections.singletonList(testField));
        Assert.assertFalse(e.getData().keySet().contains(testField));
        Assert.assertTrue(e.getData().keySet().contains(testField2));

        // remove multiple fields
        e = new Event();
        List<String> fields = new ArrayList<>();
        for (int k = 0; k < 3; k++) {
            String field = testField + k;
            e.setField(field, testValue);
            fields.add(field);
        }
        e.setField(testField, testValue);
        CommonActions.removeField(e, fields);
        for (String field : fields) {
            Assert.assertFalse(e.getData().keySet().contains(field));
        }
        Assert.assertTrue(e.getData().keySet().contains(testField));

        // remove dynamically-named field
        e = new Event();
        String otherField = "other_field";
        String otherValue = "other_value";
        e.setField(otherField, otherValue);
        String derivativeField = otherValue + "_foo";
        e.setField(derivativeField, otherValue);
        CommonActions.removeField(e, Collections.singletonList("%{" + otherField + "}_foo"));
        Assert.assertFalse(e.getData().keySet().contains(derivativeField));
        Assert.assertTrue(e.getData().keySet().contains(otherField));
    }

    @Test
    public void testRemoveTag() {

        // remove a tag
        Event e = new Event();
        String testTag = "test_tag";
        e.tag(testTag);
        CommonActions.removeTag(e, Collections.singletonList(testTag));
        Object o = e.getField(TAGS);
        Assert.assertTrue(o instanceof List);
        Assert.assertEquals(0, ((List) o).size());

        // remove non-existent tag
        e = new Event();
        e.tag(testTag);
        CommonActions.removeTag(e, Collections.singletonList(testTag + "non-existent"));
        o = e.getField(TAGS);
        Assert.assertTrue(o instanceof List);
        Assert.assertEquals(1, ((List) o).size());
        Assert.assertEquals(testTag, ((List) o).get(0));

        // remove multiple tags
        e = new Event();
        List<String> tags = new ArrayList<>();
        for (int k = 0; k < 3; k++) {
            String tag = testTag + k;
            tags.add(tag);
            e.tag(tag);
        }
        CommonActions.removeTag(e, tags);
        o = e.getField(TAGS);
        Assert.assertTrue(o instanceof List);
        Assert.assertEquals(0, ((List) o).size());

        // remove tags when "tags" fields isn't tags
        e = new Event();
        Long nonTagValue = 42L;
        try {
            e.setField(TAGS, nonTagValue);
        } catch (Event.InvalidTagsTypeException ex) {

        }

        CommonActions.removeTag(e, Collections.singletonList(testTag));
        o = e.getField(TAGS);
        Assert.assertFalse(o instanceof List);
        Assert.assertNull(o);

        // remove dynamically-named tag
        e = new Event();
        String otherField = "other_field";
        String otherValue = "other_value";
        e.setField(otherField, otherValue);
        e.tag(otherValue + "_foo");
        CommonActions.removeTag(e, Collections.singletonList("%{" + otherField + "}_foo"));
        o = e.getField(TAGS);
        Assert.assertTrue(o instanceof List);
        Assert.assertEquals(0, ((List) o).size());
    }

    @Test
    public void testRemoveFieldFromMetadata() {
        // remove a field
        Event e = new Event();
        String testField = "test_field";
        String testFieldRef = "[@metadata][" + testField + "]";
        String testValue = "test_value";
        e.setField(testFieldRef, testValue);
        CommonActions.removeField(e, Collections.singletonList(testFieldRef));
        Assert.assertFalse(e.getMetadata().keySet().contains(testField));

        // remove non-existent field
        e = new Event();
        String testField2 = "test_field2";
        String testField2Ref = "[@metadata][" + testField2 + "]";
        e.setField(testField2Ref, testValue);
        CommonActions.removeField(e, Collections.singletonList(testFieldRef));
        Assert.assertFalse(e.getMetadata().keySet().contains(testField));
        Assert.assertTrue(e.getMetadata().keySet().contains(testField2));

        // remove multiple fields
        e = new Event();
        List<String> fields = new ArrayList<>();
        List<String> fieldsRef = new ArrayList<>();
        for (int k = 0; k < 3; k++) {
            String field = testField + k;
            String fieldRef = "[@metadata][" + field + "]";
            e.setField(fieldRef, testValue);
            fields.add(field);
            fieldsRef.add(fieldRef);
        }
        e.setField(testFieldRef, testValue);
        CommonActions.removeField(e, fieldsRef);
        for (String field : fields) {
            Assert.assertFalse(e.getMetadata().keySet().contains(field));
        }
        Assert.assertTrue(e.getMetadata().keySet().contains(testField));

        // remove dynamically-named field
        e = new Event();
        String otherField = "other_field";
        String otherFieldRef = "[@metadata][" + otherField + "]";
        String otherValue = "other_value";
        e.setField(otherFieldRef, otherValue);
        String derivativeField = otherValue + "_foo";
        String derivativeFieldRef = "[@metadata][" + derivativeField + "]";
        e.setField(derivativeFieldRef, otherValue);
        CommonActions.removeField(e, Collections.singletonList("[@metadata][" + "%{" + otherField + "}_foo" + "]"));
        Assert.assertFalse(e.getMetadata().keySet().contains(derivativeField));
        Assert.assertTrue(e.getMetadata().keySet().contains(otherField));
    }
}
