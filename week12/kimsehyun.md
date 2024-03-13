## 221. Normal Volume vs. Persistent Volume

### 볼륨의 존재 목적
- 결국 일반 볼륨이든 영구 볼륨이든 볼륨이란 데이터를 계속 유지하기 존재하는 것이다.
- (도커 개념을 다시 떠올려보면) 컨테이너를 재시작하거나 삭제하거나 새로 만들 때마다 데이터가 날라가지 않도록 데이터를 유지하기 위해서다.

### 일반 볼륨(Normal Volume)
- 사실 이런 용어는 없고, 영구 볼륨(persistent volume)과 비교하려고 만들어낸 말이다.
- pod와 같이 붙어다닌다(=생명 주기가 같다)고 생각하자.
- 컨테이너와는 독립적이지만, pod와는 독립적이지 않다. 즉 pod를 삭제하면 여기 볼륨의 데이터도 삭제된다.
	- 볼륨의 종류에 따라 다르다.
	- `emptyDir` 옵션의 볼륨은 pod를 재시작하면 비어있는 상태로 초기화되지만, `hostPath` 옵션의 볼륨은 데이터를 유지한다.
- 볼륨을 어떻게 구성할지(어떤 타입인지 등등)는 pod template에 적는다.
- 단점: 만약에 k8s로 구축하는 프로젝트가 커지면 여러 개의 pod에 일일이 볼륨 옵션을 적어줘야 하기 때문에 귀찮고 번거로워진다.

### 영구 볼륨(Persistent Volume)

- "Standalone", 즉 혼자서도 잘 돌아가는 독립적인 볼륨이다.
- 영구 볼륨은 pod의 PVC(Persistent Volume Claim)로 생성된다. 일종의 청구서, 견적서라고 생각하면 되려나?
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