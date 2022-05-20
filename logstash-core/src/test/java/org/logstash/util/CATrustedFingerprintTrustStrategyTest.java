package org.logstash.util;

import org.junit.Before;
import org.junit.Test;

import java.io.IOException;
import java.io.InputStream;
import java.nio.charset.StandardCharsets;
import java.security.cert.CertificateException;
import java.security.cert.CertificateFactory;
import java.security.cert.X509Certificate;
import java.text.ParseException;
import java.text.SimpleDateFormat;
import java.time.temporal.ChronoUnit;
import java.util.Date;

import static org.junit.Assert.assertFalse;
import static org.junit.Assert.assertTrue;

public class CATrustedFingerprintTrustStrategyTest {
    private static final X509Certificate CERTIFICATE_ROOT = loadX509Certificate("x509_certificates/generated/root.crt");
    private static final X509Certificate CERTIFICATE_INTERMEDIATE = loadX509Certificate("x509_certificates/generated/intermediate-ca.crt");
    private static final X509Certificate CERTIFICATE_SERVER = loadX509Certificate("x509_certificates/generated/server_from_intermediate.crt");

    private static final String FINGERPRINT_ROOT = loadFingerprint("x509_certificates/generated/root.der.sha256");
    private static final String FINGERPRINT_INTERMEDIATE = loadFingerprint("x509_certificates/generated/intermediate-ca.der.sha256");
    private static final String FINGERPRINT_SERVER = loadFingerprint("x509_certificates/generated/server_from_intermediate.der.sha256");

    private static final Date DATE_CERTS_GENERATION = loadGeneratedDate("x509_certificates/generated/GENERATED_AT");
    private static final Date DATE_CERTS_VALID = Date.from(DATE_CERTS_GENERATION.toInstant().plus(5, ChronoUnit.MINUTES));
    private static final Date DATE_CERTS_EXPIRED = Date.from(DATE_CERTS_GENERATION.toInstant().plus(5000, ChronoUnit.DAYS));

    @Before
    public void puts() {
        System.out.format("ROOT: `%s` (%s)\n", FINGERPRINT_ROOT, CERTIFICATE_ROOT.getSubjectX500Principal());
        System.out.format("INTR: `%s` (%s)\n", FINGERPRINT_INTERMEDIATE, CERTIFICATE_INTERMEDIATE.getSubjectX500Principal());
        System.out.format("SRVR: `%s` (%s)\n", FINGERPRINT_SERVER, CERTIFICATE_SERVER.getSubjectX500Principal());
    }

    @Test
    public void testIsTrustedWhenAMatchingValidCertificateIsRootOfTheChain() throws CertificateException {
        final CATrustedFingerprintTrustStrategy trustStrategy = new CATrustedFingerprintTrustStrategy(FINGERPRINT_ROOT, ()-> DATE_CERTS_VALID);
        final X509Certificate[] chain = {CERTIFICATE_SERVER, CERTIFICATE_INTERMEDIATE, CERTIFICATE_ROOT};

        assertTrue(trustStrategy.isTrusted(chain, "noop"));
    }

    @Test
    public void testIsTrustedWhenAMatchingValidCertificateIsIntermediateOfTheChain() throws CertificateException {
        final CATrustedFingerprintTrustStrategy trustStrategy = new CATrustedFingerprintTrustStrategy(FINGERPRINT_INTERMEDIATE, ()-> DATE_CERTS_VALID);
        final X509Certificate[] chain = {CERTIFICATE_SERVER, CERTIFICATE_INTERMEDIATE, CERTIFICATE_ROOT};

        assertTrue(trustStrategy.isTrusted(chain, "noop"));
    }

    @Test(expected = CertificateException.class)
    public void testIsTrustedWhenAMatchingExpiredCertificateIsOnTheChain() throws CertificateException {
        final CATrustedFingerprintTrustStrategy trustStrategy = new CATrustedFingerprintTrustStrategy(FINGERPRINT_ROOT, ()-> DATE_CERTS_EXPIRED);
        final X509Certificate[] chain = {CERTIFICATE_SERVER, CERTIFICATE_INTERMEDIATE, CERTIFICATE_ROOT};

        trustStrategy.isTrusted(chain, "noop");
    }

    @Test
    public void testIsTrustedWhenNoMatchingCertificateIsOnTheChain() throws CertificateException {
        final CATrustedFingerprintTrustStrategy trustStrategy = new CATrustedFingerprintTrustStrategy("abad1deaabad1deaabad1deaabad1deaabad1deaabad1deaabad1deaabad1dea", ()-> DATE_CERTS_VALID);
        final X509Certificate[] chain = {CERTIFICATE_SERVER, CERTIFICATE_INTERMEDIATE, CERTIFICATE_ROOT};

        assertFalse(trustStrategy.isTrusted(chain, "noop"));
    }

    @Test(expected = CertificateException.class)
    public void testIsTrustedWhenDisjointedChainPresented() throws CertificateException {
        final CATrustedFingerprintTrustStrategy trustStrategy = new CATrustedFingerprintTrustStrategy(FINGERPRINT_ROOT, ()-> DATE_CERTS_VALID);
        final X509Certificate[] chain = {CERTIFICATE_SERVER, CERTIFICATE_ROOT};

        trustStrategy.isTrusted(chain, "noop");
    }

    private static InputStream getResource(final String name) {
        return CATrustedFingerprintTrustStrategyTest.class.getResourceAsStream(name);
    }

    private static X509Certificate loadX509Certificate(final String name) {
        try {
            final CertificateFactory cf = CertificateFactory.getInstance("X.509");
            return (X509Certificate) cf.generateCertificate(getResource(name));
        } catch (CertificateException e) {
            throw new IllegalStateException(String.format("FILE: %s", name), e);
        }
    }

    private static String loadFingerprint(final String name) {
        final InputStream inputStream = getResource(name);
        try {
            return new String(inputStream.readAllBytes(), StandardCharsets.UTF_8).trim();
        } catch (IOException e) {
            throw new IllegalStateException(String.format("FILE: %s", name), e);
        }
    }

    private static Date loadGeneratedDate(final String name) {
        try {
            final String generatedDate = new String(getResource(name).readAllBytes(), StandardCharsets.UTF_8);
            return new SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ssXXX").parse(generatedDate);
        } catch (IOException | ParseException e) {
            throw new IllegalStateException(String.format("FILE: %s", name), e);
        }
    }
}