## Image와 Container

- Image가 템플릿, 청사진, 설계도라면 컨테이너는 이 설계도를 가지고 지은 실제 구조물, 기계, 작동하고 움직이는 어떤 것에 비유할 수 있다.
- 한 image(=setup instructions)를 기반으로 여러 개의 컨테이너를 만들 수 있다. 컨테이너는 서로 다른 컴퓨터나 환경에서 작동할 수 있다.

### 키워드
- Image = setup instructions, blueprints, sharable packages, logic and code a container needs
- Container = concrete, runnable instances

Stackoverflow에 올라온 답변을 보면 감을 쉽게 잡을 수 있다.
	https://stackoverflow.com/questions/23735149/what-is-the-difference-between-a-docker-image-and-a-container

<img width="679" alt="recipe_cake" src="https://github.com/doku-study/doku-study/assets/36873797/53cabfb7-d0ae-4402-80c7-da3ab7b037bf">


## 이미 만들어진(pre-built) custom image 활용하기

![wheel](https://github.com/doku-study/doku-study/assets/36873797/efb6d628-9814-4131-885d-9863fd4291a4)

이미 사람들이 잘 만들어놓은 image가 있다. 
처음부터 나 혼자 만들 생각하지 말고 가져다쓰자.

### 예시: node image를 Docker Hub에서 가져와 쓰기

node라는 이름의 image를 docker hub에서 가져와 쓴다.
하지만 먼저 node라는 이름의 image가 로컬에 존재하는지 확인한 후, 없다면 동일한 이름의 이미지를 Docker Hub에서 가져와 (있다면) 가져다쓴다.

```bash
docker run node
```


### interactive mode로 컨테이너를 실행하고 싶을 경우

-it 옵션을 붙여주면 된다.

```bash
# docker run -it node와 동일
docker run -i -t node
```

Docker 공식 매뉴얼(https://docs.docker.com/engine/reference/run/)을 보면 아래와 같이 설명하고 있다.

```
-a=[]           : Attach to `STDIN`, `STDOUT` and/or `STDERR`
-t              : Allocate a pseudo-tty
--sig-proxy=true: Proxy all received signals to the process (non-TTY mode only)
-i              : Keep STDIN open even if not attached
```

tty(teleypewriter)는 콘솔이나 터미널을 의미한다.
즉 컨테이너를 현재 사용자가 접근하고 사용할 수 있도록 가상 터미널을 띄운다는 옵션인 것 같다.
(interactice shell)



### 현재 실행 중인 Docker 컨테이너 정보를 확인

```bash
# ps -> "process"
docker ps -a
```



## 컨테이너 생성 및 관리하기

- 남들이 잘 만들어 놓은 이미지를 기반으로 내가 필요한 부분만 추가해서 나만의 이미지를 만들 수 있지 않을까?
- 기본적인 환경과 툴을 제공하는 이미지를 Hub에서 가져온 다음에, 내가 개발하고 있는 앱에 수정을 가하고 필요한 부분을 추가하면 '나만의 이미지'를 만들고 배포할 수 있다.



## Node image를 활용한 실습

1. Docker Hub에서 제공하는 Node image를 활용하자.
2. 그렇지만 제공 image를 단순히 가져와 빌드만 하지 말고, 이 이미지를 기반으로 만든 컨테이너에 내가 작성한 코드를 포함시키자.
3. 그리고 코드를 수정하고 나서, 새롭게 업데이트 된 컨테이너를 나만의 이미지로 다시 만들어보자.

### Dockerfile 예시

```dockerfile
# FROM baseImage
# The name of the base image to use.
# Either exists in our local machine or in Docker Hub
FROM node

# Set the absolute or relative path to use as the working directory of the Docker container. Will be created if it does not exist
WORKDIR /app

# COPY [flags] source ... dest
# The name of the destination file or folder
COPY . /app


```


### COPY 명령어
COPY 명령어는 왼쪽에서부터 차례로
1) 현재 사용자(host)의 파일 시스템 중 복사하고 싶은 경로  
2) 붙여넣기할 컨테이너 내의 파일 시스템 경로

를 입력하면 된다.

![[week02.excalidraw.svg]]

container가 가지고 있는 파일 시스템은 현재 사용자의 파일 시스템과 완전히 독립된, 따로 떨어진(detached) 시스템이라고 생각해야 한다.

이렇게 COPY 명령어 전에 WORKDIR 명령어를 통해 컨테이너의 작업 디렉토리를 설정할 수도 있다.

![Container Directory](https://github.com/doku-study/doku-study/assets/36873797/8388c308-f401-4ff1-b1cd-bd48129b34f1)

### RUN 명령어
노드 서버를 실행시키고 싶다면 이렇게 Dockerfile을 구성할 수도 있다.

```dockerfile
# 윗부분 생략
RUN npm install
RUN node server.js
```

하지만 이렇게 하면 이미지를 빌드할 때마다 서버를 실행(`node server.js`)하는 것이기 때문에 올바르지 않다.
우리가 서버를 실행하고 싶은 시점은 **이미지를 빌드할 때가 아니라, 컨테이너를 실행할 때**이기 때문이다.

### CMD 명령어
이때 RUN 대신 CMD 명령어를 사용하면 된다.

```dockerfile
# 윗부분 생략
RUN npm install
CMD node server.js
```

근데 이것도 틀렸다. CMD의 인자는 문자열의 리스트라는 걸 명시해야 한다.

```dockerfile
# 윗부분 생략
RUN npm install

CMD ["node", "server.js"]
```


```dockerfile
# Execute any commands on top of the current image as a new layer and commit the results.
RUN npm install

# Provide defaults for an executing container. 
# If an executable is not specified, then `ENTRYPOINT` must be specified as well. 
# There can only be one `CMD` instruction in a `Dockerfile`

CMD node server.js
```

만약 CMD를 dockerfile에 명시하지 않으면 base image의 CMD 부분이 자동으로 실행된다.
CMD 명령어 인자가 없는 base image로 빌드하는 거라면 에러가 발생한다.

CMD 명령어는 Dockerfile의 항상 맨 마지막에 위치해야 한다. 이건 어떻게 보면 당연한 얘기다.
이미지를 빌드하고 나서 그 이미지를 바탕으로 컨테이너를 만드는 것이기 때문에,
이미지 빌드에 관여하는 다른 명령어(FROM, WORKDIR, COPY, RUN 등)가 실행되고 난 다음 컨테이너 실행 시 수행되는 명령어인 CMD를 실행하는 게 순서 상 맞기 때문

### EXPOSE 명령어
EXPOSE 명령어는 내가 실행하고자 하는 컨테이너를 로컬 시스템에서 접근(강의에서는 "listen"이라는 표현을 사용)할 수 있도록 포트 번호를 열어놓는 것이다.


### Image라는 설계도를 만드는 설계도 = Dockerfile?

Dockerfile을 통해 이미지를 빌드하는 명령어는 "build"

```bash
# dockerfile을 이용해 이미지를 빌드(나만의 커스텀 이미지 만들기)
# 현재 폴더 안에 Dockerfile이 존재해야 함
docker build .
```

이미지를 바탕으로 컨테이너를 실행(생성까지 한번에)하는 명령어는 "run"

![docker ps image ID](https://github.com/doku-study/doku-study/assets/36873797/c460518c-89ec-40b5-abff-440bfea5a5a0)

![docker container TTY](https://github.com/doku-study/doku-study/assets/36873797/26ca950b-221c-4698-bc7e-bef70334adcb)

### 포트 번호

컨테이너를 외부(=사용자)에서도 접근하게 하려면, 아래 명령어 형식으로 컨테이너를 실행하면 된다.

```
docker run -p 3000:80 docker_id
```


![Port Number](https://github.com/doku-study/doku-study/assets/36873797/a4b78fa0-24b8-4170-9120-973c1bbb421b)

웹 브라우저에서 '컨테이너를 실행하는 서버의 IP:3000' 형식으로 주소창에 입력하고 접속해보자.
만약 자신의 로컬에서 컨테이너를 실행하고 있다면 그냥 localhost:3000 을 웹브라우저에 입력해보자.

### EXPOSE에 대한 부가 설명
Dockerfile의 'EXPOSE 어떤 포트번호'는 선택 사항이라고 한다. 컨테이너가 '이 포트번호로 저 스스로를 노출할 겁니다'라고 **문서화**하는 것이기 때문. 
실제로 문서화가 되어있든 되어있지 않든 `docker run`을 실행할 때에는 `-p`를 사용해서 포트를 노출해야 한다.
하지만 Dockerfile에 'EXPOSE' 파트를 추가해서 이 동작을 문서화하는 게 모범적인 사용법이라고 한다.