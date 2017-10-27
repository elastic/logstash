package org.logstash.instrument.witness.process;

import com.fasterxml.jackson.core.JsonGenerator;
import com.fasterxml.jackson.databind.SerializerProvider;
import com.fasterxml.jackson.databind.annotation.JsonSerialize;
import com.fasterxml.jackson.databind.ser.std.StdSerializer;
import com.sun.management.UnixOperatingSystemMXBean;
import org.logstash.instrument.metrics.Metric;
import org.logstash.instrument.metrics.gauge.NumberGauge;
import org.logstash.instrument.witness.MetricSerializer;
import org.logstash.instrument.witness.SerializableWitness;
import org.logstash.instrument.witness.schedule.ScheduledWitness;

import java.io.IOException;
import java.lang.management.ManagementFactory;
import java.lang.management.OperatingSystemMXBean;
import java.util.concurrent.TimeUnit;

/**
 * A scheduled witness for process metrics
 */
@JsonSerialize(using = ProcessWitness.Serializer.class)
public class ProcessWitness implements SerializableWitness, ScheduledWitness {

    private static final OperatingSystemMXBean osMxBean;
    private static final String KEY = "process";
    public  static final boolean isUnix;
    private static final UnixOperatingSystemMXBean unixOsBean;
    private final NumberGauge openFileDescriptors;
    private final NumberGauge peakOpenFileDescriptors;
    private final NumberGauge maxFileDescriptors;
    private final Cpu cpu;
    private final Memory memory;
    private final Snitch snitch;

    static {
        osMxBean = ManagementFactory.getOperatingSystemMXBean();
        isUnix = osMxBean instanceof UnixOperatingSystemMXBean;
        unixOsBean = isUnix ? (UnixOperatingSystemMXBean) osMxBean : null;
    }

    /**
     * Constructor
     */
    public ProcessWitness() {
        this.openFileDescriptors = new NumberGauge("open_file_descriptors", -1);
        this.maxFileDescriptors = new NumberGauge("max_file_descriptors", -1);
        this.peakOpenFileDescriptors = new NumberGauge("peak_open_file_descriptors", -1);
        this.cpu = new Cpu();
        this.memory = new Memory();
        this.snitch = new Snitch(this);
    }

    @Override
    public void refresh() {
        if (isUnix) {
            long currentOpen = unixOsBean.getOpenFileDescriptorCount();
            openFileDescriptors.set(currentOpen);
            if (maxFileDescriptors.getValue() == null || peakOpenFileDescriptors.getValue().longValue() < currentOpen) {
                peakOpenFileDescriptors.set(currentOpen);
            }
            maxFileDescriptors.set(unixOsBean.getMaxFileDescriptorCount());
        }
        cpu.refresh();
        memory.refresh();
    }

    /**
     * Get a reference to associated snitch to get discrete metric values.
     *
     * @return the associate {@link Snitch}
     */
    public Snitch snitch() {
        return snitch;
    }

    /**
     * An inner witness for the process / cpu metrics
     */
    public class Cpu implements ScheduledWitness {
        private static final String KEY = "cpu";
        private final NumberGauge cpuProcessPercent;
        private final NumberGauge cpuTotalInMillis;

        private Cpu() {
            this.cpuProcessPercent = new NumberGauge("percent", -1);
            this.cpuTotalInMillis = new NumberGauge("total_in_millis", -1);
        }

        @Override
        public void refresh() {
            cpuProcessPercent.set(scaleLoadToPercent(unixOsBean.getProcessCpuLoad()));
            cpuTotalInMillis.set(TimeUnit.MILLISECONDS.convert(unixOsBean.getProcessCpuTime(), TimeUnit.NANOSECONDS));
        }
    }

    /**
     * An inner witness for the the process / memory metrics
     */
    public class Memory implements ScheduledWitness {
        private static final String KEY = "mem";
        private final NumberGauge memTotalVirtualInBytes;

        private Memory() {
            memTotalVirtualInBytes = new NumberGauge("total_virtual_in_bytes", -1);
        }

        @Override
        public void refresh() {
            memTotalVirtualInBytes.set(unixOsBean.getCommittedVirtualMemorySize());
        }
    }

    @Override
    public void genJson(JsonGenerator gen, SerializerProvider provider) throws IOException {
        Serializer.innerSerialize(this, gen);
    }

    /**
     * The Jackson serializer.
     */
    public static final class Serializer extends StdSerializer<ProcessWitness> {
        /**
         * Default constructor - required for Jackson
         */
        public Serializer() {
            this(ProcessWitness.class);
        }

        /**
         * Constructor
         *
         * @param t the type to serialize
         */
        protected Serializer(Class<ProcessWitness> t) {
            super(t);
        }

        @Override
        public void serialize(ProcessWitness witness, JsonGenerator gen, SerializerProvider provider) throws IOException {
            gen.writeStartObject();
            innerSerialize(witness, gen);
            gen.writeEndObject();
        }

        static void innerSerialize(ProcessWitness witness, JsonGenerator gen) throws IOException {
            MetricSerializer<Metric<Number>> numberSerializer = MetricSerializer.Get.numberSerializer(gen);
            gen.writeObjectFieldStart(KEY);
            numberSerializer.serialize(witness.openFileDescriptors);
            numberSerializer.serialize(witness.peakOpenFileDescriptors);
            numberSerializer.serialize(witness.maxFileDescriptors);
            //memory
            gen.writeObjectFieldStart(Memory.KEY);
            numberSerializer.serialize(witness.memory.memTotalVirtualInBytes);
            gen.writeEndObject();
            //cpu
            gen.writeObjectFieldStart(Cpu.KEY);
            numberSerializer.serialize(witness.cpu.cpuTotalInMillis);
            numberSerializer.serialize(witness.cpu.cpuProcessPercent);

            //TODO: jake load average

            gen.writeEndObject();
            gen.writeEndObject();
        }
    }

    /**
     * The Process snitch. Provides a means to get discrete metric values.
     */
    public static final class Snitch {

        private final ProcessWitness witness;

        private Snitch(ProcessWitness witness) {
            this.witness = witness;
        }

        /**
         * Get the number of open file descriptors for this process
         *
         * @return the open file descriptors
         */
        public long openFileDescriptors() {
            return witness.openFileDescriptors.getValue().longValue();
        }

        /**
         * Get the max file descriptors for this process
         *
         * @return the max file descriptors
         */
        public long maxFileDescriptors() {
            return witness.maxFileDescriptors.getValue().longValue();
        }

        /**
         * Get the high water number of open file descriptors for this process
         *
         * @return the high water/ peak of the seen open file descriptors
         */
        public long peakOpenFileDescriptors() {
            return witness.peakOpenFileDescriptors.getValue().longValue();
        }

        /**
         * Get the cpu percent for this process
         *
         * @return the cpu percent
         */
        public short cpuProcessPercent() {
            return witness.cpu.cpuProcessPercent.getValue().shortValue();
        }

        /**
         * Get the total time of the cpu in milliseconds for this process
         *
         * @return the cpu total in milliseconds
         */
        public long cpuTotalInMillis() {
            return witness.cpu.cpuTotalInMillis.getValue().longValue();
        }

        /**
         * Get the committed (virtual) memory for this process
         *
         * @return the committed memory
         */
        public long memTotalVirtualInBytes() {
            return witness.memory.memTotalVirtualInBytes.getValue().longValue();
        }

    }

    private short scaleLoadToPercent(double load) {
        if (isUnix && load >= 0) {
            return Double.valueOf(Math.floor(load * 100)).shortValue();
        } else {
            return (short) -1;
        }
    }
}
