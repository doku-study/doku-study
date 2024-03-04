# 실전 Kubernetes - 핵심 개념 자세히 알아보기

## Pod와 컨테이너 사양(Specs) 추가
spec: 필드를 통해 Deployment에 대한 정보를 추가할 수 있다.
- replicas: // pod 인스턴스의 수
- template: # deployment를 통해 생성되는 pod 정의
  - metadata: # deploy가 아닌, pod에 대한 metadata
    - labels: # K-V 형식으로 pod label 설정
      - app: second-app
  - spec: # deploy가 아닌 pod에 대한 spec 설정
    - containers: # pod의 컨테이너 목록, list 형식
      - \- name: second-node # 컨테이너  이름 설정
      -   image: nasir17/kub-first-app # 컨테이너 이미지 설정

```
apiVersion: apps/v1
kind: Deployment
metadata:
  name: second-app-deployment
spec:
  replicas: 1
  template:
    metadata: 
      labels:
        app: second-app
    spec: 
      containers:
        - name: second-node
          image: nasir17/kub-first-app
```

- kind:pod 등은 명시하지않음. DeploymentSpec의 PodTemplateSpec에는 metadata와 spec 필드만 받기 때문
https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.26/#deployment-v1-apps

kubectl apply -f deployment.yaml
- create 대신 apply 명령어를 통하여 실행
  - -f=--file

현재 구성은 selector 설정이 누락되어 실행에 실패한다.

## Label 및 Selector로 작업하기
deployment의 spec: 필드에 selector 키 추가 또한 필요하다.
- spec:
  - selector:
    - matchLabels: # pod template label의 KV 추가
      - app: second-app

```
spec:
  selector:
    matchLabels:
      app: second-app
```

deployment가 감시할 pod에 대한 명시적 연결
- deployment는 동적으로 리소스(pod) 생성 및 감소
- deploy 외부의 pod를 감시하며, 제어해야할 pod를 label-selector로 추적
  - matchLabels: label을 통한 일치
  - matchExpressions: regex 표현식을 통한 일치

## 선언적으로 Service 만들기
service.yaml을 작성해서 service 생성
- kind: Service 제외하곤 deployment와 전반적으로 유사
- spec.selector: 별도 matchLabels/exp 없음 > label만 사용
- ports: 
  - port: service가 받는 포트
  - targetPort: service가 전달하고자 하는 포트

```
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
  type: LoadBalancer
```

![맨날헷깔림](https://img1.daumcdn.net/thumb/R1280x0/?scode=mtistory2&fname=https%3A%2F%2Fblog.kakaocdn.net%2Fdn%2Fcz6smA%2Fbtr5R1lzsfE%2FkaNhCS5BNNbODYlQsOi8Wk%2Fimg.png)

## 리소스 업데이트 & 삭제
리소스 업데이트 > kubectl apply -f [fileName].YAML
- config가 있는 YAML에서 필요 변경값 변경하여 수행
  - replicas, images, labels, etc..
  - git 등의 도구를 사용해서 YAML파일에 대한 버전 추적가능 > GitOps

리소스 제거 > kubectl delete ~
- kubectl delete [리소스 종류] [리소스 이름]
- kubectl delete -f [fileName].YAML

## 다중 vs 단일 Config 파일
deployment.yaml과 service.yaml 각각의 설정파일 병합
- YAML 형식의 구분기호 `---` 넣어서 입력하면 완료
- 위에서부터 실행되기 때문에 기왕이면 service 먼저 입력 권장
  - 엥 그냥 YAML 다 읽고 그안에서 종속성확인하고 적당히 retry로 만들어지는 줄 알았는데.. 확인필요
  - 코딩 경험이 짧아서 그런가 뭐부터 쓰는게 BP인가 하는 고민도 항상.. [링크](https://www.logonme.net/tech/lambda-eventbridge/#Source_code)

## Label & Selector에 대한 추가 정보
label & selector > 리소스간 연결에 있어서 중요 기능
- deployment <> pod 연결
- service <> deployment 연결
![챕터요약](https://img1.daumcdn.net/thumb/R1280x0/?scode=mtistory2&fname=https%3A%2F%2Fblog.kakaocdn.net%2Fdn%2FonZiT%2Fbtr5R1smaIR%2FH7qEFdnFTvjlqzpk8T0pEk%2Fimg.png)

\> deployment.yml에서 pod대신 deploy에 대한 lable부여 하고 svc가 그거참조도 가능

selector에도 버전?이 있다
- 기본적으로 label을 사용하는 service의 selector
- matchLabels외에 matchExpressions를 사용하는 deployment의 selector
  - key, operator, values 활용

```
spec:
  selector:
    matchExpressions: 
      - {key: app, operator: NotIn, values: [second-app, first-app]}
```


명령적 방식에도 lable 사용 가능 (-l, --lable 옵션)
- metadata에 `group: example` label 추가
- kubectl delete deployments,services -l group=example

## 활성 프로브 (Liveness Probes)
pod/container 정상 작동 확인을 위한 심화 설정
- [DeploymentSpec > PodTemplateSpec > PodSpec > Pod > Container > Probe ](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.26/#probe-v1-core)
- spec.template.spec.containers[0].livenessProbe:
  - httpGet: # http요청을 통한 liveness 검증
    - path: / # 요청을 보낼 경로 설정
    - port: 8080 # 요청을 보낼 port
  - periodSeconds: 10 # 요청을 보낼 빈도 
  - initialDeplaySeconds: 5 # 처음 생성 대기시간

```
spec:
  template:
    spec: 
      containers:
        - name: second-node
          image: nasir17/kub-first-app:2
          imagePullPolicy: Always
          livenessProbe: 
            httpGet:
              path: /
              port: 8080
            periodSeconds: 10
            initialDelaySeconds: 5
```

## 구성 옵션 자세히 살펴보기
docker compose에서도 많은 옵션을 커스텀 할 수 있듯, YAML에서 또한 많은 커스텀이 가능하다
- spec.template.spec.containers[0].imagePullPolicy: Always # 항상 image pull
- 볼륨과 같은 추가설정시에 또 살펴볼일이 있을것

## 요약
Kubernetes 실습
- minikube를 사용한 로컬 k8s 환경 구축
- kubectl 명령줄 도구를 사용한 클러스터 제어
  - 명령적 접근방식으로 (매우 긴) 명령어를 통한 deployment/service 생성 
  - 선언전 접근방식으로 YAML 파일을 통한 리소스 생성 및 관리
    - labels&selector를 통한 리소스간 연계
    - 하나/다수의 파일로 리소스 정의하기
    - 리소스에 설정할 수 있는 수많은 옵션들

# 이야깃거리

https://velog.io/@juunini/service-monthly-keep-1000won?fbclid=IwAR2llT3fAC2PFhee0jJLuEPMrb2MbjLtwSKyUfGXu2sTLT0pdCYTQtN6IiQ   
어제 이런글 봤는데 흥미롭게 봤습니다    
이제 대충 이런글 보고 
- 아 dockerfile 이런 구성으로 만들었구나
- 생성된 docker image 이런 옵션주고 실행하는구나
- 클라우드환경에서 배포는 이렇게 이뤄지는구나
  - 대충 ECS > Cloud Run (디테일은 조금 다르지만요)
  - 대충 MongoDB Atlas > Cloud Storage
  - 대충 Docker Hub > Aritifact Registry 치환해서 보시면?

그 외에도 저번에 `개발자는 인프라는 어디까지 알아야하는가`와 유사하게   
`인프라는 개발을 어디까지 알아야하는가`도 조금 고민요소긴 해요  

뭔가 사이드 프로젝트 같은것들 종종하시나요? 그곳에 배포/자동화는 어떻게 이뤄지고있나요?   
https://recruit.mash-up.kr/ 이런거 사이드플젝 모임볼때마다 끼고싶은데     
사이드 플젝이다보니 Front/Back 같은 개발이 우선이지     
아키텍처나 배포/자동화/모니터링은 비빌곳이 없어요 흑흑    
개발못하는 인프라쟁이는 서럽다    
