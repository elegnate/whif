<?php
declare(strict_types=1);

function generateHOTP(
    string $key,
    int $counter = -1,
    int $digits = 6
): string {
    $counter = $counter < 0 ? time() : $counter;
    $plain   = pack('J', $counter);
    $hash    = hash_hmac('sha256', $plain, $key, true);
    $offset  = ord($hash[19]) & 0x0F;
    $base    = unpack('N', substr($hash, $offset, 4))[1] & 0x7FFFFFFF;
    $token   = (string)($base % pow(10, $digits));
    return str_pad($token, $digits, "0", STR_PAD_LEFT);
}
