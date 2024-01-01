
### docker --help
또는 docker 공식 문서에서 다양한 명령어를 확인할 수 있다.
그렇다면 이 명령어에서 우리가 정말 자주 쓰고 필요한 명령어(core commands)는 무엇인가?

### docker ps

```bash
# --all. 이미 중단되었던 container도 확인할 수 있다
docker ps -a

# --last int. 가장 최근에 생성된 마지막 3개 컨테이너만 보여준다
docker ps -3
# 기본 사용법: docker ps -n

# --latest. 가장 마지막으로 생성된 컨테이너를 보여준다(모든 상태 포함)
docker ps -l

# --size
# docker ps -s
```

### docker container의 attached와 detached mode

```
docker start docker_mode
```

중단되었던 컨테이너를 재시작하는 명령어. 하지만 조금 다른 방식으로 시작한다.
컨테이너와 interact할 수 없고, 터미널에선 여전히 사용자의 입력을 받을 수 있는 모드를 유지한다.
즉 컨테이너는 background mode로 실행되고 있다.

이를 다르게 표현하자면 "detached mode"로 컨테이너를 실행한다고 한다.
`docker start` 명령어는 default로 detached mode로 컨테이너를 실행하기 때문이다.

detached container는 내가 컨테이너 속 코드에서 로깅을 한다 해도 사용자 입장에서 (터미널에서) 확인할 수 없다.
반면에 attached container는 바로 터미널에서 확인할 수 있다.

docker container를 detached mode로 실행하는 법은 간단하다. -d 옵션만 붙여주면 된다.

```
docker run -p 8000:80 -d docker_id
```

 그리고 이미 detached된 container를 다시 attached mode로 바꾸려면 이렇게 명령어 입력만 해주면 된다.

```
docker attach CONTAINER_NAME
```

attached mode로 굳이 바꿀 필요 없이 log만 확인하고 싶다면

```
docker logs CONTAINER_NAME
```

follow mode로 log를 실시간으로 계속 확인하고 싶다면

```
docker logs -f CONTAINER_NAME
```

-f 옵션을 붙여서 logs 명령어를 실행하면 된다.

### Docker container의 터미널에서 표준 입력(Standard input)을 받고 싶은 경우

이런 파이썬 소스코드를 컨테이너 내에서 실행하고 싶다고 하자.

```python
from random import randint

min_number = int(input('Please enter the min number: '))
max_number = int(input('Please enter the max number: '))

if (max_number < min_number): 
  print('Invalid input - shutting down...')
else:
  rnd_number = randint(min_number, max_number)
  print(rnd_number)
```

그냥 컨테이너를 실행하면 다음과 같은 에러가 발생한다.
standard input을 받도록 옵션을 설정하지 않았기 때문

![standard input](https://github.com/doku-study/doku-study/assets/36873797/11e7f779-1168-4f40-b330-e48f84ee78fa)


이걸 해결하기 위해서는

```bash
docker run -i -t DOCKER_ID 
# docker run -it DOCKER_ID 
```

pseudo terminal that is connected to the container process that listens for user input.

docker start 명령어를 실행할 때는 다시 -i 옵션을 달아줌으로써 내가 컨테이너 터미널에 입력을 하고 싶다 ("listen"할 것이다)고 명시해야 한다.


```
docker start -a -i CONTAINER_NAME
```

-a = attached mode = "listen" mode
-i = "input" mode = I want to "input" something mode


### 안 쓰는 컨테이너 삭제하기

```
docker rm CONTAINER_NAME
```

하지만 실행 중인 컨테이너를 삭제할 수 없다(You cannot remove a running container 메시지 출력)
-> `docker stop CONTAINER_NAME` 명령어로 중단한 다음에 삭제해야 함

여러 컨테이너를 동시에 삭제할 수도 있다.
띄어쓰기로 이름을 아래처럼 여러 개 입력하면 된다.

```
docker rm CONTAINER_NAME1 CONTAINER_NAME2 CONTAINER_NAME3...
```

### Image 삭제

먼저 현재 내가 보유한 image 목록을 보려면 간단하게 이 명령어를 쓰면 된다.
```
```bash
docker images
```

image를 삭제할 수도 있다.

```bash
docker rmi IMAGE_ID
```

하지만 만약 삭제하고자 했던 이미지에 대해, 그 이미지를 기반으로 만들어진 컨테이너가 존재한다면 (그 컨테이너가 실행 중이든 중단되었든 간에) 이미지 또한 삭제할 수 없다. 
그렇기 때문에 이미지를 삭제하려면 그 이미지를 기반으로 만들어진 컨테이너를 모두 삭제한 다음에 이미지를 삭제해야 한다.

### 중지된 컨테이너 자동 삭제 옵션

다음은 컨테이너를 실행하는 run 명령어이다.
자세히 보면 이전 명령어에서 `-rm` 옵션이 추가된 걸 확인할 수 있다.

```
docker run -p 3000:80 -d -rm DOCKER_ID
```

`-rm` 옵션을 붙이면, 컨테이너가 중단되는 즉시 자동으로 그 컨테이너를 삭제한다.
그러면 이 옵션은 언제 쓰는 거고 어떨 때에 편리한 걸까?

예를 들어 node web server를 도커로 운영하는 경우, 코드를 수정하고 나면 항상 수정된 코드가 반영된 새 컨테이너로 테스트를 해야 한다. 즉 기존의 컨테이너는 더 이상 사용할 필요가 없어진다. 그렇기 때문에 중단한 컨테이너를 자동으로 삭제하는 옵션이 편리할 수 있다.


## image 검사

다시 이미지로 돌아가보자.
image는 크지만, 돌아가고 있는 container는 크지 않다. container란 image 위에 얹혀있는 command layer에 불과하기 때문
동일한 image에서 생성된 여러 개의 (서로 다른) container들은 모두 제각기 코드의 복사본을 가지고 있는 게 아니라, 이미지 속에 한 코드를 공유한다.

하지만 image에 대해 더 자세한 내용을 알고 싶다면 다음 명령어를 쓰면 된다.

```
docker image inspect IMAGE_ID
```

image ID, 생성일자, 구성, 포트 번호, 환경변수, entry point, 도커 버전, 사용 OS, layer 정보 등을 확인할 수 있다. 다른 외부 image를 pull해서 사용하거나, 본인이 직접 image를 생성했지만 그 정보에 대해 잊어버렸을 때 image에 대해 더 자세히 알 수 있으니 유용하다.


## container에 파일을 추가 또는 가져오기

```bash
docker cp target destination
```

예를 들어서 현재 사용자의 로컬에 dummy라는 폴더가 있고 그 안에 여러 파일이 있다면, 그 모든 파일을 이렇게 .을 찍어서 복사할 수 있다:

```bash
# docker cp dummy/. DEST_CONTAINER_ID:target_dir
docker cp dummy/. boring_vaughan:/test
```

cp command를 통해 container를 restart하거나, image를 rebuild하는 일 없이 파일을 container에 추가할 수 있다. 하지만 이런 방법은 에러를 일으킬 수 있다(error-proned).



## container와 image에 이름 또는 태그를 지정하기

docker image에도 태그가 존재한다.
그리고 docker container를 `docker ps` 명령어를 통해 보면, 이름이 할당되어 있다. 하지만 이건 자동으로 할당되는 것이기 때문에 매번 docker ps 명령어로 확인할 수밖에 없다.

docker container에 이름을 지정하고 싶다면, 해당 container를 실행(run)할 때 --name 옵션으로 이름을 지정하는 수밖에 없다(run하지 않고 이름을 할당할 순 없나?)

```bash
docker run -p 3000:80 -d --rm --name goalsapp CONTAINER_ID
```

containr에 이름이 있다면, 당연히 image에도 이름이 있을 것이다. 그런데 image에 대해서는 이름이라고 하지 않고 tag라고 지칭한다.

image 태그를 지정할 때 먼저 name, 아니 repository를 지정해야 한다.

![docker name and tag](https://github.com/doku-study/doku-study/assets/36873797/9ae20103-2120-42a4-a802-fef46b2bb002)


다음은 현재 폴더에 있는 Dockerfile로 image를 build하면서 태그를 지정할 때 사용하는 명령어이다.

```bash
# docker build -t my_image_repository:my_image_tag
docker build -t goals:latest
```

반면에 이미 build된 image 태그를 지정할 수도 있다.

```
docker tag 0e5574283393 fedora/httpd:version1.0
```

이미 태그가 있는 image에 대해 새로운 tag로 바꿀 수도 있다.

```
docker tag httpd:test fedora/httpd:version1.0.test
```

