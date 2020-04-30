/*
 * Licensed to Elasticsearch B.V. under one or more contributor
 * license agreements. See the NOTICE file distributed with
 * this work for additional information regarding copyright
 * ownership. Elasticsearch B.V. licenses this file to you under
 * the Apache License, Version 2.0 (the "License"); you may
 * not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *	http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */


package org.logstash.plugins;

import co.elastic.logstash.api.Codec;
import co.elastic.logstash.api.Filter;
import co.elastic.logstash.api.Input;
import co.elastic.logstash.api.Output;

import java.lang.reflect.Method;
import java.util.Arrays;

/**
 * Validates that Java plugins support the Java plugin API in this release of Logstash.
 */
public class PluginValidator {

    private static final Method[] inputMethods;
    private static final Method[] filterMethods;
    private static final Method[] codecMethods;
    private static final Method[] outputMethods;

    static {
        inputMethods = Input.class.getMethods();
        filterMethods = Filter.class.getMethods();
        codecMethods = Codec.class.getMethods();
        outputMethods = Output.class.getMethods();
    }

    public static boolean validatePlugin(PluginLookup.PluginType type, Class<?> pluginClass) {
        switch (type) {
            case INPUT:
                return containsAllMethods(inputMethods, pluginClass.getMethods());
            case FILTER:
                return containsAllMethods(filterMethods, pluginClass.getMethods());
            case CODEC:
                return containsAllMethods(codecMethods, pluginClass.getMethods());
            case OUTPUT:
                return containsAllMethods(outputMethods, pluginClass.getMethods());
            default:
                throw new IllegalStateException("Unknown plugin type for validation: " + type);
        }
    }

    private static boolean containsAllMethods(Method[] apiMethods, Method[] pluginMethods) {
        boolean matches = true;
        for (int k = 0; matches && k < apiMethods.length; k++) {
            int finalK = k;
            matches = Arrays.stream(pluginMethods).anyMatch(m -> methodsMatch(apiMethods[finalK], m));
        }
        return matches;
    }

    private static boolean methodsMatch(Method apiMethod, Method pluginMethod) {
        return apiMethod.getName().equals(pluginMethod.getName()) &&
                apiMethod.getReturnType() == pluginMethod.getReturnType() &&
                Arrays.equals(apiMethod.getParameterTypes(), pluginMethod.getParameterTypes());
    }
}
