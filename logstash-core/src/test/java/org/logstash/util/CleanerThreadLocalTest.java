package org.logstash.util;

import org.junit.Test;
import org.hamcrest.FeatureMatcher;
import org.hamcrest.Matcher;

import java.util.Collection;
import java.util.HashSet;
import java.util.Set;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicBoolean;
import java.util.concurrent.atomic.AtomicInteger;
import java.util.concurrent.atomic.AtomicReference;

import static org.hamcrest.MatcherAssert.assertThat;
import static org.hamcrest.Matchers.*;

import static org.junit.Assert.assertTrue;

public class CleanerThreadLocalTest {
    @Test
    public void testWithExecutorService() throws Exception {
        final int threads = 100;
        final int iterations = 10_000;
        final ResourceFactory resourceFactory = new ResourceFactory();
        final CleanerThreadLocal<ResourceFactory.Resource> threadLocal = CleanerThreadLocal
                .withInitial(resourceFactory::create)
                .withCleanAction(ResourceFactory.Resource::closeAction);

        assertThat(resourceFactory.getAll(), hasSize(0));

        final ExecutorService executorService = Executors.newFixedThreadPool(threads);
        for (int i = 0; i < iterations; i++) {
            executorService.submit(() -> threadLocal.get().incrementAccessCounter());
        }

        // while the threads are alive, we should not have cleaned up
        assertThat(resourceFactory.getAll(), allOf(
                everyItem(isClosed(is(equalTo(false)))),
                everyItem(closeCount(is(equalTo(0))))
        ));

        // shutdown and wait; this should kill the threads and empty the threadlocal
        executorService.shutdown();
        assertTrue(executorService.awaitTermination(10, TimeUnit.SECONDS));

        // make sure each of the threads got a resource, and that no resource was accessed cross-threads
        assertThat(resourceFactory.getAll(), hasSize(threads));
        assertThat(resourceFactory.getAll(), everyItem(accessThreadOrigins(hasSize(1))));

        // validate that all iterations completed
        Integer totalAccesses = resourceFactory.getAll().stream().map((resource -> resource.accessCounter.get())).reduce(0, Integer::sum);
        assertThat(totalAccesses, equalTo(iterations));

        // ensure that the cleanup actions were executed
        bruteForceGC();
        assertThat(resourceFactory.getAll(), allOf(
                everyItem(isClosed(is(equalTo(true)))),
                everyItem(closeCount(is(equalTo(1))))
        ));
    }

    static Matcher<ResourceFactory.Resource> isClosed(Matcher<Boolean> closedMatcher) {
        return new FeatureMatcher<ResourceFactory.Resource, Boolean>(closedMatcher, "a resource", "closed") {
            @Override
            protected Boolean featureValueOf(ResourceFactory.Resource resource) {
                return resource.isClosed();
            }
        };
    }


    static Matcher<ResourceFactory.Resource> closeCount(Matcher<Integer> closeCountMatcher) {
        return new FeatureMatcher<ResourceFactory.Resource, Integer>(closeCountMatcher, "a resource", "close count") {
            @Override
            protected Integer featureValueOf(ResourceFactory.Resource resource) {
                return resource.closeCounter.get();
            }
        };
    }

    static Matcher<ResourceFactory.Resource> accessThreadOrigins(Matcher<Collection<?>> threadOriginsMatcher) {
        return new FeatureMatcher<ResourceFactory.Resource, Collection<Long>>(threadOriginsMatcher, "a resource", "access thread origins") {
            @Override
            protected Collection<Long> featureValueOf(ResourceFactory.Resource resource) {
                return resource.threadIds.get();
            }
        };
    }

    private void bruteForceGC() throws Exception {
        for (int i = 0; i < 100; i++) {
            System.gc();
            Thread.sleep(10);
        }
    }

    static class ResourceFactory {
        private AtomicReference<Set<Resource>> resources = new AtomicReference<>(Set.of());
        protected AtomicInteger counter = new AtomicInteger();

        public Resource create() {
            final Resource resource = new Resource();
            resources.updateAndGet((existing) -> immutableSetAdd(existing, resource));
            return resource;
        }

        public Set<Resource> getAll() {
            return resources.get();
        }

        class Resource {
            private final int id = counter.incrementAndGet();

            private final AtomicInteger accessCounter = new AtomicInteger();
            private final AtomicInteger closeCounter = new AtomicInteger();
            private final AtomicBoolean closed = new AtomicBoolean();

            private final AtomicReference<Set<Long>> threadIds = new AtomicReference<>(Set.of());

            public int getId() {
                return id;
            }

            public void incrementAccessCounter() {
                if (closed.get()) {
                    throw new IllegalStateException("closed");
                }
                threadIds.updateAndGet((existing) -> immutableSetAdd(existing, getCurrentThreadId()));
                accessCounter.incrementAndGet();
            }

            @SuppressWarnings("deprecation")
            private static long getCurrentThreadId() {
                // [JEP-425](https://openjdk.org/jeps/425) introduced `Thread#threadId()` to replace `Thread#getId()`
                // in Java 19
                return Thread.currentThread().getId();
            }

            public void closeAction() {
                closeCounter.incrementAndGet();
                closed.set(true);
            }

            public boolean isClosed() {
                return closed.get();
            }
        }

        <T> Set<T> immutableSetAdd(Set<T> existing, T item) {
            final Set<T> mutable = new HashSet<>(existing);
            mutable.add(item);
            return Set.copyOf(mutable);
        }
    }
}