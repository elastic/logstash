package org.logstash.instrument.witness.schedule;


import org.apache.logging.log4j.Level;
import org.apache.logging.log4j.core.Appender;
import org.apache.logging.log4j.core.ErrorHandler;
import org.apache.logging.log4j.core.LogEvent;
import org.apache.logging.log4j.core.LoggerContext;
import org.junit.After;
import org.junit.Before;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.runners.MockitoJUnitRunner;

import java.time.Duration;
import java.util.stream.Collectors;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.*;

/**
 * Unit tests for {@link WitnessScheduler}
 */
@RunWith(MockitoJUnitRunner.class)
public class WitnessSchedulerTest {

    private Witness1 witness1;
    private Witness2 witness2;
    private Witness3 witness3;

    @Mock
    Appender appender;

    @Mock
    ErrorHandler errorHandler;

    @Before
    public void setup() {
        witness1 = new Witness1();
        witness2 = new Witness2();
        witness3 = new Witness3();
        when(appender.getName()).thenReturn("junit");
        when(appender.getHandler()).thenReturn(errorHandler);
        when(appender.isStarted()).thenReturn(true);
        LoggerContext.getContext(false).getLogger(WitnessScheduler.class.getName()).addAppender(appender);
        LoggerContext.getContext(false).getLogger(WitnessScheduler.class.getName()).setLevel(Level.WARN);
    }

    @After
    public void tearDown() {
        LoggerContext.getContext(false).getLogger(WitnessScheduler.class.getName()).removeAppender(appender);
    }

    @Test
    public void testSchedule() throws InterruptedException {
        WitnessScheduler witness1Scheduler = new WitnessScheduler(witness1);
        witness1Scheduler.schedule();
        new WitnessScheduler(witness2).schedule();
        new WitnessScheduler(witness3).schedule();
        //Give some time fo the schedules to run.
        Thread.sleep(15000);
        assertThat(witness1.counter).isBetween(15, 60);
        assertThat(witness2.counter).isBetween(3, 10);
        //this tests that an exception thrown does not kill the scheduler
        assertThat(witness3.counter).isBetween(15, 60);

        assertThat(Thread.getAllStackTraces().keySet().stream().map(t -> t.getName()).collect(Collectors.toSet())).contains("Witness1-thread").contains("Witness2-thread")
                .contains("Witness3-thread");

        ArgumentCaptor<LogEvent> argument = ArgumentCaptor.forClass(LogEvent.class);
        //tests that Witness3 is the only error and that it only gets logged once
        verify(appender).append(argument.capture());
        assertThat(argument.getAllValues().stream().filter(a -> a.getMessage().toString().equals("Can not fully refresh the metrics for the Witness3")).count()).isEqualTo(1);

        //shutdown 1 of the schedulers
        witness1Scheduler.shutdown();
        int count1 = witness1.counter;
        int count2 = witness2.counter;
        int count3 = witness3.counter;

        Thread.sleep(10000);
        //witness 1 has been stopped but the others keep on truckin
        assertThat(count1).isEqualTo(witness1.counter);
        assertThat(count2).isLessThan(witness2.counter);
        assertThat(count3).isLessThan(witness3.counter);

        assertThat(Thread.getAllStackTraces().keySet().stream().map(t -> t.getName()).collect(Collectors.toSet())).doesNotContain("Witness1-thread");
    }


    class Witness1 implements ScheduledWitness {

        int counter = 0;

        @Override
        public void refresh() {
            counter++;
        }

        @Override
        public Duration every() {
            return Duration.ofSeconds(1);
        }
    }

    class Witness2 implements ScheduledWitness {

        int counter = 0;

        @Override
        public void refresh() {
            counter++;
        }

        @Override
        public Duration every() {
            return Duration.ofSeconds(5);
        }
    }

    class Witness3 implements ScheduledWitness {

        int counter = 0;

        @Override
        public void refresh() {
            counter++;
            throw new RuntimeException();
        }

        @Override
        public Duration every() {
            return Duration.ofSeconds(1);
        }
    }
}