## AWS EKS vs ECS



| EKS (Elastic Kubernetes Service)            | ECS (Elastic Container Service)    |
| ------------------------------------------- | ---------------------------------- |
| 쿠버네티스 배포를 위한 관리형 서비스        | 컨테이너 배포를 위한 관리형 서비스 |
| AWS 만을 위한 문법이나 철학이 요구되지 않음 | AWS 만을 위한 문법과 철학이 적용됨 |
| 표준 쿠버네티스 설정과 리소스를 사용함      | AWS 만을 위한 설정과 컨셉을 사용함 |



## AWS EKS vs minikube

Kuberenetes 클러스터 환경이 AWS 냐 로컬이냐의 차이



## kubectl 과 minikube 가 통신하는 방법

운영체제의 사용자 폴더에서 `.kube` 폴더에 가면 config 파일을 볼 수 있다.

이 파일은 kubectl 명령에 의해 사용될 구성 파일로, 여기서 kubectl 이 통신할 클러스터를 설정할 수 있다.



## AWS CLI 로 kubectl 이 AWS 환경에서 실행되도록 하기

`aws eks --region YOUR-AWS-REGION update-kubeconfig --name YOUR-EKS-CLUSTER-NAME`



## AWS EKS 에 노드 그룹 추가할 때 주의할 점

노드의 EC2 인스턴스 타입은 최소 t3.small 이어야 한다.

만약 더 작은 t3.micro 로 설정하면 pod 을 스케줄링하는데 실패한다고 함.



## AWS 로 실행한 Loadbalancer 타입의 service 객체가 minikube 와 다른점

minikube 로 실행할때는 Loadbalancer 타입의 service 객체의 External-IP 가 pending 이었고, `minikube service 서비스명`으로 서비스를 명시적으로 시작해줘야 했다면,

AWS 로 실행한 같은 타입의 서비스는 yaml 파일에 대해 apply 를 적용하면 External-IP 에 URL 이 명시된다.



## EFS 를 볼륨으로 추가하기 (CSI 볼륨 사용)

다음 링크에서 AWS EFS CSI 드라이버 공식문서 볼 수 있다.  https://github.com/kubernetes-sigs/aws-efs-csi-driver

kubectl 에 apply 

`kubectl apply -k "github.com/kubernetes-sigs/aws-efs-csi-driver/deploy/kubernetes/overlays/stable/?ref=release-1.7"`



AWS EFS 페이지에서 EFS 생성 (EFS 의 VPC 나 security group은 이전에 생성한 eks 에 해당하는 걸로 설정해야 함에 주의)



## EFS 용 영구 볼륨 생성하기

```yaml
kind: StorageClass
apiVersion: storage.k8s.io/v1
metadata:
  name: efs-sc
provisioner: efs.csi.aws.com
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: efs-pv
spec:
  capacity: 
    storage: 5Gi
  volumeMode: Filesystem
  accessModes:
  	# 여러 노드가 볼륨에 접근,수정할 수 있도록 함
    - ReadWriteMany
  storageClassName: efs-sc
  csi:
    driver: efs.csi.aws.com
    volumeHandle: YOUR-FILE-SYSTEM-ID
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
apiVersion: v1
kind: Service
metadata:
  name: users-service
spec:
  selector:
    app: users
  type: LoadBalancer
  ports:
    - protocol: TCP
      port: 80
      targetPort: 3000
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: users-deployment
spec:
  replicas: 3
  selector:
    matchLabels:
      app: users
  template:
    metadata:
      labels:
        app: users
    spec:
      containers:
        - name: users-api
          image: junzero741/kub-dep-users:latest
          env:
            - name: MONGODB_CONNECTION_URI
              value: 'mongodb+srv://YOUR_NAME:YOUR_PASSWORD@cluster0.ntrwp.mongodb.net/users?retryWrites=true&w=majority'
            - name: AUTH_API_ADDRESSS
              value: 'auth-service.default:3000'
          volumeMounts:
            - name: efs-vol
              mountPath: /app/users
      volumes:
        - name: efs-vol
          persistentVolumeClaim: 
            claimName: efs-pvc
```



