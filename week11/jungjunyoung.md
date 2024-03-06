

## yaml 파일을 이용한 선언형 접근 방식 

프로젝트 루트에 yourFileName.yaml 을 생성해보자. 

파일 이름은 자유이며, 따라서 deployment 객체를 위한 yaml 이라고 생각하면 곤란하지만, deployment 만을 위한 yaml 파일임을 나타내기 위해 deployment.yaml 로 적어도 상관없다. 여기서는 deployment 를 위한 yaml 파일을 작성해보자.

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: second-app-deployment
spec:
  replicas: 1
  # template 은 항상 pod
  template:
    metadata:
      labels:
        app: second-app
    spec:
      containers:
        - name: second-node
          image: junzero741/kub-first-app:2
```



작성한 명세를 적용하여 배포를 시도해보자.

```bash
kubectl apply -f=deployment.yaml
```



배포를 시도하면 다음과 같은 에러가 나온다.

```bash
The Deployment "second-app-deployment" is invalid:
* spec.selector: Required value
* spec.template.metadata.labels: Invalid value: map[string]string{"app":"second-app"}: `selector` does not match template `labels`
```

처음 보는 selector 라는 키워드가 등장했다.





## selector

selector 는 어떤 pod 이 deployment 객체에 의해 컨트롤 될 것인지 선택하는 것으로, deployment.yaml 파일을 다음과 같이 수정해보자.

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
          image: junzero741/kub-first-app:2
```

replicas 밑에 selctor가 추가되었는데, 이는 mathLabels 에 작성된 키-값과 일치하는 label 을 갖고 있는 pod 만 deployment 에 의해 제어하겠다는 뜻이다.



이제 다시 배포를 시도하면 잘된다.

```bash
kubectl apply -f=deployment.yaml
```



그러나 아직까지는 해당 배포에 접근할 수 없는데, 그 이유는 service 객체를 만들지 않았기 때문이다.

위에서 명령적 접근으로 service 객체를 만들었던 것처럼, 선언적 방식으로 service 객체를 생성해보도록 하자.



## 선언적 Service 객체 생성

```yaml
apiVersion: v1
kind: Service
metadata:
  name: backend
spec:
  selector:
    app: second-app
  ports:
    - protocol: 'TCP'
      port: 80
      targetPort: 8080
    # - protocol: 'TCP'
    #   port: 443
    #   targetPort: 443
  type: LoadBalancer
```

새로운 yaml 파일을 생성하여 위 내용을 입력한다. 명령적 접근 방식으로 Service 객체를 생성했을 때와 대조해서 보면 좋다.

yaml 작성을 마친 뒤 적용해보자.

```bash
kubectl apply -f service.yaml
```

> 위에서 Deployment 를 적용할 때는 -f= 을 썼는데, 여기는 = 없이도 잘 동작한다. 뭐가 다른거지?



이제 minikube 에서 서비스해보면 웹 브라우저에 앱이 뜨는 걸 볼 수 있다.

```bash
minikube service backend
```



## 선언적 리소스 업데이트 & 삭제

이제 선언적 접근 방식으로 앱을 배포하는 방법까지는 알았는데, 앱을 수정하거나 삭제하려면 어떻게 해야할까?

우선 config 를 변경하려면 yaml 파일을 수정한뒤 `kubectl apply -f 수정한파일.yaml` 명령어로 적용만 다시 해주면 된다.

앱의 소스 코드(이미지) 를 변경하려면 Deployment 객체 선언 파일에서 image 를 변경한 뒤 똑같이 `kubectl apply -f 수정한파일.yaml` 로 적용만 다시 해주면 된다.



삭제의 경우에는, 위에서 했던 것처럼 명령적 접근 방식을 사용할 수도 있다.

```bash
kubectl delete deployment second-app-deployment
kubectl delete service backend
```



하지만 선언형 접근 방식이 더 깔끔하다.

```bash
kubectl delete -f=yourFileName.yaml -f=service.yaml
```

해당 방식은 해당 파일을 삭제하는게 아니라, 해당 파일에 의해 생성된 객체들을 삭제하는 방법이다.



<br />

## 다중 config 파일 vs 단일 config 파일

service 와 deployment 는 그 역할이 다르므로 파일을 나누는 것이 맞다고 생각할 수도 있다.

반면에, 둘은 항상 같이 쓰이니까 한 곳에 응집해있는게 맞다고 생각할 수도 있다.

이번에는 deployment 와 service 를 단일 config 파일에 선언해보자.

```yaml
apiVersion: v1
kind: Service
metadata:
  name: backend
spec:
  selector:
    app: second-app
  ports:
    - protocol: 'TCP'
      port: 80
      targetPort: 8080
    # - protocol: 'TCP'
    #   port: 443
    #   targetPort: 443
  type: LoadBalancer
## --- 를 통해 리소스간 구분을 줘야 한다.
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
          image: junzero741/kub-first-app
```

리소스 생성은 위에서 아래로 순차적으로 실행되므로, service 관련 내용을 deployment 관련 내용보다 위에 배치하여 service가 먼저 생성되도록 하는 것이 좋다.

왜냐하면, service 가 생성된뒤, service 의 selector 에 명시된 second-app 이라는 이름과 같은 이름을 갖고 있는 pod 이 생성되면 자동으로 이 service 에 속하기 때문이다.





## selector 에 대한 추가 정보

위에서 작성한 yaml 파일을 보면, 같은 selector 인데도 어떤 객체를 생성하느냐에 따라

matchLabels 를 사용하는 곳이 있고, 그렇지 않은 곳이 있다.

matchLabels 가 좀 더 현대적인 구문이고, 좀 더 최근의 것으로는 matchExpressions 가 있다.

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
  # expression 을 사용해 select 할 수도 있다.
  # selector:
  #   matchExpressions:
  #     - {key: app, operator: In, values: [second-app, first-app]}
```



## labels 을 이용한 그룹 삭제

각 객체에 label 을 부여해서 여러 객체를 같은 이름으로 그룹화하여 처리할 수 있다.

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: second-app-deployment
  labels:
    yourgroup: example
```



yourgroup 이란 레이블 키 중 example 이란 값을 가진 객체들 중, deployment, service 객체에 해당하는 것들을 지우는 명령이다.

```bash
kubectl delete deployments,services -l yourgroup=example
```





## livenessProbe 를 통한 health check

쿠버네티스는 pod이 정상적으로 동작하고 있는지 health check를 하고, 그렇지 않다면 pod 을 재시작하는 메커니즘을 갖고있다.

이 때, 쿠버네티스가 health check를 어떻게 실행할지에 대한 옵션을 livenessProbe를 통해 줄 수 있다.

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
    matchLabels:
      app: second-app
      tier: backend
  # expression 을 사용해 select 할 수도 있다.
  # selector:
  #   matchExpressions:
  #     - {key: app, operator: In, values: [second-app, first-app]}
  template:
    metadata:
      labels:
        app: second-app
        tier: backend
    spec:
      containers:
        - name: second-node
          image: junzero741/kub-first-app
          livenessProbe:
            httpGet:
              path: /
              port: 8080
            periodSeconds: 10
            initialDelaySeconds: 5
```

10초 마다 서비스의 / 라는 경로에 get 요청을 보내서 health check 를 한다.

처음 서비스가 구동되고 어느정도의 텀을 두고 싶으면 initialDelaySeconds 에 초를 명시하면 된다.



<br />



## 구성 옵션 자세히 살펴보기

쿠버네티스는 기본적으로 대상 이미지의 태그가 바뀌지 않으면 deployment 객체를 생성할 때 이미지를 다시 pull 해오지 않는다.

그러나 `imagePullPolicy` 를 always 로 세팅해두면, deployment 객체를 생성할 때마다 이미지를 다시 pull 한다.

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
    matchLabels:
      app: second-app
      tier: backend
  # expression 을 사용해 select 할 수도 있다.
  # selector:
  #   matchExpressions:
  #     - {key: app, operator: In, values: [second-app, first-app]}
  template:
    metadata:
      labels:
        app: second-app
        tier: backend
    spec:
      containers:
        - name: second-node
          image: junzero741/kub-first-app
          imagePullPolicy: always
          livenessProbe:
            httpGet:
              path: /
              port: 8080
            periodSeconds: 10
            initialDelaySeconds: 5
```

