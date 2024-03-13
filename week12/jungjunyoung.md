## State (상태)

애플리케이션에 의해 생성되고 사용되는, 손실되지 않아야 하는 데이터.

> 리액트 등의 애플리케이션이 종료되면 제거되어야 하는, memory based state와는 조금 다른, 인프라 차원에서의 state 개념을 설명하고자 한듯

* 유저 생성 데이터
  * DB 나 파일로 저장되곤 함
* 앱 생성 데이터
  * 메모리나 임시 DB 테이블, 또는 파일에 저장됨





<br />

## 쿠버네티스와 볼륨

도커에서는 컨테이너의 상태를 저장하기 위해 볼륨을 썼다.

쿠버네티스 또한 컨테이너와 관련된 툴이므로, 쿠버네티스에서 볼륨을 통해 컨테이너의 데이터를 보존하기 위해서는 쿠버네티스만의 별도 설정이 필요하다.



### 다양한 volume type 또는 driver 가 지원된다.

* 로컬 볼륨 (ex: Node)
* 클라우드 프로바이더가 제공하는 볼륨
* [상세 목록](https://kubernetes.io/docs/concepts/storage/volumes/#volume-types)



### 볼륨의 생애주기는 pod 과 함께한다.

* 볼륨은 컨테이너가 재시작, 삭제되더라도 살아있다.
* 그러나 pod 이 삭제될때는 볼륨도 함께 삭제된다.



### 쿠버네티스와 도커의 볼륨 비교

|                   | 쿠버네티스                                                   | 도커                                                         |
| ----------------- | ------------------------------------------------------------ | ------------------------------------------------------------ |
| 볼륨 저장공간     | 다양한 종류의 driver, type을 지원하기 때문에 데이터 저장 공간을 AWS, 데이터 센터 등 유연하게 정할 수 있음. | 기본적으로 driver, type 에 대한 지원이 없고, 볼륨은 기본적으로 로컬에 저장되기 때문에 데이터를 해당 머신에 저장할 수밖에 없음 |
| 볼륨 영속성       | pod 제거시 볼륨이 함께 제거되므로, 볼륨이 반드시 영원하진 않음 | 수동으로 볼륨을 지우기 전까지는 영원함                       |
| 컨테이너와의 관계 | 컨테이너가 재시작되고 삭제되더라도 볼륨은 살아있음           | 컨테이너가 재시작되고 삭제되더라도 볼륨은 살아있음           |





<br />

## 쿠버네티스의 다양한 볼륨 type들

위에서 쿠버네티스의 볼륨은 도커의 볼륨과 달리 다양한 driver, type 을 지원한다고 했었다.

중요한 것은, 이런 다양한 type 들이 컨테이너 내부에서 볼륨이 작동하는 방식에는 영향을 끼치지 않는다는 것이다. (볼륨을 위한 로컬 경로가 있고, 도커와 함께 사용하는 방식 등)

driver 나 type 에 의해 달라지는 것은 데이터가 컨테이너 외부에 저장되는 방식이다.



### emptyDir

항상 새로운 디렉토리를 생성하는 방법.

pod의 replica 가 한개뿐일 때 유용한 방법.

만약 replica 를 확장하면, 두 팟 간에 데이터가 공유되지 않을 수 있다는 단점이 있다.

```yaml
	apiVersion: apps/v1
kind: Deployment
metadata:
  name: story-deployment
spec:
  replicas: 1
  selector:
    matchLabels:
      app: story
  template:
    metadata:
      labels:
        app: story
    spec:
      containers:
        - name: story
          image: junzero741/kub-data-demo:1
          # volumeMounts : 컨테이너에 마운트 될 볼륨 바인딩
          volumeMounts:
          # mountPath : 마운트될 컨테이너 내부의 경로
          # /app : 단순히 Dockerfile 을 찾을 작업 디렉토리
          # /app/story : app.js 에서 /story 경로에 데이터를 저장하고 있음. 이 경로를 볼륨에 적용
            - mountPath: /app/story
              name: story-volume
      # volumes: 볼륨 설정
      volumes:
        - name: story-volume
          # 쿠버네티스에서 사용할 수 있는 다양한 volume type 중에 emptyDir 선택
          # 항상 새로운 디렉토리를 생성한다.
          emptyDir: {}
```



<br />

### hostPath

emptyDir 와 달리, hostPath는 항상 새로운 디렉토리를 생성하지 않는 방법이다.

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: story-deployment
spec:
  replicas: 2
  selector:
    matchLabels:
      app: story
  template:
    metadata:
      labels:
        app: story
    spec:
      containers:
        - name: story
          image: junzero741/kub-data-demo:1
          # volumeMounts : 컨테이너에 마운트 될 볼륨 바인딩
          volumeMounts:
          # mountPath : 마운트될 컨테이너 내부의 경로
          # /app : 단순히 Dockerfile 을 찾을 작업 디렉토리
          # /app/story : app.js 에서 /story 경로에 데이터를 저장하고 있음. 이 경로를 볼륨에 적용
            - mountPath: /app/story
              name: story-volume
      # volumes: 볼륨 설정
      volumes:
        - name: story-volume
          # 쿠버네티스에서 사용할 수 있는 다양한 volume type 중에 hostPath 선택
          hostPath:
            # path: mountPath 에 명시한 경로와 공유할 volume 경로
            path: /data
            # path 에 명시된 폴더가 존재하면 그 폴더를 사용하고, 아니면 폴더를 생성하는 옵션
            type: DirectoryOrCreate
```

<br />

### CSI

Container Storage Interface 의 약자.

쿠버네티스 팀에서 추가한 비교적 새로운 유형의 볼륨 타입.

다양한 클라우드 프로바이더와 다양한 사용 사례에 대해 더 많은 기본 내장된 유형을 추가할 필요가 없도록 하고, 대신 명확하게 정의된 인터페이스를 노출한다.

인터페이스 기반이기 때문에 유연하고, 따라서 누구나 이 인터페이스를 활용하는 드라이버 솔루션을 구축할 수 있다.

정의된 인터페이스만 구현하면 되기 때문에, AWS 의 EFS 를 쿠버네티스 볼륨의 스토리지 솔루션으로 추가하기가 매우 쉽다.

CSI 를 지키는 전세계의 모든 스토리지 솔루션 (심지어는 직접 구축해도 됨) 을 연결할 수 있다.



<br />

## 영구 볼륨

볼륨은 기본적으로 pod 이 삭제될 때 함께 삭제된다.

minikube 에서는 항상 하나의 workerNode 를 갖기 때문에, 위에서 살펴본 hostPath 와 같은 방법이 유효했다.

그러나 AWS 와 같은 클라우드 프로바이더에서는 여러 workerNode 를 갖기 때문에 더이상 hostPath 역시 유효하지 않다.

만약 데이터베이스가 저장되어 있는 컨테이너가 pod 이 삭제됨과 함께 삭제된다면, 데이터베이스의 모든 데이터가 사라지는 것이다.

따라서 pod 의 스케일링, 교체, 삭제 등에 영향을 받지 않는, pod과 독립적으로 존재하며 데이터를 보존할 수 있는 방법이 필요하다.

그래서 영구 볼륨이 존재하는 것이다.

영구 볼륨의 주요 컨셉은 클러스터 내부에는 볼륨이 존재하지 않고, 볼륨에 접근하는 claim 만 존재하는 것이고,

데이터가 저장되는 볼륨은 클러스터 외부 어딘가에 존재하는 것이다. (ex: 특정 클라우드 스토리지 서비스)



<br />

## 영구 볼륨 정의하기

```yaml
# host-pv.yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: host-pv
spec:
  # /data 라는 경로의 영구 볼륨에 최대 1GB 의 용량을 저장할 수 있도록 설정.
  capacity:
    storage: 1Gi
  volumeMode: Filesystem
  accessModes:
    # 단일 노드에 의해 읽기/쓰기 볼륨으로 마운트될 수 있음
    # hostPath 타입은 하나의 노드에 대해서만 실행 가능한 타입이므로, ReadWriteOnce 만 사용가능
    - ReadWriteOnce
    # - ReadOnlyMany
    # - ReadWriteMany
  hostPath:
    path: /data
    type: DirectoryOrCreate
```

영구 볼륨을 정의했으니,  pod 에서 해당 볼륨을 사용할 claim 도 정의해보자.



<br />

## 영구 볼륨 claim 정의하기

```yaml
# host-pvc.yaml
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
      # 최대값은 persistent volume 이 제공하는 capacity
      storage: 1Gi
```



해당 claim 을 pod 에 연결해보자.



```yaml
#deployment.yaml

apiVersion: apps/v1
kind: Deployment
metadata:
  name: story-deployment
spec:
  replicas: 2
  selector:
    matchLabels:
      app: story
  template:
    metadata:
      labels:
        app: story
    spec:
      containers:
        - name: story
          image: junzero741/kub-data-demo:1
          volumeMounts:
            - mountPath: /app/story
              name: story-volume
      volumes:
        - name: story-volume
          # 볼륨 claim 연결
          persistentVolumeClaim:
            claimName: host-pvc
```

> Deployment 에서는 볼륨에 대한 설정은 모두 PersistnetVolume, 혹은 PersistentVolumeCliam 파일에 맡기고, 어떤 볼륨 클레임에 연결할 걸지만 선언한게 인상적이다.



<br />

## 스토리지 클래스

쿠버네티스에서 관리자에게 스토리지 관리 방법과 볼륨 구성 방법을 세부적으로 제어할 수 있게 해주는 개념.

`kubectl get sc` 명령어를 통해 활성화된 스토리지 클래스를 조회할 수 있다.

default 스토리지 클래스를 사용하도록 선언해보자.

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: host-pvc
spec:
  volumeName: host-pv
  accessModes:
    - ReadWriteOnce
  # standard: kubectl get sc 를 통해 조회하면 나오는 default 스토리지 클래스.
  storageClassName: standard
  resources:
    requests:
      storage: 1Gi
```

```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: host-pv
spec:
  capacity:
    storage: 1Gi
  volumeMode: Filesystem
  # standard: kubectl get sc 를 통해 조회하면 나오는 default 스토리지 클래스.
  storageClassName: standard
  accessModes:
    - ReadWriteOnce
  hostPath:
    path: /data
    type: DirectoryOrCreate
```



<br />

## 영구 볼륨 적용하기

영구 볼륨, 볼륨 클레임까지 모두 선언했으니 이제 순서대로 적용을 해보자.

순서는 볼륨을 만들고 해당 볼륨에 대한 클레임을 선언하는 것이 일반적이다.

```bash
kubectl apply -f=host-pv.yaml
kubectl apply -f=host-pvc.yaml
kubectl apply -f=deployment.yaml
```



<br />

## 볼륨 vs 영구 볼륨

볼륨과 영구 볼륨의 차이점에 대해 알아보자.

| volume                                                       | persistent volume                                            |
| ------------------------------------------------------------ | ------------------------------------------------------------ |
| pod 에 종속적이므로, pod 이 제거되거나 교체되면 제거됨.      | 영구 볼륨은 독립적인 클러스터 리소스이므로, pod 에 독립적임. |
| pod 과 함께 선언되고 생성됨                                  | 독립적으로 생성되고, PVC(Persistent Volume Claim)으로 접근할 수 있음 |
| 구축을 위해 반복적인 작업이 많고, 글로벌 레벨에서 관리하기 어렵다는 문제가 있음. | 한 번 선언되면 여러 곳에서 사용될 수 있음                    |



<br />

## 환경변수

위의 deployment.yaml 파일에서는 app.js 에서 story 라는 폴더에 데이터를 저장할 것이라고 하드코딩 되어있었다.

이를 환경변수를 사용하도록 변경해보자.

```javascript
const filePath = path.join(__dirname, process.env.STORY_FOLDER, 'text.txt');
```



```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: story-deployment
spec:
  replicas: 2
  selector:
    matchLabels:
      app: story
  template:
    metadata:
      labels:
        app: story
    spec:
      containers:
        - name: story
          image: junzero741/kub-data-demo:2
          # env
          env:
            - name: STORY_FOLDER
              value: 'story'
            - mountPath: /app/story
              name: story-volume
      volumes:
        - name: story-volume
          persistentVolumeClaim:
            claimName: host-pvc
```

이제 이미지를 다시 빌드하고, 도커 허브에 push 후 deployment 를 다시 apply 하면 잘 된다.



<br />



## 환경변수 & ConfigMap

위의 방식대로면 각 pod (deployment) 마다 환경변수의 키-값을 명시해줘야 해서 글로벌 적용에는 조금 귀찮다.

쿠버네티스에서 제공하는 ConfigMap 오브젝트를 통해 환경변수 설정을 분리해보자.

```yaml
# environment.yaml

apiVersion: v1
kind: ConfigMap
metadata:
  name: data-store-env
data:
  folder: 'story'
  #key: value..
```



객체 적용해주고..

```bash
kubectl apply -f=environment.yaml
```



deployment.yaml 도 해당 환경변수를 참조하게 수정해주자.

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: story-deployment
spec:
  replicas: 2
  selector:
    matchLabels:
      app: story
  template:
    metadata:
      labels:
        app: story
    spec:
      containers:
        - name: story
          image: junzero741/kub-data-demo:2
          # STORY_FOLDER 라는 환경변수의 키의 값은
          # data-store-env 라는 이름을 가진 ConfigMap 오브젝트에서
          # folder 라는 키를 가진 변수의 값 (environment.yaml 참조)
          env:
            - name: STORY_FOLDER
              valueFrom:
                configMapKeyRef:
                  name: data-store-env
                  key: folder
          volumeMounts:
            - mountPath: /app/story
              name: story-volume
      volumes:
        - name: story-volume
          persistentVolumeClaim:
            claimName: host-pvc
```



