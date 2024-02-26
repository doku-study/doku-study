## 쿠버네티스가 해주는 것과 개발자가 해야할 것

쿠버네티스는 최종 아키텍처를 정의하는 올인원 도구.

컨테이너화된 애플리케이션에 대한 배포를 설정할 수 있는 프레임워크이며, 개념과 도구의 모음이다.

| 쿠버네티스                                             | 개발자                                                       |
| ------------------------------------------------------ | ------------------------------------------------------------ |
| 오브젝트 (e.g. pod) 생성 및 관리                       | 클러스터와 노드 인스턴스 생성 (마스터 노드 + 워커 노드)      |
| pod 의 모니터링, 재생성, 스케일링                      | API 서버, kubelet, 쿠버네티스 서비스들, 각 노드의 소프트웨어들 설치 |
| 제공된 리소스들과 주어진 설정값을 활용, 배포 목표 달성 | 필요할 수도 있는 (클라우드) 프로바이더 리소스들 ( 로드 밸런서, 파일 시스템, etc ) |



오른쪽 표에 적힌 개발자가 해야 할 일들 마저 직접 하기 부담스럽다면, AWS 의 EKS 와 같은 쿠버네티스 관리형 서비스 사용을 고려해봐도 좋겠다.



<br />



## 로컬개발을 위한 minikube 세팅

```bash
brew install kubectl
brew install minikube
```



minikube 에서는 현재 실행중인 쿠버네티스 정보를 한눈에 볼 수 있는 대시보드를 제공한다.

```bash
minikube dashboard
```



<br />



## kubectl 과 마스터 노드의 차이점

마스터노드가 여러 워커노드들을 컨트롤 한다는 이유로, kubectl 와 마스터노드를 헷갈려야하는 경우가 많다.

엄밀히 말하면, kubectl 은 클러스터 외부에서 클러스터에 명령을 전달하는 상위의 객체이고,

마스터노드는 클러스터 내부에 위치하여 외부에서 전달된 명령을 기반으로 워커노드들을 컨트롤한다.



<br />

## 쿠버네티스 객체 (리소스) 이해하기

쿠버네티스는 객체와 함께 동작한다.

객체의 종류는..

* Pods
* Deployments
* Services
* Volume
* ...

각 객체에 대해 알아보자.



<br />

## Pod 객체

하나 이상의 컨테이너를 소유, 실행한다. (1 pod 1 container 가 일반적임)

소유한 컨테이너들이 사용할 수 있는 공유 리소스도 갖고 있다. (e.g. 볼륨)

기본적으로 클러스터 내부에서 사용할 수 있는 IP 를 갖고 있다. (팟 내부의 컨테이너들은 localhost 로 통신할 수 있음)

기본적으로 팟은 임시적(ephemeral)이므로, 중지되면 팟 내부의 데이터도 함께 손실된다. (컨테이너와 비슷함)

팟을 컨트롤하기 위해서는 Controller 가 필요하다. (e.g Deployment)

Controller 중 Pod 생성을 관장하는 Deployment 객체를 알아보자.

팟의 인스턴스를 replica 라고 한다.



<br />

## Deployment 객체

여러 Pod 을 컨트롤한다.

* 원하는 상태를 기술하면, 쿠버네티스가 실제 상태를 바꾼다.
* 각 배포는 중지, 삭제 롤백될 수 있다는 이점이 있다.
* 각 배포는 오토 스케일링 될 수 있다.
* 하나의 pod 의 인스턴스를 여러개 생성하여 배포할수도 있다.
* Deployment 객체에서 pod 을 컨트롤하므로, 개발자가 직접 pod 을 컨트롤하는일은 드물고, 개발자는 Deployment 객체를 통해 원하는 최종 상태를 기술한다.



<br />

## 명령형 접근 방식으로 deployment 객체 생성해보기

쿠버네티스는 컨테이너를 관리해주므로, 컨테이너를 생성할 이미지가 있어야 한다.

```bash
docker build -t kub-first-app .
```



생성한 이미지로 deployment 객체를 생성해보자.

```bash
kubectl create deployment first-app --image=kub-first-app
```

> 위 명령어를 실행하면, kubectl 내부적으론 아래와 같은 일이 일어난다.
>
> 1. deployment 오브젝트를 생성한 뒤, 자동으로 쿠버네티스 클러스터에 있는 마스터 노드, 즉 컨트롤 플레인으로 전송한다.
> 2. 스케쥴러가 현재 실행중인 pod 들을 분석한 뒤, 새로운 pod 을 위해 가장 적합한 노드를 찾는다.
> 3. 새로 생성된 pod 은 워커 노드중 하나로 보내진다. (가장 적은 작업을 가진 워커 노드일 확률이 높음)
> 4. kubelet 이 pod 들을 관리한다.





그러나 사전에 생성한 이미지는 로컬에만 존재하고, 클러스터 내부에는 존재하지 않는다. 때문에 이미지pull 에 실패했다는 오류와 함께 deploy에 실패한다.

일단 방금 생성한 deployments 객체를 제거하자.

```bash
kubectl delete deployment first-app
```



클러스터가 이미지를 인식하게 하기 위해서는 도커 허브에 이미지를 올린 뒤, 해당 이미지를  클러스터에서 Pull 해올 수 있도록 하자.



<br />



## Service 객체

pod 과 pod 에서 실행되는 컨테이너에 접근하기 위해서는 service 객체가 필요하다.

클러스터의 다른 pod 에 pod 을 노출시키는 책임을 갖는다.

pod 은 교체될 때마다 IP 가 변경되기 때문에 추적이 쉽지 않은데, service 가 여러 pod 들을 공유IP 로 그룹화해준다.





<br />

## Service 객체로 Deployment 객체 노출시키기

service 를 생성하여, deployment 에 의해 생성된 pod 을 노출하는 명령어

```bash
kubectl expose deployment first-app --type=LoadBalancer --port=8080
```

> --type=Nodeport : deployment 가 현재 실행중인 워커 노드의 IP 주소를 통해 노출됨을 뜻한다.
>
> --type=LoadBalancer : 클러스터가 실행되는 인프라에 존재하는 로드 밸런서를 이용하여 노출됨을 뜻한다. 



minikube 는 가상 머신이다. 따라서 `kubectl get services` 를 실행하여 services 목록 -> EXTERNAL-IP 를 조회했을 때, 로드 밸런서가 존재하는 클라우드에서는 EXTERNAL-IP 를 볼 수 있다. 하지만 로컬에서는 가상 머신에 내어줄 수 있는 port 가 많지 않기 때문에, pending 으로 나온다.

minikube 가상 머신에서 생성한 service 를 조회하는 방법은 따로 있다.

```bash
minikube service first-app
```



<br />

## 컨테이너 재시작

실행중인 컨테이너가 트래픽 급증 등의 이유로 중지되었다면, 쿠버네티스는 이를 자동으로 재시작하려고 시도한다.





<br />

## 스케일링

pod 을 하나만 두면 pod 이 잠시 중지되었을 때 유저가 서비스를 이용할 수 없는 문제가 있다.

이를 방지하기 위해 pod 의 인스턴스(replica) 를 여러개 생성하여 특정 pod 이 잠시 죽어 있더라도 살아있는 pod 으로 트래픽이 유입될 수 있게 해보자.

```bash
kubectl scale deployment/first-app --replicas=3
```



<br />

## 이미지 교체

코드 변경등의 이유로 이미지를 교체, Deployment 객체를 업데이트해야 할 경우에는 이미지 리빌드 뒤 아래 명령어를 실행하자.

이미지를 리빌드하고 도커 허브에 올릴 때 주의할 점은, 쿠버네티스는 이미지의 태그가 동일하면 이미지를 다시 다운받지 않는다는 점이다.

따라서 이미지를 리빌드할 때는 태그를 바꿔서 올리자.

```bash
kubectl set image deployment/first-app kub-first-app=junzero741/kub-first-app:2
```



<br />

## Deployment 롤백 & 히스토리

서비스되고있는 Deployment 에 문제가 생겼을 때 롤백할 수 있다. 아래 명령을 실행하면 가장 최근의 deployment 가 undo 된다.

```bash
kubectl rollout undo deployment/first-app
```



히스토리는 아래 명령으로 볼 수 있다.

```bash
kubectl rollout history deployment/first-app
```

> --revision=1 : 각 롤아웃은 revision 이라고 하는 식별자가 붙는데, 이를 롤백 등에 명시해서 특정 롤아웃으로 롤백할 수 있다.



<br />

## 명령적 접근 방식의 문제점

kubectl 명령어를 일일이 외우고, 터미널에 입력하는 것은 휴먼 에러가 발생하기도 쉽고, 귀찮다.

이전 도커에서는 이러한 문제를 docker-compose 로 해결했다.

kubectl 도 비슷하게 선언형 방식을 사용할 수 있다.



<br />



## yaml 파일을 이용한 선언형 접근 방식 

프로젝트 루트에 yourFileName.yaml 을 생성해보자. 

파일 이름은 자유이며, 따라서 deployment 객체를 위한 yaml 이라고 생각하면 곤란하지만, deployment 만을 위한 yaml 파일임을 나타내기 위해 deployment.yaml 로 적어도 상관없다. 여기서는 deployment 를 위한 yaml 파일을 작성해보자.

```yaml
apiVersion: apps/v1
kind: Deployment
metadata: 
	name: second-app-deployment
spec: 
```

