# 데이터 관리 및 볼륨으로 작업하기

## 모듈 소개
- 지금까지는 이미지/컨테이너 내 소스코드라는 데이터만 다루었음
- 그외에 다양한 방식으로, 다양한 데이터를 관리하는 방법
    - 다른 디렉토리와의 연결
    - 인수 및 환경변수 등

## 데이터 카테고리/다양한 종류의 데이터 이해하기
- 어플리케이션(코드+종속성) > 이미지에 복사되며 고정됨 (R/O)
- 그 외 두 종류의 데이터
    1. 임시 데이터, 실행중 임시 저장된 데이터 ex) 사용자 입력값
        - 이미지 위의 컨테이너 추가 레이어에서 작동함 > 컨테이너에 저장되며 휘발성있음 (R/W)
    2. 영구 데이터, 실행중 파일/DB에 영구 저장된 데이터 ex) 사용자 계정
        - 컨테이너의 작동 상태와 별개로 영속성이 필요함 > Volume에 영구 저장 (R/W)

## 실제 앱 분석하기
- Web form application (server.js,/pages,feedback.html)
    - 임시 생성 데이터 (/temp)
    - 영구 저장 데이터 (/feedback)

## 데모 앱 구축 & 이해하기
```
FROM node:14

WORKDIR /app

COPY package.json .

RUN npm install

COPY . .

EXPOSE 80

CMD [ "node", "server.js" ]

# docker build -t feedback-node .
# docker run -p 3000:80 -d --name feedback-app --rm feedback-node
```
소스코드를 빌드하고 실행하여 폼을 작성하여도 실제 호스트머신에는 데이터가 남지않음 확인
컨테이너 실행중에만 존재하며, 정지시 삭제됨

## 문제 이해하기
이미지(R/O)를 기반으로 컨테이너 실행시, R/W인 파일시스템 레이어가 추가됨
따라서 컨테이너 작동중에는 (중지되어도!) 유지되나, 삭제시 같이 제거됨 

그러나 특정 데이터는 제거되면 안됨. 사용자 계정, 또는 제출데이터(좀더 다듬자면 신규회원,구매내역)

## 볼륨 소개
볼륨은 이미지/컨테이너와 별개로 호스트에 존재하는 파일시스템
호스트에 별개로 존재하기때문에 컨테이너의 상태와 별개로 영구적 데이터 저장이 가능함

## 첫 번째, 실패한 시도
dockerfile에 `VOLUME` 으로 경로 특정하기
VOLUME ["/app/feedback"] 을 추가하여 feedback 데이터를 저장할 컨테이너 내부 볼륨 지정

그러나 UnhandledPromiseRejectionWarining 발생
```
(node:1) UnhandledPromiseRejectionWarning: Unhandled promise rejection. This error originated either by throwing inside of an async function without a catch block, or by rejecting a promise which was not handled with .catch(). To terminate the node process on unhandled promise rejection, use the CLI flag `--unhandled-rejections=strict` (see https://nodejs.org/api/cli.html#cli_unhandled_rejections_mode). (rejection id: 1)
```
?아무튼 무언가의 node 문제발생 > 소스코드 재빌드 후 재배포 > 삭제후 재시작 > 여전히 데이터가 남아있지 않음

## 명명된(named) 볼륨으로 구조하기!
외부 데이터 저장소의 2가지 방식 (2 Types of External Data Storages)
1. Volumes (Managed by Docker)
    - Anonymous Volume: docker volume ls 로 조회가능, 컨테이너 생성시 docker에 의해 자체생성/자체삭제
    - Named Volume: dockerfile 대신 실행시 -v 옵션으로 전달, `-v volumeName:containerPath`, -v feedback:/app/feedback
2. Bind Mounts (Managed by user)
    - 후술

## 바인드 마운트 시작하기(코드 공유)
- volume의 경우 실제 호스트머신의 fs상 위치가 어디인지 알지 못하지만 bindMount의 경우에는 호스트머신의 경로와 컨테이너 내부의 경로를 매핑함
- 호스트의 경로를 완벽히 인지하기에, 소스코드를 넣어서 매번 재빌드/재배포 없이 앱 수정이 가능함
    - docker run시 `-v hostPath:containerPath` 로 지정
    - docker에서 resources-file sharing 옵션 확인

## 다른 볼륨 결합 & 병합하기
`-v volumeName:containerPath` 또는 `-v hostPath:containerPath` 을 사용하여 docker volume 또는 bindMount를 런타임에서 전달가능


그러나 bindMount시 호스트의 fs가 컨테이너내부를 덮어씌워 종속성이 제거되는등의 에러발생
`-v containerPath`로 익명볼륨을 생성하여 보완가능

- 볼륨간 충돌시 더 긴 '컨테이너 내부 경로`를 우선시함
    - -v feedback:/app/feedback -v "~:/app" -v /app/node_modules
    - 내부경로가 긴 /app/node_modules 익명 볼륨이 먼저 마운트되고
    - 그뒤 네임드 볼륨
    - 마지막으로 bindMount가 매핑

## NodeJS 특화 조정: 컨테이너에서 Nodemon 사용하기
소스코드와 실행된 노드 런타임은 별개의 문제임.
소스코드 변경이 업데이트 되었을때 런타임이 갱신되어야하는 경우도 있음

nodemon 종속성을 추가시 파일시스템 변경시마다 노드서버 재시작 -- 

## 볼륨 & 바인딩 마운트: 요약

1. docker run -v containerPath
    - docker run -v /app/data ...
    - Anonymous Volume 생성; 컨테이너 삭제 시 같이 제거
    - R/W 레이어의 데이터 중 일부를 호스트머신의 fs에 아웃소싱 (RAM 부하절감/DISK부하상승?)
2. docker run -v volumeName:containerPath
    - docker run -v data:/app/data ...
    - Named Volume 생성; 컨테이너 종료 시 남아있음
    - 재마운트, 여러 컨테이너에 단일 볼륨마운트 및 데이터 공유 등 가능
3. docker run -v hostPath:containerPath
    - docker run -v /path/to/code:/app/code ...
    - bindMounts 생성; host 파일시스템에 남아있음
    - 도커 명령어의 제어범위 외부


## 읽기 전용 볼륨 살펴보기
bindMount의 경우, 컨테이너가 외부의 호스트fs에 대한 변경을 원하지 않을시 R/O를 설정할 수 있음
설정시 docker run -v hostPath:containerPath:ro 로 읽기모드 설정
-v feedback:/app/feedback -v "~:/app:ro" -v /app/node_modules


또한 하위 볼륨(=경로가 긴)이 상위 볼륨(=경로가 짧은)보다 우선권을 갖기때문에, /app/feedback 또한 RW상태
/app/temp 또한 RW로 사용하기 위해 -v /app/temp 추가

> 결론적으로 소스코드와 관련된 /app 내부의 /public, package.json, server.js등이 RO <> 작동에 관련된 /feedback, /temp 등은 RW로 작동함

## Docker 볼륨 관리하기
`docker volume ls` - 생성된 docker volume 조회
docker run ~ - 컨테이너 실행시 익명 볼륨 조회
bindMount - 도커 상에서 확인 불가능

`docker volume create` - docker volume 생성
`docker volume inspect` - docker volume 조사 (생성일, 마운트포인트, 등)
`docker volume rm [volumeName]` - docker volume 삭제
`docker volume prune` - 미사용 중인 모든 docker volume 제거

## "COPY" 사용 vs 바인드 마운트 사용
엄밀히 말하면 dockerfile의 COPY 블럭을 bindMounts로 대체가능
그러나 이는 외부서버환경 실행시 이미지 외에도 소스코드가 동시에 있어야하는 종속성 생성

따라서 운영환경등 새로운서버에 배포시 COPY 블럭을 통해 코드의 스냅샷을 전달하는편이 권장된다.

## 모든 것을 복사하진 마세요: "dockerignore" 파일 사용하기
.gitignore와 같이, .dockerignore에 정의된 파일들은 COPY시 전달되지 않음
버전차이가 있을 수 있는 로컬의 종속성파일등 전달 배제

## 환경 변수 & \".env\" 파일 작업
- ARGuments
    - dockerfile에서 사용가능, app code에서는 사용 불가
    - docker build시 --build-arg 옵션으로 인자값 전달 가능
- ENVironment
    - dockerfile 및 app code에서 사용가능 
    - docker build시 ENV 블럭 또는 
    - docker run 시 --env/-e 또는 --env-file ./.env로 환경 변수 전달 가능


## 빌드 인수(ARG) 사용하기
dockerfile에 값을 하드코딩 하지않아도, 빌드 시 전달할 수 있음. ex)포트 번호
```
#dockfile
ARG DEFAULT_PORT=80
ENV PORT $DEFAULT_PORT
```

docker build -t feedback-node:dev --build-arg DEFAULT_PORT=8000 .

\+ 지난 강의의 layer 캐싱 최적화와 같이, 변경이 없을 부분 (COPY,RUN, ... )을 dockerfile 상단에 배치하고, 변경이 있을 ARG/ENV 블럭을 하단에 배치하면 빌드시간 단축이 가능하다
 
## 모듈 요약
- 컨테이너 실행시 이미지(R/O)위에 임시 파일시스템 레이어(R/W)가 얹혀져서 동작함
    - 임시 레이어이기 때문에 컨테이너 생애주기와 같은 생애주기를 가짐 > 삭제되면 같이 삭제됨
- 앱에서 일부데이터는 영속성이 필요하기 때문에 Volume 또는 bindMount를 활용할 수 있다
    - Managed by docker 
        - Anonymous Volume, `docker run -v containerPath`, 컨테이너랑 같은 생애주기
        - Named Volume, `docker run -v volumeName:containerPath`, 컨테이너와 별도의 생애주기
    - Managed by user
        - Bind Mounts, `docker run -v hostPath:containerPath`, 호스트와 연결된 파일시스템 마운트
- 볼륨 관리
    - 한 컨테이너의 다수 볼륨이 마운트 된 경우 내부 경로가 긴 볼륨이 우선권을 갖는다
    - -v의 경로 뒤에 :ro 등을 통해 볼륨의 읽기모드를 변경할 수 있다
    - docker volume ls, create, inspect, remove, prune 등의 명령어들
- 변수 관리
    - 인자(ARG) 및 환경변수(ENV)
        - 인자는 build시 활용
        - 환경변수는 build 및 run 시 활용 

## 이야깃거리
추후 업데이트 예정