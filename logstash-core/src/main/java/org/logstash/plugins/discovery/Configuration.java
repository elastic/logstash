package org.logstash.plugins.discovery;

import com.google.common.base.Predicate;
import java.net.URL;
import java.util.Set;
import java.util.concurrent.ExecutorService;

public interface Configuration {
    /**
     * @return the scanner instances used for scanning different metadata
     */
    Set<Scanner> getScanners();

    /**
     * @return the urls to be scanned
     */
    Set<URL> getUrls();

    /**
     * @return the metadata adapter used to fetch metadata from classes
     */
    @SuppressWarnings("rawtypes")
    MetadataAdapter getMetadataAdapter();

    /**
     * @return the fully qualified name filter used to filter types to be scanned
     */
    Predicate<String> getInputsFilter();

    /**
     * @return executor service used to scan files. if null, scanning is done in a simple for loop
     */
    ExecutorService getExecutorService();

    /**
     * @return class loaders, might be used for resolving methods/fields
     */
    ClassLoader[] getClassLoaders();

    boolean shouldExpandSuperTypes();
}
