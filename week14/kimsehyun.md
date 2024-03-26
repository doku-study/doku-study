이제 minikube 쓰지 말고 실제 클라우드 서비스에 배포해보자! (AWS EKS)

## 242~244. 모듈 소개
### 리마인드: k8s는 클러스터와 노드를 만들어주지 않는다

Kubernetes 처음 배울 때 강조했던 점으로, k8s는 클러스터 + node 인스턴스를 직접 만들어주지 않는다는 점이었다. 
그래서 지금까지 실습할 때에는 Minikube를 썼다. Minikube는 (단일 node이긴 하지만) dummy cluster 환경을 알아서 구축해주기 때문이다.

![[Pasted image 20240321223401.png]]

하지만 이제 실제 배포 환경에 가까운 cloud provider service를 사용해볼 차례다.

### 왜 AWS EKS를 쓰는가?

EKS를 쓰지 않고 low level 리소스로 클러스터를 직접 구축한다고 해보자.
- 여러 대의 EC2 인스턴스 생성 + SSH를 통한 접속
- k8s 필수 소프트웨어 설치
- 네트워크 설정
- 기타 등등...
-> 이 모든 것들을 수작업으로 해야 하는데, 귀찮고 번거롭고 관리하기도 힘들다.
또는 [kops](https://github.com/kubernetes/kops) 같은 툴을 사용해볼 수도 있다.

하지만 AWS에선 k8s 클러스터를 알아서 관리해주는 서비스를 (당연히) 제공해준다.

> Amazon Elastic Kubernetes Service(Amazon EKS)는 AWS 클라우드와 온프레미스 데이터 센터에서 Kubernetes를 실행하는 데 사용되는 관리형 Kubernetes 서비스입니다. 클라우드에서 Amazon EKS는 컨테이너 예약, 애플리케이션 가용성 관리, 클러스터 데이터 저장 및 다른 주요 작업을 담당하는 Kubernetes 컨트롤 플레인의 가용성과 확장성을 관리합니다. Amazon EKS를 사용하면 AWS 네트워킹 및 보안 서비스와의 통합뿐만 아니라 AWS 인프라의 모든 성능, 규모, 신뢰성 및 가용성을 활용할 수 있습니다 온프레미스에서 EKS는 완벽하게 지원되는 일관된 Kubernetes 솔루션을 제공합니다. 통합된 도구를 사용하여 AWS Outposts, 가상 머신 또는 베어 메탈 서버에 간편하게 배포할 수 있습니다.

### AWS ECS(Elastic Container Service) vs. EKS(Elastic Kubernetes Service)

말 그대로다. 결정적인 차이는, 
- EKS는 k8s 설정 파일을 읽고 해석하지만, ECS는 알아듣지 못한다.
- EKS는 쿠버네티스의 작동방식과 관리 철학 위에서 움직인다 (무슨 뜻인지 감 잡으려면 EKS를 실습으로 직접 써봐야)

---
## 245. AWS EKS 배포 전, 실습 코드 소개 + 유의사항

### 1. 첨부 자료 다운로드받기
kub-deploy-01-starting-setup 폴더 압축 해제

### 2. MongoDB 설정

```yaml
# users.yaml
	containers:
        - name: users-api
          image: academind/kub-dep-users:latest
          env:
            - name: MONGODB_CONNECTION_URI
              value: 'mongodb+srv://maximilian:wk4nFupsbntPbB3l@cluster0.ntrwp.mongodb.net/users?retryWrites=true&w=majority'
            - name: AUTH_API_ADDRESSS
              value: 'auth-service.default:3000'
```

users.yaml 보면 환경변수에 `MONGODB_CONNECTION_URI`가 있다. users-app.js에서 MongoDB를 쓰기 때문
-> MongoDB connection string이 필요하다.

MongoDB Atlas Cluster 만들어서, 본인의 connection string을 직접 발급받은 다음에 value 값을 대체해야 한다(현재 값은 Maximilian 강사 본인의 connection string 값).

2024년 기준 MongoDB 처음 접속하고 가입하면 UI가 강의영상이랑 다르다. 만약 처음 가입한다면, 가입하자마자 바로 cluster를 만들고 connection string을 발급받을 수 있다.

### 1. DB에 연결하기(Connect) 클릭

![[MongoDB_connect.png]]

### 2. 연결 방법(Drivers) 선택

![[MongoDB_drivers.png]]

### 3. connection string 복사하기

![[MongoDB_connection-string.png]]


---

## 248. AWS EKS 클러스터 구축하기

EKS > Create cluster 클릭 > Configure cluster로 들어가서 

1. 이름
2. 버전

을 설정

![[EKS_create-cluster.jpeg]]

![[EKS_configure-cluster 1.jpeg]]

실제로 안에서 일어나는 일은
1. EC2 인스턴스를 여러 개 만들어놓고 
2. 자동으로 관리하게 하는 것

그런데 이걸 하기 위해선 EKS에 권한을 부여해야 한다.

https://docs.aws.amazon.com/ko_kr/eks/latest/userguide/creating-a-vpc.html

### AWS CLI 사용하기
로컬 터미널에서 AWS 서비스 관리 명령어를 직접 다룰 수 있다.
`aws configure`, `aws eks`  등 aws로 시작하는 명령어를 사용하려면 어쨌든 AWS CLI를 설치해야 한다.

[이 링크](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html#getting-started-install-instructions)로 들어가서 설치 파일을 다운로드 받자.


## 248. EKS로 Kubernetes 클러스터 생성 & 구성하기

### 1. Access key 적용하기
`aws configure` 입력 후 본인의 root user(권장 X) 또는 IAM 유저에서 생성한 Access Key ID와 Secret Access Key를 입력할 것. 키 정보는 생성한 직후 한번밖에 확인할 수 없기 때문에, csv 파일로 다운로드받아 놓는 게 좋다.
그리고 region name도 입력해주는데, 이건 본인 클러스터 메뉴 들어가서 어떤 region인지 (us-east-1: North Virginia 아니면 us-east-2: Ohio가 대부분?) 확인

### 2. kube config 파일 업데이트하기

만약 본인 클러스터의 region이 `us-east-1`이고, 클러스터 이름이 `kub-dep-demo`라면 이렇게 입력하면 된다.

```bash
aws eks --region us-east-1 update-kubeconfig --name kub-dep-demo
```


### 3. 노드 그룹 추가하기

EKS 서비스 화면으로 다시 돌아가서, 생성한 클러스터를 클릭한 다음 Compute 메뉴로 들어간다.

![[add_node_group1.jpeg]]

Node group 클릭

![[add_node_group1-1.jpeg]]

노드 그룹 구성 단계에서 Node IAM role을 추가해야 한다.
결국 EKS 클러스터도 EC2 인스턴스 여러 개가 모여서 만들어지는 건데, 그 EC2 인스턴스 각각을 관리할 수 있는 권한을 또 부여해야 하는 것 같다.

![[Node IAM Role 추가.jpeg]]

IAM 화면으로 다시 돌아가서, Roles를 클릭한 다음 role을 새로 추가하기 위해 'Add Role'을 클릭하자.

![[IAM roles로 다시.jpeg]]

- Trusted Entity Type: AWS Service
- Use Case: EC2

로 선택한 다음 Next 클릭.

총 세 가지 권한을 부여한다.

- AmazonEKS_CNI_Policy
- AmazonEKSWorkerNodePolicy
- AmazonEC2ContainerRegistryReadOnly

 이 권한 세 개를 모두 선택했다면 next를 클릭하고, role 이름(나는 `eksNodeRole_v1`이라고 지정했음)을 지정하고 최종 create 버튼을 눌러 role을 생성한다.

![[role 생성.jpeg]]


IAM role까지 설정하면, 'Set compute and scaling configuration'이라는 제목이 뜬다. 클러스터 구성할 EC2 인스턴스 스펙을 지정해야 한다.

AMI Type은 Amazon Linux 2 (AL2_x86_64), Capacity Type은 On-demand로 지정해주자.
그리고 인스턴스 타입 검색창에 t3를 입력해서 t3.small (스펙을 더 키울 수 있지만 데모 프로젝트용이라 작게 설정한다)을 찾아 클릭한다.
Disk size는 20GiB default로 그대로 설정한다.

### 4. 노드 스케일링
- 노드 1대 = 물리적인 컴퓨터 1대
- 노드 수가 많을수록 pod를 새로 생성해서 할당할 수 있는 노드도 넉넉한 셈이다. 하지만 노드 수를 늘리면 당연히 그만큼 유지 비용은 증가한다.
- node minimum, maximum, desired 사이즈 모두 2개로 유지하자


### 5. 네트워크 설정
Node group network configuration
- Subnet은 건드리지 않는다
- Config remote access to nodes: 외부에서 클러스터의 EC2 인스턴스를 SSH로 직접 연결할 수 있게 설정할 것인가? No (k8s가 알아서 관리하게 둔다)


### 6. 알아서 생성된 인스턴스, 그리고 로드 밸런서

AWS 콘솔에서 EC2 메뉴로 들어가보자. 그럼 EKS 클러스터 생성 덕분에(?) 자동으로 인스턴스도 새로 생긴 것을 볼 수 있다.

![[인스턴스 자동 생성.jpeg]]


---
## 250. Kubernetes 구성 적용하기

내용 수정 없이 바로 k8s 구성 파일을 적용해보자.

```bash
cd ../kubernetes; kubectl apply -f=auth.yaml -f=users.yaml
```

하면은 요런 메시지가 뜬다.

```
error validating "auth.yaml": error validating data: failed to download openapi: the server has asked for the client to provide credentials; if you choose to ignore these errors, turn validation off with --validate=false
error validating "users.yaml": error validating data: failed to download openapi: the server has asked for the client to provide credentials; if you choose to ignore these errors, turn validation off with --validate=false
```
그래서 스택오버플로우에 찾아봤더니: https://stackoverflow.com/questions/76177011/error-validating-data-the-server-has-asked-for-the-client-to-provide-credential

서버와 내 로컬의 kubectl 버전이 달라서 그럴 수 있다고 한다. 내 터미널에다 `kubectl version` 입력하면

```
Client Version: v1.29.2
Kustomize Version: v5.0.4-0.20230601165947-6ce0bf390ce3
error: You must be logged in to the server (the server has asked for the client to provide credentials)
```

요렇게 메시지가 뜬다. [AWS 공식 문서 해결책](https://docs.aws.amazon.com/ko_kr/eks/latest/userguide/troubleshooting.html#unauthorized)을 들어가보자. 그럼 중간에 <Unauthorized or access denied (`kubectl`)> 라는 제목의 단락이 있을 텐데, `error: You must be logged in to the server (Unauthorized)` 라는 에러가 나한테도 똑같이 발생한 상황이다. 거의 정답에 근접한 것 같다.

1. 첫번째 솔루션: `kube config` 파일을 업데이트한다. -> 사실 이 파트는 이미 강의에서 했다. 
2. 두번째 솔루션: 이게 정답인데, 내가 생성한 EKS 클러스터에 IAM role이나 user access를 추가해줘야 한다.

사실 이렇게 에러가 발생한 이유는, 내가 강의 그대로 따라하지 않고 IAM user를 별도로 만들어서 이 IAM user로 클러스터 접근을 시도하려고 했기 때문이다. 강의에서는 그냥 root user로 접속하고 root user에 권한을 모두 부여한 것 같다(AWS에서는 권장하지 않는 방식이라는데?).

`aws sts get-caller-identity` 를 입력해서, 현재 클러스터 서비스를 호출하기 위해 필요한 IAM 유저나 role에 대한 정보를 확인할 수 있다.

> Q. 명령어에서 보이는 STS(Security Token Service)란? 
> AWS Security Token Service(AWS STS)를 사용하면 AWS 리소스에 대한 액세스를 제어할 수 있는 임시 보안 자격 증명을 생성하여 신뢰받는 사용자에게 제공할 수 있습니다. 임시 보안 인증은 다음과 같은 차이점을 제외하고는 장기 액세스 키 보안 인증과 거의 동일한 효력을 지닙니다.
> 임시 보안 자격 증명은 그 이름이 암시하듯 *단기적*입니다. 이 자격 증명은 몇 분에서 몇 시간까지 지속되도록 구성할 수 있습니다. 자격 증명이 만료된 후 AWS는 더는 그 자격 증명을 인식하지 못하거나 그 자격 증명을 사용한 API 요청으로부터 이루어지는 어떤 종류의 액세스도 허용하지 않습니다.
https://docs.aws.amazon.com/eks/latest/userguide/create-kubeconfig.html


### 해결 방법: IAM Access Entry 구성하기

![[2024-03-26_10-05-14.png]]

요렇게 클러스터에 IAM Access Entry를 내 IAM 유저로 추가하고 나면, 에러를 해결할 수 있다.

![[2024-03-26_10-09-30.png]]


이제 kubectl로 다시 클러스터를 확인해보자.

![[2024-03-26_13-25-51.png]]

`kubectl get pods` 명령어를 실행했는데도 `No resources found in default namespace` 메시지가 뜬다면, 말 그대로 아직 리소스를 생성 안 한 것이니 kubernetes 폴더로 들어가서 k8s 구성 파일을 적용해주자.

```bash
# 강의 첨부파일
kubectl apply -f=auth.yaml -f=users.yaml
```

실행하고 나면 요렇게 떠야 한다.

![[2024-03-26_13-30-55.png]]


그러고 나서 `kubectl get pods` 명령어 실행하면

![[2024-03-26_13-58-02.png]]

### CrashLoopBackOff로 pod가 비정상 종료, 실행을 반복

kubectl describe pods 명령어로 pod 상태를 확인했을 때, Exit Code가 1이었다.
-> 이미지 빌드 및 푸쉬를 제대로 했는지 확인

로그 확인했을 때, 다음과 같은 명령어: 

![[2024-03-26_14-27-54.png]]

맥북 M1이라서 그런 건가? docker-compose.yaml 파일에 plaftorm을 linux/amd64로 추가해보고 다시 docker compose up 하면

```yaml
version: "3"
services:
  auth:
    build: ./auth-api
    ports:
      - '8000:3000'
    environment:
      TOKEN_KEY: 'shouldbeverysecure'
    platform: linux/amd64
  users:
    build: ./users-api
    ports:
      - '8080:3000'
    environment:
      MONGODB_CONNECTION_URI: 'mongodb+srv://maximilian:wk4nFupsbntPbB3l@cluster0.ntrwp.mongodb.net/users?retryWrites=true&w=majority'
      AUTH_API_ADDRESSS: 'auth:3000'
    platform: linux/amd64
```

아래 메시지와 함께 compose up이 되지 않는다.

```
docker compose up -d --build
# image with reference kub-deploy-01-starting-setup-auth was found but does not # match the specified platform: wanted linux/amd64, actual: linux/arm64/v8
```

또는 Dockerfile에 FROM 명령어 뒤에 platform 정보를 추가하고, Node 버전을 바꾸어도 동일한 에러가 발생한다.

```dockerfile
# users-api/Dockerfile
FROM --platform=linux/amd64 node:11.15

WORKDIR /app

COPY package.json .

RUN npm install

COPY . .

EXPOSE 3000

CMD [ "node", "users-app.js" ]
```

결과적으로 동일한 에러 발생한다. 

### 시도 1
Docker Desktop에서 Settings > Features in Development > Use Rosetta for x86/amd64 emulation on Apple Silicon 체크박스 선택
그 후 docker-compose.yaml의 각 service 아래 `--platform: linux/amd64`를 추가

![[2024-03-26_16-20-37.png]]


![[2024-03-26_16-22-44.png]]

-> 현재 이미지는 AMD64 기반으로 생성이 되었다.

1. docker compose로 생성된 이미지 이름을, auth.yaml과 users.yaml에 저장한 대로 변경한다.

```bash
docker image tag kub-deploy-01-starting-setup-auth seanshnkim27/kub-dep-auth:v1
docker image tag kub-deploy-01-starting-setup-users seanshnkim27/kub-dep-users:v1
```

2. 이미지를 Docker Hub에 push한다.
```bash
docker push seanshnkim27/kub-dep-auth:v1
docker push seanshnkim27/kub-dep-users:v1
```

3. kubernetes 폴더로 다시 들어가서 구성 파일을 적용한다.
```bash
kubectl delete -f=users.yaml -f=auth.yaml
# ... 삭제되는 것 기다린 다음
kubectl apply -f=users.yaml -f=auth.yaml
```

-> 여전히 동일 에러 발생

기존 amd64 노드를 삭제하고, 새로 그룹 생성해봐도 동일 에러 발생

---
### 쿠버네티스 클러스터는 Minikube와 EKS에서 동일하게 동작한다
1. Postman으로 EKS 클러스터의 노드에 POST, GET 요청을 보내거나
2. k8s 구성 파일(users.yaml)에 replica 수를 변경한 후, `kubectl apply -f=users.yaml` 명령어를 실행하면 pod 수가 늘어난 것을 확인
3. CoreDNS (`auth-service.default`)도 문제없이 잘 작동

-> 그게 Kubernetes의 작동 방식이기 때문. 똑같은 구성 파일이라면, 어느 서비스 플랫폼에서 작동시키든 동일하게 작동해야 한다.

---
## 251~252. 볼륨 생성

- persistent volume claim
- CSI(Container Storage Interface)

```bash
kubectl apply -k "github.com/kubernetes-sigs/aws-efs-csi-driver/deploy/kubernetes/overlays/stable/?ref=release-1.7"
```

결과 창

```
# Warning: 'bases' is deprecated. Please use 'resources' instead. Run 'kustomize edit fix' to update your Kustomization automatically.
serviceaccount/efs-csi-controller-sa created
serviceaccount/efs-csi-node-sa created
clusterrole.rbac.authorization.k8s.io/efs-csi-external-provisioner-role created
clusterrole.rbac.authorization.k8s.io/efs-csi-external-provisioner-role-describe-secrets created
clusterrole.rbac.authorization.k8s.io/efs-csi-node-role created
rolebinding.rbac.authorization.k8s.io/efs-csi-provisioner-binding-describe-secrets created
clusterrolebinding.rbac.authorization.k8s.io/efs-csi-node-binding created
clusterrolebinding.rbac.authorization.k8s.io/efs-csi-provisioner-binding created
deployment.apps/efs-csi-controller created
daemonset.apps/efs-csi-node created
csidriver.storage.k8s.io/efs.csi.aws.com configured
```


### 보안 그룹 생성
EC2 메뉴 > Security Groups > Create security group 클릭
- VPC는 default가 아니라 EKS 클러스터 전용으로 만든 VPC를 선택해야 한다(이전 강의에서 클러스터 생성할 때 이미 만들어두었다).
- security group name 설정한다. (`eks-efs`)
- Inbound rules를 추가한다. Add rule > Type에 NFS로 설정한다. Source는 Custom, IP 주소에 EKS의 VPC IPv4 CIDR을 입력한다. (`192.168.0.0/16`)
- outbound rules는 0.0.0.0/0으로 그대로 놔둔다.

### EFS(Elastic File System) 생성
그리고 EFS 화면으로 가서, 'create file system'을 클릭한다.
Step 1. File System Settings에서는 건드릴 게 없다. Next를 눌러서 Step 2. Network Access 설정으로 넘어간다.

1. VPC: 마찬가지로 VPC는 EKS 클러스터용 VPC를 선택한다.
2. Mount targets의 security group: default가 아니라, 방금 전에 만든 security group으로 바꿔야 한다.
3. 그 다음에 next next 계속 클릭해서 생성한다.

![[2024-03-26_17-55-38.png]]

4. 다 만들었으면, 만든 File system ID를 복사해놓는다.

fs-0626f455f454c2118

---

## 253. EFS persistent volume 만들기

persistent volume을 EFS cluster에 반영하기 위해 users.yaml 위에 다음 내용을 추가한다.

```yaml
# users.yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: efs-pv
spec:
  capacity:
    storage: 5Gi
    volumeMode: Filesystem
    accessModes:
      - ReadWriteAny
    storageClassName: efs-sc
    csi:
      driver: efs.csi.aws.com
      volumeHandle: fs-0626f455f454c2118
---
```

storage class를 명시하기 위해 static provisioning(정확히 이게 무슨 개념?)을 참고하자. [깃허브 링크](https://github.com/kubernetes-sigs/aws-efs-csi-driver/tree/master/examples/kubernetes/static_provisioning) 

아래는 specs 폴더에 storageclass.yaml 파일 내용을 그대로 복사해온 것이다.

```yaml
# users.yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: efs-sc
provisioner: efs.csi.aws.com
```

persistentVolumeClaim을 추가한다.

```yaml
# users.yaml
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: efs-pvc
spec:
  access:
    - ReadWriteMany
  storageClassName: efs-sc
  resources:
    requests:
      storage: 5Gi
---
```

containers와 동일 레벨에서 volumes 정보를 아래처럼 추가한다.

```yaml
# users.yaml
...
	spec:
	  containers:
	    ...
	  volumes:
	    - name: efs-pv
	      persistentVolumeClaim:
			claimName: efs-pvc
```

```yaml
# users.yaml
    spec:
      containers:
        ...
          env:
            ...
          volumeMounts:
            - name: efs-pv
              # 그래서 미리 로컬 폴더에 users 폴더를 만들어놓아야 함
              mountPath: /app/users
```

