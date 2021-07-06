package org.logstash.gradle.tooling

import org.junit.Test
import org.junit.Before

import static org.logstash.gradle.tooling.StackVersionSelector.*
import static org.logstash.gradle.tooling.StackVersionSelector.StackVersion.*

class StackVersionSelectorTest {

    def versionsFixture = [
            asVersion("6.8.17-SNAPSHOT"),
            asVersion("6.8.17"),
            asVersion("7.13.2-SNAPSHOT"),
            asVersion("7.13.2"),
            asVersion("7.13.3-SNAPSHOT"),
            asVersion("7.13.3"),
            asVersion("7.14.0-SNAPSHOT"),
            asVersion("7.14.0"),
            asVersion("8.0.0-SNAPSHOT")
    ]

    def sut

    @Before
    void setUp() {
        sut = new StackVersionSelector("")
    }

    @Test
    void "selectClosestInList should return the exact match when present"() {
        assert "7.14.0" == sut.selectClosestInList(asVersion("7.14.0"), versionsFixture).toString()
    }

    @Test
    void "selectClosestInList should return the previous closest version when exact match is not present"() {
        assert "7.14.0" == sut.selectClosestInList(asVersion("7.15.0"), versionsFixture).toString()
    }

    @Test
    void "selectClosestInList should return the greatest version when the version is greater than the max"() {
        assert "8.0.0-SNAPSHOT" == sut.selectClosestInList(asVersion("8.0.0"), versionsFixture).toString()
    }

    @Test
    void "compare StackVersion tests"() {
        assert asVersion("7.1.0") < asVersion("7.2.1")
        assert asVersion("7.2.1") > asVersion("7.1.0")

        assert asVersion("7.1.0") > asVersion("7.1.0-SNAPSHOT")

        assert asVersion("7.9.0") < asVersion("7.10.0")

        assert asVersion("7.2.1-SNAPSHOT") > asVersion("7.1.0-SNAPSHOT")

        assert asVersion("7.2.1-SNAPSHOT") > asVersion("7.1.0")

        assert asVersion("7.2.1") > asVersion("7.1.0-SNAPSHOT")

        assert asVersion("8.0.0-alpha1") > asVersion("7.1.0-SNAPSHOT")

        assert asVersion("8.0.0-alpha1") > asVersion("8.0.0-SNAPSHOT")

        assert asVersion("8.0.0-rc1") > asVersion("8.0.0-alpha2")

        assert asVersion("8.0.0") > asVersion("8.0.0-alpha2")

        assert asVersion("8.0.0") > asVersion("8.0.0-SNAPSHOT")
    }
}