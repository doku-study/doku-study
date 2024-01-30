# Docker 컨테이너 배포하기

## 모듈 소개
로컬호스트 대신, 리모트 머신에서 컨테이너 실행 실습     

중점사항: 웹 앱 배포
- 배포 프로세스 일반적인 내용
- 일반적인 문제점과 필요한 변경 사항
- 단일 및 다중 컨테이너 앱 배포

## 개발(Development)에서 제품 생산(Production)까지

컨테이너는 앱 코드와 환경을 패키징한, 독립적이고 격리된 패키지       
- 지금까지는 도커 컨테이너의 개발적인 측면에 집중하였음
- 환경이 구성되지않은 리모트 머신에서 도커 컨테이너를 배포하기
  - 바인드마운트 활용 X
  - 빌드 단계의 필요성
  - 컨테이너를 다중 리모트 머신에 걸쳐 분할배포

## 배포 프로세스 & 프로바이더

단일 NodeJS앱 배포하기
- 리모트 서버 생성
- SSH 연결
- 호스트 머신에서 Docker registry로 docker image push(Upload)
- 리모트 머신에서 Docker image pull
- 컨테이너 이미지 실행 및 퍼블릭 웹 노출 

Docker hosting provider
- 여러 호스팅 업체가 있지만 메이저는 AWS, Azure, GCP
- 호스팅이라고 말하는것도 살짝 올드한 느낌이.. 요오즘것들은 클라우드회사라고 할텐데

## 예제로 시작하기

AWS EC2를 사용한 배포 과정
1. AWS EC2 인스턴스 생성(+네트워크환경,VPC,등) 
2. 보안 그룹 생성
3. SSH 연결

간단한 node App 배포 예정
```
FROM node:14-alpine

WORKDIR /app

COPY package.json .

RUN npm install

COPY . .

EXPOSE 80

CMD ["node", "app.js"] 
```
Docker Image build
- docker build -t node-dep-example .

Docker Container run
- docker run -d --rm --name node-dep -p 80:80 node-dep-example

## 프로덕션(production)에서 바인드 마운트

바인드마운트는 고려대상X    

개발 환경에서는
- 코드를 캡슐화할 필요가 없음
- 컨테이너 외부의 코드를, 별도 재빌드/재시작 없이 업데이트

운영 환경에서는
- 컨테이너 외부의 주변 설정에 의존하지 않아야 함
- 이미지와 이미지를 기반으로 하는 컨테이너 단일 소스만 있어야함

따라서 컨테이너안에 필요한것들을 모두 포함하기 위해,    
바인드 마운트 대신 빌드 시 사본(COPY)을 포함함.     

## EC2 인스턴스에 연결하기
AWS EC2 생성과 접근은 스킵
관리콘솔이 업데이트되면서 UI가 많이 바뀌기도했고
해당 부분은 최근블로그들 살펴보면 더 잘 정리된 곳들도 많습니다

## Linux에 Docker 일반적인 설치하기
https://docs.docker.com/engine/install/
항상 기준은 공식문서로 놓고 보기

기존에 Amazon Linux 2에서 Amazon Linux 2023으로 업데이트 되면서 amazon-linux-extra 명령어는 사라졌습니다.   
개인적으로는 잘쓰는 명령어긴 했는데.. 아쉽군요.     

## 로컬 이미지를 클라우드로 푸시(push)하기
로컬 도커 이미지를 리모트 머신으로 가져오는 방법

1. 소스코드 배포하기
  - 소스코드와 Dockerfile 전체를 리모트 머신에 복사
  - 호스트 머신에서 이미지 구축 후 사용

2. 컨테이너 이미지 사전 빌드
  - 빌드된 이미지를 리모트 머신에서 실행

로컬에서 도커이미지를 빌드 한 뒤, 이미지를 DockerHub에 푸시하고,    
리모트 서버에서 이미지를 끌어온뒤(pull) 실행

Docker Hub repository 생성하기
- Docker Hub login 후 node-example-1 레포지토리 생성
- .dockerignore 설정으로 node_module, Dockerfile, .pem 등 불필요한 파일 제외
- docker build -t node-dep-example-1 .
- docker tag node-dep-example-1 nasir17/node-dep-example-1
- docker login
- docker push nasir17/node-dep-example-1

## 앱 실행 & 게시하기 (EC2에서)
리모트 머신에서 Docker Hub의 이미지 사용하기
- docker run -d --rm -p 80:80 academind/node-dep-example-1 
  - 로컬이미지가 아니기에 이미지 이름 앞에 도커허브 레포지터리 추가

관리 콘솔에서 조회되는 EC2의 Pulic IP를 통한 접근
- 기본적으로는 실패
- 왜? 보안그룹 개방 필요
  - 보안그룹에 접근하여 HTTP(80)포트 개방

이런식으로 Docker 컨테이너 실행이 가능하며, Docker Compose 또한 실행가능

## 컨테이너/이미지 관리 & 업데이트
리모트 서버에 업데이트를 푸시하는 방법
- 소스코드를 변경한뒤, 이미지 재빌드하여 Docker Hub에 푸시
- EC2 인스턴스에 접근하여 sudo docker stop 으로 기존 컨테이너 중지
- docker pull을 입력해 최신 image 다운로드
- docker run으로 재시작

## 현재 접근 방식의 단점
모든것이 수동임. (DIY)  
자동화된 배포 절차(workflow) 필요
- 호스트머신의 명령어로 이미지가 리모트 머신으로 이동
- 자동으로 컨테이너 재시작 등

EC2는 사용자가 리모트 머신에 대해 모든 책임을 짐
- 운영체제 업데이트등 머신 상태 관리
- 네트워크,방화벽등 관리
- SSH 접근 필요

일반적인 웹 개발자로써 알아둬야할것들 외의 것들을 살펴볼 수 있기 때문에 진행해보았다 
\> 추후 다른 관리형 서비스 사용

## 수동 배포에서 관리형 서비스로
기존 수동 배포 방식에서는 상태 유지, 모니터링, 확장등이 필요 
\> 제대로 대처하지 못하면 불안정하고, 안전하지 못한 실행이 될 수 있음

관리형 서비스가 이에대한 대안이 될 수 있다. 

세부 설정작업들을 완화해주지만, 이를 제어하기 위해 docker 명령어외에도 CSP가 제공하는 규칙/도구들을 사용해야할 수도 있다.

## AWS ECS를 사용한 배포: 관리형 Docker 컨테이너 서비스
ECS(Elastic Container Service), EC2와는 다르게 Free tier 대상이 아님에 유의

ECS가 정의하는 Container 수준
- Container
- Task
- Service
- Cluster

제일 작은 범위인 Container부터 실습 시작
- 컨테이너 실행의 기반인 이름과 이미지 입력 (*)
- 그외 선택 가능한 옵션들
  - 메모리 제한
  - 포트 매핑 (80)
  - 헬스 체크
  - 환경(Environment)
    - Default ENTRYPOINT Override
    - Default WORKDIR
    - 환경변수(--env)
  - Network
  - Storage(Volume), Logging(Cloudwatch)

전체 어플리케이션의 청사진인 Task
- 하나 이상의 컨테이너 포함 가능한 컨테이너 실행 환경
  - 다중 컨테이너 환경의 앱 실행 가능
- 앞서 사용했던 EC2와 유사한 수준 (리모트 머신)
- Fargate(Serverless) 환경에서 구성됨
  - EC2: 사용량과 상관없이, `사용 시간`에 대해 비용 부여
  - Fargate: 사용시간과 별개로, `사용량`에 대해 비용 부여

Container가 포함된 Task의 실행/접근을 제어하는 Service
- 보안그룹 설정
- 로드밸런서 설정

Service들이 전체 실행되는 네트워크 환경인 클러스터
- 다중 컨테이너 앱 실행시, 다수 컨테이너를 그룹화 > 상호통신가능

\> 생성 완료 이후 Task ID를 통해 접근 가능

서버를 생성하거나 구성할 필요없이 딸깍과 몇글자 입력으로 컨테이너 구동 환경이 완성되었다.

## AWS에 대한 추가 정보
생성된 Task에서 여러 설정을 추가/변경이 가능함
- Task size (CPU/Mem)
- Auto Scaling

## 관리되는 컨테이너를 업데이트하기
소스코드변경, 재빌드, DockerHub 푸시까지는 동일

어떻게 ECS가 이 업데이트를 감지할 수 있는가?
- 자동으로 Sync가 맞춰지지는 않는다
- Tasks에서 업데이트된 이미지가 포함된 새로운 Revision 생성 

# 이야깃거리

## 개발자는 인프라를 어디까지 알아야할까요(넋두리)
EC2 <> ECS 에서도 살짝 그향기가 느껴졌습니다.  
Managed Service / Serverless / Platform Engineering 같은 키워드처럼, 일반적인 대세는 인프라 레벨에 대한 추상화인것 같아요.   
안예쁘고 모쌩긴 검고 흰 터미널화면에 명령어 입력하고 실행하는 대신, 깔끔하고 예쁜 UI에서 많은설정들이 추상화되서 버튼 딸깍으로 간편하게 구축하는게 트렌드이긴합니다.

그러다보니 `직접 쓰진 않더라도 가려진 설정들을 알아두긴 해야한다. 알아야 잘 쓸 수 있다` 같은 생각을 하고 있었는데, 최근에는 조금 생각이 바뀌었어요.
결국 관심사의 문제인데, 시간은 한정되어있고 집중해야한다면 네트워크나 서버플랫폼같은 로우레벨보다는 어플리케이션 개발자로써 DDD, 클린코딩, 코드레벨의 성능개선 같은 키워드에 더 많은 시간을 쏟으시지않을까 하는 생각이 들었습니다.
사바사 회바회 부바부겠지만 저처럼 DevOps/인프라 조직이 별도로 있을 수준이면 저희는 쉽고 간편하게 떠먹을수있도록 최대한 잘 패키징해서 제공하고 본연의 업무에 집중할 수 있는 환경을 제공해주는게 맞지않나?싶네요
그러니 빨리 다들 도커강의 끄고 팰월드하러가세요 내 밥그릇은 내가지켜야지  