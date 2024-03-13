# 새롭게 알게된 점



## 들어가며

- 쿠버네티스에는 궁극적으로 애플리케이션을 다중 시스템, 다중 노드 클러스터에 배포할 수 있다는 아이디어가 있음.

- 배포할 때 데이터를 저장하고 관리하는 방법에 대해 알아봄.





## Kubernetes & 볼륨 - Docker 볼륨 이상

**State** 

- 데이터로 상태를 변환할 수 있다 -> ?
- 애플리케이션에서 생성되고 사용되는 데이터지만, 손실되어서는 안됨. 



- 사용자 생성 데이터 VS
  - 주로 데이터베이스나, 파일에 저장 

- 애플리케이션에 의해 생성(혹은 지워지는)되는 중간 결과 데이터  
  - 메모리나 임시 DB 테이블 혹은 파일

> 핵심은 이 데이터가 컨테이너 재시작 후에도 살아남아야 한다는 것.



컨테이너가 중지되고 제거된다 하더라고 위 데이터들은 저장되어야 함. 

여기서 다시 볼륨 개념이 필요!

 

- 하지만, 우리가 컨테이너를 직접적으로 실행하지는 않는다.
- 때문에 쿠버네티스가 컨테이너에 볼륨을 지정하고 구성해주는 방식이 필요 



## Kubernetes & 볼륨

> Kubernetes Volume - Background
>
> 컨테이너 상태는 저장되지 않으므로 컨테이너 수명 동안 생성되거나 수정된 모든 파일이 손실됩니다. 
>
> 충돌 중에 kubelet은 깨끗한 상태로 컨테이너를 다시 시작합니다. 
> 여러 컨테이너가 하나에서 실행되고 `Pod`파일을 공유해야 할 때 또 다른 문제가 발생합니다. 
>
> 모든 컨테이너에서 공유 파일 시스템을 설정하고 액세스하는 것은 어려울 수 있습니다. 
>
> 쿠버네티스 [Volume](https://kubernetes.io/docs/concepts/storage/volumes/)추상화는 이 두 가지 문제를 모두 해결합니다.



- 쿠버네티스가 볼륨을 컨테이너에 탑재할 수 있음. 

  - 예를 들어, deployment를 설정할 때, pod의 일부로 시작될 컨테이너네 볼륨을 탑재해야한다는 지침을 pod template에 추가할 수 있음.  

  

- **쿠버네티스는 다양한 볼륨 유형과 드라이버를 지원.** 

  - 도커와는 다르게 쿠버네티스에서는 여러 노드에서 애플리케이션을 실행할 수 있고, 다른 클라우드 & 호스팅 프로바이더에서도 실행할 수 있음. 
  - 다양한 유형의 볼륨을 지원하기 때문에 , 데이터 가 실제로 저장되는 위치와 관련하여 매우 유연함.
    - 지원 볼륨
      - pod의 로컬 볼륨 지원
      - 클라우드 벤더의 특정 볼륨 (EBS)

-  **볼륨의 수명이 pod의 수명에 따라 다르다는 것이 특징** 

  - 볼륨은 쿠버네티스에 의해 시작되고 관리되는 pod, 의 일부이기 때문.

    - pod에 종속적이다.

    - 컨테이너를 다시 시작하고 제거하는 것은 볼륨의 수명에 영향을 미치지 않음.
    - pod가 삭제되면, 볼륨도 삭제됨.



쿠버네티스에서 관리하는 볼륨은 도커에서 관리하는 볼륨과 다소 차이가 있음. 

핵심 아이디어는 동일하지만, 쿠버네티스 볼륨이 조금 더 강력함.

| Kubernetes Volumes                                           | Docker Volumes                                               |
| ------------------------------------------------------------ | ------------------------------------------------------------ |
| 많은 종류의 서로 다른 드라이버와 타입을 지원<br />- 다양한 호스트에서 사용해야하기 때문에 데이터 저장방법에 대해 유연한 지원 | 기본적으로 드라이버와 타입을 지원하지 않음<br />- 하나의 머신안에서만 작동하므로 다양한 스토리지 시스템에 지원이 필요하지 않음. |
| 볼륨이 반드시 영구적인 것은 아님<br />- pod의 수명주기에 따라감. | 볼륨은 사용자가 수동으로 지우기 전까지 영구적임.<br />- 사용자에 의해 관리됨. |
| 볼륨은 컨테이너를 재시작하거나 삭제해도 그대로 남아있음.     | 볼륨은 컨테이너를 재시작하거나 삭제해도 그대로 남아있음.     |



## 새 Deployment와 service 만들기

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
          image: codongmin/kub-data-demo:1
```

```yaml
apiVersion: v1
kind: Service
metadata:
  name: story-service
spec:
  selector:
    app: story
  type: LoadBalancer
  ports:
    - protocol: "TCP"
      port: 80
      targetPort: 3000
```





### Kubernetes 볼륨 시작하기 

> Kubernetes는 다양한 유형의 볼륨을 지원합니다. [Pod](https://kubernetes.io/docs/concepts/workloads/pods/) 는 동시에 **여러 볼륨 유형을 사용**할 수 있습니다. [임시 볼륨](https://kubernetes.io/docs/concepts/storage/ephemeral-volumes/) 유형에는 **포드의 수명**이 있지만 [영구 볼륨은](https://kubernetes.io/docs/concepts/storage/persistent-volumes/) **포드의 수명을 넘어 존재**합니다. Pod가 더 이상 존재하지 않으면 Kubernetes는 임시 볼륨을 삭제합니다. 그러나 **<u>Kubernetes는 영구 볼륨을 삭제</u>**하지 않습니다. 특정 포드에 있는 모든 종류의 볼륨에 대해 컨테이너를 다시 시작해도 데이터가 보존됩니다.
>
> 기본적으로 볼륨은 포드의 컨테이너에 액세스할 수 있는 일부 데이터가 포함된 디렉터리입니다. 해당 디렉토리가 어떻게 형성되는지, 이를 뒷받침하는 매체 및 그 내용은 사용되는 특정 볼륨 유형에 따라 결정됩니다.

- 현재는 볼륨을 사용하지 않아 데이터가 휘발됨. 

- 여러가지 볼륨 타입을 지원하는데 그 중 "emptyDir" 에 대해서 사용해봄.



###  emptyDir 볼륨 유형

- 볼륨 유형을 지정하기 위해서는 pod를 정의하고 구성하는 곳에 볼륨을 정의해주어야 함. 

- 현재 구조에서는 별도의 볼륨이 지정되어있지 않음. 
  - 때문에 컨테이너가 별도의 에러를 뱉어 종료되면 쿠버네티스가 이를 감지하고 재실행해주는데 
  - 이때 컨테이너에 저장되어있던 데이터도 함께 소실됨. 

```yaml
# deployment.yaml
...
  template:
    metadata:
      labels:
        app: story
    spec:
      containers:
        - name: story
          image: codongmin/kub-data-demo:1
          volumeMounts:
            - mountPath: /app/story
              name: story-volume
      volumes:
        - name: story-volume
          emptyDir: {}
```

1. 사용가능한 볼륨을 정의 (volumes)
2. 컨테이너와 볼륨을 마운트 (volumeMounts)
   1. 컨테이너 내부경로와 (mountPath)
   2. 컨테이너 내부경로에 사용할 볼륨이름을 지정 (name)



- Pod의 일부가 되어야하는 모든 볼륨을 정의할 수 있음.
  - 그러면 해당 Pod에 위치하는 모든 컨테이너들은 해당 볼륨을 사용할 수 있음. 
- emptyDir은 기본적으로 pod가 시작될때마다 새로운 빈 디렉토리를 생성함.
  - pod가 살아있는 한, 디렉토리를 활성 상태로 유지하고 데이터를 채움
  - 컨테이너가 재시작되거나, 삭제되도 살아 있음. 



> 볼륨을 정의하는 포드의 경우 `emptyDir`포드가 노드에 할당될 때 볼륨이 생성됩니다. 이름에서 알 수 있듯이 `emptyDir`볼륨은 처음에는 비어 있습니다. 포드의 모든 컨테이너는 볼륨의 동일한 파일을 읽고 쓸 수 `emptyDir`있지만 해당 볼륨은 각 컨테이너의 동일하거나 다른 경로에 마운트될 수 있습니다. 어떤 이유로든 노드에서 포드가 제거되면 해당 노드의 데이터가 `emptyDir`영구적으로 삭제됩니다.
>
> **참고:** 컨테이너 충돌은 노드에서 포드를 제거 *하지 않습니다 .* 볼륨 의 데이터는 `emptyDir`컨테이너 충돌 시에도 안전합니다.
>
> an의 일부 용도는 `emptyDir`다음과 같습니다.
>
> - 디스크 기반 병합 정렬과 같은 스크래치 공간
> - 충돌 복구를 위한 긴 계산 체크포인트
> - 웹 서버 컨테이너가 데이터를 제공하는 동안 콘텐츠 관리자 컨테이너가 가져오는 파일을 보관합니다.
>
> 필드 는 볼륨이 저장되는 `emptyDir.medium`위치를 제어합니다 `emptyDir`. 기본적으로 `emptyDir`볼륨은 환경에 따라 디스크, SSD, 네트워크 스토리지 등 노드를 지원하는 모든 매체에 저장됩니다. `emptyDir.medium`필드를 로 설정하면 `"Memory"`Kubernetes는 대신 tmpfs(RAM 지원 파일 시스템)를 마운트합니다. tmpfs는 매우 빠르지만 디스크와 달리 작성한 파일은 해당 파일을 작성한 컨테이너의 메모리 제한에 따라 계산됩니다.
>
> 기본 미디어에 대해 크기 제한을 지정하여 볼륨의 용량을 제한할 수 있습니다 `emptyDir`. 스토리지는 [노드 임시 스토리지](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/#setting-requests-and-limits-for-local-ephemeral-storage) 에서 할당됩니다 . 다른 소스(예: 로그 파일 또는 이미지 오버레이)에서 채워지면 `emptyDir`이 제한 전에 용량이 부족해질 수 있습니다.



### hostPath 볼륨 유형

- emptyDir 은 사용하기 유용하지만, 만약의 Pod의 인스턴스의 개수가 여러개라면(replica) 상황이 다름.
  - 트래픽이 다른 pod로 리다이렉션 되었기 때문에 기존 데이터에 접근할 수 없음.
  - 기존 데이터가 있는 pod가 아닌 다른 pod로 접근하게 되는 경우 의도하고자 한 데이터를 얻을 수 없음. 

- hostPath는 노드(pod를 실행하는 실제 머신)에서 경로를 설정할 수 있음. 
  - 그리고 그 경로의 데이터가 각각의 pod에 직접 노출됨. 
  - 동일한 pod에서 모든 요청을 처리하는 경우에만 유용함.



```yaml
# deployment.yaml
...
  template:
    metadata:
      labels:
        app: story
    spec:
      containers:
        - name: story
          image: codongmin/kub-data-demo:1
          volumeMounts:
            - mountPath: /app/story
              name: story-volume
      volumes:
        - name: story-volume
          hostPath:
            path: /data
            type: DirectoryOrCreate
```

1. 경로 지정
2. 경로 생성 타입 지정

- 여러 Pod가 경로를 공유하기 때문에 데이터 접속이 가능함.
- 이 유형도 한계는 존재. 만일 단일 노드가 아닌 여러 노드라면 hostPath도 각각의 노드에 한정될 수 밖에 없음. 

>**경고:**
>
>볼륨 유형을 사용하면 `hostPath`많은 보안 위험이 발생합니다. 볼륨 사용을 피할 수 있다면 `hostPath`그렇게 해야 합니다. 예를 들어 [`local`PertantVolume](https://kubernetes.io/docs/concepts/storage/volumes/#local) 을 정의하고 이를 대신 사용하세요.
>
>승인 시간 검증을 사용하여 노드의 특정 디렉터리에 대한 액세스를 제한하는 경우 해당 `hostPath`볼륨 의 마운트를 **읽기 전용으로** 추가로 요구하는 경우에만 해당 제한이 적용됩니다 . 신뢰할 수 없는 포드에 의한 호스트 경로의 읽기-쓰기 마운트를 허용하면 해당 포드의 컨테이너가 읽기-쓰기 호스트 마운트를 파괴할 수 있습니다.



### CSI 유형

> [CSI( 컨테이너 스토리지 인터페이스](https://github.com/container-storage-interface/spec/blob/master/spec.md) )는 컨테이너 오케스트레이션 시스템(예: Kubernetes)에 대한 표준 인터페이스를 정의하여 임의의 스토리지 시스템을 컨테이너 워크로드에 노출합니다.

- 컨테이너 스토리지 인터페이스 
- 매우 유연한 볼륨 유형 



## 볼륨에서 영구(Persistent) 볼륨으로

- 볼륨은 pod가 삭제될 때 같이 삭제된다. 
  - 임시데이터의 경우에는 적합
- pod의 수명주기와 볼륨의 수명주기를 별도로 가져가는 영구 볼륨, 분리!
  - 중요 데이터의 경우 적합

- 노드가 아닌 클러스터에 별도의 리소스를 갖는 개념 (노드에 독립적)
  - Persistent Volume(PV)
  - Persistent Volume(PV) 여러개도 가능함. 
  - PV Claim이 노드와 포드에게세 PV에 접근하는 것을 도와줌 



## 영구 볼륨 정의하기

- Host-pv.yaml 정의

```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: host-pv
spec:
  capacity:
    storage: 1Gi
  volumeMode: FileSystem
  accessModes:
    - ReadWriteOnce # 단일 노드에서만
    # - ReadOnlyMany # 여러 노드에서 읽기 가능
    # - ReadWriteMany 
  hostPath: # ReadWriteOnce만 가능, 단일 노드에서만 지원하기 때문
    path: /data
    type: DirectoryOrCreate

```



## 영구 볼륨 클레임 생성하기

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: host-pvc
spec:
  volumneName: host-pv
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi

```

- 동적 볼륨 프로버저닝
- Pod에서 영구볼륨에 대한 클레임을 만드는데 사용할 수 있는 클레임 정의 



## Pod에서 클레임 사용하기

- 스토리지 클래스
  - 쿠버네티스에서 관리자에게 스토리지 관리방법과 볼륨 구성 방법을 세부적으로 제어할 수 있게 도와주는 개념 

```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: host-pv
spec:
  capacity:
    storage: 1Gi
  volumeMode: FileSystem
  storageClassName: standard # 스토리지 클래스 
  accessModes:
    - ReadWriteOnce 
  hostPath:
    path: /data
    type: DirectoryOrCreate
```

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: host-pvc
spec:
  volumneName: host-pv
  accessModes:
    - ReadWriteOnce
  storageClassName: standard # 스토리지 클래스 
  resources:
    requests:
      storage: 1Gi
```



## 볼륨 vs 영구 볼륨

- 볼륨은 데이터를 저장할 수 있게 도와줌.

| Normal Volumes                            | Persistent Volumes                                    |
| ----------------------------------------- | ----------------------------------------------------- |
| Pod와 붙어있고 Pod와 생명주기를 같이한다. | 클러스터의 리소스로서 standalone하게 존재             |
| Pod와 함께 정의되고 생성된다.             | standalone으로 동작하고 pvc와 함께 동작함.            |
| Global level에서 관리되기 힘들다.         | 한번만 정의하고 여러번 사용할 수 있다. 관리가 편하다. |





## 환경 변수 사용하기

- 도커와 마찬가지로 환경변수를 지원함

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
          image: codongmin/kub-data-demo:1
          env:
            - name: STORY_FOLDER
              value: "story"
          volumeMounts:
            - mountPath: /app/story
              name: story-volume
      volumes:
        - name: story-volume
          persistentVolumeClaim:
            claimName: host-pvc

```

```yaml
env:
  - name: STORY_FOLDER
    value: "story"
```



## 환경 변수 & ConfigMaps

- 별도의 파일이나, 리소스로 관리하여 여러 포드의 컨테이너가 공유할 수 있는 환경변수 관리 방법도 있음. 

```yaml
# environment.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: data-store-env
data:
  folder: "story"
```

```yaml
# development.yaml
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
          image: codongmin/kub-data-demo:1
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

```yaml
env:
  - name: STORY_FOLDER
    valueFrom:
      configMapKeyRef:
        name: data-store-env
        key: folder
```



# 함께 이야기하고 싶은 점

- 확실히 쿠버네티스 분야는 아직 변화점이 많은 분야라고 느낌. 
  - 신생, 강의에서 봤던 기능들이 대부분 제거되거나, 변경된 것을 보아 변화가 매우 빠른 분야라고 느꼈음. 
