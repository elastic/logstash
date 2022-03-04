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


package org.logstash.config.ir;

import org.logstash.common.SourceWithMetadata;

/**
 * This class is useful to inherit from for things that need to be source components
 * since it handles storage of the meta property for you and reduces a lot of boilerplate.
 */
public abstract class BaseSourceComponent implements SourceComponent {
    private final SourceWithMetadata meta;

    public BaseSourceComponent(SourceWithMetadata meta) {
        this.meta = meta;
    }

    public SourceWithMetadata getSourceWithMetadata() {
        return meta;
    }

    public abstract boolean sourceComponentEquals(SourceComponent sourceComponent);

    public String toString(int indent) {
        return "toString(int indent) should be implemented for " + this.getClass().getName();
    }
}
