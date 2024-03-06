### Kubernetes는 인프라를 관리하지 않는다

---

Kubernetes가 하는 일

- **파드 생성 및 관리**
- **파드 모니터링 & 스케일**
- **주어진 자원을 활용하여 목표를 달성**
노드는 개발자가 직접 구생해줘야 한다.
(만일 이것들 조차 해주길 바란다면, K8S 그 이상인 Kubermatic이나 AWS의 EKS와 같은 도구를 활용하면 된다.)

개발자가 하는 일

- **클러스터와 노드 구성**

### Install

---

- *kubectl*
    - **K8S 클러스터를 제어하기 위한 CLI 도구(리소스 관리, 모니터링)**
- *minikube*
    - **K8S 클러스터를 로컬 컴퓨터에서 쉽게 실행할 수 있도록 해주는 도구**
    - **단일 노드 쿠버네티스 클러스터임**
    일반적으로, K8S 클러스터를 운영할 땐 다수의 노드를 활용한다.(마스터노드, 워커노드 등)
    minikube에서는 하나의 노드에서 모든것을 수행 → 학습, 테스트용으로 적합
    
    ```powershell
    minikube start --driver=docker # 도커로 minikube 클러스터 샐행
    minikube dashboard # 웹 대시보드 실행
    ```
    

### Kubernetes는 객체 방식으로 동작한다.

---

→ ***Pods***, ***Deployments***, ***Services***, ***Volume***과 같은 `객체`들을 통해서 동작한다.

→ 우리는 이를 `명령적` 방식과 `선언적` 방식을 통해 생성할 수 있다.

**[Pod]**

- 클러스터의 `가장 작은 유닛`
- Pod는 하나 이상의 `컨테이너`를 실행하고 관리한다.(일반적으론 하나의 컨테이너)
- 컨테이너 뿐 아니라 `볼륨` 같은 리소스를 보유한다.
- Pod는 클러스터의 일부로, 외부와 `통신`할 수 있다. 기본적으로 클러스터의 내부 IP를 할당받는다.
하나의 파드에 있는 여러 컨테이너들은 Localhost를 통해 통신할 수 있다.
- 파드는 `임시적`이다.
파드는 K8S가 필요에 따라 실행 및 중단, 대체 될 수 있는 존재다.
그 과정에서 저장되고 생성된 데이터가 손실 될 수 있다.
(물론, 그 데이터를 영구 소장 하는 방법이 있다)
**이것이 K8S의 의도적인 디자인이다. → 컨테이너의 Stateless의 성격과 비슷**
- 일반적으로 Pod는 `Deployment` 의해 관리되고, 개발자가 직접 관리하지 않는다.
(ex, 여러 노드 중 특정 노드에 파드를 실행시키도록 개발자가 선택하지 않는다. )
→ 즉, 관리의 주체성은 개발자가 아니라, K8S의 `Deployment`가 되는것

**[Deployment]**

- Deployments는 Pods의 `배포 및 확장을 관리하는 객체`
- Deployment는 `요구사항`을 받아 들이고, 이를 요구한대로 `수행`한다.
개발자는 단순히 원하는 것을 정의하고, K8S가 이를 도달한다.
- 수정한 pod가 충돌 했더라도, 당황할 필요가 없다. 
Deployment가 이를 `롤백`하여, 정상 작동했던 deployment로 돌아가서 수행할 수 있다.
- 자동으로 동적인 `Scailing`을 할 수 있다.
(CPU사용량, 특정 트래픽과 같은 매트릭에 의한)

**[Service]**

- Pod는 기본적으로 `내부 IP`를 가지고 있다. 
하지만 외부에서 접근할 수는 없으며, Pod가 중단되고 실행될 때 마다 다른 IP를 가지게 된다.
- Pod를 외부로 공개하기 위해 `네트워크 인터페이스`를 제공
- Service는 동일한 애플리케이션(Pod)들을 그룹화 하여, `공유 IP`를 제공해 준다.
해당 IP는 변경되지 않기에, 이를 통해 외부에서도 접근이 가능해 진다.
- 또한 `Loadbalancing` 역할도 해준다.
그룹화된 Pod들 사이에 네트워크 트래픽을 자동으로 분산시킨다.

### Example

---

→ Kubernetes를 사용하더라도, Docker를 활용해 `이미지`를 생성하는것 까지는 따로 진행 해야 한다. 
다만, `컨테이너`를 Docker를 활용해 직접 build하지는 않는다.

- docker로 이미지를 빌드하고, 이를 deployment객체로 생성하여, 클러스터에 보낼것이다.
(명령적 접근 방식임)
    
    ```powershell
    docker build -t kub-first-app . # dockerfile을 image로 build한다.
    
    minikube start --driver=docker # docker 기반으로 클러스터 실행
    minikube status # 클러스터 실행 여부 확인
    
    kubectl create deployment first-app --image=kub-first-app 
    # kub-first-app 이미지에 대한 depolyment 객체 생성 
    
    kubectl get deployment 
    # 여기에 연결했던 클러스터에 deployment가 얼마나 있는지 확인
    # kubectl은 minikube에 의해 자동으로 minikube에 연결되도록 구성되어 있음
    # 일단, kub-first-app이라는 이미지는 로컬에 있고, 클러스터는 도커 환경이라 이미지를 찾을 수 없다고 함
    
    kubectl get pods # deployment에서 생성된 모든 것을 확인
    
    kubectl delete deployment first-app
    # first-app이라는 deployment 삭제
    
    docker tag kub-first-app wjdrbs51/kub-first-app
    docker push wjdrbs51/kub-first-app
    # 이미지를 도커헙에 푸시(클러스터가 로드할 수 있도록)
    
    kubectl create deployment first-app --image=wjdrbs51/kub-first-app 
    # 이제 도커헙에 저장된 이미지를 불러오도록 수정
    
    kubectl get deployment # deployment 상황 확인
    
    minikube dashboard # 대시보드로 상황 확인
    ```
    
    ![Untitled](https://prod-files-secure.s3.us-west-2.amazonaws.com/d988c03e-a2c8-4c2d-99ce-dbe44c76f65d/0c6c00b7-8c31-47be-b63b-9569425d07b8/Untitled.png)
    
    → deployment 객체를 생성하여, 파드가 실행된 상황을 확인할 수 있다.
    

### Kubectl 작동 방식

---

`kubectl create deployment --image ...` 

- `Deployment` 객체를 생성한 다음, 클러스터에 있는 `마스터노드(Control Plane)`로 전송한다.
- 마스터노드의 `Scheduler`는 현재 실행중이 Worker Node들을 분석하며, deployment객체로 넘어온 pod가 실행될 가장 적합한 `Worker Node`를 선정한다.
- 선정된 Worker Node에서는 `kubelet`이 pod를 생성, 관리하게 된다.

![Untitled](https://prod-files-secure.s3.us-west-2.amazonaws.com/d988c03e-a2c8-4c2d-99ce-dbe44c76f65d/8a3648a7-7fdc-4c21-8cb8-c6d5c3fdcbef/Untitled.png)

- 여기서 용어 정리(Control Plane과 MasterNode 용어를 교차해서 많이 말함)
    - Control Plane
    클러스터 관리 작업을 담당하는 구성 요소들의 집합체로, API서버, 스케줄러, 컨트롤 매니저 등이 있다.
    - MasterNode
    컨트롤 플레인 구성 요소들이 실행되는 물리적 혹은 가상의 머신을 의미.

### Service로 Deployment를 노출시켜 보자

---

```powershell
kubectl expose deployment first-app --port 8080 --type LoadBalancer
# kubectl expose로 pod를 노출
# --port로 노출할 포트 설정
# --type는 LoadBalancer로, 이 service에 대한 고유한 IP를 생성해준다. 또한 LoadBalancer 기능을 해줌
# NodePort로 워커노트의 IP 주소를 통해 노출을 한다는 뜻으로 외부에서 접속 가능
# default값인 ClusterIP로 클러스터 내부에서만 연결할 수 있음을 뜻함  

kubectl get services
# 결과값에서 EXTERNAL-IP가 pending인 이유는, minikube는 현재 도커로 가상화된 머신에서 돌고 있는 중이기 때문
# 그래서 로컬과 연결해줄 필요가 있음

minikube service first-app
```

### 컨테이너가 충돌 된다면,(죽는다면?)

---

- 컨테이너가 충돌 되어도, 재 시작된다.
- deployment를 생성했기 때문이다.

```powershell
kubectl get pods
# 현재 상태가 어떤지, 재 실행 횟수가 어떤지 파악할 수 있다. (물론 대시보드에서도 가능)
```

- 그런데 충돌 되고, 재 시작까지 시간이 좀 걸린다.

### 스케일링 하는 방법

---

```powershell
kubectl scale deployment/first-app --replicas=3
# 3개의 동일한 pod를 실행

kubectl get pods
# NAME                         READY   STATUS              RESTARTS        AGE
# first-app-68cbbcff87-cnh7w   0/1     ContainerCreating   0               5s
# first-app-68cbbcff87-j5mt4   1/1     Running             4 (5m56s ago)   47h
# first-app-68cbbcff87-qn56b   0/1     ContainerCreating   0               5s

kubectl scale deployment/first-app --replicas=1
# 다시 하나로 줄일 수 있다.
```

- 여기서 충돌 시키고, 재 접속하면 잘 접속 된다.
재 시작이 빨리 되서 그런게 아니라, 로드 밸런서가 유입되는 트래픽을 정상 작동중인 pod로 보냈기 때문.
그 시간동안 죽어버린 pod는 재 시작이 이루어진다.
- 근데 왜 나는 한번에 3 pod가 다 죽어버리지?..

### Deployment 업데이트하기

---

→ 이미지를 수정하여서, 수정된 이미지를 사용할 수 있도록 Deployment를 업데이트 해보자

```powershell
# 코드를 수정하고
docker build -t wjdrbs51/kub-first-app .
docker push wjdrbs51/kub-first-app

kubectl set image deployment/first-app kub-first-app=wjdrbs51/kub-first-app
# 이럼에도 아무런 변화가 일어나지 않는다.
# 이미지에 변화된 태그나 버전이 있어야 바뀐다.

docker build -t wjdrbs51/kub-first-app:2 .
docker push wjdrbs51/kub-first-app:2

kubectl set image deployment/first-app kub-first-app=wjdrbs51/kub-first-app:2
# 이제 변경사항이 반영되어 있을 것이다.
# minikube dashboard로 확인해 보자
```

***→ 컨테이너의 소스코드를 변경하고, 쿠버네티스에 반영하려면 쿠버네티스를 트리거 하기 위해 이미지 버전을 다르게 변경해놓아야 한다.***

### Deployment 롤백 & 히스토리

---

- 만약 deployment를 잘못 수정해서, 새로 실행이 잘 되지 않는다면?
    
    ```powershell
    kubectl set image deployment/first-app kub-first-app=wjdrbs51/kub-first-app:3
    # 일부로 없는 이미지를 set 해봤다.
    ```
    
    ![Untitled](https://prod-files-secure.s3.us-west-2.amazonaws.com/d988c03e-a2c8-4c2d-99ce-dbe44c76f65d/6c20b916-ec13-4d67-8250-d49d5feb7afc/Untitled.png)
    
    - 역시나 잘 실행 되지 않는다.
    - 하지만, 이전에 잘 작동하던 deployment가 사라지지 않고 대기 중이다.
    (쿠버네티스의 장점이라 할 수 있다.)
    - 하지만 저 deployment는 계속해서 업데이트 되지 않고 시도만 계속 반복될 것이다.
    
- 잘못된 deployment를 undo 시키자
    
    ```powershell
    kubectl rollout undo deployment/first-app
    ```
    
    ![Untitled](https://prod-files-secure.s3.us-west-2.amazonaws.com/d988c03e-a2c8-4c2d-99ce-dbe44c76f65d/2702a3ff-9553-4305-b9ed-5a7a89d933a0/Untitled.png)
    
    - 다시 정상 작동하는 deployment만 남아있다.
    
- 만약 현재 보다 더 이전의 deployment로 돌아가려면?
    
    ```powershell
    kubectl rollout history deployment/first-app
    # 이전의 히스토리 버전들을 보여준다.
    
    kubectl rollout history deployment/first-app --revision=1
    # --revision으로 원하는 버전을 명시해 주면, 더 자세한 사항을 볼 수 있다.
    
    kubectl rollout undo deployment/first-app --to-revision=1
    # rollout undo에다가 --to-revision으로 특정 버전을 명시해 주면, 그 버전으로 돌아간다.
    ```
    

### 객체 삭제하기

```powershell
kubectl delete service first-app
kubectl delete deployment first-app
```

### 명령적 vs 선언적

---

- 명령적
    - 모든 명령문을 다 숙지하고 있어야 한다.
- 선언적
    - docker compose와 같이 yaml 파일에 한번에 작성하고, 실행할 수 있다.
    - 해당 파일에 우리의 요구사항을 정의하기만 하면 끝이다.

### 배포 구성 파일 생성

---

```yaml
apiVersion: apps/v1 # 버전
kind: Deployment  # 생성하려는 쿠버네티스 객체의 종류를 명시
metadata: # 부가 정보 필요
	name: second-app-deployment
spec: # 이 파일의 핵심!
```