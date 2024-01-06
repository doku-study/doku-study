## 학습 목표
- Docker에서 말하는 데이터란 무엇인가?
- 볼륨(Volume)이란?
- arguments, environment variables 이해하기


![week3_part1_1](https://github.com/doku-study/doku-study/assets/36873797/65f2d7bc-0cb7-49dd-a70d-ec6e6db831e2)


### 임시 app 데이터
임시 app 데이터는 소스 코드를 말하는 게 아니다. 임시로 저장할 정보를 의미한다. 
container가 중지돼서 잃어버려도 상관없는 정보가 해당한다. 

container layer(read-write)에 저장된다. 즉 image에는 수정이 가해지지 않는다. 당연히 사용자의 로컬 시스템에도 변화가 없다.

### 영구 app 데이터
container 내에서 생성하지만 container의 실행 여부에는 상관 없이 계속 유지시켜야 하는 데이터. 마찬가지로 read-write 데이터이지만 영구적으로 저장되어야 한다. 
container에 저장되는 건 임시 데이터와 동일하지만, volume의 도움을 받아야 함


## 실습 준비

강의 영상에서 다운로드받은 폴더(data-volumes-01-starting-setup) 안에 다음 Dockerfile을 만든다.

```Dockerfile
FROM node:14

WORKDIR /app

COPY package.json .

RUN npm install

COPY . .

EXPOSE 80

CMD ["node", "server.js"]
```

image를 빌드한다.

```bash
docker build -t feedback-node .
```

container를 생성 및 실행한다.

```bash
docker run -p 3000:80 -d --name feedback-app --rm feedback-node
```

### container의 isolation 개념 복습하기

내가 도커 container로 실행한 앱에서 어떤 문자열을 입력했다고 가정하자. (container 실행하고 웹 브라우저 들어가서 localhost:3000 으로 접속)
그럼 그 문자열 변수는 사용자의 로컬에 저장되는 게 아니라, container에 저장되어야 한다.

마찬가지로 로컬의 소스코드를 수정해도, container에는 소스코드 수정된 내용이 자동으로 반영되지 않는다. 
로컬 시스템과 container으로 구동된 앱의 수정된 내용 사이 연결 고리는 전혀 없다. 
로컬의 feedback 폴더에서 아무런 데이터가 생성되지 않는 것도 그 이유 때문이다.

-> image의 내부 파일 시스템이 존재하며, 이는 로컬 host machine과 독립된 별도의 파일 시스템이다.

결국 컨테이너 상 소스코드 수정을 반영하려면 수정된 소스코드를 바탕으로 이미지를 rebuild하고 그 이미지를 기반으로 container를 다시 실행해야 한다.


### 문제
container를 삭제(--rm 옵션 사용)하면 앱에서 입력했던 문자열 변수를 잃어버린다.
하지만 삭제하지 않고 그냥 중지만 시켰다가 다시 시작하면(`docker start feedback-app`) 다시 입력하지 않아도 아까 입력했던 문자열 변수를 그대로 확인할 수 있다.

그러나 문제는, 컨테이너를 삭제하고 새로 생성할 때마다 데이터도 모두 삭제된다는 사실이다. image는 철저히 read-only한 파일이기 때문에 container layer에서 변경된 내용이 image에 저장되지 않는다.

실제로는 업데이트된 정보를 반영하기 위해 container를 많이 삭제하기도 한다. container를 아예 삭제하지 않고 계속 유지하기는 현실적으로 어렵다는 뜻이다.
하지만 삭제할 때마다 container에 저장했던 정보가 모두 날라간다면, 이 정보를 보존하면서 어떻게 container를 업데이트할 수 있을까?

## 볼륨(Volume)이란?

볼륨이란 사용자의 host machine 하드 드라이브에 존재하는 폴더이다. 

'볼륨은 container 내에 존재한다' (X)
'볼륨은 image 내에 저장된다' (X)

볼륨은 host machine에 위치한 폴더이지만 container에 "**마운트(mount)**"되어 있다는 점이 특별하다.

그렇기 때문에 볼륨은 container가 중지되고 삭제되더라도(shut down) 계속 존재한다(persist).
container가 삭제되었어도, 이걸 다시 실행해서 볼륨을 container에 마운트하기만 하면 볼륨 내에 존재하는 파일은 모두 container에서도 접근 가능하게 된다.


### Dockerfile에 볼륨을 지정하기

VOLUME 명령어로 mount할 경로를 지정할 수 있다.

```dockerfile
FROM node

RUN npm install

COPY . .

EXPOSE 80

# container 안의 경로이면서 동시에 container 바깥의 어떤 폴더에 매핑(mount)되어야 경로
VOLUME ["/app/feedback" ]

CMD ["node", "server.js"]
```

그런데 VOLUME 명령어 뒤에 따라오는 문자열 리스트에는 경로가 하나만 존재한다.
이건 container 안의 경로를 의미한다. 알다시피 볼륨은 container 내의 경로에 바깥의 경로를 마운트함으로써 작동한다. 그럼 해당 볼륨이 container 바깥의 어떤 경로(로컬 시스템)에 매핑시키는 걸까?

-> 직접 Dockerfile에 명시하는 게 아니라, docker가 내부적으로 알아서 처리한다고 한다.


![week03_part1_2](https://github.com/doku-study/doku-study/assets/36873797/367030fb-b3ee-4d97-8d48-2e3f2c45cb65)

\48. A First, Unsuccessful Try 강의 영상에서는 1) 코드 중 에러가 발생한 부분에서 함수를 수정하고(Javascript의 fs.rename -> fs.copy) image를 다시 빌드해서 container를 새로 생성했다. 그래도 볼륨에 저장되어야 할 데이터가 여전히 복구되지 않는다. 즉 볼륨이 제대로 유지되지 않았다는 뜻. 왜일까?

## 도커의 외부 데이터 저장소(External Data Storage)는 2가지로 나뉜다

1. Volumes
2. Bind Mounts

볼륨은 도커에 의해 관리되지만 bind mount는 사용자 본인에 의해서 관리된다.

볼륨이 도커에 의해 관리된다는 건, 도커가 로컬의 경로를 알아서 매핑한다는 뜻이다.
그렇기 때문에 매핑된 로컬 경로는 사용자가 지정하지 않고, 경로가 어디에 있는지 사용자가 알 수도 없다.

반면에 bind mount는 사용자 본인이 직접 매핑할 경로를 지정한다.
더 자세한 차이에 대해서는 뒤에서 설명한다. 스택오버플로우 글도 참고하면 좋다: https://stackoverflow.com/questions/47150829/what-is-the-difference-between-binding-mounts-and-volumes-while-handling-persist


![week03_part1_3](https://github.com/doku-study/doku-study/assets/36873797/2aaa3220-93ff-4b0a-9230-af044aea4309)



### Volumes
볼륨은 크게 2가지로 나뉜다. 

1) Anonymous Volumes (익명 볼륨, 이름이 없음)과 
2) Named Volumes (이름이 존재) 

둘의 공통점은 모두 `docker volume` 명령어로 관리된다는 점, 그리고 볼륨이 매핑한 host machine의 경로는 사용자에게 드러나있지 않다는 점(사실 dev 폴더인가?)이다.

차이가 있다면 수명 주기?라고 할 수 있겠다.
익명 볼륨은 container가 삭제(shut down, remove)됨과 동시에 사라진다. 
아까 설명했던 볼륨의 역할(container가 사라져도 데이터를 보존)을 전혀 수행하지 못하는 것이다. 
(그럼 도커 개발자들은 익명 볼륨은 굳이 왜 만들어놓은 걸까? 무슨 쓸모가 있어서?)

반면에 named volume은 container가 삭제돼도 여전히 존재하고 데이터를 유지한다.


### Named Volume 지정하기
Dockerfile에서 VOLUME 명령어로 지정하면 anonymous volume을 만들 수 있었다.
하지만 named volume은 Dockerfile에서 만드는 게 아니라 `docker run` 명령어에서 옵션으로 할당하면 된다.

```bash
docker run -d -p 3000:80 --rm --name feedback-app -v feedback:/app/feedback feedback-node:volumes
```

-v 옵션 뒤에 :으로 분리된 인자를 분석해보자.

```bash
-v VOLUME_NAME:MOUNT_DIR
```

: 앞에는 볼륨의 이름을, : 뒤에는 내가 container 안에서 마운트하고자 하는 경로를 지정한다.

위 명령어로 볼륨의 이름을 지정하면 이전 강의 영상에서는 에러가 났던 부분을 해결할 수 있다.



### 볼륨의 한계?
볼륨에 저장되어 있는 소스코드를 수정하려면 어떻게 해야 할까?
container 내부 경로에 있는 파일을 수정하는 건 의미가 없다. 어차피 이 container를 삭제하고 새로 만들면 파일은 초기화되기 때문이다.
그러면 매핑된 로컬 경로에서 수정해야 할 텐데 문제는 이 경로에 사용자가 직접 접근해서 수정할 수 없다는 점이다.
"도커가 알아서 관리"하기 때문에 볼륨이 로컬의 어느 경로에 마운트되었는지 모르고 매핑된 해당 로컬 경로에 접근할 권한도 없기 때문이다.


## Bind Mounts

bind mounts는 volume과 달리 매핑할 로컬 경로를 사용자가 직접 지정한다.

### Bind Mount 지정하는 법

named volume을 지정했던 것처럼, Dockerfile에 지정하는 게 아니고 명령어로 옵션을 주어야 한다.

```bash
# 경로 안에 특수문자나 공백이 있을 경우 ""로 감싼다
docker run -d -p 3000:80 --rm --name feedback-app -v feedback:/app/feedback -v "/Users/my_user_name/udemy/docker-practice/:/app" feedback-node:volumes
```

bind mount를 지정하려면 -v 옵션을 한번 더 써서 "두번째 볼륨"을 할당한다고 기억하면 된다.
그러나 볼륨과 달리 : 앞에 오는 인자는 이름이 아니라 **매핑하고자 하는 로컬 경로**를 입력해야 한다.

참고로, 위 예시처럼 로컬 경로를 절대 경로로 길게 쓰는 게 번거롭다면 셀 변수를 활용해서 입력할 수도 있다.

```bash
# macOS / Linux
-v $(pwd):/app

# Windows
-v "%cd%":/app
```


### Bind Mount의 사용 권한 부여하기

<img width="700" alt="week03_part1_4" src="https://github.com/doku-study/doku-study/assets/36873797/9e8f7baa-be2d-4afd-8224-394ba2431ab1">

Docker Desktop 들어간 후 Settings > Resources > File Sharing 에서 bind mount가 가능한 경로를 확인한다. 로컬의 폴더나 파일은 대부분 /Users 를 parent folder로 하므로 별다른 설정을 안해도 잘 작동할 것이다.


### 여전히 에러가 발생하는 이유

위에서 보여준 것처럼 -v 옵션으로 bind mount를 사용해서 어느 로컬 경로에 매핑할지도 지정했다.
그리고 나서 컨테이너를 다시 생성, 실행했더니 이번엔 dependency 에러가 발생한다.

그 이유는 Dockerfile을 보면 알 수 있다.

```dockerfile
FROM node:14

WORKDIR /app

COPY package.json .

RUN npm install

COPY . .

EXPOSE 80

VOLUME ["/app/feedback" ]

CMD ["node", "server.js"]
```

Dockerfile은 위에서부터 아래로 명령어를 차례로 수행한다. 기껏 npm install 로 node에 필요한 패키지 설치하고 파일도 복사했더니, 그 다음에 VOLUME 명령어로 container 내부 경로를 모두 로컬 경로로 매핑해버렸다. 
즉 container 내부 /app/ 경로를 덮어쓰기(overwrite)해버린 것이다. 
로컬 경로에는 npm install 하지 않았으니 `node server.js` 명령어를 실행하기 위한 패키지(experess)가 없다. 그래서 container 내부 경로에도 express 패키지가 없다고 에러가 뜬다.


### Container - Volume 상호작용 이해하기

- container의 데이터는 볼륨에 저장. 볼륨은 container에 마운트되어 있다.
- container에 데이터가 없으면 bind mount로부터 가져온다

-> 여기서 volume과 bind mount와의 차이가 분명하게 이해되지 않음...!

### 에러를 해결하려면?
anonymous volume이 여기서 다시 등장한다. 명령어를 살펴보자.

```bash
docker run -d -p 3000:80 --name feedback-app -v feeback:/app/feedback -v "$(pwd):/app" -v /app/node_modules feedback-node:volumes
```

세번째 -v 옵션을 주어서 익명 볼륨을 지정해주었다.
이때 규칙이 있다. 볼륨의 경로 간에 충돌이 발생하면 더 긴(하위) 디렉토리가 이긴다.
그렇기 때문에 /app 디렉토리의 하위 디렉토리인 /app/node_modules 에 대응하는 볼륨이 덮어씌워지지 않고
/app/node_modules에 npm이 설치되어 있기 때문에 의존성 패키지 에러가 발생하지 않게 된다.


## 요약

볼륨 또는 bind mount를 지정하는 법은 공통적으로 -v 옵션을 주는 것으로 시작한다.

1. 익명 볼륨(anonymous volume)은 이름을 따로 지정하지 않고 마운트할 container 내부 경로만 써준다.

```bash
docker run -v /app/data ...
```

 2. 이름이 지정된 볼륨(named volume)은 :(콜론)으로 앞에 볼륨의 이름을 덧붙여준다.

```bash
docker run -v data:/app/data ...
```

 3. bind mount는 named volume과 형식은 동일하지만 이름 대신 로컬에 매핑할 경로를 지정해주면 된다.

```bash
docker run -v /path/in/local:/app/data ...
```


- 익명 볼륨은 --rm 옵션을 사용하지 않는 한 container를 중지(stop)하거나 재시작(start)해도 사라지지 않는다. 하지만 container를 삭제(remove)하면 익명 볼륨도 같이 사라진다. 그렇기 때문에 컨테이너 바깥에 데이터를 저장, 공유하는 데 익명 볼륨이 쓰일 순 없다.
- "이름이 없는(익명의)" 볼륨이기 때문에 재사용할 수 없다. 같은 이미지여도 이미지에서 새로 컨테이너를 생성하면 같은 익명 볼륨을 재사용할 수 없다.


