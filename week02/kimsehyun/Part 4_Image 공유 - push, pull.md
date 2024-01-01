## Image 또는 Container를 공유하기

자명한 전제: Everyone who has an image, can create containers based on the image!

그렇기 때문에 container 자체를 공유하는 게 아니라 image를 공유할 것이다.

### 방법 1: Dockerfile과 코드를 공유
어차피 dockerfile과 필요한 코드만 있다면, docker build 명령어로 image를 만들 수 있고, container는 image-based이니 Dockerfile과 코드만 있으면 된다.
- 장점: `docker build .` 명령어만 입력하면 된다.
- 유의사항: image build 후 생성되는 디렉토리에 있어야 할 파일과 폴더(소스 코드 등)가 모두 사전에 있어야 한다.

### 방법 2: 이미 built된 image를 통째로 공유
두번째 방법은 이미 built된 image 파일을 통째로 공유하는 것이다. 
공유받은 image를 다운로드하고 이걸 바탕으로 container를 실행(run)하면 된다.

build하는 과정이 없다. image에 모든 게 다 준비되어 있다. 즉 코드를 따로 공유할 필요가 없다는 뜻이다. 
팀끼리 협업하거나 나중에 배포할 때에는 보통 완성된 image를 공유한다.


## 어디에 공유를 할 것인가? Docker Hub vs. Private Registry

Docker hub은 도커의 '공식' image registry를 말한다.
Docker hub은 무료 쓸 수 있다. 단 유료 구독을 하면 private repository를 무한정 쓸 수 있고 CI/CD에 대해서도 지원해준다.

Docker Hub에 push, pull를 하려면 그냥 image 이름만 있으면 된다.

```bash
docker push IMAGE_NAME
docker pull IMAGE_NAME
```

반면에 private repository에서 image를 가져오거나 push를 하려면 host를 지정해주어야 한다.

```bash
docker push HOST:IMAGE_NAME
docker pull HOST:IMAGE_NAME
```

1. Docker Hub 웹사이트에 들어간다.
2. 로그인한다.
3. 새로운 repository를 만든다. 깃허브와 유사하다. username/repository_name 형식이다. (예: academind/node-hello-world)
4. push하려는 image 이름(tag)를 방금 새로 생성한 user_name/repository에 맞게 변경한다.
5. `docker tag` 명령어로 rename해도 기존의 image는 그대로 남아있다. 덮어쓰기가 아니라 복사하기다.
6. 그냥 `docker push` 명령어를 쓴다면 접근 권한이 없어서 거부되므로 docker login 로그인을 해야 한다. Docker Hub에 접속할 때 썼던 본인 ID와 비밀번호를 터미널에도 똑같이 입력하면 된다.



image를 push할 때에는 전체 image를 통째로 업로드하는 게 아니다. 영상 예제의 image 파일 크기는 950MB인데 이렇게 1GB 가까이 되는 image를 전세계 도커 유저들이 업로드하면 Docker hub 서버는 진작에 터졌을 것이다.
다시 예제로 돌아가보자. 지금 push하려는 image는 node image를 바탕으로 코드만 수정해서 새로운 image를 만들었다. node image는 이미 Docker Hub에 올라와있는 공식 image이기 때문에 이 부분은 굳이 통째로 다시 업로드할 필요가 없다. 그래서 추가, 수정된 부분만 push하면 된다. 
docker push가 이루어지는 방식이 이렇다.


## 현재 존재하는 image를 전체 삭제

```
docker image prune -a
```

강의 영상에서는 academind/node-hello-world 이름의 image를 pull하기 위해 겹치는 이름이 없도록 사전에 모든 image를 삭제했다. 하지만 정말 확실한 경우가 아닌 이상 이 명령어는 함부로 쓰지 말자.

```
docker pull academind/node-hello-world
```

사용자가 public으로 공개한 image는 Docker Hub에 로그인하지 않아도 그냥 pull 해올 수 있다.
물론 push는 사용자 본인만 할 수 있다.

### pull 관련 유의사항
- docker pull 명령어를 쓸 때 태그를 지정하지 않으면 default tag인 latest로 가져온다.
- Docker Hub에 올라와있는 image라면 pull을 미리 하지 않아도 docker run 명령어를 통해 pull + run을 동시에 할 수 있다. 단, 로컬에 이미 해당 이름의 image가 있다면 로컬의 image를 실행할 것이다. 로컬에 run하고자 하는 이름의 image가 있는지 없는지 먼저 확인하기 때문

docker run 명령어는 로컬에 있는 image를 최우선으로 가져오기 때문에 업데이트한 image를 자동으로 가져오지는 못한다. 


![docker run](https://github.com/doku-study/doku-study/assets/36873797/1210e977-67c1-45c5-8897-331f861a5a8d)


### Docker Hub는 그외에도 다양한 기능을 지원한다
push, pull 외에도 배포를 위한 다양한 명령어가 있다. 하지만 지금 당장 알아두어야 할 key feature는 이 두 가지이다.

## 퀴즈 복습

```bash
docker run --name test -it debian
```

debian:latest image를 베이스로 container를 실행하되, test라는 이름을 할당한다.
(헷갈리는 부분: 이미 test라는 이름의 container를 실행하는 게 아니라, 이름을 새로 할당하는 것)
참고로 -it 옵션은 pseudo-TTY(teletype writer = terminal)를 할당해서 container의 stdin에 연결하겠다는 뜻이다. 사용자가 container 내부를 마치 자기 로컬처럼 조작할 수 있게 터미널을 할당한다는 말과 동일하다.

```bash
docker build -t myimage .
```

현재 Dockerfile을 바탕으로 image를 생성하되 그 image에 이름(tag)을 부여한다.



## 요약

Docker란 결국 **image**와 **container**에 대해 다루는 게 전부다.

1. Image란 container를 위한 템플릿 또는 설계도이다. 동일한 한 image로부터 여러 (서로 다른) container를 생성할 수 있다.
2. Image는 어디에서 오는가? 
3. Image는 여러 layer로 구성되어 있다. Dockerfile의 한 명령어는 (얼추) 한 layer에 대응된다고 보면 된다. 도커의 image가 layer 기반 구조이기 때문에 캐싱을 이용해서 build 속도를 높일 수 있다. 즉 이미 만들어놓은 layer는 다시 따로 구축할 필요가 없게 설계해 놓았다. 재사용성(reusability)를 높였다는 말과 동일하다.

### Container vs. Image
- 생성: 
	- image는 `docker pull` 명령어로 Docker hub이나 private repository에서 다운로드받거나, Dockerfile이 있다면 `docker build .` 명령어로 직접 빌드한다. 
	- container는 `docker run IMAGE` 로 생성. IMAGE에는 image ID 또는 (image 이름이 있다면) 이름(tag)이 들어간다.
- 목록 확인: image는 `docker images`, container는 `docker ps`
- 삭제: image는 `docker rmi` 또는 전체를 다 삭제할 경우 `docker image prune`, container는 `docker rm`
- 컨테이너는 이미지와 달리 `running instance`이기 때문에 실행을 시작 및 중지하는 명령어로 `docker start/stop`가 있다.