# Kubernetes 배포

### Kubernetes를 배포하는 여러 방법들

- 자체 데이터 서버
    - 자체 서버에서 K8S에 필요한 SW를 모두 설치후, 운영
- 클라우드 서버
    - EC2와 같은 머신을 빌려 K8S에 필요한 SW를 모두 설치 후, 운영
    - EKS와 같은 K8S 전용 서비스를 빌려, 편리하게 운영

# EKS

### 클러스터 생성

- EKS에서 클러스터를 하나 생성한다.(kub-deb-demo)
1. 이렇게 생성한 클러스터와 통신하기 위해 kubectl을 사용한다.
- 이렇게 생성한 클러스터와 통신하기 위해 kubectl을 사용한다.
    - 사전에, 우리의 kubectl은 어떻게 minikube와 통신하려는 걸 알고 있었을까?
    - .kube파일 내의 config라는 파일 내부에 minikube와 통신하도록 구성되어 있다.
    - 이 config파일을 수정함으로써, EKS의 클러스터와 통신할 수 있다.
    - AWS CLI를 사용하면 편하게 재정의가 가능하다.(설치하면 됨)
    - 터미널에서 `aws configure`로 접근하여 인증
    - `aws eks --region us-east-2 update-kubeconfig --name kub-dep-demo`
    - 위의 명령어를 통해, kubectl이 minikube가 아닌 aws의 eks의 kub-dep-demo의 클러스터와 통신하기 위한 요구사항을 config팔에 업데이트 하게 된다.
    

### 워커노드 추가

- 생성한 Cluster에서 Compute항목에서 워커노드 생성
    - Node 컴퓨팅 파워 선택
    - Node Group scaling configureation에서 노드의 개수를 지정해 줄 수 있음(Min, Max, Desired)
    (노드가 많을 수록 pod가 잘 배분되어 배포 시 원활할 순 있겠지만, 비용은 많이 들 수 있다. 적정선 필요)
- EKS는 이렇게 생성된 노드에 K8S에 필요한 모든 SW를 자동으로 설치해 준다.(EKS의 장점)
- deployments와 service를 배포하는 방식은, minikube를 사용했을 때와 동일하다.

### Volume

- 이전에는 emptyDir, hostPath, PersistentVolume와 같은 Volume을 활용했다.
    - emptyDir → pod가 생성될 시, 빈 디렉토리가 함께 생성되며, pod가 죽으면 함께 사라진다.
    (Pod 내부에 volume이 존재)
    - hostPath → 워커노드에 경로를 생성하여, 볼륨으로 활용. pod가 죽어도 해당 볼륨은 유지된다.
    (Pod 외부, 노드 내부에 volume이 존재)
    (여러 노드를 활용하는 상황에서는 적합하지 않음)
    - PersistentVolume → 노드 외부에 존재하며, Pod와 노드에 독립적임.
    (Pod, Node에 의존하지 않고, 영속적으로 존재하는 volume)

- EKS와 함께 EFS(Elastic Filesystem Service)를 사용하여 volume을 관리하고자 함
(AWS의 EFS를 위한 CSI 패키지가 있다.)
(CSI는 이처럼, EFS와 같은 서비스를 volume 드라이버로 손쉽게 통합해줄 수 있도록 해준다.)

- kubectl 명령어를 통해, 해당 EFS를 위한 드라이버를 github으로 부터 설치
(이렇게 드라이버를 따로 설치해 주는 이유는, EFS가 자체적으로 Volume 타입을 지원해 주지 않기 때문)

- EFS에서 파일을 생성하고, EFS를 PersistentVolume으로 사용하기 위한 yaml파일(pv.yaml)을 만든다.

- 이렇게 EFS를 PersistentVolume으로 활용함으로써, pod가 삭제되더라도, pod가 실행되는 환경이 여러 노드라도, 동일한 state를 가지는 영속적인 volume을 활용하게 됨

### 느낀점

- `VPC`, `IAM` `Security groups`등 AWS를 위한 기본 지식이 있어야, 다른 파생 서비스들을 잘 활용할 수 있을 것 같다.