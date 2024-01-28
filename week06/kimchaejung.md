# 새롭게 알게된 점

## 이번 챕터의 목표

아래 애플리케이션을 도커화

```
<애플리케이션 컨데이너>
1. php Interpreter container
  Laravel php 애플리케이션의 소스 코드

2. Nginx Web Server container
  코드를 실행하는 서버

3. MySQL Database container

<유틸리티 컨테이너>
1. Composer container
  써드파티 패키지 설치 관리자

2. Laravel Artisan container
  초기 시작 데이터를 데이터베이스에 쓰는데 사용

3. NPM container
  Laravel이 반환하는 뷰에서 javascript 코드가 필요한 경우 사용
```

> 🤔 Nginx가 뭐지?<br>
> ∙ Nginx: 고성능, 경량의 오픈 소스 웹 서버 소프트웨어. 정적 파일 서빙, 리버스 프록시 설정, 가상 호스팅 가능<br>
> ∙ 여기서 Nginx의 역할: Laravel 어플리케이션을 위한 웹 서버 역할을 담당하게 하고, 이를 통해 클라이언트 요청을 받아들이고 php 인터프리터를 트리거하여 동적 콘텐츠를 생성하게 하는 것. <br>
> ∙ React 애플리케이션 도커화할 때는 왜 안 썼지?: React 어플리케이션이 일반적으로 정적 파일로 빌드되고, 이 정적 파일들을 직접 서빙할 수 있기 때문<br>
> ∙ Laravel은 서버 측에서 실행되는 애플리케이션, React는 클라이언트 측에서 실행되는 애플리케이션. 기본적으로 역할이 다르다!

## Nginx Web Server container 설정

`nginx/nginx.conf`: 웹 서버에서 정적 파일과 동적 php 파일을 처리하기 위한 규칙을 정의

```conf
server {
		// 웹 서버가 80번 포트에서 듣도록 설정. HTTP 트래픽을 처리
    listen 80;
		// index 파일로 사용할 기본 파일을 지정.
    index index php index.html;
		// 해당 서버 블록이 응답할 도메일 설정
    server_name localhost;
		// ⭐️ 서버의 문서 루트 지정. 웹 서버의 기본 경로로 사용.
    root /var/www/html/public;
		// 웹 서버에 들어오는 모든 요청에 대한 처리 규칙 정의
		// php 파일에 대한 요청을 처리하기 위한 설정 포함.
    location / {
        try_files $uri $uri/ /index php?$query_string;
    }
		// php 파일에 대한 처리 규칙 정의
    location ~ \ php$ {
				// php 파일이 존재하지 않으면 404 에러 반환
        try_files $uri =404;
				// FastCGI로 전달되는 Path_info를 추출하기 위한 정규식 패턴
        fastcgi_split_path_info ^(.+\ php)(/.+)$;
				// FastCGI 프로세스 매니저로 요청을 전달할 주소와 포트 설정.
        fastcgi_pass php:3000;
				// index 파일로 사용할 기본 php 파일 설정.
        fastcgi_index index php;
				// FastCGI 매개 변수를 포함하는 설정 파일 추가
        include fastcgi_params;
				// FastCGI 서버로 전송되는 Script_filename 매개 변수 설정
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
				// Path_info 매개 변수를 설정
        fastcgi_param PATH_INFO $fastcgi_path_info;
    }
}
```

`docker-compose.yaml`

```yaml
version: "3.8"

services:
  server:
    image: "nginx:stable-alpine"
    ports:
      - "8000:80"
    volumes:
      - ./nginx/nginx.conf:/etc/nginx/nginx.conf:ro
```

> ❓ 왜 볼륨 경로가 `/etc/nginx/nginx.conf:ro`지요?<br> > [nginx - docker.hub](https://hub.docker.com/_/nginx#:~:text=Running%20nginx%20in%20debug%20mode) 공식문서가 그랬어요...

## php Interpreter container 설정

`dockerfiles php.dockerfile`

```dockerfile
# 사용 중인 Nginx 구성을 위해 php-fpm 이미지가 필요한 것
FROM php:8.0-fpm-alpine
# 웹 사이트를 제공하는 웹 서버의 꽤 표준적인 폴더
WORKDIR /var/www/html

COPY src .

# 필요한 php 확장프로그램
RUN docker php-ext-install pdo pdo_mysql

# access deny 에러 해결 위한 사용자 권한 편집
RUN chown -R www-data:www-data /var/www/html
```

> 🤔 dockerfile 네이밍 규칙?<br>
> 공식 문서에는 별도의 제안이 없다. 아래 참고 링크에 따르면 세 가지 방식이 존재하고, 각자 편의대로 선택하면 될 것 같다.<br>1. `<purpose>.dockerfile`: VSCode, IntelliJ의 IDE에서 자동 인식<br>2. `dockerfile.<purpose>`: 파일 정렬 시 한 곳에서 확인 가능<br> > [참고: How to name Dockerfiles - Stackoverflow](https://stackoverflow.com/questions/26077543/how-to-name-dockerfiles)

`docker-compose.yaml`

```yaml
services:
  php:
    build:
      context: .
      dockerfile: dockerfiles php.dockerfile
    volumes:
      - ./src:/var/www/html:delegated
```

- `delegated`: 컨테이너가 일부 데이터를 기록해야하는 경우 호스트 머신에 즉시 반영하지 않고 대신 batch로 기본 처리하면서 성능이 약간 더 나아진다. 안정성은 떨어지지만 속도가 향상된다.

  1. **내부 컨테이너의 변화가 적을 때**: 파일 시스템 변경이 적은 경우, 호스트에서 컨테이너로의 쓰기 작업에 대한 동기화 성능 향상 가능

  2. **성능 최적화가 필요한 경우**: 프로젝트에서 파일 시스템 동기화의 성능을 최적화해야 하는 경우, 특히 대규모 어플리케이션에서는 delegated를 사용하여 성능 이점

- volume은 소스 코드를 위한 폴더를 가지게 하고 소스 코드 작업을 할 수 있게 하며 그 코드를 php 인터프리터에 노출할 수 있게 만든다. 개발 단계에서만 필요하고 프로덕션 단계에서는 볼륨 설정이 불필요하다

- ports를 따로 설정하지 않은 이유는 nginx 서버에서 php를 이름으로 참조하여 바로 컨테이너에 연결되기 때문이다. 따라서 아래 nginx.conf만 php의 컨테이너 내부 포트인 9000으로 수정하면 된다.

`nginx.conf`

```conf
// ...
fastcgi_pass php:9000;
// ...
```

## MySQL container 설정

`env/mysql.env` 생성

```.env
MYSQL_DATABASE=homestead
MYSQL_USER=homestead
MYSQL_PASSWORD=secret
MYSQL_ROOT_PASSWORD=secret
```

[참고: mysql Environment Variables - docker.hub](https://hub.docker.com/_/mysql#:~:text=tag%20%2D%2Dverbose%20%2D%2Dhelp-,Environment%20Variables,-When%20you%20start)

`docker-compose.yaml`

```yaml
services:
  mysql:
    image: mysql:5.7
    env_file:
      - ./env/mysql.env
```

## Composer container 설정

`composer.dockerfile`

```dockerfile
FROM composer:latest

WORKDIR /var/www/html

ENTRYPOINT [ "composer", "--ignore-platform-reqs" ]
```

`docker-compose.yaml`

```yaml
services:
  composer:
    build:
      context: ./dockerfiles
      dockerfile: composer.dockerfile
    volumes:
      - ./src:/var/www/html
```

```bash
docker-compose run --rm composer create-project --prefer-dist laravel/laravel:8.0.0 .
```

`src/.env` 변경

```.env
// AS-IS
DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=laravel
DB_USERNAME=root
DB_PASSWORD=
```

```.env
// AS-IS
DB_CONNECTION=mysql
DB_HOST=mysql
DB_PORT=3306
DB_DATABASE=homestead
DB_USERNAME=homestead
DB_PASSWORD=secret
```

## 서비스 구동

```bash
docker-compose up -d server php mysql
```

> 🚧 ERROR `no matching manifest for linux/arm64/v8 in the manifest list entries`<br>
> ∙ 원인: 도커 허브의 MySQL 공식 이미지 안내에는 ARM 64 태그가 달려있다. 그럼에도 불구하고 정상적으로 이미지를 당겨 올 수 없기 때문에 오류가 뜨는 것으로 보인다.<br>
> ∙ 해결 방법: `docker-compose.yaml`의 `mysql`에 `platform: linux/amd64` 추가

- Dockerfile 또는 Dockerfile 통해 이미지 복사되는 폴더 또는 파일 변경 시 `--build` 옵션을 추가한다.

`depends_on` 추가

`docker-compose.yaml`

```yaml
services:
  server:
    image: "nginx:stable-alpine"
    ports:
      - "8000:80"
    volumes:
      - ./nginx/nginx.conf:/etc/nginx/nginx.conf:ro
    depends_on:
      - php
      - mysql
```

```bash
docker-compose up -d --build server

// depends_on때문에 (docker-compose up -d --build server php mysql)과 같은 동작
```

## Artisan, NPM container 설정

`docker-compose.yaml`

```yaml
services:
  artisan:
    build:
      context: ./dockerfiles
      dockerfile: php.dockerfile
    volumes:
      - ./src:/var/www/html
    entrypoint: ["php", "/var/www/html/artisan"]
  npm:
    image: node:14
    working_dir: /var/www/html
    entrypoint: ["npm"]
    volumes:
      - ./src:/var/www/html
```

```bash
docker-compose run --rm artisan migrate
```

- `migrate`: Laravel이 지원하는 artisan 명령 중의 하나. 데이터베이스에 데이터를 기록, 이 데이터베이스 설정이 작동하는지 그 여부도 확인

## 부가적인 Dockerfile을 쓰는 경우

- 부가적인 Dockerfile을 쓸 것인지, Docker-compose 내에서 이미지 이름을 가지고 지정할 것인지는 선호에 따라 다르다.

  강사님은 부가적인 Dockerfile로 사용하는 것을 좋아함

  - 의도가 분명하고, Docker-compose file을 간결하게 유지할 수 있다고 생각하기 때문
  - 대신 depth가 생기는 것이 단점

```docker
// nginx.dockerfile
FROM nginx:stable-alpine

WORKDIR /etc/nginx/conf.d

COPY nginx/nginx.conf .

RUN mv nginx.conf default.conf

WORKDIR /var/www/html

COPY src .
```

- nginx 이미지에 이미 디폴트 명령이 있기 때문에 CMD, ENTRYPOINT을 넣을 필요는 없다

`docker-compose.yaml`

```yaml
services:
  server:
    # image: "nginx:stable-alpine"
    build:
      context: .
      dockerfile: dockerfiles/nginx.dockerfile
    ports:
      - "8000:80"
    # volumes:
    #   - ./src:/var/www/html
    #   - ./nginx/nginx.conf:/etc/nginx/conf.d/default.conf:ro
    depends_on:
      - php
      - mysql
```

# 함께 이야기하고 싶은 점

## 강의를 듣기 전 도커화한 경험과 강의에서 알려준 방식에 어떤 차이점이 있는지 궁금해요.
