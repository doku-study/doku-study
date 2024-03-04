# 실전 Kubernetes - 핵심 개념 자세히 알아보기

## 모듈 소개
이전과정 진행사항
- 쿠버네티스 소개
- 일반적인 아키텍처 및 용어/개념

실제 쿠버네티스 사용 실습
- 쿠버네티스 환경 생성
- 쿠버네티스로 배포하기
- 쿠버네티스 객체 / 종류 등

## Kubernetes는 인프라를 관리하지 않습니다.
쿠버가 하지않는것 > 클러스터 및 노드 생성   
쿠버가 하는것 > 파드/컨테이너 모니터링, 실패한 파드 교체 및 스케일링 등 관리적인 측면

쿠버네티스는 컨테이너화된 어플리케이션에 대한 배포를 설정하는 프레임워크/개념과 도구의 모음
- 구체적인 머신의 상태는 알지 못함
- 컴퓨팅, 네트워크, 스토리지, 보안등은 사용자 설정의 영역

## Kubernets: 요구 설정 & 설치 단계
클러스터 
- 마스터 노드: API/Scheduler 등 구성 요소
- 워커 노드: Docker, kubelet 등 구성 요소 

로컬 필요도구
- kubectl: kubernetes control 도구
- minikube: 로컬에서 사용할 클러스터 생성 도구

## macOS 설정
docker는 이미 설치되어있기때문에 그냥 도커드라이브로 클러스터구성해도 뭐..      
- `brew install kubectl minikube`
- `minikube start`
- `minikube status`
- `minikube dashboard`

## Windows 설정
윈도우용 패키지 매니저인 Chocolatey를 사용한 설치
- `choco install kubectl-cli`

kubeconfig 빈 파일 생성
- cd %USERPROFILE% 부터 장렬히 실패

Virtualbox 설치 후 minikube 설치(Chocolatey)
- `choco install minikube`

## Kubernetes 객체 (리소스) 이해하기
쿠버네티스에는 Pod,Deploy,Sevice,Volume과 같은 리소스들이 존재함.       
특정 명령으로 실행(desired state)하면 객체가 만들어짐(actual state)
- 명령적 방식
- 선언적 방식

명령적 방식으로 Pod 실행
- Pod는 하나 이상의 컨테이너를 실행 가능
- 볼륨과 같은 공유 리소스 연결 가능
- 기본적으로 클러스터 내부 IP를 갖고 통신가능
  - 볼륨과 네트워킹은 추후 강의에서 살펴볼 예정
- 컨테이너와 같이 임시적인 존재(stateless)
  - pod 생성,제거,교체를 관리하기위해 deployment 객체를 사용

## "Deployment" 객체 (리소스)
deployment 객체를 사용해 하나이상의 pod를 제어 가능
- 쿠버네티스에 의해 생성되고 관리되기때문에 적절한 노드에 배치
- 일시중지, 삭제, 롤백, 스케일링 등이 용이함

## 첫 번째 Deployment - 명령적 접근 방식 사용
간단한 NodeJS 앱을 빌드 후 배포
- `docker build -t kub-first-app .`
- `kubectl create deployment first-app --image=kub-first-app`
  - ImagePullBackoff 발생 > 로컬 이미지를 찾지 못함, docker hub 업로드필요
- `docker tag kub-first-app nasir17/kub-first-app`; `docker push`

## kubectl: 작동 배경
kubectl로 명령을 전달하면 컨트롤 플레인으로 전달되어 처리됨
- 컨트롤플레인의 API서버가 수신
- 스케줄러가 pod/node를 분석하여 적절한 노드 선정
- 선정node의 kubelet이 pod 생성절차 시작 및 네트워킹 설정

## "Service" 객체 (리소스)
Pod 네트워크 관리를 위해 Service 객체 추가
- 기본 pod IP의 문제점
  - 클러스터 내부 IP 이기 때문에 외부에서 접근 불가
  - pod가 교체될 때마다 변경됨
- Service는 pod를 그룹화하여 공유 DNS주소, 공유 IP주소를 제공
- 클러스터 내부 뿐만 아니라 외부와도 통신 가능

## Service로 Deployment 노출하기
`kubectl create`를 통해서 생성할 수도 있지만, 좀더 간편한 `kubectl expose` 사용
- `kubectl expose deploy first-app --type=LoadBalancer --port=8080`
  - 생성된 first-app 디플로이를 8080 포트로 노출
  - 서비스의 유형
    - ClusterIP: 디폴트, 클러스터 내부 연결만 가능, 고정 IP 제공
    - NodePort: deploy가 위치한 워커노드의 IP:NodePort를 통해 외부 액세스 가능
    - LoadBalancer: 인프라에 따른 LoadBalancer에 따라 고유 주소 생성, 트래픽 밸런싱
- `minikube service first-app`
  - minikube 클러스터내의 서비스를 로컬호스트로 연결해줌

## 컨테이너 재시작
pod의 컨테이너를 종료하고, 재시작 시킴
- 앱의 /error 경로로 요청하면 컨테이너 실패 가능
- 자동적으로 재시작 됨을 확인 가능
- 무한 루프를 방지하기위해 재시작 시간은 점증함

## 실제 스케일링(scaling)
kubernetes 환경에서 scaling 실행
- `kubectl scale deploy/first-app --replicas=3`
  - 기존의 1개 외에, 추가로 2개 생성되어 총 3개의 replicas 운영
  - /error 요청시 1개의 pod restart 확인 > 트래픽 분산 확인

## Deployment 업데이트 하기
생성된 deploy를 (신규 이미지로) 업데이트하고 롤백하는 방법
- `docker build -t nasir17/kub-first-app:2 .; docker push`
  - 소스 코드 업데이트 후, 2라는 이미지 태그를 달고 빌드한 뒤 docker hub push
- `kubectl set image deployment/first-app kub-first-app=nasir17/kub-first-app:2`
  - deploy의 kub-first-app 컨테이너 이미지를 신규 이미지로 변경
  - 자동적으로 새 이미지를 사용하는 파드로 컨테이너들이 교체 됌

## Deployment 롤백 & 히스토리
존재하지않는 이미지로 변경하여 실패하고, 히스토리와 롤백 수행
- `kubectl set image deployment/first-app kub-first-app=nasir17/kub-first-app:3`
  - 존재하지않는 tag로 업데이트 > 이미지가 존재하지않아 에러 발생
- `kubectl rollout undo deployment/first-app`
  - 최근의 배포를 되돌리기(undo) 함
- `kubectl rollout history deployment/first-app`
  - 배포 기록 확인
- `kubectl rollout undo deployment/first-app --to-revision=1`
  - 바로 이전이 아닌, 배포기록의 특정 시점(배포판,revision)으로 롤백 가능

## 명령적 접근방식 vs 선언적 접근방식
지금 까지는 명령적 접근방식, 문제점은?
- 명령어를 외워서/반복적으로 사용해야함
- docker run 시의 문제점과 유사, docker에서는 docker compose를 사용하여 구성을 문서화(YAML)하여 해결하였음
- Kubenetes에서 또한 오브젝트 구성을 파일로(YAML) 정의하여 실행할(apply) 수 있다 = 선언적 접근방식

## 배포 구성 파일 생성하기 (선언적 접근방식)
deployment 리소스 생성을 위한 deployment.yaml 작성

```
apiVersion: apps/v1
kind: Deployment
metadata:
  name: second-app-deployment
spec:
```

![Kubernetes YAML schema](https://blog.kakaocdn.net/dn/cjHZcI/btrgV6wRBLZ/W9cBd078Js0Liab1gmkod1/img.png)
