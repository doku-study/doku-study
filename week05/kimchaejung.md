# 새롭게 알게된 점

## Docker-compose란?

> 다수의 docker build, docker run 명령을 하나의 설정 파일로 만드는 오케스트레이션 커맨드 툴

### Docker-compose를 왜 쓰는가?

설정 프로세스를 자동화, 하나의 명령으로 개별 구성이 지닌 모든 설정을 가져올 수 있다.
개별 명령을 터미널을 일일이 입력하지 않고 설정 파일 하나로 연결된 서비스를 작동시킬 수 있다

### Docker compose 가 아닌 것

- 커스텀 이미지를 위한 Dockerfile을 대체하지 않는다
- 이미지나 컨테이너를 대체하지 않는다
- 다수의 호스트에서 다중 컨테이너를 관리하는 데 적합하지 않다
  - 이건 배포 섹션에서 다룰 예정

### Docker Compose 파일은 어떻게 작성하는가?

- 포트, 환경 변수, 볼륨, 네트워크를 설정할 수 있다
- Docker compose는 yaml 파일로 작성한다
- yaml은 들여쓰기를 사용하여 구성 옵션 간의 종속성을 표현하는 텍스트 포맷
- 동일한 docker compose에 포함된 애플리케이션들은 하나의 default 네트워크로 묶이게 된다

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
      # - KEY=NAME
      # KEY: NAME
      - MONGO_INITDB_ROOT_USERNAME=blcklamb
      - MONGO_INITDB_ROOT_PASSWORD=secret
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
    # docker-compose에만 있는 값 다른 컨테이너에 의존하는 경우
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

⭐️ docker compose 내에 작성한 서비스 이름은 코드에서 접근 가능한 컨테이너 이름이다

docker-compose에서 만들어주는 이름 `폴더명_서비스 이름_증가하는 숫자`

- 이름을 직접 명명하고 싶을 때

```yaml
mongodb:
    # image: 'IMAGE_NAME'
    # Detach 모드, --rm 이 기본 설정
    image: "mongo"
    volumes:
      # - VOLUME_NAME:CONTAINER_INNER_PATH
      - data:/data/db
    environment:
      # - KEY=NAME
      # KEY: NAME
      - MONGO_INITDB_ROOT_USERNAME=blcklamb
      - MONGO_INITDB_ROOT_PASSWORD=secret
      # 또는 env 파일 지정 가능
    env_file:
      - ./env/mongo.env
***************************
    container_name: mongodb
***************************
```

## Docker-compose command

```bash
docker-compose up
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

# 함께 이야기하고 싶은 점
