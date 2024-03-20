# Kubernetes Networking

## 모듈 소개
Kubernete Networking
- 컨테이너간 상호 통신, 퍼블릭웹 접근 확인
- Pod 내부 통신 (pod-internal)
- Pod 간 통신 (pod to pod)

## 프로젝트 시작 & 목표
3개의 Backend API container, NodeJS
- users > auth > tasks 
- 볼륨에 관한 챕터가 아니기에 별도 데이터 저장 X
  - user > auth: pod 내부 통신 
  - tasks: 별도 pod로 실행, pod간 통신

docker(compose) 테스트
- **mkdir ./tasks-api/tasks**
- `docker compose up -d --build`
- user 컨테이너에 더미 데이터를 보내 토큰 수신
  - `curl -X POST -H "Content-Type: application/json" -d '{"email": "test@test.com", "password":"testers"}' localhost:8080/login`
- auth 컨테이너는 별도 노출되어있지않아 직접요청시 실패
- tasks 컨테이너에 저장 및 불러오기
  - `curl -X POST -H "Content-Type: application/json" -H "Authorization: Bearer abc" -d '{"text": "A second task", "title":"Do this,too"}' localhost:8000/tasks`
  - `curl -X GET -H "Authorization: Bearer abc" localhost:8000/tasks`

## 첫 번째 배포 만들기
혼자 작동하도록 ./users-api/user-app.js 수정
- L26) const hashedPW = 'dummy text';
- L57-59) const response = {status:200, data: {token: 'abc' } };
- docker build . -t nasir17/kub-demo-users:v1; docker push nasir17/kub-demo-users:v1

별도 .kubernetes 디렉토리 생성후 users-deployment.yaml작성
```
apiVersion: apps/v1
kind: Deployment
metadata:
  name: users-deployment
spec:
  replicas: 1
  selector: 
    matchLabels:
      app: users
  template:
    metadata:
      labels:
        app: users
    spec:
      containers:
        - name: users
          image: nasir17/kub-demo-users:v1
```

## Service에 대한 또다른 관점
고정IP제공 및 접근 진입점으로서의 service
- Pod의 IP는 재생성시 변경가능 / 상대적으로 안정적인 svc의 IP
- 뒷단의 앱 Pods(Users, Auth,Tasks) 로의 트래픽 전달

users-service.yaml 작성
```
apiVersion: v1
kind: Service
metadata:
  name: users-service
spec:
  selector:
    app: users
  type: LoadBalancer
  ports:
    - protocol: TCP
      port: 8080
      targetPort: 8080
```

/signup으로 새로운 유저 생성하기
```
# aaa@aaa.com / aaa 유저 signup
curl -X POST -H "Content-Type: application/json" -d '{"email": "aaa@aaa.com", "password":"aaa"}' $(minikube service users-service --url)/signup

# aaa@aaa.com / aaa 유저 login
curl -X POST -H "Content-Type: application/json" -d '{"email": "aaa@aaa.com", "password":"aaa"}' $(minikube service users-service --url)/login
```

## 하나의 Pod안에 있는 다중 컨테이너
users-api가 auth-api와 통신하도록 구성 > 소스코드 변경 필요
- users-app.js의 기존 docker-compose service name 환경변수화
  - L26) 복구 후 'auth' 문자열을 \`${process.env.AUTH_ADDRESS}`로 변경
  - L57-59) 복구 후 'auth' 문자열을 \`${process.env.AUTH_ADDRESS}`로 변경
  - docker build . -t nasir17/kub-demo-users:v2; docker push nasir17/kub-demo-users:v2
- auth-api build & push
  - docker build . -t nasir17/kub-demo-auth:v1; docker push nasir17/kub-demo-auth:v1
- users-deployment.yaml에 auth-api 컨테이너 추가
  - spec.template.spec.containers에 kub-demo-auth 컨테이너 추가
  - 강의에선 latest 이야기 나왔는데 추적 힘드니까 가능한 쓰지않는게 좋습니다

## Pod 내부 커뮤니케이션
같은 pod 내의 컨테이너들은 localhost로 통신 가능
```
spec:
  template:
    spec:
      containers:
        - name: users
          image: nasir17/kub-demo-users:v2
          env:
            - name: AUTH_ADDRESS
              value: localhost
        - name: auth
          image: nasir17/kub-demo-auth:v1
```
위의 /signup, /login 작동 확인

## 다중 Deployments 생성
tasks-api 배포 및 작동확인 필요     
auth-api 내부화 필요 (users에서 분리 및 internal svc 사용)
- 사실 현재 구조도 user-svc에서 8080 포트만 개방했기때문에 auth(p80)는 내부화되어있긴함
- 확실한 내부화를 위해 auth-api 분리 배포 및 내부 svc를 통한 통신

auth-deployment.yaml 생성
- user-deployment.yaml에서 적당히 이미지태그 바꿔서 auth-deployment.yaml 생성
- pod는 생성되더라도 IP가 가변적이기때문에 svc 생성 필요

auth-service.yaml 생성
- user-service.yaml에서 적당히 포트/타입 바꿔서 auth-service.yaml 생성

## IP 주소 & 환경 변수를 사용한 Pod간 통신
auth-set 배포 후 IP 적용
- k apply -f auth-deployment.yaml,auth-service.yaml
- k get svc (=kubectl get svc auth-service -o=jsonpath='{.spec.clusterIP}')
- 해당값 users-deployment.yaml의 env에 업데이트

k8s의 [자체적인 환경변수](https://kubernetes.io/docs/concepts/services-networking/service/#environment-variables) 사용
- `{SVCNAME}_SERVICE_HOST` 형식으로 SVC IP를 가져올 수 있다.
- users-app.js 수정
  - ${process.env.AUTH_ADDRESS} > ${process.env.AUTH_SERVICE_SERVICE_HOST}
  - docker build . -t nasir17/kub-demo-users:v3; docker push nasir17/kub-demo-users:v3

## Pod간 통신에 DNS 사용하기
CoreDNS라는 k8s 클러스터에 기본 포함된 내부 DNS 서비스 활용
- [서비스명].[네임스페이스명]의 DNS로 요청하면 CoreDNS가 클러스터 내부 IP로 바꿔준다
- "auth-service.default" > "10.96.36.57"

## 어떤 접근 방식이 최고인가? 그리고 도전!
가능한 하나의 pod에 하나의 container 연결
- 하나의 pod에 다수의 container를 연결을 할 수는 있다

pod간 통신을 위해 설정할 수 있는 방법들
- 기본적으로 서비스의 IP를 사용 (고정IP)
1. spec.template.spec.containers[].env의 환경 변수를 통해
2. 쿠버네티스의 자체적인 환경변수 `{SVCNAME}_SERVICE_HOST`를 통해
3. 내부 DNS [서비스명].[네임스페이스명]
- 불필요한 필드, docker compose와 같이 사용 등 고려하여 선택

## 챌린지 솔루션
\1. 의 AUTH_ADDRESS 사용    

tasks-app.js 수정 및 배포세트 생성
- 하드코딩된 docker compose의 auth service 변수화
  - L20)   const response = await axios.get('http://auth/verify-token/' + token);
  - ${process.env.AUTH_ADDRESS}
  - docker build . -t nasir17/kub-demo-tasks:v1; docker push nasir17/kub-demo-tasks:v1
- tasks-deployment.yaml 생성
  - TASKS_FOLDER: tasks env 추가에 유의
- tasks-service.yaml 생성
- tasks-api 작동확인
  - `curl -X POST -H "Content-Type: application/json" -H "Authorization: Bearer abc" -d '{"text": "A second task", "title":"Do this,too"}' $(minikube service tasks-service --url)/tasks`
  - `curl -X GET -H "Authorization: Bearer abc" $(minikube service tasks-service --url)/tasks`

## 컨테이너화된 프론트엔드 추가하기
백엔드 API 테스트를 위해 별도의 방법을 사용했지만 프론트를 붙여서 확인해 볼것

하드코딩으로 작동확인
- App.js의 L11,32 수정 > minikube service frontend-service --url 
  - fetch('http://192.168.49.2:32503/tasks'
- docker build . -t nasir17/kub-demo-frontend:v1; docker push nasir17/kub-demo-frontend:v1
- docker run -p 80:80 -d --rm nasir17/kub-demo-frontend:v1
- CORS 에러로 인해 작동확인 실패 

CORS 헤더삽입 - tasks-app.js 업데이트
- 파일 갈아끼기 (L14-19 setHeader 추가)
- docker build . -t nasir17/kub-demo-tasks:v2; docker push nasir17/kub-demo-tasks:v2
- 401 Unauthorized 발생

브라우저 헤더정보 추가 - App.js 업데이트
- L12-15에 인증헤더 추가 (6번 자료에서 되어있음?)
- 저도 작업할때 많이 뚝딱거리는데 그거보는거같군요

## Kubernetes로 프론트엔드 배포하기
frontend-deployment.yaml 생성
- 대충 구성
```
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frontend-deployment
spec:
  replicas: 1
  selector: 
    matchLabels:
      app: frontend
  template:
    metadata:
      labels:
        app: frontend
    spec:
      containers:
        - name: frontend
          image: nasir17/kub-demo-frontend:v2
```

frontend-service.yaml 생성
- 대충 구성
```
apiVersion: v1
kind: Service
metadata:
  name: frontend-service
spec:
  selector:
    app: frontend
  type: LoadBalancer
  ports:
    - protocol: TCP
      port: 80
      targetPort: 80
```

아직 아쉬운점
- frontend-service의 minikube service의 url이 하드코딩 되어있음
  - fetch('http://192.168.49.2:32503/tasks'
```
Now that's not necessarily horrible because typically if you deploy this
on a real cloud provider and not just with minikube,
this address will be pretty stable
and you might even map your own domain
to this IP address so that it's super stable.
```
- minikube가 아닌, 실제 클라우드환경의 k8s 클러스터의 서비스 IP는 안정적임
- 또는 도메인을 넣고 IP와 연동하여 매우 안정적으로 사용할 수 있음
  - fetch('http://sample.logonme.net/tasks' 같이 설정하고 sample.logonme.net 값을 192.168.49.2로 설정 하는 등

## 프론트엔드에 리버스 프록시 사용하기
대충 nginx로 받아서 proxy_pass로 넘겨주기


리버스 프록시: 특정 경로등을 대상으로 하는 경우, 요청을 다른 호스트/도메인으로 전달하는 기능
- 80port로 들어오는 요청에 대해서
  - 경로가 /api라면 다른 도메인(tasks-service.default)으로 전달
    - curl http://localhost/api/ > curl http://tasks-service.default:8000/api/
  - 경로가 /라면 nginx 기본 index.html로 전달
    - curl http://localhost/ > /usr/share/nginx/html/index.html 리턴
```
server {
  listen 80;

  location /api/ {
    proxy_pass http://tasks-service.default:8000/;
  }
  
  location / {
    root /usr/share/nginx/html;
    index index.html index.htm;
    try_files $uri $uri/ /index.html =404;
  }
  
  include /etc/nginx/extra-conf.d/*.conf;
}
```

## 모듈 요약
Container <> Pod <> PublicWeb 통신 확인     
  - Pod 내부 Container들은 localhost로 통신 가능
  - Pod 간 통신은 Service를 통해 안정적으로 통신 가능

pod간 통신을 위해 설정할 수 있는 방법들
- 기본적으로 서비스의 IP를 사용 (고정IP)
1. spec.template.spec.containers[].env의 환경 변수를 통해
2. 쿠버네티스의 자체적인 환경변수 `{SVCNAME}_SERVICE_HOST`를 통해
3. 내부 DNS [서비스명].[네임스페이스명]
- 불필요한 필드, docker compose와 같이 사용 등 고려하여 선택
