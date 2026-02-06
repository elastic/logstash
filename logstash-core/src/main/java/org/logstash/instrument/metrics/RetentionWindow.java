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

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

import java.lang.invoke.MethodHandles;
import java.lang.invoke.VarHandle;
import java.time.Duration;
import java.util.Objects;
import java.util.Optional;
import java.util.concurrent.atomic.AtomicReference;
import java.util.function.BiConsumer;
import java.util.function.BiFunction;

/**
 * A {@link RetentionWindow} efficiently holds sufficient {@link DatapointCapture}s to
 * meet its {@link FlowMetricRetentionPolicy}, providing access to the youngest capture
 * that is older than the policy's allowed retention (if any), and to the youngest capture.
 * The implementation is similar to a singly-linked list whose youngest captures are at
 * the tail and oldest captures are at the head, with an additional pre-tail stage.
 * Compaction is always done at read-time and occasionally at write-time.
 * Both reads and writes are non-blocking and concurrency-safe.
 */
abstract class RetentionWindow<CAPTURE extends DatapointCapture, VALUE> {
    static final Logger LOGGER = LogManager.getLogger(RetentionWindow.class);

    private final AtomicReference<NodeStagingPair<CAPTURE>> tail;
    private final AtomicReference<Node<CAPTURE>> head;
    final FlowMetricRetentionPolicy policy;

    RetentionWindow(final FlowMetricRetentionPolicy policy, final CAPTURE zeroCapture) {
        this.policy = policy;
        final Node<CAPTURE> zeroNode = Node.detached(zeroCapture);
        this.head = new AtomicReference<>(zeroNode);
        this.tail = new AtomicReference<>(NodeStagingPair.ofNode(zeroNode));
    }

    /**
     * @param oldCapture the base capture
     * @param newCapture a new capture to apply on top of the base
     * @return a {@link CAPTURE} representing both provided captures
     */
    abstract CAPTURE mergeCaptures(final CAPTURE oldCapture, final CAPTURE newCapture);

    /**
     * @return a calculated value
     */
    abstract Optional<VALUE> calculateValue();

    /**
     * Append the newest {@link DatapointCapture} into this {@link RetentionWindow},
     * while respecting our {@link FlowMetricRetentionPolicy}.
     * We tolerate minor jitter in the provided {@link DatapointCapture#nanoTime()}, but
     * expect callers of this method to minimize lag between instantiating the capture
     * and appending it.
     *
     * @param newestCapture the newest capture to stage
     */
    void append(final CAPTURE newestCapture) {
        final NodeStagingPair.Mutable<CAPTURE> newTailWithStaging = new NodeStagingPair.Mutable<>();

        // atomically replace our tail with our new capture applied
        NodeStagingPair<CAPTURE> oldTailWithStaging = this.tail.getAndUpdate((committedNodeStagePair) -> {
            newTailWithStaging.reset(); // after a lost race, our new tail-stage will be dirty
            applyCaptureWithStaging(committedNodeStagePair, newestCapture, newTailWithStaging::set);
            return newTailWithStaging;
        });

        // re-attach the tail to the previous tail if we severed it
        if (oldTailWithStaging.committed != newTailWithStaging.committed) {
            oldTailWithStaging.committed.setNext(newTailWithStaging.committed);
        }

        // occasional force compaction
        final Node<CAPTURE> currentHead = this.head.get();
        if (currentHead.captureNanoTime() > policy.forceCompactionBarrierNanos(newestCapture.nanoTime())) {
            final Node<CAPTURE> compactHead = compactHead(policy.retentionBarrierNanos(newestCapture.nanoTime()));
            if (LOGGER.isDebugEnabled()) {
                final long compactHeadAgeNanos = Math.subtractExact(newestCapture.nanoTime(), compactHead.captureNanoTime());
                LOGGER.debug("{} forced-compaction result (captures: `{}` span: `{}`)", this, estimateSize(compactHead), Duration.ofNanos(compactHeadAgeNanos));
            }
        }
    }

    /**
     * Applies a capture to the existing committed tail-with-staging, handling the details of committed vs staged.
     * This method is expected to be side-effect free, since it may be run multiple times in the event of a lost race.
     *
     * @param committedTailWithStaging the currently-committed tail
     * @param newestCapture            our newest capture, to be merged or promoted
     * @param resultNodeStageConsumer  a consumer of the {@code nodeToCommit}/{@code captureToStage} pair
     */
    private void applyCaptureWithStaging(final NodeStagingPair<CAPTURE> committedTailWithStaging,
                                         final CAPTURE newestCapture,
                                         final BiConsumer<Node<CAPTURE>, CAPTURE> resultNodeStageConsumer) {
        final Node<CAPTURE> committedNode = committedTailWithStaging.committed;
        final CAPTURE committedCapture = committedNode.capture;
        final CAPTURE stagedCapture = committedTailWithStaging.staged;

        final Node<CAPTURE> nodeToCommit;
        final CAPTURE captureToStage;

        if (Objects.nonNull(stagedCapture) && (Objects.isNull(committedCapture) || committedCapture.nanoTime() < policy.commitBarrierNanos(newestCapture.nanoTime()))) {
            // if we have a staged capture that is worth committing, rotate.
            nodeToCommit = Node.detached(stagedCapture);
            captureToStage = newestCapture;
        } else if (Objects.isNull(committedCapture)) {
            // if we don't have a commit yet, just commit what we have
            nodeToCommit = Node.detached(newestCapture);
            captureToStage = null;
        } else {
            // otherwise merge newest into our stage
            nodeToCommit = committedNode;
            captureToStage = mergeCaptures(stagedCapture, newestCapture);
        }

        resultNodeStageConsumer.accept(nodeToCommit, captureToStage);
    }

    @Override
    public String toString() {
        return "RetentionWindow{" +
                "policy=" + policy.policyName() +
                " id=" + System.identityHashCode(this) +
                '}';
    }

    /**
     * @return the youngest capture, which might be uncommitted.
     */
    private CAPTURE youngestCapture() {
        NodeStagingPair<CAPTURE> captureNodeStagingPair = this.tail.get();
        if (Objects.nonNull(captureNodeStagingPair.staged)) {
            return captureNodeStagingPair.staged;
        }
        if (Objects.nonNull(captureNodeStagingPair.committed)) {
            return captureNodeStagingPair.committed.capture;
        }
        return null;
    }

    /**
     * @param referenceNanoTime the reference time
     * @return the *youngest* capture that is older than this window's retention policy
     */
    private CAPTURE baselineCapture(long referenceNanoTime) {
        final long barrier = policy.retentionBarrierNanos(referenceNanoTime);
        final CAPTURE capture = compactHead(barrier).capture;

        if (capture.nanoTime() <= barrier || policy.reportBeforeSatisfied()) {
            return capture;
        } else {
            return null;
        }
    }

    /**
     *
     * @param transform a {@link BiFunction}{@code (compareCapture, baselineCapture)}
     * @return the transformed result
     * @param <V> the {@code transform} return type
     */
    public <V> V calculateFromBaseline(final BaselineCompareFunction<CAPTURE, V> transform) {
        final CAPTURE youngestCapture = youngestCapture();
        if (youngestCapture == null) { return transform.apply(null, null); }

        final CAPTURE baselineCapture = baselineCapture(youngestCapture.nanoTime());
        return transform.apply(youngestCapture, baselineCapture);
    }

    @FunctionalInterface
    public interface BaselineCompareFunction<CAPTURE, V> extends BiFunction<CAPTURE, CAPTURE, V> {
        @Override
        V apply(CAPTURE compareCapture, CAPTURE baselineCapture);
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
    private Node<CAPTURE> compactHead(final long barrier) {
        return this.head.updateAndGet((existingHead) -> {
            final Node<CAPTURE> proposedHead = existingHead.seekWithoutCrossing(barrier);
            return Objects.requireNonNullElse(proposedHead, existingHead);
        });
    }

    /**
     * Internal testing support
     */
    long excessRetained(final long barrierNanos) {
        return Math.max(0L, Math.subtractExact(barrierNanos, this.head.getPlain().captureNanoTime()));
    }

    /**
     * A {@link Node} holds a single {@link DatapointCapture} and
     * may link ahead to the next {@link Node}.
     * It is an implementation detail of {@link RetentionWindow}.
     */
    private static class Node<CAPTURE extends DatapointCapture> {
        private static final VarHandle NEXT;

        static {
            try {
                MethodHandles.Lookup l = MethodHandles.lookup();
                NEXT = l.findVarHandle(Node.class, "next", Node.class);
            } catch (ReflectiveOperationException e) {
                throw new ExceptionInInitializerError(e);
            }
        }

        static <CAPTURE extends DatapointCapture> Node<CAPTURE> detached(final CAPTURE capture) {
            return new Node<>(capture);
        }

        private final CAPTURE capture;
        private volatile Node<CAPTURE> next;

        Node(final CAPTURE capture) {
            this.capture = capture;
        }

        Node<CAPTURE> seekWithoutCrossing(final long barrier) {
            Node<CAPTURE> newestOlderThanThreshold = null;
            Node<CAPTURE> candidate = this;

            while (candidate != null && candidate.captureNanoTime() < barrier) {
                newestOlderThanThreshold = candidate;
                candidate = candidate.getNext();
            }
            return newestOlderThanThreshold;
        }

        long captureNanoTime() {
            return this.capture.nanoTime();
        }

        void setNext(final Node<CAPTURE> nextNode) {
            next = nextNode;
        }

        Node<CAPTURE> getNext() {
            return next;
        }

        Node<CAPTURE> getNextPlain() {
            return (Node<CAPTURE>) NEXT.get(this);
        }

        @Override
        public String toString() {
            return "Node{" +
                    "capture=" + capture +
                    ", next=" + next +
                    '}';
        }
    }

    private static class NodeStagingPair<CAPTURE extends DatapointCapture> {
        protected Node<CAPTURE> committed;
        protected CAPTURE staged;

        private static <CAPTURE extends DatapointCapture> NodeStagingPair<CAPTURE> ofNode(final Node<CAPTURE> node) {
            NodeStagingPair.Mutable<CAPTURE> tStaging = new NodeStagingPair.Mutable<>();
            tStaging.set(node, null);
            return tStaging;
        }

        private static class Mutable<CAPTURE extends DatapointCapture> extends NodeStagingPair<CAPTURE> {
            void set(final Node<CAPTURE> committed, final CAPTURE staged) {
                this.committed = committed;
                this.staged = staged;
            }
            void reset() {
                this.committed = null;
                this.staged = null;
            }
        }
    }

}
