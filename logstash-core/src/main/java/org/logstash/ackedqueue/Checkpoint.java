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
 * Persistent queue chekpoint. There is one checkpoint per queue, and simply it's a picture of some
 * management data like first not acked sequence number.
 *
 * */
public class Checkpoint {
//    Checkpoint file structure see FileCheckpointIO

    public static final int VERSION = 1;

    private final int pageNum;             // local per-page page number
    private final int firstUnackedPageNum; // queue-wide global pointer, only valid in the head checkpoint
    private final long firstUnackedSeqNum; // local per-page unacknowledged tracking
    private final long minSeqNum;          // local per-page minimum seqNum
    private final int elementCount;        // local per-page element count


    public Checkpoint(int pageNum, int firstUnackedPageNum, long firstUnackedSeqNum, long minSeqNum, int elementCount) {
        this.pageNum = pageNum;
        this.firstUnackedPageNum = firstUnackedPageNum;
        this.firstUnackedSeqNum = firstUnackedSeqNum;
        this.minSeqNum = minSeqNum;
        this.elementCount = elementCount;
    }

    public int getPageNum() {
        return this.pageNum;
    }

    public int getFirstUnackedPageNum() {
        return this.firstUnackedPageNum;
    }

    public long getFirstUnackedSeqNum() {
        return this.firstUnackedSeqNum;
    }

    public long getMinSeqNum() {
        return this.minSeqNum;
    }

    public int getElementCount() {
        return this.elementCount;
    }

    // @return true if this checkpoint indicates a fulle acked page
    public boolean isFullyAcked() {
        return this.elementCount > 0 && this.firstUnackedSeqNum >= this.minSeqNum + this.elementCount;
    }

    // @return the highest seqNum in this page or -1 for an initial checkpoint
    public long maxSeqNum() {
        return this.minSeqNum + this.elementCount - 1;
    }

    public String toString() {
        return "pageNum=" + this.pageNum + ", firstUnackedPageNum=" + this.firstUnackedPageNum + ", firstUnackedSeqNum=" + this.firstUnackedSeqNum + ", minSeqNum=" + this.minSeqNum + ", elementCount=" + this.elementCount + ", isFullyAcked=" + (this.isFullyAcked() ? "yes" : "no");
    }

    public boolean equals(Checkpoint other) {
        if (this == other ) { return true; }
        return (this.pageNum == other.pageNum && this.firstUnackedPageNum == other.firstUnackedPageNum && this.firstUnackedSeqNum == other.firstUnackedSeqNum && this.minSeqNum == other.minSeqNum && this.elementCount == other.elementCount);
    }

}
