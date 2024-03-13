
## 210~213. Kubernetes에서 볼륨은 왜 필요한가? state란 무엇인가?

- 컨테이너는 프로세스다.
- 즉, 어떤 고정된 데이터가 아니라 stateless한 대상이라고 볼 수 있다.
- 그래서 컨테이너에 볼륨이라는, state가 존재하는 객체를 결합해서 사용하는 것이다.

강의에서 말하는 state란? 
- 앱 내에서 생성되는 데이터지만, 컨테이너를 중지, 삭제하면서 같이 날아가면 안되는 데이터다.
- 유저의 계정 정보, 유저가 업로드한 기록 등
- 데이터베이스에 저장되어야 하는 데이터

## 214~215. emptyDir 타입과 hostPath 타입의 볼륨

### emptyDir 볼륨의 정의

```yaml
# delpoyment.yaml
    spec:
      containers:
        - name: story
          image: academind/kub-data-demo:1
          volumeMounts:
	        # 컨테이너 내부에서 어느 경로에 볼륨이 마운트될지를 결정
            - mountPath: /app/story
              name: story-volume
      volumes:
        - name: story-volume
          emptyDir: {}
```

- emptyDir은 기본적으로 pod-specific하다. 이 말인즉슨 한 pod는 하나의 emptyDir 볼륨을 가지고 있다는 뜻이다. 
- 만약 배포하고자 하는 앱의 pod replica가 여러 개라면, 하나의 replica에 있는 emptyDir 볼륨에 있는 데이터는 다른 replica에서 접근이 불가능해진다.
- emptyDir 볼륨은 pod가 매번 새로 시작할 때마다 빈 디렉토리를 생성한다. 하지만 pod를 이루는 컨테이너가 새로 시작한다고 해서 볼륨이 초기화되는 건 아니다. pod가 살아있는 한 (컨테이너가 replace되거나 재시작해도) emptyDir 볼륨 내 데이터는 그대로 유지된다.
- emptyDir로 명시만 하면 알아서 디폴트 옵션으로 지정한다.


### hostPath 볼륨의 정의

```yaml
# deployment.yaml
    spec:
      containers:
        - name: story
          image: academind/kub-data-demo:1
          volumeMounts:
            - mountPath: /app/story
              name: story-volume
      volumes:
        - name: story-volume
          hostPath:
            # 여기서 path는 host machine의 경로다. 어디에 데이터를 저장할지 지정
            path: /data
            # DirectoryOrCreate: 존재하지 않는다면 directory를 만든다.
            type: DirectoryOrCreate
```

- 앞서 살펴본 emptyDir 볼륨은, 볼륨 자체가 하나의 pod에만 종속되어 있기 때문에 pod가 죽으면 볼륨의 내용도 같이 사라져버린다는 치명적인 단점이 있었다.
- 이걸 개선하고자 한 게 hostPath라고 할 수 있다. hostPath 볼륨은 말 그대로 host machine(node)에 경로를 지정해서 node 안의 여러 개의 pod가 공유할 수 있도록 한다.
- host path가 이미 데이터를 가지고 있다면 컨테이너에서 바로 접근이 가능하다(어떻게 보면 편리한?).
- 도커 컨테이너에서 마치 bind mount 같은 역할을 한다. `hostPath` 는 host machine 상의 경로를 컨테이너에 bind해준다.


## 216. "CSI" 볼륨이란?

CSI(Container Storage Interface)가 아닌 다른 볼륨 타입에는 무엇이 있을까?
- NFS 볼륨 타입은 말 그대로 network file system에 연결해서 데이터를 저장할 수 있도록 지원한다. 
- 특정 클라우드 서비스에 맞게 지원하는 볼륨도 있다. 하지만 이미 deprecated되었거나 오래된 버전에서만 지원한다.
	- AWS  (`awsElasticBlockStore`)
	- Azure (`azureFile` 또는 `azureDisk` -> 둘의 차이는?)

그럼 특정 클라우드 서비스에 맞게 지원하는 볼륨을 왜 굳이 deprecated시켰을까?
그 질문에 대한 답이 바로 CSI의 존재 이유라고 할 수 있다.

### CSI(Container Storage Interface)는 '다목적 볼륨 드라이버'다

대표적인 클라우드 서비스로는 AWS, Azure, GCP가 있으니 이 세 가지에 대해서 볼륨 타입을 지정해놓으면 되는 것 아니냐, 할 수 있겠지만 사실 이것 외에도 (잘 쓰이진 않겠지만) 여러 클라우드 서비스 업체가 있을 거고 사용자마다 다 use case가 다를 것이다.

그럼 이 개별적인 케이스에 대해 일일이 볼륨 타입을 만들어놓으면 편리할까? -> No
CSI는, 이런 다양한 use case를 통합하고 상황에 맞게 쓸 수 있도록 유연하게 기능을 지원한다.

예를 들어 AWS 팀에선 자사의 Elastic File System 서비스를 사용자들이 사용하기 편하도록 CSI에 기능을 통합해놓았다.

CSI가 다른 볼륨 타입과 달리 좀 더 유연하고 다채로운 기능을 지원한다고 할 수 있는 이유다.

CSI는 사실 지금처럼 MiniKube로 로컬에서 테스트하고 데모 프로젝트할 때는 쓸 필요가 없지만, 실제 AWS 같은 클라우드 환경에서 배포할 때는 CSI를 쓰게 된다.

### k8s 공식 독스에서 CSI 개념을 설명하는 원문을 읽어보자

링크: https://kubernetes.io/blog/2019/01/15/container-storage-interface-ga/

> CSI was developed as a standard for exposing arbitrary block and file storage systems to containerized workloads on Container Orchestration Systems (COs) like Kubernetes. With the adoption of the Container Storage Interface, the Kubernetes volume layer becomes truly extensible. Using CSI, third-party storage providers can write and deploy plugins exposing new storage systems in Kubernetes without ever having to touch the core Kubernetes code. This gives Kubernetes users more options for storage and makes the system more secure and reliable.

> CSI는 쿠버네티스 같은 컨테이너 orchestration 시스템에서 사용하기 위한 파일 저장 시스템 표준으로 자리잡았다. CSI를 표준으로 채택하면서 k8s 볼륨 레이어의 확장성이 아주 커졌다고 할 수 있다. CSI를 사용하면 third-party 스토리지 제공 업체(클라우드 서비스 회사?)들도, 쿠버네티스 내부 코드를 건드릴 필요없이 그냥 플러그인을 작성하고 배포해서 자신들의 스토리지 시스템을 k8s 상에 제공할 수 있다. 덕분에 k8s 유저들은 스토리지 시스템을 선택할 수 있는 옵션도 늘어나고 스토리지 시스템도 더 안전하게 유지할 수 있다.




## 217. 영구 볼륨(Persistent Volume) 개념 이해하기

### 일반 볼륨(emptyDir, hostPath...)의 한계

- `hostPath` Minikube 같은 단일 노드 환경에선 데이터를 유지시킬 수 있을진 몰라도, 멀티 노트 환경에선 소용없다.
- 실제 배포 환경(AWS 같은)에서는 `hostPath` 으로 설정한 볼륨은 pod랑 노드에 종속되기 때문에 소용없다. 
- 물론 데이터의 성격마다 다르다. 유저의 로그 데이터?는 pod가 삭제되면 같이 없어져도 무방하지만, 유저의 계정 정보 등은 pod가 삭제돼도 유지되어야 한다.

컨테이너는 프로세스다. 즉 stateless한 대상이고, 데이터처럼 지속적으로 저장되는 것이 아니다.

### 영구 볼륨(Persistent Volume)의 특징

- 이름 그대로 pod와 node의 생명주기와 관계없이 계속 유지된다.
- 하지만 데이터 지속성보다 더 중요한 특징은, pod와 분리(detached)되어 있다는 점이다.
- 분리되어 있기 때문에 관리가 편해진다. 저장장치(볼륨)의 관리 권한을 여러 개의 pod에 걸쳐서 중앙 통제할 수 있다.
	- 클러스터 노드에 데이터를 저장하지 않고 외부(AWS Elastic Block Store 같은)에 저장해놓는다. 

### PVC(Persistent Volume Claim)
- pod가 영구 볼륨의 스펙을 요청하고 영구 볼륨을 사용하기 위한 일종의 청구서, 견적서라고 생각하자.
- pod 구성 파일에서 불러온다.
- 이것 하나만 있으면 여러 개의 pod에 걸쳐서 영구 볼륨에 접근할 수 있도록 설정할 수 있어서, pod마다 일일이 볼륨 설정을 할 필요가 없어진다.



## 218. 영구 볼륨 만들기(실습)

실습 환경은 다음과 같다.
- hostPath 드라이버 사용
- MiniKube (단일 노드 환경)

### host-pv.yaml 만들기

```yaml
# host-pv.yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: host-pv
spec:
  capacity: 
    storage: 1Gi
  volumeMode: Filesystem
  accessModes:
    - ReadWriteOnce
  hostPath:
    path: /data
    type: DirectoryOrCreate
```

- API 버전은 v1으로
- kind는 `PersistentVolume`
- metadata에는 영구 볼륨의 이름 (`host-pv`)
- 그리고 spec이 중요하다. spec은 말 그대로 영구 볼륨의 스펙(저장 용량, 저장 타입, 접근 모드 등)을 구체적으로 정의하는 파트다.

### 영구 볼륨의 스펙(spec)에 들어가야 할 것

1. **볼륨 타입**: 이 경우 `hostPath`로 지정했다.
2. **저장 용량(Capacity)**: 처음엔 4Gi(기가바이트)로 설정했는데 1Gi로 낮추었다.
3. **볼륨 모드**: `Filesystem` (디폴트) 또는 `Block` 으로 설정한다.
4. **접근 모드(Access Modes)**: 볼륨을 어떻게 접근할지 정의. `hostPath` 타입의 볼륨은 `ReadWriteOnce` 만 접근 가능하다. hostPath라는 설정 자체가 단일 노드의 read-write 볼륨으로만 마운트되도록 제한하기 때문이다.
	- 사실 이 경우가 특수한 거지, 여러 모드를 동시에 지정할 수 있다.






## 219. 영구 볼륨 클레임(PVC) 만들기

pod가 영구 볼륨에 접근할 수 있으려면 claim이 있어야 한다.
영구 볼륨의 스펙을 host-pv.yaml에 저장했다면, 이번엔 영구 볼륨의 claim을 위한 파일도 하나 만들자.

### host-pvc.yaml 파일에 영구 볼륨 spec을 직접 명시하기

```yaml
# host-pvc_ver1.yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: host-pvc
spec:
  capacity: 
    storage: 1Gi
  volumeMode: Filesystem
  accessModes:
    - ReadWriteOnce
  hostPath:
    path: /data
    type: DirectoryOrCreate
```

근데 이미 host-pv.yaml에 spec 정보를 저장해놨으니까, 간단히 이름(name)으로 불러올 수 있다.


```yaml
# host-pvc_ver2.yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: host-pvc
spec:
  # volumeName으로 지정만 하면 끝!
  volumeName: host-pv
```

그리고 이어서 accessMode와 resource를 지정한다.

```yaml
# host-pvc_ver2.yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: host-pvc
spec:
  volumeName: host-pv
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
```

deployment.yaml로 다시 돌아가서, 기존의 hostPath 대신에 

```yaml
spec:
  ...
  volumes:
    - name: story-volume
      # hostPath:
      #  path: /data
      #  type: DirectoryOrCreate
      persistentVolumeClaim: 
        claimName: host-pvc
        
```

- 볼륨 마운트된 건 사실 변함이 없다. 특정 pod를 위해 볼륨을 직접 설정하는 대신, claim으로 (동일한 볼륨을) 요청하는 것으로 바뀐 것일 뿐이다.


## 220. storage class
- 쿠버네티스는 관리자가 storage 관리, 볼륨 구성을 좀 더 세밀하게 할 수 있도록 도와준다.
- storage class는 영구볼륨 구성 파일과 함께 어떻게 storage가 관리되고 작동해야 하는지 정의한다.

storage class 상태는 다음 명령어로 확인할 수 있다.

```bash
# storage class의 줄임말
kubectl get sc
```

영구볼륨 구성 파일, host-pv.yaml의 spec에 storageClassName을 추가한다.

```yaml
# host-pv.yaml
...
spec:
	...
	storageClassName: standard
```

PVC에도 똑같이 추가한다.

```yaml
# host-pvc.yaml
...
spec:
	...
	storageClassName: standard
```

그 다음에 적용한다.

```bash
# 차례로 host-pv, 그 다음에 host-pvc
kubectl apply -f=host-pv.yaml
kubectl apply -f=host-pvc.yaml
```

그리고 확인하면

```bash
kubectl get pv 
kubectl get pvc
```




## 221. Normal Volume vs. Persistent Volume

### 볼륨의 존재 목적
- 결국 일반 볼륨이든 영구 볼륨이든 볼륨이란 데이터를 계속 유지하기 존재하는 것이다.
- (도커 개념을 다시 떠올려보면) 컨테이너를 재시작하거나 삭제하거나 새로 만들 때마다 데이터가 날라가지 않도록 데이터를 유지하기 위해서다.

### 일반 볼륨(Normal Volume)
- 사실 이런 용어는 없고, 영구 볼륨(persistent volume)과 비교하려고 만들어낸 말이다.
- pod와 같이 붙어다닌다(=생명 주기가 같다)
- 컨테이너와는 독립적이지만, pod와는 독립적이지 않다. 즉 pod를 삭제하면 여기 볼륨의 데이터도 삭제된다.
	- 볼륨의 종류에 따라 다르다.
	- `emptyDir` 옵션의 볼륨은 pod를 재시작하면 비어있는 상태로 초기화되지만, `hostPath` 옵션의 볼륨은 데이터를 유지한다.
- 볼륨을 어떻게 구성할지(어떤 타입인지 등등)는 pod template에 적는다.
- 단점: 만약에 k8s로 구축하는 프로젝트가 커지면 여러 개의 pod에 일일이 볼륨 옵션을 적어줘야 하기 때문에 귀찮고 번거로워진다.

### 영구 볼륨(Persistent Volume)

- "Standalone", 즉 혼자서도 잘 돌아가는 독립적인 볼륨이다.
- 영구 볼륨은 pod의 PVC(Persistent Volume Claim)로 생성된다. 
- pod와 독립적이다. 분명 pod에 의해 요청(**"claim"**)되지만 pod의 생명주기를 따라가지 않는다. 다른 node에서 pod가 재시작되거나 삭제돼도 영구 볼륨의 데이터는 날라가지 않는다.
- 규모가 큰 프로젝트(multi-pod)에서 더 다루기 쉽다. 구성 파일만 갖고 있으면 언제든지 재사용이 가능해 편리하다.
	- 관리자 입장에서 보면, 추상적인 수준(global level)에서 pod 템플릿을 직접 건드리지 않고 관리가 가능하니 더 쉽다.
	- 사실 본격적인 실습을 안해봐서 그런지 100% 와닿지는 않는다.
- 

### 결론: 언제 무얼 쓰는가?

- 그렇다고 꼭 영구 볼륨만 고집할 필요는 없다.
- 만약에 토이 프로젝트나 작은 규모의 프로젝트라면 영구 볼륨 쓰는 게 오히려 더 귀찮을 수도 있다. 어차피 작은 프로젝트에선 pod를 1~2개만 다룰  거라 pod를 삭제하면 볼륨도 삭제하는 게 간편하기 때문
- 하지만 일반적으로 k8s를 쓰는 케이스는, pod를 여러 개 구축하고 앱을 제대로 배포하려는 회사나 개발자들이지 않을까? 영구 볼륨 쓰는 법을 먼저 익히는 게 나아 보인다.


---





## 222. 환경변수 사용하기

### 요약
- 앱을 구성하는 소스코드(app.js)에 어떤 텍스트 파일을 읽어들이기 위해 파일 경로가 하드코딩되어 있다.
- 파일 경로를 바꿀 때마다 앱 안의 소스코드를 바꿔야 하므로 불편하다. 환경변수를 이용한다면 앱 안의 소스코드를 직접 건드릴 필요 없이 배포할 때만 바꾸면 되므로 유연하게 대처할 수 있다.
- 환경변수 설정은 pod의 구성 파일인 deployment.yaml에서 설정하면 된다. 애플리케이션 소스코드도 결국 pod안에서 배포할 것이기 때문.

### app.js 코드 수정 전

```javascript
const app = express();
// 경로명이 하드코딩되어 있다.
const filePath = path.join(_dirname, 'story', 'text.txt');
app.use(bodyParser.json()):
```


### app.js 코드 수정 후

```javascript
const app = express();
// 환경변수로 바꿔준다.
const filePath = path.join(_dirname, process.env.STORY_FOLDER, 'text.txt');
app.use(bodyParser.json());
```


### deployment.yaml 파일 구성

container 스펙 안에 env라는 키로 다음과 같이 추가해주었다.

- 환경'변수'니까 변수명(name)을 설정한다: `STORY_FOLDER`
- value에 폴더 이름을 지정한다: `'story'`

```yaml
env:
	- name: STORY_FOLDER
	  value: 'story'
```


![[2024-03-13_15-30-38.png]]


### 배포하기

- deployment.yaml 파일이 업데이트되었으니 이미지도 새로 pull해준다.
- ImagePullPolicy를 always로 설정해서, 바뀔 때마다 이미지를 새로 pull하도록 설정할 수도 있지만 여기 강의에서는 그냥 이미지 tag만 살짝 바꿔서 새로 pull하기로 한다.

```bash
# image 태그를 my_rep_name/kub-data-demo:1에서 my_rep_name/kub-data-demo:2로 변경
docker push my_rep_name/kub-data-demo:2

# 이미지 업데이트되기까지 조금 기다렸다가 실행
kubectl apply -f=deployment.yaml
```



---

## 223. 환경변수 사용하기 2편:  ConfigMaps 활용하기

### 요약
- 앞에서는 deployment.yaml의 containers 아래에 환경변수 key를 지정해서 환경변수를 설정했다.
	- 이렇게 하면 환경변수가 특정 컨테이너 구성에 종속되게 된다.
- 반면에 환경변수만 따로 모아서 집중적으로 관리할 수 있다. 즉, **환경변수만을 위한 별도의 파일**을 만들어서 따로 관리하는 방식이다.

### ConfigMaps 방식의 장점
- environment.yaml 파일을 따로 만들어야 한다.
- 별도의 파일로 구성한 환경변수는 여러 pod나 node에 공유할 수 있다.
- 환경변수를 특정 컨테이너 구성에 종속시키지 않고 분리시켜서 관리할 수 있다.


### environment.yaml 파일 구성하기

파일 이름은 environment.yaml 로 설정해서 구성 파일을 새로 만든다. (다르게 해도 상관없다)

```yaml
# environment.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: data-store-env
data:
  folder: 'story'
  # 여러 개의 key-value 쌍을 추가할 수 있다. 이 예제는 간단해서 하나만 필요
  # key: value..
```

그 다음에 이 파일을 kubectl로 적용하자.

```bash
kubectl apply -f=environment.yaml
```


### deployment.yaml 수정하기

deployment.yaml로 다시 넘어가서, pod가 environment.yaml 파일의 key-value 맵을 불러들여서 환경변수를 설정할 수 있도록 고쳐보자.

```yaml
env:
- name: STORY_FOLDER
# value: "story"
valueFrom:
	configMapkeyRef:
		name: data-store-env
		key: folder
```

- `valueFrom: configMapkeyRef`: "configMap에서 환경변수 값을 가져오겠다"
- `name`: environment.yaml의 metadata 아래에 지정한 name에 해당하는 변수를 가져온다.
- `key`: 하나의 환경변수 아래에도 여러 개의 key-value 쌍이 있을 수 있는데, 이 중 어느 쌍을 가져올지 key로 결정한다.

그리고 다 수정했으면 마찬가지로 적용한다.

```bash
kubectl apply -f=deployment.yaml
```

### deployment.yaml 환경변수 추가 전 vs. 후

![[2024-03-13_15-27-31.png]]


---

## 224. 모듈 요약

### Kubernetes에서의 볼륨이란?
- 기본적으로 볼륨은 pod의 spec에서 지정할 수 있다.
- k8s는 여러 가지 타입의 볼륨을 지원하는데, 이 중 가장 기초적이고 간단한 건 `emptyDir`이나 `hostPath`이지만 pod와 node와 생명주기를 같이 한다는 한계가 있다.
- 그 외에도 클라우드 서비스 회사(AWS, Azure, GCP 등)에 맞는 볼륨이나 

### 영구 볼륨(Persistent Volume)
- 더 복잡한 시나리오, 즉 관리해야 할 pod나 node가 많은 (k8s를 쓸 만한) 환경이라면 여러 pod나 node 간에 데이터를 지속적으로 공유해야 하고, 일부가 삭제되거나 재시작해도 데이터가 날라가면 안되기 때문에 영구 볼륨(persistent volume)을 써야 한다.

### PVC(Persisten Volume Claim)
 - 볼륨의 크기, 스펙 등을 지정하는 일종의 주문서(견적서)다.
 - pod 구성 파일에서 PVC를 불러온다. PVC를 통해서 pod는 특정 영구 볼륨에 접근할 수 있다.

### 환경변수
- 컨테이너 spec에서 `env` 키로 지정하거나, ConfigMap으로 name-value 쌍을 만든 다음에 별도의 파일로 만들어서 관리할 수 있다.