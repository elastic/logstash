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

import org.logstash.ackedqueue.io.PageIO;

import java.io.IOException;
import java.util.BitSet;
import java.util.Objects;

class PageFactory {

    /**
     * create a new head page object and new page.{@literal {pageNum}} empty valid data file
     *
     * @param pageNum the new head page page number
     * @param queue the {@link Queue} instance
     * @param pageIO the {@link PageIO} delegate
     * @return {@link Page} the new head page
     */
    public static Page newHeadPage(int pageNum, Queue queue, PageIO pageIO) {
        return new Page(pageNum, queue, 0, 0, 0, ackedSeqNums(null), pageIO, true);
    }

    /**
     * create a new head page from an existing {@link Checkpoint} and open page.{@literal {pageNum}} empty valid data file
     *
     * @param checkpoint existing head page {@link Checkpoint}
     * @param queue the {@link Queue} instance
     * @param pageIO the {@link PageIO} delegate
     * @return {@link Page} the new head page
     */
    public static Page newHeadPage(Checkpoint checkpoint, Queue queue, PageIO pageIO) throws IOException {
        assert checkpoint.getMinSeqNum() == pageIO.getMinSeqNum() && checkpoint.getElementCount() == pageIO.getElementCount() :
                String.format("checkpoint minSeqNum=%d or elementCount=%d is different than pageIO minSeqNum=%d or elementCount=%d", checkpoint.getMinSeqNum(), checkpoint.getElementCount(), pageIO.getMinSeqNum(), pageIO.getElementCount());

        return new Page(
                checkpoint.getPageNum(),
                queue,
                checkpoint.getMinSeqNum(),
                checkpoint.getElementCount(),
                checkpoint.getFirstUnackedSeqNum(),
                ackedSeqNums(checkpoint),
                pageIO,
                true
        );
    }

    /**
     * create a new tail page for an exiting Checkpoint and data file
     *
     * @param checkpoint existing tail page {@link Checkpoint}
     * @param queue the {@link Queue} instance
     * @param pageIO the {@link PageIO} delegate
     * @return {@link Page} the new tail page
     */
    public static Page newTailPage(Checkpoint checkpoint, Queue queue, PageIO pageIO) throws IOException {
        return new Page(
                checkpoint.getPageNum(),
                queue,
                checkpoint.getMinSeqNum(),
                checkpoint.getElementCount(),
                checkpoint.getFirstUnackedSeqNum(),
                ackedSeqNums(checkpoint),
                pageIO,
                false
        );
    }

    private static BitSet ackedSeqNums(final Checkpoint checkpoint) {
        final BitSet ackedSeqNums = new BitSet();

        if (Objects.nonNull(checkpoint) && checkpoint.getFirstUnackedSeqNum() > checkpoint.getMinSeqNum()) {
            ackedSeqNums.set(0, (int) (checkpoint.getFirstUnackedSeqNum() - checkpoint.getMinSeqNum()));
        }

        return ackedSeqNums;
    }
}
