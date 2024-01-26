# 새롭게 알게된 점

- Laravel & PHP 프로젝트 실습 예시
- 지금까지 배운 도커를 활용하여 구체적인 예시 구성
  - 새로운 기능들 추가
  - 도커 컴포즈를 사용하는 여러 새로운 방식
  - 이미지간 연결에 여러 dockerfile을 사용하여 상호 작용



## Laravel & PHP 프로젝트

이전의 nodejs로 실행하던 웹 어플리케이션보다 의존및 종속성이 많이 요구되는 프로젝트 



**구현 환경**

- 도커를 제외하고 호스트 머신에 아무것도 설치 X



**목표 아키텍쳐 셋업**

> composer : 3rd 패키지 관리자 

> artisan : 초기 시작데이터를 데이터베이스에 쓰는데 사용

> npm : 프론트 엔드 로직을 위한 경우 





## PHP Container 

도커 파일 네이밍을 .을 통해 구분하여 표현한다. 

- `php.dockerfile`, 

- Php 인터프리터 , Php 인터프리터가 소스코드에 접근하게 끔

```dockerfile
# php.dockerfile
FROM php:8.0-fpm-alpine
 
WORKDIR /var/www/html
 
RUN docker-php-ext-install pdo pdo_mysql
```

```yaml
# docker-compose.yaml
version: '3.8'

services:
	...
  php:
    build:
      context: .
      dockerfile: dockerfiles/php.dockerfile
    volumes:
      - ./src:/var/www/html:delegated
```

- `delegated` : 컨테이너가 일부 데이터를 기록해야하는 경우 그 결과를 호스트머신에 즉시 반영하지 않고 배치로 기본 처리하면서 성능이 약간 더 나아짐. (최적화 옵션 ), 해당 폴더에 자주 기록되지 않아야 하기 때문에  -> why?, 어디에서 주로 사용하나 ? 

## MYSQL Container  

이전과 거의 동일

```yaml
mysql:
    image: mysql:5.7
    env_file:
      - ./env/mysql.env
```

>  개인적으론 이것도 dockerfile로 만드는게 어떤가 싶음
>
> 지금은 최대한 간단한 이미지라 설정 관련이 적지만, 기타 설정도 들어있는 경우 dockerfile에서ㅓ 별도 관리하는게 용이하지 않나 싶음



## Composer Container  

- **유틸리티 컨테이너** 개념 사용 
  - Laravel 애플리케이션 설정용

> Before creating your first Laravel project, make sure that your local machine has PHP and [Composer](https://getcomposer.org/) installed. If you are developing on macOS, PHP and Composer can be installed in minutes via [Laravel Herd](https://herd.laravel.com/). In addition, we recommend [installing Node and NPM](https://nodejs.org/).
>
> After you have installed PHP and Composer, you may create a new Laravel project via Composer's `create-project` command:

- ```composer create-project laravel/laravel example-app```



- ```docker-compose run --rm composer create-project --prefer-dist laravel/laravel .```

```dockerfile
FROM composer:latest
 
RUN addgroup -g 1000 laravel && adduser -G laravel -g laravel -s /bin/sh -D laravel

USER laravel 

WORKDIR /var/www/html
 
ENTRYPOINT [ "composer", "--ignore-platform-reqs" ]
```

```yaml
version: '3.8'

services:
  composer:
      build:
        context: ./dockerfiles
        dockerfile: composer.dockerfile
      volumes:
        - ./src:/var/www/html
```

- 로컬의 src 에 laravel 어플리케이션 구성파일 빌드



## 도커 컴포즈에서 별도의 컨테이너를 런하는 방법 

- 컴포즈를 통해 동시에 모든 컨테이너를 올리는 것이 아닌 

  - 유틸리티와 같은 컨테이너는 제외하고 구동시키기 위해 다음과 같은 명령어 사용

  - ```docker-compose up [service]```

  - Depend_on 을 통해 다른 컨테이너와 연결 가능 

  - ```yaml
    depends_on:
          - php
          - mysql
    ```

    

- 도커 파일 재평가 --build
  - ```docker-compose up -d --build [service]```



## 기타 3rd party (Artisan, NPM)

- 유틸리티 컨테이너 개념 사용 

```yaml
version: '3.8'

services:
  ...
  artisan:
    build:
      context: .
      dockerfile: dockerfiles/php.dockerfile
    volumes:
      - ./src:/var/www/html
    entrypoint: ['php', '/var/www/html/artisan']
  npm:
    image: node:14
    working_dir: /var/www/html
    entrypoint: ['npm']
    volumes:
      - ./src:/var/www/html

```

- artisan
  - php언어로 빌드된 기능으로 php image를 사용할 수 있다. 
  - entrypoint를 별도로 compose 파일에서 지정가능
- `docker-compose run --rm artisan migrate`
  - 일종의 데이터 연결&마이그레이션 명령어 
  - django의 `**python manage.py makemigrations [app_name]** 비슷한 개념인듯? 

## Dockerfile이 있거나, 없거나

**dockerfile을 만들거나, compose에서 다 해결하거나**

- `working_dir` ` entrypoint` 를 compose에서도 사용 가능함.
- dockerfile로 작성하지 않아도 compose에서 사용가능

> 개인적인 생각으로는 도커파일로 모두 작성하고 copmose에서는 단순 결합만 해주는 편이 낫다고 생각함. 
> 유지관리 관점에서도 유리할 듯? 개발버전, 테스트 버전, 배포버전 이미지 따로 관리

```yaml
# docker-compose.yaml
version: '3.8'

services:
	...
  npm:
    image: node:14
    working_dir: /var/www/html
    entrypoint: ['npm']
    volumes:
      - ./src:/var/www/html
```



## 바인드 마운트와 COPY 

### **개발 환경과 배포 환경의 전환**

```yaml
    volumes:
      - ./src:/var/www/html
      - ./nginx/nginx.conf:/etc/nginx/conf.d/default.conf:ro
```

로컬 호스트를 참조하던 `nginx`바인드 마운트를 배포환경에서는 참조할 수 없기 때문에 이를 이미지 스냡샷에 추가 시키기 위해 아래와 같이 변경 

```dockerfile
# nginx.dockerfile
FROM nginx:stable-alpine
 
WORKDIR /etc/nginx/conf.d
 
COPY nginx/nginx.conf .
 
RUN mv nginx.conf default.conf

WORKDIR /var/www/html
 
COPY src .
```



**Build context 차이** 

- 프로젝트 폴더로부터 무엇인가 필요하다면, context를 하위 폴더로 설정하면 작동되지 않음

```yaml
build:
		context: .
		dockerfile: dockerfiles/nginx.dockerfile
```

```yaml
build:
    context: ./dockerfiles
    dockerfile: composer.dockerfile
```



**배포 해야하는 경우, 변경 포인트**

- 바인드 마운트 된 경로들은 개발 사항에서 필요한 옵션으로 배포 시에는 로컬호스트에서 참조하던 경로를 비활성화 
- 대신에 **COPY**를 통해 해당 소스 코드를 이미지에 복사 

```yaml
version: '3.8'

services:
  server:
    build:
      context: .
      dockerfile: dockerfiles/nginx.dockerfile
    ports:
      - '8000:80'
#    volumes: # 변경(배포)
#      - ./src:/var/www/html # 변경(배포)
#      - ./nginx/nginx.conf:/etc/nginx/conf.d/default.conf:ro # 변경(배포)
    depends_on:
      - php
      - mysql
  php:
    build:
      context: . # 변경(배포)
      dockerfile: dockerfiles/php.dockerfile # 변경(배포)
#    volumes: # 변경(배포)
#      - ./src:/var/www/html:delegated # 변경(배포)
```

`Php.dockerfile` 수정

```dockerfile
FROM php:8.0-fpm-alpine
 
WORKDIR /var/www/html
 
COPY src . # 변경(배포)
 
RUN docker-php-ext-install pdo pdo_mysql
```





# 함께 이야기하고 싶은 점

`delegated` : 컨테이너가 일부 데이터를 기록해야하는 경우 그 결과를 호스트머신에 즉시 반영하지 않고 배치로 기본 처리하면서 성능이 약간 더 나아짐. (최적화 옵션 ), 해당 폴더에 자주 기록되지 않아야 하기 때문에  -> why?, 어디에서 주로 사용하나 ? 