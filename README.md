# WHIF
**공개 SW 개발자 대회**  
**모바일 신분증 WHIF**  
  
소개/사용 영상 [보러가기](https://youtu.be/MgRTrrlrRsc)

***

## Swift build
**[xCode 10.0]** **[Swift 4]** **[iOS 10~]** **[iPhone 6~]**
  
terminal로 프로젝트 폴더로 이동한 후 ```pod install```  
생성된 xcode work space 파일(**whif.xcworkspace**)로 프로젝트를 실행 및 빌드할 수 있습니다.
  
***

## Server build
**[Ubuntu 18.04]** **[Nginx 1.14]** **[PHP7.2 fpm]** **[PHP Slim 3.0]** **[MySQL5.7]**  

***

#### 0. apt-get update
```
$ sudo apt-get update
```


#### 1. Nginx, PHP-fpm, MySQL install & setting
```
$ sudo apt-get install nginx
$ sudo apt-get install php7.2-fpm, php7.2-mysql
$ sudo apt-get install mysql-server
$ sudo nano /etc/mysql/my.cnf
```
**my.cnf** 파일을 **/etc/mysql/my.cnf** 에 복사하세요.
```
$ sudo nano /etc/php/7.2/fpm/php.ini
```
``` cgi .fix_pathinfo``` 부분을 찾아서 ```;``` 주석을 제거한 후 ``` cgi .fix_pathinfo=0``` 으로 설정합니다. 실행할 PHP파일이 없을 때 근접 파일 실행을 차단합니다.


#### 2. 방화벽 설정
```
$ sudo iptables -A INPUT -p tcp -m state --state NEW -m tcp --dport 80 -j ACCEPT
$ sudo iptables -A INPUT -p tcp -m state --state NEW -m tcp --dport 443 -j ACCEPT
```


#### 3. certbot 설치
```
$ add-apt-repository ppa:certbot/certbot
$ apt-get install python-certbot-nginx
```  


#### 4. Nginx 설정
```
$ sudo nano /etc/nginx/sites-available/[domain name]
$ sudo ln -s /etc/nginx/sites-enable /etc/nginx/sites-available/[domain name]
```  
**[domain name]** 에 **nginx-site-available** 파일 내용을 복사하세요.  
**nginx-site-available** 파일에 모든 **[domain name]** 을 수정해야 합니다.


#### 5. SSL 인증서 생성
```
$ sudo certbot --nginx -d [domain name] -d www.[domain name]
$ sudo openssl dhparam -out /etc/ssl/certs/dhparam.pem 2048
```  
자세한 내용은 [Nginx Let's Encrypt](https://varins.com/home-server-07-lets-encrypt-wildcard-certificates/)에서 확인할 수 있습니다.


#### 6. Nginx 시동
```
$ sudo nginx -t
$ sudo systemctl restart nginx
```  

***

## 사용 라이브러리
> Tesseract OCR v4.0
  * Purpose: 이미지 내 글자 추출
  * Made by: Daniele Galiotto
  * License: [보기](https://github.com/elegnate/whif/tree/master/iOS/Pods/TesseractOCRiOS)
  
> CryptoSwift v0.12.0
  * Purpose: 신분증 데이터 암호화
  * Mady by: Marcin Krzyżanowski
  * License: [보기](https://github.com/elegnate/whif/blob/master/iOS/Pods/CryptoSwift/LICENSE)

> SwiftyRSA v1.5.0
  * Purpose: FIDO 인증
  * Made by: Scoop Technologies
  * License: [보기](https://github.com/TakeScoop/SwiftyRSA/blob/master/LICENSE)
  
> Slim v3.0
  * Purpose: PHP Restful API
  * License: [보기](https://github.com/slimphp/Slim/blob/3.x/LICENSE.md)
