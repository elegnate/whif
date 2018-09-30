# WHIF
**공개 SW 개발자 대회**  
**모바일 신분증 WHIF**  
CCL **BY-NC-SA**  
  
소개/사용 영상 [보러가기](https://youtu.be/MgRTrrlrRsc)



## Swift build
**[xCode 10.0]** **[Swift 4]** **[iOS 10~]** **[iPhone 6~]**
  
terminal로 프로젝트 폴더로 이동한 후 ```pod install```  
생성된 xcode work space 파일(**whif.xcworkspace**)로 프로젝트를 실행 및 빌드할 수 있습니다.
  


## Server build
**[Ubuntu 18.04]** **[Nginx 1.14]** **[PHP7.2 fpm]** **[PHP Slim 3.0]**  


#### 1. certbot 설치
```
$ add-apt-repository ppa:certbot/certbot
$ apt-get update
$ apt-get install python-certbot-nginx
```  


#### 2. Nginx 설정
```
$ sudo nano /etc/nginx/sites-available/[domain name]
$ sudo ln -s /etc/nginx/sites-enable /etc/nginx/sites-available/[domain name]
```  
**[domain name]** 에 **nginx-site-available** 파일 내용을 복사하세요.  
**nginx-site-available** 파일에 모든 **[domain name]** 을 수정해야 합니다.


#### 3. SSL 인증서 생성
```
$ sudo certbot --nginx -d [domain name] -d www.[domain name]
$ sudo openssl dhparam -out /etc/ssl/certs/dhparam.pem 2048
```  
자세한 내용은 [Nginx Let's Encrypt](https://www.digitalocean.com/community/tutorials/how-to-secure-nginx-with-let-s-encrypt-on-ubuntu-14-04)에서 확인할 수 있습니다.


#### 4. Nginx 시동
```
$ sudo nginx -t
$ sudo systemctl restart nginx
```
