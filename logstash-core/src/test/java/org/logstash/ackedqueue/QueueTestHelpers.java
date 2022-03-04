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

import java.io.IOException;
import org.logstash.ackedqueue.io.MmapPageIOV2;

/**
 * Class containing common methods to help DRY up acked queue tests.
 */
public class QueueTestHelpers {

    /**
     * Returns the {@link MmapPageIOV2} capacity required for the supplied element
     * @param element
     * @return int - capacity required for the supplied element
     * @throws IOException Throws if a serialization error occurs
     */
    public static int computeCapacityForMmapPageIO(final Queueable element) throws IOException {
        return computeCapacityForMmapPageIO(element, 1);
    }

    /**
     * Returns the {@link org.logstash.ackedqueue.io.MmapPageI} capacity require to hold a multiple elements including all headers and other metadata.
     * @param element
     * @return int - capacity required for the supplied number of elements
     * @throws IOException Throws if a serialization error occurs
     */
    public static int computeCapacityForMmapPageIO(final Queueable element, int count) throws IOException {
        return MmapPageIOV2.HEADER_SIZE + (count * (MmapPageIOV2.SEQNUM_SIZE + MmapPageIOV2.LENGTH_SIZE + element.serialize().length + MmapPageIOV2.CHECKSUM_SIZE));
    }
}
