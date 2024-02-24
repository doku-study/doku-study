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
빌드 단계의 필요성
- 개발과 운영 설정의 차이가 있는 경우) React와 같이 JavaScript로 작성된, 브라우저에서 실행되는 코드
  - React에서는 HTML이 혼합된 javascript파일 존재 > JSX 
  - 백그라운드에서 실행되는 일부 스크립트를 통해 컴파일되어 브라우저에서 실행되는 코드
  - npm start시 컴파일되어 브라우저에 적절하게 변환되어 실행
  - 해당 컴파일 과정은 무거워서 운영환경에서 하기엔 적절하지 않음
  - start 명령대신 build 명령을 사용해서 코드컴파일 및 최적화 수행 > 결과물 내보내기
    - start: 컴파일 및 최적화 후 실행, 자체 서버 가짐, 무거움
    - build: 컴파일 및 최적화만, 자체서버 없음

## "빌드 전용" 컨테이너 만들기
운영환경을 위한 Dockerfile.prod 별도의 도커파일 추가    
기본적인 내용은 동일하지만, 별도 포트를 노출하지않고 npm start 대신 npm run build 수행

## 멀티 스테이지 빌드 소개
멀티 스테이지 빌드를 사용하여, stage라고 부르는 여러 빌드/설정 단계 정의 가능     

첫번째 빌드 단계 
- 종속성 설치 및 소스코드를 가져와, 완성된 소스코드 빌드
- node를 사용하여 빌드하지만, 빌드 이후에 node는 필요하지 않다
```
FROM node:14-alpine as build

WORKDIR /app

COPY package.json .

RUN npm install

COPY . .

RUN npm run build
```

두번째 빌드 단계
- 실행을 위해 nginx만 사용
- 첫단계의 빌드 결과물을 --from 옵션을 사용하여 가져옴
```
FROM nginx:stable-alpine

COPY --from=build /app/build /usr/share/nginx/html

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
```

## 멀티 스테이지 이미지 구축
별도 환경에서 실행하기 위한 소스코드의 변경
- 로컬머신에서는 URL을 localhost를 사용하여 요청을 보냈음
- ECS와 같은 별도 환경에서는 같은 머신 보장X > 디폴트경로로 수정 / 이후 변수화도 가능
- `docker build -f frontend/Dockerfile.prod -t nasir17/goals-react ./frontend`
- `docker push nasir17/goals-react`

## 스탠드얼론 프론트엔드 앱 배포하기
배포를 위해 기존 goals 태스크에 컨테이너 추가한 새 개정판 생성
- 기존 태스크에서 새 개정판 생성이후, 컨테이너 추가 클릭(컨테이너-2 생성)
- goals-frontend로 컨테이너 이름 설정 / `nasir17/goals-react` 컨테이너 URI 추가
- 80 포트매핑 설정
- backend 컨테이너가 먼저 생성되도록 시작 종속성 정렬 설정
  - goals-backend 설정 후 success 조건 설정
  - 에러대응) 필수컨테이너를 백엔드에서 프론트엔드컨테이너로 변경
- 하나의 태스크 내에서 같은 포트(80)을 여러 컨테이너가 동시 사용 불가
  - 지금 구조에서 프론트/백 두개를 하나의 컨테이너로 병합이 이상적
  - 별도 태스크로 분리하여 적용
- 새 개정판 생성 취소

goals-react 태스크 정의 생성
- goals-react 태스크 정의 이름 설정
- goals-react 컨테이너 이름 / `nasir17/goals-react` 컨테이너 URI 추가
- 80 포트매핑(디폴트)
- 하지만 별도 task로 분리되었기 때문에 백엔드 찾아갈 수 있도록 소스코드에 URL 추가 필요
- 태스크 생성 취소

frontend 소스코드 변경 
- App.js L86 backendUrl 상수 추가
- App.js L7 backendUrl 상수 설정에 개발시 localhost / ECS시 로드밸런서 경로 추가
- EC2 콘솔에서 로드밸런서 생성
  - goals-react-lb 이름설정
  - ecs와 같은 네트워크(VPC/서브넷/보안그룹 설정)
  - react-tg 타겟그룹 생성, IP유형, 생성단계에서 대상은 추가X
  - 아니근데 이건 프론트용이고..
- 기존의 백엔드 로드밸런서(ecs-lb)의 DNS를 추가

frontend 컨테이너 배포
- 재빌드/docker push
- 기존 goals-app 클러스터의 goals-react 서비스 생성
  - goals-react 태스크 정의 선택
  - goals-react 서비스 이름 설정
  - 기존 goals-react-lb와 연결
- 생성완료 이후 goals-react-lb의 DNS로 접근하여 화면 확인

## 이야깃거리
AWS 이야기잠깐
https://ap-northeast-2.console.aws.amazon.com/ecs/v2/create-cluster?region=ap-northeast-2   
Amazon Elastic Container Service    
AWS Fargate     

언제 Amazon이고 언제 AWS?

### taskdefinition(JSON)
실습시 업데이트된 AWS UI와의 괴리는 문제가 있음   
태스크정의는 JSON으로 뺄 수 있고, JSON으로 생성할 수 있어서 백업차 빼둠   
다만 IAM Role(번호계정ID), 보안그룹명(실습이랑 조금다르게함)로 인해 바로 적용은 어려움
- backend(goals)
```
{
    "family": "goals",
    "containerDefinitions": [
        {
            "name": "goals-backend",
            "image": "nasir17/goals-node",
            "cpu": 0,
            "portMappings": [
                {
                    "name": "goals-backend-80-tcp",
                    "containerPort": 80,
                    "hostPort": 80,
                    "protocol": "tcp",
                    "appProtocol": "http"
                }
            ],
            "essential": true,
            "command": [
                "node",
                "app.js"
            ],
            "environment": [
                {
                    "name": "MONGODB_DATABASE",
                    "value": "goals"
                },
                {
                    "name": "MONGODB_PASSWORD",
                    "value": "admin123"
                },
                {
                    "name": "MONGODB_USERNAME",
                    "value": "nasir17dev"
                },
                {
                    "name": "MONGODB_URL",
                    "value": "cluster0.d생략4.mongodb.net"
                }
            ],
            "environmentFiles": [],
            "mountPoints": [],
            "volumesFrom": [],
            "ulimits": [],
            "logConfiguration": {
                "logDriver": "awslogs",
                "options": {
                    "awslogs-create-group": "true",
                    "awslogs-group": "/ecs/goals",
                    "awslogs-region": "ap-northeast-2",
                    "awslogs-stream-prefix": "ecs"
                },
                "secretOptions": []
            }
        }
    ],
    "taskRoleArn": "arn:aws:iam::2819생략263:role/ecsTaskExecutionRole",
    "executionRoleArn": "arn:aws:iam::2819생략263:role/ecsTaskExecutionRole",
    "networkMode": "awsvpc",
    "requiresCompatibilities": [
        "FARGATE"
    ],
    "cpu": "1024",
    "memory": "3072",
    "runtimePlatform": {
        "cpuArchitecture": "X86_64",
        "operatingSystemFamily": "LINUX"
    }
}
```

- frontend(goals-react)
{
    "family": "goals-react",
    "containerDefinitions": [
        {
            "name": "goals-react",
            "image": "nasir17/goals-react",
            "cpu": 0,
            "portMappings": [
                {
                    "name": "goals-react-80-tcp",
                    "containerPort": 80,
                    "hostPort": 80,
                    "protocol": "tcp",
                    "appProtocol": "http"
                }
            ],
            "essential": true,
            "environment": [],
            "environmentFiles": [],
            "mountPoints": [],
            "volumesFrom": [],
            "ulimits": [],
            "logConfiguration": {
                "logDriver": "awslogs",
                "options": {
                    "awslogs-create-group": "true",
                    "awslogs-group": "/ecs/goals-react",
                    "awslogs-region": "ap-northeast-2",
                    "awslogs-stream-prefix": "ecs"
                },
                "secretOptions": []
            }
        }
    ],
    "taskRoleArn": "arn:aws:iam::2중간생략3:role/ecsTaskExecutionRole",
    "executionRoleArn": "arn:aws:iam::2중간생략3:role/ecsTaskExecutionRole",
    "networkMode": "awsvpc",
    "requiresCompatibilities": [
        "FARGATE"
    ],
    "cpu": "1024",
    "memory": "3072",
    "runtimePlatform": {
        "cpuArchitecture": "X86_64",
        "operatingSystemFamily": "LINUX"
    }
}