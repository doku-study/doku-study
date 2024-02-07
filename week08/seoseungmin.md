
## 다중 컨테이너

- docker-compose를 ECS에서 실행시키면 어떻게 될까?
- 배포할 땐 docker-compose가 마냥 좋지는 않다고 함
    - 클라우드 상에선 여러 대 머신이 작동함. 여러 머신에 대한 리소스를 잘 할당해야함
- ECS 환경에선 컨테이너 IP를 네이밍해서 사용할 수 없음
    - 동일한 태스크에 컨테이너 추가하면 localhost를 대신 사용할 수 있음
- 근데 이러면 로컬에선 도커 네트워크용 네이밍 사용하고, 배포 환경에선 localhost 쓰는 차이가 생김
    - 환경 변수로 해결 가능
    - env는 로컬, 배포 환경 달라도 되니까? 뭔가 이상한데..

## 백엔드 내 Dockerfile 이미지 빌드 후 도커 허브 푸시

- 백엔드 app.js에서 `mongodb`를 `${process.env.MONGODB_URL}`로 변경
- backend.env에 `MONGODB_URL=mongodb` 추가
- `docker build -t goals-node ./backend`

- 도커 허브에 goals-node라는 레포 생성
- 로컬 이미지에 위에서 생성한 레포 이름을 태그로 달아줌
    - `docker tag goals-node baoro9394/goals-node`
- push 하기 전 `docker login`
- `docker push baoro9394/goals-node`

## 푸시한 백엔드 이미지를 ECS에서 실행

- 클러스터 생성.
- 태스크 생성
    - 이름: goal
    - 태스크 크기: 가장 작은 것
    - 태스크 역할: ecsTaskExecutionRole
    - 컨테이너 정의: goals-node, 허브 레포, 80 포트
    - 환경 변수에서 `command`와 `node, app.js` 추가하는건 어떻게..?
    - 앞에서 설정한 mongodb_url 환경변수 관련 작업 필요
        - backend/Dockerfile에 `ENV MONGODB_URL=mongodb` 추가 (Dockerfile이 컨테이너 내부 코드에서 사용되는 모든 환경 변수 다루도록 설정)
        - 이미지 리빌드 `docker build -t goals-node ./backend`
        - 태그도 다시 지정 `docker tag goals-node baoro9394/goals-node`
        - 허브에 푸시 `docker push baoro9394/goals-node`
    - 환경 변수 아래 추가
        - MONGODB_USERNAME=root
        - MONGODB_PASSWORD=secret
        - MONGODB_URL=localhost

## 이제 몽고디비 컨테이너 추가

- 태스크 정의에 또다른 컨테이너 추가하기만 하면 됨
    - 컨테이너 정의에서 mongodb 공식 이미지 입력
    - 환경 변수에선 mongo.env에 있는 값 추가
- 몽고디비의 볼륨은? 일단 넘어가는데 스토리지 로깅 부분에서 다루는 것 같음


결국 docker-compose를 녹여서 ECS의 태스크 정의에 잘 붙이는 작업

뭔가 더 효과적으로 할 수 있는 방법 없을까? AWS ECR? 이건 그냥 도커 허브 같은건가..

## 서비스 생성

- goal 태스트 정의를 패밀리로 선택
    - 이름: goals-service
- 네트워킹 탭은 그대로 두면 될듯
- 로드밸런서 탭에선 Application Load Balancer 선택
    - 이름만 ecs-lb 로 두고 나머진 그대로.
- 서비스 생성
- 서비스 - 태스크 들어가면 퍼블릭 IP 확인 주소 가능
- postman으로 해당 IP주소 + /goals 에 요청 보내서 응답값 확인 가능

여기서부터 비용 너무 나가서 중단함...ㅠ

## 로드 밸런서

- 퍼블릭 IP 주소는 업데이트된 컨테이너 배포할 때마다 변경됨
- EC2의 로드밸런서에서 DNS name 조회하면 이 고정된 URL로 접속 가능함


## EFS 볼륨

- 코드에서 무언가 변경하고 배포하는 경우
    - AWS ECS의 서비스 탭에서 업데이트된 이미지로 배포, 업데이트 할 수 있긴함
    - 이 경우 컨테이너 종료되고, DB에 쌓던 것도 날라갈 위험 있음
- 로컬에선 볼륨, ECS에선 태스크 정의 - 볼륨 탭에서 설정 가능
    - `data` & 볼륨 유형은 EFS (Elastic File System)
    - EFS: 서버리스 컨테이너에 파일 시스템 연결시키는 솔루션
- EFS 솔루션 접속
    - 이름 섲렁
    - VPC 동일하게 설정 (?)
    - network access에서 보안 그룹 설정 필요
- EFS로 볼륨 만들었으면 이제 컨테이너에 이 볼륨 연결해야 함
- mongodb 컨테이너 들어가서 config에 들어가 스토리지 & 로깅 들어감
    - mount point에서 아까 설정한 volume 지정
- 뭐 이것저것 건드리면 ECS에서도 볼륨 설정할 수 있음


## DB용 컨테이너에 대해

- 단점
    - scaling & managing이 어려움 (동기화 이슈)
    - 트래픽 급증하면 퍼포먼스 이슈
    - 백업, 보안  이슈
- 로컬에선 트래픽, 백업 등 고려할 필요 없었음. 프로덕션에선 이런 문제를 필연적으로 고민해야 함
- managed Database service (AWS RDS, MongoDB Atlas 등)으로 전환하는걸 고려할 수 있음
- 이후엔 Atlas 사용하는 방법에 대해


## Atlas

- 클라우드 환경에서 mongodb 데이터베이스 제공하는 프로그램 (free tier로 진행)
- 데이터베이스 생성하면 연결할 수 있는 연결 정보 확인해서 스크립트에 입력하면 됨
- 개발 중엔 mongodb 컨테이너, 프로덕션에선 mongodb atlas 사용하는 방법을 권장함
- 다음은 atlas 사용하면 기존의 코드에선 어떤거 들어내야 할지에 대해 
- 나중에 atlas 사용할 일이 있으면 그 때 다시 보는걸로.. 너무 복잡 ㅠ


## 프론트엔드 추가

- 아키텍처에 React SPA가 뱔도 컨테이너로 추가된 형태
- 개발 환경과 프로덕션 환경 각각 따로 다뤄줘야 함
- 프로덕션 환경에선 빌드 전용 컨테이너가 필요함
    - `Dockerfile.prod` 추가
    - 프로덕션 환경에서 이 컨테이너를 사용하려면 이걸 제공하는 서버가 필요 -> 멀티 스테이지 빌드로 해결 가능


## 멀티 스테이지 빌드

- 하나의 dockerfile에 stage라고 하는 여러 빌드 단계를 설정할 수 있음
- `RUN npm run build`까지가 첫번째 스테이지. 여기까지하면 소스코드 완성
    - 멀티 스테이지 빌드에선 CMD 대신 RUN 사용
- 이 명령 후 다른 베이스 이미지로 전환

- 멀티 스테이지 빌드와 docker-compose는 어떻게 다를까?
    - 컨테이너 하나 vs 컨테이너 여러개.
    - 1 컨테이너 1 이미지일 필요가 없다는건가? 그건 아님. 한 컨테이너에서 이미지가 전환되는 것

- 두번째 베이스 이미지 단계에선 `COPY --from`으로 이전 스테이지를 복사할 수 있음
- 포트 80을 노출. nginx가 내부적으로 노출하는 기본 포트.

- docker-compose로 했던걸 멀티 스테이지 빌드로 대체할 수 있을까?
    - 전환이 끝난 스테이지에 대해서는 사후(?) 관리가 안됨. 관리가 필요한 경우 docker-compose를 사용해야 함
    - 완벽히 대체되는건 아니고 보완 관계

- --target 으로 일부 스테이지만 빌드할 수 있다고 함

## 멀티 스테이지 이미지 구축

- frontend/src/app.js에 localhost로 요청 보내고 있음. 다만 프론트 코드는 브라우저에서 실행되는 것.
    - 여기서 localhost라면 결국 클라이언트 머신을 참조하게 됨 (배포 환경에서)
- `localhost` 부분을 그냥 지움
- 프론트 폴더의 `Dockerfile.prod`를 빌드하고 푸시함


## 프론트 쪽 ECS 작업

- 태스크 정의에서 컨테이너 추가
- 다만 백엔드와 프론트를 하나의 컨테이너에 통합
- 동일한 ECS 태스크에서 백, 프론트를 모두 호스팅하는 방법은 없음
    - 결국 태스크 분리는 필요함
- 태스크가 분리되면서 url이 분리됨. 백과 프론트의 Url을 이어주는 코드 작업 필요

## dev VS prod

- 개발과 프로덕션 환경에서 다른 dockerfile을 사용해야 할 때가 있음
- 코드 상에서의 차이일 뿐 docker의 기본 정신(?)을 해치는건 아니라고 함


## 느낀 점

- 프로덕션 환경을 클라우드에 구축하는건 생각보다 훨씬 복잡한 것 같다
    - docker-compose가 만능이라 생각했는데, 프로덕션 환경에서 갖는 여러 단점을 접하니 마냥 만능은 아니라는 생각
    - 멀티 스테이지 빌드라는 기능은 docker-compose와 비슷하지만 또 다른, 명확한 목적을 가지고 있고..
- 개발과 배포는 단순히 기술적인 의미를 넘어선 가치가 있는 것 같음.
    - 개발과 배포는 100명의 카페 종업원이 동시에 10,000명의 손님을 대하는 것과 비슷한 것 같음
    - 그만큼 수많은 상황를 커버하는 무언가가 필요했을 것. 모든 기능이 다 어떤 실패에서 생겨난 것이라고 본다면 정말 많은 고민과 선택의 흔적이 느껴짐
    - devops 많이 하다보면 나름의 인생 철학이 생길 것 같다. 나중에 강의 같은거라도 찾아보기로.


