이제 minikube 쓰지 말고 실제 클라우드 서비스에 배포해보자! (AWS EKS)

## 242~244. 모듈 소개
### 리마인드: k8s는 클러스터와 노드를 만들어주지 않는다

Kubernetes 처음 배울 때 강조했던 점으로, k8s는 클러스터 + node 인스턴스를 직접 만들어주지 않는다는 점이었다. 
그래서 지금까지 실습할 때에는 Minikube를 썼다. Minikube는 (단일 node이긴 하지만) dummy cluster 환경을 알아서 구축해주기 때문이다.


![Pasted image 20240321223401](https://github.com/doku-study/doku-study/assets/36873797/982edfa9-9020-42d3-8682-117f7ce1b4f6)


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

![MongoDB_connect](https://github.com/doku-study/doku-study/assets/36873797/a6212604-dcc5-42fe-8e0d-90b82056a383)




### 2. 연결 방법(Drivers) 선택

![MongoDB_drivers.png](https://github.com/doku-study/doku-study/assets/36873797/7333eae4-ec8b-4725-8dd7-d742c8345487)


### 3. connection string 복사하기

![MongoDB_connection-string.png](https://github.com/doku-study/doku-study/assets/36873797/e1b1c5c7-cec3-44d3-8831-e392155e3047)


---

## 248. AWS EKS 클러스터 구축하기

EKS > Create cluster 클릭 > Configure cluster로 들어가서 

1. 이름
2. 버전

을 설정

![EKS_create-cluster.jpeg](https://github.com/doku-study/doku-study/assets/36873797/240e0203-e098-40da-a103-30ebe6b16274)


![EKS_configure-cluster 1.jpeg](https://github.com/doku-study/doku-study/assets/36873797/27887ccf-0f78-49c0-87ec-c4e9d806af48)


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

![add_node_group1.jpeg](https://github.com/doku-study/doku-study/assets/36873797/0584b4d5-19ed-4c95-ad28-331116d50711)

Node group 클릭

노드 그룹 구성 단계에서 Node IAM role을 추가해야 한다.
결국 EKS 클러스터도 EC2 인스턴스 여러 개가 모여서 만들어지는 건데, 그 EC2 인스턴스 각각을 관리할 수 있는 권한을 또 부여해야 하는 것 같다.

![Node IAM Role 추가.jpeg](https://github.com/doku-study/doku-study/assets/36873797/b52c53de-8a06-4dc0-a100-c7c68ac2263b)


IAM 화면으로 다시 돌아가서, Roles를 클릭한 다음 role을 새로 추가하기 위해 'Add Role'을 클릭하자.

![IAM roles로 다시.jpeg](https://github.com/doku-study/doku-study/assets/36873797/94594e9f-e518-4555-a839-124c88081edc)

- Trusted Entity Type: AWS Service
- Use Case: EC2

로 선택한 다음 Next 클릭.

총 세 가지 권한을 부여한다.

- AmazonEKS_CNI_Policy
- AmazonEKSWorkerNodePolicy
- AmazonEC2ContainerRegistryReadOnly

 이 권한 세 개를 모두 선택했다면 next를 클릭하고, role 이름(나는 `eksNodeRole_v1`이라고 지정했음)을 지정하고 최종 create 버튼을 눌러 role을 생성한다.

![role 생성.jpeg](https://github.com/doku-study/doku-study/assets/36873797/708d9c97-6516-481b-8c43-0690f318bf50)


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

![인스턴스 자동 생성.jpeg](https://github.com/doku-study/doku-study/assets/36873797/3a69636c-f0fc-4ac1-b3d5-350291ce1586)


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

![2024-03-26_10-05-14.png](https://github.com/doku-study/doku-study/assets/36873797/6738f06b-a093-4a85-96bd-f4e7ca5b6611)

요렇게 클러스터에 IAM Access Entry를 내 IAM 유저로 추가하고 나면, 에러를 해결할 수 있다.

![2024-03-26_10-09-30.png](https://github.com/doku-study/doku-study/assets/36873797/cf11bd5a-bfab-4caa-8e2f-f99ccbc3055c)


이제 kubectl로 다시 클러스터를 확인해보자.

![2024-03-26_13-25-51.png](https://github.com/doku-study/doku-study/assets/36873797/398ea9c4-ea1a-4359-9eb5-f266461fa785)

`kubectl get pods` 명령어를 실행했는데도 `No resources found in default namespace` 메시지가 뜬다면, 말 그대로 아직 리소스를 생성 안 한 것이니 kubernetes 폴더로 들어가서 k8s 구성 파일을 적용해주자.

```bash
# 강의 첨부파일
kubectl apply -f=auth.yaml -f=users.yaml
```

실행하고 나면 요렇게 떠야 한다.

![2024-03-26_13-30-55.png](https://github.com/doku-study/doku-study/assets/36873797/487a1637-e4eb-48ac-8f4c-09827d9970db)


그러고 나서 `kubectl get pods` 명령어 실행하면

![2024-03-26_13-58-02.png](https://github.com/doku-study/doku-study/assets/36873797/1497dde6-0a50-43b2-b801-2af0c8e92508)

### CrashLoopBackOff로 pod가 비정상 종료, 실행을 반복

kubectl describe pods 명령어로 pod 상태를 확인했을 때, Exit Code가 1이었다.
-> 이미지 빌드 및 푸쉬를 제대로 했는지 확인

로그 확인했을 때, 다음과 같은 명령어: 

![2024-03-26_14-27-54.png](https://github.com/doku-study/doku-study/assets/36873797/a9d0a371-e745-41aa-92eb-b696d439700e)

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

![2024-03-26_16-20-37.png](https://github.com/doku-study/doku-study/assets/36873797/ebb9274b-36f5-4770-845f-552c5b1237e2)


![2024-03-26_16-22-44.png](https://github.com/doku-study/doku-study/assets/36873797/424fd021-55e9-4ef7-818f-44222691396f)

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
## 251~252. EKS 클러스터에 볼륨 생성하기

### 키워드
- persistent volume claim
- CSI(Container Storage Interface)
- CSI Driver

일단 CSI 드라이버를 설치해야 한다. AWS 공식 홈페이지 매뉴얼을 따라 설치하는 방법도 있을 것 같은데, 강의에서는 [깃허브](https://github.com/kubernetes-sigs/aws-efs-csi-driver/)에 올린 링크로 설치하는 방식을 소개하고 있다.

```bash
kubectl apply -k "github.com/kubernetes-sigs/aws-efs-csi-driver/deploy/kubernetes/overlays/stable/?ref=release-1.7"

# 설치 메시지
'''Warning: 'bases' is deprecated. Please use 'resources' instead. Run 'kustomize edit fix' to update your Kustomization automatically.
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
'''
```


### 보안 그룹 생성
EFS를 생성하기 전에, 보안 그룹을 만들어두어야 한다.

EC2 메뉴 > Security Groups > Create security group 클릭

- VPC는 default가 아니라 EKS 클러스터 전용으로 만든 VPC를 선택해야 한다(이전 강의에서 클러스터 생성할 때 이미 만들어두었다).
- security group name 설정한다. (`eks-efs`)
- Inbound rules를 추가한다. Add rule > Type에 NFS로 설정한다. Source는 Custom, IP 주소에 EKS의 VPC IPv4 CIDR을 입력한다. (`192.168.0.0/16`)
- outbound rules는 0.0.0.0/0으로 그대로 놔둔다.

### EFS(Elastic File System) 생성
그리고 EFS 화면으로 가서, 'create file system'을 클릭한다.
- Step 1. File System Settings에서는 건드릴 게 없다. Next 클릭.
- Step 2. Network Access 설정에서 VPC, 보안 그룹 설정을 해야 한다.

1. VPC: 보안 그룹과 마찬가지로 EKS 클러스터용 VPC를 선택한다.
2. **Mount targets의 보안 그룹 설정: default가 아니라, 방금 전에 만든 security group으로 바꿔야 한다.** (아래 캡처 이미지 참고)
3. 그 뒤로는 건드릴 게 없으니 next 계속 클릭해서 EFS 생성한다.

![2024-03-26_17-55-38.png](https://github.com/doku-study/doku-study/assets/36873797/edb6d8ff-c135-4309-bdcd-fe3c4fbc4087)

4. 다 만들었으면 방금 생성한 EFS의 ID를 복사해놓는다.

---

## 253. EFS persistent volume 만들기

지금까지 EFS를 설정한 이유는 볼륨을 클러스터에 추가하기 위해서다. 볼륨을 추가하기 위한 지금까지의 과정+253번 모듈의 내용을 요약해보면
1. (터미널) CSI 드라이버 설치
2. (AWS EC2 > Security Group 페이지) 보안 그룹 생성
3. (AWS EFS 페이지) file system 생성
4. EKS 클러스터의 yaml 파일에 볼륨 명시(persistent volume claim)

이제 4번을 실행에 옮겨보자. 
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
아래는 저 깃허브 링크로 접속했을 때 보이는 'specs' 폴더 안의 storageclass.yaml 파일 내용을 그대로 복사해온 것이다.

```yaml
# users.yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: efs-sc
provisioner: efs.csi.aws.com
```

그리고 persistentVolumeClaim을 추가한다.

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

claim을 추가했으니 볼륨 정보도 추가해야 한다. containers와 동일 레벨에서 volumes 정보를 아래처럼 추가한다.

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

볼륨을 추가했으니, 실제로 볼륨이 잘 작동하는지 확인해봐야 한다.
기존 데모 앱에선 파일을 저장하고 기록하는 코드가 없었다. 
users-api > controllers > user-actions.js에서 유저 정보를 로그로 저장하는 코드를 추가했다.

```javascript
// users-api > controllers > user-actions.js
// 추가
const path = require('path');
const fs = require('fs');
// 삭제
// const { response } = require('express');

...

// 추가
  const logEntry = `${new Date().toISOString()} - ${savedUser.id} - ${email}\n`;

  fs.appendFile(
    path.join('/app', 'users', 'users-log.txt'),
    logEntry,
    (err) => {
      console.log(err);
    }
  );
  
...

// 추가
const getLogs = (req, res, next) => {
  fs.readFile(path.join('/app', 'users', 'users-log.txt'), (err, data) => {
    if (err) {
      createAndThrowError('Could not open logs file.', 500);
    } else {
      const dataArr = data.toString().split('\n');
      res.status(200).json({ logs: dataArr });
    }
  });
};

...
// 추가
exports.getLogs = getLogs;
```

user-api > routes > user-routes.js 파일에는 이 한 줄을 추가했다.

```javascript
// user-api > routes > user-routes.js
// 추가
router.get('/logs', userActions.getLogs);
```

소스코드를 변경했으니 이미지를 재빌드하고, push한다.

```bash
cd users-api; docker build -t my_docker_id/kub-dep-users .
```

```bash
cd kubernetes
kubectl delete deployment users-deployment
# Error from server (NotFound): deployments.apps "users-deployment" not found

kubectl apply -f=users.yaml
# 파일 잘못 쓰면 이런 에러가 납니다
# Error from server (BadRequest): error when creating "users.yaml": PersistentVolume in version "v1" cannot be handled as a PersistentVolume: quantities must match the regular expression '^([+-]?[0-9.]+)([eEinumkKMGTP]*[-+]?[0-9]*)$'
# Error from server (BadRequest): error when creating "users.yaml": PersistentVolumeClaim in version "v1" cannot be handled as a PersistentVolumeClaim: strict decoding error: unknown field "spec.access"
```

여담이지만, 파일을 그대로 복사해오지 않고 yaml 파일을 영상 보면서 따라 치면 indent 실수를 할 여지가 있다.

![[2024-03-26_19-40-36.png | 400]]

그리고 PostMan으로 테스트하면? -> 추가한 EKS 볼륨도 잘 작동하는 걸 볼 수 있다.

```bash
# replicas=0으로 설정 후
kubectl apply -f=users.yaml -f=auth.yaml
# 그러고 나서 pod 상태를 확인해보자
kubectl get pods
```

---

## 255. 도전 과제

모듈 256번 넘어가기 전에, 스스로 해보기

1. 첨부파일에 tasks-api 폴더가 새로 추가되었다. 이 Task API를 EKS 클러스터에 추가하는 게 목표다.
2. Task API는 클러스터 외부에서도 접근 가능해야 한다.
3. Task API는 Auth API와 통신할 수 있어야 한다.
4. k8s 구성에 맞게 환경변수도 설정해야 한다.

아 그리고 users.yaml에 `AUTH_ADDRESS` 환경변수 오타가 있다.(`AUTH_ADDRESSS` -> S자 3개를 2개로 고쳐야 함) 

---
## 256. 솔루션

나는 task-deployment.yaml과 task-service.yaml로 분리해서 작성했지만, 강의에선 하나의 파일로 합쳤다.

### tasks-deployment.yaml
- tasks-deployment.yaml의 tasks 컨테이너의 환경변수에 `MONGODB_CONNECTION_URI` 를 추가해야 한다.
- 나머지는 다 week13과 동일하다.

### tasks-service.yaml
- 마찬가지로 포트 번호만 바꾸고, 나머지는 week13와 동일하다. (`port: 80 targetPort: 3000`) -> tasks-app.js에 있는 포트 번호로 변경

이제 task 이미지를 빌드하고 push한다.

```bash
# 실행하기 전 Docker Hub에 kub-dep-tasks라는 이름의 repo를 생성해야 한다.
# 태그를 v1으로 설정(현재 버전이 에러가 날 경우, 다음 시도는 v2, v3...)
docker build -t my_docker_hub_id/kub-dep-tasks:v1 .
docker push my_docker_hub_id/kub-dep-tasks:v1

# 그 다음에 tasks 구성을 클러스터에 적용
kubectl apply -f=tasks.yaml

# 그리고 auth-api, users-api도 코드를 일부 변경했다고 하니 이미지 재빌드하고 push한다
cd ../auth-api; docker build -t my_docker_hub_id/kub-dep-auth:task_ver .
docker push my_docker_hub_id/kub-dep-auth:task_ver
cd ../users-api; docker build -t my_docker_hub_id/kub-dep-users:task_ver .
docker push my_docker_hub_id/kub-dep-users:task_ver
```

그리고 기존 deployment과 service를 삭제하고 새로 실행한다.

```bash
cd kubernetes
kubectl delete deployment users-deployment.yaml
kubectl delete deployment auth-deployment.yaml
kubectl apply -f=users.yaml -f=auth.yaml
```


```bash
# External URL을 가져온다.
kubectl get services
```

### 테스트 과정
1. signup POST 요청 보내서 유저 계정 생성
2. 생성한 유저 계정으로 로그인(email과 password json 형식으로 POST login 요청)
3. 결과로 얻은 token 값을 복사
4. Authorization Header의 value에 복사한 토큰을 붙여넣기
5. 그러고 나서 tasks POST 요청을 보내보자 (title, text 텍스트 채워서)
6. 똑같은 유저의 똑같은 Authorization header 값으로 DELETE tasks 요청을 보내면 tasks 값이 잘 삭제된 걸 볼 수 있다.

---
## 섹션 16: 마무리 정리 & 다음 단계

지금까지 많은 걸 다뤘다.
- 도커, 컨테이너가 무엇인지
- 왜 도커 컨테이너를 사용하면 좋은지
- 도커 컨테이너를 어떻게 사용하는지(로컬에 컨테이너, 이미지 빌드하기, 실행하기, 다중 컨테이너 환경 구축하기, 배포하기, AWS 사용하기, 쿠버네티스 환경에 배포하기)
- docker compose 사용하기 (컨테이너의 runtime 구성을 공유, 수정 기록하는 최선의 방법)
- Kubernetes로 컨테이너 오케스트레이션하기. pod scaling, 통신, 볼륨 생성 등

하지만 이 강의에서 다루지 않은 것도 많다.

- CI/CD 파이프라인(Travis, GitHub actions, AWS CodePipeline 등)
- AWS를 본격적으로 다루는 법
- 도커 클러스터 심화 개념

이제 어떻게 더 공부하면 될까?
- 반복 숙달
- Docker, k8s 공식 독스
- AWS 독스
- VS Docker Support?


