상황 1: 도커 컨테이너에 담긴 소스 코드의 일부를 수정하고 싶다. 이 코드를 수정한 다음 컨테이너에 새로 반영하고 싶었기 때문에 컨테이너를 중단하고 다시 시작했다. 어라, 그런데 여전히 아까랑 똑같은 결과다. 왜 그런 걸까?

도커 image는 소스코드의 스냅샷(snapshot)을 찍는 것과 같기 때문이다. 즉 image는 한번 빌드한 이후로는 기본적으로 외부에서 더 이상 바꿀 수 없으며 끝난(locked and finished) 상태가 된다.


## image는 layer로 구성되어 있다

Dockerfile에서 명령어의 순서는 중요하다(The order of Dockerfile instructions matters).
각 명령어는 한 layer에 대강 대응한다고 보면 된다.

(공식 문서도 꼼꼼히 읽어볼 것: https://docs.docker.com/build/guide/layers/)

image에 수정이 가해졌다고 다시 처음부터 쌩으로 build하는 건 중복이 많고 비효율적인 작업이다. 수정을 하지 않은 똑같은 부분은 그대로 저장(=cache)해두었다가 활용하고, 바뀐 부분만 업데이트해서 빌드하면 더 빠를 것이다.
하지만 Dockerfile에서 image를 빌드하는 과정은 분명히 순서가 존재한다.

![Docker Layers](https://github.com/doku-study/doku-study/assets/36873797/7e90f966-5dfb-471b-af7e-3f1d52a4bb26)

![Docker Layers with Explanation](https://github.com/doku-study/doku-study/assets/36873797/00973bc8-c625-488d-9262-e66a55f70aea)


하지만 어떤 코드를 수정했다고 해서, 그 layer 다음의 모든 layer를 처음부터 다시 rebuild하는 건 비효율적이다.
다시 node image의 Dockerfile을 예로 들어보자.

### 비효율적인 방식 (Dockerfile로 image build하기)

```dockerfile
FROM node

WORKDIR /app

COPY . /app

RUN npm install

EXPOSE 80

CMD ["node", "server.js"]
```

코드 일부를 수정하면 COPY 명령어의 layer부터 다시 build해야 한다.
그러면 코드만 바뀌었을 뿐 사실 node 패키지는 다시 새로 설치(`npm install` )할 필요가 없는데, RUN 명령어는 COPY 이후의 layer에 해당하니 npm을 새로 설치하게 된다. 이는 분명 불필요한 작업이다.

이 부분을 어떻게 optimization해야 할까?

### 개선된 방식 (Dockerfile로 image build하기)

```dockerfile
FROM node

WORKDIR /app

COPY package.json /app

RUN npm install

COPY . /app

EXPOSE 80

CMD ["node", "server.js"]
```

이렇게 하면
1) RUN 명령어는 COPY 명령어 이전에 있기 때문에, COPY 명령어(`COPY . /app`)의 layer에서 수정이 되어 cache가 invalidate되어도 이미 `RUN npm install` 파트는 지나왔다(cache를 활용). 즉 불필요하게 npm을 다시 설치하지 않는다
2) 설령 이 Dockerfile에 대한 캐시가 없더라도 `COPY package.json /app` 에서 npm을 설치하기 위한 패키지를 package.json으로 가져오기 때문에 아무런 문제 없이 `npm install`을 실행할 수 있다.