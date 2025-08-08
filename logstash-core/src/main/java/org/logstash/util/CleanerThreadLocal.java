package org.logstash.util;

import java.lang.ref.Cleaner;
import java.util.Objects;
import java.util.function.Consumer;
import java.util.function.Supplier;

/**
 * A {@link CleanerThreadLocal} is semantically the same as a {@link ThreadLocal}, except that a clean action
 * is called against each object when the {@link CleanerThreadLocal} no longer holds a reference to it.
 * @param <T> the external value type
 */
public final class CleanerThreadLocal<T> {
    private final ThreadLocal<CleanableHolder> threadLocal;
    private final Consumer<T> cleanAction;
    private final Cleaner cleaner;

    private CleanerThreadLocal(final Cleaner cleaner,
                               final Supplier<T> factory,
                               final Consumer<T> cleanAction) {
        this.cleaner = cleaner;
        this.cleanAction = cleanAction;
        this.threadLocal = ThreadLocal.withInitial(() -> wrap(factory.get()));
    }

    public T get() {
        return unwrap(threadLocal.get());
    }

    public void set(final T value) {
        threadLocal.set(wrap(value));
    }

    public void remove() {
        threadLocal.remove();
    }

    private T unwrap(final CleanableHolder holder) {
        if (holder == null) {
            return null;
        }
        return holder.getDelegate();
    }

    private CleanableHolder wrap(final T value) {
        if (value == null) {
            return null;
        }
        return new CleanableHolder(value, this.cleanAction);
    }

    public static <T> Factory<T> withInitial(final Supplier<T> initialValueSupplier) {
        return new Factory<>(initialValueSupplier);
    }

    public static <T> CleanerThreadLocal<T> withCleanAction(final Consumer<T> cleanAction) {
        return new Factory<T>().withCleanAction(cleanAction);
    }

    public static <T> CleanerThreadLocal<T> withCleanAction(final Consumer<T> cleanAction, final Cleaner cleaner) {
        return new Factory<T>().withCleanAction(cleanAction, cleaner);
    }

    public static class Factory<T> {
        private final Supplier<T> initialValueSupplier;

        private Factory() {
            this.initialValueSupplier = () -> null;
        }

        private Factory(final Supplier<T> initialValueSupplier) {
            this.initialValueSupplier = Objects.requireNonNull(initialValueSupplier);
        }

        public CleanerThreadLocal<T> withCleanAction(final Consumer<T> cleanAction) {
            return withCleanAction(cleanAction, Cleaner.create());
        }

        public CleanerThreadLocal<T> withCleanAction(final Consumer<T> cleanAction, final Cleaner cleaner) {
            return new CleanerThreadLocal<>(Objects.requireNonNullElseGet(cleaner, Cleaner::create), initialValueSupplier, cleanAction);
        }
    }

    private class CleanableHolder {
        private final T delegate;

        static class CleaningAction<T> implements Runnable {
            private final T delegate;
            private final Consumer<T> cleanAction;

            CleaningAction(final T delegate,
                           final Consumer<T> cleanAction) {
                this.delegate = delegate;
                this.cleanAction = cleanAction;
            }

            @Override
            public void run() {
                if (delegate != null) {
                    cleanAction.accept(delegate);
                }
            }
        }

        private CleanableHolder(final T delegate,
                                final Consumer<T> finalizer) {
            this.delegate = delegate;
            cleaner.register(this, new CleaningAction<T>(delegate, finalizer));
        }

        private T getDelegate() {
            return delegate;
        }
    }
}