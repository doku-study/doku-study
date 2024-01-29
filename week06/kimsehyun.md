
### Laravel과 PHP를 프로젝트 주제로 고른 이유

지금까지는 NodeJS로 실습을 진행해보았다.
NodeJS는 application 코드 + server 로직을 모두 포함하고 있어 다른 걸 굳이 설치할 필요가 없었다.
반면에 Laravel(PHP 프레임워크)를 구축하려면 좀 더 복잡하게 설정해야 하기 때문에,
docker compose로 다중 컨테이너를 구축하는 데 좋은 실습 주제가 될 수 있다.

아래 그림과 같이 총 6개의 컨테이너를 준비해야 한다

### 프로젝트 구조도

![Pasted image 20240123105311](https://github.com/doku-study/doku-study/assets/36873797/80794aaf-6b2c-43f0-b5ff-5456bb6a3120)




## docker-compose 파일 작성 예시

```yaml
# compose 버전을 명시
version: "3.8"

services:
  # 1. 웹 서버 역할을 한 컨테이너를 만든다.
  server:
    # web server nginx을 활용. 가벼운 버전인 alpine을 pull한다.
    image: nginx:stable-alpine
	ports:
	  # nginx의 default 포트 번호는 80.
	  - '8000:80'
	volumes:
	  # 서버도 결국 php에 필요한 소스코드를 필요로 하기 때문에, bind mount로 마운트해준다.
	  - ./src:/var/www/html
	  
	  # docker nginx 이미지 공식 페이지에서 다음과 같이 제시
	  # 로컬에다 nginx > nginx.conf 파일을 따로 만들어야 함(강의 자료에 첨부)

      # 잘못된 예시 (에러 발생)
	  # - ./nginx/nginx.conf:/etc/nginx/nginx.conf:ro
	  # 올바른 예시
      - ./nginx/nginx.conf:/etc/nginx/conf.d/default.conf:ro
	
	  # server 서비스는 php와 mysql 서비스가 실행되어야만 작동하기 떄문(의존하기 때문)
      # server 서비스를 실행하면, php와 mysql 서비스도 자동으로 실행하게 한다.  
	depends_on:
	  - php
	  - mysql

  php:
    build:
	  context: ./dockerfiles
	  dockerfile: php.dockerfile
    volumes:
      - ./src:/var/www/html:delegated
    ports:
      # 도커 php base image 공식 소스코드를 보면 default 포트가 9000
      # 하지만 사실 해줄 필요가 없다.
      # - '3000:9000'

  mysql:
    image: mysql:5.7
    # mysql DB를 사용하려면 계정 정보가 있어야 하고, 
    # 이런 개인정보는 환경변수로 저장하는 게 보안을 위해 좋다.
    env_file:
      - ./env/mysql.env
  
  composer:
    build:
      context: ./dockerfiles
      dockerfile: composer.dockerfile
    volumes:
      - ./src:/var/www/html

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


### 1. 웹 서버 서비스 ("server")
- nginx 공식 이미지를 활용한다.
- 포트 번호를 열어준다.
- bind mount로 볼륨을 설정하는데, 이때 경로는 nginx 도커 공식 페이지에 나와있는 대로 설정한다.


### 2. PHP 서비스 ("php")
- 공식 PHP base 이미지를 그대로 pull할 수도 있지만, 실습에선 커스터마이징을 할 것이기 때문에 로컬에 dockerfiles > php.dockerfile 파일을 생성한다.

```dockerfile
# dockerfiles > php.dockerfile
FROM php:7.4-fpm-alpine

# 웹 애플리케이션 컨테이너의 일반적인 작업경로(convention)
WORKDIR /var/www/html

RUN docker-php-ext-install pdo pdo_mysql
```

- dockerfile을 다 만들었다면 docker-compose 파일에 build, context 키워드로 dockerfile 경로를 적어준다.
- 볼륨에 bind mount를 설정한다. 로컬 머신의 폴더에 소스코드가 업데이트될 폴더를 마운트한다. 폴더 이름은 "src", 컨테이너 내 경로는 `/var/www/html:delegated` -> delegated는 컨테이너에서 파일 쓰기(write)가 자주 일어나지 않을 때 성능을 더 최적화해준다? 
- 포트번호를 docker-compose에 명시할 필요가 없다. 우리가 원하는 건 php 컨테이너가 호스트 머신과 통신하는 게 아니라, php 컨테이너가 nginx 컨테이너와 통신하는 것이기 때문이다.
- 네트워크 설정은 따로 해줄 필요 없다. docker compose가 알아서 설정하기 때문




### 3. 데이터베이스 서비스("mysql")
- base 이미지를 가져온다.
- mysql을 이용하기 위해 계정정보(아이디, 패스워드)를 환경 변수 파일에 저장(env > mysql.env)하고 이 환경 변수 파일을 docker-compose에 불러온다.

```env
# mysql.env
MYSQL_DATABASE=homestead
MYSQL_USER=homestead
MYSQL_PASSWORD=ilovedocker2024!
MYSQL_ROOT_PASSWORD=ilovegultto2024!
```

- 공식 mysql 이미지 독스(https://hub.docker.com/_/mysql)를 보면 환경 변수를 어떻게 설정해야 하는지 나와있다.



### 4. composer 서비스("composer")
- dockerfile을 만든다. entrypoint를 설정해서, 이 컨테이너에선 명령어 입력할 때마다 composer 실행파일을 자동으로 실행하도록 한다.

```dockerfile
FROM composer:latest

WORKDIR /var/www/html

ENTRYPOINT ["composer", "--ignore-platform-reqs"]
```

node를 설치하기 위해 npm을 이용했던 것처럼, Laravel을 설치하기 위해 composer를 이용해보자.

```bash
# composer로 Laravel 설치하는 명령어
composer create-project --prefer-dist laravel/laravel MY_TARGET_FOLDER
```

composer 컨테이너만 실행시켜보자.

```bash
# entrypoint에 composer를 이미 설정했으므로 composer를 create-project 앞에 적을 필요가 없다.
docker compose run --rm composer create-project --prefer-dist laravel/laravel .
```

bind mount를 지정했으므로 src 폴더에 새로 파일이 생길 것이다.



## 유틸리티 컨테이너 설정하기
### 1. composer 컨테이너 내 src > .env 파일 설정

로컬 환경 변수 파일인 env > mysql.env 에 이렇게 저장했다면

```env
MYSQL_DATABASE=homestead
MYSQL_USER=homestead
MYSQL_PASSWORD=secret
MYSQL_ROOT_PASSWORD=secret
```

컨테이너 안의 폴더 src에 있는 .env 파일에도 수정을 해줘야 한다.

```env
DB_CONNECTION=mysql

# 원래 설정인 DB_HOST=127.0.0.1 IP 주소 대신에 MySQL 서비스(컨테이너)의 이름을 입력한다.
DB_HOST=mysql

DB_PORT=3306

# DB_DATABASE를 mysql.env 내용에 맞게 수정
DB_DATABASE=homestead

# USERNAME, PASSWORD를 mysql.env 내용에 맞게 수정
DB_USERNAME=homestead
DB_PASSWORD=secret
```


### 2. server의 역할, 그리고 볼륨을 추가해야 하는 이유
server = main entry point
- serve application
- forward requests to the PHP interpreter


main entry point인 server는 source code에 대해서 전혀 모른다.
따라서 server 서비스에선 PHP file에 대해 접근할 수 있어야 한다. 
PHP file은 호스트 머신의 ./src 폴더에 있을 것이므로(mirroring되고 있다) 여기에 bind mount되어야 한다.
docker-compose.yaml에서 server 부분에 볼륨(bind mount)을 추가한다.

```yaml
services: 
  server:
    image: 'nginx:stable-alpine'
    ports: 
      - '8000:80'
    volumes:
      - ./src:/var/www/html
      - ./nginx/nginx.conf:/etc/nginx/nginx.conf:ro
```


### 3. nginx confd 파일 설정

그 다음에 이 명령어로 server, php, mysql 서비스를 시작해보자.

`docker compose up -d server php mysql`

nginx web server가 제대로 작동되지 않는다. 그 이유는 docker-compose.yaml 파일에서 nginx.conf 대신에 conf.d/default.conf로 설정해야 하기 때문

```yaml
    volumes:
      - ./src:/var/www/html
      - ./nginx/nginx.conf:/etc/nginx/conf.d/default.conf:ro
```

defaul.conf 파일의 역할?
https://stackoverflow.com/questions/22143565/which-nginx-config-file-is-enabled-etc-nginx-conf-d-default-conf-or-etc-nginx
기본 가상 서버를 설정하는 데 쓰인다고 한다. (nginx conf 관련 더 자세한 내용: https://www.digitalocean.com/community/tutorials/how-to-configure-the-nginx-web-server-on-a-virtual-private-server)



### 4. depends_on 키워드로 의존성 있는 서비스를 자동으로 실행하기

server 서비스는 php와 mysql 서비스가 실행되어야 온전히 제 기능을 수행할 수 있다.
그러면 server를 run할 때 이렇게 명령어를 입력해줘야 한다.

```bash
docker compose run --rm server mysql php
```

그런데 만약 실행하고자 하는 서비스가 3개보다 훨씬 많다면 일일이 실행할 서비스 이름을 명령어에 입력하는 게 번거로울 것이다.
그래서 server가 실행되면 자동으로 실행되어야 하는(즉, server가 "의존하는") 서비스를 docker compose에 적어주자. 그럼 이렇게만 쳐도 `docker compose run server` mysql, php 서비스는 알아서 실행될 것이다.

```yaml
# docker-compose.yaml
  server:
    ...
    depends_on:
      - php
      - mysql
```



### 5. build 옵션을 통해 이미지를 재빌드하기

`docker compose up -d --build server`

--build 옵션이 없다면 Dockerfile에 수정이 가해져도 업데이트해서 이미지를 재빌드하지 않는다.
dockefile에 수정이 가해졌고, 수정된 내용을 이미지에 최신으로 반영하기 위해선 --build 옵션을 붙여야 한다.


### 6.  artisan 서비스("artisan". 이것도 유틸리티 컨테이너)

artisan도 PHP 기반이므로 php.dockerfile을 그대로 가져다쓰면 된다.
단, 이 dockerfile에 artisan만의 entrypoint를 추가하고 싶다면 어떻게 해야 할까?

```yaml
  artisan:
    build:
      context: ./dockerfiles
      dockerfile: php.dockerfile
    volumes:
      - ./src:/var/www/html
    entrypoint: ["php", "/var/www/html/artisan"]
    

```

간단하다. 그냥 docker-compose 파일에 적으면 된다.

그리고 artisan 서비스를 실행해보자. 뒤에 migrate 명령어를 붙여야 한다.

```bash
# 왜 DB migration을 해야 하는가??
docker compose run --rm artisan migrate
```

### TIP. dockerfile을 새로 하나 만들 것인가, 아니면 docker-compose 파일에 추가할 것인가?

앞서 artisan 서비스를 docker compose에 명시할 때 php.dockerfile을 끌어다 쓰는 대신 entrypoint를 compose 파일에 추가해주었다.

```yaml
  artisan:
    build:
      context: ./dockerfiles
      dockerfile: php.dockerfile
    volumes:
      - ./src:/var/www/html
    entrypoint: ["php", "/var/www/html/artisan"]
```

하지만 이렇게 하는 대신에 artisan 전용 dockerfile을 아예 따로 만드는 법(php.dockerfile에 entrypoint만 추가)도 있다.

강의자는 dockerfile을 직접 하나 더 만드는 걸 선호한다고 한다.




## bind mount에 따른 문제 해결하기

컨테이너를 배포하려면 bind mount에 의존하지 않고, 컨테이너가 필요 소스코드를 모두 가지고 있도록 설정해야 한다. 즉 소스코드의 "스냅샷(snapshot)"을 컨테이너에 저장해야 한다.

아까는 compose 파일에서 server(nginx 웹 서버) 서비스에 대해 그냥 nginx base 이미지를 사용했다. 
이번엔 dockerfile을 따로 만들어보자.

```dockerfile
# dockerfiles > nginx.dockerfile
FROM nginx:stable-alpine

WORKDIR /etc/nginx/conf.d

COPY nginx/nginx.conf .

RUN mv nginx.conf default.conf

WORKDIR /var/www/html

COPY src .
```

그리고 compose 파일에 base 이미지를 넣는 대신, dockerfile을 명시하자.


docker compose에서 context는 dockerfile이 존재하는 경로이기도 하지만, 이미지를 어디에 빌드하고 저장할지를 나타내기도 한다.
따라서 context 또한 ./dockerfiles에서 .로 바꿔줘야 한다. nginx.dockerfile에는 현재 경로가 로컬 폴더의 프로젝트 디렉토리를 기준으로 되어 있기 때문이다.

PHP 서비스도 compose 파일에서 설정했던 bind mount를 삭제하고, 대신 dockerfile에서 COPY 명령어로 로컬의 src 폴더가 컨테이너 폴더로 복사되도록 설정하자.

```dockerfile
# php.dockerfile

FROM php:7.4-fpm-alpine

WORKDIR /var/www/html

# bind mount 대신에 소스코드의 snapshot을 저장한다.
COPY src .

RUN docker-php-ext-install pdo pdo_mysql
```


이렇게 수정하고 다시 server 서비스를 실행해보자.

```
docker compose up -d --build server
```

그럼 php 권한 에러가 발생할 것이다.
다시 php.dockerfile로 돌아가서

```dockerfile
# php.dockerfile

FROM php:7.4-fpm-alpine

WORKDIR /var/www/html

# bind mount 대신에 소스코드의 snapshot을 저장한다.
COPY src .

RUN docker-php-ext-install pdo pdo_mysql

# 쓰기 권한을 default user에 부여한다.
RUN chown -R www-data:www-data /var/www/html
```





---

## 최종 docker-compose 파일

```yaml
# compose 버전을 명시
version: "3.8"

services:
  # 1. 웹 서버 역할을 한 컨테이너를 만든다.
  server:
    # web server nginx을 활용. 가벼운 버전인 alpine을 pull한다.
    image: nginx:stable-alpine
	ports:
	  # nginx의 default 포트 번호는 80.
	  - '8000:80'
	volumes:
	  # 서버도 결국 php에 필요한 소스코드를 필요로 하기 때문에, bind mount로 마운트해준다.
	  # - ./src:/var/www/html
	  
	  # docker nginx 이미지 공식 페이지에서 다음과 같이 제시
	  # 로컬에다 nginx > nginx.conf 파일을 따로 만들어야 함(강의 자료에 첨부)

      # 잘못된 예시 (에러 발생)
	  # - ./nginx/nginx.conf:/etc/nginx/nginx.conf:ro
	  # 올바른 예시
      # - ./nginx/nginx.conf:/etc/nginx/conf.d/default.conf:ro
	
	  # server 서비스는 php와 mysql 서비스가 실행되어야만 작동하기 떄문(의존하기 때문)
      # server 서비스를 실행하면, php와 mysql 서비스도 자동으로 실행하게 한다.  
	depends_on:
	  - php
	  - mysql

  php:
    build:
	  context: .
	  dockerfile: dockerfiles/php.dockerfile
	# 배포 단계에서는 bind mount를 따로 설정하지 않는다
    volumes:
      - ./src:/var/www/html:delegated
    ports:
      # 도커 php base image 공식 소스코드를 보면 default 포트가 9000
      # 하지만 사실 해줄 필요가 없다.
      # - '3000:9000'

  mysql:
    image: mysql:5.7
    # mysql DB를 사용하려면 계정 정보가 있어야 하고, 
    # 이런 개인정보는 환경변수로 저장하는 게 보안을 위해 좋다.
    env_file:
      - ./env/mysql.env
  
  composer:
    build:
      context: ./dockerfiles
      dockerfile: composer.dockerfile
    volumes:
      - ./src:/var/www/html

  artisan:
    build:
      context: .
      dockerfile: ./dockerfiles/php.dockerfile
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


---


### Mac Apple Silicon에서 실행 에러

다음과 같은 에러 발생: `no matching manifest for linux/arm64/v8 in the manifest list entries`


![[2024-01-18_21-24-41.png]]

해결책: docker compose 파일에서 mysql 설정에 이렇게 platform 정보를 추가해준다.

```yaml
  mysql:
    image: mysql:5.7
    platform: linux/amd64
    env_file:
      - ./env/mysql.env
```



### PHP 버전 때문에 발생하는 syntax 에러
```
Parse error: syntax error, unexpected '|', expecting variable (T_VARIABLE) in /var/www/html/vendor/nunomaduro/termwind/src/Functions.php on line 17
```

composer와 php 버전 차이 때문에 발생한 듯
https://stackoverflow.com/questions/69072898/parse-error-syntax-error-unexpected-expecting-variable-t-variable-symfo

> This character '|' is used only in php version >= 8.0 You can update the php version


dockerfile을 직접 새로 하나 만들어서 docker compose에 지정하든가,
아니면 기존 dockerfile를 사용하되 entrypoint를 추가하든가.

base image에 대해서만 docker compose에 working_dir와 entrypoint를 지정하는 경우가 대부분.

### bind mount
혼자 develop하기엔 파일을 바로바로 미러링할 수 있어서 좋지만, deploy할 때는 지양해야 한다.




---

### 부록: delegated 옵션으로 docker volume 설정하기

볼륨의 파일 전송 상태를 설정하는 법은 delegated 포함해서 총 세 가지가 있다.

- `default` or `consistent`
- `delegated`
- `cached`

"delegated" 옵션을 직역하자면 파일 전송의 권한을 컨테이너에게 위임한다는 뜻으로, 컨테이너가 자기 폴더 안에 있는 파일을 로컬 호스트 머신의 폴더에 업데이트할 때 호스트의 폴더를 read-only로 "꼼짝 못하게 묶어둔다"고 이해하면 된다. 

한 가지 의문점은,  스택오버플로우(https://stackoverflow.com/questions/43844639/how-do-i-add-cached-or-delegated-into-a-docker-compose-yml-volumes-list)에선 컨테이너의 파일 업데이트가 빈번하게 일어날 때 delegated 옵션을 쓴다고 나와있는데 왜 강의 설명은 반대인지 모르겠다.

![Pasted image 20240123113854](https://github.com/doku-study/doku-study/assets/36873797/6bfd011a-e485-4899-b215-d91db8b92182)


![Pasted image 20240123113904](https://github.com/doku-study/doku-study/assets/36873797/cd54a321-d7fc-4b68-84fc-f9f8bc8111ca)




