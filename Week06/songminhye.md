# Laravel APP설정하기

- 6개의 모듈 설정이 필요

### Nginx 컨테이너(웹서버)

```yaml
version: "3.8"

services: # 필요한 모든 서비스들
		server: # 들어오는 모든 요청을 받아들여 PHP 인터프리터를 트리거 함
		image: 'nginx:stable-alpine' # server에 대한 이미지 지정 ## 텍스트는 따옴표로 묶는 게 안정적
		ports: # 웹 서버 포트 노출
			- '8000:80'
		volumes: # 바인드 마운트 추가
			- ./src:/var/www/html # 서버에서 php파일에 접근할 수 있어야 하므로 볼륨을 추가해줌
			- ./nginx/nginx.conf:/etc/nginx/nginx.conf:ro # 공식문서와 맞춤 # ro:read only
		depends_on: # 의존성 있는 서비스 자동으로 실행
      - php
      - mysql
```

```yaml
server {
    listen 80;
    index index.php index.html;
    server_name localhost;
    root /var/www/html/public;
    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }
    location ~ \.php$ {
        try_files $uri =404;
        fastcgi_split_path_info ^(.+\.php)(/.+)$;
        fastcgi_pass php:3000;
        fastcgi_index index.php;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        fastcgi_param PATH_INFO $fastcgi_path_info;
    }
}
```

### PHP container

```yaml
php:
    build: 
      context: ./dockerfiles
      dockerfile: php.dockerfile
    volumes:
      - ./src:/var/www/html:delegated 
      # 컨테이너가 일부 데이터를 기록하는 경우, 
      # 그 결과를 호스트 머신에 즉시 반영하지 않고, 배치(batch)로 처리하기
      # 속도 향상, 안정성 떨어짐(손실이 발생해서 그렇지 않을까. 배치가 돌아오기전에 컨테이너가 꺼지면 데이터를 잃으니까?)
      # 최적화 옵션 ## 약간 실시간 반영될 필요없는 데이터들을 쌓을 때 충분히 쌓이면 한번에 가져오도록 하는 옵션인듯?(개인생각)
    # ports:
      #- '3000:9000' 
      # 로컬 호스트를 통해서가 아니라 컨테이너 간 직접 통신을 하고 있기 때문에 docker 내부포트에 바로 연결
      # nginx.conf의 fastcgi_pass를 이렇게 변경해줘야 함 php:3000; -> php:9000;
```

```docker
FROM php:8.0-fpm-alpine
# 7.4-fpm-alpine

WORKDIR /var/www/html 
# 웹서버의 표준적인 폴더 # nginx.conf의 root위치 
# finally: laravel PHP app을 보관할 컨테이너 내부 폴더

COPY src .

RUN docker-php-ext-install pdo pdo_mysql

# RUN addgroup -g 1000 laravel && adduser -G laravel -g laravel -s /bin/sh -D laravel
# 
# USER laravel

# dockerfile 끝에 CMD, ENTRYPOINT가 없으면 베이스 이미지 사용
## 여기서는 php이미지 베이스에 있는 php 인터프리터를 호출하는 명령을 자동 실행하게됨

# access deny 에러 해결 위한 사용자 권한 편집
RUN chown -R www-data:www-data /var/www/html
```

### MySQL container

```yaml
mysql:
    image: 'mysql:5.7'
    env_file: # 환경변수
      - ./env/mysql.env
# env/mysql.env 여기에 필요 환경변수 저장 및 관리
	## DATABASE,USER,PASSWORD,ROOT_PASSWORD
```

### Composer container

```yaml
composer:
    build: 
      context: ./dockerfiles
      dockerfile: composer.dockerfile # entrypoint 지정하기 위해 custom dockerfile 필요
    volumes:
      - ./src:/var/www/html
```

```docker
FROM composer:latest

# RUN addgroup -g 1000 laravel && adduser -G laravel -g laravel -s /bin/sh -D laravel

WORKDIR /var/www/html

ENTRYPOINT [ "composer", "--ignore-platform-reqs" ]
# '--ignore-platform-reqs': 일부 종속성이 누락되더라도 경고나 오류없이 실행 가능
```

```bash
docker compose run --rm composer create-project --prefer-dist laravel/laravel .
# 여기서 php parse 에러 발생 왜 나는 거냐..대체..
```

### ⚠️ ERROR

<aside>
File at "/var/www/html/vendor/symfony/mime/Test/Constraint/EmailAddressContains.php" 
could not be parsed as PHP, it may be binary or corrupted
</aside>

**TRY**

1. 대부분 권한에러 혹은 파일이 없어서 나는 에러라고 했음 -> 강의 내에 안내된 RUN cmd 추가 -> **같은 에러 발생**
`RUN addgroup -g 1000 laravel && adduser -G laravel -g laravel -s /bin/sh -D laravel`
2. PHP와 laravel 버전 변경 -> **같은 에러 …**
`FROM php:8.0-fpm-alpine`  &&  `docker-compose run --rm composer create-project --prefer-dist laravel/laravel:8.0.0 .`
3. https://forums.docker.com/t/m1-mac-docker-cannot-parse-php-files/131860
→ **같은 에러…**

### 남은 서비스 추가: artisan & npm

```yaml
artisan:
    build:
      context: ./dockerfiles
      dockerfile: php.dockerfile
    volumes:
      - ./src:/var/www/html
    entrypoint: ["php", "/var/www/html/artisan"]
npm:
    image: 'node:14'
    working_dir: /var/www/html
    entrypoint: ["npm"]
    volumes:
      - ./src:/var/www/html
```

```bash
docker-compose up -d --build server # 잘 올라오긴 한다..
docker compose run --rm artisan migrate # 데이터베이스에 데이터 기록
```
