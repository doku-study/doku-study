# Kubernetes에서 Pod간, Container간 통신하는 방법을 알아보자

## User, Auth, Task API에 대한 다양한 아키텍처로 실습

### User API를 위한 Pod

[User Deployment]

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
					image: wjdrbs51/kub-demo-users
```

[User Service]

- service의 역할 리마인딩!
    1. 항상 변경되지 않는 안정적인 주소를 제공해 준다.
    2. 외부 세계 엑세스를 가능하도록 한다.

```yaml
apiVersion: v1
kind: Service
metatdata:
	name : users-service
spec:
	selector:
			app: users
	type: LoadBalancer
	ports:
		- protocol: TCP
		  port: 8080 
		  targetPort: 8080
			
```

## 이제 User와 Auth를 네트워크 연결 하자

### 우선 User와 동일한 파드에 Auth 컨테이너를 만든다.

[User & Auth Deployment]

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
					image: wjdrbs51/kub-demo-users:latest
				- name: auth
					image: wjdrbs51/kub-demo-auth:latest
```

- Service 파일은 따로 수정해주지 않을것이다. Auth는 Service로 인해 외부로 공개되길 원하지 않기 때문

### User가 Auth에 보내는 API주소는 무엇으로 작성해야 할까??

pod 내부 통신의 경우, 2개의 컨테이너가 동일한 pod에서 실행되는 경우 `localhost`를 사용하면 된다.

즉, 동일한 pod에서 실행중인 다른 컨테이너에 요청을 보내려 한다면, localhost를 사용하면 된다. 

[User & Auth Deployment]

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
					image: wjdrbs51/kub-demo-users:latest
					env:
						- name: AUTH_ADDRESS
							value: localhost
				- name: auth
					image: wjdrbs51/kub-demo-auth:latest
```

### 이제 여러 Pod간 통신을 알아보자

[User  Deployment]

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
					image: wjdrbs51/kub-demo-users:latest
					env:
						- name: AUTH_ADDRESS
							value: localhost
```

[Auth  Deployment]

```yaml
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
					image: wjdrbs51/kub-demo-auth:latest
```

[User Service]

[Auth Service]

```yaml
apiVersion: v1
kind: Service
metatdata:
	name : users-service
spec:
	selector:
			app: users
	type: LoadBalancer
	ports:
		- protocol: TCP
		  port: 8080 
		  targetPort: 8080
			
```

```yaml
apiVersion: v1
kind: Service
metatdata:
	name : auth-service
spec:
	selector:
			app: auth
	type: ClusterIP
	ports:
		- protocol: TCP
		  port: 80 
		  targetPort: 80
			
```

- type를 `ClusterIP`로 해준 이유는, 다른 Pod와 통신하기 위해 고정 IP를 제공 받기는 하지만, Auth pod가 외부로 공개되길 원치 않아서이다. 
즉, 내부 클러스터에서만 공개된다.
***(ClusterIP 또한 로드밸런서를 지원해 준다.)***

### Auth Service의 type를 ClusterIP로 함으로써, 클러스터 내부에서만 접근 할 수 있도록 해주었다. 그렇다면, 이 Auth에는 어떻게 접근할 수 있을까?

1. `kubernetes get services`를 통해 Auth Service의 `ClusterIP` 주소를 찾아 넣을 수 있지만 불편하다.
2. kubernetes에 의해 자동으로 생성되는 환경변수를 기입하자
    
    `auth-service.yaml`에 의해 생성된 IP에 연결하기 위해 `AUTH_SERVICE_SERVICE_HOST` 환경 변수를 사용할 수 있다.
    
3. Pod간 통신에 DNS를 적용시킬 수 있다.
(쿠버네티스의 내장 CoreDNS기능)
    
    
    [User Deployment]
    
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
    					image: wjdrbs51/kub-demo-users:latest
    					env:
    						- name: AUTH_ADDRESS
    							value: "auth-service.default"
    ```
    
    - 환경 변수로 받는 IP에 Auth의 “ `Service 파일 이름` + `.` + `네임스페이스` ”를 작성하면 된다.
    

### 이제 task-api를 위한 pod를 생성해서, 나머지 통신 구성을 해보자.

[Task Deployment]

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
	name: users-deployment
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
					image: wjdrbs51/kub-demo-tasks:latest
					env:
						- name: AUTH_ADDRESS
							value: "auth-service.default"
						- name: TASKS_FOLDER
							value: tasks
```

[Task Service]

```yaml
apiVersion: v1
kind: Service
metatdata:
	name : tasks-service
spec:
	selector:
			app: tasks
	type: LoadBalancer
	ports:
		- protocol: TCP
		  port: 8000 
		  targetPort: 8000
			
```

### K8S로 프론트엔드  배포하기

- 우선 로컬에서 실행되는 프론트엔드도, K8S의 클러스터 내부의 백엔드 애플리케이션과 통신이 가능하다.
- 프론트엔드 이미지를 K8S의 Pod로 올리기위한 deployment와 service는 다른 pod와 비슷하다.
- 프론트엔드 이미지 내에서 API주소를 하드코딩 하지 않기 위해 → 리버시프록시 활용
    
    [nginx.conf]
    
    ```yaml
    server{
    	listen 80;
    	location /api {
    		proxy_pass http://-.-.-.-:32140; # /api로 요청하면 해당 주소로 리다이렉션 됨
    	}	
    }
    ```
    
    - 하지만, 현재 클러스터 내에서 컨테이너 내부에서 해당 주소로 리다이렉션 되는 것으로, 에러가 발생한다. 
    즉, 브라우저에서 실행되어 클러스터 외부에서 접근하는게 아닌, 클러스터 내부의 컨테이너에서 접근하는 것으로, 연결을 하지 못하는 것이다.
    즉, 해당 주소로 접근하는 주체가 외부냐, 내부냐의 차이점에서 나오는 에러
    - 우리는, `http://-.-.-.-:32140`를 K8S 내의 도메인 주소인 `http://task-service.default:8000/`로 연결할 수 있다. → Pod끼리 통신하기 위한 방법 참고하기
    - 리버시 프록시의 장점은, 브라우저에서 실행되는 앱이라 할 지언정, 해당 코드는 클러스터 내부에서 작동 하므로, 도메인 이름의 할당이나 클러스터 관리 IP와 같은 요소들을 활용할 수 있다.

### 느낀점

1. pod간 통신을 할때, 쿠버네티스에서 알아서 환경변수를 만들어 주기는 하는데, 그 변수를 활용하려면 docker 이미지를 빌드하기 전, 이미 통신하려는 pod의 service의 이름을 알고 있어야 하는것 같다.
개인적으로 불편해 보인다.

→ 그래서 나는 3번째 방법인 CoreDNS를 활용하여 접근하는것이 편해 보이는데, 어떻게들 생각하는지?