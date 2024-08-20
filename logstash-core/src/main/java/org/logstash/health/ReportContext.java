package org.logstash.health;

import java.util.ArrayList;
import java.util.List;
import java.util.function.Consumer;

/**
 * A {@code ReportContext} is used when building an {@link Indicator.Report} to provide contextual configuration
 * for a specific {@link Indicator} that is being reported on.
 */
public class ReportContext {
    private final List<String> path;

    public static final ReportContext EMPTY = new ReportContext(List.of());

    ReportContext(final List<String> path) {
        this.path = List.copyOf(path);
    }

    public ReportContext descend(final String node) {
        final ArrayList<String> newPath = new ArrayList<>(path);
        newPath.add(node);
        return new ReportContext(newPath);
    }

    public void descend(final String node, final Consumer<ReportContext> consumer) {
        consumer.accept(this.descend(node));
    }

    public boolean isMuted(final String childNodeName) {
        return false;
    }

    @Override
    public String toString() {
        return "ReportContext{" +
                "path=" + path +
                '}';
    }
}
