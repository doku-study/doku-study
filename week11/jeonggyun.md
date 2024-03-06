### 명령적 vs 선언적

---

- ***명령적***
    - 모든 명령문을 다 숙지하고 있어야 한다.
    - 많은 명령문 속에서 실수가 발생하기 마련이다.
- ***선언적***
    - `docker compose`와 비슷하게 yaml 파일에 한번에 작성하고, 실행할 수 있다.
    - 해당 파일에 우리의 요구사항을 정의하기만 하면 끝이다.

### 배포 구성 파일 생성

---

- 배포 파일 구성
    
    ```yaml
    apiVersion: apps/v1 # 버전
    kind: Deployment  # 생성하려는 쿠버네티스 객체의 종류를 명시
    metadata: 
    	name: second-app-deployment
    spec: # 해당 객체의 특성을 명시
    	replicas : 1 # pod의 개수
    	template:
    		metadata: 
    			labels:
    				app : second-app # app과 second-app이라는 키와 값은 정하기 달렸다. -> 추후 용이
    		spec: # 이 spec은 pod에 대한 spec이다.
    			containers: # pod에서 실행할 컨테이너 목록
    				- name : second-node
    					image: wjdrbs51/kube-first-app:2 
    ```
    
- 위의 파일을 실행하기 위해선
    
    ```yaml
    kubectl apply -f=deployments.yaml
    ```
    
    - selector가 없다고 에러가 뜬다. → selector는 선언적 접근 방식에서 중요한 개념
    

### Selector란?

- Selector를 통해 해당 객체가 제어해야할 하는 다른 리소스들을 명시해 줄 수 있다.
- 즉, 여기선 `Deployment`가 관리 해야하는 `Pod`를 명시 해 준다. 
추후 생성하게 되는 Pod를 트래킹 할 수 있다
    
    ```yaml
    apiVersion: apps/v1 
    kind: Deployment  
    metadata: 
    	name: second-app-deployment
    spec: 
    	replicas : 1 
    	**selector:
    		matchLabels:
    			app: second-app** 
    	template:
    		metadata: 
    			labels:
    				app : second-app 
    		spec: 
    			containers: 
    				- name : second-node
    					image: wjdrbs51/kube-first-app:2
    ```
    
    - 이렇게 함으로써,  `app: second-app` 라벨을 가진 pod를 제어해야한다고 deployment에게 명시 해줄 수 있다.
    - 아직까진, selector의 필요성에 대해서 와닿지 않는다. 필요성을 느낄 수 있는 실습이나 상황을 마주쳤으면 좋겠다. 
    (이미 `spec.template.metadata.labels`에 해당 pod의 라벨을 명시함으로써, deployment가 관리해야할 pod를 명시해 줬는데 또 중복으로 selector를 활용해 명시해주는 느낌.. 근데 추후 요긴하게 쓰이니깐 중요한거겠지?)

### Service

→ 외부에서 앱에 접속해 보자.

- Service 객체의 역할을 상기 시켜 보면, `pod`객체를 외부 세계에 노출 하는데에 있다.
    
    ```yaml
    apiVersion: v1
    kind: Service 
    metadata:
    	name: backend
    spec:
    	selector:
    		app: second-app 
    
    	ports:
    		- protocol: 'TCP'   # 유형
    			port: 80          # 외부로 노출시킬 포트
    			targetPort: 8080  # 내부의 타겟 포트(앱이 실행되고 있는 해당 머신의 포트)
    
    	type: LoadBalancer
    ```
    

→ 이렇게 함으로써, `app: second-app`이라는 모든 pod는 그룹화 되어, 해당 service에 의해 제어된다.

→ 이를 실행하려면, `kubectl apply -f=service.yaml`

### 객체를 제거하려면

- `kubectl delete deployment second-app-deployment`
    - or
- `kubectl delete -f=deployment.yaml`
- `kubectl delete -f=deployment.yaml -f=service.yaml`
- `kubectl delete deployment -l group=example`
→ 이렇게 특정 라벨을 가진 deployment를 제거할 수 있다.

### 다양한 객체를 단일 파일로 작성할 수 있다.

```yaml
<특정 객체를 위한 yaml>
---
<또 다른 객체를 위한 yaml>
---
<...>
```

→ `Deployment` 보다 `Service` 먼저 작성해주는것을 권장. K8S는 동적

### 활성 프로브

→ 클러스터 내의 특정 `pod`가 잘 실행 중인지 확인할 수 있도록 정의

→ 시스템이 자동으로 애플리케이션의 문제를 감지하고, 필요한 경우 자체적으로 복구할 수 있도록 도와줌

```yaml
apiVersion: apps/v1
kind: Deployment  
metadata: 
	name: second-app-deployment
spec: 
	replicas : 1 
	template:
		metadata: 
			labels:
			app : second-app 
		spec: 
			containers: 
				- name : second-node
					image: wjdrbs51/kube-first-app:2
					**livenessProbe:
						httpGet:
							path: /
							port: 8080
						periodSeconds: 10** # 10초마다 한번씩 생존여부를 전송
						**initialDelaySeconds: 5** # 컨테이너가 실행 된 후 최초의 전송까지 대기시간
```

→ livenessProbe가 없어도, deployment가 알아서 고장난 파드는 바꿔 끼워주는 녀석인줄 알았는데?

- 도와줘 ChatGPT
    
    <aside>
    <img src="/icons/notification_red.svg" alt="/icons/notification_red.svg" width="40px" /> 답변 )
    
    Kubernetes의 Deployment 컨트롤러는 Pod의 상태를 모니터링하고, 원하는 상태를 유지하려고 시도합니다. 그러나, **`livenessProbe`** 없이는 Deployment가 Pod가 "잘 작동되지 않는다"는 것을 자동으로 감지할 수 있는 방법이 제한적입니다.
    
    ### **Kubernetes의 자동 재시작 없이 Pod 상태 관리**
    
    Deployment와 ReplicaSet은 지정된 수의 Pod 복사본이 실행 중이고 사용 가능한지를 보장하기 위해 디자인되었습니다. 이들은 Pod가 예상대로 실행되고 있는지에 대한 내부적인 건강 상태(예: 프로세스가 충돌하여 종료된 경우)를 직접 모니터링하지 않습니다. 대신, Pod가 어떤 이유로든 종료되면, ReplicaSet은 누락된 Pod를 대체하기 위해 새로운 Pod를 생성합니다.
    
    ### **`livenessProbe`의 중요성**
    
    **`livenessProbe`**는 컨테이너가 살아있고 정상적으로 작동하고 있는지를 Kubernetes에 알려주는 메커니즘입니다. Pod 내의 컨테이너가 더 이상 제대로 응답하지 않거나, 데드락 상태에 빠진 경우(프로세스는 실행 중이지만, 정상적인 작업을 수행하지 못하는 상태), **`livenessProbe`**가 실패하면 Kubernetes는 이를 감지하고 해당 컨테이너를 자동으로 재시작합니다.
    
    ### **재시작 없이는 불충분한 상황들**
    
    - **데드락:** 애플리케이션이 데드락 상태에 빠지면, 프로세스는 여전히 실행 중이지만, 아무런 유용한 작업도 수행하지 못합니다. 이 경우, 외부에서는 Pod가 정상적으로 실행 중으로 보이지만, 실제로는 응답을 하지 못할 수 있습니다. **`livenessProbe`** 없이는 이러한 상황을 자동으로 해결할 수 없습니다.
    - **무한 루프:** 애플리케이션이 무한 루프에 빠진 경우에도 유사하게, Pod는 "정상적으로" 실행 중으로 보일 수 있으나, 실제로는 아무런 진전도 없는 상태가 됩니다.
    - **응답 불가:** 네트워크 문제나 애플리케이션 레벨의 오류로 인해 컨테이너가 외부 요청에 응답하지 못하는 경우도 있습니다. 이런 경우에도 **`livenessProbe`**가 있으면 문제가 있는 컨테이너를 재시작하여 자동으로 복구할 수 있습니다.
    
    따라서, **`livenessProbe`**는 컨테이너의 상태를 보다 세밀하게 감시하고, 문제를 자동으로 해결할 수 있는 방법을 제공합니다. 이는 애플리케이션의 가용성과 안정성을 크게 향상시킬 수 있으며, 시스템 운영자가 수동으로 개입하지 않아도 문제를 해결할 수 있게 해줍니다.
    
    </aside>
    

### 다양한 구성요소들

---

- imagePullPolicy
    - 이미지를 가져오는 방식 → Always, Never, etc
    - Always → image의 이름과 tag가 동일하더라도, 항상 가져온다.
- 문서를 봐라