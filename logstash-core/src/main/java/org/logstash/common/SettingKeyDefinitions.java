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

package org.logstash.common;

/**
 * A class to contain Logstash setting definitions broadly used in the Java scope.
 */
public class SettingKeyDefinitions {

    public static final String PIPELINE_ID = "pipeline.id";

    public static final String PIPELINE_WORKERS = "pipeline.workers";

    public static final String PIPELINE_BATCH_SIZE = "pipeline.batch.size";

    public static final String PATH_QUEUE = "path.queue";

    public static final String QUEUE_PAGE_CAPACITY = "queue.page_capacity";

    public static final String QUEUE_MAX_EVENTS = "queue.max_events";

    public static final String QUEUE_CHECKPOINT_WRITES = "queue.checkpoint.writes";

    public static final String QUEUE_CHECKPOINT_ACKS = "queue.checkpoint.acks";

    public static final String QUEUE_CHECKPOINT_INTERVAL = "queue.checkpoint.interval";

    public static final String QUEUE_CHECKPOINT_RETRY = "queue.checkpoint.retry";

    public static final String QUEUE_MAX_BYTES = "queue.max_bytes";
}