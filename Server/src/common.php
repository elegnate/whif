<?php
/*
 * @param $key
 * @return string
 */
function pkcs2x509_public($key) {
    $key = str_replace(['-----BEGIN RSA PUBLIC KEY-----', '-----END RSA PUBLIC KEY-----', "\r\n", "\n"],
        ['', '', "\n", ''], $key);

    $key = 'MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8A'.trim($key);
    $x509 = "-----BEGIN PUBLIC KEY-----\n".wordwrap($key, 64, "\n", true)."\n-----END PUBLIC KEY-----";
    return $x509;
}

?>
