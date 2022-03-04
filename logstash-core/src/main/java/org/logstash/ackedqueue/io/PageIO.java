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


package org.logstash.ackedqueue.io;

import org.logstash.ackedqueue.SequencedList;

import java.io.Closeable;
import java.io.IOException;

/**
 * Internal API to access pages stored in files.
 * */
public interface PageIO extends Closeable {

    // the concrete class should be constructed with the pageNum, capacity and dirPath attributes
    // and open/recover/create must first be called to setup with physical data file
    //
    // TODO: we should probably refactor this with a factory to force the creation of a fully
    //       initialized concrete object with either open/recover/create instead of allowing
    //       a partially initialized object using the concrete class constructor. Not sure.

    // open an existing data container and reconstruct internal state if required
    void open(long minSeqNum, int elementCount) throws IOException;

    // optimistically recover an existing data container and reconstruct internal state
    // with the actual read/recovered data. this is only useful when reading a head page
    // data file since tail pages are read-only.
    void recover() throws IOException;

    // create a new empty data file
    void create() throws IOException;

    // verify if the data container has space for the given number of bytes
    boolean hasSpace(int bytes);

    // write the given bytes to the data container
    void write(byte[] bytes, long seqNum) throws IOException;

    // read up to limit number of items starting at give seqNum
    SequencedList<byte[]> read(long seqNum, int limit) throws IOException;

    // @return the data container total capacity in bytes
    int getCapacity();

    // @return the current head offset within the page
    int getHead();

    // @return the actual persisted byte count (with overhead) for the given data bytes
    int persistedByteCount(int bytes);

    // signal that this data page is not active and resources can be released
    void deactivate() throws IOException;

    // signal that this data page is active will be read or written to
    // should do nothing if page is aready active
    void activate() throws IOException;

    // issue the proper data container "fsync" sematic
    void ensurePersisted();

    // delete/unlink/remove data file
    void purge() throws IOException;

    // @return the data container elements count
    int getElementCount();

    // @return the data container min sequence number
    long getMinSeqNum();

    // check if the page size is < minimum size
    boolean isCorruptedPage() throws IOException;
}
