앞서 설명했던 것처럼 볼륨은 컨테이너의 수명 주기에 상관없이 데이터를 저장하고 유지하는 역할을 한다고 했다.
더불어 컨테이너 내부의 경로와 외부(로컬, host machine) 경로를 연결(mount)한다는 개념도 배웠다.

그럼 볼륨에 저장된 데이터를 수정할 때 이런 의문이 들 수 있다.

1) 컨테이너 안에서 데이터를 수정하면 host machine의 경로 안에 있는 데이터도 수정되는가?
2) 반대로, host machine 안의 데이터를 수정하면 컨테이너 안의 데이터가 수정되는 건가?

결국 host machine의 데이터가 원천(source)이고 지속적으로 유지되어야 하는 것이기 때문에 1번은 바람직하지 않다.
또한 컨테이너라는 것도 결국 host machine에 저장된 image를 바탕으로 생성하는 것이기 때문에 2번이 더 타당하다고 납득할 수 있다.

그렇지만 어쨌든 bind mount에서는 1번도 일어날 수 있기 때문에, 컨테이너 안 볼륨에서 데이터를 수정할 수 없도록 별도로 조치를 취할 수 있다. 이때 등장하는 게 바로 read-only volume(읽기 전용 볼륨)이다.

### Read-Only volume(읽기 전용 볼륨)

bind mount의 매핑하고자 하는 경로 인자 뒤에 :ro(read-only)를 붙여주었다.
이렇게 하면 컨테이너 내 /app 이라는 경로는 데이터를 읽어올 수만 있을 뿐, 수정(write)하지 못한다. (정말?)

```bash
docker run -d -p 3000:80 --rm --name feedback-app -v feedback:/app/feedback -v "/Users/my_user_name/udemy/docker-practice/:/app:ro" -v /app/node_modules -v feedback-node:volumes
```

### 읽기 전용으로 만들었다, 하지만 일부 하위 디렉토리는...

위 명령어로 컨테이너 내부의 /app 폴더를 모두 읽기 전용으로 만든 것 같다. 

하지만 우리가 익명 볼륨에 대해 직전에 배웠던 걸 상기해보자. 익명 볼륨을 /app/node_modules 경로로 지정해주면 앞서 /app 경로로 bind mount를 지정해도 /app/node_modules 는 /app의 하위 경로이기 때문에 /app/node_modules 폴더는 host machine 경로의 덮어쓰기로부터 살아남게 된다.

마찬가지로, 위 명령어에선 bind mount로 /app 폴더에 대해 읽기 전용으로 지정했지만 /app/node_modules에 대해 익명 볼륨을 지정하고 /app/feedback에 대해서는 named volume으로 지정했기 때문에 두 경로 모두 read-write, 읽기와 쓰기가 모두 가능한 경로로 살아남게 된다.


## Docker 볼륨 관리하기

`docker volume` 명령어로 볼륨을 다루는 방법에 대해서 알아보자.

먼저 docker volume --help 명령어를 입력해서 어떤 세부 명령어가 있는지 확인해보자.

```bash
docker volume --help
```

- create: 볼륨을 생성
- inspect: 하나 또는 두 개 이상의 볼륨에 대해 자세한 정보를 표시
- ls: 볼륨 목록을 보여줌
- prune: 로컬(무슨 뜻?) 볼륨 중 사용하지 않은 볼륨을 모두 제거
- rm: 하나 또는 두 개 이상의 볼륨을 삭제


docker volume 명령어로 볼륨을 수동으로 생성할 수 있다.

```bash
docker volume create DOCKER_NAME
```

현재 사용 중인 볼륨 목록을 확인하려면 docker volume 명령어에 ls 만 붙이면 된다.

```bash
docker volume ls
```


볼륨이 도커에 의해 관리된다는 건 
1) host machine에 매핑할 경로를 사용자가 알 수 없게 알아서 지정한다는 뜻도 있지만, 
2) 컨테이너 실행 시 볼륨이 존재하지 않으면 도커가 알아서 볼륨을 생성한다는 뜻도 있다.


이렇게 수동으로 직접 볼륨을 생성할 수 있지만, 어차피 처음에 없으면 도커가 알아서 생성해주는데 왜 굳이?

```bash
docker volume create feedback-files
```

만약 어떤 볼륨을 실행 중인 컨테이너에서 사용하고 있다면 그 볼륨은 삭제할 수 없다.

```bash
Error response from daemon: remove DOCKER_NAME: volume is in use - [some docker volume ID]
```

그래서 해당 컨테이너를 중지하고 볼륨을 삭제해야 한다.

```bash
docker stop feedback-app
```



## bind mount를 하더라도 COPY 명령어를 Dockerfile에 유지해야 하는 이유

bind mount는 내가 원하는 로컬의 폴더를 컨테이너가 그대로 가져다 쓸 수 있도록 해준다.

```bash
docker run -d -p 3000:80 --rm --name feedback-app -v feedback:/app/feedback -v "/Users/my_user_name/udemy/docker-practice/:/app:ro" -v /app/node_modules -v feedback-node:volumes
```

위 명령어에선 로컬의 "/Users/my_user_name/udemy/docker-practice/" 경로에 해당하는 폴더를 몽땅 컨테이너의 /app 폴더에다 연결시켰다.
그럼 어차피 컨테이너의 작업 디렉토리인 /app 안에서는 로컬의 폴더에 있는 내용을 모두 참조할 수 있으니까, 
굳이 Dockerfile에서 COPY 명령어로 파일을 복사할 이유가 없는 것 아닐까?


```Dockerfile
FROM node:14

WORKDIR /app

COPY package.json .

RUN npm install

# 로컬의 현재 작업 디렉토리에 있는 내용을 몽땅 컨테이너에 복사한다.
COPY . .

EXPOSE 80

CMD ["node", "server.js"]
```

답은 '그렇지 않다'이다.
컨테이너 배포를 하게 되면 분명 내 로컬이 아니라 서버에서 Dockerfile를 빌드할 거고,
그러면 bind mount로 내 로컬 폴더를 참조하는 게 의미가 없어진다.
그래서 배포 단계를 고려하면 Dockerfile에 여전히 COPY 명령어를 유지하는 게 맞다.


## 모든 것을 복사하진 마세요: "dockerignore" 파일 사용하기

COPY 명령어로 현재 로컬 폴더의 모든 파일을 컨테이너에 복사하려고 한다.

```dockerfile
COPY . .
```

하지만 내가 로컬에서 복사하고 싶지 않은 파일이 있을 수도 있다.

예를 들어서 내가 도커 이미지에다가 `npm install` 명령어를 실행하고, 이것저것 npm과 관련된 패키지를 업데이트하고 추가했다고 하자.

반면에 로컬에도 npm을 설치했다고 가정하자.
하지만 이것 말고는 아무 것도 업데이트하지 않았기 때문에
도커 이미지에 비하면 outdated된 상태라고 볼 수 있다. 
그래서 로컬의 npm 관련 패키지 파일을 컨테이너에 통째로 복사하는 대신 필요한 파일만 복사하고 싶다.

그때 특정 파일만 COPY 목록에서 제외하기 위해 적는 것이 dockerignore이다.

깃(git)을 한 번이라도 써봤다면 .gitignore를 다뤄봤을 것이다.
dockerignore도 똑같이 숨김 파일이기 때문에 .을 파일 이름 앞에 붙여야 한다.
단 깃에서는 커밋을 하지 않기 위해 gitignore를 쓴다면, 도커에서는 이미지에 복사하지 않기 위해 dockerignore를 쓴다는 점이 다르다.


## 환경 변수와 .env 파일 작업

도커는 build-time 인자(ARGuments)와 runtime 환경 변수(ENVironment variables)를 지원한다.

이 내용을 배우기 전에 난 환경 변수가 무엇인지 다시 한번 복습해보기로 했다.
가장 먼저 인터넷에 검색했을 때 뜨는 환경변수의 정의는 '프로세스가 컴퓨터에서 동작하는 방식에 영향을 미치는 변수'라고 한다. 뭔 소린지 하나도 모르겠다.

차라리 환경변수로는 무엇이 있는지 그 예시를 보는 게 이해가 훨씬 빠르다.

| 환경 변수 | 설명 |
| ---- | ---- |
| $USER | 현재 사용자 |
| $PATH | 각종 실행 파일의 경로가 :로 구분되어 있다 |
| $HOME | 홈 디렉토리. 보통 /Users/my_user_name 형식이다 |
| $PWD | 현재 작업 디렉토리 |
| $LANG | 시스템 기본 설정 언어 |
| $UID | 현재 유저의 ID |

이제 환경변수를 대강 이해했다고 가정하고 인자와 환경변수가 도커에서 어떻게 다른지 살펴보자.

인자(ARG)는 
- Dockerfile 내에서 접근할 수 있지만, 프로그램의 코드나 CMD에서는 접근할 수 없음
- 이미지 빌드 과정에서 설정한다. --build-arg 옵션으로 준다.

환경 변수(ENV)는
- Dockerfile 내에서 접근 가능하고 프로그램의 코드(application)에서도 접근 가능함
- Dockerfile 내에서 ENV 명령어로 설정하거나 docker run 명령어로 컨테이너 실행할 때 --env 옵션으로 설정할 수 있다.


### 환경변수 설정하기

내가 컨테이너에 접근하기 위한 포트 번호를 80이라고 지정했다면,
이걸 굳이 하드 코딩하지 않고 PORT라는 변수로 지정해놓을 수 있지 않을까?


```Dockerfile
FROM node:14

WORKDIR /app

COPY package.json .

RUN npm install

# 로컬의 현재 작업 디렉토리에 있는 내용을 몽땅 컨테이너에 복사한다.
COPY . .

ENV PORT 80

EXPOSE 80

CMD ["node", "server.js"]
```

이렇게 Dockerfile에 ENV 명령어로 지정해놓으면 컨테이너 안의 코드에선 언제든지 PORT라는 변수명으로 80을 참조하는 게 가능해진다.

```node
// 거의 모든 프로그래밍 언어나 툴은 대부분 환경변수를 지원한다.
// 컨테이너 내부의 코드라고 한다면 process.ENV.PORT = 80을 가리키게 된다.
app.listen.(process.env.PORT);
```

그리고 Dockerfile에 환경 변수를 한번 설정하면 그 다음 명령어부턴 변수명 앞에 $를 붙여 계속 사용할 수 있다.

```Dockerfile
...

ENV PORT 80

EXPOSE $PORT

...
```


docker run 명령어에서도 환경 변수를 지정할 수 있다. --env 옵션 또는 -e 로 주면 된다.

```bash
docker run -d -p 3000:80 --rm --name feedback-app --env PORT=8000 -v feedback:/app/feedback -v "/Users/my_user_name/udemy/docker-practice/:/app:ro" -v /app/node_modules -v feedback-node:volumes
```

여러 개의 환경변수를 지정할 거면 각 변수마다 -e 옵션을 붙여서 지정하면 된다. 볼륨을 -v 여러 번 옵션 줘서 지정했던 것처럼 말이다.
그런데 이렇게 매 변수마다 -e 옵션으로 지정하는 게 귀찮을 수 있다. 
내가 지정하려는 환경변수가 여러 개일 때, 이걸 한꺼번에 파일에 저장해두었다가 쓸 수 있다면?

그래서 쓰는 게 .env 파일(꼭 이름은 이렇게 지정 안해도 된다. 하지만 이게 convention인 듯)이다.
.env 파일로 환경변수를 지정하려면 --env-file 옵션을 주면 된다.

```bash
docker run -d -p 3000:80 --rm --name feedback-app --env-file .env -v feedback:/app/feedback -v "/Users/my_user_name/udemy/docker-practice/:/app:ro" -v /app/node_modules -v feedback-node:volumes
```



## 인자(ARG)를 Dockerfile에 설정하기

아까 Dockerfile 일부를 보면 PORT 환경변수를 이용하지만, 결국 변수 기본 값으로 80을 직접 하드코딩하고 있다.

```Dockerfile
...

ENV PORT 80

EXPOSE $PORT

...
```


ARG 명령어를 이용하면 아예 DEFAULT_PORT라는 인자로 Dockerfile에서 활용할 수 있다.
주의할 점은, ARG로 설정하는 인자 값은 1) 프로그램(컨테이너 안 소스 코드)에서 접근할 수 없고 2) Dockerfile 내 일부 명령어(런타임에 실행되는 CMD 같은)에서도 사용할 수 없다는 점이다.

```bash
docker build -t feedback-node:dev --build-arg DEFAULT_PORT=8000 .
```

도커 이미지에서 PORT 변수 값을 매번 바꾸지 않고도 터미널에서 외부 인자만 다르게 줌으로써
서로 다른 포트 번호를 가지는 컨테이너를 생성할 수 있다. 더 "유연한(flexible)" 대처법이라고 할 수 있다.


### Dockerfile의 명령어 순서는 항상 확인하자

아래 Dockerfile을 다시 보자.

```Dockerfile
FROM node:14

ARG DEFAULT_PORT=80

WORKDIR /app

COPY package.json .

RUN npm install

# 로컬의 현재 작업 디렉토리에 있는 내용을 몽땅 컨테이너에 복사한다.
COPY . .

ENV PORT $DEFAULT_PORT

EXPOSE $PORT

CMD ["node", "server.js"]
```

`RUN npm install` 명령어가 `ARG DEFAULT_PORT=80`보다 뒤에 등장한다.
똑같은 이미지에서 포트 번호만 다르게 설정하면 매번 npm install을 새로 하는 것이다.
이건 비효율적이니까 순서를 이렇게 바꿔준다.


```Dockerfile
FROM node:14

WORKDIR /app

COPY package.json .

RUN npm install

# 로컬의 현재 작업 디렉토리에 있는 내용을 몽땅 컨테이너에 복사한다.
COPY . .

ARG DEFAULT_PORT=80

ENV PORT $DEFAULT_PORT

EXPOSE $PORT

CMD ["node", "server.js"]
```