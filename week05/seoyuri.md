# 정리 및 새롭게 알게된 점
## docker-compose
### 무엇이며 왜 사용하는가?
- docker build와 docker run 명령을 대체할 수 있는 도구
- 여러 docker build와 docker run을 단 하나의 구성파일로 가짐
- Dockerfile을 대체하지 않음
- 이미지나 컨테이너를 대체하지 않음
- 다수의 호스트에서 다중 컨테이너를 관리하는데는 적합하지 않음

### compose 파일 (docker-compose.yaml)
- 버전확인 : docs.docker.com/compose/compose-file
```
version: "3.8"
service:
    mongodb:
        image: 'mongo' # 이미지 이름
        volumes:
            - data:/data/db # 볼륨이름: 컨테이너 내부 경로
        container_name: mongodb # container 이름 설정
        #environment: # 직접 설정
        #    MONGO_INITDB_ROOT_USERNAME: max
        #    MONGO_INITDB_ROOT_PASSWORD: secret
            # - MONGO_INITDB_ROOT_USERNAME=max
        env_file:
            - ./env/mongo.env

    backend:
        build: ./backend #Dockerfile이 있는 폴더를 가르킴
        #build:
        #    context: ./backend
        #    dockerfile: Dockerfile
        #    args:
        #        some-arg: 1
        ports:
            - '80:80'
        volumes:
            - logs:/app/logs
            - ./bbackend:app # 바인드마운트 절대경로 대신 compose파일에 대한 상대경로 사용
            - /app/node_modules
        env_file:
            - ./env/backend.env
        depends_on: #backend가 mongodb에 의존함을 컴포즈에 알려주기위한 옵션
            - mongodb # 의존할 서비스, mongodb 실행 후 backend 실행 

    frontend:
        build: ./frontend
        ports:
            - '3000:3000'
        volumes:
            - ./frontend/src:/app/src
        # -it 플래그는 개방형 표준 입력을 위한 명령어

        stdin_open: true # 이 서비스에 개방형 입력 연결이 필요
        tty: true # 이 터미널에 연결
        depends_on:
            - backend


# 최상위 수준의 volumes 키, service에서 사용 중인 명명된 볼륨이 나열되어야함, 바인드마운트와 익명볼륨은 추가할 필요X
volumes: 
    data: # 명명된 볼륨을 인식하기 위해 필요한 구문
    logs:
```
- detached와 --rm 옵셥은 defualt 값
- 도커가 컴포즈 파일에 특정된 서비스에 대해 새환경을 자동으로 생성하고 모든 서비스를 즉시 네트워크에 추가
- docker-compose up : 컴포즈 파일에서 찾을 수 있는 서비스 시작, 필요한 이미지 빌드, detach모드: -d 추가
- docker-compose down : 모든 컨테이너 삭제 및 네트워크 종료, 볼륨 삭제: -v 추가
- 한번 빌드된 이미지는 재빌드X, 코드가 변경될 때 docker-compose가 인지하여 빌드
- 강제로 빌드하고 싶다면 'docker-compose build' 혹은 'docker-compose up --build'(docker-compose file에서 build만 해당))
- 컨테이너 이름은 자동생성 (!= service이름)

### linux에 Docker Compose 설치

~~~
1. sudo curl -L "https://github.com/docker/compose/releases/download/1.27.4/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
2. sudo chmod +x /usr/local/bin/docker-compose
3. sudo ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose
~~~



# 함께 이야기하고 싶은 점, 느낀점
