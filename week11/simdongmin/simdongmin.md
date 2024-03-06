# 새롭게 알게된 점

- 선언적 접근 방식 - 배포 구성 파일 작성 - > Pod와 스펙 상세
- Selector
- livnessProbe
- 단일 config 파일
- 구성 옵션



## Recap



- Service 객체는 pod를 클러스터나 외부 세계로 노출 해줌



## 배포 구성 파일에 Pod Spec 명시



```yaml
apiVersion: apps/v1

# 생성하려는 쿠버네티스의 객체 종류를 지정
# Service, Job 등 지정되어 있는 리소스 유형을 기재
kind: Deployment

# kind에 세부 Metadata 설정
metadata:
  name: second-app-deployment

# 배포 파일의 핵심, kind를 구성하는 방법을 정의하는 구역
spec: # DeploymentSpec
  replicas: 1 # default=1
  selector:
  	matchLabels:
        app: second-app
  template: # podTemplateSpec
    metadata:
      labels:
        app: second-app
        tier: backend
    spec: # PodSpec = replica spec
      containers:
        - name: second-node
          image: codongmin/kub-first-app:2
        # - name: ...
        #   image:

```



Deployment의 `template` 는 항상 Pod를 나타냄, 따라서 별도의 `kind` 옵션을 줄 필요 없음

https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.23/#podtemplatelist-v1-core



`kubectl apply -f=deployment.yaml` 배포 시작



## Selector란 ?

- deployment template 에 적용된 pod는 deployment가 apply될 때 생성된다

- deployment 는 쿠버네티스에서 동적인 개체이다. 

  - 예를 들어 deployment가 생성된 후, pod수를 확장한다면, 생성된 pod는 이미 존재하는 deployment에 의해 자동으로 관리됨.

  - 따라서 deployment는 고정된 것이 아니라 외부에 있는 모든 pod를 지속적으로 감시하며 제어해야하는 pod 가 있는지 살핌

- 그리고 selector(거의 모든 리소스와 작동)로 제어할 pod를 선택한다.



deployment에 따라 다양한 유형의 selector가 있음.

- matchLabels
  - deployment에 의해 제어되어야 하는 pod 레이블의 키-값 쌍을 아래에 명시 
  - matchLabels에 지정된 것만 제어됨
  - matchLabels는 AND 조건?
- matchExpressions
  - 이후에 다룸




## Service 생성

```yaml
apiVersion: v1

kind: Deployment

metadata:
  name: backend

spec:
  selector:
  	app: second-app
 # 	tier: backend

```



Selector는 이 리소스(service)에게 제어되거나 연결되어야 하는 다른 리소스(pod)를 식별합니다.

여기서는 service의 일부가 되어야 하는 pod를 정의 



서비스로 deployment를 제어하지 않고, 대신 pod로 제어한다

pod는 deployment에 의해 생성된다. 그럼에도 불구하고 selector을 사용하여 개별 pod를 선택함.



service의 selector는 deployment의 selector과 다르게 동작함. 

- deployment에서 label이 다른 pod는 다른 deployment의 pod로 간주됨 (AND 조건, 레이블의 키-값 쌍이 모두 동일애햐함.)
  - `app:second-app` 과 `tier:backend`를 둘 다 label로 가지고 있는 pod와 `app:second-app` label 하나만 가지고 있는 pod는 다르다 (?)
- service에서 selector에서 label을 가지고만 있어도 pod를 인식함.(OR 조건, 레이블중 하나만 들고 있어도 선택 대상)
  - `app:second-app` 를 가진 pod들을 동일 service로 그룹화할 수 있음.  



selector의 배경 아이디어 

- 다른 리소스(service)에 연결되거나, 다른 리소스(service, deployment)에 의해 제어되어야 하는 다른 리소스(pod)를 표현할때 매우 유연하게 사용할 수 있음.



```yaml
...

spec:
  selector:
  	app: second-app
  ports:
  	- protocol: 'TCP'
  		port: 80 # 외부로 노출시킬 port
  		targetPort: 8080 # container에 있는 port
  #	- protocol: 'TCP'
  #		port: 443
  #		targetPort: 443
 	type: LoadBalancer
```

위 설정에 따라 이제 deployment에 의해 생성된 pod(`app: second-app` 레이블을 가진)가 이 서비스에 의해 노출될 수 있음.

그러나 어떤 pod들이 노출되어야 하는지는 알지만(`app: second-app` 레이블을 가진 pod 그룹) 어떻게(port, 세부 등등) 노출되어야하고, 개별 pod중 어떤 포드가 노출되어야 하는지는 아직 모름

`ports` 옵션으로 지정해줄 수 있음.

- `protocol`
- `port`
- `targetPort`

여러 pod가 있는 경우 여러 `ports` 를 설정해 줄 수 있음.



`type` 옵션

- ClusterIP 가 기본값, 내부적으로 노출된 IP
- NodePort : 클러스너 내부에서만 엑세스 가능, 기본적으로 실행되는 워커 노드의 IP와 포트에 노출하고,
- LoadBalancer :  외부 세계 엑세스를 원하는 경우 -> 클러스터 인프라의 LB에서 외부에서 접속할 IP 주소를 할당, 그러면 이 service와 service에서 노출되는 pod에 연결할 수 있음.  



서비스 적용

`kubectl apply -f service.yaml`



선언적 접근 방식의 장점과 권장 이유

- 에러, 실수 방지

- 변경 쉽고, 반복 쉬움

- 공유 쉬움



## 리소스 업데이트 & 삭제

### 리소스 입데이트 방법

- deployment.yaml 수정 후 `kubectl apply -f deployment.yaml`

- yaml 파일을 변경하고 apply 명령어 실행 시 구성을 변경하는 것이 매우 쉬움



### 리소스 입데이트 삭제 

- `kubectl delete [resource, name]` 로 삭제 가능
- `kubectl delete -f=[file name].yaml,[file2 name].yaml` 로 삭제 가능



## 다중 vs 단일 config 파일

- 구성파일에 하나로 합칠 수도 있고 별개로 가져갈 수 도 있음(여태까지 진행한 방식)



```yaml
apiVersion: v1
kind: Service
metadata:
  name: backend
spec:
  selector:
    app: second-app
  ports:
    - protocol: "TCP"
      port: 80 # 외부로 노출시킬 port
      targetPort: 8080 # container에 있는 port
  type: LoadBalancer
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: second-app-deployment
spec:
  replicas: 1
  selector:
    matchLabels:
      app: second-app
      tier: backend
  template:
    metadata:
      labels:
        app: second-app
        tier: backend
    spec:
      containers:
        - name: second-node
          image: codongmin/kub-first-app:2
```

- 단일 설정 파일에서는 `---` 로 객체 구분을 할 수 있으면 대시를 기준으로 필요한 리소스들의 명세를 적어주면됨
- 앞에 있는 리소스 정의가 먼저 생성됨. 원하는 만큼 리소스를 정의할 수 있음.
- Service 리소스를 보통 앞에 둠
- <u>Selector 가 있기 때문에 (Service에) 이후에 생성되는 pod들은 동적으로 추가된다.</u>(?)

-  `kubectl apply -f=master-deployment.yaml` 로 동일하게 실행 가능



## Label & Selector에 대한 추가 정보 

- Selector : 다른 리소스레 연결하는데 사용 

  - 예) Deployment에 pod를 연결하거나, Service에 경로를 연결하는 용도

- matchExpressions

  - 더 많은 작업을 수행할 수 있는 더 많은 구성 옵션을 가진 항목을 선택하는, 보다 강력한 방법.
  - 일치하는 객체를 갖기 위해 모두 충족되어야 하는 표현식의 목록을 가짐 

  ```yaml
  apiVersion: apps/v1
  kind: Deployment
  metadata:
    name: second-app-deployment
    labels:
    	group: example
  spec:
    replicas: 1
    selector:
      matchExpressions:
        - {key: app, operator: In,values: [secode-app, first-app]}
  ```

  - 유연성이 요구되는 경우 matchExpressions 셀렉터를 사용할 수 있음. 
  - operator: In, NotIn 등 지원

- `kubectl delete deployments,services -l group=example ` 과 같이 옵션값에 레이블로 필터링 할 수 있는 기능을 지원함.



## 활성 프로브

- 쿠버네티스가 pod와 컨테이너가 정상인지 아닌지의 여부를 확인하는 방법과 관련이 있음.

- 컨테이너가 실행중인지 확인하기 위해 pod가 컨테이너를 확인하는 방법을 설정할 수 있음. 

  ```yaml
  apiVersion: apps/v1
  kind: Deployment
  metadata:
    name: second-app-deployment
  spec:
    replicas: 1
    selector:
      matchLabels:
        app: second-app
        tier: backend
    template: 
      metadata:
        labels:
          app: second-app
          tier: backend
      spec: 
        containers:
          - name: second-node
            image: codongmin/kub-first-app:2
            livnessProbe:
              httpGet:
                path: /
                port: 8080
              periodSeconds: 10
              initialDelaySeconds: 5
  ```

- 여러가지 방식으로 지정할 수 있음, 예시에서는 Http Get 요청으로 실행중인 애플리케이션의 헬스체크를 진행함.

- livenessProbe를 정의하는 것은 디폴트 값에 반응하지 않는 애플리케이션이 있거나, 특정 경로에 요청을 전송하여 그 상태를 확인하려는 경우에 매우 유용함 

### 

## 구성 옵션 자세히 살펴보기

- 컨테이너 수준에서 더 많은 구성을 지정할 수 있음. 

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: second-app-deployment
spec:
  replicas: 1
  selector:
    matchLabels:
      app: second-app
      tier: backend
  template: 
    metadata:
      labels:
        app: second-app
        tier: backend
    spec: 
      containers:
        - name: second-node
          image: codongmin/kub-first-app:2
          imagePullPolicy: Always
          livnessProbe:
            httpGet:
              path: /
              port: 8080
            periodSeconds: 10
            initialDelaySeconds: 5
```

- `imagePullPolicy`:  Always, Never, IfNotPresent (이미지 풀링 전략)



# 함께 이야기하고 싶은 점

- 아직은 추상적인 내용들이 많아 적극적으로 실감이 안나는군요...

- 쿠버네티스를 활용하여 서비스에 적용한 사례를 읽어봤는데 흥미로웠습니다.
  - https://engineering.linecorp.com/ko/blog/apply-warm-up-in-spring-boot-and-kubernetes
  - 쿠버네티스의 probe 를 활용하여 웜업 적용 & 성능 향상 사례 
    - 서버를 구동하고 트래픽 받기 전에 한번 러닝시켜 라이브러리, 기능 등을 미리 메모리에 로딩 시키는 전략 = 웜업
    - 트래픽에 대한 반응성이 높아짐(로딩 지연성 낮아짐) 
  - 금번에 배운 livenessProbe의 사례 예시를 접한 것 같이 재밌게 읽었습니다. 
    - 사례에서도 강의에서 예시를 든 것 처럼 별도의 HTTP API와 헬스체크 핸들러를 두어 구현했습니다. 
  - 다음에 한번 실험해보고 싶은 생각이.. 글감 확보! 
