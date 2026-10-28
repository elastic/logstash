package org.logstash.gradle.tooling

import org.gradle.api.GradleException

import java.security.KeyStore
import java.security.MessageDigest

/**
 * Removes trust anchors from a JDK's {@code cacerts} by the SHA-256 hash of their public key.
 * Fails if one of them is not in the store.
 */
class JdkCacerts {

    static void removeTrustAnchors(File cacerts, Collection<String> spkiSha256s) {
        KeyStore keyStore = KeyStore.getInstance("PKCS12")
        cacerts.withInputStream { keyStore.load(it, null) }

        Map<String, String> matches = Collections.list(keyStore.aliases()).collectEntries { alias ->
            [alias, spkiSha256(keyStore.getCertificate(alias).publicKey.encoded)]
        }.findAll { alias, spki -> spkiSha256s.contains(spki) }
        Collection<String> missing = spkiSha256s - matches.values()
        if (missing) {
            throw new GradleException("Expected trust anchors with public key SHA-256 ${missing} in [${cacerts}]")
        }

        matches.keySet().each { keyStore.deleteEntry(it) }
        ByteArrayOutputStream updated = new ByteArrayOutputStream()
        keyStore.store(updated, null)
        cacerts.bytes = updated.toByteArray()
    }

    static String spkiSha256(byte[] encodedPublicKey) {
        return MessageDigest.getInstance("SHA-256").digest(encodedPublicKey).encodeHex().toString().toUpperCase(Locale.ROOT)
    }
}
