



도커 컴포즈라는 도구
- 다중 컨테이너 설정을 도와줌
- 정확히는 다수의 `docker build`, `docker run`을 대체하는 도구
- 하나의 config 파임만 가짐
- 일종의 orchestration commands set 이라고 할 수 있음
- *.sh로 관리하는 것과는 어떻게 다른걸까?*
    - 대략 아래와 같은 형태. start_containers.sh 등으로 저장 후 `chmod +`로 실행 권한 부여한 뒤, `./start_containers.sh`로 스크립트 실행하기만 하면 됨
    - 도커 네트워크 수동으로 설정, 컨테이너 의존성 관리 등 docker-compose의 기능을 활용 못한다는 단점과 시스템 셀 환경에 의존하기 때문에 호환성 문제 발생할 수 있음

```bash
docker run -d \
    --name mongodb \
    -v data:/data/db \
    --env-file ./env/mongo.env \
    mongo
```

- 도커 컴포즈는 다수의 host 환경에 적합하지 않음. 무슨 말일까?
    - 배포 관련한 것 같음

- 구성
- services = containers
    - published ports
    - env var
    - volumes
    - networks


- yaml 을 '야믈'이라 읽는다는 규칙?도 처음 접함
    - yml 가능
    - 들여쓰기를 사용해서 구성 옵션 간의 종속성을 표현하는 특정한 텍스트 포맷


## mongodb

- version 먼저 작성
    - 앱, 파일 버전이 아닌 도커 컴포트 사양의 버전
    - `version: "3.8"`
- 서비스 키
    - `services:`
    - 그 다음부턴 해당 서비스의 하위 요소인데 들여쓰기로 종속 관계 표현해야 함
- 서비스의 children = 컨테이너
    - `mongodb:`
    - `backend:`
    - `frontend:`
- 컨테이너 하위 요소 = 컨테이너 시작 명령 등
    - 이미지
    - detached mode 와 rm 옵션은 docker compose 기본값. 추가 필요 없음
    - 볼륨
        - 더 많은 nested 값 가짐. 다중 볼륨을 나타내기 위해
        - `- data:/data/db`
    - 환경 변수
        - `MONGO_INITDB_ROOT_USERNAME: max`
        - `- MONGO_INITDB_ROOT_USERNAME=max`
        - 둘 중 하나 가능
        - env 폴더에 mongo.env 파일로 관리할 수 있음
        - `env-file:` 옵션 추가해서, 위 파일 경로를 목록으로 추가 가능
        - `./env/mongo.env`
    - 네트워크
        - 도커 컴포즈에서 생성된 서비스, 컨테이너끼린 이미 동일한 하나의 네트워크에 속해있음
        - 자체 네트워크 사용하려면 `networks:` 옵션 사용 가능
        -
- 서비스에서 사용 중인 모든 named volume을 최상위 수준의 볼륨에 리스트업 해야 함
    - `volumes:` 옵션의 자식으로 `data:`만 입력하면 됨
    - 이렇게하면 다른 서비스에서 동일한 볼륨 사용할 수 있음
    - 익명, 바인드 마운트는 지정할 필요 없음

- 도커 컴포트로 서비스 시작
    - `docker-compose up -d`: detached 모드에서 시작
    - `docker-compose down`: 모든 컨테이너 삭제, 디폴트 네트워크 등 종료. 볼륨은 삭제 안 함. (볼륨은 `-v` 옵션으로 삭제 가능한데 권장하지 않음)

## backend    

- 공식 이미지가 아닌 커스텀 이미지륿 빌드해야 하기 때문에 `image` 옵션이 아닌 `build` 옵션 필요
    - `build: ./backend`
    - `context: ./backend` 파일 경로 지정. 여기서 지정한 경로 내의 파일만을 Dockerfile에서 다루게 됨. 외부 폴더에 엑세스 해야 한다면, 더 높은 수준의 경로 필요
    - `dockerfile: Dockerfile` 파일 이름 지정
- 포트
    - `ports:`
    - ` - '80:80'` : 호스트 포트 : 컨테이너 내부 포트
- 네트워크: 마찬가지로 지정할 필요 없음
- detached mode, rm 옵션 이것도 지정할 필요 없음
- 볼륩, 바인드 마운트
    - `volumes: `
    - `logs:/app/logs` named volume 추가. 최상위 볼륨에도 추가 필요
    - 바인드 마운트 시 상대 경로 필요함. `./backend:/app`.
    - `/app/node_modules`로 익명 볼륨 추가
- 환경변수
    - 위와 똑같이. 이름만 backend.env 로 설정
- `depends_on:` 옵션
    - nested 구조로 의존하는 서비스 이름 입력하면 됨 (`mongodb`)

## frontend

- `build: ./frontend`
- 볼륨
    - `./frontend/src:/app/src`
- 포트
    - `3000:3000`
- 인터렉티브 모드 필요
    - `stdin_open: true`
    - `tty: true`
- `depends_on:` 백엔드 의존하는 구 넣음

- down 후 up 한 뒤 서비스 접속하려면 약간 텀이 필요한듯
- 여튼 볼륨 잘 붙은 것 확인 가능

## 컨테이너 이름 지정

- `docker-compose up --build` : 이미지 리빌드를 강제
- `docker-compose build`: 컨테이너 시작 없이 이미지만 빌드
- 컴포즈 파일 내 서비스마다 `container_name: ` 옵션을 사용해 컨테이너 이름 지정 가능



## 유틸리티 컨테이너

- application container는 environment와 앱 파일이 있음
- utility containers는 특정 environment만 있음
    - 도커를 응용한 것

- `docker run -it node` 노드를 인터렉티브 모드로 시작할 수 있음
- `docker run -it -d node`
- `docker exec` : 컨테이너가 실행하는 기본 명령 외에 특정 명령을 실행할 수 있음
    - `docker exec -it {container name} npm init`
- `docker run -it node npm init`

## 유틸리티 컨테이너 구축

- Dockerfile을 아래와 같이 작성

```
FROM node:14-alpine
WORKDIR /app
```

- `docker build -t node-util .` 실행
- `docker run -it -v /Users/krafton/doku_study/empty:/app/node-util node-util npm init`
    - 중간에 바인드 마운트 하는 이유?
- 이렇게 유틸리티 컨테이너를 만든셈
- 내 로컬에 NodeJS 설치 안해도 된다는 장점. 
    - 모든 부가적인 도구를 설치 안해도 된다는 장점이 있다는데.. 잘 이해 안감
    - Dockerfile에서 CMD 구를 입력 안한게 오히려 독립성을 부여한다는 건가? npm 명령이 가능하게?

- `ENTRYPOINT ["executable"]` 단순히 CMD 로 입력하면 명령문에서 실행하는 것들에 덮어 씌워짐. 이걸 방지하는게 ENTRYPOINT 로 맨 앞에 실행되는 명령어를 값으로 받음
    - `docker build -t mynpm .`
    - `docker run -it -v /Users/krafton/doku_study/empty:/app/ mynpm init`

- 이 방식의 단점: CLI에서 꽤 긴 명령어 실행해야 함 -> 도커 컴포즈로 보완
- 아래와 같이 작성 후

```
version: '3.8'
services:
  npm:
    build: ./
    stdin_open: true
    tty: true
    volumes:
      - ./:/app
```

- `docker-compose run {service name} {command}`
    - `docker-compose run npm init` : 도커 컴포트에서도 유틸리티 컨테이너 개념 사용 가능
- `docker-compose run --rm npm init` : 명령 완료 후 제거됨

- 유틸리티 컨테이너.. 시작되는 앱이 없고, 특정 명령을 실행하는데 필요한 환경만 있음. 이걸 docker compose로 구성하는 방법을 다룸
    - 근데 이걸로 뭘 할건지 그래서?
    - 강의에선 모든 도구를 설치하지 않아도 로컬 시스템에서 특정한 것을 설정할 수 있다고 함.


