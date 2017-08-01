package org.logstash.benchmark.cli;

/**
 * Class holding setting constants.
 */
public final class LsBenchSettings {

    /**
     * Name of the property holding the URL to download the dataset used by
     * {@link org.logstash.benchmark.cli.cases.ApacheLogsComplex} from.
     */
    public static final String APACHE_DATASET_URL = "org.logstash.benchmark.apache.dataset.url";

    /**
     * Property that sets how often the input dataset is to be repeated.
     */
    public static final String INPUT_DATA_REPEAT = "org.logstash.benchmark.input.repeat";
}
