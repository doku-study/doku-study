# Docker Compose: 우아한 다중 컨테이너 오케스트레이션

## 모듈 소개
DB/Backend/Frontend로 구성된 멀티컨테이너 어플리케이션 구현

문제점
1. 실행 시 긴 실행 명령어
2. 종료 시 컨테이너외의 볼륨,네트워크 등 잔여물 처리

\> Docker Compose 
- 다중 컨테이너 설정 관리 / 자동화
- 단일 명령어로 다중 컨테이너 제어

## Docker-Compose: 무엇이며 왜 사용하는가?
다수의 build/run 명령이 포함된 구성파일을 통해 컨테이너 오케스트레이션

도커 컴포즈가 할 수 없는것
- Dockerfile 
- Docker Image & Container
- 다수 호스트의 컨테이너 관리

도커 컴포즈 파일의 구성
- Service (Containers)
    - Port
    - Environment Variables
    - Volumes
    - Networks

## Compose 파일 만들기
프로젝트 폴더에 docker-compse.yaml 파일 생성    
내용 레퍼런스는 다음의 링크 참조 https://docs.docker.com/compose/compose-file/

- version > 사용하려는 docker-compose file의 버전 명시
- service > 어플리케이션에서 실행될 컨테이너들 정의, 들여쓰기 차이로 컨테이너간 구분

```docker-compose
version: '3.8'
services: 
  mongodb:
  backend:
  frontend:
```

## Compose 파일 구성(configuration) 자세히 알아보기


```docker-compose
version: '3.8'
services: 
version: '3.8'
services: 
  mongodb:
    image: 'mongo'
    volumes: 
      - data:/data/db
    environment: 
      MONGO_INITDB_ROOT_USERNAME: max
      # - MONGO_INITDB_ROOT_USERNAME=max # K:V대신 - K=V사용가능
      MONGO_INITDB_ROOT_PASSWORD: secret
    env_file: 
      - ./env/mongo.env
    # networks: # 기본적으로 service 내부의 컨테이너는 동일 network로 묶인다. 명시적으로 설정가능
    #   - goals-net 
  backend:
  frontend:

volumes:
  data: # 네임드볼륨을 생성하고, 마운트는 개별 서비스에서 설정한다

  backend:
  frontend:
```

## Docker Compose Up과 Down
docker compose up
- -d > detached 모드로 실행
docker compose down
- -v > volume 또한 제거


## 다중 컨테이너로 작업하기
backend 서비스 구성하기
```dockerfile
  backend:
    # 이미지를 수동빌드하는 단계 대체
    build: ./backend
    # 아래와같이 세부사항을 설정할수도 있음
    # build:
    #   context: ./backend
    #   dockerfile: Dockerfile
    #   args:
    #     some-arg: 1
    ports:
      - '80:80'
    volumes: 
      - logs:/app/logs
      - ./backend:/app
      - /app/node_modules
    env_file: 
      - ./env/backend.env
    # 컨테이너간 실행 우선순위를 결정
    depends_on:
      - mongodb
```

## 또다른 컨테이너 추가하기
frontend 서비스 구성하기
```dockerfile
  frontend:
    build: ./frontend
    ports: 
      - '3000:3000'
    volumes: 
      - ./frontend/src:/app/src
    # stdin_open = -i, --interactive
    stdin_open: true
    # tty = -t, --tty
    tty: true
    depends_on: 
      - backend
```
## 이미지 빌드 & 컨테이너 이름 이해하기
docker-compose up --help > 사용할 수 있는 옵션 조회하기
- docker-compose up --build > 강제리빌드
- docker-compose build > docker-compose 경로내에 커스텀 이미지 빌드경로가 있을경우


컨테이너 이름   
`디렉토리명_서비스명_숫자`로 구성됨.    
커스텀한 이름을 넣고 싶다면 개별 서비스의 하위항목에 container_name: Name 추가

## 모듈 요약
docker-compose 명령어 및 docker-compose.yaml

단일 컨테이너 프로젝트
- 볼륨,바인드마운트등 복잡한 설정부담 감소
- 긴 명령어 대신 간단한 실행구성

도커 컴포즈가 Dockerfile, docker를 대체하진 않는다    
\> docker run, docker build등 docker의 기능 중 일부를 대체함


# “유틸리티 컨테이너”로 작업하기 & 컨테이너에서 명령 실행하기

## 모듈 소개 & "유틸리티 컨테이너"란 무엇인가?
`유틸리티 컨테이너` > 공식 용어는 아님    

지금까지 했던것은 일종의 `어플리케이션 컨테이너`
- 컨테이너에 코드와 런타임 포함
- 컨테이너 혼자/다른 컨테이너와 통신하며 작동함

`유틸리티 컨테이너`
- NodeJS나 PHP와 같은 특정 환경 구성
- 어플리케이션 구동이 아닌 특정 작업실행

## 유틸리티 컨테이너: 왜 사용하는가?
지금까지)
- 완성된 소스코드와(*.js), 종속성(package.json)이 같이 제공되었음
- 그러나 정말 개발을 한다면, 개발 도구를 설치하고(nodeJS설치), 개발 환경을 구성해야한다(npm init>package.json)
- 그러기 위해서 초기 개발시에는 이것저것 다양한 도구를 설치해야한다
- <> 이는 호스트 머신에 도구를 설치하지 않는다는 도커 아이디어와 상충

이번강의)
- 어플리케이션 도구를 직접설치하지 않고, 앱 환경이 포함된 컨테이너를 사용하는 방법

## 컨테이너에서 명령을 실행하는 다양한 방법
- docker run -it -d node
  - 입력대기중인 detach 모드로 node 컨테이너 실행

- docker exec
  - 컨테이너의 기본 명령외의 특정 명령어 실행 가능
- docker exec -it [containerName] [Command]
  - docker exec -it intelligent_mirzakhani npm init
  - 실행 중인 컨테이너 내에서 작업하는 방법
- docker run -it [ImageName] [Command]
  - docker run -it node npm init
  - 컨테이너의 기본 실행명령어를, npm init 으로 오버라이드하였음


## 첫 번째 유틸리티 컨테이너 구축
유틸리티 컨테이너 생성을 위한 Dockerfile
```dockerfile
FROM node:14-alpine

WORKDIR /app
```
유연성을 위해 추가설정을 하지않고 빌드함  
- docker build -t node-util .
- docker run -it node-util npm init

컨테이너에서 내부(/app)에서 실행되는 결과를 미러링하기위해 호스트와 연결
- docker run -it -v $(pwd):/app node-util npm init
- 생성이 완료되고, 현재 경로에 package.json 생성됨 

## ENTRYPOINT 활용
???
- docker run -it -v $(pwd):/app node-util npm init
```
0:50~1:10
즉, 이것으로 우리 자신을 보호하기 위해
모든 것을 할 수 없도록 더 제한된
유틸리티 컨테이너를 갖게 됩니다.
컨테이너에서 실수로 모든 것을 삭제하는 명령을 실행하여
바인드 마운트로 인해 호스트 머신에서도 콘텐츠를 삭제하는 경우를
이것으로 방지할 수 있습니다.
So that we have a more restricted utility container
where we can't do everything.
Also to protect ourselves,
so that I don't accidentally run some command
in the container, which deletes everything. 
And then because of the bind mount,
it starts deleting content on my host machine as well.
So for this reason, as well, it might be interesting
to restrict the commands we can run.
```
이말이 무슨말인지 잘 이해가 안가네요.     
바인드 마운트되어있어서 컨테이너내에서 삭제하는 명령어를 내리면, 호스트머신에서도 지워지는데..?   
계속 컨테이너와 연결된 상태가 아니라 주어진 명령어만 실행하고 바로 종료되어 별도오작동을 막는다는 의미?   

ENTRYPOINT
- CMD와 유사하게 컨테이너 기동시 실행될 명렁어를 정의
  - CMD의 경우 docker run 뒤의 전달되는 명령어로 오버라이드됨
  - ENTRYPOINT의 경우 docker run 뒤의 전달되는 명령어가 ENTRYPOINT 뒤에 추가됨

```dockerfile
FROM node:14-alpine

WORKDIR /app

ENTRYPOINT [ "npm" ]
``` 
- docker build -t mynpm .
- docker run -it -v $(pwd):/app mynpm init
  - init만 전달하여도 ENTRYPOINT에 따라서 컨테이너 내부에선 npm init으로 실행 
- docker run -it -v $(pwd):/app mynpm install express --save
  - express 패키지 설치 > 호스트머신에도 종속성파일 미러링

## Docker Compose 사용
그사이 또 명령어가 길어졌기때문에, 간단히 사용하기위해 docker compose 적용
```YAML
version: '3.8'
services: 
  npm:
    build: ./
    stdin_open: true
    tty: true
    volumes:
      - ./:/app
```
- docker-compose up init
  - 제대로 작동하지 않음
  - docker-compose up은 서비스 실행을 위한것
  - 명령어 실행을 위해서는 docker-compose exec 또는 docker-compose run이 있다
- docker-compose run --rm npm init
  - --rm 플래그를 추가하여 작업 종료된 컨테이너가 제거되도록 설정 가능

## 모듈 요약
- 유틸리티 컨테이너
  - 특정 어플리케이션 구동 대신, 특정 명렁어를 실행하는 환경 제공
  - docker run 또는 docker-compose run을 통해 사용 가능
  - 이후 PHP Framework인 Laravel 프로젝트 소개
    - 개발환경 설정을 위해서 얼마나 많은 도구의 구성이 필요한지
    - 도커를 통해 얼마나 간편히 구성할 수 있는지

## 이야깃거리
몇가지 유용한 도커컴포즈 커맨드들
- docker-compose -f [파일명] up
  - 주어진 파일명의 docker-compose.yaml 실행
  - 작업하다보면 얘도 도커컴포즈 쟤도 도커컴포즈라서 헷깔립니다. 아니면 같은 디렉토리에서 다른 환경의 컴포즈를 실행하고싶을수도있구요.
  - 위의 명령어로 가능합니다. 순서 중요) docker-compose --help 해야 보이고, docker-compose up -f [파일명]은 작동하지 않습니다
- docker-compose ps
  - docker-compose 로 실행된 컨테이너들 상황 보기

Docker Compose를 통한 패키지 설치 및 운영
- 일반적으로 리눅스나 맥에서 패키지설치할때는 yum/apt/brew처럼 바이너리를 직접받고 구성하기도하지만
- 요즘 오픈소스 프로젝트들 설치 옵션으로 도커(컴포즈)도 제공하기도 합니다
  - 데이터 시각화툴 Redash https://redash.io/help/open-source/setup#-Docker
  - 데이터 파이프라인툴 Airflow https://airflow.apache.org/docs/apache-airflow/stable/howto/docker-compose/index.html#fetching-docker-compose-yaml
  - git 레포지토리 플랫폼 GitLab https://docs.gitlab.com/ee/install/docker.html#install-gitlab-using-docker-compose

혹시 YAML에 친숙하신가요? 아니라면 JSON은요? 편하게 다루시는 데이터세트?가 있나요? CSV?
  - https://youtu.be/55FrHTNjTCc?si=W_6kQrH2ST-ySgfn
  - https://onlineyamltools.com/convert-yaml-to-json
  - https://onlineyamltools.com/convert-yaml-to-csv

docker 면접질문 같은거 찾아보다보면 CMD <> ENTRYPOINT 차이 묻는질문 자주등장하더라구요
- 둘다 컨테이너 실행시 명령어를 정의하는 구문인데 무슨 차이가 있나요?
  - 실행시 전달되는 값에 대해 CMD는 오버라이드되고 ENTRYPOINT는 되지않음
- 왜 그런가요? 당해보신적있나요? 언제 CMD를 쓰고 언제 ENTRYPOINT를 써야할까요?
  - ?

유틸리티 컨테이너하니까 떠올랐는데, Node에는 가상화도구?모듈은 없나요?
- python의 경우 venv 모듈로 별도 가상환경을 구축할수 있는데 이 가상화는 컨테이너가상화와 다른건가싶네요

