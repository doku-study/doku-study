# Kubernetes로 데이터 & 볼륨 관리하기

## 모듈 소개
Kubernetes를 활용하면 궁극적으로 다중 노드 클러스터에 배포할 수 있음.       
- 로컬 머신의 도커와 유사하게 데이터 관리의 문제 발생
- 컨테이너 종료, 확장, 노드간 이동 시 데이터 보장 방법?

Kubernetes에서 볼륨을 다루는 방법
- 일반 볼륨
- 영구 볼륨, 영구 볼륨 클레임
- 환경변수를 활용한 작업

## 프로젝트 시작하기 & 우리가 이미 알고 있는 것
간단한 NodeJS API 앱
- 3000포트 수신, /story에 대한 GET/POST 요청 처리
- `docker compose up -d --build`를 통해 빌드 후 컨테이너 기동
  - GET) `curl localhost/story`
  - POST) `curl -X POST -H "Content-Type: application/json" -d '{"text": "My Text!\n"}' localhost/story`
  - 컨테이너 재시작 후 GET 하여도 조회가능 > 볼륨을 통해 데이터 보존

## Kubernetes & 볼륨 - Docker 볼륨 이상의 것
State: 앱에서 생성 및 사용하는 데이터
- 중요도에 따라 별도 DB, 파일에 영구적 저장 또는 임시로 메모리등에 보존
- 중요한 것은 컨테이너 재시작 후에도 해당 데이터가 보존되어야 함
- 쿠버네티스에서 컨테이너에 볼륨을 추가하는 방법

## Kubernetes 볼륨: 이론 & Docker와의 비교
pod template에 볼륨 탑재지점 설정 가능
- 워커노드의 로컬 볼륨
- CSP의 특정 볼륨

볼륨 수명
- 볼륨의 생명은 pod의 생명에 의존함
- 일반적으로는 pod의 생애주기를 따라가지만 별도로 유지 위해선 설정 필요

쿠버네티스 볼륨에는 다양한 드라이버와 유형이 존재
- docker/compose의 경우 로컬 머신에 의존적임
- 다양한 호스팅 환경(로컬,클라우드,데이터센터 등) 대응 가능

## 새 Deployment & Service만들기
샘플앱 kub-data-demo로 빌드
- docker build . -t nasir17/kub-data-demo
- docker push nasir17/kub-data-demo

deployment 설정
- replicas 1 
- images nasir17/kub-data-demo

service 설정
- ports 80:3000
- type LoadBalancer

## Kubernetes 볼륨 시작하기
Pod내 컨테이너 재시작시 볼륨 데이터 손실
- 언제? 저번예시처럼 /error, 또는 트래픽 과부하, 컨테이너 충돌 등
- 현재 볼륨미사용 설정에서는 데이터가 유실됨

다양한 유형의 [volumes](https://kubernetes.io/docs/concepts/storage/volumes/#volume-types) 지원
- AWS,Azure와 같은 클라우드 상의 스토리지
- 별도 데이터센터등을 토애 구축한 스토리지
- 로컬 스토리지
  - emptyDir
  - hostPath 등

## 첫 번째 볼륨: "emptyDir" 유형
/error 엔드포인트 업데이트
- 해당 경로로 요청시 process.exit(1) 되어 컨테이너 재시작
- 1 태그를 부여하여 재빌드/재푸시

deployment에 emptyDir volume 추가하기
- spec.template.spec에 `volumes:` 필드 추가
  - name: story-volume
  - emptyDir: {}
- spec.template.spec.containers[*]:에 `volumeMounts:` 필드 추가
  - mountPath: /app/story
  - name: story-volume

```
spec: 
  template:
    spec:
      containers:
        - name: story
          image: nasir17/kub-data-demo:1
          volumeMounts:
            - mountPath: /app/story
              name: story-volume
      volumes:
        - name: story-volume
          emptyDir: {}
```

## 두 번째 볼륨: "hostPath" 유형
emptyDir의 경우 파드에 개별적으로 부여되므로 파드간 공유X
\> hostPath를 사용하여 노드의 특정 경로를 Pod에 부여 가능
\> 특정 노드에 종속되는 단점은 있지만 일단 파드간 공유는 해결 가능

hostPath volume 추가하기
- spec.template.spec.volumes: 의 emptyDir를 hostPath로 변경
  - name: story-volume
  - hostPath:
    - path: /data
    - type: DirectoryOrCreate

```
spec: 
  template:
    spec:
      containers:
        - name: story
          image: nasir17/kub-data-demo:1
          volumeMounts:
            - mountPath: /app/story
              name: story-volume
      volumes:
        - name: story-volume
          hostPath: 
            path: /data
            type: DirectoryOrCreate
```

## "CSI" 볼륨 유형 이해하기
CSI=Container Storage Interpace
- 컨테이너 볼륨 탑재를 위한 표준 인터페이스
- 이를 활용한 볼륨 솔루션 구축 용이
  - EFS, EBS, etc...

## 볼륨에서 영구(Persistent) 볼륨으로
지금까지 활용한 볼륨 유형은 pod 제거/교체시 데이터 보존 X
- Pod, Node에 독립적인 영구 볼륨 활용 가능
- Pod와 Volume의 수명주기 분리
- 스토리지가 클러스터내 노드에 존재하지 않고 외부에 존재

## 영구 볼륨 정의하기
hostPath유형의 영구볼륨인 host-pv.yaml 생성
- capacity, volumeMode,acccessModes 추가설정 필요
```
apiVersion: v1
kind: PersistentVolume
metadata:
  name: host-pv
spec:
  capacity: 
    storage: 1Gi
  volumeMode: Filesystem
  storageClassName: standard
  accessModes:
    - ReadWriteOnce
  hostPath:
    path: /data
    type: DirectoryOrCreate
```

## 영구 볼륨 클레임 생성하기
pv 생성후, 파드에 할당하기 위해 pvc 생성 필요 > host-pvc.yaml
- volumeName, accessModes, requests 추가설정 필요
```
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: host-pvc
spec:
  volumeName: host-pv
  accessModes:
    - ReadWriteOnce
  storageClassName: standard
  resources:
    requests: 
      storage: 1Gi
```

pod 설정에 pvc 설정 추가 필요
```
# deployment.yaml
spec: 
  template:
    spec:
      volumes:
        - name: story-volume
          persistentVolumeClaim:
            claimName: host-pvc
```

## Pod에서 클레임 사용하기
pv 생성을 위해 스토리지 클래스 생성또한 필요함 > minikube에 default sc생성되어있음
- 생성 이후 kubectl get pv > standard sc사용, Bound 상태

어플리케이션이 사용하는 데이터에 따라 적절한 볼륨사용 필요
- 앱 데이터 (사용자 계정, 데이터 등) > 영구적 저장 필요 > pv
- 임시 데이터 (중간 결과, 등) > pod 자체 볼륨만으로도 충분

## 볼륨 vs 영구 볼륨
볼륨이 있으면 데이터 보존 가능
- (일반)볼륨: 컨테이너와는 독립적이지만 파드 종속적 
- 영구 볼륨: pod가 재생성되어도 데이터 유지

프로젝트 규모에 따라 적절한 볼륨유형 사용 필요
- 소규모 프로젝트면 Pod별 pv로도 사용 가능
- 프로젝트 규모가 거대해질수록 반복증가 > 피로 증가
- 대형 PV생성 후 PVC로 가져감으로써 반복감소/중앙통제 가능

## 환경 변수 사용하기
/story/text.txt는 코드에 하드코딩되어있음 > 환경변수로 유연하게사용가능
- story > process.env.STORY_FOLDER 교체
- spec.template.spec.container[*]: 필드에 env: 추가
  - \- name: STORY_FOLDER
  - value: story

```
# deployment.yaml
spec: 
  template:
    spec:
      containers:
        - name: story
          image: nasir17/kub-data-demo:2
          env:
            - name: STORY_FOLDER
              value: 'story'
```


## 환경 변수 & ConfigMaps
deployment의 spec 대신, 별도의 리소스에 K-V를 할당하여 가져다 쓰고자함
- environment.yaml 생성
  - a,k,m 설정 후 spec대신 data: 필드 추가
  - folder: 'story' 와 같은 K-V 추가

```
apiVersion: v1
kind: ConfigMap
metadata:
  name: data-store-env
data:
  folder: 'story'
```

- deployment.yaml  수정
  - value: 필드 대신 valueFrom.configMapKeyRef: 필드 추가
```
# deployment.yaml
spec: 
  template:
    spec:
      containers:
        - name: story
          image: nasir17/kub-data-demo:2
          env:
            - name: STORY_FOLDER
              valueFrom: 
                configMapKeyRef:
                  name: data-store-env
                  key: folder
```

## 모듈 요약
컨테이너 환경에서 볼륨 사용은 이미 실습했지만,  
k8s 환경에서는 여러 노드에서 컨테이너가 실행되기 때문에 데이터 유지 문제가 복잡해짐    
- Pod/Node에 직접 연결된 emptyDir/hostPath 유형 사용 방법
- Pod/Node와 분리된 영구볼륨(PV,Persistent Volume) 
- PV mount를 위한 PVC(Persistent Volume Claim), PV 생성을 위한 SC(Storage Class)
- 환경변수 활용을 위한 env 설정/configmap 생성
---

![volumes](https://blossun.github.io/assets/images/INFRA/kubernetes/image-20210404210021500.png) 
[Volumes](https://blossun.github.io/infra/kubernetes/05_-%EA%B8%B0%EB%B3%B8-%EC%98%A4%EB%B8%8C%EC%A0%9D%ED%8A%B8-_Volume/)
---

![Dynamic provisioning](https://blog.kakaocdn.net/dn/NM0QS/btrCKWA4o00/93TqcdRJV06ln0aas0iT21/img.png)    
[링크](https://happycloud-lee.tistory.com/256)


