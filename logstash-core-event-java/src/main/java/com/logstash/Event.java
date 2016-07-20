package com.logstash;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.logstash.bivalues.NullBiValue;
import com.logstash.bivalues.StringBiValue;
import com.logstash.bivalues.TimeBiValue;
import com.logstash.bivalues.TimestampBiValue;
import com.logstash.ext.JrubyTimestampExtLibrary;
import org.joda.time.DateTime;
import org.jruby.RubySymbol;

import java.io.IOException;
import java.io.Serializable;
import java.util.ArrayList;
import java.util.Date;
import java.util.HashMap;
import java.util.List;
import java.util.Map;


public class Event implements Cloneable, Serializable {

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

    private static final Logger DEFAULT_LOGGER = new StdioLogger();
    private static final ObjectMapper mapper = new ObjectMapper();

    // logger is static since once set there is no point in changing it at runtime
    // for other reasons than in tests/specs.
    private transient static Logger logger = DEFAULT_LOGGER;

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
        this.timestamp = initTimestamp(data.get(TIMESTAMP));
        this.data.put(TIMESTAMP, this.timestamp);
        this.accessors = new Accessors(this.data);
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

    public String toJson()
            throws IOException
    {
        return mapper.writeValueAsString(this.data);
    }

    public static Event[] fromJson(String json)
            throws IOException
    {
        // empty/blank json string does not generate an event
        if (json == null || json.trim().isEmpty()) {
            return new Event[]{ };
        }

        Event[] result;
        Object o = mapper.readValue(json, Object.class);
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
                Event.logger.warn("Unrecognized " + TIMESTAMP + " value type=" + o.getClass().toString());
            }
        } catch (IllegalArgumentException e) {
            Event.logger.warn("Error parsing " + TIMESTAMP + " string value=" + o.toString());
        }

        tag(TIMESTAMP_FAILURE_TAG);
        this.data.put(TIMESTAMP_FAILURE_FIELD, o);

        return Timestamp.now();
    }

    public void tag(String tag) {
        List<Object> tags = (List<Object>) this.data.get("tags");
        if (tags == null) {
            tags = new ArrayList<>();
            this.data.put("tags", tags);
        }

        if (!tags.contains(tag)) {
            tags.add(tag);
        }
    }

    // Event.logger is static since once set there is no point in changing it at runtime
    // for other reasons than in tests/specs.
    public static void setLogger(Logger logger) {
        Event.logger = logger;
    }
}
