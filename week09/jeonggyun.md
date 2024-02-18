# K8S

### Kubernetes란?

---

- 컨테이너화된 애플리케이션을 자동으로 `배포`하고 `Scailing`해주며, `관리`해주는 오픈소스
    - 기존의 컨테이너가 다운되거나 문제가 생겼을 때, 새로운 컨테이너를 재 실행
    - 들어오는 큰 트래픽을 컨트롤하기 위해, 더 많은 컨테이너를 생성하거나 분산
    - etc ..
- 사실 위의 관리 역할을 AWS의 ECS와 같은 툴이 지원 해 주기도 하지만, 이와 같은 특정 프로바이더(AWS, GCP, Azure)에 의존하게 되면, 다른 프로바이더를 사용하는 데에 있어서 유연성이 떨어진다.
- `Docker-Compose`가 단일 머신에 한해서 컨테이너를 지휘 하는 역할을 했다면, `Kubernetes`는 다중 머신에서 컨테이너들을 지휘하는 역할을 한다고 볼 수 있다.
- Kubernetes의 구조는 아래와 같다.
    
    - Cluster
        - Worker Node
            - Proxy
            - Pod
        - Master Node
            - The Control Plane

### Worker Node

---

- Worker Node는 하나의 인스턴스라 볼 수 있다.(AWS의 EC2와 같은)
- 이 Worker Node는 Master Node에 의해 관리 된다.
- Worker Node 내에 pod이 실행된다.
- Pod 내에는 실행할 수 있는 여러 컨테이너를 가질 수 있다.
- 하나의 Worker Node에 여러개의 Pod을 가지는게 일반적이다.
이는 애플리케이션에 들어오는 트래픽을 분산하기위해, Scailing의 목적으로 동일한 Pod을 복사한 것일 수도 있고, 다른 특정 애플리케이션을 실행하기 위한 Pod일 수도 있다.
- 이러한 Worker Node에는 `docker`가 설치되어 있어야 하고, Master Node와 통신하기 위한 `Kubelet`이라는 소프트웨어도 실행되어 있어야 하며, 들어오고 나가는 트래픽을 관리하는 `kube-proxy`라는 것도 있어야 한다.
- 우리는 쿠버네티스를 사용하여, 원하는 최종 상태를 정의하기만 하면 된다.

    

### Master Node

---

- `API serve`r(Kubelet 통신을 위한)
    
    클러스터의 운영에 있어서 중심적인 역할을 하며, 클러스터내의 통신과 보안, 접근 제어 등을 종합적으로 관리
    클러스터내의 중앙 집권자라 볼 수 있음
    
- `Scheduler` 
생성된 Pod를 관찰하고, Pod를 어디에 실행시킬 워커노드를 선택한다.
Scheduler가 리소스의 여러 요구사항들을 종합하여 위의 결정을 내리게 된다.
- `kube-controller manager`
요구된 수의 포드를 가동하고 있는지 확인하는 등, 워커 노드 전체를 모니터링하는 역할
- `cloud-controller manager`
    
    클라우드 제공업체(AWS, GCP, Azure)와 상호작용을 관리하는 역할
    클라우드의 여러 서비스(노드, 볼륨, 네트워킹 등)와의 통합을 담당