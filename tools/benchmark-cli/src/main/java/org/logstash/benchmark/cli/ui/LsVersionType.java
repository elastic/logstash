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


package org.logstash.benchmark.cli.ui;

/**
 * Enum of the various types of Logstash versions.
 */
public enum LsVersionType {
    /**
     * A local version of Logstash that is assumed to have all dependencies installed and/or build.
     */
    LOCAL,

    /**
     * A release version of Logstash to be downloaded from elastic.co mirrors.
     */
    DISTRIBUTION,

    /**
     * A version build from a given GIT tree hash/identifier.
     */
    GIT
}
