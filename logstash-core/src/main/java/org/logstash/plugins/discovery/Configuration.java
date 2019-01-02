package org.logstash.plugins.discovery;

import com.google.common.base.Predicate;
import java.net.URL;
import java.util.Set;
import java.util.concurrent.ExecutorService;

public interface Configuration {
    /**
     * the scanner instances used for scanning different metadata
     */
    Set<Scanner> getScanners();

    /**
     * the urls to be scanned
     */
    Set<URL> getUrls();

    /**
     * the metadata adapter used to fetch metadata from classes
     */
    @SuppressWarnings("rawtypes")
    MetadataAdapter getMetadataAdapter();

    /**
     * get the fully qualified name filter used to filter types to be scanned
     */
    Predicate<String> getInputsFilter();

    /**
     * executor service used to scan files. if null, scanning is done in a simple for loop
     */
    ExecutorService getExecutorService();

    /**
     * get class loaders, might be used for resolving methods/fields
     */
    ClassLoader[] getClassLoaders();

    boolean shouldExpandSuperTypes();
}
