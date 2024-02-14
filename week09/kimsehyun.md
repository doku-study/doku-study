# 쿠버네티스 Kubernetes란?

> "쿠버네티스는 (다중) 컨테이너의 배포, 스케일링, 그리고 관리를 자동화하고 조율하는 오픈소스 기반 시스템이다." Kubernetes is an open-source system and de-facto standard(사실상 표준) for automating and orchestrating deployment, scaling and management of containerized applications.

동어반복 같지만, 쿠버네티스를 이렇게 정의할 수도 있다: 
> Kubernetes 클러스터를 어떻게 관리하고 배포할 것인지를 기술(describe)하는 표준적인 방법.



### AWS ECS만으로는 불충분한 이유
AWS ECS는 컨테이너의 autoscaling과 모니터링(health check) 기능을 제공하긴 한다.

하지만 AWS에서만 작업한다면, 컨테이너를 관리하는 규칙이 모두 AWS에만 특화되어 있기 때문에 유연하게 대처할 수 없다. (**lock-in 효과**)

구체적으로 설명하자면, 만약 다른 CSP(Cloud Service Provider)로 옮기고 싶다면 컨테이너 배포의 모든 설정, 관리 규칙 등을 또다른 CSP에 맞게 수정해야 한다는 뜻이다.



### 왜 쿠버네티스를 쓰는가?

![Pasted image 20240212121156](https://github.com/doku-study/doku-study/assets/36873797/dcc6409c-36a2-4fb5-bd03-78c596d1e88c)



반면에 k8s는 configuration file이 존재하는데, (편의상 "kubeconfig"이라고 하자) 이 kubeconfig 파일을 어떠한 tool(?)에 전달하면 어느 종류의 CSP나 서버든 간에 이를 읽어들여 똑같이 적용할 수 다. 그리고 configuration 파일을 작성하는 법은 한 가지로 통일되어 있다. 즉 쿠버네티스만 알면 서버나 클라우드 서비스에 상관없이 일관되게 대처할 수 있다는 뜻.

강의에서는 이걸 "Extensible, yet standardized configuration(확장 가능하면서도 표준화된 구성)"이라고 표현했다.



### 쿠버네티스에 대한 오해와 진실
#### 쿠버네티스는 tool인가요?
X. 쿠버네티스는 tool이라기보다 container orchestration, large-scale deployment를 도와주는 프레임워크다. 

#### 쿠버네티스는 AWS, Azure와 같은 클라우드 서비스인가요?
X. 클라우드 서비스와 독립적으로 작동한다. 쿠버네티스는 오픈 소스 프로젝트에서 출발했다.

#### 쿠버네티스는 특정 클라우드 서비스하고만 호환되나요?
X. Kubernetes를 지원만 한다면, 어느 CSP에서든 쓸 수 있다.

#### 그럼 쿠버네티스는 내 컴퓨터에 돌아가는 소프트웨어 같은 건가요?
X. 쿠버네티스는 컨테이너를 관리하기 위한 일종의 개념과 유용한 도구의 모음이라고 할 수 있다.

#### 쿠버네티스만 있으면 도커는 이제 아예 사용할 필요가 없나요?
X. 쿠버네티스는 도커를 대체하는 개념이 아니라, Docker와 함께 쓰인다.


---


# Kubernetes 구조와 용어

## Pod
- 쿠버네티스를 구성하는 가장 작은 단위.
- 하나의 컨테이너일 수도 있고, 여러 개의 컨테이너가 모여 하나의 pod를 구성할 수도 있다. 컨테이너와 그 컨테이너를 실행하기 위한 리소스의 집합이라고 정의할 수 있다.
- Kubernetes 공식 docs에서는 "a set of running containers in a cluster(클러스터 내에서 실행되고 있는 컨테이너들의 집합)"이라고 간단하게 정의하고 있다.


## Node (worker node)
- node란 서버, 컴퓨터, 가상 머신에 대응되는 개념이다.
- AWS EC2 인스턴스에 대응하는 개념이다.
- 클러스터에 따라 virtual 또는 physical machine 둘 중에 아무거나 해당할 수 있다.


### node vs. pod
- pod는 node의 하위 구성 요소라고 생각하자.
- pod 외에도, node에는 다음과 같은 구성 요소(component)가 존재한다.
	- kubelet
	- kube-proxy
	- container runtime


### Master Node
- worker node를 관리, 통제하는 역할을 한다. 공장이나 발전소의 중앙통제실, control tower에 대응한다고 볼 수 있을 것 같다.
- Kubernetes는 worker node를 직접 통제하는 대신, master node에게 'end state'(이렇게 되기를 바라는 상태, 목표 상태)를 주고서 통제하는 일을 위임한다.
- control plane은 클러스터에 대해 전반적인 결정(scheduling 같은)을 내리고 클러스터 내에서 어떤 이벤트가 일어나면 감지하고 반응하는 등의 역할을 한다. (출처: https://kubernetes.io/docs/concepts/overview/components/#control-plane-components)


### Proxy
- worker node의 구성 요소로서, pod 간의 네트워크를 관리하는 역할을 한다.
- pod를 외부 네트워크와 연결/통신하려면 proxy 설정을 해야 한다.


### Cluster
- master node와 worker node, 그리고 이를 하나로 묶는 네트워크, 그리고 cloud provider API가 존재한다.
- Cloud Provider API를 통해 AWS나 Azure 등 클라우드 서비스에게, Kubernetes의 요청사항을 전달해서 컨테이너들으 관리할 수 있도록 한다.







---

# Kubernetes가 하는 것, 하지 않는 것

## 쿠버네티스는 많은 과정을 자동화해준다. 하지만...

- Kubernetes 설치하기
- 클러스터, 그리고 노드 생성하기
- API server, kubelet, 그리고 다른 Kubernetes 서비스 / 소프트웨어 (node에서 돌아가는 것) 설정하기
- 클라우드에서 필요로 하는 reource (load balancer, file system 등) 할당하기

스스로 이해를 쉽게 하기 위해 비유를 하자면,
요리하기 위해 재료(클러스터를 구성하는 각 노드)와 물, 가스, 주방도구, 식기(computing resource)를 제공해주면 알아서 이 자원을 잘 활용해서, 메뉴별로 요리를 시작하고, 계속 지켜보면서 굽고 끓이고 볶고 요리 시간도 잘 조절해다는 뜻.


## Kubernetes의 특징: "Desired State"로 클러스터 관리하기

출처: https://jennifersoft.com/ko/blog/tech/2023-08-16-jennifer-kubernetes-1/

쿠버네티스에서는 end state, 즉 목표 상태(또는 의도한 상태, desired state)를 명시한다.
(나중에 쿠버네티스에 대한 개념이 좀 더 잡히면 복습할 때 저 글을 다시 한번 꼼꼼히 읽어보자)


---

# Worker Node와 Master Node 파악하기

## Worker Node

- worker node는 task별로 나뉘지 않는다. 하나의 worker node에는 다른 역할을 하는 서로 다른 pod가 여러 개 존재할 수 있다.
- worker node는 Kubernetes 입장에서는 CPU와 메모리를 갖고 있는 하나의 컴퓨터, 머신으로 취급할 뿐이다.

![Pasted image 20240214204905](https://github.com/doku-study/doku-study/assets/36873797/a3efb015-0c57-43f1-90c5-d5b2e2546b86)



## Master Node

### API Server
- worker node와 master node 간 통신을 관리

### Scheduler
- pod를 모니터링하는 역할 + pod 중에 잘못 돌아간 건 없는지(중단, 재시작), 새로 생성해야 하는 pod는 없는지 등을 담당

### kube-controller manager
- worker node를 관리 (나머지 구성 요소와 차이가 뭐지?)

### cloud controller manager
- cloud service provider에게 맞는 지시를 내리는 역할
- AWS나 Azure 같은 큰 CSP는 이미 kubernetes config만 있으면 알아서 필요한 기능을 다 제공해준다.