# 더 복잡한 설정: Laravel & PHP 도커화 프로젝트

## 모듈 소개
- Docker, Docker Container, Docker compose 사용
- 다중 컨테이너로 구성된 어플리케이션 구축

Laravel & PHP 프로젝트
- 도커외에 다른 도구 설치안하고 프로젝트 환경 설정
- 배웠던 사례들 적용

왜 Laravel&PHP?
- Node는 이미 많이 함
- 많은 환경설정 절차 필요

## Target 설정
NodeJS는 JavaScript 런타임
- NodeJS만 설치하면 됌

PHP 
- 자체로 서버 구축 불가
- 요청을 처리할수있도록 PHP 인터프리터 트리거 필요
https://laravel.com/docs/10.x/installation

1. PHP 인터프리터 
- 소스코드 디렉토리가 PHP 인터프리터에게 노출

2. Nginx Web Server
- NGINX 웹서버가 들어오는 요청을 받은 다음 인터프리터에게 전달
- 인터프리터가 응답을 생성하여 전달

3. MySQL
- 데이터 저장을 위한 MySQL <> PHP인터프리터와 통신

---
3개의 유틸리티 컨테이너 추가 필요
1. Composer
    - Node의 npm과 같이, Laravel에 필요한 종속성 생성
2. Laravel Artisan 
    - 데이터베이스에 대한 마이그레이션 실행, 초기 시작 데이터 생성
3. npm
    - Laravel의 뷰에서 JavaScript가 필요한 경우 프론트엔드 로직 일부에 사용

총 6개의 컨테이너가 필요

## Nginx(웹 서버) 컨테이너 추가
docker-compose.yaml로 전체 6개의 앱/유틸리티 컨테이너 설정

```dockercompose
version: "3.8"

services: 
  server:
    image: 'nginx:stable-alpine'
    ports: 
      - '8000:80'
    volumes: 
      - ./nginx/nginx.conf:/etc/nginx/nginx.conf:ro
  # php:
  # mysql:
  # composer:
  # artisan:
  # npm:
```
NGINX
  - 공식 Docker Image 사용
  - https://hub.docker.com/_/nginx
    - 포트 설정: `Exposing external port`
    - 구성파일 연결: `Mount your configuration file`

## PHP 컨테이너 추가
별도의 디렉토리(dockerfiles) 생성 후 빌드에 필요한 dockerfile 생성
PHP 
  - 공식 Docker Image 기반, 필요설정 추가
  - https://hub.docker.com/_/php
```
FROM php:7.4-fpm-alpine

WORKDIR /var/www/html

RUN docker-php-ext-install pdo pdo_mysql

```
특이점
  - 부가 종속성 설치(docker-php-ext-install)
  - CMD/ENTRYPOINT 없음
    - Base 이미지의 CMD/ENTRYPOINT를 사용함

docker-php-ext-install 이 명령어는 뭔가요
- FROM에 있는 fpm [Dockerfile](https://github.com/docker-library/php/blob/master/8.3/alpine3.19/fpm/Dockerfile)
- 같은 경로의 source를 /local/bin으로 옮겨서 명령어화 https://github.com/docker-library/php/blob/master/8.3/alpine3.19/fpm/Dockerfile#L89
- 해당 파일은 그냥 입력값 받아서 case로 분기처리후 사용 https://github.com/docker-library/php/blob/master/8.3/alpine3.19/fpm/docker-php-source
- 이렇게 https://github.com/docker-library/php/blob/master/8.3/alpine3.19/fpm/docker-php-ext-install

docker-compose.yaml에 공식 php로 추가
```
  php:
    build:
      context: ./dockerfiles
      dockerfile: php.dockerfile
    volumes:
      - ./src:/var/www/html:delegated
    # ports: 
    #   - '3000:9000'
```

- 별도 생성한 디렉토리로 context 잡아줌
- 소스코드와 연결되는 바인드마운트 추가-
  - 읽기전용 미사용
- 별도의 port 설정 불필요
  - localhost<>PHP간 통신이 아닌, 도커 네트워크 내부 컨테이너간 통신이기때문에 별도의 포트설정 불필요

## MySQL 컨테이너 추가
docker-compose.yaml에 공식 mysql이미지로 추가
https://hub.docker.com/_/mysql

```
  mysql:
    image: mysql:5.7
    env_file:
      - ./env/mysql.env
```
- 환경변수 주입을 위한 별도 mysql.env 생성
  - MYSQL_DATABASE=homestead
  - MYSQL_USER=homestead
  - MYSQL_PASSWORD=secret
  - MYSQL_ROOT_PASSWORD=secret


## Composer 유틸리티 컨테이너 추가
dockerfiles/composer.dockerfile 추가

ENTRYPOINT를 지정하기위해, 별도의 Composer 유틸리티 컨테이너 이미지를 빌드함.
```
FROM composer:latest

WORKDIR /var/www/html

ENTRYPOINT [ "composer", "--ignore-platform-reqs" ]

```
- composer 공식이미지로 시작 https://hub.docker.com/_/composer
- 작업경로는 /var/www/html로 설정
- 특정 명령어를 추가함으로써 일부 종속성이 누락되더라도 경고/오류없이 실행

빌드된 이미지를 docker-compose.yaml에 추가
```
  composer:
    build:
      context: ./dockerfiles
      dockerfile: composer.dockerfile
    volumes:
      - ./src:/var/www/html

```
- php와 유사하게, custom composer image 빌드를 위한 설정 추가
- 작업할 앱 소스를 컨테이너 내부 경로(/var/www/html)에 바인딩


## Composer 유틸리티 컨테이너로 Laravel 앱 만들기
[Laravel Installation](https://laravel.com/docs/10.x/installation) 페이지의 `Creating a Laravel Project` 항목에서 초기 Laravel project를 시작하기 위한 명령어를 확인할 수 있다.  

강의에서 나온 `--prefer-dist` 옵션은 [Laravel 7.0버전](https://laravel.com/docs/7.x/installation#installing-laravel)에서 사용된다

`docker-compose run --rm composer create-project laravel/laravel .`
- run: docker-compose up과 달리, 일회용 명령어를 수행한다. target 설정언급안했지만 사용함
- custom docker image에서 ENTRYPOINT에서 "composer", "--ignore-platform-reqs"가 정의되어있기 때문에 뒷부분만 추가한다.
- 실행 완료 후 src 디렉토리 내부에 Laravel project가 생성되었는지 확인

## 일부 Docker Compose 서비스만 구동하기
어플리케이션 실행여부 확인을 위해, Laravel project 내 .env 확인
- DB_* 블럭
  - /env/mysql.env 내용과 동기화 (HOST,DATABASEM,USER,PWD,etc..)

현재까지 구성된 services 평가(server,php,mysql)
- server
  - nginx, 애플리케이션의 메인 엔트리포인트
  - 요청을 뒷단 PHP 인터프리터에 포워딩
- php 인터프리터
  - MYSQL DB와 통신하여 처리
- php 파일에 대한 요청만 전달하도록 볼륨 추가
  - nginx 블럭중에 /va/www/html/ 경로가 있기 때문

composer 를 제외한 3개 서비스 시작하기
- docker-compose up server php mysql
  - 각 서비스를 target 지정하여 composer 제외하고 실행
- depend_on 추가하기
  - server만 지정하여도 의존서비스 같이 호출
```
  server:
    image: 'nginx:stable-alpine'
    ports: 
      - '8000:80'
    volumes: 
      - ./src:/var/www/html
      - ./nginx/nginx.conf:/etc/nginx/conf.d/default.conf:ro
    depends_on:
      - php
      - mysql
```
- docker-compose up -d --build server
09:06 아잇이거 지난주랑 말이다른데 다시확인필요
```
즉, Dockerfile이 변경되거나

또는 Dockerfile을 통해 복사된 일부 파일을 변경된다면...

지금 여기에서는 변경된 것이 없지만, 만약에 변경한다면

그렇다면 이러한 변경사항은

docker-compose에 의해 적용되지 않습니다.

즉, 이미지를 리빌드 하지 않을 겁니다.
```


## 더 많은 유틸리티 컨테이너 추가하기
Artisan: 데이터베이스에 초기데이터 채워넣기 목적으로사용

```
  artisan:
    build:
      context: ./dockerfiles
      dockerfile: php.dockerfile
    volumes:
      - ./src:/var/www/html:delegated
    entrypoint: ["php", "/var/www/html/artisan"]
```
- php로 빌드된 Laravel 명령이기때문에 php image 재사용
- 소스코드가 필요해서 바인드마운트
- 원본 이미지에없는 entrypoint를 docker-compose 단계에서 추가

npm 서비스 설정
```
  npm:
    image: node:14
    working_dir: /var/www/html
    entrypoint: ["npm"]
    volumes:
      - ./src:/var/www/html
```

- 별도의 docker image 없이도 docker-compose 실행단에서 override가능 (composer.dockerfile은 왜만들었는가..)

Artisan 실행
- docker-compose run --rm artisan migrate
  - 데이터베이스 연결이 없으면 작동하지않음

## Dockerfile이 있거나, 없는 Docker Compose
dockerfile 명령을 docker-compose 파일에 추가할 수 있음
- entrypoint: 또는 working_dir: 같은 것
- 대신 dockerfile 을 생성하여 사용할 수도 있음
  - 의도를 명확히 파악할 수 있고
  - docker-compose 파일을 간략하게 유지 가능
  - COPY, RUN 같이 docker-compose에서 실행할 수 없는 명령들이 있음

바인드마운트 고려사항
- 어디까지나 개발상 편의를 위한것
- 배포단계에서는 바인드마운트는 고려대상X, 파일시스템을 구축하는것은 컨테이너 아이디어사상X
- 소스코드와 nginx 구성등 앱 작동상 필요사항을 이미지로 복사하는것에 대한 고려 필요

## 바인드 마운트와 COPY: 언제 무엇을 사용하는가?
소스코드의 구성의 스냅샷을 이미지에 포함하기 위한 작업

nginx.dockerfile 생성
```
FROM nginx:stable-alpine

WORKDIR /etc/nginx/conf.d

COPY nginx/nginx.conf .

RUN mv nginx.conf default.conf

WORKDIR /var/www/html

COPY src .

```

- 기존 image: 'nginx:stable-alpine', - ./nginx/nginx.conf:/etc/nginx/conf.d/default.conf:ro 설정 대체
  - 바인드 마운트에 의존하지않고, 원본 이미지에 구성과 소스코드의 스냅샷 복사

docker-compose.yaml의 server 서비스 수정
```
  server:
    build:
      context: .
      dockerfile: dockerfiles/nginx.dockerfile
    ports: 
      - '8000:80'
    # volumes: 
    #   - ./src:/var/www/html
    #   - ./nginx/nginx.conf:/etc/nginx/conf.d/default.conf:ro
    depends_on:
      - php
      - mysql
```

- 기존의 build:와 다르게, dockerfiles 디렉토리가 아닌 한단계 위의 디렉토리를 설정
  - 이미지 빌드과정에서 dockerfiles 외부의 nginx,src 디렉토리 참조가 필요
- volumes 블럭 비활성화
  - 이미 필요구성이 이미지 빌드단게에 전달되었기 때문에 바인드마운트 해제

php.dockerfiles 수정
```
FROM php:8.0-fpm-alpine

WORKDIR /var/www/html

COPY src .

RUN docker-php-ext-install pdo pdo_mysql

RUN addgroup -g 1000 laravel && adduser -G laravel -g laravel -s /bin/sh -D laravel

USER laravel 
```
- COPY src . 
  - 소스코드의 스냅샷을 이미지안에 복사

docker-compose.yaml의 php 서비스 수정
```
  php:
    build:
      context: .
      dockerfile: dockerfiles/php.dockerfile
    # volumes: 
    #   - ./src:/var/www/html:delegated
```

- 이후 서비스 재시작을 위한 일련의 과정 수행
  - docker-compose down 
  - docker-compose up -d --build server

docker-compose.yaml의 artisan 서비스 수정
```
  artisan:
    build:
      context: .
      dockerfile: dockerfiles/php.dockerfile
    volumes: 
      - ./src:/var/www/html
    entrypoint: ["php", "/var/www/html/artisan"]
```
- php와 같이 context 범위 수정

## 모듈 리소스

# 이야깃거리
- docker-php-ext-install 명렁어보고 떠오름
깃헙릴리즈같은데서 패키지 받아서 바이너리 설치해보신적있나요
대충 curl/wget하고
unzip/untar 하고
필요한거 cp /usr/local/bin 또는 ln -s

한발자국 더 나아가면 PATH설정까지?

- 강의에서 배운거 어디까지 쓰시나요
사실 이번에 docker compose build context등은 쓰면 나만 보고 유지보수 할수 있는거같음    
이것도 유지보수하기어렵게 코딩하는법과 비슷한가   

- Custom composer image 빌드한것은 뭔가 안티패턴같음
  - 이미 [compose docker image](https://github.com/composer/docker/blob/main/2.6/Dockerfile)안에 CMD로 실행될것을 대비해서 다 짜넣었는데..
  - docker run -v $(pwd)/src:/var/www/html --rm composer composer --ignore-platform-reqs create-project --prefer-dist laravel/laravel:8.0.0 /var/www/html 으로 실행해도 될것같은데
  - 개인적으로 동료거나 후임으로 인수인계받는다면, 봐야할게 늘어서(composer.dockerfile) 맘에 안듭니다 