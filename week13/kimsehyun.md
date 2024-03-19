## 226. 모듈 소개
- pod끼리, 그리고 컨테이너끼리 어떻게 서로 통신할 것인가?
- 어떻게 외부에서 pod를 통신할 수 있게 설정할 것인가?

이번 모듈에서는 크게 2가지를 살펴본다. 
1) pod 안에서 일어나는 통신(컨테이너끼리, pod-internal communication)
2. pod끼리 일어나는 통신(pod-to-pod communication)

![[Pasted image 20240319101130.png]]


---
## 227. 프로젝트 소개

실습 코드는 크게 세 가지로 나뉜다.

1. users-api: 사용자의 정보
2. auth-api: 권한, 토큰 부여
3. tasks-api: 


![[Pasted image 20240319101456.png]]

- 외부(client)에서는 Auth API에 직접 접근할 수 없다. 대신, 외부에서는 users-api를 통해서 Users Api가 Auth API과 통신해서 토큰 등을 받아낸다. (users-api는 중개자 같은 느낌?)
- 외부 client로는 PostMan을 쓸 것이다.

### 실습 시작하기 전

웹에 대해 아예 초짜인 (본인같은) 사람이라면 대강이라도 코드가 어떻게 돌아가는지, 어떻게 네트워크를 테스트하는지 확실히 알고 넘어가야 한다.

1. 강의 자료를 다운로드받고, 폴더 안에 있는 docker compose 파일을 빌드한다. 그리고 auth, users, tasks 컨테이너 총 3개를 모두 실행한다.

```bash
docker compose up -d --build
```

< Docker Desktop에서 컨테이너 돌아가는지 확인 >

![[2024-03-19_10-41-13.png]]

2. PostMan 쓰기 전에 PostMan Agent를 설치한다.
3. POST > localhost:8080/login, body에는 dummy 계정 정보를 입력해보면 token을 얻을 수 있다.

```json
// body - raw
{
	"email": "test@gmail.com",
	"password": "testers"
}
```

< POST > login 성공한 모습>

![[2024-03-19_10-34-59.png]]


4. 하지만 GET > localhost/verify-token/abc로 Auth API에 직접 접근하려면 안된다. Auth API는 외부에서 접근할 수 없게 코드 상 설정해놓았기 때문이다.

![[2024-03-19_10-39-16.png]]

5. 그런데 POST > localhost:8000/tasks 파트에서 에러가 발생하는데

![[2024-03-19_11-02-03.png]]


> 답변: task-api 도커 컨테이너에 /app/tasks/tasks.txt 파일이 없어서 생기는 문제 입니다. 도커 빌드전에 tasks-api 아래에 tasks 폴더를 만들고 아래에 tasks.txt 파일을 만든 후 Dockerfile 에 COPY tasks . 를 추가한 후 빌드하면 해결 됩니다. (출처: https://www.udemy.com/course/docker-kubernetes-2022/learn/lecture/30291508#questions/17563016)

위 답변대로 하면 잘 된다.

![[2024-03-19_11-04-55.png]]

그리고 이 모듈에서는 볼륨을 사용하지 않기 때문에(그게 주요 토픽이 아님), docker compose down 하면 데이터가 모두 사라질 것이다.




## 228. 첫번째 배포 만들기

1. minkube를 시작하고, 다른 이미 실행 중인 서비스는 없는지 확인한다.

```bash
minikube status
# 만약 시작 안했다면, 아래로 실행
minikube start

kubectl get deployments
# No resources found in default namespace.
kubectl get services
# NAME         TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)   AGE
# kubernetes   ClusterIP   10.96.0.1    <none>        443/TCP   26d
```

2. users-api > users-app.js로 들어가서 이 코드가 다른 컨테이너에 의존하지 않도록 코드를 일부 수정(주석 처리 + dummy data 추가)한다.

```javascript
// 26번째 줄
// const hashedPW = await axios.get('http://auth/hashed-password/' + password);
const hashedPW = 'dummy text';

// ...
// 57번째 줄
// const response = await axios.get(
// 'http://auth/token/' + hashedPassword + '/' + password
// );
const response = { status: 200, data: { token: 'abc' } };
```

3. Docker Hub에 kub-demo-users 리포지토리를 새로 생성하고, 도커 이미지를 빌드한 다음 push한다.

```bash
cd users-api
docker build -t my_docker_hub_id/kub-demo-users .
docker push my_docker_hub_id/kub-demo-users
```

4. kubernetes > users-deployment.yaml 파일을 다음과 같이 만든다.

```yaml
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
        - # 주의: 여기에 꼭 자기 Docker Hub 이름을 넣어줘야 Image Pull 에러 안 발생
          # image: academind/kub-demo-users
          image: my_docker_hub_id/kub-demo-users
```

그리고 적용한다. 

```bash
cd ../kubernetes
kubectl apply -f=users-deployment.yaml
# deployment.apps/users-deployment created
```

```bash
kubectl get pods
# NAME                                READY   STATUS    RESTARTS   AGE
# users-deployment-59c8765689-hn6cz   1/1     Running   0          11s
```


---

## 229. Service에 대한 또다른 관점

service가 쿠버네티스에서 필요한 이유
1. 고정된 IP 주소: pod는 삭제되거나 이동하면 IP 주소가 매번 변하기 때문
2. 클러스터 외부에서도 pod에 접근할 수 있도록 함

-> 고정된, 안정적인 IP 주소가 있어서 2번이 가능하다는 건지? 이해가 좀 더 필요함

### <쿠버네티스 입문 (정원천, 공용준, 홍석용, 정경록 지음, 동양북스, 2019)>

> pod는 controller가 관리하므로 한군데에 고정해서 실행하지 않고, 클러스터 안을 옮겨 다닙니다. 이 과정에서 node를 옮기면서 실행하기도 하고 클러스터 안 pod의 IP가 변경되기도 합니다. 이렇게 동적으로 변하는 pod들에 고정적으로 접근할 때 사용하는 방법이 쿠버네티스의 서비스service입니다.
> 서비스를 사용하면 pod가 클러스터 안 어디에 있든 고정 주소(stable IP address)를 이용해 접근할 수 있습니다. 클러스터 외부에서 클러스터 안 pod에 접근할 수도 있습니다. 
> pod가 클러스터 안 다른 위치로 옮겨져 IP가 변하더라도 서비스가 자동으로 새로 위치를 옮겨 실행한 pod와 통신하므로 실제 접속하는 사용자는 서비스만 이용해서 문제없이 위치를 옮긴 pod를 사용할 수 있습니다. (p.198)


users-service.yaml을 생성한다.

```yaml
apiVersion: v1
kind: Service
metadata:
  name: users-service
spec:
  selector:
    app: users
  # type: ClusterIP -> 이렇게 하면 클러스터 내부에서만 통신이 가능하다.
  # type: NodePort -> Node IP 주소로 접근. 하지만 다중 pod/node 환경에서는 pod가 위치한 node가 자주 바뀔 수 있어 번거롭다
  type: LoadBalancer
  ports:
    - protocol: TCP
      port: 8080
      targetPort: 8080
```

- LoadBalancer: 클러스터 외부에서도 접근할 수 있는 IP 주소를 제공.
- pod가 위치한 node와도 독립적인 IP 주소 (매번 새로 생성?)
- users-api > users-app.js에서 `app.listen(8080)`이므로 targetPort도 8080으로 설정

```bash
kubectl apply -f=users-service.yaml

# cloud provider를 쓰는 것이라면 load balancer에 IP 주소가 자동으로 할당된다.
# minikube 환경이기 때문에 이렇게 실행
minikube service users-service
```

```bash
|-----------|---------------|-------------|---------------------------|
| NAMESPACE |     NAME      | TARGET PORT |            URL            |
|-----------|---------------|-------------|---------------------------|
| default   | users-service |        8080 | http://192.168.49.2:32493 |
|-----------|---------------|-------------|---------------------------|
🏃  Starting tunnel for service users-service.
|-----------|---------------|-------------|------------------------|
| NAMESPACE |     NAME      | TARGET PORT |          URL           |
|-----------|---------------|-------------|------------------------|
| default   | users-service |             | http://127.0.0.1:53507 |
|-----------|---------------|-------------|------------------------|
🎉  Opening service default/users-service in default browser...
❗  Because you are using a Docker driver on darwin, the terminal needs to be open to run it
```

무한 버퍼링 (왜 안되지?)

![[2024-03-19_11-50-03.png]]

어쨌든 이 모듈에서 강조하려고 했던 건 service가 k8s의 네트워크에도 중요한 역할을 한다는 것. 애초에 pod에 접근할 수 있게 하는 역할이기 때문.

---

## 230. 하나의 pod 내에 있는 다중 컨테이너

이 이미지를 머릿속에 확실히 넣고 실습 시작!

![[Pasted image 20240319231316.png | 400]]

users-app.js에 있는 코드를 다시 이렇게 고친다.

```javascript
// 26번째 줄
const hashedPW = await axios.get('http://auth/hashed-password/' + password);
// const hashedPW = 'dummy text';

// ...
// 57번째 줄
const response = await axios.get(
'http://auth/token/' + hashedPassword + '/' + password
);
// const response = { status: 200, data: { token: 'abc' } };
```

그리고 환경변수를 이용해서 이렇게 바꾼다.

```javascript
// 26번째 줄
// const hashedPW = await axios.get('http://auth/hashed-password/' + password);
const hashedPW = await axios.get(`http://${process.env.AUTH_ADDRESS}/` + password);

// 58번째 줄
// const response = await axios.get(
//     'http://auth/token/' + hashedPassword + '/' + password
//   );
const response = await axios.get(
    `http://${process.env.AUTH_ADDRESS}/` + hashedPassword + '/' + password
)
```

docker-compose.yaml 에는 환경변수를 추가한다.

```yaml
version: "3"
services:
  auth:
    build: ./auth-api
  users:
    build: ./users-api
    # 이 부분
    environment:
      AUTH_ADDRESS: auth
    ports: 
      - "8080:8080"
  tasks:
    build: ./tasks-api
    ports: 
      - "8000:8000"
    environment:
      TASKS_FOLDER: tasks
```

1. kub-demo-auth 이름으로 Docker hub에 repo를 새로 만든다.
2. 이미지 build하고 push한다.

```bash
cd ../auth-api
docker build -t my_docker_hub_id/kub-demo-auth .
docker push my_docker_hub_id/kub-demo-auth
```

3. users-deployment.yaml에 컨테이너를 추가한다.

```yaml
# users-deployment.yaml
...
spec:
      containers:
        - name: users
          image: my_docker_hub_id/kub-demo-users:latest
        - name: auth
          image: my_docker_hub_id/kub-demo-auth:latest
```

users-service.yaml에서는 따로 건드릴 필요가 없다.
auth API를 외부에 port를 직접 노출시키지 않을 것이기 때문

```bash
cd users-api
docker build -t my_docker_hub_id/kub-demo-users .
docker push my_docker_hub_id/kub-demo-users
```


---
## 231. pod 내부 통신

![[Pasted image 20240319201023.png]]

현재 하나의 pod 안에 두 개의 컨테이너를 통신하려고 실습하는 것이기 때문에, localhost를 사용한다.
users-deployment.yaml 파일에 AUTH_ADDRESS 환경변수의 값을 localhost로 넣는다.

```yaml
# users-deployment.yaml
	...
    spec:
      containers:
        - name: users
          image: my_docker_hub_id/kub-demo-users:latest
          env:
          # 아래 두 줄을 추가한다.
            - name: AUTH_ADDRESS
              value: localhost
        - name: auth
          image: my_docker_hub_id/kub-demo-auth:latest
```

그리고 이걸 적용하면

```bash
cd kubernetes
# 이것만?
kubectl apply -f=users-deployment.yaml
```

![[2024-03-19_20-17-56.png]]

...왜 안될까?


```yaml
# users-service.yaml
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

---
## 232. 이제 pod를 분리해보자: 다중 deployments 생성

이 이미지를 머릿속에 확실히 넣고 실습 시작!

![[Pasted image 20240319231652.png | 500]]


- 사실 Auth API는 "public facing(클러스터 외부에서 직접 접근 가능)" 하지 않아야 한다.
- Task API는 별도의 pod에서 생성하되, Task API를 가진 pod와 User API를 가진 pod에서 모두 접근 가능해야 한다. 즉 pod-to-pod 통신(cluster 내부 통신)이다.

### auth-deployment.yaml 만들기

1. Auth API에 대한 구성 파일을 별도로 만들었기 때문에, Auth API는 Users API와 다른 pod 안에 생성된다.

```yaml
# auth-deployment.yaml. users-deployment.yaml에서 복사해서, 일부만 수정
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
          image: seanshnkim27/kub-demo-users:latest
          env:
            - name: AUTH_ADDRESS
              value: localhost
        - name: auth
          image: seanshnkim27/kub-demo-auth:latest
```

2. Auth API를 위한 service는 아직 존재하지 않는다. -> pod에 접근하기 위한 IP 주소가 매번 바뀔 수 있기 때문에 문제 발생. service 객체를 만들어주자.

```yaml
# auth-service.yaml
apiVersion: v1
kind: Service
metadata:
  name: auth-service
spec:
  selector:
    app: auth
  # type: LoadBalancer
  type: ClusterIP
  ports:
    - protocol: TCP
      # port: 8080
      port: 80
      # targetPort: 8080
      targetPort: 80
```

- auth-api > Dockerfile에 보면 port 번호를 80으로 명시하고 있다(`EXPOSE 80`).
- Auth API를 public facing, 즉 외부에 노출시키지 않을 것이기 때문에 타입을 LoadBalancer에서 ClusterIP로 바꾼다.

---
## 233. IP 주소 & 환경 변수를 사용한 pod-to-pod 통신



