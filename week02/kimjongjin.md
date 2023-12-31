# Docker 이미지 & 컨테이너: 코어 빌딩 블록

## 모듈 소개

## 이미지 & 컨테이너: 무엇이며, 왜 사용하는가?
- 이미지: 컨테이너 생성의 청사진
- 컨테이너: 실제로 실행된 어플리케이션 환경

- 마치 코딩에서의 함수/클래스와 같이, 앱 환경을 이미지로 정의하고, 실행된 앱 인스턴스를 컨테이너로 분리함

## 외부(사전 빌드된) 이미지의 사용 & 실행
1. 이미 존재하는 사전 이미지 활용
    - DockerHub와 같은 이미지 레지스트리 활용
    - `docker run node`
        - Node 이미지 다운로드 후 컨테이너로 실행
    - `docker ps -a`
        - 도커가 실행한 모든 컨테이너 조회
        - 별도의 명령어를 넣어주지않았기 때문에 바로 종료되었음을 확인
    - `docker run node -it`
        - -i, --interactive                    Keep STDIN open even if not attached
        - -t, --tty                            Allocate a pseudo-TTY
        - 노드 컨테이너로 진입해 쉘 명령어 사용가능
        - 로컬 호스트와는 다른 환경

## 우리의 목표: NodeJS 앱
- 다른 이미지(Node)에 기반한 자체 이미지 빌드
    - server.js / package.json / public이 있는 소스코드 활용

## Dockerfile을 사용하여 자체 이미지 빌드하기
- Dockerfile
    - FROM node: 다른 베이스 이미지 불러오기\
    - WORKDIR /app : 컨테이너 내부의 작업경로를 /app 로 전환
    - COPY . /app
        - 앞의 . : 컨테이너 외부의, dockerfile이 위치한 경로
        - 뒤의 /app : 컨테이너 내부의, 작업경로 
    - RUN npm install: 명령어 실행
    - EXPOSE 80: 컨테이너 환경을 포트 80에 노출, 필수X 참조용
    - CMD ["node", "server.js"] : 컨테이너 시작 시 실행

## 자체 이미지를 기반으로 컨테이너 실행하기
- `docker buiild .`
- `docker run [생성된 이미지ID]`
- `docker run [생성된 이미지ID] -p 3000:80`
    - dockerfile에서의 EXPOSE 설정은 참고용
    - 실제로 컨테이너 접근을 위해선 실행시 -p 옵션을 사용한 포트매핑을 해주어야함.

## 이미지는 읽기 전용!
- 이미지는 생성시의 소스코드를 가지고 빌드됨
- 그 이후에 소스코드 변경시 재반영X > 재빌드, 재배포 필요

## 이미지 레이어 이해하기
- 이미지는 레이어기반으로 작동
    - 이미지 빌드/재빌드 시 모든 사항이 재시작되지않음
    - 단계별로 cache되어 변경이 있을때만 재작업됨

- 이미지 레이어 최적화
    - `RUN npm install` 시 package.json이 동일하여도 앞의 레이어의 변경이 있으면 뒤의 레이어도 재실행
    - 변경이 잦을 COPY 앞에, 상대적으로 변경이 적을 RUN을 배치함으로써 캐시 효율적 사용가능
        - COPY package.json /app
        - RUN npm install
        - COPY . /app 

## 첫 번째 요약
- Docker image (Dockerfile)
    - 어떤 이미지를 기반으로 실행할 지
    - 어떤 코드와 종속성을 추가할지
    - 어떤 명령어를 실행할 지 정의
- Docker container (인스턴스)
    - 생성된 이미지 기반으로 생성가능한 컨테이너들
    - 각자 개별적으로 동작함
- 이미지와 컨테이너 모두 개별적으로 동작함
    - 변경 필요시 재빌드,재배포 필요

## 이미지 & 컨테이너 관리
- 명령어에 --help를 사용하여 사용가능한 옵션 확인 가능
- tag를 통해 관리하기
- 이미지/컨테이너 조회, 분석, 중지, 재시작 삭제  등

## 컨테이너 중지 & 재시작
- `docker start [containerID]`: 중지된 컨테이너 시작

## Attached & Detached컨테이너 이해하기
- `docker run`으로 실행시 컨테이너는 foreground에서 작동하며, 터미널 사용불가 (attached)
- `docker start`로 실행시 컨테이너는 backgorund에서 작동하며, 터미널 사용가능 (detached)
- attahced 모드에서는 컨테이너 출력을 확인 가능 / detached 모드로 단순 실행 가능

- `docker run`으로 detached 모드를 사용하고싶다면, -d 옵션을 줌으로써 가능
- `docker start`으로 attache 모드를 사용하고싶다면, -a 옵션을 줌으로써 가능

- 컨테이너 출력을 재확인하고 싶을 시
    - `docker attach [containerID]`
    - `docker logs [containerID]` / -f 옵션으로 following 가능

## 인터렉티브 모드로 들어가기
기존에 사용하던 웹서버 Node 대신 로컬 python app 활용 예시
- python dockerfile
    - FROM python
    - WORKDIR /app
    - COPY . /app
    - CMD ["python", "rng.py"]

- docker run으로 attach 모드로 실행되어도 상호작용은 할 수 없다.
    - attach되어 출력을 받을 순 있지만 입력을 전달할 수는 없음
    - -it 옵션을 통해 인터랙티브 쉘을 붙이는것이 가능
        - `docker run -it `
        - `docekr start -a -i` 최초 docker run 시 -t 옵션이 들어갔기때문에 없어서 수행가능

## 이미지 & 컨테이너 삭제하기
- `docker rm [containerID]` 컨테이너 삭제,중지된 컨테이너만 가능
- `docker stop [containerID]` 컨테이너 중지
- `docker rmi [iamgeId]` 이미지 삭제, 관련 컨테이너가 생성되어있으면 불가

- `docker image prune` 미사용 이미지 삭제

## 중지된 컨테이너 자동 제거하기
- `docker run --rm` 컨테이너 종료시 자동 제거 

## 작동 배경 살펴보기: 이미지 검사
- `docker inspect [imageID]` 이미지 레이어 검사, 이미지 구성, 레이어, 캐싱정보 확인 가능

## 컨테이너에/컨테이너로 부터 파일 복사하기
- `docker cp [source] [dest]` source 경로에서 dest 경로로 복사/가져오기
- 해당 방식으로 소스코드 변경시 이미지 빌드를 하지않고 컨테이너를 변경할 수 있음
    - 당연히 비권장

## 컨테이너와 이미지에 이름 지정 & 태그 지정하기
- `docker run --name [name]` 무작위 ContainerID대신 지정한 name으로 컨테이너 제어 가능
- `docker build -t [name]:[tag] .` 이미지 빌드시 특정 tag 부여 가능
- `docker run -p 3000:80 -d --rm --name [name] [name]:[tag]` >  무작위 imageID와 ContainerID대신 이름과 태그기반 제어가능

## 이미지 공유하기 – 개요
- dockerfile과 소스코드 공유 > 이미지 빌드 후 사용
- 빌드된 전체 이미지 공유 > 이미지 다운로드 후 사용 (일반적 사용예시)

## DockerHub에 이미지 푸시(push)하기
- dockerhub에서, 개인 repository 생성 
- dockerId/repoName 태그를 부여한 이미지 빌드
- `docker login`으로 계정 연동
- `docker push`로 개인 repo에 docker image 전달 

## 공유 이미지 가져오기(pull) & 사용하기
- `docker pull dockerId/repoName`
- public repo이기에 모든 사람이 pulling 가능

## 모듈 요약
- Docker는 Image와 Container 로 구성
    - Image: 컨테이너 정보
    - Contaner: 이미지를 통해 실행된 객체
    - 이미지와 컨테이너가 분리됨으로써 구성과 실행을 분리하였음

- Image
    - Dockerfile을 통해 빌드 / 완성된 Image를 Dockerhub등에서 다운로드
        - dockerfile 
            - 일반적으로 FROM, COPY, RUN, CMD 등의 인자가 포함된 구조
            - 각 단계별 레이어가 구성되고, 캐시되어 재빌드시 속도 최적화
        - 또는 docker pull을 통해 빌드된 이미지 다운로드 가능
    - tagging
        - 빌드시 `-t [name]:[tag]` 옵션을 통해 버전정보 포함 가능

- Container
    - 컨테이너 실행,중지 및 삭제등 관리에 관한 다양한 명령어들
        - run, start, ps, stop, cp, logs, etc..
        - attached/detached > 터미널 foreground 실행/background 실행
        - -p [host]:[container] > 호스트의 포트와 컨테이너의 포트 매핑
