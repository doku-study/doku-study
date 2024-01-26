FROM php:8.0-fpm-alpine
 
WORKDIR /var/www/html # 웹서버 표준 폴더
 
COPY src .
 
RUN docker-php-ext-install pdo pdo_mysql
 
RUN addgroup -g 1000 laravel && adduser -G laravel -g laravel -s /bin/sh -D laravel

USER laravel 
 
# CMD or ENTRYPOINT가 없으면 베이스 이미지의 CMD or ENTRYPOINT 사용
# php 이미지의 경우 php 인터프리터 호출

# RUN chown -R laravel:laravel .