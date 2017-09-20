package org.logstash;

import java.io.IOException;
import java.util.ArrayList;
import java.util.Date;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.joda.time.DateTime;
import org.jruby.RubySymbol;
import org.logstash.ackedqueue.Queueable;
import org.logstash.bivalues.BiValues;
import org.logstash.bivalues.NullBiValue;
import org.logstash.bivalues.StringBiValue;
import org.logstash.bivalues.TimeBiValue;
import org.logstash.bivalues.TimestampBiValue;
import org.logstash.ext.JrubyTimestampExtLibrary;

import static org.logstash.ObjectMappers.CBOR_MAPPER;
import static org.logstash.ObjectMappers.JSON_MAPPER;

public final class Event implements Cloneable, Queueable {

    private boolean cancelled;
    private ConvertedMap data;
    private ConvertedMap metadata;
    private Timestamp timestamp;

    public static final String METADATA = "@metadata";
    public static final String METADATA_BRACKETS = "[" + METADATA + "]";
    public static final String TIMESTAMP = "@timestamp";
    public static final String TIMESTAMP_FAILURE_TAG = "_timestampparsefailure";
    public static final String TIMESTAMP_FAILURE_FIELD = "_@timestamp";
    public static final String VERSION = "@version";
    public static final String VERSION_ONE = "1";
    private static final String DATA_MAP_KEY = "DATA";
    private static final String META_MAP_KEY = "META";

    private static final FieldReference TAGS_FIELD = PathCache.cache("tags");
    
    private static final Logger logger = LogManager.getLogger(Event.class);

    public Event()
    {
        this.metadata = new ConvertedMap(10);
        this.data = new ConvertedMap(10);
        this.data.put(VERSION, VERSION_ONE);
        this.cancelled = false;
        this.timestamp = new Timestamp();
        this.data.put(TIMESTAMP, this.timestamp);
    }

    /**
     * Constructor from a map that will be copied and the copy will have its contents converted to
     * Java objects.
     * @param data Map that is assumed to have either {@link String} or {@link org.jruby.RubyString}
     * keys and may contain Java and Ruby objects.
     */
    public Event(Map data) {
        this(ConvertedMap.newFromMap(data));
    }

    /**
     * Constructor wrapping a {@link ConvertedMap} without copying it. Any changes this instance
     * makes to its underlying data will be propagated to it.
     * @param data Converted Map
     */
    public Event(ConvertedMap data) {
        this.data = data;
        if (!this.data.containsKey(VERSION)) {
            this.data.put(VERSION, VERSION_ONE);
        }

        if (this.data.containsKey(METADATA)) {
            this.metadata = ConvertedMap.newFromMap((Map) this.data.remove(METADATA));
        } else {
            this.metadata = new ConvertedMap(10);
        }
        this.cancelled = false;

        Object providedTimestamp = data.get(TIMESTAMP);
        // keep reference to the parsedTimestamp for tagging below
        Timestamp parsedTimestamp = initTimestamp(providedTimestamp);
        this.timestamp = (parsedTimestamp == null) ? Timestamp.now() : parsedTimestamp;
        Accessors.set(data, FieldReference.TIMESTAMP_REFERENCE, timestamp);
        // the tag() method has to be called after the Accessors initialization
        if (parsedTimestamp == null) {
            tag(TIMESTAMP_FAILURE_TAG);
            this.setField(TIMESTAMP_FAILURE_FIELD, providedTimestamp);
        }
    }

    public ConvertedMap getData() {
        return this.data;
    }

    public ConvertedMap getMetadata() {
        return this.metadata;
    }

    public void cancel() {
        this.cancelled = true;
    }

    public void uncancel() {
        this.cancelled = false;
    }

    public boolean isCancelled() {
        return this.cancelled;
    }

    public Timestamp getTimestamp() throws IOException {
        if (this.data.containsKey(TIMESTAMP)) {
            return this.timestamp;
        } else {
            throw new IOException("fails");
        }
    }

    public void setTimestamp(Timestamp t) {
        this.timestamp = t;
        this.data.put(TIMESTAMP, this.timestamp);
    }

    public Object getField(final String reference) {
        final Object unconverted = getUnconvertedField(PathCache.cache(reference));
        return unconverted == null ? null : Javafier.deep(unconverted);
    }

    public Object getUnconvertedField(final String reference) {
        return getUnconvertedField(PathCache.cache(reference));
    }

    public Object getUnconvertedField(final FieldReference field) {
        switch (field.type()) {
            case FieldReference.META_PARENT:
                return this.metadata;
            case FieldReference.META_CHILD:
                return Accessors.get(metadata, field);
            default:
                return Accessors.get(data, field);
        }
    }

    public void setField(final String reference, final Object value) {
        setField(PathCache.cache(reference), value);
    }

    public void setField(final FieldReference field, final Object value) {
        switch (field.type()) {
            case FieldReference.META_PARENT:
                this.metadata = ConvertedMap.newFromMap((Map) value);
                break;
            case FieldReference.META_CHILD:
                Accessors.set(metadata, field, value);
                break;
            default:
                Accessors.set(data, field, Valuefier.convert(value));
        }
    }

    public boolean includes(final String field) {
        return includes(PathCache.cache(field));
    }

    public boolean includes(final FieldReference field) {
        switch (field.type()) {
            case FieldReference.META_PARENT:
                return true;
            case FieldReference.META_CHILD:
                return Accessors.includes(metadata, field);
            default:
                return Accessors.includes(data, field);
        }
    }

    private Map<String, Map<String, Object>> toSerializableMap() {
        HashMap<String, Map<String, Object>> hashMap = new HashMap<>();
        hashMap.put(DATA_MAP_KEY, this.data);
        hashMap.put(META_MAP_KEY, this.metadata);
        return hashMap;
    }

    private static Event fromSerializableMap(Map<String, Map<String, Object>> representation) throws IOException{
        if (!representation.containsKey(DATA_MAP_KEY)) {
            throw new IOException("The deserialized Map must contain the \"DATA\" key");
        }
        if (!representation.containsKey(META_MAP_KEY)) {
            throw new IOException("The deserialized Map must contain the \"META\" key");
        }
        Map<String, Object> dataMap = representation.get(DATA_MAP_KEY);
        dataMap.put(METADATA, representation.get(META_MAP_KEY));
        return new Event(dataMap);
    }

    private static Map<String, Map<String, Object>> fromBinaryToMap(byte[] source) throws IOException {
        Object o = CBOR_MAPPER.readValue(source, HashMap.class);
        if (o == null) {
            throw new IOException("incompatible from binary object type only HashMap is supported");
        } else {
            return (Map<String, Map<String, Object>>) o;
        }
    }

    public String toJson()
            throws IOException
    {
        return JSON_MAPPER.writeValueAsString(this.data);
    }

    public static Event[] fromJson(String json)
            throws IOException
    {
        // empty/blank json string does not generate an event
        if (json == null || json.trim().isEmpty()) {
            return new Event[]{ };
        }

        Event[] result;
        Object o = JSON_MAPPER.readValue(json, Object.class);
        // we currently only support Map or Array json objects
        if (o instanceof Map) {
            result = new Event[]{ new Event((Map)o) };
        } else if (o instanceof List) {
            result = new Event[((List) o).size()];
            int i = 0;
            for (Object e : (List)o) {
                if (!(e instanceof Map)) {
                    throw new IOException("incompatible inner json array object type=" + e.getClass().getName() + " , only hash map is supported");
                }
                result[i++] = new Event((Map)e);
            }
        } else {
            throw new IOException("incompatible json object type=" + o.getClass().getName() + " , only hash map or arrays are supported");
        }

        return result;
    }

    public Map toMap() {
        return Cloner.deep(this.data);
    }

    public Event overwrite(Event e) {
        this.data = e.getData();
        this.cancelled = e.isCancelled();
        try {
            this.timestamp = e.getTimestamp();
        } catch (IOException exception) {
            this.timestamp = new Timestamp();
        }

        return this;
    }

    public Event append(Event e) {
        Util.mapMerge(this.data, e.data);

        return this;
    }

    public Object remove(final String path) {
        return remove(PathCache.cache(path));
    }

    public Object remove(final FieldReference field) {
        return Accessors.del(data, field);
    }

    public String sprintf(String s) throws IOException {
        return StringInterpolation.evaluate(this, s);
    }

    @Override
    public Event clone() {
        final ConvertedMap map =
            ConvertedMap.newFromMap(Cloner.<Map<String, Object>>deep(data));
        map.put(METADATA, Cloner.<Map<String, Object>>deep(metadata));
        return new Event(map);
    }

    public String toString() {
        Object hostField = this.getField("host");
        Object messageField = this.getField("message");
        String hostMessageString = (hostField != null ? hostField.toString() : "%{host}") + " " + (messageField != null ? messageField.toString() : "%{message}");

        try {
            // getTimestamp throws an IOException if there is no @timestamp field, see #7613
            return getTimestamp().toIso8601() + " " + hostMessageString;
        } catch (IOException e) {
            return hostMessageString;
        }
    }

    private static Timestamp initTimestamp(Object o) {
        if (o == null || o instanceof NullBiValue) {
            // most frequent
            return new Timestamp();
        } else {
            return parseTimestamp(o);
        }
    }

    /**
     * Cold path of {@link Event#initTimestamp(Object)}.
     * @param o Object to parse Timestamp out of
     * @return Parsed {@link Timestamp} or {@code null} on failure
     */
    private static Timestamp parseTimestamp(final Object o) {
        try {
            if (o instanceof String) {
                // second most frequent
                return new Timestamp((String) o);
            } else if (o instanceof StringBiValue) {
                return new Timestamp(((StringBiValue) o).javaValue());
            } else if (o instanceof TimeBiValue) {
                return new Timestamp(((TimeBiValue) o).javaValue());
            } else if (o instanceof JrubyTimestampExtLibrary.RubyTimestamp) {
                return new Timestamp(((JrubyTimestampExtLibrary.RubyTimestamp) o).getTimestamp());
            } else if (o instanceof Timestamp) {
                return new Timestamp((Timestamp) o);
            } else if (o instanceof TimestampBiValue) {
                return new Timestamp(((TimestampBiValue) o).javaValue());
            } else if (o instanceof DateTime) {
                return new Timestamp((DateTime) o);
            } else if (o instanceof Date) {
                return new Timestamp((Date) o);
            } else if (o instanceof RubySymbol) {
                return new Timestamp(((RubySymbol) o).asJavaString());
            } else {
                logger.warn("Unrecognized " + TIMESTAMP + " value type=" + o.getClass().toString());
            }
        } catch (IllegalArgumentException e) {
            logger.warn("Error parsing " + TIMESTAMP + " string value=" + o.toString());
        }
        return null;
    }

    public void tag(final String tag) {
        final Object tags = Accessors.get(data, TAGS_FIELD);
        // short circuit the null case where we know we won't need deduplication step below at the end
        if (tags == null) {
            initTag(tag);
        } else {
            existingTag(Javafier.deep(tags), tag);
        }
    }

    /**
     * Branch of {@link Event#tag(String)} that handles adding the first tag to this event.
     * @param tag Tag to add
     */
    private void initTag(final String tag) {
        final ConvertedList list = new ConvertedList(1);
        list.add(BiValues.newBiValue(tag));
        Accessors.set(data, TAGS_FIELD, list);
    }

    /**
     * Branch of {@link Event#tag(String)} that handles adding to existing tags.
     * @param tags Existing Tag(s)
     * @param tag Tag to add
     */
    private void existingTag(final Object tags, final String tag) {
        if (tags instanceof List) {
            appendTag((List<String>) tags, tag);
        } else {
            scalarTagFallback((String) tags, tag);
        }
    }

    /**
     * Merge the given tag into the given list of existing tags if the list doesn't already contain
     * the tag.
     * @param tags Existing tag list
     * @param tag Tag to add
     */
    private void appendTag(final List<String> tags, final String tag) {
        // TODO: we should eventually look into using alternate data structures to do more efficient dedup but that will require properly defining the tagging API too
        if (!tags.contains(tag)) {
            tags.add(tag);
            Accessors.set(data, TAGS_FIELD, ConvertedList.newFromList((List) tags));
        }
    }

    /**
     * Fallback for {@link Event#tag(String)} in case "tags" was populated by just a String value
     * and needs to be converted to a list before appending to it.
     * @param existing Existing Tag
     * @param tag Tag to add
     */
    private void scalarTagFallback(final String existing, final String tag) {
        final List<String> tags = new ArrayList<>(2);
        tags.add(existing);
        appendTag(tags, tag);
    }

    @Override
    public byte[] serialize() throws IOException {
        return CBOR_MAPPER.writeValueAsBytes(toSerializableMap());
    }

    public static Event deserialize(byte[] data) throws IOException {
        if (data == null || data.length == 0) {
            return new Event();
        }
        return fromSerializableMap(fromBinaryToMap(data));
    }
}
