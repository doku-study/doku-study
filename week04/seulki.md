# 네트워킹: (교차) 컨테이너 통신

## 모듈 소개

## case 1: WWW 통신 컨테이너
컨테이너에서 실행되는 어플리케이션에서 웹 API로 HTTP Request를 보내는 방법 설명
- 일반적인 API 통신과 동일
## case 2: 컨테이너에서 로컬 호스트 머신으로의 통신
- 호스트머신 / DB 등과 도커화된 앱 내부에서 통신 원하는 상황 발생시 이에 대한 주소를 적음
## case 3: 컨테이너 간 통신
- 컨테이너 내에서 실행 중인 어플리케이션이 다른 컨테이너와 통신하길 원하는 경우 아이피를 적
## 데모 앱 분석하기

## 컨테이너 만들기 & 웹 통신하기(WWW)
```
docker run --name favorites -d -rm -p 3000:3000 favorites-node
```
- d : 분리된 모드
- rm : 실행후 삭제

기본적으로 컨테이너는 월드 와이드 웹에 요청을 보낼 수 있음

도커화된 애플리케이션 내부에서 웹 API 및 웹 페이지와 통신 가능

## 호스트 통신 작업을 위한 컨테이너 만들기
도커화된 어플리케이션에서 다른 로컬 호스트 머신과의 통신으로 변경을 원할 때 도커화된 컨테이너의 코드의 일부분만 변경하면 됨 

```docker
localhost -> host.docker.internal
```

- 도커가 이해할 수 있는 도메인
- 도커 컨테이너 내부에서 알 수 있는 호스트 머신의 IP 주소로 변환되고 이는 컨테이너와 호스트 머신 간의 통신을 보장
- 변경 후 이미지 리빌드 필요
## 컨테이너 간 통신: 기본 솔루션
컨테이너는 하나에만 집중하는 것이 낫다

```docker
docker run mongo
```

- 도커 파일 작성 필요 없이 mongo DB 공식 이미지를 실행

```docker
docker container inspect {name}
```

- NetworkSettings > IPAddress
    - 컨테이너의 IP 주소
    - 이 컨테이너에 연결 가능
- default port : 27017

⇒ 접속하는 컨테이너의 IP가 변경될 떄 마다 코드 수정후 새 이미지를 빌드해야 하는데 이를 해소 할 수 있는 방안이 없을까?
## Docker Networks 소개: 우아한 컨테이너 간 통신
**컨터이너 네트워크(=네트워크)**

다중 컨테이너 간의 통신을 허용하는 것 

```docker
docker run --network {네트워크 이름}
```

- 모든 컨테이너를 하나의 동일한 네트워크에 밀어 넣을 수 있음
    - 플래그 설정 : `--network`
- 컨테이너 IP 조회 및 해결 작업을 자동으로 수행
- 실행시 중지된 컨테이너 제거 후 실행 필요
- 도커는 네트워크를 자동으로 생성하지 않음으로 직접 만들어야 함
    
    ```docker
    docker networkd create {네트워크 이름}
    # my_network 와 같이 생성한 네트워크 뿐만 아니라 내장 네트워크 확인 가능 
    docker networkd ls 
    ```
    
- 두개의 컨테이너가 동일한 네트워크의 일부분인 경우 애플리케이션의 코드에 IP 하드코딩 하는 대신 
`컨테이너의 이름`을 입력하면 됨
    - 도커에 의해 컨테이너의 IP 주소로 변환됨
- ✅ 네트워크 설정시 컨테이너에 연결하기 위해 실행될때 포트 게시(publish) 안해줘도 됨
## Docker가 IP 주소를 해결하는 방법
✅ 도커는 코드를 읽고 내부적으로 교체하는 것이 아님

컨테이너의 이름을 보고, 코드에 플러그인된 컨테이너의 IP 주소를 연결함 

도커가 애플리케이션이 실행되는 환경을 소유하고 `애플리케이션이 요청을 전송하는 경우` 도커가 이를 인식

- 이 시점에서 주소, 컨테이너 이름, host.docker.internal 을 실제 `IP 주소로 변환`
- 주변의 컨테이너와 호스트 머신을 앎으로써 가능
## Docker Container Communication & Networks

## Docker 네트워크 드라이버
`bridge 드라이버`

- default
- 컨테이너가 동일한 네트워크에 있는 경우 이름으로 서로를 찾을 수 있음

대체 드라이버도 지원하지만 대부분 default 사용
## 모듈 요약

## 모듈 리소스

# Docker로 다중 컨테이너 애플리케이션 구축하기

## 모듈 소개
여러 서비스와 다중 컨테이너로 구성된 애플리케이션을 구축하는 것을 설명 예정
## Target 앱 & 설정
세개의 블록 : 데이터 베이스 ↔ 백엔드 웹 ↔ 프론트엔드 웹 어플리케이션 

```docker
cd backend
# package.json에 지정된 백엔드 종속성 설치
npm install
# 백엔드 어플리케이션 실행
node app.js

cd frontend
# package.json에 지정된 프론트엔드 종속성 설치
npm install
# 어플리케이션 실행
node install.js
# package.json내 scripts 실행
npm start
```
## MongoDB 서비스 도커화 하기
```docker
# 첫번째 방법
docker run mongo
# 응용, mongodb라는 이름의 컨테이너를 종료시 지우도록 detached 모드로 실행
# 백엔드 API가 도커화 되기 전 데이터베이스를 포함하는 컨테이너에서 통신시 포트 노출 필요 
docker run --name mongodb --rm -d -p 27017:27017 mongo
# 백엔드 앱 다시 실행시 mongo DB 정상적으로 접근 완료 확인 가능 
node app.js
# 로그로 확인 가능
docker logs 
```

백엔드 API가 도커화 되기 전 데이터베이스를 포함하는 컨테이너에서 통신시 포트 노출 필요

- 예시 : DB 접근시 ‘mongodb://localhost:27017/course-goals’
- 27017:27017로 설정함으로써 로컬 호스트 머신의 동일한 포트에서 이 포트 노출 가능
## Node 앱 도커화 하기
```docker
FROM node
WORKDIR /app
COPY package.json .
RUN npm install
COPY . .
# 실제 docker run시 -p 80:80 으로 내부 포트 게시 필요
EXPOSE 80
CMD ["node", "app.js"]
```

☑️ 컨테이너 내 백엔드 어플리케이션에서 localhost로 mongoDB 접근시 동일 컨테이너 내부여야만 가능함 주의

→ `host.docker.internal` (실제 로컬 호스트 머신 IP로 변환되는 특수 주소, 특수 식별자)로 변환 필요
## React SPA를 컨테이너로 옮기기
```
FROM node
WORKDIR /app
COPY package.json .
RUN npm install
COPY . .
EXPOSE 3000 
# 컨테이너 생성시마다 트리거 되어야 하는 명령
CMD ["npm", "start"]
```
```docker
docker run --name goals-frontend --rm -p 3000:3000 goals-react
```

- React 의 경우 `-it` option을 추가하여 인터렉티브 모드로 실행해야 함
    - 이 입력 수신을 하지 않으면 그것이 트리거 되어 서버가 즉시 중단됨

## 효율적인 컨테이너 간 통신을 위한 Docker 네트워크 추가하기
```
docker network ls

docker nerwork create goals-net

docker build -t mongodb .

# 같은 네트워크 상 통신임으로 포트 노출 안함
docker run --name mongodb --rm -d --network goals-network mongo

# 같은 네트워크 상 통신임으로 포트 노출 안함
# + 브라우저 등의 테스트를 위해 로컬 호스트 통신을 위해 포트 추가
docker run --name goals-frontend --rm -d -p 3000:3000
--network goals-network -it goals-react 
```
- 앞에서 배운대로 네트워크 상 통신임으로 백엔드 코드내 [localhost](http://localhost) 등의 주소를 컨테이너 이름으로 변경
    - 실행 불가
- 프론트엔드 JS 코드는 서버가 아닌 브라우저 에서 실행, 노드 런타임에 의해 컨테이너에서 직접적으로 실행
(Dockerfile < CMD 참고)
    - API와 통신하는 코드에는 브라우저에서 실행됨으로 코드내 [`localhost](http://localhost) 등의 주소` 유지
        - 백엔드 컨테이너의 경우 -p 80:80 로 호스트 머신과 포트 연결해주었음으로 프론트앤드에서 [localhost:80](http://localhost:80) 으로 접근시 정상적으로 접근 가능
    - `--network` goals-network 제거
## 몽고DB 인증 오류 해결하기(다음 강의와 관련)

## 볼륨으로 MongoDB에 데이터 지속성 추가하기
관련 링크 : https://hub.docker.com/_/mongo

**볼륨 설정**

```docker
docker run --name some-mongo -v /my/own/datadir:/data/db -d mongo
```

**보안 설정**

```docker
$ docker run -d --network some-network --name some-mongo \
	-e MONGO_INITDB_ROOT_USERNAME=mongoadmin \
	-e MONGO_INITDB_ROOT_PASSWORD=secret \
	mongo

$ docker run -it --rm --network some-network mongo \
	mongosh --host some-mongo \
		-u mongoadmin \
		-p secret \
		--authenticationDatabase admin \
		some-db
> db.getName();
some-db
```

`MONGO_INITDB_ROOT_USERNAME`, `MONGO_INITDB_ROOT_PASSWORD`

- mongodb 컨테이너에 데이터베이스 삽입이 생성되어 엑세스시 해당 정보 필요
- `-e` option으로 추가

**[Standard Connection String Format](https://www.mongodb.com/docs/manual/reference/connection-string/#std-label-connections-standard-connection-string-format)**

```docker
mongodb://[username:password@]host1[:port1][,...hostN[:portN]][/[defaultauthdb][?options]]
```

- `MONGO_INITDB_ROOT_USERNAME:MONGO_INITDB_ROOT_PASSWORD` 으로 코드에서 접근
- 맨 끝에 `authSource=admin` 추가 필요
## NodeJS 컨테이너의 볼륨, 바인딩 마운트 및 폴리싱(Polishing)
### 볼륨 바인딩 마운트

명명된 볼륨

- 호스트 머신에서 저장 위치를 알 수 없지만 컨테이너 소멸에서 데이터가 살아남도록 함

바인드 마운트

- 호스팅 머신 내부에서 로그 파일 읽기 가능

```docker
docker run --name goals-backend 
# 바인드 마운트(소스 코드에서 변경시 적용)
# 컨테이너 경로가 더 우선됨 
-v {백엔드에 대한 전체 경로}:/app
# 명명된 볼륨 사용(로그 확인용)
-v logs:/app/logs --rm -p 80:80
# /app/node_modules가 그대로 있어야 함을 컨테이너에게 알리고 
# 'app' 폴더에 바인딩하는 호스트 시스템 폴더에 존재하지 않는 node_modules 폴더로 덮어쓰면 안된다고 알림
-v /app/node_modules
-d --network goals-net goals-node
```

```docker
CMD ["node", "app.js"]
```

- node 명령으로 app.js를 실행하고 기본으로 컨테이너가 실행되는 시점에 코드에 로그인
- 노드 프로세스는 모든 코드를 로드한 다음 그 코드를 실행함으로 이후 코드가 변경되더라도 실행 중인 노드 서버에 영향을 미치지 않음
    - 방법1 ) 컨테이너 중지 - 시작
    - 방법2) package.josn > devDependencies > nodemon, script > “start” : “nopdemon app.js” 추가 + Dockerfile > CMD [”npm”, “start”] 로 변경 후 리빌드(도커 파일 변경 되었음으로)
    

### 환경변수

mongoDB 아이디/비번을 환경 변수를 통해 동적으로 주입

Dockerfile 내 값은 default

```docker
ENV MONGODB_USERNAME=root
ENV MONGODB_PASSWORD=secret
```

JS의 경우 백틱(’)을 통해 동적 값을 문자 열에 쉽게 주입

```docker
'mongodb://${process.env.MONGODB_USERNAME}:${process.env.MONGODB_PASSWORD}@mongodb:27017...'
```

docker 실행 명령줄에 하나 이상의 환경 변수를 전달하여 MongoDB 인스턴스의 초기화를 조정

```docker
$ docker run -d --network some-network --name some-mongo \
	-e MONGO_INITDB_ROOT_USERNAME=mongoadmin \
	-e MONGO_INITDB_ROOT_PASSWORD=secret \
	mongo
```

### .dockerignore

기본 컨테이너에서 복사되지 않은 것을 정의
## (바인드 마운트로) React 컨테이너에 대한 라이브 소스 코드 업데이트하기
### 바인드 마운트 볼륨 설정

```docker
docker -run -v {프로젝트 경로}:/app/src --name goals-frontend --rm -p 3000:3000 -it goals-react
```

### 이미지 빌딩 프로세스

불필요한 파일을 `.dockerignore` 에 추가시 도커 빌드 속도 향상
## 모듈 요약

## 모듈 리소스
