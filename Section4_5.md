# SECTION 4-5 네트워킹: (교차) 컨테이너 통신 - Docker로 다중 컨테이너 애플리케이션 구현하기

컨테이너 내부에서 컨테이너 외부로 통신이 필요한 경우

- www 통신 :  HTTP 요청을 웹사이트나 웹 API로 보내는 경우
    - 별도의 설정이 필요하지 않음
- 로컬 호스트 머신 통신 : 호스팅 머신,데이터 베이스와 통신하는 경우
    - 컨테이너 내부에서 인식하는 url로 변경 필요host.docker.internal
    
    ```jsx
    "mongodb://localhost:27017/swfavorites" -> "mongodb://host.docker.internal:27017/swfavorites",
    ```
    
- 컨테이너 간 통신  : 다중컨테이너 애플리케이션
    - 네트워크를 생성해야함 `docker network create NETWORK_NAME`
    - 네트워크?
        - 컨테이너 간 통신을 할 수 있도록 하는 공간
        - 모든 컨테이너가 서로 통신할 수 있으며 IP 조회 및 해결 작업을 자동으로 수행함
    - **IP 주소를 연결하고 싶은 컨테이너 이름으로 변경**
    
    ```docker
    # 컨테이너의 IP 주소 알기
    docker container inspect CONTAINER_NAME
    
    # 주소 변경하기
    "mongodb://localhost:27017/swfavorites" -> "mongodb://mongodb:27017/swfavorites"
    ```
    
    - 컨테이너 빌드할 때, 네트워크 연결해줘야 함
        
        `docker run --name CONTAINER_NAME --network NETWORK_NAME -d --rm IMAGE_NAME`
        

# SECTION 6 Docker Compose: 우아한 다중 컨테이너 오케스트레이션

Docker-compose

여러개의 도커 컨테이너를 빌드하고, run등의 명령을 하나의 설정 파일로 만드는 오케스트레이션 커맨드 툴

- 사용하는 이유
    - 설정 프로세스를 자동화
    - docker-compose파일 하나로 연결된 서비스를 실행시킬 수 있음
- 할 수 없는 것
    - Dockerfiles 대체 X
    - 이미지나 컨테이너를 대체하지 X
    - 다수의 호스트에서 다중 컨테이너를 관리하는 데 적합하지 X
- 포트, 환경변수, 볼륨, 네트워크 설정 가능
- .yaml 형식으로 작성
- 같은 docker-compose에 포함된 애플리케이션들은 하나의 default 네트워크로 묶임

                                                         

```docker
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

## Docker-compose command

```docker
## 띄우기
docker-compose up
# detach mode: Run containers in the background
docker-compose up -d

## 삭제
# 모든 컨테이너 삭제, 생성된 디폴트 네트워크, 모든 것 종료
docker-compose down

# 볼륨까지 삭제하고 싶을 때
docker-compose down -v

# 커스텀 이미지의 빌드를 강제하는 경우
docker-compose up --build

# 컨테이너를 시작하지 않고 이미지만 빌드하는 경우
docker-compose build
```
