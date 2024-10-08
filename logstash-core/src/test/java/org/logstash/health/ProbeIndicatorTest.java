package org.logstash.health;

import org.junit.Test;

import static org.hamcrest.CoreMatchers.is;
import static org.hamcrest.CoreMatchers.nullValue;
import static org.hamcrest.MatcherAssert.assertThat;
import static org.junit.Assert.assertThrows;

public class ProbeIndicatorTest {

    @Test
    public void attachProbeWhenNotExists() throws Exception {
        final ProbeIndicator<ProbeSubject> probeIndicator = new ProbeIndicator<>("subject", ProbeSubject::new);
        final Probe<ProbeSubject> existingProbe = new ProbeImplementation();
        probeIndicator.attachProbe("existing", existingProbe);

        final Probe<ProbeSubject> probeToAdd = new ProbeImplementation();
        probeIndicator.attachProbe("new", probeToAdd);

        assertThat(probeIndicator.getProbe("new"), is(probeToAdd));
        assertThat(probeIndicator.getProbe("existing"), is(existingProbe));
    }

    @Test
    public void attachProbeWhenExists() throws Exception {
        final ProbeIndicator<ProbeSubject> probeIndicator = new ProbeIndicator<>("subject", ProbeSubject::new);
        final Probe<ProbeSubject> existingProbe = new ProbeImplementation();
        probeIndicator.attachProbe("existing", existingProbe);

        final Probe<ProbeSubject> probeToAdd = new ProbeImplementation();
        assertThrows(IllegalArgumentException.class, () -> probeIndicator.attachProbe("existing", probeToAdd));

        assertThat(probeIndicator.getProbe("existing"), is(existingProbe));
    }

    @Test
    public void attachProbeWhenAttached() throws Exception {
        final ProbeIndicator<ProbeSubject> probeIndicator = new ProbeIndicator<>("subject", ProbeSubject::new);
        final Probe<ProbeSubject> existingProbe = new ProbeImplementation();
        probeIndicator.attachProbe("existing", existingProbe);

        // attach it again
        probeIndicator.attachProbe("existing", existingProbe);

        assertThat(probeIndicator.getProbe("existing"), is(existingProbe));
    }


    @Test
    public void detachProbeByNameWhenAttached() {
        final ProbeIndicator<ProbeSubject> probeIndicator = new ProbeIndicator<>("subject", ProbeSubject::new);
        final Probe<ProbeSubject> existingProbe = new ProbeImplementation();
        probeIndicator.attachProbe("existing", existingProbe);
        final Probe<ProbeSubject> existingProbeToRemove = new ProbeImplementation();
        probeIndicator.attachProbe("to_remove", existingProbeToRemove);

        probeIndicator.detachProbe("to_remove");

        assertThat(probeIndicator.getProbe("existing"), is(existingProbe));
        assertThat(probeIndicator.getProbe("to_remove"), is(nullValue()));
    }

    @Test
    public void detachProbeByNameWhenDetached() {
        final ProbeIndicator<ProbeSubject> probeIndicator = new ProbeIndicator<>("subject", ProbeSubject::new);
        final Probe<ProbeSubject> existingProbe = new ProbeImplementation();
        probeIndicator.attachProbe("existing", existingProbe);

        probeIndicator.detachProbe("to_remove");

        assertThat(probeIndicator.getProbe("existing"), is(existingProbe));
        assertThat(probeIndicator.getProbe("to_remove"), is(nullValue()));
    }

    @Test
    public void detachProbeByValueWhenAttached() {
        final ProbeIndicator<ProbeSubject> probeIndicator = new ProbeIndicator<>("subject", ProbeSubject::new);
        final Probe<ProbeSubject> existingProbe = new ProbeImplementation();
        probeIndicator.attachProbe("existing", existingProbe);
        final Probe<ProbeSubject> existingProbeToRemove = new ProbeImplementation();
        probeIndicator.attachProbe("to_remove", existingProbeToRemove);

        probeIndicator.detachProbe("to_remove", existingProbeToRemove);

        assertThat(probeIndicator.getProbe("existing"), is(existingProbe));
        assertThat(probeIndicator.getProbe("to_remove"), is(nullValue()));
    }

    @Test
    public void detachProbeByValueWhenDetached() {
        final ProbeIndicator<ProbeSubject> probeIndicator = new ProbeIndicator<>("subject", ProbeSubject::new);
        final Probe<ProbeSubject> existingProbe = new ProbeImplementation();
        probeIndicator.attachProbe("existing", existingProbe);
        final Probe<ProbeSubject> existingProbeToRemove = new ProbeImplementation();

        probeIndicator.detachProbe("to_remove", existingProbeToRemove);

        assertThat(probeIndicator.getProbe("existing"), is(existingProbe));
        assertThat(probeIndicator.getProbe("to_remove"), is(nullValue()));
    }

    @Test
    public void detachProbeByValueWhenConflict() {
        final ProbeIndicator<ProbeSubject> probeIndicator = new ProbeIndicator<>("subject", ProbeSubject::new);
        final Probe<ProbeSubject> existingProbe = new ProbeImplementation();
        probeIndicator.attachProbe("existing", existingProbe);
        final Probe<ProbeSubject> anotherProbeToRemove = new ProbeImplementation();

        assertThrows(IllegalArgumentException.class, () -> probeIndicator.detachProbe("existing", anotherProbeToRemove));

        assertThat(probeIndicator.getProbe("existing"), is(existingProbe));
        assertThat(probeIndicator.getProbe("to_remove"), is(nullValue()));
    }

    @Test
    public void report() {
    }

    private static class ProbeSubject implements ProbeIndicator.Observation {}

    private static class ProbeImplementation implements Probe<ProbeSubject> {
        @Override
        public Analysis analyze(ProbeSubject observation) {
            return Analysis.builder().build();
        }
    }
}