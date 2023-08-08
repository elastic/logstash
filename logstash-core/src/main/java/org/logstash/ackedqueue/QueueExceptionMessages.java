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

/**
 * A public class holds number of descriptive messages are used during the interaction with acked queue.
 */
public class QueueExceptionMessages {

    public final static String CANNOT_READ_FROM_CLOSED_QUEUE = "Attempted to read on a closed acked queue.";

    public final static String CANNOT_WRITE_TO_CLOSED_QUEUE = "Tried to write to a closed queue.";

    public final static String BIGGER_DATA_THAN_PAGE_SIZE = "data to be written is bigger than page capacity";

    public final static String CANNOT_CREATE_QUEUE_DIR = "Error creating queue directories.";

    public final static String CANNOT_DESERIALIZE = "cannot find deserialize method on class ";

    public final static String UNHANDLED_ERROR_WRITING_TO_QUEUE = "Unhandleable error occurred while writing to queue.";

    public final static String CANNOT_READ_PAGE_WITHOUT_LOCK = "Cannot get next read page without first acquiring the lock.";

}
