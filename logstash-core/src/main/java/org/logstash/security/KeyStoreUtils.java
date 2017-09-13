package org.logstash.security;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.security.KeyFactory;
import java.security.NoSuchAlgorithmException;
import java.security.PrivateKey;
import java.security.spec.InvalidKeySpecException;
import java.security.spec.PKCS8EncodedKeySpec;
import java.util.Base64;
import java.util.LinkedList;
import java.util.List;

class KeyStoreUtils {
    private static final String RSA_PEM_HEADER = "-----BEGIN PRIVATE KEY-----";
    private static final String RSA_PEM_FOOTER = "-----END PRIVATE KEY-----";

    static PrivateKey loadPrivateKeyPEM(Path path) throws IOException, NoSuchAlgorithmException, InvalidKeySpecException {

        List<String> lines = Files.readAllLines(path);
        List<String> keyLines = new LinkedList<>();

        // Look for the key entry
        boolean foundStart = false;
        for (String line : lines) {
            if (!foundStart) {
                if (line.equals(RSA_PEM_HEADER)) {
                    foundStart = true;
                    continue;
                }
            } else {
                if (line.equals(RSA_PEM_FOOTER)) {
                    break;
                }
            }
            keyLines.add(line);
        }

        byte[] pkcs8bytes = Base64.getDecoder().decode(String.join("", keyLines).getBytes());

        KeyFactory keyFactory = KeyFactory.getInstance("RSA");

        PKCS8EncodedKeySpec pkcs8 = new PKCS8EncodedKeySpec(pkcs8bytes);
        return keyFactory.generatePrivate(pkcs8);
    }
}
