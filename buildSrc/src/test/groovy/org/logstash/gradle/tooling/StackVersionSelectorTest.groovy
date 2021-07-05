package org.logstash.gradle.tooling

import org.junit.Test
import org.junit.Before

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

    @Test
    void "selectClosestInList should return the previous closest version when exact match is not present"() {
        assert "7.14.0" == sut.selectClosestInList("7.15.0", versionsFixture)
    }

    @Test
    void "selectClosestInList should return the greatest version when the version is greater than the max"() {
        assert "8.0.0-SNAPSHOT" == sut.selectClosestInList("8.0.0", versionsFixture)
    }

    @Test
    void "versionComparator tests"() {
        def versionComparator = new StackVersionSelector.VersionComparator()
        assert -1 == versionComparator.compare("7.1.0", "7.2.1")
        assert 1 == versionComparator.compare("7.2.1", "7.1.0")

        assert 1 == versionComparator.compare("7.1.0", "7.1.0-SNAPSHOT")

        assert 1 == versionComparator.compare("7.2.1-SNAPSHOT", "7.1.0-SNAPSHOT")

        assert 1 == versionComparator.compare("7.2.1-SNAPSHOT", "7.1.0")

        assert 1 == versionComparator.compare("7.2.1", "7.1.0-SNAPSHOT")

        assert 1 == versionComparator.compare("8.0.0-alpha1", "7.1.0-SNAPSHOT")

        assert 1 == versionComparator.compare("8.0.0-alpha1", "8.0.0-SNAPSHOT")

        assert 1 == versionComparator.compare("8.0.0-rc1", "8.0.0-alpha2")

        assert 1 == versionComparator.compare("8.0.0", "8.0.0-alpha2")

        assert 1 == versionComparator.compare("8.0.0", "8.0.0-SNAPSHOT")

    }
}