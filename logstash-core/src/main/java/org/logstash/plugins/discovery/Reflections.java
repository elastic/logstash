package org.logstash.plugins.discovery;

import com.google.common.base.Predicate;
import com.google.common.collect.HashMultimap;
import com.google.common.collect.Iterables;
import com.google.common.collect.Lists;
import com.google.common.collect.Multimap;
import com.google.common.collect.Sets;
import java.lang.annotation.Annotation;
import java.lang.annotation.Inherited;
import java.net.URL;
import java.util.List;
import java.util.Set;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Future;

public class Reflections {

    protected final Configuration configuration;
    protected Store store;

    public Reflections(final Configuration configuration) {
        this.configuration = configuration;
        store = new Store(configuration);

        if (configuration.getScanners() != null && !configuration.getScanners().isEmpty()) {
            //inject to scanners
            for (Scanner scanner : configuration.getScanners()) {
                scanner.setConfiguration(configuration);
                scanner.setStore(store.getOrCreate(scanner.getClass().getSimpleName()));
            }

            scan();

            if (configuration.shouldExpandSuperTypes()) {
                expandSuperTypes();
            }
        }
    }

    public Reflections(final String prefix, final Scanner... scanners) {
        this((Object) prefix, scanners);
    }

    public Reflections(final Object... params) {
        this(ConfigurationBuilder.build(params));
    }

    //
    protected void scan() {
        if (configuration.getUrls() == null || configuration.getUrls().isEmpty()) {
            return;
        }
        ExecutorService executorService = configuration.getExecutorService();
        List<Future<?>> futures = Lists.newArrayList();

        for (final URL url : configuration.getUrls()) {
            try {
                if (executorService != null) {
                    futures.add(executorService.submit(() -> scan(url)));
                } else {
                    scan(url);
                }
            } catch (ReflectionsException e) {
            }
        }

        if (executorService != null) {
            for (Future future : futures) {
                try {
                    future.get();
                } catch (Exception e) {
                    throw new RuntimeException(e);
                }
            }
        }

        if (executorService != null) {
            executorService.shutdown();
        }
    }

    protected void scan(URL url) {
        Vfs.Dir dir = Vfs.fromURL(url);

        try {
            for (final Vfs.File file : dir.getFiles()) {
                // scan if inputs filter accepts file relative path or fqn
                Predicate<String> inputsFilter = configuration.getInputsFilter();
                String path = file.getRelativePath();
                String fqn = path.replace('/', '.');
                if (inputsFilter == null || inputsFilter.apply(path) || inputsFilter.apply(fqn)) {
                    Object classObject = null;
                    for (Scanner scanner : configuration.getScanners()) {
                        try {
                            if (scanner.acceptsInput(path) || scanner.acceptResult(fqn)) {
                                classObject = scanner.scan(file, classObject);
                            }
                        } catch (Exception e) {
                        }
                    }
                }
            }
        } finally {
            dir.close();
        }
    }

    public void expandSuperTypes() {
        if (store.keySet().contains(index(SubTypesScanner.class))) {
            Multimap<String, String> mmap = store.get(index(SubTypesScanner.class));
            Sets.SetView<String> keys = Sets.difference(mmap.keySet(), Sets.newHashSet(mmap.values()));
            Multimap<String, String> expand = HashMultimap.create();
            for (String key : keys) {
                final Class<?> type = ReflectionUtils.forName(key);
                if (type != null) {
                    expandSupertypes(expand, key, type);
                }
            }
            mmap.putAll(expand);
        }
    }

    private void expandSupertypes(Multimap<String, String> mmap, String key, Class<?> type) {
        for (Class<?> supertype : ReflectionUtils.getSuperTypes(type)) {
            if (mmap.put(supertype.getName(), key)) {
                expandSupertypes(mmap, supertype.getName(), supertype);
            }
        }
    }

    public Set<Class<?>> getTypesAnnotatedWith(final Class<? extends Annotation> annotation) {
        return getTypesAnnotatedWith(annotation, false);
    }

    public Set<Class<?>> getTypesAnnotatedWith(final Class<? extends Annotation> annotation, boolean honorInherited) {
        Iterable<String> annotated = store.get(index(TypeAnnotationsScanner.class), annotation.getName());
        Iterable<String> classes = getAllAnnotated(annotated, annotation.isAnnotationPresent(Inherited.class), honorInherited);
        return Sets.newHashSet(Iterables.concat(ReflectionUtils.forNames(annotated, loaders()), ReflectionUtils.forNames(classes, loaders())));
    }

    protected Iterable<String> getAllAnnotated(Iterable<String> annotated, boolean inherited, boolean honorInherited) {
        Iterable<String> subTypes = Iterables.concat(annotated, store.getAll(index(TypeAnnotationsScanner.class), annotated));
        return Iterables.concat(subTypes, store.getAll(index(SubTypesScanner.class), subTypes));
    }

    private static String index(Class<? extends Scanner> scannerClass) {
        return scannerClass.getSimpleName();
    }

    private ClassLoader[] loaders() {
        return configuration.getClassLoaders();
    }

}
