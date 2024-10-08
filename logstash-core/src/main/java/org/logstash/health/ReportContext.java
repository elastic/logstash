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

import java.util.ArrayList;
import java.util.List;
import java.util.function.Consumer;

/**
 * A {@code ReportContext} is used when building an {@link Indicator.Report} to provide contextual configuration
 * for a specific {@link Indicator} that is being reported on.
 */
public class ReportContext {
    private final List<String> path;

    public static final ReportContext EMPTY = new ReportContext(List.of());

    ReportContext(final List<String> path) {
        this.path = List.copyOf(path);
    }

    public ReportContext descend(final String node) {
        final ArrayList<String> newPath = new ArrayList<>(path);
        newPath.add(node);
        return new ReportContext(newPath);
    }

    public void descend(final String node, final Consumer<ReportContext> consumer) {
        consumer.accept(this.descend(node));
    }

    public boolean isMuted(final String childNodeName) {
        return false;
    }

    @Override
    public String toString() {
        return "ReportContext{" +
                "path=" + path +
                '}';
    }
}
