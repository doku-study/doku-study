# Utility Container
-> 공식 용어는 아니지만, 이 강의자가 붙인 이름이다.

지금까지는 application container로만 작업했다. 그리고 이게 primary selling이고 core idea이다. 도커가 존재하는 가장 큰 이유일 것이다.

유틸리티 컨테이너란 특정 환경만 구축해놓은 컨테이너를 말한다.

이해 안되니까 일단 그대로 받아적자.
And the idea here is that they don't start an application when you run them, but instead you run them in conjunction with some command specified by you to then execute a certain task.


## 컨테이너 '안'에서 명령을 실행하는 방법: docker exec

어떤 컨테이너를 detached mode로 실행하면, 그 컨테이너의 터미널로 접속할 방법이 컨테이너 중지 -> attached mode로 재실행 말고는 없는 걸로 알고 있다.
하지만 docker exec 명령어를 쓰면 detached된 컨테이너에 명령을 입력할 수 있다.

```bash
docker exec MY_CONTAINER_NAME npm init
```

 만약에 현재 실행하고자 하는 명령어가, 이후에 input을 받아야하는 명령이라면(npm init은 그 이후에 ~를 설치하시겠습니까? 류의 질문을 받는다) interactive mode로 exec 할 수도 있다.

```bash
docker exec -it MY_CONTAINER_NAME npm init
```



## 첫 번째 유틸리티 컨테이너 구축하기

```Dockerfile
# extra slim operating layer in node
FROM node:14-alpine

WORKDIR /app

%% CMD npm init %%
```

이미지 빌드 후
mirroring한다?

```
docker build -t node-util .

docker run -it node-util npm init
```

bind mount로

```bash
docker run -it -v /Users/my/local/folder:/app node-util npm init
```


## Entrypoint

```dockerfile
FROM node:14-alpine

WORKDIR /app

ENTRYPOINT ["npm"]
```


```bash
docker run -it -v /Users/my/local/folder:/app mynpm init
```

npm init이 아니라 그냥 init만 입력해도 npm  명령어를 실행한다.

### 부록: CMD vs. ENTRYPOINT 명령어의 차이?

출처: https://stackoverflow.com/questions/21553353/what-is-the-difference-between-cmd-and-entrypoint-in-a-dockerfile

아래 명령어로 이미지를 빌드하고 컨테이너를 생성, 실행한다고 해보자.

```bash
docker run -i -t MY_IMAGE
```

만약 이 이미지를 빌드하기 전 dockerfile에 CMD를 `do something` 로 주었다면,

```bash
docker run -i -t MY_IMAGE <cmd>
```

의 효과를 낼 것이다.

반면에 ENTRYPOINT를 dockerfile에 주었다고 생각해보자.
그리고 아래 명령어로 컨테이너를 실행하려 한다고 해보자.

```bash
docker run MY_IMAGE redis -H something -u toto get key
```

이렇게 매번 길게 쓰기 불편하니까, ENTRYPOINT를 사전에

```bash
ENTRYPOINT ["redis", "-H", "something", "-u", "toto"]
```

로 준다면

```bash
docker run MY_IMAGE get key
```

명령어로 위 명령어와 동일한 효과를 낼 수 있다.


참고로 ubuntu dockerfile의 기본 CMD는 `CMD ["bash"]` 이고 ENTRYPOINT는 `/bin/sh -c` 이다.
그래서 사실 `docker run -i -t ubuntu` 를 실행하면 `docker run -i -t ubuntu /bin/sh -c bash`를 실행하는 것과 동일하다.
여기서 `/bin/sh -c`라는 entrypoint를 어떻게 하면 사람들이 직접 커스터마이징할 수 있을까 해서 생겨난 명령어가 ENTRYPOINT이고, 매번 컨테이너 실행할 때마다 명령어 입력하기 귀찮으니 run할 때 같이 자동으로 실행할 수 있게 만든 게 CMD라고 보면 될 것 같다.


## docker-compose로 만들기

하나의 컨테이너여도 docker compose로 만들면 관리하기가 편하다.

```yaml
version: "3.8"
services: 
  npm:
    build: ./
    stdin_open: true
    tty: true
    volumes:
      - ./:/app
```

이렇게 docker compose 파일을 만들어서 

```bash
docker compose up
```

으로 실행하면, 
entrypoint를 명시하고는 아무런 명령어를 입력하지 않았기 때문에 npm을 제대로 설치 못한다(뭘 실행한 건지 정확히 모르는?).
그래서 이번에는 끝에 init을 붙여줘서 `npm init`을 실행하도록 하자.

```
docker compose up init
```

어라라? 이렇게 하면 에러가 발생한다. No such service: init라고 한다.

### docker compose up은 docker run과 작동 방식이 다르다.
아하, docker compose up 명령어는 docker run과 작동하는 방식이 좀 다른가보다.
docker compose up 뒤에 명령어를 붙여봤자 이걸 명령어로 인식하지 못한다.
docker compose up은 말 그대로 compose 파일에 있는 서비스를 차례로 '차려놓는' 것에 불과하기 때문이다.

### docker compose run

docker compose 파일에 여러 서비스가 있을 때(대부분 이런 경우다) 여기에서 특정 한 서비스만 이름을 지정해서 실행할 수 있다.

```bash
docker compose run npm init
```

docker compose파일에서 npm이라는 이름의 서비스가 있는지 확인하고, 있다면 그 서비스만 실행한다.
그리고 entrypoint로 "npm"이 있기 때문에 init만 붙여도 npm init을 실행한다.

### docker compose run: 컨테이너를 알아서 삭제하지 않는다.
docker compose up을 하면, 서비스를 중지할 때 알아서 삭제한다. 
즉 --rm 옵션을 명시하지 않아도 해당 옵션을 달아놓은 것처럼 작동한다는 뜻이다.

하지만 docker-compose run은 컨테이너를 중지해도, 알아서 삭제하지 않는다.
그렇기 때문에 자동 삭제를 원한다면 --rm 옵션을 붙여줘야 한다.

```bash
docker compose run --rm npm init
```

