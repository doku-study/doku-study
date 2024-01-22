# 새롭게 알게된 점

## Docker-compose란?

> 다수의 `docker build`, `docker run`` 명령을 하나의 설정 파일로 만드는 오케스트레이션 커맨드 툴

### Docker-compose를 왜 쓰는가?

설정 프로세스를 자동화, 하나의 명령으로 개별 구성이 지닌 모든 설정을 가져올 수 있다.

개별 명령을 터미널을 일일이 입력하지 않고 설정 파일 하나로 연결된 서비스를 작동시킬 수 있다.

### Docker-compose가 할 수 없는 것

- 커스텀 이미지를 위한 Dockerfile을 대체하지 않는다
- 이미지나 컨테이너를 대체하지 않는다
- 다수의 호스트에서 다중 컨테이너를 관리하는 데 적합하지 않다
  - 이건 배포 섹션에서 다룰 예정

### Docker-compose 파일은 어떻게 작성하는가?

- 포트, 환경 변수, 볼륨, 네트워크를 설정할 수 있다
- Docker-compose는 yaml 파일로 작성한다
  - yaml은 들여쓰기를 사용하여 구성 옵션 간의 종속성을 표현하는 텍스트 포맷
- 동일한 Docker-compose에 포함된 애플리케이션들은 하나의 default 네트워크로 묶이게 된다

## Docker-compose Configuration

```yaml
# docker compose 사양의 버전
version: "3.8"

services:
  # NAME:
  mongodb:
    # image: 'IMAGE_NAME'
    # Detach 모드, --rm 이 기본 설정
    image: "mongo"
    volumes:
      # - VOLUME_NAME:CONTAINER_INNER_PATH
      - data:/data/db
    environment:
      # - KEY=NAME 또는 KEY: NAME
      - MONGO_INITDB_ROOT_USERNAME=username
      - MONGO_INITDB_ROOT_PASSWORD=password
    # 또는 env 파일 지정 가능
    env_file:
      - ./env/mongo.env

  backend:
    # 새로 빌드하는 경우
    build: ./backend
    # build:
    #   # 이미지 빌드하는 경로
    #   context: ./backend
    #   # dockerfile의 이름
    #   dockerfile: Dockerfile
    #   args:
    #     - some-arg=1
    # 완성된 이미지를 쓰는 경우
    # image: 'goals-backend-image'
    ports:
      # - "노출하고 싶은 호스트 머신의 포트:컨테이너 내부에서 사용하는 포트"
      - "80:80"
    volumes:
      - logs:/app/logs
      # 바인드 마운트
      - ./backend:/app
      - /app/node_modules
    env_file:
      - ./env/backend.env
    # Docker-compose에만 있는 값. 다른 컨테이너에 의존하는 경우
    depends_on:
      - mongodb

  frontend:
    build: ./frontend
    ports:
      - "3000:3000"
    volumes:
      # 바인드 마운트
      - ./frontend/src:/app/src
    # 개방형 입력 연결이 필요하다는 것을 도커에게 알림
    stdin_open: true
    # 인터렉티브 모드
    tty: true
    depends_on:
      - backend

# named volume
volumes:
  # VOLUME_NAME
  data:
  logs:
```

- ⭐️ Docker-compose 내에 작성한 서비스 이름은 코드에서 접근 가능한 컨테이너 이름이다

- Docker-compose에서 만들어주는 이름은 기본적으로 `폴더명_서비스 이름_증가하는 숫자`로 만들어진다.

  - 이름을 직접 명명하고 싶을 때

    ```yaml
    mongodb:
        // ..
        container_name: mongodb
    ```

## Docker-compose command

```bash
docker-compose up
# detach mode: Run containers in the background
docker-compose up -d

# 모든 컨테이너 삭제, 생성된 디폴트 네트워크, 모든 것 종료
docker-compose down
# 볼륨까지 삭제하고 싶을 때
docker-compose down -v

```

```bash
# 커스텀 이미지의 빌드를 강제하는 경우
docker-compose up --build

# 컨테이너를 시작하지 않고 이미지만 빌드하는 경우
docker-compose build
```

## 유틸리티 컨테이너

- 유틸리티 컨테이너는 공식적인 용어는 아니다
- 특정 환경(NodeJS, PHP…)만 포함하는 컨테이너
  - 애플리케이션이 아니라 특정 작업을 실행한다
- 시작되는 앱이 존재하지 않고 대신 특정 명령을 실행하는데 사용할 수 있는 환경만이 존재한다

## 컨테이너에서 명령을 실행하는 방법

```bash
# Dockerfile에 지정되어 있는 명령 외에 입력된 특정 명령을 실행
docker exec CONTAINER_NAME COMMAND
ex)
docker exec -it upbeat_williams npm init
```

- 메인 프로세스를 중단하지 않고 컨테이너 내부에 작성된 로그 파일을 읽는데 유용하다

```bash
# default command override
docker run -it IMAGE_NAME COMMAND
ex)
docker run -it node npm init
```

> `docker exec`와 `docker run`의 차이?<br> > `docker run`은 이미지에서 커맨드를 읽고 실행하면서 컨테이너를 생성 및 실행한다. 반대로 `docker exec`는 컨테이너 내부에서 실행된다. 그래서 해당 커맨드를 실행하기 위해서는 컨테이너가 먼저 실행되고 있어야 한다.<br> > [출처: What is Difference Between Docker Run and Docker Exec Command - linuxhint](https://linuxhint.com/difference-between-docker-run-and-docker-exec-command/)

## 실습) 유틸리티 컨테이너 구축

```docker
FROM node:14-alpine

WORKDIR /app
```

```bash
docker build -t node-util .
docker run -it -v "$(pwd)":/app node-util npm init
```

> 👩‍💻 지금까지 배워서 당연한 거지만 커맨드 실행 후 package.json 생겼을 때 깜짝 놀랐다…

### 기본 prefix 명령어 추가하기

- docker run 뒤에 이어지는 명령어들이 ENTRYPOINT 뒤에 추가된다

  ```docker
  FROM node:14-alpine

  WORKDIR /app

  ENTRYPOINT [ "npm" ]
  ```

  ```bash
  docker run -it -v "$(pwd)":/app my-npm init
  ```

  ```docker
  docker run -it -v "$(pwd)":/app my-npm install express --save
  ```

  `--save` npm install 명령이 이 프로젝트에 대한 종속성으로 들어가게 하는 플래그

### `--save`?

> 지금까지 `--save-dev` 옵션은 써봤지만, `--save`는 처음 써봐서 무슨 용도일까 싶어서 찾아보았다.

> npm 5.0.0 전까지는 package를 설치할 때 node_modules 밑으로 설치됐다. 그래서 의존성을 추가하기 위해서 `--save` 옵션을 써야했던 것이다. 그런데 npm 5.0.0 이후로는 default로 `--save` 옵션이 들어가기 때문에 더 이상 입력할 필요가 없는 것이다.

> `--save-dev`?<br>
> `devDependencies`에만 추가하기 위한 옵션이다. 즉, 개발 단게에서만 쓰이는 package인 경우 설치할 때 해당 옵션을 주는 것이다. 대표적으로 코드 컨벤션 규칙과 관련한 `eslint`, 이것과 관련된 플러그인이 `devDependencies`에 들어간다.

[참고: What is the --save option for npm install? - Stackoverflow](https://stackoverflow.com/questions/19578796/what-is-the-save-option-for-npm-install)

### 에러

> 🧑‍💻 미러링된 파일 삭제할 때마다 에러가 뜬다!

![image](https://github.com/doku-study/doku-study/assets/92101831/adf4e9fc-3a43-4952-97ce-2f511f59f18f)
![image](https://github.com/doku-study/doku-study/assets/92101831/16bb2cf6-38ae-42ca-a045-34cfc2b65147)

> 아니, 재현이 안된다...! 분명히 수업 들을 때는 계속 에러 메시지가 떴는데 찾아보려니 이젠 안 뜬다...

---

### Docker-compose 작성

```yaml
version: "3.8"
services:
	npm:
		build: ./
		stdin_open: true
		tty: true
		volumes:
			- ./:/app
```

```bash
# yaml에 여러 서비스가 있을 때 서비스 이름으로 단일 서비스 실행 가능
docker-compose run SERVICE_NAME
ex)
docker-compose run npm init

# 컨테이너 종료 시 자동 삭제 희망할 때
docker-compose run --rm npm init
```

# 함께 이야기하고 싶은 점

> linux 한정 사용자 권한 문제가 발생하는데, 혹시 비 linux 사용자 분들도 해당 에러를 유심히 보셨나요...? 과연 어느 범위까지 커버하면서 공부해야하는 건지 고민되네요.
