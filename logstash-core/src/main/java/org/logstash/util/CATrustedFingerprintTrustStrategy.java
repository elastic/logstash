package org.logstash.util;

import com.google.common.io.BaseEncoding;
import org.apache.http.conn.ssl.TrustStrategy;

import java.security.InvalidKeyException;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.security.NoSuchProviderException;
import java.security.SignatureException;
import java.security.cert.CertificateException;
import java.security.cert.X509Certificate;
import java.util.Arrays;
import java.util.Collection;
import java.util.Date;
import java.util.Set;
import java.util.function.Supplier;
import java.util.stream.Collectors;

public class CATrustedFingerprintTrustStrategy implements TrustStrategy {

    private final Set<Fingerprint> trustedFingerprints;
    private final Supplier<Date> dateSupplier;

    public CATrustedFingerprintTrustStrategy(final String hexEncodedTrustedFingerprint) {
        this(hexEncodedTrustedFingerprint, Date::new);
    }

    public CATrustedFingerprintTrustStrategy(final String hexEncodedTrustedFingerprint, final Supplier<Date> dateSupplier) {
        this(Set.of(Fingerprint.fromHex(hexEncodedTrustedFingerprint)), dateSupplier);
    }

    public CATrustedFingerprintTrustStrategy(final Collection<String> hexEncodedTrustedFingerprints) {
        this(hexEncodedTrustedFingerprints, Date::new);
    }

    public CATrustedFingerprintTrustStrategy(final Collection<String> hexEncodedTrustedFingerprints, final Supplier<Date> dateSupplier) {
        this(hexEncodedTrustedFingerprints.stream()
                .map(Fingerprint::fromHex)
                .collect(Collectors.toUnmodifiableSet()),
             dateSupplier);
    }

    CATrustedFingerprintTrustStrategy(final Set<Fingerprint> trustedFingerprints) {
        this(trustedFingerprints, Date::new);
    }

    /**
     *
     * @param trustedFingerprints one or more {@link Fingerprint}s
     * @param dateSupplier a {@link Date} from this {@link Supplier} is used when checking the validitiy of
     *                     a matching certificate
     */
    CATrustedFingerprintTrustStrategy(final Set<Fingerprint> trustedFingerprints, final Supplier<Date> dateSupplier) {
        this.trustedFingerprints = Set.copyOf(trustedFingerprints);
        this.dateSupplier = dateSupplier;
    }

    @Override
    public boolean isTrusted(X509Certificate[] chain, String authType) throws CertificateException {
        if (chain.length == 0 || this.trustedFingerprints.isEmpty()) { return false; }

        final MessageDigest sha256Digest = sha256();

        // traverse up the chain until we find one whose fingerprint matches
        for (int i = 0; i < chain.length; i++) {
            final X509Certificate currentCandidate = chain[i];
            final byte[] derEncoding = currentCandidate.getEncoded();
            Fingerprint candidateFingerprint = new Fingerprint(sha256Digest.digest(derEncoding));
            if (this.trustedFingerprints.contains(candidateFingerprint)) {
                final Date currentDate = dateSupplier.get();
                currentCandidate.checkValidity(currentDate);

                // zip back down the chain and make sure everything is valid
                for(; i > 0; i--) {
                    final X509Certificate signer = chain[i];
                    final X509Certificate signed = chain[i-1];

                    verifyAndValidate(signed, signer, currentDate);
                }
                return true;
            }
        }
        return false;
    }

    private MessageDigest sha256() {
        try {
            return MessageDigest.getInstance("SHA-256");
        } catch (NoSuchAlgorithmException e) {
            throw new IllegalStateException(e);
        }
    }

    private void verifyAndValidate(final X509Certificate signed, final X509Certificate signer, final Date currentDate) throws CertificateException {
        try {
            signed.verify(signer.getPublicKey());
            signed.checkValidity(currentDate);
        } catch (SignatureException e) {
            throw new CertificateException(e);
        } catch (NoSuchAlgorithmException | InvalidKeyException | NoSuchProviderException e) {
            throw new IllegalStateException(e);
        }
    }

    private static class Fingerprint {
        private static final BaseEncoding HEX_ENCODING = BaseEncoding.base16().upperCase();

        static Fingerprint fromHex(final String hexEncodedFingerprint) {
            try {
                final byte[] bytes = HEX_ENCODING.decode(hexEncodedFingerprint.toUpperCase());
                return new Fingerprint(bytes);
            } catch (Exception e) {
                throw new IllegalStateException(String.format("BAD INPUT: `%s`", hexEncodedFingerprint), e);
            }
        }

        private final byte[] value;

        private Fingerprint(final byte[] fingerprint) {
            this.value = fingerprint;
        }

        @Override
        public boolean equals(Object o) {
            if (this == o) return true;
            if (o == null || getClass() != o.getClass()) return false;
            Fingerprint that = (Fingerprint) o;
            return Arrays.equals(value, that.value);
        }

        @Override
        public int hashCode() {
            return Arrays.hashCode(value);
        }
    }
}
