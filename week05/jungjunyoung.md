## Docker Compose 란 무엇이며 왜 사용할까?

앞서 여러 컨테이너를 빌드하고, 실행하는 과정을 겪었다면 반복되는 이미지 빌드와 컨테이너 실행 명령에 지쳤을 것이다.

또 이러한 명령을 CLI 에 타이핑하는 것은 휴먼 에러 (오타 등)이 발생하는 것을 방지하지 못한다.

Docker Compose 는 이러한 문제점을 해결하기 위해 등장했다.

Docker Compose 는 다수의 docker build 와 다수의 docker run 을 대체하는 도구로,

하나의 config 파일과 Orchestration 명령들 (build, start, stop, ...) 을 사용한다.

Docker Compose 가 Dockerfile 을 대체하는 것은 아니다.

Docker Compose 가 이미지나 컨테이너를 대체하는 것 또한 아니다.

Docker Compose 는 하나의 호스트에서 다중 컨테이너를 핸들링하는 데에 적합하다.





<br />

## Docker Compose 파일 작성해보기 (MongoDB)

프로젝트 루트에 docker-compose.yaml 파일을 생성한 뒤, 다음과 같이 작성해보자.

```yaml
# docker-compose.yaml

# 파일 버전이 아닌, Docker Compose 의 버전을 명시함
version: '3.8'

# 각 컨테이너를 service 로 칭한다.
services:
  mongodb:
    image: 'mongo'
    # 키-값 쌍이 아닌 단일 값인 경우에는 아래와 같이 [- 값] 으로 표현한다.
    volumes:
      - data:/data/db
    # environment:
    # MONGO_INITDB_ROOT_USERNAME: max
    # MONGO_INITDB_ROOT_PASSWORD: secret
    # 보안을 위해 외부 env 파일의 값을 불러올 수도 있다.
    env_file:
      - ./env/mongo.env
# 도커가 services 를 위해 생성해야 하는 명명된 볼륨을 인식하기 위해 필요한 구문. service 끼리 명명된 볼륨을 공유할 수 있다.
# 익명 볼륨과 바인드 마운트는 여기에 선언하지 않는다.
volumes:
  data:
```



### docker run 과 비교한 service 의 default 옵션들

* `--rm ` : 서비스(컨테이너)가 중지되면 자동으로 삭제된다.
* `-d` : 서비스는 기본적으로 detached 모드에서 실행된다.
* `--network` : docker compose 에 명시된 모든 service 는 compose 에 의해 자동으로 하나의 docker network 에 할당된다.



<br />



## Up, Down 으로 compose 실행, 중지해보기

다음 명령을 통해 docker-compose.yaml 파일에 명시된 service 들을 실행할 수 있다.

```shell
docker-compose up
```

* up 관련 옵션들

`-d` : compose 를 detached 모드에서 실행





다음 명령을 통해 service 들을 실행 중지하고, 컨테이너를 삭제할 수 있다.

```shell
docker-compose down
```

중지된 컨테이너는 즉각 삭제되며, 함께 생성된 default 네트워크도 삭제된다.

그러나 볼륨은 바로 삭제되지 않는다.

* down 관련 옵션들

`-v` : service 들을 실행 중지할 때 볼륨도 함께 삭제







<br />

## Docker Compose 파일 작성해보기 (MongoDB + backend)

```yaml
# docker-compose.yaml

# 파일 버전이 아닌, Docker Compose 의 버전을 명시함
version: '3.8'

# 각 컨테이너를 service 로 칭한다.
services:
  mongodb:
    image: 'mongo'
    # 키-값 쌍이 아닌 단일 값인 경우에는 아래와 같이 [- 값] 으로 표현한다.
    volumes:
      - data:/data/db
    # environment:
    # MONGO_INITDB_ROOT_USERNAME: max
    # MONGO_INITDB_ROOT_PASSWORD: secret
    # 보안을 위해 외부 env 파일의 값을 불러올 수도 있다.
    env_file:
      - ./env/mongo.env
  backend:
    # build: ./backend
    build:
      # Dockerfile 은 자신이 위치한 상위 디렉토리를 참조하지 못한다.
      # 그러므로 Dockerfile 이 다른 중첩 폴더에 있고 그 중첩 폴더의 외부를 참조해야 한다면,
      # 아래의 context는 더 상위의 폴더로 설정되어야 한다.
      context: ./backend
      dockerfile: Dockerfile
      # args: Dockerfile 에 ARG 구문에 삽입할 값을 선언한다.
      args:
        some-arg: 1
    ports:
      - '80:80'
    volumes:
      - logs:/app/logs
      # 바인드 마운트
      - ./backend:/app
      # 익명 볼륨
      - /app/node_modules
    env_file:
      - ./env/backend.env
    depends_on:
      # 의존하고 있는 다른 컨테이너 (서버의 경우 DB 에 의존) 를 명시하여 컨테이너 생성 순서 보장
      - mongodb
# 도커가 services 를 위해 생성해야 하는 명명된 볼륨을 인식하기 위해 필요한 구문. service 끼리 명명된 볼륨을 공유할 수 있다.
# 익명 볼륨과 바인드 마운트는 여기에 선언하지 않는다.
volumes:
  data:
  logs:
```



<br />







## Docker Compose 파일 작성해보기 (MongoDB + backend + frontend)

```yaml
# docker-compose.yaml

# 파일 버전이 아닌, Docker Compose 의 버전을 명시함
version: '3.8'

# 각 컨테이너를 service 로 칭한다.
services:
  mongodb:
    image: 'mongo'
    # 키-값 쌍이 아닌 단일 값인 경우에는 아래와 같이 [- 값] 으로 표현한다.
    volumes:
      - data:/data/db
    # environment:
    # MONGO_INITDB_ROOT_USERNAME: max
    # MONGO_INITDB_ROOT_PASSWORD: secret
    # 보안을 위해 외부 env 파일의 값을 불러올 수도 있다.
    env_file:
      - ./env/mongo.env
  backend:
    # build: ./backend
    build:
      # Dockerfile 은 자신이 위치한 상위 디렉토리를 참조하지 못한다.
      # 그러므로 Dockerfile 이 다른 중첩 폴더에 있고 그 중첩 폴더의 외부를 참조해야 한다면,
      # 아래의 context는 더 상위의 폴더로 설정되어야 한다.
      context: ./backend
      dockerfile: Dockerfile
      # args: Dockerfile 에 ARG 구문에 삽입할 값을 선언한다.
      args:
        some-arg: 1
    ports:
      - '80:80'
    volumes:
      - logs:/app/logs
      # 바인드 마운트
      - ./backend:/app
      # 익명 볼륨
      - /app/node_modules
    env_file:
      - ./env/backend.env
    depends_on:
      # 의존하고 있는 다른 컨테이너 (서버의 경우 DB 에 의존) 를 명시하여 컨테이너 생성 순서 보장
      - mongodb
  frontend:
    build:
      context: ./frontend
      dockerfile: Dockerfile
    ports:
      - '3000:3000'
    volumes:
      - ./frontend/src:/app/src
    depends_on:
      - backend
    # 아래 두 옵션은 React 16 버전에서 인터렉티브 모드로 실행하지 않으면 앱이 종료되는 문제를 해결하기 위한 옵션이다.
    # docker run -it 옵션과 같은 역할을 한다.
    stdin_open: true
    tty: true
# 도커가 services 를 위해 생성해야 하는 명명된 볼륨을 인식하기 위해 필요한 구문. service 끼리 명명된 볼륨을 공유할 수 있다.
# 익명 볼륨과 바인드 마운트는 여기에 선언하지 않는다.
volumes:
  data:
  logs:
```

<br />

## Docker Compose 관련 명령 변형 예시들

up 할 때 이미지 리빌드 강제 : `docker-compose up --build`

이미지 빌드만 하고 컨테이너는 시작하지 않음 : `docker-compose up build`

compose detached 모드로 시작 : `docker-compose up -d`





<br />

## Docker Compose 관련 기타 팁



### docker ps 로 실행중인 컨테이너를 조회하면 컨테이너 이름이 바뀌어있는 문제

docker compose 를 실행시킨 후 컨테이너 목록을 조회하는  `docker ps`  로 실행중인 컨테이너 목록을 조회해보면 컨테이너 이름이 docker 가 자동으로 service 이름을 차용하여 설정된 이름으로 되어있는 것을 볼 수 있다. (ex: 프로젝트이름-서비스이름_1)

그러나, docker-compose-yaml 에 명시한 service 이름 (위에서는 mongodb, backend) 은 여전히 각 애플리케이션 소스 코드에서 사용할 수 있음을 잊지 말자.



```javascript
// mongodb 라는 서비스 이름은 여전히 node.js 애플리케이션 코드에서 사용하고 있다.
mongoose.connect(
  `mongodb://${process.env.MONGODB_USERNAME}:${process.env.MONGODB_PASSWORD}@mongodb:27017/course-goals?authSource=admin`,
  {
    useNewUrlParser: true,
    useUnifiedTopology: true,
  },
  (err) => {
    if (err) {
      console.error('FAILED TO CONNECT TO MONGODB');
      console.error(err);
    } else {
      console.log('CONNECTED TO MONGODB!!');
      app.listen(80);
    }
  }
);
```



만약 실행되는 컨테이너 이름도 서비스 이름과 같게 설정하고 싶다면, docker-compose.yaml 에 다음 구문을 추가하자.

```yaml
services:
	mongodb:
		image: 'mongo'
		container_name: mongodb
```



<br />

### Docker compose 가 이미지를 항상 리빌드하지는 않는다

`docker-compose up` 명령은 소스 코드의 수정 등이 있을 때에는 이미지를 리빌드한다.

그러나 이미지를 다시 빌드할 필요가 없을 경우에는 캐시된 이미지를 사용한다.





<br />



## 컨테이너에서 명령어 실행하기





```shell
docker exec -it vigorous_dewdney npm init
```



```shell
docker exec 컨테이너이름 컨테이너에전달할명령
```





<br />

## 유틸리티 컨테이너 만들어보기

유틸리티 컨테이너는 프로젝트 셋업을 위해 호스트 머신에 여러 시스템을 설치해야 하는 불편함을 덜어준다.

* ex1 : React 프로젝트 생성을 위해 node 를 호스트 머신에 설치

<br />



먼저 빈 프로젝트에 Dockerfile 을 작성하자.

```dockerfile
# Dockerfile

# alpine 버전은 좀더 슬림하고 최적화되어있는 node 버전이다.
FROM node:14-alpine

WORKDIR /app
```

<br />

node-util 이라는 이름으로 이미지를 생성해준다.

```shell
docker build -t node-util .
```

<br />

node-util 이미지로 컨테이너 실행

컨테이너에서 실행한 node를 호스트머신에서는 node 설치 없이 사용할 수 있도록 한다.

```shell
docker run -it -v $(pwd):/app node-util npm init
```



여기까지 진행하면, 비어있던 프로젝트 폴더에 npm init 으로 인해 package.json이 생긴 걸 볼 수 있다.

호스트 머신에서 npm init 명령으로 node 프로젝트를 생성하기 위해서는 node 설치가 필수적이었는데, node 이미지와 바인드 마운트된 컨테이너의 도움으로 node 를 호스트 머신에 설치하지 않고도 프로젝트 셋업을 할 수 있었다.





<br />

## ENTRYPOINT

앞서 봤던 명령인

```shell
docker run -it -v $(pwd):/app node-util npm init
```

에서, docker run 뒤의 npm init 커맨드는 컨테이너가 실행될 때 컨테이너 내부에서 실행할 명령어이다.

Dockerfile 에서도 이와 같은 기능을 하는 `CMD` 구문이 있었다. 

문제는 CMD로 정의한 실행 명령은 docker run 뒤에 붙이는 컨테이너 내부 실행 명령에 의해 덮어씌워진다는 것이다.

이를 방지하기 위해 `ENTRYPOINT`가 있다. ENTRYPOINT 에 정의한 명령은 docker run 뒤의 컨테이너 내부 실행 명령의 prefix 역할을 한다.



```dockerfile
# Dockerfile

# alpine 버전은 좀더 슬림하고 최적화되어있는 node 버전이다.
FROM node:14-alpine

# npm 이 컨테이너 내부 실행 명령의 prefix 로 선언되었다. 
ENTRYPOINT ["npm"]

WORKDIR /app
```



npm 이 컨테이너 내부 실행 명령의 prefix 로 선언되었으므로, npm init 을 다 쓸 필요 없이, init 만 쓰면 된다.

```shell
docker run -it -v $(pwd):/app node-util init
```

npm install 도 문제없이 실행할 수 있다.

```shell
docker run -it -v $(pwd):/app node-util install
```



호스트 머신에 node 를 직접 설치하지 않고, 컨테이너의 도움으로 프로젝트를 셋업하고,  node 프로젝트에 필요한 종속성 라이브러리들 역시 node 를 설치하지 않고도 설치할 수 있었다.



그런데 docker run 으로 작성해야 하는 명령이 너무 길다. docker-compose 를 활용해보자.

<br />

## Docker Compose 와 유틸리티 컨테이너 





```yaml
version: '3.8'
services:
  npm:
    build: ./
    # stdin_open 과 tty 는 인터렉티브 모드를 위해 켜둔다.
    stdin_open: true
    tty: true
    # 바인드 마운트
    volumes:
      - ./:/app
```

> 위의 길었던 docker run ...  install 명령을 docker-compose.yaml 파일로 옮겼다.



docker compose 에서 특정 서비스만 실행하고자 할 때에는 `run` 명령어를 쓴다.

```shell
docker-compose run --rm npm init
```

package.json 이 성공적으로 생성되었다면, 이제 express 도 한 번 설치해보자.

```shell
docker-compose run --rm npm install express --save
```
