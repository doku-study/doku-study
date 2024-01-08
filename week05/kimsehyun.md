데이터베이스나, 백엔드 웹 서버 등등 현실에서는 컨테이너를 여러 개 운영하는 경우가 대부분이다.

이 섹션에서는 뭔가 아예 새로운 걸 배운다기보다는, 이미 배웠던 걸 종합해서 multi-service, multi-container 서비스에 적용해보는 시간이 될 것이다.

1. 여러 개의 서비스를 합쳐서 한 app에 적용하기(Combining Multiple Services To One App)
2. 여러 개의 컨테이너 다루기(Working with Multiple Containers)


## 세 가지 빌딩 블록(=컨테이너?)

어떤 웹 앱을 구현한다고 할 때, 그 구성 요소를 크게 세 가지로 나눌 수 있다.

1. 데이터베이스(MongoDB)
2. 백엔드(NodeJS REST API)
3. 프론트엔드(React SPA)

백엔드는 데이터베이스와 소통하고, 프론트는 백엔드와 소통한다.

### 실습에서 다루는 app에 대한 소개

- 자기 할 일 목표(goal)를 웹에서 만들고, 삭제하는 게 주 기능이다.
- 목표를 데이터베이스에 저장할 수도 있다.
- 프론트엔드는 React를, 백엔드는 NodeJS REST API를 쓴다.

리액트는 서버에서 작동하는 게 아니라 브라우저 위에서 작동한다고 한다. (이게 무슨 뜻이지?)


![Pasted image 20240108180900](https://github.com/doku-study/doku-study/assets/36873797/4c1087c3-4f5b-4a60-9aa3-4a592f9d6898)




## 1. 데이터베이스 전용 컨테이너 연결하기

가장 기본적인 것에서부터 시작하자. MongoDB가 설치된 컨테이너는 mongo라는 이름의 공식 이미지를 다운로드받아와 실행할 수 있다.

```bash
docker run --name mongodb --rm -d mongo
```

근데 DB 전용 컨테이너는 백엔드 전용 컨테이너와 통신해야 하니, 포트번호를 열어준다.

```bash
docker run --name mongodb --rm -d -p 3000:27017 mongo
```

27017은 MongoDB의 공식 포트번호이다.
실습할 땐 똑같은 이름으로 만들어놓은 기존 컨테이너를 잘못 실행하지 않게 이전 걸 다 삭제하고(`docker container prune`) 실습을 진행한다 (기존 컨테이너 중에 계속 쓰고 있는 건 없는지 신중하게 확인!)

저 명령어를 실행하고 다시 node 컨테이너(백엔드 담당 컨테이너)로 돌아가서 중지하고 다시 실행하면, 

```bash
CONNECTED TO MONGODB
```

출력이 뜬다. 로컬 몽고DB를 닫아도 DB전용 컨테이너의 데이터베이스에 잘 연결되었다는 뜻이다.


## 2. 백엔드 전용 컨테이너

DB 전용 컨테이너는 도커 허브에서 몽고DB 공식 이미지를 다운로드받으면 됐었지만, 백엔드 컨테이너부터는 직접 짠 앱에 해당하기 때문에 Dockerfile을 작성해주어야 한다.

```dockerfile
FROM node

WORKDIR /app

COPY package.json .

RUN npm install

COPY . .

EXPOSE 80

CMD ["node", "app.js"]
```

그러고 나서 이미지를 빌드해준다.

```bash
docker build -t goals-node .
```

컨테이너를 실행한다.

```bash
docker run --name goals-backend --rm goals-node
```

그럼 에러가 발생한다. 당연하다. 코드에는 아직 localhost로 몽고DB에 접근하려고 하기 때문이다.

```node
mongoose.connect(
  'mongodb://localhost:27017/course-goals',
  {
    useNewUrlParser: true,
    useUnifiedTopology: true,
  },
  ...
```

로컬 호스트 머신에 접근하려면 localhost 대신 host.docker.internal로 바꾼 다음,
소스코드가 바뀌었으니 (나중에는 이미지 빌드 없이 실시간 반영 가능하게 함. 지금 당장은 X) 이미지를 다시 빌드하고 컨테이너 실행시켜서 시도해보면 잘 연결되는 걸 확인할 수 있다.



## 3. 프론트엔드 컨테이너

리액트에선(아직 도커 컨테이너로 안 만듦) 여전히 백엔드 컨테이너에 통신할 수 없다.
백엔드 컨테이너에 접근할 수 있도록 포트번호를 설정(publish)하지 않았기 때문

```bash
docker run --name goals-backend --rm -d -p 80:80 goals-node
```

이렇게 하면 리액트 컨테이너를 만들기 전에 문제없이 웹에서 작동하는 걸 볼 수 있다.

이제 프론트엔드 컨테이너까지 만들어보자.


### Dockerfile 만들기

리액트 컨테이너 또한 node.js 패키지를 기본으로 설치해야 한다.
리액트(React)가 필요로 하는 모듈을 다운로드하고 관리하는 데 npm이 필요한데, 이 npm(Node Package Manager) 또한 Node.js 기반으로 움직이기 때문
-> 잘 모르겠지만 어쨌든 리액트로 코드를 짜려면 node.js가 필요하다!

```dockerfile
FROM node

WORKDIR /app

COPY package.json .

RUN npm install

COPY . .

EXPOSE 3000

CMD ["npm", "start"]
```

그 다음에 이미지를 빌드하고

```bash
docker build -t goals-react .
```

컨테이너를 실행한다.

```bash
docker run --name goals-frontend --rm -d 3000:3000 goals-react
```

그런데 이렇게 컨테이너를 실행해도 `docker ps`로 확인하면 실행 중인 컨테이너가 없다고 뜬다.
이건 사실 우리가 코드를 잘못 짜서 생긴 에러라기보다는, 리액트의 설계 자체 때문이다.

리액트는 interactice mode로 진입하지 않으면 컨테이너를 열어두는 게 의미없다고 보고 그냥 닫아버린다(중지). 그래서 -it 옵션을 달아서 터미널로 interact할 수 있게 설정해야 한다.

```bash
docker run --name goals-frontend --rm -p 3000:3000 -it goals-react
```

자, 여기까지 했으면 문제는 없이 돌아간다. 하지만 문제는 이 컨테이너들이 모두 로컬 호스트 머신을 통해서 통신하고 있다는 점이다.

![Pasted image 20240108185705](https://github.com/doku-study/doku-study/assets/36873797/b92814a3-3c55-4b10-b842-1584d6b5afc1)




## 도커 컨테이너 네트워크 추가하기

앞서 배운 네트워크 기능을 활용해서, 각 컨테이너끼리 통신하도록 설정할 수 있다.
우선 현재 존재하는 도커 네트워크를 확인하자.

```bash
docker network ls
```


그 다음에 아직 없다면, 네트워크를 만든다.

```bash
docker network create goals-net
```

이제 포트번호를 publish할 이유가 없다. 로컬 호스트 머신을 통해서 통신할 필요 없이 컨테이너끼리 통신하면 되기 때문이다.

DB 컨테이너는 이렇게 실행하고

```bash
docker run --name mongodb --rm -d --network goals-net mongo
```

백엔드 컨테이너는 이렇게 실행한다. 

```bash
docker run --name goals-backend --rm -d --network goals-net goals-node
```

그리고 백엔드 컨테이너 안의 코드에서 localhost나 host.docker.internal 대신 DB 컨테이너의 이름(mongodb)을 지정하자.

```node
mongoose.connect(
  'mongodb://mongodb:27017/course-goals',
  {
    useNewUrlParser: true,
    useUnifiedTopology: true,
  },
  ...
```

그리고 다시 `docker build -t goals-node .` 명령어로 이미지 빌드한 다음 `docker run --name goals-backend --rm -d --network goals-net goals-node` 로 실행하면, DB와 백엔드 컨테이너 간 통신을 goals-net라는 이름의 네트워크로 통신하게 할 수 있다.

그러면 마지막으로 프론트엔드 컨테이너는 어떻게 처리할까?
로컬에서도 접근 가능하면서, 동시에 컨테이너끼리도 통신이 가능하게 -p 옵션과 --network 옵션을 모두 주자.

```bash
docker run --name goals-frontend --rm -p 3000:3000 -it --network goals-net 
```

그리고 위 명령어를 실행하면... 연결 에러가 뜬다. 왜일까?

### 리액트의 코드는 브라우저 위에서 작동한다

리액트의 코드 자체는 컨테이너 안이 아니라 브라우저 위에서 작동하기 때문이다.
그래서 사실 리액트 컨테이너는 네트워크에 포함시킬 필요도 없다.

```bash
docker run --name goals-frontend --rm -p 3000:3000 -it goals-react
```

그리고 백엔드 컨테이너도 다시 실행한다.
그렇지만 똑같이 실행하는 게 아니라, 이번엔 포트번호를 주어서 백엔드 컨테이너가 포트번호를 통해 리액트 컨테이너 통신할 수 있도록 한다.

```bash
# 일단 기존 컨테이너를 중지한 다음
docker stop goals-backend

# goals-backend 컨테이너 실행할 때 --rm 옵션을 주었기 때문에 start가 아니라 run 명령어 써야 함
docker run --name goals-backend --rm -d -p 80:80 --network goals-net goals-node
```

-> 여기서 어떻게 리액트가 백엔드와 통신한다는 걸까?(포트번호 3000 vs. 80으로 다른데?)




## 볼륨으로 MongoDB 컨테이너에 데이터 지속하기

명명 볼륨(named volume)을 추가해주자.

```bash
docker stop mongodb

docker run --name mongodb -v data:/data/db --rm -d --network goals-net mongo
```

이젠 컨테이너를 멈추더라도 데이터가 보존된다.

```bash
docker stop mongo
docker run --name mongodb -v data:/data/db --rm -d --network goals-net mongo
```


## MongoDB에 권한 제한하기

DB에 아무나 접근할 수 없게 보안 설정을 해야 한다. 그럼 몽고DB에 접근할 때마다 사용자의 아이디와 비밀번호를 요구하면 되지 않을까? 그럴 때 활용하는 게 환경변수다.

MONGO_INITDB_ROOT_USERNAME 
MONGO_INITDB_ROOT_PASSWORD

```bash
docker run --name mongodb -v data:/data/db \
--rm -d --network goals-net \
-e MONGO_INITDB_ROOT_USERNAME=sehyun \
-e MONGO_INITDB_ROOT_PASSWORD=ilovedocker2023! \
mongo
```

이렇게 그대로 실행하면 실패한다. 왜냐면 node 컨테이너의 코드에서 mongodb 컨테이너에 통신을 요청할 때 아이디와 패스워드를 명시하지 않았기 때문이다.

```node
// backend > app.js 86번째 줄
mongoose.connect(
  'mongodb://mongodb:27017/course-goals',
...
```

여기에 아이디와 패스워드를 추가하면

```node
// backend > app.js 86번째 줄
mongoose.connect(
  'mongodb://sehyun:ilovedocker2023!:27017/course-goals',
...
```


```bash
docker build -t goals-node .

docker run --name goals-backend --rm -d -p 80:80 --network goals-net goals-node
```

여전히 실패한다.
공식 문서를 보면 authSource=admin 문자열을 추가해주어야 한다고 한다.

```node
// backend > app.js 86번째 줄
mongoose.connect(
  'mongodb://sehyun:ilovedocker2023!:27017/course-goals?authSource=admin',
...
```

그런데 이렇게 코드에 내 아이디와 비밀번호를 하드코딩하기보다는, 환경변수로 설정해주는 게 더 낫다.
다시 Dockerfile로 돌아가서 환경변수를 ENV 명령어로 설정한 다음에

```dockerfile
# backend > Dockerfile

FROM node

WORKDIR /app

COPY package.json .

RUN npm install

COPY . .

EXPOSE 80

# root, secret은 default 값이다.
ENV MONGODB_USERNAME=root
ENV MONGODB_PASSWORD=mongodb2024

CMD ["node", "app.js"]
```

코드에도 원래 아이디와 비밀번호가 있던 자리를 환경변수로 바꾼다.

```node
// backend > app.js 86번째 줄
mongoose.connect(
  `mongodb://${process.env.MONGODB_USERNAME}:${process.env.MONGDODB_PASSWORD}:27017/course-goals?authSource=admin`,
...
```







## 실시간 코드 수정을 반영하기

우선 컨테이너를 멈추고 볼륨 옵션을 주어서 다시 실행한다.

```bash
docker stop goals-backend
docker run --name goals-backend -v logs:/app/logs --rm -p 80:80 --network goals-net goals-node
```

근데 아직 부족하다. 내 로컬 폴더의 어떤 소스코드든 수정이 되면 바로 컨테이너에 반영하고 싶기 때문이다.
그래서 bind mount를 써준다.

```bash
docker run --name goals-backend \
-v /Users/my_user_name/development/docker_study/backend:/app \
-v logs:/app/logs \
-v /app/node_modules \
-d --rm -p 80:80 --network goals-net goals-node
```


### app.js 코드 수정 시 컨테이너 재실행 없이 반영하기: nodemon을 활용

아래 코드에서

```node
// backend > package.json
{
  "name": "backend",
  "version": "1.0.0",
  "description": "",
  "main": "index.js",
  "scripts": {
    "test": "echo \"Error: no test specified\" && exit 1"
  },
  "author": "Maximilian Schwarzmüller / Academind GmbH",
  "license": "ISC",
  "dependencies": {
    "body-parser": "^1.19.0",
    "express": "^4.17.1",
    "mongoose": "^5.10.3",
    "morgan": "^1.10.0"
  }
}
```

devdependency로 nodemon을 추가하고 script에는 "start": nodemon app.js를 써준다.

```node
// backend > package.json
{
  "name": "backend",
  "version": "1.0.0",
  "description": "",
  "main": "index.js",
  "scripts": {
    "test": "echo \"Error: no test specified\" && exit 1"
    "start": "nodemon app.js"
  },
  "author": "Maximilian Schwarzmüller / Academind GmbH",
  "license": "ISC",
  "dependencies": {
    "body-parser": "^1.19.0",
    "express": "^4.17.1",
    "mongoose": "^5.10.3",
    "morgan": "^1.10.0"
  },
  "devdependencies": {
	  "nodemon": "^2.0.4"}
}
```

nodemon 자바스크립트 파일 중에 수정된 부분이 있으면 node 서버를 다시 시작하게 한다.

그리고 Dockerfile의 CMD 부분도 

```dockerfile
...
CMD ["npm", "start"]
```

로 수정해준다.

그러면 코드를 수정할 때마다 컨테이너의 로그에는

```
[nodemon] restarting due to changes...
[nodemon] starting 'node app.js'
```

라는 메시지가 뜨면서 코드(app.js)를 다시 시작한다.


### dockerignore 파일 구성하기

```dockerignore
node_modules
Dockerfile
.git
```

node_modules를 dockerignore에 추가한 이유는 Dockerfile에서 npm을 설치한 다음에 복사하기 때문이다.
파일을 통째로 복사하기 전에 이미 npm install로 필요한 패키지를 설치하기 때문에,
COPY 단계에서는 npm과 관련된 패키지를 굳이 복사할 필요가 없기 때문이다.

```dockerfile
RUN npm install

COPY . .
```


## 리액트 컨테이너의 소스코드 실시간으로 반영하기

로컬에서 일어난 소스코드 수정을 자동으로 컨테이너에 반영하기(live source code update).
첫번째 해결책은 bind mount이다.

```bash
docker run -v /Users/my_user_name/development/docker_study/frontend:/app/src \
--name goals-frontend \
--rm -p 3000:3000 -it goals-react
```

마찬가지로 frontend의 폴더에도 .dockerignore 파일을 만들고, node_modules를 목록에 추가해준다.



## 요약

지금 모듈에서 다룬 내용은 '개발(development)' 과정에 초점이 맞추어져 있었다.
여기서 말하는 개발이란, 내 로컬을 벗어나지 않는 테두리를 말한다.
그리고 실제로 도커를 개발 용도로만 쓰는 개발자들도 많다. 환경을 캡슐화(encapsulate)하기 가장 좋은 도구가 도커이기 때문이다.

하지만 앞으로는 개발과 함께 배포하는 과정도 살펴볼 것이다. -> deployment + production

### 개선의 여지(Room for Improvement)
- 지금까지 썼던 도커 명령어, 너무 길지 않았는가?
- 개발에만 초점을 맞춘 설정(set-up) -> 배포에는 적합하지 않다. 실제 production용 서버에서는 내가 했던 방식으로 컨테이너가 실행되어서는 안된다.