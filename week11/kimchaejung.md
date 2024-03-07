# 실전 Kubernetes - 핵심 개념 자세히 알아보기

## Deployment 객체에 Pod와 컨테이너 사양(Specs) 추가

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: second-app-deployment
  # selector가 있어야 에러가 안 난다
  selector:
    matchLabels:
      app: second-app
      tier: backend
spec:
  // 동시에 실행하고자 하는 pod 갯수
  replicas: 3
  // pod의 정의, 언제나 pod에 대한 것을 가리킨다
  template:
    metadata:
      labels:
        // deployment, depl, tier 등 원하는 이름으로 네이밍 가능
        app: second-app
        tier: backend
    // 각 pod에 대한 spec
    spec:
      containers:
      - name: second-node
        image: blcklamb/kub-first-app:2
```

### selector가 필요한 이유

deployment 객체는 계속해서 모든 pod들을 보는데, 제어해야하는 pod가 있는지 확인한다, 그 제어하는 것을 고르기 위해 selector가 필요하다

- 종류

  - matchLabels
  - matchExpressions (좀 더 복잡한 selector)

  [Labels and Selectors](https://kubernetes.io/docs/concepts/overview/working-with-objects/labels/#resources-that-support-set-based-requirements)

```yaml
apiVersion: apps/v1
kind: Deployment
# ...
spec:
  # ...
  selector:
    matchExpressions:
      - { key: app, operator: In, values: [second-app, first-app] }
  template:
    metadata:
      labels:
        app: second-app
        tier: backend
    # ...
```

```yaml
# 연결된 클러스터에 설정 파일 적용
kubectl apply -f=deployment.yaml
kubectl get deployments
```

## Service 객체 선언적으로 추가

- `service.yaml`
- 아래의 예시는 second-app이라는 값의 app label을 가진 모든 포드를 노출시킨다는 것

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
      port: 80
      targetPort: 8080
  type: LoadBalancer
```

```bash
kubectl apply -f=service.yaml
minikube service backend
```

## 객체 업데이트 & 삭제

```bash
kubectl delete -f=deployment.yaml,service.yaml
kubectl delete -f=deployment.yaml -f=service.yaml
```

## 단일 Config 파일

- `master-deployment.yaml`

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
      port: 80
      targetPort: 8080
  type: LoadBalancer
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: second-app-deployment
spec:
  # 동시에 실행하고자 하는 pod 갯수
  replicas: 3
  selector:
    matchLabels:
      app: second-app
      tier: backend
  # pod의 정의, 언제나 pod에 대한 것을 가리킨다
  template:
    metadata:
      labels:
        app: second-app
        tier: backend
    # 각 pod에 대한 spec
    spec:
      containers:
        - name: second-node
          image: blcklamb/kub-first-app:2
```

- service를 먼저 위치시키는 것이 Best practice라고 한다. selector가 있기 때문에 동적으로 해당 부분을 연결시킬 수 있기 때문

```yaml
kubectl apply -f=master-deployment.yaml
minikube service backend
```

## label로 객체 삭제

- 객체 최상단 metadata의 labels에서 정의한 label로 지정한 경우 해당 label로 삭제 가능

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: second-app-deployment
  labels:
    group: example
spec:
  replicas: 3
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
          image: blcklamb/kub-first-app:2
```

```yaml
kubectl delete deployments,services -l group=example
```

## 활성 프로브(liveness probes)

- 쿠버네티스의 컨테이너가 실행 중인지 확인하기 위한 설정
- 디폴트 값에 반응하지 않는 애플리케이션이 있거나 `/` 가 아닌 다른 요청을 전송하여 그 상태를 확인하려는 경우에 유용하다

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: second-app-deployment
  labels:
    group: example
spec:
  replicas: 3
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
          image: blcklamb/kub-first-app:2
          livenessProbe:
            httpGet:
              path: /
              port: 8080
            periodSeconds: 10
            initialDelaySeconds: 5
```

[Configure Liveness, Readiness and Startup Probes](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/)

[kubernetes Pod의 진단을 담당하는 서비스 : probe](https://medium.com/finda-tech/kubernetes-pod의-진단을-담당하는-서비스-probe-7872cec9e568)

## 더 자세한 구성 옵션

- `imagePullPolicy`
  always의 경우: 항상 lastest 버전을 가져온다.

  [Images](https://kubernetes.io/docs/concepts/containers/images/#image-pull-policy)
