FROM composer:2
 
RUN addgroup -g 1000 laravel && adduser -G laravel -g laravel -s /bin/sh -D laravel

USER laravel 

WORKDIR /var/www/html  # 웹서버 표준 폴더(코드가 들어갈 폴더)
 
ENTRYPOINT [ "composer", "--ignore-platform-reqs" ] # 일부 종속성이 누락되어도 경고나 오류없이 실행