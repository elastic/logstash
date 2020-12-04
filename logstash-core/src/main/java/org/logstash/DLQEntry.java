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


/*
 * Licensed to Elasticsearch under one or more contributor
 * license agreements. See the NOTICE file distributed with
 * this work for additional information regarding copyright
 * ownership. Elasticsearch licenses this file to you under
 * the Apache License, Version 2.0 (the "License"); you may
 * not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */

package org.logstash;

import java.io.IOException;
import java.nio.ByteBuffer;
import org.logstash.ackedqueue.Queueable;

/**
 * Dead letter queue item
 */
public class DLQEntry implements Cloneable, Queueable {

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
        ByteBuffer buffer = ByteBuffer.allocate(entryTimeInBytes.length
                + eventInBytes.length
                + pluginTypeBytes.length
                + pluginIdBytes.length
                + reasonBytes.length
                + (Integer.BYTES * 5)); // magic number represents the five byte[] + lengths
        putLengthAndBytes(buffer, entryTimeInBytes);
        putLengthAndBytes(buffer, eventInBytes);
        putLengthAndBytes(buffer, pluginTypeBytes);
        putLengthAndBytes(buffer, pluginIdBytes);
        putLengthAndBytes(buffer, reasonBytes);
        return buffer.array();
    }

    public static DLQEntry deserialize(byte[] bytes) throws IOException {
        ByteBuffer buffer = ByteBuffer.allocate(bytes.length);
        buffer.put(bytes);
        buffer.position(0);

        Timestamp entryTime = new Timestamp(new String(getLengthPrefixedBytes(buffer)));
        Event event = Event.deserialize(getLengthPrefixedBytes(buffer));
        String pluginType = new String(getLengthPrefixedBytes(buffer));
        String pluginId = new String(getLengthPrefixedBytes(buffer));
        String reason = new String(getLengthPrefixedBytes(buffer));

        return new DLQEntry(event, pluginType, pluginId, reason, entryTime);
    }

    private static void putLengthAndBytes(ByteBuffer buffer, byte[] bytes) {
        buffer.putInt(bytes.length);
        buffer.put(bytes);
    }

    private static byte[] getLengthPrefixedBytes(ByteBuffer buffer) {
        int length = buffer.getInt();
        byte[] bytes = new byte[length];
        buffer.get(bytes);
        return bytes;
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

    @Override
    public String toString() {
        return "DLQEntry{" +
                "event=" + event +
                ", pluginType='" + pluginType + '\'' +
                ", pluginId='" + pluginId + '\'' +
                ", reason='" + reason + '\'' +
                ", entryTime=" + entryTime +
                '}';
    }
}
