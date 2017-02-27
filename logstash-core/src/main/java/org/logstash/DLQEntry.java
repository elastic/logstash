package org.logstash;

import org.logstash.ackedqueue.Queueable;

import java.io.IOException;
import java.io.Serializable;
import java.nio.ByteBuffer;


public class DLQEntry implements Cloneable, Serializable, Queueable {

    private final Event event;
    private final String pluginType;
    private final String pluginId;
    private final String reason;
    private final Timestamp entryTime;

    public DLQEntry(Event event, String pluginType, String pluginId, String reason) {
        this(event, pluginType, pluginId, reason, Timestamp.now());
    }

    public DLQEntry(Event event, String pluginType, String pluginId, String reason, Timestamp entryTime) {
        this.event = event;
        this.pluginType = pluginType;
        this.pluginId = pluginId;
        this.reason = reason;
        this.entryTime = entryTime;
    }

    @Override
    public byte[] serialize() throws IOException {
        byte[] entryTimeInBytes = entryTime.serialize();
        byte[] eventInBytes = this.event.serialize();
        byte[] pluginTypeBytes = pluginType.getBytes();
        byte[] pluginIdBytes = pluginId.getBytes();
        byte[] reasonBytes = reason.getBytes();
        ByteBuffer buffer = ByteBuffer.allocate(eventInBytes.length + pluginTypeBytes.length +
                pluginIdBytes.length + reasonBytes.length + (Integer.BYTES * 4));
        buffer.put(entryTimeInBytes);
        buffer.putInt(eventInBytes.length);
        buffer.put(eventInBytes);
        buffer.putInt(pluginTypeBytes.length);
        buffer.put(pluginTypeBytes);
        buffer.putInt(pluginIdBytes.length);
        buffer.put(pluginIdBytes);
        buffer.putInt(reasonBytes.length);
        buffer.put(reasonBytes);
        return buffer.array();
    }

    public static DLQEntry deserialize(byte[] bytes) throws IOException {
        ByteBuffer buffer = ByteBuffer.allocate(bytes.length);
        buffer.put(bytes);
        buffer.position(0);

        byte[] entryTimeBytes = new byte[24];
        buffer.get(entryTimeBytes);
        Timestamp entryTime = new Timestamp(new String(entryTimeBytes));

        int eventLength = buffer.getInt();
        byte[] eventBytes = new byte[eventLength];
        buffer.get(eventBytes);
        Event event = Event.deserialize(eventBytes);

        int pluginTypeLength = buffer.getInt();
        byte[] pluginTypeBytes = new byte[pluginTypeLength];
        buffer.get(pluginTypeBytes);
        String pluginType = new String(pluginTypeBytes);

        int pluginIdLength = buffer.getInt();
        byte[] pluginIdBytes = new byte[pluginIdLength];
        buffer.get(pluginIdBytes);
        String pluginId = new String(pluginIdBytes);

        int reasonLength = buffer.getInt();
        byte[] reasonBytes = new byte[reasonLength];
        buffer.get(reasonBytes);
        String reason = new String(reasonBytes);

        return new DLQEntry(event, pluginType, pluginId, reason, entryTime);
    }

    public Event getEvent() {
        return event;
    }

    public String getPluginType() {
        return pluginType;
    }

    public String getPluginId() {
        return pluginId;
    }

    public String getReason() {
        return reason;
    }

    public Timestamp getEntryTime() {
        return entryTime;
    }
}
