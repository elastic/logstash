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
package org.logstash.health;

import com.google.common.collect.Iterables;

import java.util.EnumSet;

public class HealthObserver {
    public final Status getStatus() {
        // INTERNAL-ONLY Proof-of-concept to show flow-through to API results
        switch (System.getProperty("logstash.apiStatus", "green")) {
            case "green":  return Status.GREEN;
            case "yellow": return Status.YELLOW;
            case "red":    return Status.RED;
            case "random":
                final EnumSet<Status> statuses = EnumSet.allOf(Status.class);
                return Iterables.get(statuses, new java.util.Random().nextInt(statuses.size()));
            default:
                return Status.UNKNOWN;
        }
    }
}
