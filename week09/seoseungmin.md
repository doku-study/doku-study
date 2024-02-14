

## 도커 톺아보기

- 컨테이너는 코드와 환경을 담은 isolated된 박스
- 1 컨테이너 1 task
- 필요한 패키지만 담아 가벼운 박스를 share하고 reproduce 하는 것이 도커 컨테이너의 selling point
- 컨테이너는 이미지로부터 생성됨. 이미지는 Dockerfile로부터 생성되거나 Dokcer hub에서 pull 할 수 있음
- 컨테이너는 이런 이미지 위에 thin layer가 붙은 것이라 생각하면 됨
    - read-write layer 라고 할 수 있음
- 1 이미지로 여러 컨테이너 생성 가능
- 이미지 자체는 read-only
- 이미지는 run 하는게 아니라 built 되는 것

- `docker build -t NAME:TAG .`
    - TAG는 versions of an image
- `docker run --name NAME --rm -d IMAGE`
- `docker push REPOSITORY/NAME:TAG`
- `docker pull REPOSITORY/NAME:TAG`

- bind mounts, volumn
- docker network

- docker compose
    - 긴 도커 명령문 + 멀티 컨테이너 작업 -> docker compose 라는 파일로 해결 가능
    - `docker-compose up`
    - `docker-compose down`

- 도커를 local host에서만 사용: 이것도 충분히 selling point 있다고 함
- 도커를 remote host에서도 사용
    - reproducible이 가장 큰 장점인 것 같다. 지금 프로젝트에서도 개발 환경이 가장 큰 골칫거리..

- Deployment
    - prod 환경에선 bind mounts 사용 X. 대신 볼륨이라 COPY 명령어 사용
    - 멀티 컨테이너는 multiple hosts 필요
    - multi-stage builds 는 한 Dockerfile 내 순서에 따라 실행되는 여러 컨테이너와 같음
    - control VS ease-of-use 라는 트레이드-오프



## Kubernetes

- 컨테이너 수동 배포, 관리 시 겪는 문제
    - 컨테이너 자체가 crash, go down되는 위험
    - traffic 뛰는 상황에서 컨테이너 자원 추가하기 어려움
    - 트래픽이 골고루 분산되게 하기 어려움 (실제 개발에선 1 이미지 - 멀티 컨테이너가 흔함. 트래픽 분산 대응하기 위해)
- AWS ECS 사용하면 어느정도 해결되긴 함 (autoscaling, load balancer)
    - 그러나 ECS를 사용하는건, 특정 서비스에 발 묶이는 것. 전환이 어려움
    - 도커만 알아선 안됨. 알아야 할게 훨씬 많아짐
    - 비용도 있을테고..
    - ECS의 이런 단점까지 해결한게 쿠버!


- 쿠버는 프로그램이 아니라 시스템에 가까움 (컨테이너 배포를 돕는)
    - independent container orchestration / large scale deployment
    - automatic deployment / scaling & load balancing / management
    - 쿠버는 cloud service provider가 아님. 오픈 소스 프로젝트
    - 무료!!
    - 도커 대체재가 아닌 도커와 같이 쓰이는 것
- 어떻게?
    - 쿠버 configuration 작성. docker-compose와 비슷한거 아닌가? 몇가지 기능만 더 추가됐을 뿐이지 별반 다를게 없어보이는데
        - *바로 강의에서 언급하네 소름... 다만 차이는 multiple machines의 deployment에 적용 가능하다는 것*
    - config 실행.. 끝?

- Pod은 쿠버의 가장 작은 실행 단위(?)
    - 컨테이너를 담고 있음
- Worker node
    - pod, proxy를 담고 있음
    - 컨테이너 run 하는 역할
    - 필요 시 여러개 사용 가능
- master node
    - 모든 worker node 제어함. 직접 다룰 필요 없게 해줌
    - control plane이란 것이 있어 여기서 config 같은걸 작성하는 것 같음
- 사실 무슨 말인지 잘 모르겠다. 직접 해봐야 알 듯
- 내가 도커 배포 담당할거 아니면 쿠버는 거의 접할 일 없지 않을까

- 내가 헤야 하는 것
    - 클러스터, 노드 생성
    - API 서버 구축, 쿠버 소프트웨어 설치
    - 로드 밸런서, 파일 시스템 등의 cloud provider resources 생성
- 쿠버가 하는 것
    - pod 생성, 관리
    - pod 모니터, 재생성, 스케일링
    - utilize the provided (cloud) resources

- Worker node
    - 그냥 one copmuter / machine / virtual instance 라고 봐도 됨
    - 마스터 노드에 의해 관리됨
    - 여러 pod을 담을 수 있음
    - 내부에 도커가 설치되어야 함. 추가로 kubelet (worker - master node간 통신 담당) 필요. kube-proxy도 필요 (노드 - 팟 통신을 위해?)
- Pod
    - 여러 컨테이너, 볼륨을 담을 수 있음
    - 쿠버에 의해 생성, 관리되는 것
- Master node
    - API server: worker 와 master node간 통신을 위한 counterpart
    - Scheduler: 새로운 pod 감지. 실행시킬 워커 노드 선택 등
    - kube-controller-manager: 워커노드, 팟 제어
    - cloud-controller-manager: 위에서 하던걸 클라우드로 옮긴 것

- 용어
    - Cluster: 워커, 마스터 노드 머신의 집합
    - Node: = 호스트 머신
    - Pods: 앱 컨테이너 + 환경, 볼륨 등을 담은 개념
    - Container: 그냥 도커 컨테이너
    - Services: groups of pods. 이걸 밖에 노출시키는 것(IP 주소 등)과 관련된 개념.






