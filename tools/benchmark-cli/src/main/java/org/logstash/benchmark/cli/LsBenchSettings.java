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


package org.logstash.benchmark.cli;

/**
 * Class holding setting constants.
 */
public final class LsBenchSettings {

    /**
     * Name of the property holding the URL to download the dataset used by
     * {@link org.logstash.benchmark.cli.cases.ApacheLogsComplex} from.
     */
    public static final String APACHE_DATASET_URL = "org.logstash.benchmark.apache.dataset.url";

    /**
     * Property that sets how often the input dataset is to be repeated.
     */
    public static final String INPUT_DATA_REPEAT = "org.logstash.benchmark.input.repeat";
}
