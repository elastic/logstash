package org.logstash.secret;


import org.junit.Test;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Unit tests for {@link SecretIdentifier}
 */
public class SecretIdentifierTest {

    /**
     * Example usage
     */
    @Test
    public void testBasic() {
        SecretIdentifier id = new SecretIdentifier("foo");
        assertThat(id.toExternalForm()).isEqualTo("urn:logstash:secret:v1:foo");
        assertThat(id.getKey()).isEqualTo("foo");
    }

    /**
     * identifiers are case insensitive
     */
    @Test
    public void testCase() {
        SecretIdentifier id = new SecretIdentifier("FOO");
        assertThat(id.toExternalForm()).isEqualTo("urn:logstash:secret:v1:foo");
        SecretIdentifier id2 = new SecretIdentifier("foo");
        assertThat(id).isEqualTo(id2);
        assertThat(id.getKey()).isEqualTo(id2.getKey());
        assertThat(id.toExternalForm()).isEqualTo(id.toExternalForm()).isEqualTo(id.toString()).isEqualTo(id2.toString());
    }

    /**
     * Colons get transformed to underscores
     */
    @Test
    public void testColon() {
        SecretIdentifier id = new SecretIdentifier("foo:bar");
        assertThat(id.toExternalForm()).isEqualTo("urn:logstash:secret:v1:foo_bar");
    }

    @Test(expected = IllegalArgumentException.class)
    public void testEmptyKey() {
        new SecretIdentifier("");
    }

    /**
     * valid urns should be able to be constructed from the urn
     */
    @Test
    public void testFromExternal() {
        assertThat(SecretIdentifier.fromExternalForm("urn:logstash:secret:v1:foo")).isEqualTo(new SecretIdentifier("foo"));
        assertThat(SecretIdentifier.fromExternalForm("urn:logstash:secret:v1:foo:bar")).isEqualTo(new SecretIdentifier("foo:bar"));
    }

    /**
     * invalid urn's return null
     */
    @Test
    public void testFromExternalInvalid() {
        assertThat(SecretIdentifier.fromExternalForm("urn:logstash:secret:nope:foo")).isNull();
        assertThat(SecretIdentifier.fromExternalForm("urn:logstash:foo")).isNull();
    }

    @Test(expected = IllegalArgumentException.class)
    public void testNullKey() {
        new SecretIdentifier(null);
    }

}