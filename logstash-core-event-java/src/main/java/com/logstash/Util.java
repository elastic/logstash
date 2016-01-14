package com.logstash;

import java.util.ArrayList;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;

public class Util {
    private Util() {}

    public static void mapMerge(Map<String, Object> target, Map<String, Object> add) {
        for (Map.Entry<String, Object> e : add.entrySet()) {
            if (target.containsKey(e.getKey())) {
                if (target.get(e.getKey()) instanceof Map && e.getValue() instanceof Map) {
                    mapMerge((Map<String, Object>) target.get(e.getKey()), (Map<String, Object>) e.getValue());
                } else if (e.getValue() instanceof List) {
                    if (target.get(e.getKey()) instanceof List) {
                        // needs optimizing
                        List targetList = (List) target.get(e.getKey());
                        targetList.addAll((List) e.getValue());
                        target.put(e.getKey(), new ArrayList<Object>(new LinkedHashSet<Object>(targetList)));
                    } else {
                        Object targetValue = target.get(e.getKey());
                        List targetValueList = new ArrayList();
                        targetValueList.add(targetValue);
                        for (Object o : (List) e.getValue()) {
                            if (!targetValue.equals(o)) {
                                targetValueList.add(o);
                            }
                        }
                        target.put(e.getKey(), targetValueList);
                    }
                } else if (target.get(e.getKey()) instanceof List) {
                    List t = ((List) target.get(e.getKey()));
                    if (!t.contains(e.getValue())) {
                        t.add(e.getValue());
                    }
                } else if (!target.get(e.getKey()).equals(e.getValue())) {
                    List targetValue = new ArrayList();
                    targetValue.add(target.get(e.getKey()));
                    ((List) targetValue).add(e.getValue());
                    target.put(e.getKey(), targetValue);
                }
            } else {
                target.put(e.getKey(), e.getValue());
            }
        }
    }
}
