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
```docker
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
- `docker-compose up` : 컴포즈 파일에서 찾을 수 있는 서비스 시작, 필요한 이미지 빌드, detach모드: -d 추가
- `docker-compose down` : 모든 컨테이너 삭제 및 네트워크 종료, 볼륨 삭제: -v 추가
- 한번 빌드된 이미지는 재빌드X, 코드가 변경될 때 docker-compose가 인지하여 빌드
- 강제로 빌드하고 싶다면 'docker-compose build' 혹은 'docker-compose up --build'(docker-compose file에서 build만 해당)
- 컨테이너 이름은 자동생성 (!= service이름)

### linux에 Docker Compose 설치

~~~
1. sudo curl -L "https://github.com/docker/compose/releases/download/1.27.4/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
2. sudo chmod +x /usr/local/bin/docker-compose
3. sudo ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose
~~~

## 유틸리티 컨테이너
### 컨테이너에서 명령을 실행하는 다양한 방법
- `docker exec` : 실행중인 컨테이너에서 Dockerfile에 지정되어 있는 명령 외에 입력한 특정 명령을 실행
- docker stop 후 컨테이너 다시 시작할때 이미지 이름 앞에 -it(인터렉티브 모드) 옵션을 주고 뒤에 명령을 입력하여 디폴트 명령을 오버라이드 할 수 있음 -> 명령 완료 후 컨테이너 종료
    - ex: docker run -it node npm init
### 유틸리티 컨테이너 구축
- node 이미지를 만들고, 컨테이너를 올릴 때 바인드마운트로 미러링하여 로컬내부에 개발도구를 설치하지 않아도 로컬에서 작업할 수 있는 환경이 될 수 있음
### ENTRYPOINT 활용
- Dockerfile - ENTRYPOINT : defult 명령어, 유틸리티컨테이너의 명령어가 추가됨
- Dockerfile - CMD : 명령어가 대체됨
    - docker run -it 바인드마운트 이미지이름 명령
### docker compose 사용
```docker
version: "3.8"
service:
    npm:
        build: ./
        stdin_open: true # 입력이 필요한 명령의 경우 입력받을 수 있음
        tty: true # 입력이 필요한 명령의 경우 입력받을 수 있음
        volumes:
            - ./:/app
```
- `docker-compose run --rm npm init`


# 함께 이야기하고 싶은 점, 느낀점

