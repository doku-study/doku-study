# Section 15: Kubernetes - 배포(AWS EKS)

## 모듈 소개
minikube 활용
- 로컬 개발 클러스터 

클라우드환경에서의 클러스터 구축
- 단일/여러 머신에 배포하기
- 로컬 머신 뿐만 아니라 퍼블릭 웹 접근 가능
- AWS의 EKS 서비스를 사용

## Deployment 옵션 & 단계
쿠버네티스가 하는것
- 오브젝트(컨테이너,파드 등) 생성
- pod 감시 > 재생성, 스케일링 등 수행
- 설정된 환경의 리소스를 활용하여 목표 수행

사용자가 해야하는것
- 클러스터 및 노드 생성
- API Server, kubelet, kube-proxy 등 k8s 필요 서비스 및 노드 구성
- 설정된 환경의 리소스 사전 설정 (로드밸런서, 볼륨 등)

\> 쿠버네티스는 인프라를 관리하지 않는다 재확인
\> 관리형 서비스를 사용하면 알아서 다해준다 재확인

## AWS EKS vs AWS ECS
- EKS: Elastic Kubernetes Service
- ECS: Elastic Container Service
  - 컨테이너 실행(배포)에 관한 관리형 서비스이지만 k8s 여부 차이

## 시작 프로젝트 준비하기
2개의 backend-api: auth-api, users-api
- users-api -> auth-api(그외 접근 불가)
- p80 > LB-service > p3000 > users-api > p3000 > auth-service > p3000 > auth-api
- users-api는 MongoDB와의 연결 필요
  - docker build . -t nasir17/kube-dep-users:v1 --push
  - docker build . -t nasir17/kube-dep-auth:v1 --push

## AWS에 뛰어들기
[AWS free tier 세부정보](https://aws.amazon.com/ko/free/)
- EKS는 프리티어 대상 X
- 워커노드를 프리티어 활용해서 사용 불가 (최소사양 미달)

## EKS를 사용하여 Kubernetes 클러스터 생성 & 구성하기
EKS 관리 콘솔에서 클러스터 생성 (영상은 ECS EKS 분리도 되기전.. )
- 이름 적당히
- 버전 적당히 (1.17이라니..)
- [Cluster Service role](https://docs.aws.amazon.com/eks/latest/userguide/service_IAM_role.html#create-service-role) 문서따라서 적절히 생성
- [VPC 설정](https://docs.aws.amazon.com/eks/latest/userguide/creating-a-vpc.html#create-vpc) 대충 VPC를 CFN(CloudFormataioN)로 생성

인증정보설정
- k8s 클러스터에 대한 인증/접근정보는 ~/.kube/config에 저장되어있음
- aws configure > aws cli 사용 설정
- aws eks update-kubeconfig --name kub-dep-demo > .kube/config 갱신

## 워커 노드 추가하기
생성된 클러스터에서, Compute > NodeGroup 추가
- 이름 설정
- Node IAM role 설정
  - [관리형 노드 그룹 생성](https://docs.aws.amazon.com/ko_kr/eks/latest/userguide/create-managed-node-group.html) 문서의 [Amazon EKS 노드 IAM 역할](https://docs.aws.amazon.com/ko_kr/eks/latest/userguide/create-node-role.html) 참고하여 부여
- Node type 설정 > 최소 small 이상

## Kubernetes 구성 적용하기
기존 2개의 (auth,users) 배포 테스트
- kubectl apply -f auth.yaml -f users.yaml
- kubectl get service > ExternalIP에 CLB(클래식로드밸런서)가 생성되어있음을 확인가능
  - `curl -X POST -H "Content-Type: application/json" -d '{"email": "aaa@aaa.com", "password":"a1234567"}' $(kubectl get service users-service -o=jsonpath='{.status.loadBalancer.ingress[0].hostname}')/signup`
    - {"message":"User created.","user":{"_id":"660c2c0088b71847aef68bbf","email":"aaa@aaa.com","password":"$2a$12$bp.1pKrsX9ZdZSigr7gQ.OfJYzEiNLSTLi8lhbQasWGHcEIZ7i05S","__v":0}}
  - `curl -X POST -H "Content-Type: application/json" -d '{"email": "aaa@aaa.com", "password":"a1234567"}' $(kubectl get service users-service -o=jsonpath='{.status.loadBalancer.ingress[0].hostname}')/login`
    - {"token":"eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpYXQiOjE3MTIwNzM3NTUsImV4cCI6MTcxMjA3NzM1NX0.3UJA9OXwIa0aob5QS98uIw_fW0r71pNy9-AR-qqo4Qg","userId":"660c2c0088b71847aef68bbf"}

- minikube(로컬)과 같은 구성파일(YAML)을 k8s 환경에서도 재사용가능
- 구성 변경이 필요한 경우 간단히 YAML 수정 후 apply
- pod 개수는 전체 노드에 걸쳐 고르게 배치됨
- DNS 또한 내부적으로 잘처리됨

## 볼륨으로 시작하기
emptyDir/hostPath 외에 CSI 유형 사용 예정
- 기존 docker compose의 경우 볼륨이 필요하면 로컬 볼륨 추가
- k8s에서는 pod 템플릿 직접추가/PV,PVC 생성 후 추가 가능
- 로컬머신은 1대라서 노드의 볼륨을 직접사용(emptyDir/hostPath) 유용했지만 다수 노드환경에는 부적합

## EFS를 볼륨으로 추가하기 (CSI 볼륨 유형 사용)
클러스터에 EFS Driver 설치
- [공식문서](https://docs.aws.amazon.com/ko_kr/eks/latest/userguide/efs-csi.html#efs-create-iam-resources) 의 설명에 따라 IAM 역할 생성 및 eks 콘솔 내 추가기능으로 설치하는것이 제일 간편할듯      
- 강의처럼, [github의 installation](https://github.com/kubernetes-sigs/aws-efs-csi-driver?tab=readme-ov-file#-manifest-public-registry-)을 따라 직접 manifests를 적용할 순 있지만.. 음.. 굳이?    

사용할 EFS 생성
- EFS에서 사용할 보안그룹 생성 > 포트:2049(NFS),소스: VPC의 CIDR
- EFS 콘솔로 이동해서 EFS 생성

## EFS용 영구 볼륨 생성
수동으로 영구 볼륨 생성 및 추가
- users-pv.yaml 생성
```
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
    - ReadWriteMany
  storageClassName: efs-sc
  csi:
    driver: efs.csi.aws.com
    volumeHandle: fs-0c9e21079dd4cb83f
---
kind: StorageClass
apiVersion: storage.k8s.io/v1
metadata:
  name: efs-sc
provisioner: efs.csi.aws.com
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
spec:
  template:
    spec:
      containers:
        - name: users-api // 기존 컨테이너에 볼륨 및 볼륨 마운트 추가
          volumeMounts:
            - name: efs-vol
              mountPath: /app/users
      volumes:
        - name: efs-vol
          persistentVolumeClaim: 
            claimName: efs-pvc
```

StorageClass 생성
- [example의 storageclass.yaml](https://github.com/kubernetes-sigs/aws-efs-csi-driver/blob/master/examples/kubernetes/static_provisioning/specs/storageclass.yaml) 생성

deployment 수정
- 기존 users.yaml에 volume 설정 추가
```
```
## EFS 볼륨 사용하기
users-api source 업데이트
- 로그 조회 및 저장기능 업데이트: GET, /logs
  - user-api/controllers/user-action.js, user-api/routes/user-routes.js
  - sudo docker build . -t nasir17/kub-dep-users:v8 && docker push nasir17/kub-dep-users:v8 && kubectl rollout restart -f ../kubernetes
- 작동 확인
  - `curl -X POST -H "Content-Type: application/json" -d '{"email": "test13@test.com", "password":"a1234567"}' $(kubectl get service users-service -o=jsonpath='{.status.loadBalancer.ingress[0].hostname}')/signup`
    - {"message":"getaddrinfo ENOTFOUND undefined"}
    - AUTH_API_ADDRESSS........
  - curl -X GET $(kubectl get service users-service -o=jsonpath='{.status.loadBalancer.ingress[0].hostname}')/logs
    - {"logs":["2024-04-02T17:35:27.518Z - 660c41dfa5004736594c3eea - test13@test.com",""]}
- pod 삭제후 재생성 > logs 남아있는지 확인

## 도전!
task-api 추가
- week13이랑 동일, 별도 pod로 구분되어있음 및 내부 service를 통한 통신
 
## 챌린지 솔루션
task docker image build
- sudo docker build . -t nasir17/kub-dep-tasks:latest && docker push nasir17/kub-dep-tasks:latest && kubectl rollout restart -f ../kubernetes

task.yaml
```
apiVersion: v1
kind: Service
metadata:
  name: tasks-service
spec:
  selector:
    app: task
  type: LoadBalancer
  ports:
    - protocol: TCP
      port: 80
      targetPort: 3000
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: tasks-deployment
spec:
  replicas: 1
  selector:
    matchLabels:
      app: task
  template:
    metadata:
      labels:
        app: task
    spec:
      containers:
        - name: tasks-api
          image: nasir17/kub-dep-tasks:latest
          env:
            - name: MONGODB_CONNECTION_URI
              value: 'mongodb+srv://temp_240402:z중간생략G@cluster0.dmgthm4.mongodb.net/?retryWrites=true&w=majority&appName=Cluster0'
            - name: AUTH_API_ADDRESS
              value: 'auth-service.default:3000'
```

작동확인
- tasks-service) tasks 조회
  - curl -X GET $(kubectl get service tasks-service -o=jsonpath='{.status.loadBalancer.ingress[0].hostname}')/tasks
  - {"message":"Could not authenticate user."}
- users-service) signup & login > token 획득
  - curl -X POST -H "Content-Type: application/json" -d '{"email": "nasir@test.com", "password":"a1234567"}' $(kubectl get service users-service -o=jsonpath='{.status.loadBalancer.ingress[0].hostname}')/signup
  - {"message":"User created.","user":{"_id":"660c46da5dbc5dd18d7b6517","email":"nasir@test.com","password":"$2a$12$azaUYs67b53iLVOr.m1nHu89EA1JquU6PnXEw7GdQ7q5AgITzjEue","__v":0}}
  - curl -X POST -H "Content-Type: application/json" -d '{"email": "nasir@test.com", "password":"a1234567"}' $(kubectl get service users-service -o=jsonpath='{.status.loadBalancer.ingress[0].hostname}')/login
  - {"token":"eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpYXQiOjE3MTIwODA2NDksImV4cCI6MTcxMjA4NDI0OX0.nNiLzbJbwP3DgTiraaEjFRbfpcgPZdrq876FOmdnWw0","userId":"660c46da5dbc5dd18d7b6517"}
- tasks-service) 헤더에 토큰 첨부하여 task 재조회
  - curl -X GET -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpYXQiOjE3MTIwODA2NDksImV4cCI6MTcxMjA4NDI0OX0.nNiLzbJbwP3DgTiraaEjFRbfpcgPZdrq876FOmdnWw0" $(kubectl get service tasks-service -o=jsonpath='{.status.loadBalancer.ingress[0].hostname}')/tasks
  - {"tasks":[]}
- tasks-service) tasks 추가
  - curl -X POST -H "Content-Type: application/json" -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpYXQiOjE3MTIwODA2NDksImV4cCI6MTcxMjA4NDI0OX0.nNiLzbJbwP3DgTiraaEjFRbfpcgPZdrq876FOmdnWw0" -d '{"text": "A second task", "title":"Do this,too"}' $(kubectl get service tasks-service -o=jsonpath='{.status.loadBalancer.ingress[0].hostname}')/tasks
  - {"task":{"_id":"660c47903a1f25bbc07df08d","title":"Do this,too","text":"A second task","user":"660c47903a1f2543c07df08c","__v":0}}
  - 근데 get으로 조회안됨
- tasks-service) tasks 제거 
  - curl -X Delete -H "Content-Type: application/json" -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpYXQiOjE3MTIwODA2NDksImV4cCI6MTcxMjA4NDI0OX0.nNiLzbJbwP3DgTiraaEjFRbfpcgPZdrq876FOmdnWw0" $(kubectl get service tasks-service -o=jsonpath='{.status.loadBalancer.ingress[0].hostname}')/tasks/660c47903a1f25bbc07df08d
  - {"message": "You are not authorized to delete this task."}
  - ?? 머지 인증에서 꼬인건가
  - 아니면 지난번 강의때 tasks디렉토리 만들고 파일저장하는부분 때문에?흠

sudo docker build . -t nasir17/kub-dep-users:latest && docker push nasir17/kub-dep-users:latest && kubectl rollout restart -f ../kubernetes
sudo docker build . -t nasir17/kub-dep-auth:latest && docker push nasir17/kub-dep-auth:latest && kubectl rollout restart -f ../kubernetes
sudo docker build . -t nasir17/kub-dep-tasks:latest && docker push nasir17/kub-dep-tasks:latest && kubectl rollout restart -f ../kubernetes
