# 도커 배포하기 part 2



## ECS 의 Command 와 Dockerfile 의 CMD 

ECS 에서 컨테이너를 생성할 때, 컨테이너 실행시 함께 실행할 Command 를 지정할 수 있다.

이 Command 는 Dockerfile 의 CMD 구문을 대체한다.

이를 통해 프로덕션 환경에서는 Command 에 node app.js 를 실행하게 하고, 

개발 환경에서는 npm start (nodemon 이 포함된 )를 실행하게 해서 환경별로 서로 다른 명령어를 줄 수 있다.



<br />

## 컨테이너 실행 위치에 따른 환경변수 값

동일한 컨테이너를 실행하는 위치(환경)이 다를 수 있다. (로컬 개발 환경 VS 리모트 프로덕션 환경)

따라서 컨테이너 실행 환경이 다를 경우, 애플리케이션 코드를 수정하지 않고도 정상동작 하도록 하기 위해 환경변수를 활용한다.

### 애플리케이션 코드

```javascript
mongoose.connect(
  `mongodb://......@${process.env.MONGODB_URL}:27017/course-goals?authSource=admin`)
```

### 로컬 개발 환경

```
// .env
// docker-compose 에 의해 사용되는 이름을 사용한다.

MONGODB_URL=mongodb 
```



### AWS 컨테이너 환경변수 설정 (리모트 프로덕션 환경)

| key         | value     |
| ----------- | --------- |
| MONGODB_URL | localhost |



## 로드밸런서의 역할

로드 밸런서는 EC2에 속한다.

컨테이너를 배포할 때마다 변경되는 public IP 에 대응하기 위해, 로드 밸런서의 Domain DNS 를 활용할 수 있다.

급증하는 트래픽에 대해 오토스케일링 가능



## EFS

일반적으로는 ECS 에서 각 container (task) 의 새 버전을 배포하면 이전 컨테이너의 데이터가 손실된다.

이러한 문제를 해결하기 위해 로컬에서 볼륨을 사용했던 것처럼, 

AWS 에서는 Elastic File System 을 통해 볼륨을 저장, 사용할 수 있다.

로컬 볼륨과의 차이점은, 로컬 볼륨의 경우 볼륨이 로컬 호스트 머신의 어디에 저장되는지 정확한 위치를 알 수 없었다면,

EFS 는 데이터가 저장될 위치를 알 수 있다.



<br />

## 데이터베이스 컨테이너를 직접 관리할 때 주의할 점

1. 스케일링 & 가용성 관리가 쉽지 않다.
2. 퍼포먼스 ( 트래픽 급증 시 포함 )이 나쁠 수 있다.
3. 보안 & 백업이 쉽지 않다.

-> 따라서 관리되는 데이터베이스 서비스 (Ex : AWS RDS, MongoDB Atlas) 사용을 고려해볼 만 하다.

[ 지난 강의에서 언급한 통제(control) 와 책임(Responsibility) 사이의 트레이드오프에 대해 고민할 포인트 ]



<br />

## 관리되는 데이터베이스 서비스 이용해보기 (MongoDB Atals)

MongoDB Atlas는 클라우드 기반이므로, 로컬에서는 mongodb 컨테이너가 더이상 필요하지 않다.

따라서 MongoDB Atlas 설정이 끝나면 로컬과 ECS 의 mongoDB 관련 컨테이너를 삭제한다.



<br />

## "빌드 전용" 컨테이너 만들기

개발 환경과 프로덕션 환경이 다른 앱(ex : React) 과 같은 경우, 빌드 단계로 인해 개발 환경의 코드가 프로덕션 레벨로 최적화된다.

개발 환경과 달리, 프로덕션 환경에서 React 는 자체 서버를 구축하는게 아니라면  node 가 필요하지 않다. React 코드는 브라우저에서 실행될 것을 염두에 두고 작성하기 때문이다.

따라서 이전에 작성한 서버 사이드 node 앱의 Dockerfile 와 달리, React 는 프로덕션 빌드용 Dockerfile 을 따로 작성한다,

```dockerfile
# Dockerfile.prod

# react 앱에서는 node 가 필요하지 않지만, build 스크립트 내부적으로 node 를 사용한다.
FROM node:14-alpine

WORKDIR /app

COPY package.json .

RUN npm install

COPY . .

CMD ["npm", "run", "build"]
```



이제 프로덕션 환경에서 사용할 수 있는 최적화된 파일은 빌드되었는데, 이 파일을 제공할 서버가 없는 상태이다.

이를 위해 멀티 스테이지 빌드에 대해 알아보자.



<br />

## 멀티 스테이지 빌드

멀티 스테이지 빌드를 사용하면 하나의 도커 파일 안에 스테이지(stage) 라고 하는 여러 빌드 단계 (or 설정 단계) 를 정의할 수 있다.

예를 들어, 위에서 빌드한 파일을 가져와 빌드 다음 단계에 빌드된 파일을 가지고 웹 서버에 제공할 수 있다.

Dockerfile 내부에 작성한 FROM 구문을 통해 각 스테이지를 구분할수 있다.

```dockerfile
# Dockerfile.prod

# 스테이지 A (빌드) 
FROM node:14-alpine as 빌드스테이지이름A

WORKDIR /app

COPY package.json .

RUN npm install

COPY . .

RUN npm run build

# 스테이지 B (웹 서버)
FROM nginx:stable-alpine

# 빌드스테이지이름A 에서 빌드된 최종 콘텐츠 웹 서버로 복사
# 빌드 최종 디렉토리 이름은 /app/build 대신 /app/dist 일수도 있음
COPY --from=빌드스테이지이름A /app/build /usr/share/nginx/html

EXPOSE 80

# nginx 웹 서버 시작
CMD ["nginx", "-g", "daemon off;"]
```



### 빌드 명령어

```bash
docker build -f frontend/Dockerfile.prod -t academind/goals-react ./frontend
```

명령어 끝의 ./frontend 는 이 빌드 명령의 컨텍스트(이미지가 빌드되어 저장될 폴더)를 설정하는 부분이다.

이미지 빌드가 완료되면, 해당 이미지를 도커 허브 등에 push 하여 사용할 수 있다.



### --target 옵션으로 특정 스테이지만 빌드

```bash
docker build -f --target 빌드스테이지이름A frontend/Dockerfile.prod -t academind/goals-react ./frontend
```





<br />

## 스탠드얼론 프론트엔드 앱 배포하기

이전에 ECS 에 특정 task 내부에 node 백엔드 컨테이너를 배포해뒀다면, 방금 생성한 프론트엔드 이미지도 해당 task 의 내부에 컨테이너로 배포해두고 싶을 것이다.

그러나 이전에 배포한 node 백엔드 컨테이너는 80 포트를 사용하고 있고, 방금 생성한 프론트엔드 이미지의 웹 서버인 nginx 도 80 포트를 사용하고 있다.

하나의 네트워크 안에서 같은 포트를 사용할 수는 없기에, 둘 중 하나의 포트를 변경하면 해결되겠지만, default port 를 변경하면 예상하지 못한 문제들이 생겨날 수 있다.

따라서 방금 생성한 프론트엔드 이미지는 ECS 에 새로운 task 를 생성해서 배포한다.

이렇게 구현하면 프론트엔드와 백엔드가 서로 다른 로드밸런서, 서로 다른 URL 을 갖게 된다.



