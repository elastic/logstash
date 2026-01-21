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

package org.logstash.instrument.metrics;

import java.lang.invoke.MethodHandles;
import java.lang.invoke.VarHandle;
import java.time.Duration;
import java.util.Objects;
import java.util.Optional;
import java.util.concurrent.atomic.AtomicReference;
import java.util.function.ToLongFunction;

/**
 * A {@link RetentionWindow} efficiently holds sufficient {@link DatapointCapture}s to
 * meet its {@link FlowMetricRetentionPolicy}, providing access to the youngest capture
 * that is older than the policy's allowed retention (if any).
 * The implementation is similar to a singly-linked list whose youngest captures are at
 * the tail and oldest captures are at the head, with an additional pre-tail stage.
 * Compaction is always done at read-time and occasionally at write-time.
 * Both reads and writes are non-blocking and concurrency-safe.
 */
abstract class RetentionWindow<T extends DatapointCapture> {
//    private final AtomicReference<T> stagedCapture = new AtomicReference<>();
    private final AtomicReference<Staging<T>> tail;
    private final AtomicReference<Node<T>> head;
    final FlowMetricRetentionPolicy policy;

    RetentionWindow(final FlowMetricRetentionPolicy policy, final T zeroCapture) {
        this.policy = policy;
        final Node<T> zeroNode = new Node<>(zeroCapture);
        this.head = new AtomicReference<>(zeroNode);
        this.tail = new AtomicReference<>(Staging.ofNode(zeroNode));
    }

    abstract CommitStagedPair<T> mux(CommitStagedPair<T> existing, T newCapture);

    /**
     * Internal tooling to select the younger of two captures provided.
     */
    static <T extends DatapointCapture> T selectNewestCaptureOf(final T existing, final T proposed) {
        if (existing == null) {
            return proposed;
        }
        if (proposed == null) {
            return existing;
        }

        return (existing.nanoTime() > proposed.nanoTime()) ? existing : proposed;
    }

    /**
     * Append the newest {@link DatapointCapture} into this {@link RetentionWindow},
     * while respecting our {@link FlowMetricRetentionPolicy}.
     * We tolerate minor jitter in the provided {@link DatapointCapture#nanoTime()}, but
     * expect callers of this method to minimize lag between instantiating the capture
     * and appending it.
     *
     * @param newestCapture the newest capture to stage
     */
    void append(final T newestCapture) {
        final Staging<T> newTailWithStaging = new Staging<>();

        Staging<T> oldTailWithStaging = this.tail.getAndAccumulate(newTailWithStaging, (committed, staging) -> {
            final CommitStagedPair<T> result = mux(committed.asCommitStaged(), newestCapture);
            Node<T> committedNode = Objects.equals(committed.committed.capture, result.committed) ? committed.committed : new Node<>(result.committed);
            newTailWithStaging.set(committedNode, result.staged);
            return newTailWithStaging;
        });

        // re-attach the tail if we severed it
        if (oldTailWithStaging.committed != newTailWithStaging.committed) {
            oldTailWithStaging.committed.setNext(newTailWithStaging.committed);
        }

        // occasional force compaction
        final Node<T> currentHead = this.head.get();
        if (Math.subtractExact(newestCapture.nanoTime(), currentHead.captureNanoTime()) > policy.forceCompactionNanos()) {
            final Node<T> compactHead = compactHead(Math.subtractExact(newestCapture.nanoTime(), policy.retentionNanos()));
            if (ExtendedFlowMetric.LOGGER.isDebugEnabled()) {
                final long compactHeadAgeNanos = Math.subtractExact(newestCapture.nanoTime(), compactHead.captureNanoTime());
                ExtendedFlowMetric.LOGGER.debug("{} forced-compaction result (captures: `{}` span: `{}`)", this, estimateSize(compactHead), Duration.ofNanos(compactHeadAgeNanos));
            }
        }
    }

    @Override
    public String toString() {
        return "RetentionWindow{" +
                "policy=" + policy.policyName() +
                " id=" + System.identityHashCode(this) +
                '}';
    }

    public Optional<T> returnHead(long nanoTime) {
        final long barrier = Math.subtractExact(nanoTime, policy.retentionNanos());
        final RetentionWindow.Node<T> head = compactHead(barrier);
        T capture = head.capture;
        if (capture.nanoTime() <= barrier) {
            return Optional.of(capture);
        } else {
            return Optional.empty();
        }
    }

    /**
     * @return a computationally-expensive estimate of the number of captures in this window,
     * using plain memory access. This should NOT be run in unguarded production code.
     */
    private static <T extends DatapointCapture> int estimateSize(final Node<T> headNode) {
        int i = 1; // assume we have one additional staged
        // NOTE: we chase the provided headNode's tail with plain-gets,
        //       which tolerates missed appends from other threads.
        for (Node<T> current = headNode; current != null; current = current.getNextPlain()) {
            i++;
        }
        return i;
    }

    /**
     * @see RetentionWindow#estimateSize(Node)
     */
    int estimateSize() {
        return estimateSize(this.head.getPlain());
    }

    /**
     * @param barrier a nanoTime that will NOT be crossed during compaction
     * @return the head node after compaction up to the provided barrier.
     */
    private Node<T> compactHead(final long barrier) {
        return this.head.updateAndGet((existingHead) -> {
            final Node<T> proposedHead = existingHead.seekWithoutCrossing(barrier);
            return Objects.requireNonNullElse(proposedHead, existingHead);
        });
    }

    /**
     * Internal testing support
     */
    long excessRetained(final long currentNanoTime, final ToLongFunction<FlowMetricRetentionPolicy> retentionWindowFunction) {
        final long barrier = Math.subtractExact(currentNanoTime, retentionWindowFunction.applyAsLong(this.policy));
        return Math.max(0L, Math.subtractExact(barrier, this.head.getPlain().captureNanoTime()));
    }

    /**
     * A {@link Node} holds a single {@link DatapointCapture} and
     * may link ahead to the next {@link Node}.
     * It is an implementation detail of {@link RetentionWindow}.
     */
    private static class Node<T extends DatapointCapture> {
        private static final VarHandle NEXT;

        static {
            try {
                MethodHandles.Lookup l = MethodHandles.lookup();
                NEXT = l.findVarHandle(Node.class, "next", Node.class);
            } catch (ReflectiveOperationException e) {
                throw new ExceptionInInitializerError(e);
            }
        }

        private final T capture;
        private volatile Node<T> next;

        Node(final T capture) {
            this.capture = capture;
        }

        Node<T> seekWithoutCrossing(final long barrier) {
            Node<T> newestOlderThanThreshold = null;
            Node<T> candidate = this;

            while (candidate != null && candidate.captureNanoTime() < barrier) {
                newestOlderThanThreshold = candidate;
                candidate = candidate.getNext();
            }
            return newestOlderThanThreshold;
        }

        long captureNanoTime() {
            return this.capture.nanoTime();
        }

        void setNext(final Node<T> nextNode) {
            next = nextNode;
        }

        Node<T> getNext() {
            return next;
        }

        Node<T> getNextPlain() {
            return (Node<T>) NEXT.get(this);
        }
    }

    private static class Staging<T extends DatapointCapture> {
        private Node<T> committed;
        private T staged;

        static <T extends DatapointCapture> Staging<T> ofNode(final Node<T> node) {
            Staging<T> tStaging = new Staging<>();
            tStaging.set(node, null);
            return tStaging;
        }

        void set(final Node<T> committed, final T staged) {
            this.committed = committed;
            this.staged = staged;
        }

        CommitStagedPair<T> asCommitStaged() {
            return new CommitStagedPair<>(committed.capture, staged);
        }
    }

    record CommitStagedPair<T extends DatapointCapture>(T committed, T staged) {
        static <T extends DatapointCapture> CommitStagedPair<T> commitOnly(final T committed) {
            return new CommitStagedPair<>(committed, null);
        }
    }
}
