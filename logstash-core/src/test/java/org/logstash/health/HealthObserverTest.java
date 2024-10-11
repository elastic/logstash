package org.logstash.health;

import org.hamcrest.Matchers;
import org.junit.Test;

import java.util.Objects;

import static org.hamcrest.MatcherAssert.assertThat;
import static org.logstash.health.HealthObserver.FORCE_API_STATUS_PROPERTY;

public class HealthObserverTest {

    private final HealthObserver healthObserver = new HealthObserver();

    @Test
    public void testStatusWhenNotForcedPropagates() {
        withUnsetSystemProperty(FORCE_API_STATUS_PROPERTY, () -> {
            for (Status reportStatus : Status.values()) {
                withIndicator(new TestIndicator(reportStatus), () -> {
                    assertThat(String.format("Status[%s] should propagate", reportStatus), healthObserver.getStatus(), Matchers.is(reportStatus));
                });
            }
        });
    }

    @Test
    public void testStatusWhenForcedGreenEmitsGreen() {
        withSystemProperty(FORCE_API_STATUS_PROPERTY, "green", () -> {
            for (Status reportStatus : Status.values()) {
                withIndicator(new TestIndicator(reportStatus), () -> {
                    assertThat(String.format("Status[%s] should not propagate", reportStatus), healthObserver.getStatus(), Matchers.is(Status.GREEN));
                });
            }
        });
    }

    @Test
    public void testStatusWhenForcedNonsensePropagates() {
        withSystemProperty(FORCE_API_STATUS_PROPERTY, "nonsense", () -> {
            for (Status reportStatus : Status.values()) {
                withIndicator(new TestIndicator(reportStatus), () -> {
                    assertThat(String.format("Status[%s] should propagate", reportStatus), healthObserver.getStatus(), Matchers.is(reportStatus));
                });
            }
        });
    }

    void withUnsetSystemProperty(final String propertyName, final Runnable action) {
        withSystemProperty(propertyName, null, action);
    }

    void withSystemProperty(final String name, final String value, final Runnable action) {
        synchronized (System.class) {
            final String oldValue;
            if (Objects.isNull(value)) {
                oldValue = System.clearProperty(name);
            } else {
                oldValue = System.setProperty(name, value);
            }
            try {
                action.run();
            } finally {
                if (oldValue != null) {
                    System.setProperty(name, oldValue);
                } else {
                    System.clearProperty(name);
                }
            }
        }
    }

    void withIndicator(Indicator<?> indicator, Runnable runnable) {
        this.healthObserver.getIndicator().attachIndicator("single", indicator);
        try {
            runnable.run();
        } finally {
            this.healthObserver.getIndicator().detachIndicator("single", indicator);
        }
    }

    static class TestIndicator implements Indicator<Indicator.Report> {
        private final Status status;

        public TestIndicator(final Status status) {
            this.status = status;
        }

        @Override
        public Report report(ReportContext reportContext) {
            return () -> this.status;
        }
    }
}