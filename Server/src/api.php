<?php
use Psr\Http\Message\ServerRequestInterface as Request;
use Psr\Http\Message\ResponseInterface as Response;

require 'common.php';
require 'database.php';


class API
{
    private $request = null;
    private $response = null;
    private $msg = array();
    private $statusCode = 422;
    private $postData = null;
    private $getData = null;
    private $argsData = null;


    function __construct(
        Request $request,
        Response $response,
        array $args = null
    ) {
        $this->response = $response;
        $this->request = $request;
        $this->postData = $request->getParsedBody();
        $this->getData = $request->getQueryParams();
        $this->argsData = $args;
        $this->msg['error'] = true;
        $this->msg['message'] = "";
        $this->statusCode = 422;
    }

    function __destruct()
    {
        // TODO: Implement __destruct() method.
        unset($this->msg);
    }

    /**
     * @param $required_params
     * @param $data
     * @return bool
     */
    private function haveEmptyParameters(
        array $required_params,
        array $data
    ): bool {
        $error = false;
        foreach ($required_params as $param) {
            if (!isset($data[$param]) || strlen($data[$param]) <= 0) {
                $error = true;
                break;
            }
        }
        return $error;
    }

    /**
     * @return Response
     */
    private function responseMessage(): Response {
        $this->response->getBody()->write(json_encode($this->msg));
        return $this->response
            ->withHeader('Content-type', 'application/json')
            ->withStatus($this->statusCode);
    }

    /**
     * @return Response
     */
    public function challengeFIDO(): Response {
        $data = $this->postData;
        $this->msg['challenge'] = "";
        $this->msg['isBiometric'] = $data['isBiometric'];

        if ($this->haveEmptyParameters(['mode', 'did'], $data) || !isset($data['isBiometric']) ||
            ($data['mode'] != 'identity' && $data['mode'] != 'login')) {
            $this->msg['message'] = 'invalid param';
            return $this->responseMessage();
        }

        $db = new Database();
        $row = $db->getUser($data['did']);

        if ($this->haveEmptyParameters(['phone', 'did', 'pubkey'], $row)) {
            $this->msg['message'] = "doesnt exsit";
            return $this->responseMessage();
        }

        $challenge = "";

        if ($data['mode'] == 'identity' && !$this->haveEmptyParameters(['piecepw'], $row)) {
            $challenge = $row['piecepw'];
        } else if ($data['mode'] == 'login') {
            $plain = hash_hmac('sha256', $row['did'], $row['phone'], true);
            $publicPem = base64_decode($row['pubkey']);
            openssl_public_encrypt(base64_encode($plain), $challenge, $publicPem);
            $challenge = base64_encode($challenge);
        }

        if (!empty($challenge)) {
            $this->msg['error'] = false;
            $this->msg['message'] = 'success';
            $this->msg['challenge'] = $challenge;
            $this->statusCode = 201;
        } else {
            $this->msg['message'] = 'failed load publicKey';
        }

        return $this->responseMessage();
    }

    /**
     * @return Response
     */
    public function login(): Response {
        $data = $this->postData;
        $this->msg['phone'] = "";
        $this->msg['name'] = "";
        $this->msg['birth'] = "";
        $this->msg['regDate'] = "";

        if ($this->haveEmptyParameters(['did', 'challenge'], $data)) {
            $this->msg['message'] = 'invalid param';
            return $this->responseMessage();
        }

        $db = new Database();
        $row = $db->getUser($data['did']);

        if ($row == null) {//($this->haveEmptyParameters(['phone', 'did', 'name', 'regDate'], $row)) {
            $this->msg['message'] = 'doesnt exsit';
            return $this->responseMessage();
        }

        $plain = hash_hmac('sha256', $row['did'], $row['phone'], true);
        if (base64_encode($plain) == $data['challenge']) {
            $this->msg['error'] = false;
            $this->msg['message'] = 'success';
            $this->msg['phone'] = $row['phone'];
            $this->msg['name'] = $row['name'];
            $this->msg['birth'] = $row['birth'];
            $this->msg['regDate'] = $row['regDate'];
            $this->statusCode = 201;
        } else {
            $this->msg['message'] = 'failed verify challenge';
        }

        return $this->responseMessage();
    }

    /**
     * @return Response
     */
    public function identity(): Response {
        $data = $this->postData;
        $this->msg['image'] = "";
        $this->msg['requirerName'] = "";
        $this->msg['validDate'] = "";
        $this->msg['verifyNumber'] = "";
        $this->msg['sign'] = "";

        if ($this->haveEmptyParameters(['did', 'requirer', 'piece', 'challenge'], $data)) {
            $this->msg['message'] = 'invalid param';
            return $this->responseMessage();
        }

        $db = new Database();
        $row = $db->identity($data['did'], $data['requirer']);

        if ($this->haveEmptyParameters(['myPhone', 'myBirth', 'myPiece', 'myIdImageHash', 'rqName', 'rqDid'], $row)) {
            $this->msg['message'] = 'doesnt exsit';
            return $this->responseMessage();
        }

        $key = base64_decode($data['challenge']);
        $iv = substr($key, 0, openssl_cipher_iv_length('aes-256-cbc'));
        $imageCrypto = base64_decode($row['myPiece'].$data['piece']);
        $image = openssl_decrypt($imageCrypto, 'aes-256-cbc', $key, OPENSSL_PKCS1_PADDING, $iv);
        $imageHash = base64_encode(hash('sha256', $image, true));

        if ($imageHash == $row['myIdImageHash']) {
            require_once('hotp.php');
            $this->msg['error'] = false;
            $this->msg['message'] = 'success';
            $this->msg['image'] = $image;
            $this->msg['requirerName'] = $row['rqName'];
            $this->msg['validDate'] = (string)(Date('Y-m-d H:i:s', time() + 60));

            $oneTimeVerifyCode = substr($row['myPhone'], -4);
            $plain = $row['rqDid'].$data['requirer'].$oneTimeVerifyCode;
            $secret = hash('sha256', $plain, true);
            $this->msg['verifyNumber'] = $oneTimeVerifyCode.generateHOTP($secret);
            $plain = $imageHash.$this->msg['requirerName'].$this->msg['validDate'].$this->msg['verifyNumber'];
            $sign = "";
            $privateId = openssl_get_privatekey(file_get_contents('../private.pem'));
            openssl_sign($plain, $sign, $privateId, OPENSSL_ALGO_SHA256);
            $this->msg['sign'] = base64_encode($sign);
            openssl_free_key($privateId);
            $this->statusCode = 201;
        } else {
            $this->msg['message'] = 'failed verify challenge';
        }

        return $this->responseMessage();
    }

    /**
     * @return Response
     */
    public function deleteUser(): Response {
        if ($this->haveEmptyParameters(['did'], $this->argsData)) {
            $this->msg['message'] = 'invalid param';
            return $this->responseMessage();
        }

        $db = new Database();
        if ($db->removeUser($this->argsData['did'])) {
            $this->msg['error'] = false;
            $this->msg['message'] = 'success';
            $this->statusCode = 201;
        } else {
            $this->msg['message'] = 'doesnt exsit';
        }

        return $this->responseMessage();
    }

    public function createUser() {
        $data = $this->postData;
        $this->msg['piece'] = "";

        if ($this->haveEmptyParameters(['phone', 'did', 'name', 'pubkey'], $data)) {
            $this->msg['message'] = 'invalid param';
            return $this->responseMessage();
        }

        $publicPem = pkcs2x509_public(base64_decode($data['pubkey']));;

        if (!$this->haveEmptyParameters(['image', 'hid', 'birth'], $data)) {
            $key = openssl_random_pseudo_bytes(32);
            $iv  = substr($key, 0, openssl_cipher_iv_length('aes-256-cbc'));
            $keyCrypto = "";
            openssl_public_encrypt($key, $keyCrypto, $publicPem);

            if (!empty($keyCrypto)) {
                $b64ImageHash   = base64_encode(hash('sha256', $data['image'], true));
                $b64ImageCrypto = base64_encode(openssl_encrypt($data['image'], 'aes-256-cbc', $key, OPENSSL_PKCS1_PADDING, $iv));
                $pieceServer    = substr($b64ImageCrypto, 0, 64);
                $pieceClient    = substr($b64ImageCrypto, 64);

                $db = new Database();
                if ($db->registerUser($data['phone'], $data['did'], $data['name'], base64_encode($publicPem),
                    $data['hid'], $data['birth'], $pieceServer, $b64ImageHash, base64_encode($keyCrypto))) {
                    $this->msg['error'] = false;
                    $this->msg['piece'] = $pieceClient;
                    $this->msg['message'] = 'success';
                    $this->statusCode = 201;
                } else {
                    $this->msg['message'] = $db->lastErrno;
                }
            } else {
                $this->msg['message'] = 'failed load publicKey';
            }
        } else {
            $db = new Database();
            if ($db->registerUser($data['phone'], $data['did'], $data['name'], base64_encode($publicPem))) {
                $this->msg['error'] = false;
                $this->msg['message'] = 'success';
                $this->statusCode = 201;
            } else {
                $this->msg['message'] = $db->lastErrno;
            }
        }

        return $this->responseMessage();
    }
}
