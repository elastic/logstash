package org.logstash.gradle.tooling

import org.junit.Test
import org.junit.Before

import static org.junit.Assert.assertEquals
import static org.junit.Assert.assertFalse
import static org.junit.Assert.assertNull
import static org.junit.Assert.assertTrue

class StackVersionSelectorTest {

    def versionsFixture = [
            "6.8.17-SNAPSHOT",
            "6.8.17",
            "7.13.2-SNAPSHOT",
            "7.13.2",
            "7.13.3-SNAPSHOT",
            "7.13.3",
            "7.14.0-SNAPSHOT",
            "7.14.0",
            "8.0.0-SNAPSHOT"
    ]

    def sut

    @Before
    void setUp() {
        sut = new StackVersionSelector("")
    }

    @Test
    void "selectClosestInList should return the exact match when present"() {
        assert "7.14.0" == sut.selectClosestInList("7.14.0", versionsFixture)
    }
}