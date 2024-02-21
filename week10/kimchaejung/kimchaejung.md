# 새롭게 알게된 점

## 요약

- 쿠버네티스 환경 설정
- 쿠버네티스 객체 활용

## 개발자가 하는 것과 쿠버네티스가 하는 것

### 내가 직접 하는 것(=== 쿠버네티스가 요구하는 것)

- 클러스터, 노드 인스턴스 생성(워커 + 마스터 노드)
- 쿠버네티스 API server, kubelet과 다른 쿠버네티스 서비스, 소프트웨어를 머신에 설치
- 로드 밸런서, 파일 시스템과 같은 클라우드 서비스 리소스 생성

### 쿠버네티스가 하는 것

- 포드와 같은 객체 관리
- 컨테이너 오케스트레이션
- 배포된 애플리케이션 관리
- 포드 모니터, 재생성, 스케일링
- 설정과 목표에 따라 제공된 클라우드 리소스를 활용

### 쿠버네티스가 하지 않는 것

- 애플리케이션이 요구하는 인프라 관리
  이런 걸 직접할 수 있는 서비스가 별도로 존재

  [ex. Multi Cloud Kubernetes Management Platform](https://www.kubermatic.com/)

- 자체적으로 쿠버네티스의 설정을 그대로 쓸 수 있게 하는 클라우스 서비스 리소스도 존재

  [ex. 관리형 Kubernetes 서비스 | Amazon EKS - Amazon Web Services](https://aws.amazon.com/ko/eks/)

## Kubernetes: 요구 설정 & 설치 단계

- kubectl
  - 클러스터에 명령할 수 있는 툴
  - API server, master node와는 다르다
- cluster
  - 클러스터는 기술적인 인프라
- minikube
  - local에서 k8s 작동시킬 수 있는 툴
    [minikube start](https://minikube.sigs.k8s.io/docs/start/)
  - kubectl, kublet을 대체하는 것이 아니다

## macOS 설정

1. 로컬 머신이 조건에 부합하는지 확인

```bash
sysctl -a | grep -E --color 'machdep.cpu.features|VMX'
```

> m1에서 해당 명령어가 안 먹어서 pass...

2. kubectl 설치

   [참고. Install Tools](https://kubernetes.io/docs/tasks/tools/#install-with-homebrew-on-macos)

```bash
brew install kubectl
```

- 잘 설치됐는지 확인하기

```bash
kubectl version --client
```

3. 컨테이너 또는 가상 머신 매니저 설치

> m1에서 virtualBox, hyperkit도 설치가 안돼서 pass,
> docker가 설치되어 있어서 docker로 하기로 결정

4. minikube 설치

```bash
brew install minikube
```

5. 컨테이너 / 가상 머신 매니저 연결

가상 머신 안에 클러스터 생성하는 과정, 마스터 노드와 마스터 노드가 필요한 소프트웨어 설치

```bash
minikube start --driver=docker
```

6. 설치 확인

```bash
minikube status
minikube dashboard
```

## kubernetes 객체

- 객체는 imperatively 또는 declaratively 생성될 수 있다
  - imperatively: 명령적
  - declaratively: 선언적

### Pod

- 쿠버네티스가 상호작용하는 가장 작은 유닛
- 하나 이상의 컨테이너를 포함한다
- 하나의 포드 당 하나의 컨테이너를 갖는 것이 일반적
- 공유된 리소스를 포함한다(볼륨)
- 기본적으로 내부 IP 주소를 갖는다
  - 여러 컨테이너인 경우 localhost로 서로 통신한다
- AWS의 ECS의 경우 task가 pod와 유사한 개념
- ⭐️ 포드는 ephemeral되게 설계됐다.
  - ephemeral: 수명이 짧다
  - 지속되지 않는다
  - 필요에 따라 시작, 중지, 대체될 것이다
  - 컨테이너 wrapper와 같은 역할이기에 컨테이너의 철학과 닮아 있다
- ⭐️ 포드가 관리될 때 controller가 필요하다

### Service 객체

- 포드를 클러스터 또는 외부적으로 노출시킨다
  - 포드는 기본적으로 내부 IP 주소를 갖는다(이는 포드가 대체될 때마다 변경됨)
    - 그래서 IP 주소가 변경될 때마다 포드를 찾는 것은 어렵다
- 서비스 객체는 포드를 동일한 IP로 그룹화시킨다
- 서비스 객체는 외부에서 포드에 접근할 수 있도록 허용한다

→ 서비스 객체 없이는 포드에 접근, 통신하는 것이 어렵다

### Deployment Object

- 포드 제어 가능
  - desired state를 설정하면 k8s가 실제 state를 변경한다
    - 어떤 포드와 컨테이너가 실행되고 몇 개의 인스턴스를 실행할 것인지 정의한다
- 배포를 중지, 삭제, 롤백 할 수 있다
- 배포가 스케일링 될 수 있다(동적으로, 자동으로)
  - 들어오는 트래픽, CPU 활용도에 따라
    - 바라는 포드들을 필요한 것 만큼 수를 변경할 수 있다

→ 배포 객체가 포드를 관리해주고, 다수 배포 객체를 생성할 수 있다

결국 직접적으로 포드를 제어하는 것이 아니라 원하는 상태를 설정해 배포 객체를 사용한다

## 명령적 접근 방식

- k8s 클러스터에 올릴 이미지 빌드
  ```bash
  docker build -t kub-first-app .
  ```
- 클러스터가 가동 중인지 확인
  ```bash
  minikube status
  >>>>>>>>>>>>>>
  minikube
  type: Control Plane
  host: Running
  kubelet: Running
  apiserver: Running
  kubeconfig: Configured
  ```
- 만약 중지됐다면,
  ```bash
  minikube start --driver=docker
  ```
- 클러스터(마스터 노드)에 instruction 보내기
  스케줄러가 현재 가동 중인 포드를 분석하고 새로운 포드를 위한 최적의 노드를 찾는다
  kubelet이 포드와 컨테이너를 관리한다

  ```bash
  kubectl create
  ```

  ```bash
  Available Commands:
    clusterrole           Create a cluster role
    clusterrolebinding    Create a cluster role binding for a particular cluster
  role
    configmap             Create a config map from a local file, directory or
  literal value
    cronjob               Create a cron job with the specified name
    deployment            Create a deployment with the specified name
    ingress               Create an ingress with the specified name
    job                   Create a job with the specified name
    namespace             Create a namespace with the specified name
    poddisruptionbudget   Create a pod disruption budget with the specified name
    priorityclass         Create a priority class with the specified name
    quota                 Create a quota with the specified name
    role                  Create a role with single rule
    rolebinding           Create a role binding for a particular role or cluster
  role
    secret                Create a secret using a specified subcommand
    service               Create a service using a specified subcommand
    serviceaccount        Create a service account with the specified name
    token                 Request a service account token
  ```

  ```bash
  kubectl create deployment first-app --image=kub-first-app
  kubectl get deployments
  kubectl get pods
  ```

  - 쿠버네티스 클러스터에서 알 수 없는 로컬 이미지이기 때문에 pull error가 뜨는 것

  ```bash
  kubectl delete deployment first-app
  docker tag kub-first-app blcklamb/kub-first-app
  docker push blcklamb/kub-first-app
  ```

  ```bash
  kubectl create deployment first-app --image=blcklamb/kub-first-app
  kubectl get deployments
  kubectl get pods
  ```

  - 이미지 보내기

  ```bash
  minikube dashboard
  ```

- Service 객체 추가

```bash
kubectl expose deployment first-app --type=ClusterIP --port=8080
DEPLOYMENT_NAME
```

- type
  - ClusterIP: 클러스터 내부에서만 접근 가능
  - NodePort: 실행 중인 워커 노드의 IP 주소를 통해 노출됨
  - LoadBalancer: 고유 IP 생성, 들어오는 트래픽을 이 service의 일부인 모든 pod에 고르게 분산
    - 스케일링하여 여러 인스턴스를 생성한다면 문제가 된다
    - 클러스터와 클러스터가 실행되는 인프라가 지원하는 경우에만 사용 가능
- External-IP가 항상 pending인 이유
  - minikube가 로컬에서 돌고 있는 가상 머신이라서
  - 만약 AWS로 로드밸런서를 미리 설정했다면 나왔을 것임
  - 해결 방법

```bash
minikube service first-app
```

> 강사님이랑은 화면이 다르다, 테이블이 두 개가 나옴...!

## 컨테이너 스케일링

```bash
kubectl scale deployment/first-app --replicas=3
```

- `replica` : 포드, 컨테이너의 인스턴스 개수
  - 3 replica는 같은 포드, 컨테이너가 3개 실행된다는 뜻
- 실행되는 pod가 있으면 서비스가 중지되지 않음

## Deployment 업데이트

```bash
kubectl set image deployment/first-app
kubectl set image deployment/first-app kub-first-app=blcklamb/kub-first-app
```

- tag가 달라지지 않으면 변화를 감지하지 못한다!

```bash
docker build -t blcklamb/kub-first-app:2 .
docker push blcklamb/kub-first-app:2
kubectl set image deployment/first-app kub-first-app=blcklamb/kub-first-app:2
```

```bash
kubectl rollout status deployment/first-app
```

## Deployment 롤백

```bash
kubectl set image deployment/first-app kub-first-app=blcklamb/kub-first-app:3
```

- 배포 업데이트가 문제가 발생했을 때, 기존 포드를 중지시키지 않는다, 대신 새로운 포드가 시작되지 않을 것

```bash
kubectl rollout undo deployment/first-app
```

```bash
kubectl rollout history deployment/first-app
kubectl rollout history deployment/first-app --revision=3
kubectl rollout undo deployment/first-app --to-revision=1
```

```bash
kubectl delete service first-app
kubectl delete deployment first-app
```

## 선언적 접근 방식

- 명령적 접근 방식으로는 명령어를 다 외우고 step-by-step으로 실행해야 하기 때문에 번거롭다, docker run과 동일한 맥락의 문제 발생
- `config.yaml` 을 만들어서 실행
- config file이 desired state로 변경하기 위해 적용된다
- Docker compose와 같은 맥락에서 나오게 된 방식
