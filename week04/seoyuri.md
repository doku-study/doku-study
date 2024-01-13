# 정리 및 새롭게 알게된 점

## 네트워킹: (교차)컨테이너 통신
### 도커화된 앱에서 가능한 통신방법
#### 1. www 통신 컨테이너
- HTTP 요청을 다른 웹사이트나 웹 API로 전송하는 방법
- 기본적으로 컨테이너는 월드와이드웹에 요청을 보낼 수 있음
#### 2. 컨테이너에서 로컬호스트 머신으로의 통신
- 컨테이너화 된 애플리케이션 내부로 부터의 통신은 나의 호스트 머신에서 실행 중인 특정 서비스에 연결
- 컨테이너 또는 컨테이너화 된 앱과 그 컨테이너 외부의 무언가 간의 통신
- localhost를 docker가 이해할 수 있도록 도메인 대체 -> host.docker.internal : 컨테이너와 호스트머신간의 통신 보장
#### 3. 컨테이너 간 통신 
- 통신 및 네트워킹의 또 다른 형태
- 실습 : mongodb 컨테이너 올리기 -> docker container inspect로 컨테이너 정보 조회 -> NetworkSetting/IPAdress로 도메인 대체
    - 문제점: 하드코딩
- 우아한 컨테이너 간 통신 : Docker networks
    - docker run --netword my_network : 모든컨테이너가 서로 통신할 수 있는 네트워크 생성
    - IP 조회 및 해결작업을 자동으로 수행 : 각각의 목적을 가진 컨테이너가 독립적으로 존재
    - network not found : 볼륨같이 자동으로 볼륨을 생성하지 않음 -> docker network created network로 network 생성 -> 다시 docker run --netword my_network로 네트워크안에 컨테이너 연결하기
    - 컨테이너 내부에서 다른 컨테이너의 api 호출할 때 도메인에 컨테이너 이름 입력
    - 도커를 시작할 때 port를 지정해줄 필요 없음

### docker가 IP 주소를 해결하는 방법
- 도커가 IP 주소를 자동으로 해결 : 소스코드를 내부적으로 교체하지 않아도 컨테이너 이름을 보고 코드에 플러그인 된 컨테이너의 IP 주소를 연결
    - 도커가 애플리케이션이 실행되는 환경을 소유하고 주소, 컨테이너 이름, host.docker.internal을 인식 후 실제 IP주소로 변경, 주변의 컨테이너와 호스트머신을 알고 있기 때문


## Docker로 다중 컨테이너 애플리케이션 구축하기
### database(MongoDB)
- 기본 컨테이너 만들기
    - mongoDB 이미지 다운 받아 port번호 지정해 컨테이너 올림
    - docker run --name mongodb --rm -d -p 27017:27017 mongo
- 접근이 제한되어야 함
    - docker run --name mongodb --rm -d --network goals-net mongo
    - 백엔드와 같은 네트워크에 있기 때문에 포트번호 필요 없음, 네트워크만 지정
- 데이터가 지속되어야 함
    - 볼륨 추가 :  -v data:/data/db
    - 보안을 위한 환경변수(userName, password) 추가 : -e MONGO_INITDB_ROOT_PASSWORD=secret
```
docker run --name mongodb -v data:/data/db --rm -d --network goals-net -e MONGO_INITDB_ROOT_USERNAME=max -e MONGO_INITDB_ROOT_PASSWORD=secret mongo
```

### backend(NodeJS REST API)
- 기본 컨테이너 만들기
    - Dockerfile 작성, 이미지 빌드(docker build -t goals-node .)
    - mongoDB 도메인주소를 localhost -> host.docker.internal로 변경
    - docker run -name goals-backend --rm -d -p 80:80 goals-node
- 접근이 제한되어야 함
    - mongoDB 도메인주소를 host.docker.internal -> mongo로 변경 동일한 네트워크상에서 컨테이너 이름을 읽을 수 있기 때문
    - docker run -name goals-backend --rm -d -p 80:80 --network goals-net goals-node(프론트와 통신하기위해 포트 남김)
- 가이드에 따라 데이터베이스 환경변수 적용 : 도메인에 max:secret@mongodb, 마지막에 ?authSource-admin 추가
    - 'mongodb://max:secret@mongodb:27017/course-goals?authSource=admin'
    - 그러나 mongoDB username과 password가 변경될 수 있음 -> Dockerfile에서 ENV 명령으로 변경시 유연하게 대처 : ENV MONGODB_USERNAME=root, ENV MONGODB_PASSWORD=secret
    ```
    mongodb://${ process.env.MONGODB_USERNAME}:${process.env.MONGODB_PASSWORD}
    @mongodb:27017/course-goals?authSource-admin
    ```
- 실시간 소스 코드 업데이트
    - 실시간 소스코드가 업데이트 되도록 : -v User/docker=complete/backend/:/app
    - 컨테이너가 작성하는 로그파일에 데이터가 유지되도록 : -v logs:/app.logs
    - 로컬호스트 머신에 node_modules이 없는 경우 로컬에 존재하지 않는 그 폴더로 덮어쓰지 말아야 한다 -> 익명볼륨 사용 : -v /app/node_modules (87강, 3:50)
    - 코드가 변경될 때마다 노드서버가 다시 시작 : nodemon
```
docker run -name goals-backend -v User/docker=complete/backend:/app -v logs:/app.logs -v /app/node_modules --rm -d -p 80:80 --network goals-net goals-node
```

### frontend(React SPA)
- 기본 컨테이너 만들기
    - Dockerfile 작성, 이미지 빌드(docker build -t goals-react .)
    - docker run -name goals-frontend --rm -d -p 3000:3000 -it goals-react(-it: 인터렉티브 모드 - 명령을 입력하여 상호작용하는 것이 가능)
- 네트워크 추가 후
    - 네트워크 추가 후 백엔드 도메인주소 그대로 localhost : 리엑트코드는 브라우저에서 실행되고 브라우저는 도커컨테이너를 읽지 못하기 때문에 
    - docker run -name goals-frontend --rm -d -p 3000:3000 -it goals-react
    - --network옵션 필요 없음 : 네트워크를 신경쓰지 않고 노드API와 데이터베이스와 상호작용하지 않음
    - 프론트는 포트 남기기 : 로컬에서 앱과 상호작용하기 위해
- 실시간 소스 코드 업데이트
    - 바인드마운트 추가 : -v User/docker=complete/frontend/src:/app/src

### 효율적인 컨테이너 간 통신을 위한 Docker 네트워크 추가하기
- docker network create goals-net

# 함께 이야기하고 싶은 점, 느낀점
- 환경변수 설정 등은 처음에 대충 넘어가서 헷갈렸는데 이번 복습을 통해 제대로 알 수 있었다.
- 전반적으로 복잡하긴 했는데 애플리케이션 운영하는데 도커를 어떤식으로 이용해야하는지 알 수 있어 좋았다
- '로컬호스트 머신에 node_modules이 없는 경우 로컬에 존재하지 않는 그 폴더로 덮어쓰지 말아야 한다' 바인드마운트, 명명볼륨, 익명볼륨 3개 다 쓰이는 부분은 저번에도 이번에도 잘 이해가 가지 않는다. 더 찾아봐야할듯