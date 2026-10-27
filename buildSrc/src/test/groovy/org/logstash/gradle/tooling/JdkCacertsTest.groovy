package org.logstash.gradle.tooling

import org.gradle.api.GradleException
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.Test
import org.junit.jupiter.api.io.TempDir

import java.nio.file.Path
import java.security.KeyStore
import java.security.cert.CertificateFactory
import java.security.cert.X509Certificate

import static org.junit.jupiter.api.Assertions.assertEquals
import static org.junit.jupiter.api.Assertions.assertThrows

class JdkCacertsTest {
    static final File FIXTURES = new File("src/test/resources/distrusted_ca_certs")
    // emSign Root TLS CA - G3
    static final String REMOVED_SPKI = "C619E4780ED8E0ABEDA24AD732567DE4383A7EA941338F6D1A7D1B49AC792FE9"

    @TempDir
    public Path tempDir

    File cacerts

    @BeforeEach
    void setUp() {
        KeyStore keyStore = KeyStore.getInstance("PKCS12")
        keyStore.load(null, null)
        keyStore.setCertificateEntry("removed", certificate("emsign-root-tls-ca-g3-by-emsign-ecc-root-ca-g3.crt"))
        keyStore.setCertificateEntry("kept", certificate("em-dv-tls-ca-g3b-emsign.crt"))
        cacerts = tempDir.resolve("cacerts").toFile()
        // unprotected like the JDK's cacerts; JDK 17 otherwise encrypts the entries
        System.setProperty("keystore.pkcs12.certProtectionAlgorithm", "NONE")
        System.setProperty("keystore.pkcs12.macAlgorithm", "NONE")
        try {
            cacerts.withOutputStream { keyStore.store(it, null) }
        } finally {
            System.clearProperty("keystore.pkcs12.certProtectionAlgorithm")
            System.clearProperty("keystore.pkcs12.macAlgorithm")
        }
    }

    @Test
    void "removes the anchors with a matching public key"() {
        JdkCacerts.removeTrustAnchors(cacerts, [REMOVED_SPKI])

        KeyStore keyStore = KeyStore.getInstance("PKCS12")
        cacerts.withInputStream { keyStore.load(it, null) }
        assertEquals(["kept"], Collections.list(keyStore.aliases()))
    }

    @Test
    void "fails and leaves the file untouched when an anchor is missing"() {
        byte[] before = cacerts.bytes
        assertThrows(GradleException) { JdkCacerts.removeTrustAnchors(cacerts, [REMOVED_SPKI, "00" * 32]) }
        assertEquals(before.toList(), cacerts.bytes.toList())
    }

    static X509Certificate certificate(String name) {
        new File(FIXTURES, name).withInputStream { (X509Certificate) CertificateFactory.getInstance("X.509").generateCertificate(it) }
    }
}
