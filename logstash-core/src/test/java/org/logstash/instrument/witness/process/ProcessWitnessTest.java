package org.logstash.instrument.witness.process;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.Before;
import org.junit.Test;

import java.security.MessageDigest;
import java.time.Instant;
import java.util.UUID;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.ScheduledExecutorService;
import java.util.concurrent.TimeUnit;

import static org.assertj.core.api.Assertions.assertThat;
import static org.junit.Assume.assumeTrue;

/**
 * Unit tests for {@link ProcessWitness}
 */
public class ProcessWitnessTest {

    private ProcessWitness witness;

    @Before
    public void setup(){
        witness = new ProcessWitness();
    }

    @Test
    public void testInitialState(){
        ProcessWitness.Snitch snitch = witness.snitch();
        assertThat(snitch.cpuProcessPercent()).isEqualTo((short) -1);
        assertThat(snitch.cpuTotalInMillis()).isEqualTo(-1);
        assertThat(snitch.maxFileDescriptors()).isEqualTo(-1);
        assertThat(snitch.memTotalVirtualInBytes()).isEqualTo(-1);
        assertThat(snitch.openFileDescriptors()).isEqualTo(-1);
        assertThat(snitch.peakOpenFileDescriptors()).isEqualTo(-1);
    }

    @Test
    public void testRefresh(){
        ProcessWitness.Snitch snitch = witness.snitch();
        assumeTrue(ProcessWitness.isUnix);
        witness.refresh();
        assertThat(snitch.cpuProcessPercent()).isGreaterThanOrEqualTo((short) 0);
        assertThat(snitch.cpuTotalInMillis()).isGreaterThan(0);
        assertThat(snitch.maxFileDescriptors()).isGreaterThan(0);
        assertThat(snitch.memTotalVirtualInBytes()).isGreaterThan(0);
        assertThat(snitch.openFileDescriptors()).isGreaterThan(0);
        assertThat(snitch.peakOpenFileDescriptors()).isGreaterThan(0);
    }

    @Test
    public void testRefreshChanges() throws InterruptedException {
        ProcessWitness.Snitch snitch = witness.snitch();
        assumeTrue(ProcessWitness.isUnix);
        witness.refresh();
        short before = snitch.cpuProcessPercent();

        ScheduledExecutorService refresh = Executors.newSingleThreadScheduledExecutor();
        refresh.scheduleAtFixedRate(() -> witness.refresh(), 0 , 100, TimeUnit.MILLISECONDS);

        //Add some arbitrary CPU load
        ExecutorService cpuLoad = Executors.newSingleThreadExecutor();
        cpuLoad.execute(() -> {
            while(true){
                try {
                    MessageDigest md = MessageDigest.getInstance("SHA-1");
                    md.update(UUID.randomUUID().toString().getBytes());
                    md.digest();
                    if(Thread.currentThread().isInterrupted()){
                        break;
                    }
                } catch (Exception e) {
                    //do nothing
                }
            }
        });
        //we only care that the value changes, give the load some time to change it
        boolean pass = false;
        Instant end = Instant.now().plusSeconds(10);
        do {
            Thread.sleep(100);
            if (before != snitch.cpuProcessPercent()) {
                pass = true;
                break;
            }
        } while (end.isAfter(Instant.now()));
        assertThat(pass).isTrue();

        refresh.shutdownNow();
        cpuLoad.shutdownNow();
    }

    @Test
    public void testAsJson() throws Exception {
        ObjectMapper mapper = new ObjectMapper();
        assertThat(mapper.writeValueAsString(witness)).isEqualTo(witness.asJson());
    }

    @Test
    public void testSerializeEmpty() throws Exception {
        String json = witness.asJson();
        assertThat(json).isEqualTo("{\"process\":{\"open_file_descriptors\":-1,\"peak_open_file_descriptors\":-1,\"max_file_descriptors\":-1," +
                "\"mem\":{\"total_virtual_in_bytes\":-1},\"cpu\":{\"total_in_millis\":-1,\"percent\":-1}}}");
    }

    @Test
    public void testSerializePopulated() throws Exception {
        assumeTrue(ProcessWitness.isUnix);
        String emptyJson = witness.asJson();
        witness.refresh();
        String populatedJson = witness.asJson();
        assertThat(emptyJson).isNotEqualTo(populatedJson);
        assertThat(populatedJson).doesNotContain("-1");
    }
}