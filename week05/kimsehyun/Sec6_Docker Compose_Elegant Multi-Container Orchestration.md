## Docker Compose를 왜 쓰는가?
"Automating multi-container setups". 즉 다중 컨테이너 설정을 자동화하고 편리하게 관리하기 위해서다.

docker compose라는 단 하나의 구성 파일만 가지고 컨테이너들의 편성(orchestration)을 진행한다. 
모든 이미지를 빌드하고, 모든 컨테이너를 한번에 실행하고 중지하는 것이 이 과정에 포함된다.

그리고 이 configuration file만으로 다중 컨테이너(multi containers)를 관리한다. 
물론 하나의 컨테이너를 관리할 때도 docker compose를 쓸 수 있지만 컨테이너가 여러 개일 때 빛을 발한다.


### docker compose와 dockerfile 사이 관계
Docker compose는 dockerfile을 대체하지 않는다. dockerfile은 여전히 필요하다. docker compose는 이미지나 컨테이너 관리를 편리하게 하기 위해 존재할 뿐이다.

### docker compose는 서로 다른 호스트에서도 작동하나요?
docker compose는 **다른 호스트**에서 다중 컨테이너를 관리하는 데 쓰는 게 아니다. 같은 호스트에서 써야 한다.


---

## 실습 시작하기: docker compose 파일 구성

### docker compose 파일 작성 시 유의사항
- docker-compose 파일은 확장자가 **yaml**이다. yaml에서는 indentation(backspace 2번)으로 종속 관계를 구분한다.
- yaml에선 하위 요소가 key-value pair를 이룰 때 따로 -(hyphon)을 안 써도 되지만(yaml object으로 인식), key-value pair가 아니면 요소임을 나타내기 위해 -를 써줘야 한다.
- version이나 services 같은 키워드 맞춤법이 틀리지 않게 주의한다. Docker에서 이미 정해진 키워드를 읽어들여 찾기 때문. VS Code에서 Docker extension을 쓰면 자동으로 완성해주는 것도 그 이유다.


### version 지정
compose version을 설정한다(docker compose만의 자체 버전이 따로 있다고?)

강의 촬영했을 때 3.8이 제일 최근이라고 했는데, 여전히 3.8이 최신이다(2024년 1월 10일 기준). 강의 찍은 지 얼마 안됐나보네?

```yaml
version: "3.8"
```


### services 구성

```yaml
services: 
  mongodb:
    image: 'mongo'
	  volumes:
	    - my_volume_name:/container/internal/path
	  environment:
	    - MONGO_INITDB_ROOT_USERNAME: sehyun
	    - MONGO_INITDB_ROOT_PASSWORD: ilovedocker2024!
  backend: 
    
  frontend:
```

- 이미지에는 도커 허브에서 가져온 공식 이미지('mongo'가 예시) 이름이 들어갈 수도 있고, 내가 로컬에 저장해놓은 이미지의 경로를 넣을 수도 있다.
- --rm 옵션은 따로 명시해줄 필요 없다. docker compose는 컨테이너 중지되면 알아서 제거하기 때문(사실인가?)
- detached mode도 따로 명시할 필요 없다. 서비스(컨테이너) 시작하면 그때 설정해주면 된다.

### 환경변수 설정

직접 compose에 쓰는 대신에 .env 파일을 구성하고

```env
# env > mongo.env
MONGO_INITDB_ROOT_USERNAME=sehyun
MONGO_INITDB_ROOT_PASSWORD=ilovedocker2024!
```


```yaml
services: 
  mongodb:
    image: 'mongo'
	  volumes:
	    - my_volume_name:/container/internal/path
	  env_file:
	    - ./env/mongo.env
    
  frontend:
```


### 네트워크

따로 설정해줄 필요 없다. 어차피 같은 docker compose 파일 안에 적힌 서비스(컨테이너)들은 모두 같은 네트워크에 묶이도록 docker compose가 자동으로 설정해주기 때문

물론 네트워크 따로 compose 파일에 명시했다고 해서 문제 생기지 않는다. 
네트워크 이름을 설정해줄 수도 있다.


### 볼륨 설정

명명 볼륨(named volumes)을 쓸 거면 services와 같은 수준(indentation의 수준)에다 적어야 한다.
그리고, 항상 : 을 볼륨 이름 뒤에 붙여야 한다.

```yaml
services: 
  mongodb:
    image: 'mongo'
	  volumes:
	    - my_volume_name:/container/internal/path
	  env_file:
	    - ./env/mongo.env
    
volumes:
  # 볼륨의 이름 뒤에 콜론(:)을 붙여야 한다.
  data:
```


## Linux에 docker compose 설치하기

윈도우나 맥은 도커를 설치할 때 compose도 알아서 설치하지만 리눅스에선 따로 설치해줘야 한다.

1. 
```bash
sudo curl -L "https://github.com/docker/compose/releases/download/1.27.4/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
```

2. 
```
sudo chmod +x /usr/local/bin/docker-compose
```

3. 
```
sudo ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose
```

to verify: `docker-compose --version`

참조: [https://docs.docker.com/compose/install/]


docker-compose up
-> 이 compose 파일에 있는 모든 서비스를 시작(즉 이미지를 빌드)

왜 docker-complete이라는 prefix가 붙는 걸까?

### docker-compose 대신 docker compose?
version 1에서 version 2로 넘어오면서 docker-compose 대신 docker compose, 즉 -(hyphen)을 공백(space)로 바꿔서 명령어 쓰면 된다.

참고 글: https://docs.docker.com/compose/migrate/

> With Docker Desktop, Compose V2 is always accessible as `docker compose`. Additionally, the **Use Compose V2** setting is turned on by default, which provides an alias from `docker-compose`.

> Update scripts to use Compose V2 by replacing the hyphen (`-`) with a space, using `docker compose` instead of `docker-compose`.



docker-compose up -d -> 모든 이미지를 pull하고 빌드한다. -d 옵션은 detached mode를 의미한다.

docker-compose down -> 컨테이너를 중지하고 알아서 삭제. 그리고 네트워크도 삭제. 하지만 볼륨을 삭제하지는 않는다. 만약 볼륨을 삭제하고 싶다면 -v 옵션을 붙이면 된다.

```bash
docker compose down -v
```


### Dockerfile 경로 명시하기

backend 컨테이너에도 이미지를 추가하면 되지 않을까?
하지만 이미 goals-node라는 이미지가 사라져있다(docker compose down하면서 사라짐)

```yaml
services: 
  ...
  backend:
    image: 'goals-node'
```

### build 

대신에, dockerfile을 지정해서 빌드할 수 있다. 
build 명령어를 쓰면 도커는 image attribute를 자동으로 무시한다.

```yaml
...
build: ./where/Dockerfile/is/located
```

- build만 쓴다면 Dockerfile(파일 이름도 그대로 'Dockerfile'이어야 함)이 존재하는 경로를 써준다. 이때, docker compose 파일에 대한 상대 경로로 써준다.
- 또는 git 리포 URL를 써줄 수도 있다. 다음은 도커 공식 docs에서 가져온 예시다.

```yaml
services:
  webapp:
    build: https://github.com/mycompany/example.git#branch_or_tag:subdirectory
```


### context
Dockerfile 이름을 dockerfile이라고 그대로 지었다면 그냥 build 명령어에 Dockerfile 있는 경로를 적어주면 된다. context에는 절대 경로나 상대 경로 둘 다 들어갈 수 있다.
context 키워드를 명시 안하면 그냥 현재 작업 디렉토리(project directory, `.` )로 알아서 읽어들인다.

```yaml
services: 
  ...
  backend:
    # build: ./backend
    build:
      context: ./backend
```



### dockerfile
같은 폴더 안에 Dockerfile이 여러 개 있을 수도 있지 않은가?
이때, 만약에 메인으로 쓰고자 하는 dockerfile 이름이 'Dockerfile'이고
이 Dockerfile이 에러 날 경우를 대비해서 따로 만들어놓은 dockerfile 이름이 'tmp.Dockerfile'라면

```yaml
services: 
  ...
  backend:
    # build: ./backend
    build:
      context: ./backend
      dockerfile: tmp.Dockerfile
```

이런 식으로 대체용(alternate) Dockerfile 이름을 적어놓을 수 있다. 파일 이름을 정확하게 적어주어야 한다.



### args

yaml 포맷에 맞게, mapping 또는 list 형식으로 지정할 수 있다.

```yaml
services: 
  ...
  backend:
    build:
	  ...
      args:
        GIT_COMMIT: cdc3b19
```

또는

```yaml
services: 
  ...
  backend:
    build:
	  ...
      args:
        - GIT_COMMIT=cdc3b19
```



### port

```
services: 
  ...
  backend:
    # build: ./backend
    build:
      context: ./backend
      dockerfile: tmp.Dockerfile
    ports:
      - '80:80'
```


### volumes, env_file, dependency
bind mount를 이제 상대 경로로 줄여서 지정할 수 있다.
그리고 명명 볼륨은 서비스 항목 아래에도 추가해야 하지만, 밑에도 추가해줘야 한다.
익명 볼륨은 그냥 항목 아래에만 추가하면 된다.

그리고 mongoDB 컨테이너 다음에 백엔드 컨테이너가 만들어져야 하는 의존성을 compose에 명시하기 위해
depends_on 키워드를 달아준다.

```
services: 
  ...
  backend:
    # build: ./backend
    build:
      context: ./backend
      dockerfile: tmp.Dockerfile
    ports:
      - '80:80'
    volumes:
      - logs:/app/logs
      - ./backend:/app
      - /app/node_modules
    env_files:
      - ./env/backend.env
    depends_on:
      - mongodb

volumes:
  data:
  logs:
```

### docker compose 이후 네트워크 설정

여전히 서비스 이름(컨테이너 이름)은 그대로 기억한다.
코드 안에 HTTP 요청 보낼 때 docker-complete이라는 prefix를 이름 앞에 붙일 필요가 없다는 뜻이다.


## 마지막 컨테이너(프론트엔드) 추가하기

```
services: 
  ...
  backend:
    build:
      ...
  frontend:
    build: ./frontend
    ports: 
      - '3000:3000'
    volumes: 
	  - ./frontend/src:/app/src
	stdin_open: true
	
volumes:
  data:
  logs:
```

docker compose up -> 이미지가 이미 존재한다면 존재하는 이미지를 사용할 뿐, 이미지에 변화가 있을 때만 재빌드한다. (docker compose가 알아서 감지)

### stdin_open, tty
말 그대로다. 표준 입력(터미널에 입력받는 것)을 컨테이너에 열어둔다는 뜻이다. 
그래서 docker compose에서

```
stdin_open: true
```

로 설정해두면 커맨드 창에서 `docker run -i MY_CONTAINER` 명령어 실행한 것과 똑같다.
여기에 하나만 더 추가해서 

```
stdin_open: true
tty: true
```

로 설정하면 `docker run -it MY_CONTAINER` 명령어 실행한 것과 똑같아진다.

```
services: 
  ...
  backend:
    build:
      ...
  frontend:
    build: ./frontend
    ports: 
      - '3000:3000'
    volumes: 
	  - ./frontend/src:/app/src
	stdin_open: true
	depends_on:
	  - backend
	
volumes:
  data:
  logs:
```


## docker compose의 장점 다시 요약

docker compose 전에 배웠던 명령어들을 일일이 개별적으로 치는 것보다, 하나의 셸 스크립트처럼 만들어서 실행하는 게 관리하기도 편하고, 실수할 확률도 줄일 뿐 아니라, 시간도 단축할 수 있다.


## docker compose up 옵션

--build 옵션을 docker compose up 명령어에 달아주면, 이미지를 강제로 재빌드한다. 

```
docker compose build
```

1) docker compose가 이미 존재하는 이미지를 재사용하지 않도록 한다.
2) 이미지만 빌드하고 컨테이너는 실행 안한다?

### docker compose는 컨테이너 이름을 자동으로 짓는다

docker-complete_frontend_1, docker-complete_backend_1, 이런 식으로.
그런데 이 이름이 마음에 안 들면 직접 compose 파일에 지정하는 법도 있다.

```
services: 
  ...
  backend:
    build:
      ...
  frontend:
    build: ./frontend
    ports: 
      - '3000:3000'
    volumes: 
	  - ./frontend/src:/app/src
	stdin_open: true
	depends_on:
	  - backend
	container_name: frontend
```


## 퀴즈

1. docker compose 커맨드는 docker 커맨드(docker build, docker run, docker push 등)를 완전히 대체할 수 있는가?
	-> Nope. docker compose를 쓰면서 여전히 docker push 명령어로 이미지를 푸쉬할 수 있다.

`docker compose push` 라는 명령어가 존재하긴 함.

근데 여기서 궁금한 점은, 대체하는가? 와 대체할 수 있는가?의 뉘앙스가 다르지 않은가? 맘만 먹으면 docker compose로 모든 기능을 다 수행할 수 있는 건지 아니면 docker compose로도 수행을 못하는 다른 커맨드가 있는 건지가 궁금하다.

2. docker compose에서는 컨테이너에만 집중하여 컨테이너 이미지의 개념을 무시한다. (True/False)
	-> False. docker-compose에서도 여전히 이미지를 사용한다(이미 존재하는 이미지가 있다면 가져다가 그대로 사용하고, 아니면 이미지를 새로 빌드한다.)


