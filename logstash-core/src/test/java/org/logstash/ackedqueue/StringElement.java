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


package org.logstash.ackedqueue;

import java.nio.ByteBuffer;

public class StringElement implements Queueable {
    private final String content;

    public StringElement(String content) {
        this.content = content;
    }

    @Override
    public byte[] serialize() {
        byte[] contentBytes = this.content.getBytes();
        ByteBuffer buffer = ByteBuffer.allocate(contentBytes.length);
        buffer.put(contentBytes);
        return buffer.array();
    }

    public static StringElement deserialize(byte[] bytes) {
        ByteBuffer buffer = ByteBuffer.allocate(bytes.length);
        buffer.put(bytes);

        buffer.position(0);
        byte[] content = new byte[bytes.length];
        buffer.get(content);
        return new StringElement(new String(content));
    }

    @Override
    public String toString() {
        return content;
    }


    @Override
    public boolean equals(Object other) {
        if (other == null) {
            return false;
        }
        if (!StringElement.class.isAssignableFrom(other.getClass())) {
            return false;
        }

        final StringElement element = (StringElement)other;
        if ((this.content == null) ? (element.content != null) : !this.content.equals(element.content)) {
            return false;
        }
        return true;
    }

    @Override
    public int hashCode() {
        int hash = 13;
        hash = 53 * hash + (this.content != null ? this.content.hashCode() : 0);
        return hash;
    }
}
