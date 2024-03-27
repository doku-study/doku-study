# 새롭게 알게된 점

## 모듈 요약

- Pod-Internal 통신
- Pod-To-Pod 통신
- 프론트엔드 애플리케이션 통신

> ❗️ tasks 폴더 누락 문제<br>
> 강사님께서 주신 코드에서 `/tasks-api`에 `tasks` 폴더가 누락되어 해당 폴더 경로가 존재하지 않는다는 에러가 발생한다. 빈 폴더를 추가해서 에러를 해결했다.

## 주요 command

- 코드 변경 이후 이미지 빌드와 원격 레포지토리 갱신
  (`USER_NAME/IMAGE_NAME`은 docker hub 원격 레포지토리 이름)

```bash
docker build -t USER_NAME/IMAGE_NAME .
docker push USER_NAME/IMAGE_NAME
```

- 이미지 갱신 이후 쿠버네티스 deployment 객체 갱신

```bash
kubectl delete -f=DEPLOYMENT.yaml
kubectl apply -f=DEPLOYMENT.yaml
```

- service 객체 생성 및 활성화

```bash
kubectl apply -f=SERVICE.yaml
minikube service SERVICE
```

## 목표 구조

- Auth API를 외부에서 접근 못하게 하면서 동시에 User API와 Tasks API와는 통신이 가능하도록 만들기
- auth-service에서 생성된 IP 주소를 동적으로 users-deployment와 연결시켜야 함(`AUTH_ADDRESS`)

### Auth-API

```yaml
# auth-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: auth-deployment
spec:
  replicas: 1
  selector:
    matchLabels:
      app: auth
  template:
    metadata:
      labels:
        app: auth
    spec:
      containers:
        - name: auth
          image: blcklamb/kub-demo-auth:latest
```

```yaml
# auth-service.yaml
apiVersion: v1
kind: Service
metadata:
  name: auth-service
spec:
  selector:
    app: auth
  type: ClusterIP
  ports:
    - protocol: TCP
      port: 80
      targetPort: 80
```

### User-API

```yaml
# user-deployment.yaml
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
          image: blcklamb/kub-demo-users:latest
          env:
            - name: AUTH_ADDRESS

              # 쿠버네티스에서 자동 지정한 정적 IP로 할 경우
              # value: "10.97.205.103"
              # 쿠버네티스에서 자동 할당한 cluster 내부 도메인을 쓸 경우
              value: "auth-service.default"
```

- cluster 내부 도메인<br/>
  [CoreDNS: DNS and Service Discovery](https://coredns.io/)<br/>
  ex) `{{SERVICE_NAME}}.NAMESPACE`

- 또는 쿠버네티스가 자동 생성하며, 코드 상에서 바로 사용 가능한 환경 변수가 있다
  `{{SERVICE_NAME}}_SERVICE_HOST`<br/>
  ex) `AUTH_SERVICE_SERVICE_HOST`<br/>
  주의할 점은 docker_compose로 배포한 애플리케이션에는 자동 생성되지 않는 키워드이기 때문에 별도 지정이 필요하다

- 여러 방법이 있지만 name space로 만들어진 cluster 내부 도메인을 쓰는 것이 일반적이다. 하지만 선호에 따라서 어떤 것을 쓰는 지 상관이 없다!

```yaml
# user-service.yaml
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

### Tasks-API

```yaml
# tasks-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: tasks-deployment
spec:
  replicas: 1
  selector:
    matchLabels:
      app: tasks
  template:
    metadata:
      labels:
        app: tasks
    spec:
      containers:
        - name: tasks
          image: blcklamb/kub-demo-tasks:latest
          env:
            - name: AUTH_ADDRESS
              value: "auth-service.default"
            - name: TASKS_FOLDER
              value: tasks
```

```yaml
# tasks-service.yaml
apiVersion: v1
kind: Service
metadata:
  name: tasks-service
spec:
  selector:
    app: tasks
  type: LoadBalancer
  ports:
    - protocol: TCP
      port: 8000
      targetPort: 8000
```

### Frontend

```yaml
# frontend-deployment.yaml
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
          image: blcklamb/kub-demo-frontend:latest
```

```yaml
# frontend-service.yaml
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

```conf
# frontend/conf/nginx.conf
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

## CORS?

Cross-Origin Resource Sharing(교차 출처 리소스 공유)

SOP(Same-Origin Policy): 같은 출처에서만 리소스를 공유할 수 있는 정책
CORS 정책을 지킨 리소스 요청은 출처가 다르더라도 허용한다.

## 리버스 프록시?

특정 URL로 보내는 요청에 대해 브라우저는 다른 출처로 보낸 것으로 알고 있지만 웹팩/nginx로 동일 출처로 요청을 프록싱하게 만들 수 있다. 이를 통해 CORS 정책을 우회할 수 있다.

정적 IP는 Local machine에서 사용할 때 바라보는 주소이다. 리버스 프록시로 프론트 애플리케이션을 브라우저가 아니라 컨테이너 내에서 돌리는 것으로 만들었기 때문에 해당 IP는 작동하지 않고 기본으로 제공해주는 주소를 사용할 수 있다. 포트 번호도 잊지 말기!

# 궁금한 점

1.  왜 Deployment와 Service의 apiVersion이 다를까?
2.  YAML 파일 작성 시 `""`는 언제 쓰는 걸까?

# 느낀 점

- 여러 command 자동화 alias 처리

  네트워크 실습하면서 프로젝트 코드 변경 후 docker 빌드 -> docker push -> kubectl deployment 삭제 -> kubectl deployment apply 이 네 개의 command가 고정 반복이 되는 걸 알 수 있었다. image 이름을 label처럼 지정하고 yaml 파일 이름도 `{{IMAGE_NAME}}-deployment.yaml` 이렇게 컨벤션을 둔다면 alias로 지정해서 한 command로 파이프라인을 만드는 것도 가능하지 않을까?
