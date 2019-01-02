package org.logstash.plugins.discovery;

import com.google.common.base.Predicate;
import com.google.common.collect.Lists;
import com.google.common.collect.ObjectArrays;
import com.google.common.collect.Sets;
import java.net.URL;
import java.util.Collection;
import java.util.List;
import java.util.Set;
import java.util.concurrent.ExecutorService;

public final class ConfigurationBuilder implements Configuration {

    private final Set<Scanner> scanners;

    private Set<URL> urls;
    @SuppressWarnings("rawtypes") protected MetadataAdapter metadataAdapter;

    private Predicate<String> inputsFilter;

    private ExecutorService executorService;

    private ClassLoader[] classLoaders;
    private boolean expandSuperTypes = true;

    public ConfigurationBuilder() {
        scanners = Sets.newHashSet(new TypeAnnotationsScanner(), new SubTypesScanner());
        urls = Sets.newHashSet();
    }

    @SuppressWarnings({"unchecked","rawtypes"})
    public static ConfigurationBuilder build(final Object... params) {
        ConfigurationBuilder builder = new ConfigurationBuilder();

        //flatten
        List<Object> parameters = Lists.newArrayList();
        if (params != null) {
            for (Object param : params) {
                if (param != null) {
                    if (param.getClass().isArray()) {
                        for (Object p : (Object[]) param)
                            if (p != null) {
                                parameters.add(p);
                            }
                    } else if (param instanceof Iterable) {
                        for (Object p : (Iterable) param)
                            if (p != null) {
                                parameters.add(p);
                            }
                    } else {
                        parameters.add(param);
                    }
                }
            }
        }

        List<ClassLoader> loaders = Lists.newArrayList();
        for (Object param : parameters)
            if (param instanceof ClassLoader) {
                loaders.add((ClassLoader) param);
            }

        ClassLoader[] classLoaders = loaders.isEmpty() ? null : loaders.toArray(new ClassLoader[loaders.size()]);
        FilterBuilder filter = new FilterBuilder();
        List<Scanner> scanners = Lists.newArrayList();

        for (Object param : parameters) {
            if (param instanceof String) {
                builder.addUrls(ClasspathHelper.forPackage((String) param, classLoaders));
                filter.includePackage((String) param);
            } else if (param instanceof Class) {
                if (Scanner.class.isAssignableFrom((Class) param)) {
                    try {
                        builder.addScanners((Scanner) ((Class) param).newInstance());
                    } catch (Exception e) { /*fallback*/ }
                }
                builder.addUrls(ClasspathHelper.forClass((Class) param, classLoaders));
                filter.includePackage((Class) param);
            } else if (param instanceof Scanner) {
                scanners.add((Scanner) param);
            } else if (param instanceof URL) {
                builder.addUrls((URL) param);
            } else if (param instanceof ClassLoader) { /* already taken care */ } else if (param instanceof Predicate) {
                filter.add((Predicate<String>) param);
            } else if (param instanceof ExecutorService) {
                builder.setExecutorService((ExecutorService) param);
            }
        }

        if (builder.getUrls().isEmpty()) {
            if (classLoaders != null) {
                builder.addUrls(ClasspathHelper.forClassLoader(classLoaders)); //default urls getResources("")
            } else {
                builder.addUrls(ClasspathHelper.forClassLoader()); //default urls getResources("")
            }
        }

        builder.filterInputsBy(filter);
        if (!scanners.isEmpty()) {
            builder.setScanners(scanners.toArray(new Scanner[scanners.size()]));
        }
        if (!loaders.isEmpty()) {
            builder.addClassLoaders(loaders);
        }

        return builder;
    }

    @Override

    public Set<Scanner> getScanners() {
        return scanners;
    }

    /**
     * set the scanners instances for scanning different metadata
     * @param scanners provided scanners
     * @return updated {@link ConfigurationBuilder} instance
     */
    public ConfigurationBuilder setScanners(final Scanner... scanners) {
        this.scanners.clear();
        return addScanners(scanners);
    }

    /**
     * set the scanners instances for scanning different metadata
     * @param scanners provided scanners
     * @return updated {@link ConfigurationBuilder} instance
     */
    public ConfigurationBuilder addScanners(final Scanner... scanners) {
        this.scanners.addAll(Sets.newHashSet(scanners));
        return this;
    }

    @Override

    public Set<URL> getUrls() {
        return urls;
    }

    /**
     * add urls to be scanned
     * <p>use {@link ClasspathHelper} convenient methods to get the relevant urls
     * @param urls provided URLs
     * @return updated {@link ConfigurationBuilder} instance
     */
    public ConfigurationBuilder addUrls(final Collection<URL> urls) {
        this.urls.addAll(urls);
        return this;
    }

    /**
     * add urls to be scanned
     * <p>use {@link ClasspathHelper} convenient methods to get the relevant urls
     * @param urls provided URLs
     * @return updated {@link ConfigurationBuilder} instance
     */
    public ConfigurationBuilder addUrls(final URL... urls) {
        this.urls.addAll(Sets.newHashSet(urls));
        return this;
    }

    /**
     * @return the metadata adapter.
     * if javassist library exists in the classpath, this method returns {@link JavassistAdapter} otherwise defaults to {@link JavaReflectionAdapter}.
     * <p>the {@link JavassistAdapter} is preferred in terms of performance and class loading.
     */
    @SuppressWarnings("rawtypes")
    @Override
    public MetadataAdapter getMetadataAdapter() {
        if (metadataAdapter != null) {
            return metadataAdapter;
        } else {
            try {
                return metadataAdapter = new JavassistAdapter();
            } catch (Throwable e) {
                return metadataAdapter = new JavaReflectionAdapter();
            }
        }
    }

    @Override
    public Predicate<String> getInputsFilter() {
        return inputsFilter;
    }

    /**
     * sets the input filter for all resources to be scanned.
     * <p> supply a {@link Predicate} or use the {@link FilterBuilder}
     * @param inputsFilter provided inputs filter
     * @return updated {@link ConfigurationBuilder} instance
     */
    public ConfigurationBuilder filterInputsBy(Predicate<String> inputsFilter) {
        this.inputsFilter = inputsFilter;
        return this;
    }

    @Override
    public ExecutorService getExecutorService() {
        return executorService;
    }

    /**
     * sets the executor service used for scanning.
     * @param executorService provided executor service
     * @return updated {@link ConfigurationBuilder} instance
     */
    public ConfigurationBuilder setExecutorService(ExecutorService executorService) {
        this.executorService = executorService;
        return this;
    }

    /**
     * @return class loader, might be used for scanning or resolving methods/fields
     */
    @Override
    public ClassLoader[] getClassLoaders() {
        return classLoaders;
    }

    @Override
    public boolean shouldExpandSuperTypes() {
        return expandSuperTypes;
    }

    /**
     * add class loader, might be used for resolving methods/fields
     * @param classLoaders provided class loaders
     * @return updated {@link ConfigurationBuilder} instance
     */
    public ConfigurationBuilder addClassLoaders(ClassLoader... classLoaders) {
        this.classLoaders = this.classLoaders == null ? classLoaders : ObjectArrays.concat(this.classLoaders, classLoaders, ClassLoader.class);
        return this;
    }

    /**
     * add class loader, might be used for resolving methods/fields
     * @param classLoaders provided class loaders
     * @return updated {@link ConfigurationBuilder} instance
     */
    public ConfigurationBuilder addClassLoaders(Collection<ClassLoader> classLoaders) {
        return addClassLoaders(classLoaders.toArray(new ClassLoader[classLoaders.size()]));
    }
}
