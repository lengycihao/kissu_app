import java.io.FileInputStream;
import java.security.MessageDigest;
import java.security.cert.CertificateFactory;
import java.security.cert.X509Certificate;

public class GetMD5 {
    public static void main(String[] args) {
        try {
            // 读取keystore文件
            FileInputStream fis = new FileInputStream("app/kissu1.keystore");
            java.security.KeyStore keystore = java.security.KeyStore.getInstance("JKS");
            keystore.load(fis, "111111".toCharArray());
            
            // 获取证书
            java.security.cert.Certificate cert = keystore.getCertificate("kissu");
            X509Certificate x509Cert = (X509Certificate) cert;
            
            // 计算MD5
            MessageDigest md = MessageDigest.getInstance("MD5");
            byte[] certBytes = x509Cert.getEncoded();
            byte[] md5Bytes = md.digest(certBytes);
            
            // 转换为十六进制字符串
            StringBuilder sb = new StringBuilder();
            for (byte b : md5Bytes) {
                sb.append(String.format("%02X:", b));
            }
            String md5 = sb.toString().substring(0, sb.length() - 1); // remove last colon
            
            System.out.println("MD5: " + md5);
            
            // 同时计算SHA1
            MessageDigest sha1 = MessageDigest.getInstance("SHA1");
            byte[] sha1Bytes = sha1.digest(certBytes);
            StringBuilder sha1Sb = new StringBuilder();
            for (byte b : sha1Bytes) {
                sha1Sb.append(String.format("%02X:", b));
            }
            String sha1Str = sha1Sb.toString().substring(0, sha1Sb.length() - 1);
            System.out.println("SHA1: " + sha1Str);
            
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
}
