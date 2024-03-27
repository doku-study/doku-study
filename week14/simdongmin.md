# 새롭게 알게된 점

## 들어가며

- 프로젝트 배포
- 배포 관리를 위한 쿠버네티스의 사용

## 배포 옵션 & 단계

- 자체 데이터 센터(자체 설치) OR Cloud Provider
- Cloud Provider: 스스로 머신을 이용하여 설치, 자체 클러스터 구성
- Cloud Provider: 관리형 서비스 사용, 클러스터 아키텍쳐만 정의

## AWS EKS vs ECS

- EKS (Elastic Kubernetes Service)
  - 기본 쿠버네티스 구성을 사용하고 적용할 수 있도록 모든 것을 설정
  - AWS-specific 한 구문이나, 설정이 필요하지 않음
  - 쿠버네티스 표준을 사용하고, 정적 시스템 구성을 사용할 수 있음.
- ECS (Elastic Kubernetes Service)
  - 컨테이너 배포를 위한 일반적인 서비스
  - 쿠버네티스와 관련이 없음.
  - AWS 만의 구문이나, 세부 설정과 개념을 익혀야 함.

## 시작 프로젝트 준비하기

- 데모 프로젝트 사용

## AWS 사용

> WS 클라우드와 온프레미스 데이터 센터에서 Kubernetes를 실행하는 데 사용되는 관리형 Kubernetes 서비스입니다. 클라우드에서 Amazon EKS는 컨테이너 예약, 애플리케이션 가용성 관리, 클러스터 데이터 저장 및 다른 주요 작업을 담당하는 Kubernetes 컨트롤 플레인의 가용성과 확장성을 관리합니다

- https://aws.amazon.com/ko/eks/

![](https://d1.awsstatic.com/product-page-diagram_Amazon-EKS%402x.ddc48a43756bff3baead68406d3cac88b4151a7e.ddc48a43756bff3baead68406d3cac88b4151a7e.png)

## EKS를 사용하여 Kubernetes 클러스터 생성 & 구성하기

1. 클러스터 생성
2. 클러스터 구성 설정(쿠버네티스 버전 설정)
   - EKS 내부로 EC2 를 사용하여 대신 리소스를 사용하는 권한을 제공해야함.
   - IAM role
3. VPC 설정 추가
4. 검토 후 생성

EKS 클러스터 생성, 클러스터에서 네트워크 문제 해결

kubetl - eks 클러스터와 통신할 수 있도록 local의 config를 변경
aws cli로 조금 더 쉽게 접근할 수 있음.

minikube를 대상으로 실행되던 kubectl이 aws를 바라보게 됨.

## 워커 노드 추가하기

- 클러스터의 Node Group 그룹에서 실질적인 워커 노드를 추가
- Node에도 IAM role을 적용해주어야함.

  - 내부에 구동되는 리모트 머신인 EC2에 적용될 role
  - CNI policy
  - EC2 ReadOnly

- 워커노드(EC2) spec 결정
  - type(OS IMAGE), instance type, disk size 등

## Kubernetes 구성 적용하기

- 이전에 사용했던 yaml 파일을 그대로 사용해서 구성할 수 있음.
  `kubectl apply -f=auth.yaml -f=users.yaml`

aws에서는 실제 서비스의 external-ip를 적용받은 것을 볼 수 있음.

kubectl 명령어를 그대로 사용할 수 있어 aws 서비스에서 구성만 잘해주면 구성을 적용하는 것은 그리 어렵지 않음.

## EFS를 볼륨으로 추가하기(CSI 볼륨 유형 사용)

- AWS 용 EFS 볼륨 사용
- 사용 방법이 약간은 변경된 듯 하다.
  [깃허브 링크](https://github.com/kubernetes-sigs/aws-efs-csi-driver)

```
kubectl kustomize \
    "github.com/kubernetes-sigs/aws-efs-csi-driver/deploy/kubernetes/overlays/stable/?ref=release-1.X" > public-ecr-driver.yaml
```

If you already created a service account by following Create an IAM policy and role, then edit the public-ecr-driver.yaml file. Remove the following lines that create a Kubernetes service account.

```
apiVersion: v1
kind: ServiceAccount
metadata:
  labels:
    app.kubernetes.io/name: aws-efs-csi-driver
  name: efs-csi-controller-sa
  namespace: kube-system
---
```

```
kubectl apply -f public-ecr-driver.yaml
```

## EFS용 영구 볼륨 생성

```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: efs-pv
spec:
  capacity:
    storage: 5Gi
  volumeMode: Filesystem
  accessModes:
    - ReadWriteMany
  storageClassName: efs-sc
  csi:
    driver: efs.csi.aws.com
    volumeHandle: { AWS의 EFS 파일시스템의 ID }
```

storageClass 를 구성하기 위한 드라이버 명시 [깃허브](https://github.com/kubernetes-sigs/aws-efs-csi-driver/blob/master/examples/kubernetes/static_provisioning/specs/storageclass.yaml)

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: efs-sc
provisioner: efs.csi.aws.com
```

컨테이너 하단에 볼륨 추가

```yaml
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: efs-pvc
spec:
  accessModes:
    - ReadWriteMany
  storageClassName: efs-sc
  resources:
    requests:
      storage: 5Gi
---

---
    ...
    volumeMounts:
      - name: efs-vol
        mountPath: /app/users
volumes:
  - name: efs-vol
    persistentVolumeClaim:
      clasimName: efs-pvc
```

# 함께 이야기하고 싶은 점

- 클러스터를 구성하는 전체적인 동작원리를 이해하는데 EKS 서비스 대신, virtual box같은 가상 머신으로 (자체 데이터센터)를 구축해보는 게 원리 측면에서는 이해가 더 잘되지 않았을까? 그러기엔 기타 내용들이 너무 방대하고, 내용도 많아서,,?
