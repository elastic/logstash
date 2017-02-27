package org.logstash;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.logstash.bivalues.NullBiValue;
import org.logstash.bivalues.StringBiValue;
import org.logstash.bivalues.TimeBiValue;
import org.logstash.bivalues.TimestampBiValue;
import org.logstash.ext.JrubyTimestampExtLibrary;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.joda.time.DateTime;
import org.jruby.RubySymbol;
import org.logstash.ackedqueue.Queueable;

import java.io.IOException;
import java.io.Serializable;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Date;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import static org.logstash.ObjectMappers.CBOR_MAPPER;
import static org.logstash.ObjectMappers.JSON_MAPPER;


public class Event implements Cloneable, Serializable, Queueable {

    private boolean cancelled;
    private Map<String, Object> data;
    private Map<String, Object> metadata;
    private Timestamp timestamp;
    private Accessors accessors;
    private Accessors metadata_accessors;

    public static final String METADATA = "@metadata";
    public static final String METADATA_BRACKETS = "[" + METADATA + "]";
    public static final String TIMESTAMP = "@timestamp";
    public static final String TIMESTAMP_FAILURE_TAG = "_timestampparsefailure";
    public static final String TIMESTAMP_FAILURE_FIELD = "_@timestamp";
    public static final String VERSION = "@version";
    public static final String VERSION_ONE = "1";
    private static final String DATA_MAP_KEY = "DATA";
    private static final String META_MAP_KEY = "META";
    private static final String SEQNUM_MAP_KEY = "SEQUENCE_NUMBER";


    private static final Logger logger = LogManager.getLogger(Event.class);
    private static final ObjectMapper mapper = new ObjectMapper();

    public Event()
    {
        this.metadata = new HashMap<String, Object>();
        this.data = new HashMap<String, Object>();
        this.data.put(VERSION, VERSION_ONE);
        this.cancelled = false;
        this.timestamp = new Timestamp();
        this.data.put(TIMESTAMP, this.timestamp);
        this.accessors = new Accessors(this.data);
        this.metadata_accessors = new Accessors(this.metadata);
    }

    public Event(Map data)
    {
        this.data = (Map<String, Object>)Valuefier.convert(data);

        if (!this.data.containsKey(VERSION)) {
            this.data.put(VERSION, VERSION_ONE);
        }

        if (this.data.containsKey(METADATA)) {
            this.metadata = (Map<String, Object>) this.data.remove(METADATA);
        } else {
            this.metadata = new HashMap<String, Object>();
        }
        this.metadata_accessors = new Accessors(this.metadata);

        this.cancelled = false;

        Object providedTimestamp = data.get(TIMESTAMP);
        // keep reference to the parsedTimestamp for tagging below
        Timestamp parsedTimestamp = initTimestamp(providedTimestamp);
        this.timestamp = (parsedTimestamp == null) ? Timestamp.now() : parsedTimestamp;

        this.data.put(TIMESTAMP, this.timestamp);
        this.accessors = new Accessors(this.data);

        // the tag() method has to be called after the Accessors initialization
        if (parsedTimestamp == null) {
            tag(TIMESTAMP_FAILURE_TAG);
            this.setField(TIMESTAMP_FAILURE_FIELD, providedTimestamp);
        }
    }

    public Map<String, Object> getData() {
        return this.data;
    }

    public Map<String, Object> getMetadata() {
        return this.metadata;
    }

    public void setData(Map<String, Object> data) {
        this.data = ConvertedMap.newFromMap(data);
    }

    public Accessors getAccessors() {
        return this.accessors;
    }

    public Accessors getMetadataAccessors() {
        return this.metadata_accessors;
    }

    public void setAccessors(Accessors accessors) {
        this.accessors = accessors;
    }

    public void setMetadataAccessors(Accessors accessors) {
        this.metadata_accessors = accessors;
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

    public Object getField(String reference) {
        Object val = getUnconvertedField(reference);
        return Javafier.deep(val);
    }

    public Object getUnconvertedField(String reference) {
        if (reference.equals(METADATA)) {
            return this.metadata;
        } else if (reference.startsWith(METADATA_BRACKETS)) {
            return this.metadata_accessors.get(reference.substring(METADATA_BRACKETS.length()));
        } else {
            return this.accessors.get(reference);
        }
    }

    public void setField(String reference, Object value) {
        if (reference.equals(TIMESTAMP)) {
            // TODO(talevy): check type of timestamp
            this.accessors.set(reference, value);
        } else if (reference.equals(METADATA_BRACKETS) || reference.equals(METADATA)) {
            this.metadata = (Map<String, Object>) value;
            this.metadata_accessors = new Accessors(this.metadata);
        } else if (reference.startsWith(METADATA_BRACKETS)) {
            this.metadata_accessors.set(reference.substring(METADATA_BRACKETS.length()), value);
        } else {
            this.accessors.set(reference, Valuefier.convert(value));
        }
    }

    public boolean includes(String reference) {
        if (reference.equals(METADATA_BRACKETS) || reference.equals(METADATA)) {
            return true;
        } else if (reference.startsWith(METADATA_BRACKETS)) {
            return this.metadata_accessors.includes(reference.substring(METADATA_BRACKETS.length()));
        } else {
            return this.accessors.includes(reference);
        }
    }

    public byte[] toBinary() throws IOException {
        return toBinaryFromMap(toSerializableMap());
    }

    private Map<String, Map<String, Object>> toSerializableMap() {
        HashMap<String, Map<String, Object>> hashMap = new HashMap<>();
        hashMap.put(DATA_MAP_KEY, this.data);
        hashMap.put(META_MAP_KEY, this.metadata);
        return hashMap;
    }

    private byte[] toBinaryFromMap(Map<String, Map<String, Object>> representation) throws IOException {
        return CBOR_MAPPER.writeValueAsBytes(representation);
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

    public static Event fromBinary(byte[] source) throws IOException {
        if (source == null || source.length == 0) {
            return new Event();
        }
        return fromSerializableMap(fromBinaryToMap(source));
    }

    private static Map<String, Map<String, Object>> fromBinaryToMap(byte[] source) throws IOException {
        Object o = CBOR_MAPPER.readValue(source, HashMap.class);
        if (o instanceof Map) {
            return (HashMap<String, Map<String, Object>>) o;
        } else {
            throw new IOException("incompatible from binary object type=" + o.getClass().getName() + " , only HashMap is supported");
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
                    throw new IOException("incompatible inner json array object type=" + e.getClass().getName() + " , only hash map is suppoted");
                }
                result[i++] = new Event((Map)e);
            }
        } else {
            throw new IOException("incompatible json object type=" + o.getClass().getName() + " , only hash map or arrays are suppoted");
        }

        return result;
    }

    public Map toMap() {
        return Cloner.deep(this.data);
    }

    public Event overwrite(Event e) {
        this.data = e.getData();
        this.accessors = e.getAccessors();
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

    public Object remove(String path) {
        return this.accessors.del(path);
    }

    public String sprintf(String s) throws IOException {
        return StringInterpolation.getInstance().evaluate(this, s);
    }

    public Event clone()
            throws CloneNotSupportedException
    {
//        Event clone = (Event)super.clone();
//        clone.setAccessors(new Accessors(clone.getData()));

        Event clone = new Event(Cloner.deep(getData()));
        return clone;
    }

    public String toString() {
        // TODO: (colin) clean this IOException handling, not sure why we bubble IOException here
        try {
            return (getTimestamp().toIso8601() + " " + this.sprintf("%{host} %{message}"));
        } catch (IOException e) {
            String host = (String)this.data.get("host");
            host = (host != null ? host : "%{host}");

            String message = (String)this.data.get("message");
            message = (message != null ? message : "%{message}");

            return (host + " " + message);
        }
    }

    private Timestamp initTimestamp(Object o) {
        try {
            if (o == null || o instanceof NullBiValue) {
                // most frequent
                return new Timestamp();
            } else if (o instanceof String) {
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

    public void tag(String tag) {
        List<Object> tags;
        Object _tags = this.getField("tags");

        // short circuit the null case where we know we won't need deduplication step below at the end
        if (_tags == null) {
            setField("tags", Arrays.asList(tag));
            return;
        }

        // assign to tags var the proper List of either the existing _tags List or a new List containing whatever non-List item was in the tags field
        if (_tags instanceof List) {
            tags = (List<Object>) _tags;
        } else {
            // tags field has a value but not in a List, convert in into a List
            tags = new ArrayList<>();
            tags.add(_tags);
        }

        // now make sure the tags list does not already contain the tag
        // TODO: we should eventually look into using alternate data structures to do more efficient dedup but that will require properly defining the tagging API too
        if (!tags.contains(tag)) {
            tags.add(tag);
        }

        // set that back as a proper BiValue
        this.setField("tags", tags);
    }

    public byte[] serialize() throws IOException {
        Map<String, Map<String, Object>> dataMap = toSerializableMap();
        return toBinaryFromMap(dataMap);
    }

    public byte[] serializeWithoutSeqNum() throws IOException {
        return toBinary();
    }

    public static Event deserialize(byte[] data) throws IOException {
        if (data == null || data.length == 0) {
            return new Event();
        }
        Map<String, Map<String, Object>> dataMap = fromBinaryToMap(data);
        return fromSerializableMap(dataMap);
    }
}
