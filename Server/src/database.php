<?php
define('DB_USERNAME', 'mid_u');
define('DB_PASSWORD', 'mid');
define('DB_USER_TB', 'u5er_t6');

class Database {

    protected $conn = null;
    private   $mysql_path = "mysql:host=localhost;port=3306;dbname=mid_db;charset=utf8";
    public    $lastErrno  = "";


    function __construct()
    {
        $this->connection();
    }

    function __destruct()
    {
        // TODO: Implement __destruct() method.
        $this->release();
    }

    /**
     * @return bool
     */
    function connection()
    {
        try {
            if (is_null($this->conn)) {
                $this->conn = new PDO($this->mysql_path, DB_USERNAME, DB_PASSWORD);
                $this->conn->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
                return true;
            } else {
                $this->lastErrno = "Already connected. Please disconnect and retry.";
            }
        } catch (PDOException $e) {
            echo $e->getCode();
            $this->lastErrno = $e->getCode();
        }
        return false;
    }

    function release()
    {
        unset($this->conn);
        $this->conn = null;
    }

    /**
     * @param $phone
     * @param $did
     * @param $name
     * @param $publicKey
     * @param $hid
     * @param $birth
     * @param $piece
     * @param null $idImageHash
     * @param null $idImagePassword
     * @return bool
     */
    function registerUser($phone, $did, $name, $publicKey,
                          $hid = null, $birth = null, $piece = null, $idImageHash = null, $idImagePassword = null)
    {
        try {
            $qry = "insert into ".DB_USER_TB." (phone, devid, humid, name, birth, reg_date, piece, piecehash, piecepw, pubkey) 
                    value(?, ?, ?, ?, ?, now(), ?, ?, ?, ?) 
                    ON DUPLICATE KEY UPDATE 
                    humid=?, birth=?, reg_date=now(), piece=?, piecehash=?, piecepw=?, pubkey=?, del_date=null";
            $stmt = $this->conn->prepare($qry);
            $stmt->bindParam(1, $phone, PDO::PARAM_STR);
            $stmt->bindParam(2, $did, PDO::PARAM_STR);
            $stmt->bindParam(3, $hid, PDO::PARAM_STR);
            $stmt->bindParam(4, $name, PDO::PARAM_STR);
            $stmt->bindParam(5, $birth, PDO::PARAM_STR);
            $stmt->bindParam(6, $piece, PDO::PARAM_STR);
            $stmt->bindParam(7, $idImageHash, PDO::PARAM_STR);
            $stmt->bindParam(8, $idImagePassword, PDO::PARAM_STR);
            $stmt->bindParam(9, $publicKey, PDO::PARAM_STR);
            $stmt->bindParam(10, $hid, PDO::PARAM_STR);
            $stmt->bindParam(11, $birth, PDO::PARAM_STR);
            $stmt->bindParam(12, $piece, PDO::PARAM_STR);
            $stmt->bindParam(13, $idImageHash, PDO::PARAM_STR);
            $stmt->bindParam(14, $idImagePassword, PDO::PARAM_STR);
            $stmt->bindParam(15, $publicKey, PDO::PARAM_STR);
            $stmt->execute();
            $this->lastErrno = "";
            return true;
        } catch (PDOException $e) {
            $this->lastErrno = (string)$e->getCode();
        }
        return false;
    }

    /**
     * @param $did
     * @return array
     */
    function getUser($did): array
    {
        try {
            $qry = "select phone, devid as did, name, 
                    COALESCE(birth, '') as birth, date_format(reg_date, '%Y.%c.%e') as regDate, piecepw, pubkey 
                    from ".DB_USER_TB." where devid=? and del_date is null";
            $stmt = $this->conn->prepare($qry);
            $stmt->bindParam(1, $did, PDO::PARAM_STR);
            $stmt->execute();
            $row = $stmt->fetch(PDO::FETCH_ASSOC);
            $this->lastErrno = "";
            return $row == null ? array() : $row;
        } catch (PDOException $e) {
            $this->lastErrno = (string)$e->getCode();
        }
        return array();
    }

    /**
     * @param $did
     * @return bool
     */
    function removeUser($did)
    {
        try {
            $qry = "update ".DB_USER_TB." set del_date=now() where devid=?";
            $stmt = $this->conn->prepare($qry);
            $stmt->bindParam(1, $did, PDO::PARAM_STR);
            $stmt->execute();
            $this->lastErrno = "";
            return true;
        } catch (PDOException $e) {
            $this->lastErrno = (string)$e->getCode();
        }
        return false;
    }

    /**
     * @param $phone
     * @param $did
     * @param $verifierPhone
     * @return array
     */
    function identity($did, $verifierPhone): array
    {
        try {
            $qry = "select my.phone as myPhone, my.piece as myPiece, my.piecehash as myIdImageHash, my.birth as myBirth, 
                           rq.name as rqName, rq.devid as rqDid from 
                   (select phone, piece, piecehash, birth from ".DB_USER_TB." where devid = ?) as my, 
                   (select name, devid from ".DB_USER_TB." where phone = ?) as rq";
            $stmt = $this->conn->prepare($qry);
            $stmt->bindParam(1, $did,           PDO::PARAM_STR);
            $stmt->bindParam(2, $verifierPhone, PDO::PARAM_STR);
            $stmt->execute();
            $row = $stmt->fetch(PDO::FETCH_ASSOC);
            $this->lastErrno = "";
            return $row == null ? array(): $row;
        } catch (PDOException $e) {
            $this->lastErrno = (string)$e->getCode();
        }
        return null;
    }
}
