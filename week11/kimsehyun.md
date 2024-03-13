
## 쿠버네티스 개요
### 쿠버네티스가 하지 않는 것, 사람이 해야 하는 것
1. 클러스터와 노드 생성은 사람이 해야 한다.
2. 인프라를 자동으로 생성해주는 서비스가 아니다.
3. Kubernetes API Server. kubelet, node에 필요한 Kubernetes 서비스/소프트웨어 등은 사용자가 직접 알아서 설치해야 한다.
4. cloud provider에서 제공해주는 load balance나 file system의 생성도 Kubernetes가 알아서 해주지 않는다.

요지는, Kubernetes는 서버 관리자 역할을 하지 않는다는 것!
하지만 사람은 언제나 더 편한 것을 추구하고 시장은 그 니즈를 절대 놓치지 않는다.
### 예시 1. AWS EKS(Elastic Kubernetes Service) 

소개 글을 보자.

> Amazon Elastic Kubernetes Service(Amazon EKS)는 AWS 클라우드와 온프레미스 데이터 센터에서 Kubernetes를 실행하는 데 사용되는 관리형 Kubernetes 서비스입니다. 클라우드에서 Amazon EKS는 컨테이너 예약, 애플리케이션 가용성 관리, 클러스터 데이터 저장 및 다른 주요 작업을 담당하는 Kubernetes 컨트롤 플레인의 가용성과 확장성을 관리합니다. Amazon EKS를 사용하면 AWS 네트워킹 및 보안 서비스와의 통합뿐만 아니라 AWS 인프라의 모든 성능, 규모, 신뢰성 및 가용성을 활용할 수 있습니다 온프레미스에서 EKS는 완벽하게 지원되는 일관된 Kubernetes 솔루션을 제공합니다. 통합된 도구를 사용하여 AWS Outposts, 가상 머신 또는 베어 메탈 서버에 간편하게 배포할 수 있습니다. (출처: https://aws.amazon.com/ko/eks/)

1. Kubernetes 관리
2. AWS 네트워킹 및 보안 서비스(기존 Kubernetes만으로는 할 수 없고, 사람이 직접 설정해야 했던 것)
3. AWS 인프라를 사용할 수 있음


### 예시 2. Kubermatic
Kubermatic Kubernetes Platform(KKP)은
- infrastructure-agnostic: 인프라 구성 방식(on-premise, hybrid 또는 multi-cloud 등)을 자유롭게 할 수 있고
- kubernetes의 multi-cluster 관리를 자동화해서 시간과 비용을 줄여준다고 한다.
- TMI이지만, 아직 전세계적으로 많이 쓰는 플랫폼은 아닌 듯. 독일 스타트업이라 강의에서 언급한 게 아닐까..?(강사 분도 독일 출신)

그 외에도 DigitalOcean Kubernetes, Red Hat OpenShit 뿐만 아니라 (이 플랫폼들이 인프라 구축까지 해주는지는 조사 필요) Azure Kubernetes, Google Kubernetes Engine 등 빅3 클라우드 업체는 모두 Kubernetes 관리 플랫폼을 제공하고 있다.

## 쿠버네티스 요구 설정 및 설치 단계

### 1. 클러스터
### 2. kubectl(=kube control)
- 클러스터에 명령을 보내기 위한 일종의 툴, 소통 장치
- master node와 다르다. master node는 클러스터 내에 존재하며, 사용자가 내린 명령을 실행에 옮기고 잘  실행되었는지 확인하는 역할을 한다.
- kubectl = 대통령(통수권자)이라면, master node는 대통령에게 받은 지시를 실행에 옮기는 장군이라고 생각하자.
- 로컬에 설치하는 툴이다.

## Minikube
- minikube를 사용해서 데모 클러스터를 하나 만들어보자.
- minikube를 사용하지 않더라도 kubectl은 로컬에서 반드시 필요하다.

실행 명령어

```bash
brew install minikube
```


```bash
kubectl version

# WARNING: This version information is deprecated and will be replaced with the output from kubectl version --short.  Use --output=yaml|json to get the full version.
```

> “kubectl version” 명령으로 버전 정보 조회시 나타나는 메세지 “The connection to the server localhost:8080 was refused - did you specify the right host or port?”는 아직 kubeconfig 파일을 설정하지 않아서 발생하는 에러입니다. 지금 단계에서는 무시해도 되는 메세지입니다. (출처: https://feellikeghandi.tistory.com/59)


### virtual machine 설치?

---

## Kubernetes 객체(리소스) 이해하기

Kubernetes는 **객체(resource)** 로 이루어져 있다. 그렇다면 여기서 말하는 객체란 무엇인가?
- 명령을 내려서 어떠한 역할을 수행하는 객체를 생성한다.

- Pods
- Deployments
- Services
- Volume

객체는 두 가지 방식으로 만들어질 수 있다.
1. Imperatively
2. Declaratively


### Pod
- Kubernetes가 다루는 가장 작은 단위
- 하나 또는 여러 개의 컨테이너를 포함할 수 있다.
- 가장 흔한 use-case는 "하나의 pod에 하나의 컨테이너"이다.
- 컨테이너뿐만 아니라 volume과 같은 공유 자원을 포함한다.
- 클러스터의 다른 객체와 통신하기 위해 cluster-internal IP 주소를 default로 가지고 있다.
- 만약 pod 안에 여러 개의 컨테이너가 있다면 이 컨테이너들끼리도 통신하기 위해 local host 주소도 가지고 있다.

1. Pod는 한정된 생명 주기가 존재한다(ephemeral): pod가 삭제되거나 replace되면 pod가 가지고 있던 자원을 모두 잃어버린다. (이건 컨테이너와 같은 속성)
2. 결국 Kubernetes는 배포 및 관리를 자동화하고자 쓰는 것이기 때문에 수동으로 pod를 만들고 실행할 이유가 없다. 대신 Kubernetes가 pod의 생성 및 관리를 알아서 하게 해야 한다. 이때 pod를 사용자 대신 생성하고 관리하는 객체가 controller object, 즉 "Deployment" object이 필요한 이유다.

### Deployment Object
1. 사용자가 desired state(되기를 바라는 상태, 희망 상태)를 명시하면, 쿠버네티스는 그 desired state에 도달할 수 있도록 작동한다. 
2. deployments는 중지되거나 삭제, 롤백될 수 있다.
3. auto스케일링이 가능하다. (원하는 만큼 pod 개수를 늘리거나 줄일 수 있다)

### Desired State
- 다다르고 싶은 상태를 명시 -> Kubernetes는 그 상태에 도달하기 위해 알아서 할 것이다.
- 이렇게 하면 사용자가 직접 pod를 만들고 worker node에 배치하는 대신, Kubernetes가 알아서 할 수 있다는 뜻
- roll back이 쉬워진다(왜?). 에러가 발생하면, 코드 고치고 pod를 직접 중단한 다음 replace하는 대신 그냥 이전 deployment object로 가서 새 코드로 다시 시작하면 되기 때문?
- autoscaling이 가능하다.

예를 들어 앱 배포를 하는데 트래픽이나 CPU utilization이 많이 증가하면 Kubernetes가 자동으로 pod를 더 생성하고 container instance 개수를 늘린다(scaling, autoscaling).

---

## 실습: Deployment Objects

- `kubeectl` 명령어는 항상 로컬에서 작동한다.
- kubernetes 클러스터에 명령을 보내는 명령어다.
- `kubectl help` 명령어로 다양한 kubectl 명령어를 볼 수 있다.
- `kubectl create` 만 치면 어떤 걸 create할지 목록을 확인할 수 잇다.

![[2024-03-04_13-38-34.png]]

```bash
# first-app이라는 이름의 deployment 객체를, kub-first-app이라는 이름의 이미지를 이용해서 생성
kubectl create deployment first-app --image=kub-first-app
```

참고로, 이미지가 없다면 여전히 도커를 사용해서 이미지를 미리 빌드해놔야 한다.

```bash
docker build -t kub-first-app .
```

Docker Hub에 내 이미지를 푸쉬하고 나서,

```bash
kubectl create deployment first-app --image=my_docker_hub_ID/repository_name
```

대시보드 기능을 이용하면 웹페이지로 현재 클러스터의 상태를 확인할 수 있다.

```bash
kubectl dashboard
```


![[Pasted image 20240304141901.png]]

그런데 이 명령어를 실행할 때 뒷단에서는 어떻게 돌아가는 걸까?

```bash
kubectl create deployment --image
```

1. 위에 명령어를 실행할면 자동으로 deployment object를 쿠버네티스 클러스터(master node, control plane에)에 보낸다.
2. Scheduler: master node에서는 이 스케쥴러가 현재 실행 중인 pod를 분석해서 어느 node에 배치할지(최적의 후보를 찾는 과정) 결정한다.
3. Kubelet: worker node에서는 kubelet service가 있는데, worker node에서 pod를 관리하고 pod 안의 컨테이너를 실행하고 pod의 health를 점검하는 역할을 한다.


---
## Service Object이란?
사실 클러스터 입장에서는 pod를 직접 접근할 수가 없다. pod는 각자 자기의 내부 IP를 default로 가지고 있는데, 이 IP 주소는 pod가 교체될 때마다 매번 바뀐다. 그리고 pod가 삭제되거나 새로 생성되는 건 자주 있는 일이다.

따라서 IP 주소만으로 pod를 접근하는 건 곤란하다. 대신, service 객체는 이 pod들을 그룹으로 묶은 다음 공유 IP 주소를 할당한다.
또 service는 pod를 외부(클러스터 외부)에서도 접근할 수 있게 허용한다. default는 internal only이다.

### service object 생성하기
마찬가지로 `kubectl` 를 이용해서 생성할 수 있다.

하지만 kubectl expose 명령어를 이용해서, deployment로 만든 pod들을 바로 접근가능하게 만들 수 있다. expose하는 거니까 포트번호는 꼭 지정해줘야 한다.

```bash
kubectl expose deployment first-app --type=ClusterIP --port=8080
```

type도 설정할 수 있는데, ClusterIP로 설정하면 클러스터 내부에서만 접근이 가능하다. 근데 우린 외부에서도 접근 가능하게 설정하고 싶으니까

```bash
kubectl expose deployment first-app --type=NodePort --port=8080
```

```bash
kubectl expose deployment first-app --type=LoadBalancer --port=8080
```

요렇게 LoadBalancer로 설정하면, service 객체가 사용할 수 있는 고유한 주소를 만들고 load balancing 기능까지 수행한다.
(모든 상황에서 Load Balancer가 다 적용 가능한 건 아님. 클러스터나 인프라가 load balancer를 지원해야)

![[2024-03-04_15-25-15.png]]

kubectl get services 명령어로 서비스 상태를 확인해보면, 내부 IP 주소랑 외부 IP 주소를 확인할 수 있다. 내부 IP 주소는 쓸데없고 외부 IP 주소도 현재 minikube 환경이라 \<pending\>으로만 뜨는데,

```bash
minikube service first-app
```

service 명령어로 deployment 객체(first-app라고 이름지은)에 접근할 수 있다.

![[2024-03-04_15-31-07.png]]

아차. Docker Hub에 이미지 푸쉬하고 나서 deployment를 새로 만들어줘야 하는데 안했다.

기존 deployment 객체를 삭제하고 나서, 다시 새로 만들자.

```bash
# 기존 deployment인 first-app를 삭제
kubectl delete deploy first-app
# 다시 새로 만들어
kubectl create deployment first-app --image=seanshnkim27/kub-first-app

# 배포 상태를 확인
kubectl get deployments 
```

![[2024-03-04_15-38-46.png]]

다시 minikube + service 명령어 조합해서 입력하면

```bash
minikube service first-app
```


![[2024-03-04_15-44-32.png]]

로드된 웹페이지(주소: 테이블에 적힌 그대로, https://127.0.0.1:64672)를 확인할 수 있다.

### deployment, service 객체 삭제하기
deployment, service를 삭제하는 법은 간단하다.

```bash
kubectl delete service service_name
kubectl delete deployment deployment_name
```


---
## Imperative vs. Declarative

지금까지 한 명령어는 **imperative**한 방식이었다. 즉, 쿠버네티스가 해야 할 행동을 하나씩 지시를 내려야 한다. 물로 관련 명령어를 착실히 외워서 매번마다 그 명령어를 쓸 순 있겠지만, 이렇게 하면 번거롭고 명령어를 외우기도 벅차다.

대신에 어떤 설정 파일을 만들고 그걸 쿠버네티스에 전달만 해주면 알아서 클러스터를 내가 원하는 상태(desired state)로 조정해줄 수 없을까?
-> 이러한 방식을 **declarative**하다고 한다. 
-> Docker compose와 유사한 개념이다.


## 197. Declarative 방식으로 config 파일 생성하기

- yaml 파일로 작성한다.
- 다음 4가지 상위 요소는 필수다: `apiVersion`, `kind`, `metadata`, `spec`

```yaml
# 4가지 기본 구성요소. 하나라도 빠뜨려서는 안된다.
apiVersion: apps/v1
kind: Deployment
metadata:
	name: second-app-deployment
spec:
	...
```


---

## 198. Pod와 spec 추가

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
	name: second-app-development
spec:
	replicas: 2
```

- replica로 생성할 pod 개수를 명시할 수 있다.
- replicas 설정이 없으면, 기본으로 1개의 pod를 생성한다.


```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
	name: second-app-development
spec:
	replicas: 2
	template:
		# kind: Pod <- 따로 명시할 필요가 없고, 할 수도 없다
		metadata:
			labels:
				app: second-app
		spec:
			containers:
			 - name: second-node
			   image: my_docker_hub_ID/repository_name:my_tag
			 - name: second-node_v2
			   image: ...
```

- deployment과 별개로 template로 명시할 pod도 별개의 object이므로 metadata를 적는다.
- spec 아래에 containers로, 해당 pod가 포함하는 컨테이너(들)를 적을 수 있다.
- image에는 이미지 repository를 적는다.


이렇게 k8s 설정 파일을 만들었다면, 이 설정 파일은 이 명령어로 적용하면 된다.

```bash
kubectl apply -f=deployment.yaml
```

하지만 실행하면 `missing required field "selector"` 에러가 발생한다.


---
## 199. Label 및 Selector로 작업하기

```yaml
spec:
	replicas: 2
	selectors:
		matchLabels:
			app: second-app
			tier: backend
```

### selector
- selector = 선택하는 것 -> 무얼, 왜 선택하는가?
	- 사용자에게 유용한, 또는 의미있다고 간주되는 리소스(예를 들어 pod)
	- 구체적으로 어떤 경우에 특정 리소스를 선택해야는가? 
- 이런 걸 강의에선 설명 안해줘서 아쉽다 ()

### Label: 무엇으로(how) 식별하는가?
- 그럼 어떤 리소스를 '특별 관리'할지 선별해야 하는데, 이때 기준이 되는 게 바로 label이다.
- 위와 같이 selector: matchLabels에 app은 second-app, tier는 backend로 명시했다면 해당 label을 가진 pod만 deployment 객체가 관리한다.
- label selector에는 equality-based(= 등호 관계로 정의되는)와 set-based(집합) 2가지로 나뉜다.


---

## 200. Declarative한 방식으로 service 만들기

- service는 pod들을 클러스터 또는 외부 세계에서 접근 가능하도록 노출(expose)시키는 역할을 한다고 했다.
- service는 deployment과 달리 matchLabels을 쓰지 않고 labels로 직접 명시한다.

```yaml
apiVersion:
kind: Service
metadata:
	name: backend
spec:
	selector: 
		app: second-app
	ports:
		- protocol: 'TCP'
		  port: 80
		  targetPort: 8080
	type: LoadBalancer
```

- deployment로 만든 pod라고 해도 'second-app'라는 app을 가진 pod는 service에 의해 노출된다.
- NodeType 대신 LoadBalancer를 쓰는 이점이 더 크다.

### Declarative 방식의 장점
- 업데이트할 때마다 일일이 명령어를 반복할 필요가 없다.
- 명령어 입력할 때마다 발생할 수 있는 휴먼 에러(맞춤법, 누락 등) 일어날 일도 없고
- 구성 파일을 공유하기도 쉽다.
- 클러스터를 어떻게 구성했는지 설계 정보가 그대로 저장되어 있기 때문에 그 자체로 훌륭한 문서가 된다.

---

## 201. 리소스 업데이트 및 삭제

declarative한 방식으로 구성한 리소스를 어떻게 업데이트할 수 있을까?

1. 구성 파일을 수정한다.
2. `kubectl apply -f=deployment.yaml` 명령어를 실행한다.

declarative한 방식으로 구성한 리소스를 어떻게 삭제할 수 있을까?

```bash
kubectl delete -f=deployment.yaml, service.yaml
```

또는

```bash
kubectl delete -f=deployment.yaml -f=service.yaml
```

이렇게 하면 yaml 파일 자체를 삭제한다는 뜻이 아니라, 그 yaml 파일로 구성한 리소스를 삭제한다는 뜻이다.

---

## 202. 다중 vs. 단일 config 파일

deployment.yaml과 service.yaml 파일로 쪼갰던 걸 하나로 합쳐서 사용할 수도 있다.

```yaml
# service.yaml 내용 (이게 위에 먼저 온다)
---
# deployment.yaml 내용
```

`---`로 구분하면 된다.

- 사실 service 정보를 먼저, 즉 구성 파일 위에 배치하라고 하는데 그 이유를 잘 이해 못했다.

```bash
kubectl apply -f=master-deployment.yaml
```

하나의 파일에 service와 deployment를 통합하려면 ---로 구분하되 한 파일로 같이 쓰면 된다.


---
## 203. Selector와 Label에 대한 추가 정보

selector는 여러 종류가 있다.

- `matchLabels`
- `matchExpressions`

### matchExpressions

```yaml
...
matchExpressions:
	- {key: app, operator: In, values: [second-app, first-app]}

```

matchExpressions는 더 유연한 selector 기능을 제공한다.


### delete 옵션에 label 명시하기

label로 어떤 리소스만을 특정해서 삭제할지도 정할 수 있다.

```bash
kubectl delete -l group=example
```




---

## 부록: YAML in Kubernetes

항상 k8s 설정 파일은 항상 요 4가지 top level 필드를 포함한다.

```yaml
# pod-definition.yaml
apiVersion: v1

kind: Pod
metadata:
	name: myapp-pod
	labels:
		app: myapp
		type: front-end
spec:
	containers:
		- name: nginx-container
		  image: nginx

```

- metadata 아래에는 k8s가 지정한 특정 키만 넣을 수 있다(예: name, labels)
- label을 붙이는 이유는? 
	-> 앱을 배포했다고 가정하자. 근데 앱 규모가 꽤 커서 돌리고 있는 pod 개수가 수백 개라고 상상해보자. 그럼 이 pod들 중 어떤 게 frontend 담당이고 어떤 게 backend 담당인지 어떻게 구분할 수 있는가? 

- spec은 딕셔너리고, spec 안에 어떤 컨테이너를 배포할지 입력한다.

```bash
kubectl create -f pod-definition.yaml
```

- 이미지 이름을 검증(validate)하지는 않는다. -> nginx-container라고 이름짓든, 아무렇게나 이름지어도 에러 발생시키지 않는다
- 반대로 kind 필드 같은 경우는 k8s에서 맞게 썼는지 검증한다.

### yaml 관련 유의사항

```yaml
# 에러 발생 예시
...
spec:
	containers:
		- name: nginx-container
	    - image: nginx
```

```yaml
# 올바른 예시
...
spec:
	containers:
		- name: nginx-container
		  image: nginx
```

출력 결과:

```yaml
# 첫번째 
{'spec': {'containers': [{'name': 'nginx'}, {'image': 'nginx'}]}}

# 두번째
{'spec': {'containers': [{'name': 'nginx', 'image': 'nginx'}]}}
```
