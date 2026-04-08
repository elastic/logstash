/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License;
 * you may not use this file except in compliance with the Elastic License.
 */


package org.logstash.xpack.test;

import org.junit.Test;

import java.util.Arrays;
import java.util.List;

public class RSpecIntegrationTests extends RSpecTests {

    @Override
    protected List<String> rspecArgs() {
        String specs = System.getProperty("org.logstash.xpack.integration.specs", "qa/integration");
        return Arrays.asList("-fd", specs);
    }

    @Test
    @Override
    public void rspecTests() throws Exception {
        super.rspecTests();
    }

}
