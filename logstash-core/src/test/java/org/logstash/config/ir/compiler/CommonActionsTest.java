package org.logstash.config.ir.compiler;

import org.junit.Assert;
import org.junit.Test;
import org.logstash.Event;
import org.logstash.RubyUtil;
import org.logstash.ext.JrubyEventExtLibrary;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collections;
import java.util.List;

public class CommonActionsTest {

    private static final String TAGS = "tags";

    @Test
    public void testAddField() {
        // add field to empty event
        Event e = new Event();
        String testField = "test_field";
        String testStringValue = "test_value";
        CommonActions.addField(JrubyEventExtLibrary.RubyEvent.newRubyEvent(RubyUtil.RUBY, e),
                Collections.singletonMap(testField, testStringValue));
        Assert.assertEquals(testStringValue, e.getField(testField));

        // add to existing field and convert to array value
        e = new Event(Collections.singletonMap(testField, testStringValue));
        CommonActions.addField(JrubyEventExtLibrary.RubyEvent.newRubyEvent(RubyUtil.RUBY, e),
                Collections.singletonMap(testField, testStringValue));
        Object value = e.getField(testField);
        Assert.assertTrue(value instanceof List);
        Assert.assertEquals(2, ((List) value).size());
        Assert.assertEquals(testStringValue, ((List) value).get(0));
        Assert.assertEquals(testStringValue, ((List) value).get(1));

        // add to existing array field
        String testStringValue2 = "test_value2";
        List<String> stringVals = Arrays.asList(testStringValue, testStringValue2);
        e = new Event(Collections.singletonMap(testField, stringVals));
        CommonActions.addField(JrubyEventExtLibrary.RubyEvent.newRubyEvent(RubyUtil.RUBY, e),
                Collections.singletonMap(testField, testStringValue));
        value = e.getField(testField);
        Assert.assertTrue(value instanceof List);
        Assert.assertEquals(3, ((List) value).size());
        Assert.assertEquals(testStringValue, ((List) value).get(0));
        Assert.assertEquals(testStringValue2, ((List) value).get(1));
        Assert.assertEquals(testStringValue, ((List) value).get(2));

        // add non-string value to empty event
        Long testLongValue = 42L;
        e = new Event();
        CommonActions.addField(JrubyEventExtLibrary.RubyEvent.newRubyEvent(RubyUtil.RUBY, e),
                Collections.singletonMap(testField, testLongValue));
        Assert.assertEquals(testLongValue, e.getField(testField));

        // add non-string value to existing field
        e = new Event(Collections.singletonMap(testField, testStringValue));
        CommonActions.addField(JrubyEventExtLibrary.RubyEvent.newRubyEvent(RubyUtil.RUBY, e),
                Collections.singletonMap(testField, testLongValue));
        value = e.getField(testField);
        Assert.assertTrue(value instanceof List);
        Assert.assertEquals(2, ((List) value).size());
        Assert.assertEquals(testStringValue, ((List) value).get(0));
        Assert.assertEquals(testLongValue, ((List) value).get(1));

        // add non-string value to existing array field
        e = new Event(Collections.singletonMap(testField, stringVals));
        CommonActions.addField(JrubyEventExtLibrary.RubyEvent.newRubyEvent(RubyUtil.RUBY, e),
                Collections.singletonMap(testField, testLongValue));
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
        CommonActions.addField(JrubyEventExtLibrary.RubyEvent.newRubyEvent(RubyUtil.RUBY, e),
                Collections.singletonMap(newField, newValue));
        Assert.assertEquals(testStringValue + "_value", e.getField(testStringValue + "_field"));
    }

    @Test
    public void testAddTag() {

        // add tag to empty event
        Event e = new Event();
        String testTag = "test_tag";
        CommonActions.addTag(JrubyEventExtLibrary.RubyEvent.newRubyEvent(RubyUtil.RUBY, e),
                Collections.singletonList(testTag));
        Object value = e.getField(TAGS);
        Assert.assertTrue(value instanceof List);
        Assert.assertEquals(1, ((List) value).size());
        Assert.assertEquals(testTag, ((List) value).get(0));

        // add two tags to empty event
        e = new Event();
        String testTag2 = "test_tag2";
        CommonActions.addTag(JrubyEventExtLibrary.RubyEvent.newRubyEvent(RubyUtil.RUBY, e),
                Arrays.asList(testTag, testTag2));
        value = e.getField(TAGS);
        Assert.assertTrue(value instanceof List);
        Assert.assertEquals(2, ((List) value).size());
        Assert.assertEquals(testTag, ((List) value).get(0));
        Assert.assertEquals(testTag2, ((List) value).get(1));

        // add duplicate tag
        e = new Event();
        e.tag(testTag);
        CommonActions.addTag(JrubyEventExtLibrary.RubyEvent.newRubyEvent(RubyUtil.RUBY, e),
                Collections.singletonList(testTag));
        value = e.getField(TAGS);
        Assert.assertTrue(value instanceof List);
        Assert.assertEquals(1, ((List) value).size());
        Assert.assertEquals(testTag, ((List) value).get(0));

        // add dynamically-named tag
        e = new Event(Collections.singletonMap(testTag, testTag2));
        CommonActions.addTag(JrubyEventExtLibrary.RubyEvent.newRubyEvent(RubyUtil.RUBY, e),
                Collections.singletonList("%{" + testTag + "}_foo"));
        value = e.getField(TAGS);
        Assert.assertTrue(value instanceof List);
        Assert.assertEquals(1, ((List) value).size());
        Assert.assertEquals(testTag2 + "_foo", ((List) value).get(0));
    }

    @Test
    public void testAddType() {
        // add tag to empty event
        Event e = new Event();
        String testType = "test_type";
        CommonActions.addType(JrubyEventExtLibrary.RubyEvent.newRubyEvent(RubyUtil.RUBY, e), testType);
        Assert.assertEquals(testType, e.getField("type"));

        // add type to already-typed event
        e = new Event();
        String existingType = "existing_type";
        e.setField("type", existingType);
        CommonActions.addType(JrubyEventExtLibrary.RubyEvent.newRubyEvent(RubyUtil.RUBY, e), testType);
        Assert.assertEquals(existingType, e.getField("type"));
    }

    @Test
    public void testRemoveField() {
        // remove a field
        Event e = new Event();
        String testField = "test_field";
        String testValue = "test_value";
        e.setField(testField, testValue);
        CommonActions.removeField(JrubyEventExtLibrary.RubyEvent.newRubyEvent(RubyUtil.RUBY, e),
                Collections.singletonList(testField));
        Assert.assertFalse(e.getData().keySet().contains(testField));

        // remove non-existent field
        e = new Event();
        String testField2 = "test_field2";
        e.setField(testField2, testValue);
        CommonActions.removeField(JrubyEventExtLibrary.RubyEvent.newRubyEvent(RubyUtil.RUBY, e),
                Collections.singletonList(testField));
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
        CommonActions.removeField(JrubyEventExtLibrary.RubyEvent.newRubyEvent(RubyUtil.RUBY, e), fields);
        for (String field:fields) {
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
        CommonActions.removeField(JrubyEventExtLibrary.RubyEvent.newRubyEvent(RubyUtil.RUBY, e),
                Collections.singletonList("%{" + otherField + "}_foo"));
        Assert.assertFalse(e.getData().keySet().contains(derivativeField));
        Assert.assertTrue(e.getData().keySet().contains(otherField));
    }

    @Test
    public void testRemoveTag() {

        // remove a tag
        Event e = new Event();
        String testTag = "test_tag";
        e.tag(testTag);
        CommonActions.removeTag(JrubyEventExtLibrary.RubyEvent.newRubyEvent(RubyUtil.RUBY, e),
                Collections.singletonList(testTag));
        Object o = e.getField(TAGS);
        Assert.assertTrue(o instanceof List);
        Assert.assertEquals(0, ((List) o).size());

        // remove non-existent tag
        e = new Event();
        e.tag(testTag);
        CommonActions.removeTag(JrubyEventExtLibrary.RubyEvent.newRubyEvent(RubyUtil.RUBY, e),
                Collections.singletonList(testTag + "non-existent"));
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
        CommonActions.removeTag(JrubyEventExtLibrary.RubyEvent.newRubyEvent(RubyUtil.RUBY, e), tags);
        o = e.getField(TAGS);
        Assert.assertTrue(o instanceof List);
        Assert.assertEquals(0, ((List) o).size());

        // remove tags when "tags" fields isn't tags
        e = new Event();
        Long nonTagValue = 42L;
        e.setField(TAGS, nonTagValue);
        CommonActions.removeTag(JrubyEventExtLibrary.RubyEvent.newRubyEvent(RubyUtil.RUBY, e),
                Collections.singletonList(testTag));
        o = e.getField(TAGS);
        Assert.assertFalse(o instanceof List);
        Assert.assertEquals(nonTagValue, o);

        // remove dynamically-named tag
        e = new Event();
        String otherField = "other_field";
        String otherValue = "other_value";
        e.setField(otherField, otherValue);
        e.tag(otherValue + "_foo");
        CommonActions.removeTag(JrubyEventExtLibrary.RubyEvent.newRubyEvent(RubyUtil.RUBY, e),
                Collections.singletonList("%{" + otherField + "}_foo"));
        o = e.getField(TAGS);
        Assert.assertTrue(o instanceof List);
        Assert.assertEquals(0, ((List) o).size());
    }
}
