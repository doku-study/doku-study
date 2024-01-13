# 네트워킹: (교차) 컨테이너 통신

## 모듈 소개
Docker Network
- 다수 컨테이너 간 연결
- 컨테이너간 통신
- 컨테이너 <> 로컬 호스트 머신 연결

- 다른 서비스로 요청 보내기
- 퍼블릭 네트워크(WWW)로 요청 보내기

## case 1: WWW 통신 컨테이너
특정 어플리케이션(Node, Python, PHP 등)에서 퍼블릭(WWW) API 호출(=HTTP)

예시
- Axios 패키지를 사용한 Node 앱을 통해 swapi.dev/api/films로 GET 호출

## case 2: 컨테이너에서 로컬 호스트 머신으로의 통신
컨테이너 외부의 서비스와의 통신 ex) Database

예시
- 위의 Node앱은 MongoDB와 연결되어 데이터 저장 및 가져오기 수행

## case 3: 컨테이너 간 통신
SQL DB가 있는 다른 컨테이너와 통신

## 데모 앱 분석하기
axios, express, body-parser, mongoose 종속성이 포함된 Node  Web Application

4개의 엔드포인트
- GET /favorites
- POST /favorites
- GET /movies
- GET /people

mongoose 패키지를 사용해 POST /favorites 결과를 MongoDB에 저장

- GET API 요청
    - 문제없이 작동함
- POST API 요청
    - 앞선 GET 응답에서 필요한 값을 찾은 뒤
    - postman을 통해 "name", "type", "url" JSON K-V body 작성 후 요청
    - MongoDB에 저장 후 결과 응답


## 컨테이너 만들기 & 웹 통신하기(WWW)
docker build -t favorites-node . 
docker run --name favorites -d --rm -p 3000:3000 favorites-node
- 컨테이너가 제대로 시작되지 않음을 확인할 수 있다.

docker run --name favorites -p 3000:3000 favorites-node
```
MongoNetworkError: failed to connect to server [localhost:27017] on first connect [Error: connect ECONNREFUSED 127.0.0.1:27017
    at TCPConnectWrap.afterConnect [as oncomplete] (node:net:1595:16) {
  name: 'MongoNetworkError'
}]
```
- 컨테이너가 MongoDB에 접근하지못함. > 소스코드의 mongoose 부분을 주석처리하여 웹서비스만 시작
- 도커화된 앱 내부에서 HTTP 요청이 자연스럽게 가능

## 호스트 통신 작업을 위한 컨테이너 만들기
'로컬 머신'에 있는 MongoDB <> '컨테이너'에 있는 Node App
통신을 위해서는 소스코드(app.js)의 L71의 localhost를 host.docker.internal로 변경해주어야한다.

## 컨테이너 간 통신: 기본 솔루션
mongodb를 호스트머신 설치 대신 컨테이너로 실행한다 > docker run -d --name mongodb
생성된 mongodb의 ip주소 확인 > docker container inspect mongodb | grep IPAddress
소스코드(app.js)의 L71의 localhost를 조회한 IP로 변경

단점
컨테이너 IP주소를 직접 찾아서 입력해야함
Mongodb 컨테이너의 IP주소가 변경되면, 소스코드업데이트 후 리빌드 (하드코딩)

## Docker Networks 소개: 우아한 컨테이너 간 통신
docker run 명령어 수행시 --network 옵션을 추가하여, 컨테이너가 통신할 수 있는 공유 네트워크를 생성할 수 있다.
이를 통해 IP 조회 및 적용을 자동으로 수행할 수 있다.

docker run -d --name mongodb --network favorites-net mongo
\> docker: Error response from daemon: network favorites-net not found.

docker network create favorite-net
docker network ls 

소스코드에 컨테이너 이름을 입력하도록 변경
docker build -t favorites-node:net-mongo .


## Docker가 IP 주소를 해결하는 방법
컨테이너와 호스트 머신간 통신 > host.docker.internal 사용
컨테이너와 다른 컨테이너간 통신 > container network 사용 및 container name을 주소로 사용

소스코드의 변경하지않고, 소스코드의 DNS주소를 파악해 적절히 라우팅함

## Docker 네트워크 드라이버
https://docs.docker.com/network/drivers/

## 모듈 요약
Docker container가 통신을 하고자 할 시, 다음과 같은 방법을 통해 수행된다.
- To Public Web: 기본 생성된 bridge network를 통해 호스트머신과 매핑되어 인터넷 통신이 가능하다.
- To Localhost: host.docker.internal 도메인을 통해 요청이 가능
- To Containers: 
    - 하드코딩: 컨테이너 IP를 직접 찍어서 통신 가능
    - 권장: docker Network를 생성한뒤 컨테이너를 연결하여 컨테이너ID 도메인을 통한 요청 가능

# Docker로 다중 컨테이너 애플리케이션 구축하기

## 모듈 소개
지금까지 배웠던 내용(도커 컨테이너 기본사용법, 볼륨, 네트워크등)을 사용한,
둘 이상의 컨테이너로 구성된 멀티컨테이너 애플리케이션 구현

## Target 앱 & 설정
3개의 주요 빌딩 블록
1. 데이터베이스
    - MongoDB
        - 앱에서 생성되는 데이터 저장
        - 데이터 보존 필요
        - 액세스 제한(사용자,비밀번호 추가)
2. 백엔드 웹 앱
    - NodeJS REST API
        - JSON 데이터 처리
            - log데이터 유지 필요
            - 소스코드 변경사항 즉시 반영
3. 프론트 웹 앱
    - React SPA

## MongoDB 서비스 도커화 하기
Docker Hub에 존재하는 MongoDB 이미지 사용한 실행

docker run --name mongodb --rm -d -p 27017:27017 mongo


## Node 앱 도커화 하기
``` dockerfile
FROM node:14

WORKDIR /app

COPY ./package.json .

RUN npm install

COPY . .

EXPOSE 80

CMD ["node", "app.js"]
```

docker build -t goals-node .
docker run --name goals-backend --rm -d -p 80:80 goals-node


## React SPA를 컨테이너로 옮기기
```dockerfile
FROM node:14

WORKDIR /app

COPY ./package.json .

RUN npm install

COPY . .

EXPOSE 3000

CMD ["npm", "start"]
```
docker build -t goals-react .
docker run --name goals-frontend -it --rm -d -p 3000:3000 goals-react

## 효율적인 컨테이너 간 통신을 위한 Docker 네트워크 추가하기
docker network create goals-net
\> port지정 대신 별도 네트워크 부여를 통한 컨테이너간 통신
docker rm $(docker ps -aq) -f

1. 데이터베이스
    - docker run --name mongodb --rm -d --network goals-net mongo
2. 백엔드
    - /backend/app.js L87   'mongodb://mongodb:27017/course-goals', 로 교체 
    - docker build -t goals-node .
    - docker run --name goals-backend -d --network goals-net goals-node
3. 프론트엔드
    - /frontend/src/app.js 모든 localhost를 goals-backend로 변경
    - docker build -t goals-react .
    - docker run --name goals-frontend -itd -p 3000:3000 --network goals-net goals-react

    - /frontend/src/app.js 모든 localhost를 goals-backend로 변경 다시 롤백 (react는 도커외부의 브라우저에서 실행되기 때문)
    - 백엔드 실행시 -p 80:80 추가 (로컬호스트의 리액트가 찾아올수있도록)


## 몽고DB 인증 오류 해결하기(다음 강의와 관련)
기존 volume의 데이터베이스에 자격증명이 남아있고, 이를 사용할 수 있으므로 기존 docker volume에 대한 삭제필요
docker volume prune (-f) > 미사용중인 docker volume 삭제

## 볼륨으로 MongoDB에 데이터 지속성 추가하기
MongoDB 컨테이너가 데이터를 저장하는 내부경로를 파악한뒤, 적절한 volume을 매핑하여 재시작하여야 한다.

- 데이터 저장 내부경로 파악
    - 우리가 만든 컨테이너 이미지가 아니기때문에, dockerhub의 설명 문서 참조
    - https://hub.docker.com/_/mongo 의 `Where to Store Data` 부분 > /data/db
- 적절한 볼륨 매핑
    - bindMount를 사용하여도 되지만 NamedVolume사용 > -v data:/data/db
- 컨테이너 재시작
    - docker stop mongodb (기존 --rm 옵션으로 인해 중지시 자동제거)
    - docker run --name mongodb -v data:/data/db --rm -d --network goals-net mongo

데이터 액세스 방지를 위한 USERNAME 및 PASSWORD 추가하기
- 컨테이너 실행시 환경변수 전달로 가능
    - https://hub.docker.com/_/mongo 의 `Environment Variables` 부분 > `MONGO_INITDB_ROOT_USERNAME`, `MONGO_INITDB_ROOT_PASSWORD`
    -  docker run --name mongodb -v data:/data/db --rm -d --network goals-net -e MONGO_INITDB_ROOT_USERNAME=max -e MONGO_INITDB_ROOT_PASSWORD=secret mongo
- 백엔드에 접근 정보 추가
    - [MongoDB Standard Connection String Format](https://www.mongodb.com/docs/manual/reference/connection-string/#standard-connection-string-format)
    - /backend/app.js L87   'mongodb://max:secret@mongodb:27017/course-goals?authSource=admin', 로 교체 
    - 이미지 재빌드후 재배포

## NodeJS 컨테이너의 볼륨, 바인딩 마운트 및 폴리싱(Polishing)
Node Backend에 대하여, log 데이터 유지 및 실시간 소스코드 업데이트 적용

1. log 데이터를 위한 명명된 볼륨 매핑
    - -v logs:/app/logs
2. 실시간 소스코드 업데이트 적용을 위한 바인드마운트
    - (아무튼 /backend 경로로 이동)
    - -v $(pwd):/app
3. 종속성 모듈들이 덮어씌워지는것 방지를 위한 익명 볼륨 사용
    - -v /app/node_modules
- docker run --name goals-backend -v logs:/app/logs -v $(pwd):/app -v /app/node_modules -d --network goals-net goals-node

소스코드 변경시, 컨테이너 내 앱 재시작을 위한 nodemon dependency 추가
- package-lock.json 삭제
- package.json 수정
    - "devDependencies": { "nodemon": "^2.0.4"}  추가
    - script 아래 "start": "nodemon app.js" 추가
- Dockerfile 수정
    - CMD npm start
아잇 또 재빌드 재배포야

DB 접근정보 하드코딩 > 입력변수로 변경
- Dockerfile에 ENV 추가
    - ENV MONGO_INITDB_ROOT_USERNAME=root
    - ENV MONGO_INITDB_ROOT_PASSWORD=secret
- /backend/app.js L87 접근정보 수정
    - `mongodb://${process.env.MONGO_INITDB_ROOT_USERNAME}:${process.env.MONGO_INITDB_ROOT_PASSWORD}@mongodb:27017/course-goals?authSource=admin`
- 재빌드 후 재배포
    - docker run --name goals-backend -v logs:/app/logs -v $(pwd):/app -v /app/node_modules -e MONGO_INITDB_ROOT_USERNAME=max -d --network goals-net goals-node

node_modules 복사방지를 위한 .dockerignore
- .dockerignore 생성 후 다음 제외할 파일명들 추가
    - node_modules
    - Dockerfile
    - .git 
재빌드재배포

## (바인드 마운트로) React 컨테이너에 대한 라이브 소스 코드 업데이트하기
React의 경우 전체 소스코드 보다는 /src 디렉토리만 바인딩하여도 충분
- /src를 /app/src에 바인드마운트
    - (/frontend/src 디렉토리 이동 후)
    - docker run -v $(pwd):/app/src --name goals-frontend -it --rm -d -p 3000:3000 goals-react

.dockerignore 추가 > node_modules 제외함으로써 중복위험성 감소 및 COPY시간 단축
- .dockerignore 생성 후 다음 제외할 파일명들 추가
    - node_modules
    - .git 

## 모듈 요약
백엔드 데이터베이스, 백엔드 API, 프론트엔드 SPA를 각 개별 스탠드얼론 컨테이너로 전환
전환된 컨테이너간 통신 가능
필요한 데이터 유지 및 라이브 소스 업데이트

주로 개발환경에 적용 가능한 이야기들
- 이미지가 아닌 라이브 소스 업데이트
- 매우 긴 docker 명령어 사용
    - 실행시 필요한 볼륨 및 환경변수 누락과 같은 휴먼에러 우려

운영배포시 고민할만한 요소들
- 복잡한 다중 컨테이너 프로젝트 배포 개선
    - 하나의 명령어로 모든 설정 실행

## 이야깃거리
### 실행중인 모든 도커 컨테이너 중지 후 삭제
- docker rm $(docker ps -aq) -f
    - docker ps -h
        - -a, --all 모든 컨테이너(중지포함)
        - -q, --quiet 컨테이너ID만 표시
    - docker rm -h
        - -f, --force 실행중인 컨테이너 강제 제거

### DNS 처리는 누가하는거지 + 어떻게 확인해볼수있지
이번주차 범위 통틀어서 IP 대신 DNS 이름을 활용해 컨테이너 접근을 쉽게하는 사례가 많이 소개되었습니다
- host.docker.internal
- 컨테이너 네트워크 연결 후 컨테이너이름

하지만 CoreDNS(쿠버네티스이야기..)처럼 어딘가에서 해당 DNS Resolving을 해주는 주체가 있을거 같은데 못찾겠네요? docker 바이너리안에 포함되어있나?
- host.docker.internal > (어딘가에서 쓱쓱싹싹해서 IP 값으로 전환) > 127.0.0.1
- mongodb(컨테이너이름) > (어딘가에서 쓱쓱싹싹해서 docker container inspect mongodb | grep IPAddress 값 ) > 172.22.0.2 

CS기본기) 일반적인 DNS 쿼리과정을 살펴보면 보통 아래 이미지처럼 요청하는 서버 외부의 DNS서버로 질의하는 과정이 나오지만
![normal-dns](https://blog.kakaocdn.net/dn/cJz4jV/btrsRPdRLQ5/7ioMsYkkxL5bNEYzuKmBRK/img.jpg "normalDNS")
![normal2](https://github.com/doku-study/doku-study/assets/102286363/ed278531-2cb3-4b37-9fe1-895f816b28e5 "normal2")

좀더 디테일하게는 서버가 외부의 DNS서버로 요청을 보내기전에 다음처럼 서버내부에서도 한번 질의를 하고 없을경우 외부로 찾으러 나가게 됩니다.

- /etc/hosts > 로컬 서버내부의 IP<>DNS 매핑
- /etc/resolv.conf > hosts에 없으면 그때 찾으러 나갈 nameserver 주소
- /etc/nsswitch.conf > 오이건 저도 처음봤어요
![local](https://miro.medium.com/v2/resize:fit:1200/1*H86CpIF8JZvdlAErnq4z_w.png "local-dns")

컨테이너 내부의 해당 파일들 조회
- docker exec -it mongodb cat /etc/hosts  
(저희가 localhost 요청했을때 127.0.0.1 되는게 이파일때문인걸로 알고있어요)
```
docker exec -it mongodb cat /etc/hosts
# 127.0.0.1       localhost
# ::1     localhost ip6-localhost ip6-loopback
# fe00::0 ip6-localnet
# ff00::0 ip6-mcastprefix
# ff02::1 ip6-allnodes
# ff02::2 ip6-allrouters
# 172.22.0.2      cc53134c3663
```

- docker exec -it mongodb cat /etc/resolv.conf  
(작성시 아마존EC2에서 작성 중)
```
docker exec -it mongodb cat /etc/resolv.conf
# search ap-northeast-2.compute.internal
# nameserver 127.0.0.11
# options timeout:2 attempts:5 ndots:0
```

- 172.22.0.2      cc53134c3663 찾아보기
- docker container inspect mongodb | grep cc53  
(hash값 입력할때 고유하기만 하면 되서 일부만 적어도 작동)
```
docker container inspect mongodb | grep cc53
        "Id": "cc53134c366397c638739fcbc40c560c847b88712e224ca0fed67a5f93d00976",
        "ResolvConfPath": "/var/lib/docker/containers/cc53134c366397c638739fcbc40c560c847b88712e224ca0fed67a5f93d00976/resolv.conf",
        "HostnamePath": "/var/lib/docker/containers/cc53134c366397c638739fcbc40c560c847b88712e224ca0fed67a5f93d00976/hostname",
        "HostsPath": "/var/lib/docker/containers/cc53134c366397c638739fcbc40c560c847b88712e224ca0fed67a5f93d00976/hosts",
        "LogPath": "/var/lib/docker/containers/cc53134c366397c638739fcbc40c560c847b88712e224ca0fed67a5f93d00976/cc53134c366397c638739fcbc40c560c847b88712e224ca0fed67a5f93d00976-json.log",
            "Hostname": "cc53134c3663",
                        "cc53134c3663"
```

- 저 resolvconf인가? 해봤더니 내부 /etc/resolv.conf랑 동일한 값이였습니다
- sudo cat /var/lib/docker/containers/cc53134c366397c638739fcbc40c560c847b88712e224ca0fed67a5f93d00976/resolv.conf
```
sudo cat /var/lib/docker/containers/cc53134c366397c638739fcbc40c560c847b88712e224ca0fed67a5f93d00976/resolv.conf 
# search ap-northeast-2.compute.internal
# nameserver 127.0.0.11
# options timeout:2 attempts:5 ndots:0
```
- 좀더 뒤적거려보겠습니다..

### React는 서버가 아닌 사용자 브라우저에서 실행이 된다.

다양한 분야의 사람들이 만난김에 연관된거있으면 각자 분야 기초/흥미거리정도 썰풀기는 어떠신가요?  

이 표현 5챕터에서 많이 등장하던데 SSR/CSR(SPA) 떠오르긴했네요. 이거 그이야기 맞죠?

https://solo5star.tistory.com/44    
모바일화면 목업으로 보여주는게 이해하기 좋았습니다


https://namu.wiki/w/Server%20Side%20Rendering   
애매할땐 나무위키

https://youtu.be/iZ9csAfU5Os?si=q89LHi7hmaASyxVY    
CSR에서 SSR까지의 흐름보기에 좋았습니다

https://youtu.be/YuqB8D6eCKE?si=NmA4qtkf68mcH7zH    
10분 테코톡 콘텐츠 좋아합니다
