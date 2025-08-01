package org.logstash.instrument.metrics;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.jruby.anno.JRubyMethod;

import java.util.*;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.ConcurrentMap;
import java.util.concurrent.locks.ReentrantLock;
import java.util.function.Consumer;
import java.util.function.Supplier;
import java.util.stream.Collectors;

public final class MetricStore {

    static final Logger LOGGER = LogManager.getLogger(MetricStore.class);

    public static class NamespacesExpectedError extends RuntimeException {
        private static final long serialVersionUID = 4456147903096417842L;

        NamespacesExpectedError(String message) {
            super(message);
        }
    }

    public static class MetricNotFound extends RuntimeException {
        private static final long serialVersionUID = -6471818257968802560L;

        public MetricNotFound(String message) {
            super(message);
        }
    }

    // We keep the structured cache to allow the api to search the content of the different nodes.
    // Value could be a metric or another layer (ConcurrentMap)
    private final ConcurrentMap<String, Object> store = new ConcurrentHashMap<>();

    // This hash has only one dimension and allow fast retrieval of the metrics.
    private final ConcurrentMap<List<String>, Metric<?>> fastLookup = new ConcurrentHashMap<>();

    /**
     * This Mutex block the critical section for the
     * structured hash, it block the zone when we first insert a metric
     * in the structured hash or when we query it for search or to make
     * the result available in the API.
     */
    private final ReentrantLock lock = new ReentrantLock();

//    public Metric<?> fetchOrStore(List<RubySymbol> namespacesPath, RubySymbol key, final Metric<?> metric) {
    public Metric<?> fetchOrStore(List<String> namespacesPath, String key, final Metric<?> metric) {
        return fetchOrStore(namespacesPath, key, () -> metric);
    }

    /**
     * This method use the namespace and key to search the corresponding value of
     * the hash, if it doesn't exist it will create the appropriate namespaces
     * path in the hash and return `new_value`.
     *
     * @param namespacesPath
     *      The path where the values should be located.
     * @param key
     *      The metric key.
     * @param metricGenerator
     *      The function to be invoked to generate the metric if doesn't existing on the kay at the namespacePath.
     * @return Metric instance for the namespace path and key provided.
     */
    public Metric<?> fetchOrStore(List<String> namespacesPath, String key, Supplier<Metric<?>> metricGenerator) {
        // We first check in the `fastLookup` store to see if we have already see that metrics before,
        // This give us a `O(1)` access, which is faster than searching through the structured
        // data store (Which is a `O(n)` operation where `n` is the number of element in the namespace and
        // the value of the key). If the metric is already present in the `fastLookup`, then that value is sent
        // back directly to the caller.

        List<String> namespacePathConverted = namespacesPath /*convertToJavaPath(namespacesPath)*/;

        List<String> fastLookupKey = new ArrayList<>(namespacePathConverted);
//        fastLookupKey.add(key.asJavaString());
        fastLookupKey.add(key);

        Metric<?> existingValue = fastLookup.get(fastLookupKey);
        if (existingValue != null) {
            return existingValue;
        }

        // BUT. If the value was not present in the `fastLookup` we acquire the lock
        // before modifying _either_ the fast-lookup or the structured store.
        lock.lock();
        try {
            // by using compute_if_absent, we ensure that we don't overwrite a value that was
            // written by another thread that beat us to the lock.
            return fastLookup.computeIfAbsent(fastLookupKey, k -> {
                Metric<?> generated = metricGenerator.get();
                fetchOrStoreNamespaces(namespacePathConverted).putIfAbsent(key/*.asJavaString()*/, generated);
                return generated;
            });
        } finally {
            lock.unlock();
        }
    }

//    private static List<String> convertToJavaPath(List<RubySymbol> namespacesPath) {
//        return namespacesPath.stream().map(rs -> rs.asJavaString()).collect(Collectors.toList());
//    }

    // Keys is a list of string, but can also contain maps and submaps
    @SuppressWarnings("unchecked")
    public Map<String, Object> extractMetrics(List<String> path, List<Object> keys) {
        Map<String, Object> acc = new HashMap<>();
        for (Object key : keys) {
            // Simplify 1-length keys
            if ((key instanceof List) && ((List) key).size() == 1) {
                key = ((List) key).getFirst();
            }

            // If we have list values here we need to recurse.
            // There are two levels of looping here, one for the paths we might pass in,
            // one for the upcoming keys we might pass in.
            // TODO alternatively check also RubyArray
            if (key instanceof List) {
                // We need to build up future executions to extractMetrics
                // which means building up the path and keys arguments.
                // We need a nested loop here to execute all permutations of these in case we hit
                // something like [["a", "b"],["c", "d"]] which produces 4 different metrics
                List<String> castedKey = (List<String>) key;
                List<Object> nextPaths = wrapWithListIfScalar(castedKey.getFirst());
                List<Object> nextKeys = wrapWithListIfScalar(castedKey.get(1));
                List<String> rest = castedKey.subList(2, castedKey.size());

                for (Object nextPath : nextPaths) {
                    // If there already is a hash at this location use that so we don't overwrite it
                    Map<String, Object> npMap = (Map<String, Object>) acc.getOrDefault(nextPath, new HashMap<>());

                    // combine recursion key as path + nextPath
                    List<String> nextPathRec = new ArrayList<>(path);
                    nextPathRec.add(nextPath.toString());

                    for (Object nextKey : nextKeys) {
                        // combine recursion key as nextKey + [rest]
                        List<Object> keysRec = new ArrayList<>();
                        keysRec.add(nextKey);
                        keysRec.addAll(rest);
                        // wrap inside a List because ruby code use a splat operator that wrap all remaining params into an array (*keys)
                        Map<String, Object> recMap = extractMetrics(nextPathRec, Collections.singletonList(keysRec));

                        // merge recMap into npMap replacing the existing keys
                        for (Map.Entry<String, Object> entry : recMap.entrySet()) {
                            npMap.put(entry.getKey(), entry.getValue());
                        }
                    }
                    acc.put(nextPath.toString(), npMap);
                }
            } else {
                // scalar value, key is a string
                String castedKey = (String) key;

                // copy the path because it's modified by getRecursively!
                Object value = getShallow(new ArrayList<>(path));
                // we give for granted that value is a map
                Object m = ((Map<String, Object>) value).get(castedKey);
                acc.put(castedKey, m != null ? ((Metric<?>) m).getValue() : null);
            }
        }

        return acc;
    }

    @SuppressWarnings("unchecked")
    private static List<Object> wrapWithListIfScalar(Object toWrap) {
        if (toWrap instanceof List) {
            return (List<Object>) toWrap;
        }
        return Collections.singletonList(toWrap);
    }


    /**
     * Use the path to navigate the metrics tree and return what it matches, returns a Map or Metric.
     *
     * Retrieve values like `get`, but don't return them fully nested.
     * This means that if you call `getShallow(["foo", "bar"])` the result will not
     * be nested inside of `{"foo" {"bar" => values}`.
     * */
    @SuppressWarnings("unchecked")
    public Object getShallow(List<String> path) {
        // save a copy because get method modifies the instance, so it cleans up removing the head at each step.
        ArrayList<String> savedPath = new ArrayList<>(path);
        Map<String, Object> acc = get(path);
        for (String key : savedPath) {
            Object next = acc.get(key);
            if (!(next instanceof Map)) {
                return next;
            }

            acc = (Map<String, Object>) next;
        }
        return acc;
    }

    @JRubyMethod(name = "has_metric?")
    public boolean hasMetric(List<String> path) {
        return fastLookup.containsKey(path);
    }

    public int size() {
        return fastLookup.size();
    }

    public List<Metric<?>> each() {
        return getAll();
    }

    public List<Metric<?>> each(Consumer<Metric<?>> processor) {
        List<Metric<?>> result = getAll();
        result.forEach(processor);
        return result;
    }

    public List<Metric<?>> each(String path) {
        return transformToArray(getWithPath(path));
    }

    public List<Metric<?>> each(String path, Consumer<Metric<?>> processor) {
        List<Metric<?>> result = transformToArray(getWithPath(path));
        result.forEach(processor);
        return result;
    }

    @SuppressWarnings("unchecked")
    public static List<Metric<?>> transformToArray(Map<String, Object> map) {
        List<Metric<?>> result = new ArrayList<>();

        for (Object value : map.values()) {
            if (value instanceof Map) {
                // Recursive call for nested map
                result.addAll(transformToArray((Map<String, Object>) value));
            } else {
                // TODO potential casting runtime error
                result.add((Metric<?>) value);
            }
        }

        return result;
    }

    private List<Metric<?>> getAll() {
        return new ArrayList<>(fastLookup.values());
    }

    public void prune(String path) {
        List<String> keyPaths = keyPaths(path);
        lock.lock();
        try {
            List<List<String>> keysToDelete = fastLookup.keySet()
                    .stream()
                    .filter(namespace -> keyMatch(namespace, keyPaths))
                    .collect(Collectors.toList());
            keysToDelete.forEach(fastLookup::remove);
            deleteFromMap(store, keyPaths);
        } finally {
            lock.unlock();
        }
    }

    @SuppressWarnings("unchecked")
    private void deleteFromMap(Map<String, Object> map, List<String> keys) {
        String key = keys.get(0);

        if (keys.size() == 1) {
            // If it's the last key, remove the entry from the map
            map.remove(key);
            return;
        }

        // Retrieve the value associated with the key
        Object nestedObject = map.get(key);
        if (nestedObject == null) {
            return;
        }

        // Check if the retrieved value is a nested map
        if (nestedObject instanceof Map) {
            // Safely cast the nested map and proceed recursively
            deleteFromMap((Map<String, Object>) nestedObject, keys.subList(1, keys.size()));
        }
    }

    private static boolean keyMatch(List<String> namespace, List<String> keyPaths) {
        return keyPaths.containsAll(namespace.subList(0, namespace.size() - 1));
    }

    /**
     * This method allow to retrieve values for a specific path,
     * This method support the following queries:
     *
     * stats/pipelines/pipeline_X
     * stats/pipelines/pipeline_X,pipeline_2
     * stats/os,jvm
     *
     * If you use the `,` on a key the metric store will return the both values at that level
     *
     * The returned hash will keep the same structure as it had in the `ConcurrentMap`
     * but will be a normal ruby hash. This will allow the api to easily serialize the content
     * of the map.
     * */
    public Map<String, Object> getWithPath(String path) {
        return get(keyPaths(path));
    }

    public Map<String, Object> get(List<String> keyPaths) {
        lock.lock();
        try {
            return getRecursively(keyPaths, store, new HashMap<>());
        } finally {
            lock.unlock();
        }
    }

    /**
     * Split the string representing a path like /jvm/process into the tokens list [jvm, process]
     */
    private List<String> keyPaths(String path) {
        // returned path has to be modifiable, so thw wrap into an ArrayList
        return new ArrayList<>(Arrays.asList(path.replaceAll("^\\/+", "").split("/")));
    }

    /**
    * This method take an array of keys and recursively search the metric store structure
    * and return a filtered hash of the structure. This method also take into consideration
    * getting two different branches.
    * If one part of the `key_paths` contains a filter key with the following format
    * "pipeline01, pipeline_02", It know that need to fetch the branch `pipeline01` and `pipeline02`.
    *
    * @param keyPaths
    *       The list of keys part to filter.
    * @param map
    *       The part of map to search in.
    * @param newHash
    *       The hash to populate with the results.
    * @return the newHash.
    */
    @SuppressWarnings("unchecked")
    private Map<String, Object> getRecursively(List<String> keyPaths, ConcurrentMap<String, Object> map, Map<String, Object> newHash) {
        String[] keyCandidates = extractFilterKeys(keyPaths.getFirst());

        // shift left the paths
//        keyPaths = keyPaths.subList(1, keyPaths.size());
        keyPaths.remove(0);

        for (String keyCandidate : keyCandidates) {
            if (!map.containsKey(keyCandidate)) {
                throw new MetricNotFound(String.format("For path: %s. Map keys: %s", keyCandidate, map.keySet()));
            }

            if (keyPaths.isEmpty()) {
                // End of the user requested path, breaks the recursion
                if (map.get(keyCandidate) instanceof ConcurrentMap) {
                    newHash.put(keyCandidate, transformToHash((ConcurrentMap<String, Object>) map.get(keyCandidate)));
                } else {
                    newHash.put(keyCandidate, map.get(keyCandidate));
                }
            } else {
                if (map.get(keyCandidate) instanceof ConcurrentMap) {
                    newHash.put(keyCandidate, getRecursively(keyPaths, (ConcurrentMap<String, Object>) map.get(keyCandidate), new HashMap<>()));
                } else {
                    newHash.put(keyCandidate, map.get(keyCandidate));
                }
            }
        }
        return newHash;
    }

    /**
     * Transform the ConcurrentMap hash into a Map format,
     * This is used to be serialize at the web api layer.
     * */
    @SuppressWarnings( "unchecked")
    private static Map<String, Object> transformToHash(Map<String, Object> map, Map<String, Object> newHash) {
        map.forEach((key, value) -> {
            if (value instanceof Map) {
                // If the value is a nested map, initialize a new HashMap and recurse
                Map<String, Object> nestedMap = new HashMap<>();
                newHash.put(key, nestedMap);
                transformToHash((Map<String, Object>) value, nestedMap);
            } else {
                // Otherwise, directly copy the value to the new map
                newHash.put(key, value);
            }
        });

        return newHash;
    }

    public static Map<String, Object> transformToHash(Map<String, Object> map) {
        // Start by providing the initial HashMap as an empty map
        return transformToHash(map, new HashMap<>());
    }

    private String[] extractFilterKeys(String key) {
        return key.strip().split("\\s*,\\s*");
    }

    /** This method iterate through the namespace path and try to find the corresponding
     *  value for the path, if any part of the path is not found it will
     *  create it.
     *
     * @param namespacesPath
     *      The path where values should be located.
     * @throws NamespacesExpectedError
     *      Throws if the retrieved object isn't a `Concurrent::Map`.
     * @return
     *       Map where the metrics should be saved. The returned map could contain Metric or another layer of ConcurrentMap.
     */
    @SuppressWarnings("unchecked")
    private ConcurrentMap<String, Object> fetchOrStoreNamespaces(List<String> namespacesPath) {
        int index = 0;
        ConcurrentMap<String, Object> node = store;
        for (String namespace : namespacesPath) {
            Object newNode = node.computeIfAbsent(namespace, k -> new ConcurrentHashMap<>());
            if (! (newNode instanceof ConcurrentMap)) {
                final String error = String.format("Expecting a `Namespaces` but found class:  %s for namespaces_path: #{namespaces_path.first(index + 1)}",
                        node.getClass().getName(), namespacesPath.subList(0, index + 1));
                throw new NamespacesExpectedError(error);
            }
            node = (ConcurrentMap<String, Object>) newNode;

            index++;
        }
        return node;
    }
}
