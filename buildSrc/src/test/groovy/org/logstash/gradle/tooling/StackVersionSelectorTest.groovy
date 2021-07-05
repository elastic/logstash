package org.logstash.gradle.tooling

import org.junit.Test

import static org.junit.Assert.assertEquals
import static org.junit.Assert.assertFalse
import static org.junit.Assert.assertNull
import static org.junit.Assert.assertTrue

class StackVersionSelectorTest {

    @Test
    void "selectClosestInList should return the exact match when present"() {
        def sut = new StackVersionSelector("")

        def result = sut.selectClosestInList("7.14.0", [
                "6.8.17-SNAPSHOT",
                "6.8.17",
                "7.13.2-SNAPSHOT",
                "7.13.2",
                "7.13.3-SNAPSHOT",
                "7.13.3",
                "7.14.0-SNAPSHOT",
                "7.14.0",
                "8.0.0-SNAPSHOT"
        ])

        assert "7.14.0" == result
    }
}