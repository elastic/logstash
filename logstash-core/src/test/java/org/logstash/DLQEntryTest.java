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

import org.junit.Test;

import java.util.Collections;

import static net.javacrumbs.jsonunit.JsonAssert.assertJsonEquals;
import static org.hamcrest.MatcherAssert.assertThat;
import static org.hamcrest.core.IsEqual.equalTo;
import static org.junit.Assert.assertNotNull;

public class DLQEntryTest extends RubyTestBase {
    @Test
    public void testConstruct() throws Exception {
        Event event = new Event(Collections.singletonMap("key", "value"));
        DLQEntry entry = new DLQEntry(event, "type", "id", "reason");
        assertThat(entry.getEvent(), equalTo(event));
        assertNotNull(entry.getEntryTime());
        assertThat(entry.getPluginType(), equalTo("type"));
        assertThat(entry.getPluginId(), equalTo("id"));
        assertThat(entry.getReason(), equalTo("reason"));
    }

    @Test
    public void testSerDe() throws Exception {
        Event event = new Event(Collections.singletonMap("key", "value"));
        DLQEntry expected = new DLQEntry(event, "type", "id", "reason");
        byte[] bytes = expected.serialize();
        DLQEntry actual = DLQEntry.deserialize(bytes);
        assertJsonEquals(actual.getEvent().toJson(), event.toJson());
        assertThat(actual.getEntryTime().toString(), equalTo(expected.getEntryTime().toString()));
        assertThat(actual.getPluginType(), equalTo("type"));
        assertThat(actual.getPluginId(), equalTo("id"));
        assertThat(actual.getReason(), equalTo("reason"));
    }
}
