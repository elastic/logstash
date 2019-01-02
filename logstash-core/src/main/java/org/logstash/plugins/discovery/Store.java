package org.logstash.plugins.discovery;

import com.google.common.collect.Iterables;
import com.google.common.collect.Lists;
import com.google.common.collect.Multimap;
import com.google.common.collect.Multimaps;
import com.google.common.collect.SetMultimap;
import com.google.common.collect.Sets;
import java.util.Arrays;
import java.util.Collections;
import java.util.HashMap;
import java.util.Iterator;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.concurrent.ConcurrentHashMap;

public final class Store {

    private transient boolean concurrent;
    private final Map<String, Multimap<String, String>> storeMap;

    //used via reflection
    @SuppressWarnings("UnusedDeclaration")
    protected Store() {
        storeMap = new HashMap<>();
        concurrent = false;
    }

    public Store(Configuration configuration) {
        storeMap = new HashMap<>();
        concurrent = configuration.getExecutorService() != null;
    }

    /**
     * return all indices
     */
    public Set<String> keySet() {
        return storeMap.keySet();
    }

    /**
     * get or create the multimap object for the given {@code index}
     */
    public Multimap<String, String> getOrCreate(String index) {
        Multimap<String, String> mmap = storeMap.get(index);
        if (mmap == null) {
            SetMultimap<String, String> multimap =
                Multimaps.newSetMultimap(new HashMap<>(),
                    () -> Collections.newSetFromMap(new ConcurrentHashMap<>()));
            mmap = concurrent ? Multimaps.synchronizedSetMultimap(multimap) : multimap;
            storeMap.put(index, mmap);
        }
        return mmap;
    }

    public Multimap<String, String> get(String index) {
        Multimap<String, String> mmap = storeMap.get(index);
        if (mmap == null) {
            throw new ReflectionsException("Scanner " + index + " was not configured");
        }
        return mmap;
    }

    /**
     * get the values stored for the given {@code index} and {@code keys}
     */
    public Iterable<String> get(String index, String... keys) {
        return get(index, Arrays.asList(keys));
    }

    /**
     * get the values stored for the given {@code index} and {@code keys}
     */
    public Iterable<String> get(String index, Iterable<String> keys) {
        Multimap<String, String> mmap = get(index);
        IterableChain<String> result = new IterableChain<>();
        for (String key : keys) {
            result.addAll(mmap.get(key));
        }
        return result;
    }

    /**
     * recursively get the values stored for the given {@code index} and {@code keys}, including keys
     */
    private Iterable<String> getAllIncluding(String index, Iterable<String> keys, IterableChain<String> result) {
        result.addAll(keys);
        for (String key : keys) {
            Iterable<String> values = get(index, key);
            if (values.iterator().hasNext()) {
                getAllIncluding(index, values, result);
            }
        }
        return result;
    }

    /**
     * recursively get the values stored for the given {@code index} and {@code keys}, not including keys
     */
    public Iterable<String> getAll(String index, Iterable<String> keys) {
        return getAllIncluding(index, get(index, keys), new IterableChain<>());
    }

    private static class IterableChain<T> implements Iterable<T> {
        private final List<Iterable<T>> chain = Lists.newArrayList();

        private void addAll(Iterable<T> iterable) {
            chain.add(iterable);
        }

        public Iterator<T> iterator() {
            return Iterables.concat(chain).iterator();
        }
    }
}
