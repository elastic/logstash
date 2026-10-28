import java.io.InputStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.security.KeyStore;
import java.security.MessageDigest;
import java.security.Provider;
import java.security.Security;
import java.security.cert.CertPathValidator;
import java.security.cert.CertPathValidatorException;
import java.security.cert.Certificate;
import java.security.cert.CertificateFactory;
import java.security.cert.PKIXParameters;
import java.security.cert.TrustAnchor;
import java.security.cert.X509Certificate;
import java.time.Instant;
import java.util.ArrayList;
import java.util.Collections;
import java.util.HashSet;
import java.util.HexFormat;
import java.util.List;
import java.util.Map;
import java.util.Set;

/**
 * Checks that a trust store does not trust distrusted roots.
 * usage: java BundledJdkTrustCheck.java artifact JDK_HOME JDK_VERSION_FILE FIXTURES_DIR
 *        java -cp bc-fips.jar BundledJdkTrustCheck.java bcfks FILE FIXTURES_DIR
 */
public class BundledJdkTrustCheck {

    // SHA-256 public key hashes of roots that must not be trusted
    static final Map<String, String> DISTRUSTED = Map.of(
        "8D417DB2DD8BF5E3084D1E3F196D583849D81BDD4C00C70B9D39369E96B8C782", "emSign ECC Root CA - G3"
    );

    static final Instant VALIDATION_TIME = Instant.parse("2026-10-21T00:00:00Z");

    public static void main(String[] args) throws Exception {
        List<String> failures = new ArrayList<>();
        List<X509Certificate> anchors;
        Path fixtures;
        if (args[0].equals("artifact")) {
            Path jdkHome = Path.of(args[1]);
            fixtures = Path.of(args[3]);
            anchors = keyStore(jdkHome.resolve("lib/security/cacerts"), "PKCS12", null);
            String jdkVersion = Files.readString(Path.of(args[2])).strip();
            String release = Files.readAllLines(jdkHome.resolve("release")).stream()
                .filter(line -> line.startsWith("IMPLEMENTOR_VERSION="))
                .map(line -> line.substring(line.indexOf('=') + 1).replace("\"", ""))
                .findFirst().orElse("missing");
            System.out.println("  JDK " + release);
            if (!jdkVersion.equals(release)) {
                failures.add("JDK_VERSION is " + jdkVersion + " but the bundled JDK is " + release);
            }
        } else {
            fixtures = Path.of(args[2]);
            Security.addProvider((Provider) Class.forName("org.bouncycastle.jcajce.provider.BouncyCastleFipsProvider")
                .getDeclaredConstructor().newInstance());
            anchors = keyStore(Path.of(args[1]), "BCFKS", "changeit".toCharArray());
        }
        check(anchors, fixtures, failures);
        failures.forEach(failure -> System.out.println("  FAIL " + failure));
        System.exit(failures.isEmpty() ? 0 : 1);
    }

    static void check(List<X509Certificate> anchors, Path fixtures, List<String> failures) throws Exception {
        System.out.println("  " + anchors.size() + " trust anchors");
        if (anchors.size() < 100) {
            failures.add("only " + anchors.size() + " trust anchors");
        }
        for (X509Certificate anchor : anchors) {
            String name = DISTRUSTED.get(spkiSha256(anchor.getPublicKey().getEncoded()));
            if (name != null) {
                failures.add("trusts " + name);
            }
        }

        CertificateFactory factory = CertificateFactory.getInstance("X.509");
        X509Certificate root = load(factory, fixtures.resolve("emsign-ecc-root-ca-g3.crt"));
        List<X509Certificate> chain = List.of(
            load(factory, fixtures.resolve("em-dv-tls-ca-g3b-emsign.crt")),
            load(factory, fixtures.resolve("emsign-root-tls-ca-g3-by-emsign-ecc-root-ca-g3.crt"))
        );
        if (!validates(factory, chain, List.of(root))) {
            failures.add("control: chain does not validate against emSign ECC Root CA - G3 itself");
        }
        if (validates(factory, chain, anchors)) {
            failures.add("trusts a chain to emSign ECC Root CA - G3");
        }
    }

    static boolean validates(CertificateFactory factory, List<X509Certificate> chain, List<X509Certificate> anchors) throws Exception {
        Set<TrustAnchor> trustAnchors = new HashSet<>();
        anchors.forEach(anchor -> trustAnchors.add(new TrustAnchor(anchor, null)));
        PKIXParameters params = new PKIXParameters(trustAnchors);
        params.setRevocationEnabled(false);
        params.setDate(java.util.Date.from(VALIDATION_TIME));
        try {
            CertPathValidator.getInstance("PKIX").validate(factory.generateCertPath(chain), params);
            return true;
        } catch (CertPathValidatorException e) {
            return false;
        }
    }

    static List<X509Certificate> keyStore(Path file, String type, char[] password) throws Exception {
        KeyStore keyStore = KeyStore.getInstance(type);
        try (InputStream in = Files.newInputStream(file)) {
            keyStore.load(in, password);
        }
        List<X509Certificate> anchors = new ArrayList<>();
        for (String alias : Collections.list(keyStore.aliases())) {
            Certificate certificate = keyStore.getCertificate(alias);
            if (certificate instanceof X509Certificate x509) {
                anchors.add(x509);
            }
        }
        return anchors;
    }

    static X509Certificate load(CertificateFactory factory, Path path) throws Exception {
        try (InputStream in = Files.newInputStream(path)) {
            return (X509Certificate) factory.generateCertificate(in);
        }
    }

    static String spkiSha256(byte[] encoded) throws Exception {
        return HexFormat.of().withUpperCase().formatHex(MessageDigest.getInstance("SHA-256").digest(encoded));
    }
}
