# Docker 컨테이너 배포하기

## 다중 컨테이너 앱 준비하기
프론트를 제외하고 백엔드(goals API), 데이터베이스(mongodb) 준비

기존 로컬 머신의 다중 컨테이너는 docker compose를 사용하여 배포하였지만, ECS 배포시에는 미사용

ECS 배포시 추가로 고려해야할 점
- 기존 배포시에는 고려하지 않았던, CPU 용량 같은 사안에 대한 고려 필요
- 도커네트워크를 사용한, IP 대신 컨테이너 이름을 통한 연결 불가
  - 동일한 태스크(ECS의 물리서버단위?)에 컨테이너를 추가필요(localhost)
  - node의 환경변수(process.env.MONGODB_URL) 활용
- 빌드 이후 바로 시작이 아닌, Image tag, Docker Hub에 대한 push/pull 필요

## NodeJS 백엔드 컨테이너 구성하기
기존 ECS 환경 제거 이후, 새로운 Cluster, task, service를 사용한 배포 진행

Cluster
- goals-app 이름 설정 외 디폴트 사항 유지
- 현재 UI에서는 네트워크 설정 없음
- 추후 fargate 사용을 위해 인프라탭에서 AWS Fargate 설정

Tasks
- Service는 Task 기반으로 실행되기 때문에 Task 사전설정 필요
- 생성한 goasl-app cluster 클릭 후 새 태스크 실행으로 설정
- Tasks Definition (태스크 정의) 필요함

Tasks Definition
- goals 이름 설정
- Fargate 시작 유형 및 필요한 리소스(CPU/Mem)부여 (최소값)
- ecsTaskExecutuionRole 태스크 역할 선택
- 컨테이너-1의 탭에서 실행한 컨테이너 정보 입력
  - goals-backend 이름 설정
  - 80 포트 매핑 설정
  - 도커 구성 항목에서 override 설정 (개발과 운영차이 반영)
    - 기존에는 nodemon 사용을 위해 `npm start`로 시작 > node 사용을 위해 `node app.js`
  - 환경 변수 항목에서 backend.env에 해당하는 값 K-V 추가
  
## 두 번째 컨테이너 & 로드 밸런서 배포하기
Tasks Definition
- goals 태스크 정의에 이어서, 컨테이너-2를 추가하여 mongodb 컨테이너 설정
- mongodb 이름 설정
- mongo image 설정(Dockerhub의 퍼블릭 이미지)
- 27017 포트 매핑(mongo default)
- 환경 변수 항목에서 mongo.env에 해당하는 값 K-V 추가

Service create
- 기존 goals-app 클러스터 내에서, 서비스 생성
- goals_service 이름 설정
- public IP 할당이 가능한 VPC/Subnet 네트워크 설정
- 트래픽 효율적 처리를 위한 로드밸런서 설정
  - 로드밸런서는 AWS EC2에 해당하는 서비스이기때문에, 별도로 이동해서 생성해야..했으나 ECS에 신규생성/기존선택이 내장되었음
  - ecs-lb 이름 설정
  - IP유형의 target grpup(tg, 타겟그룹) 설정

접속 확인
- 생성된 task의 퍼블릭 IP/goals 형식으로 적용

## 안정적인 도메인을 위해 로드 밸런서 사용하기
타겟그룹 설정 변경
- 기본생성시 tg 경로가 /로 설정되어있음
- /goals 로 요청하기 때문에 타겟그룹을 찾아 헬스체크 변경

## ECS로 EFS 볼륨 사용하기
업데이트 배포
- 소스 코드 변경 후 이미지 재빌드, 태깅, 푸시
- ECS Service에서 Force new deployment 선택 후 Update service

별도의 스토리지 설정을 하지않았기때문에 컨테이너 재시작시 데이터 손실되었음
- localhost에서는 볼륨 사용
- ECS 볼륨 설정
  - data 이름 설정
  - EFS 볼륨 유형 설정
    - EFS 콘솔에서 신규 스토리 생성 필요
    - db-storage 이름 설정
    - ECS랑 같은 VPC선택
    - 사용자 지정
      - 기본값 선택 후 다음
      - Network Access에서 타겟 마운트 설정
      - EC2 보안그룹에서 efs-sc 이름의 2049 포트에 대해 ecs 보안그룹 허용하는 신규 보안그룹 생성
- mongodb 태스크 정의 업데이트
  - 신규생성한 efs-sc 볼륨을 /data/db 경로에 바인딩
  - 새로 POST 요청을 통해 데이터 저장 후 컨테이너를 재시작하여도 GET으로 조회되어야한다
  - 현재 롤링 배포 설정에서는 업데이트시 동시에 2개가 태스크가 존재할 수 있어 수동으로 기존 태스크를 삭제해야 업데이트 가능
  - 저장된 데이터 조회 가능

## 현재 아키텍처
- node backend API 컨테이너/mongodb 컨테이너 존재
- 배포를 위해 AWS ECS 플랫폼의 Fargate 사용
- 데이터 저장을 위해 AWS EFS 사용
- 고정된 URL 사용을 위해 ALB 사용

## 데이터베이스 & 컨테이너: 중요한 고려 사항
자체 데이터베이스 컨테이너 사용 중
- 가용성 확장 및 관리의 어려움
- 트래픽 급증 시 성능 문제 발생의 위험성
- 백업 및 보안 대책

MySQL의 경우 AWS의 RDS 사용등의 방법이 있음, MongoDB의 경우 MongoDB회사가 제공하는 MongoDB Atlas 존재

## MongoDB Atlas로 이동하기

신규 계정 생성 및 클러스터 생성
- https://www.mongodb.com/ko-kr/cloud/atlas 에서 신규 체험 계정 생성
- 무료인 M0 티어 사용
- AWS/Seoul Region 사용
- Cluster0 (기본값) 이름 사용

mongoDB 연결
- 생성된 클러스터 선택 후 Connect > Driver 방식
- node 선택 후 mongodb+svc~ 로 시작하는 url 확인
- 최신버전의 mongodb와, atlas에서 제공하는 mongodb의 버전이 다를 수 있음 > 주의 필요 
- 기존 접근 설정 업데이트
  - 인증에 필요한 querystring 업데이트 authSource=admin > ?retryWrites=true&w=majority
  - URL 변경 mongodb > cluster0.dmgthm4.mongodb.net
  - Database 변수화 및 적용 course-goals > ${process.env.MONGODB_DATABASE}

## 프로덕션에서 MongoDB Atlas 사용하기
ECS Task에서 mongo 컨테이너와 EFS 제거 후 업데이트된 백엔드 이미지 적용

## 업데이트 & Target 아키텍처
기존 backendAPI+mongodb 구조에서, 데이터베이스를 MongoDB Atlas로 변경 후 단일 컨테이너 구조로 전환하였음.   

사용자가 웹에서 상호작용 할 수 있도록 Fronted React 컨테이너를 추가하여 배포 예정


## 일반적인 문제 이해하기

## "빌드 전용" 컨테이너 만들기

## 멀티 스테이지 빌드 소개

## 멀티 스테이지 이미지 구축

## 스탠드얼론 프론트엔드 앱 배포하기

## Development vs Production: 차이점

## 멀티 스테이지 빌드 Target이해하기

## AWS를 넘어서

## 모듈 요약

## 모듈 리소스

## 이야깃거리
AWS 이야기잠깐
https://ap-northeast-2.console.aws.amazon.com/ecs/v2/create-cluster?region=ap-northeast-2   
Amazon Elastic Container Service    
AWS Fargate     

언제 Amazon이고 언제 AWS?
