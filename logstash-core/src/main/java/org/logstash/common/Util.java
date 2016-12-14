package org.logstash.common;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;

/**
 * Created by andrewvc on 12/23/16.
 */
public class Util {
    // Modified from http://stackoverflow.com/a/11009612/11105
    public static String sha256(String base) {
        try {
            MessageDigest digest = MessageDigest.getInstance("SHA-256");
            byte[] hash = digest.digest(base.getBytes(StandardCharsets.UTF_8));
            return bytesToHexString(hash);
        } catch (NoSuchAlgorithmException e) {
            throw new RuntimeException("Your system is (somehow) missing the SHA-256 algorithm!", e);
        }
    }

    public static String bytesToHexString(byte[] bytes) {
        StringBuilder hexString = new StringBuilder();

        for (byte aHash : bytes) {
            String hex = Integer.toHexString(0xff & aHash);
            if (hex.length() == 1) hexString.append('0');
            hexString.append(hex);
        }

        return hexString.toString();
    }
}
