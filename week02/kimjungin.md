# Docker 이미지 & 컨테이너  : 코어 빌딩 블록


## 이미지와 컨테이너의 차이

- 이미지는 애플리케이션을 실행하는 무엇이든 포함하는 작은 패키지이다.


- 컨테이너에는 소프트웨어 실행 유닛이 존재한다.


- 도커로 작업할 때, 이미지라는 디졸버(dissolver) 개념이 필요하다.


- 디졸버는 소프트웨어 모듈이나 도구를 가리키는 말로, (Resolver) 의존성 해결, 도메인 네임시스템 (도메인 IP 주소를 찾아 해당 서버와 연결해주는 시스템) 등 문제나 요청에 대한 해결책 역할을 한다.


- 이미지는 템플릿, 컨테이너의 블루프린트의 역할을 한다.


- 이 이미지를 사용하면 하나의 이미지로 여러 컨테이너를 생성할 수 있습니다.


- 이미지는 모든 설정 명령과 모든 코드가 포함된 공유 가능한 패키지입니다.


- 컨테이너는 이미지의 구체적인 실행 인스턴스입니다. 이미지를 기반으로 하는 컨테이너를 실행하는 것이다.


## Dockerfile

```python
FROM golang:1.20

WORKDIR /app

COPY go.mod go.sum ./

RUN go mod download

COPY . .

RUN go build -o basic

EXPOSE 8080

CMD ["./basic"]
```

- FROM : Docker Base Image (기반이 되는 이미지, <이미지 이름>:<태그> )
- MAINTAINER : 메인테이너 정보 (작성자 정보)
- LABEL : 라벨 작성 (docker inspect 명령으로 label 확인 가능)
- WORKDIR : “RUN” , “CMD” , “ENTRYPOINT” 명령이 실행될 작업 디렉터리
- ENV : 환경변수 설정
- USER : 명령 실행할 사용자 권한 지정
- ARG : Dockerfile 내부 변수
- ONBUILD : 다른 이미지의 Base Image 로 쓰이는 경우 실행될 명령 수행
- SHELL : Default Shell 지정
- ADD : 파일 / 디렉터리 추가
- RUN : Shell Script 또는 명령을 실행
    - 이미지가 생성될 때 실행되는 명령어
- ***COPY : 파일 복사***
    - `COPY . .`
    - 첫번째 . 은 컨테이너의 외부 경로를 의미하며 , 두번째 . 은 컨테이너 내부 이미지 경로이다.
        - 때문에 컨테이너 외부 (프로젝트 전체파일) 를 전체 복사해서 컨테이너 내부로 옮기는 것은 환경변수 파일도 모두 가져갈 수 있기 때문에 보안 상의 문제로 지양한다.
        - 또한 컨테이너 내부의 어떤 작업 디렉터리에 옮기는 지도 명시가 안되기 때문에 컨테이너 내부 경로도 명시해주는 것이 좋다.
    - Dockerfile 기준 외부 경로 파일을 → 컨테이너 내부로 복사
- EXPOSE : 호스트와 연결할 포트 번호를 설정
    - 이는 Documentation 목적으로만 명시할 뿐, 실제 포트를 열기 위해서는 docker run 명령어에서 명시해야한다.
- VOLUME : 볼륨 마운트
- ENTRYPOINT : 컨테니어가 시작되었을 때 스크립트 실행
- CMD : 컨테이너가 실행되었을 때 명령이 실행
    - 이미지 생성이 모두 완료되고 실행되는 명령어

# Docker Container 명령어

---

### 도커 이미지 빌드

```jsx
docker build -f Dockerfile --tag $(IMAGE_REPOSITORY):$(TARGET_VERSION) .
```

- `-f` : 도커 이미지 빌드를 할 때 사용하는 Dockerfile 명시
- `--tag` : 도커이미지 태그 설정

### 컨테이너를 이미지 기반으로 생성 및 실행

```jsx
docker run -d -p {컨테이너 외부 포트}:{컨테이너 내부 포트} --restart always --rm --name {container_id}
```

- `-p {컨테이너 외부 포트}:{컨테이너 내부 포트}` : 컨테이너 외부 포트(물리서버)와 컨테이너 내부 포트를 연결
- `container_id` 는 전체가 아닌 앞 Prefix 만 사용해도 사용가능하다.
- `--restart always` : container 가 불시에 Stop 이 되었을 때 Restart 를 자동화한다.
- `-d`  : detache mode 로 실행
- `--rm` : 도커 동작이 끝난 후 자동으로 컨테이너 삭제
- `--name` : 컨테이너에 이름을 붙일 수 있음

### 실행중인 컨테이너 조회 목록

```jsx
docker ps -a
```

- `-a` : 도커 컨테이너의 모든 목록

### 이미 생성된 컨테이너 실행

```python
docker start -a -i {container_id}
```

- `-a` : 도커 컨테이너를 실행할 때 접속하는 옵션
- `-i` : 도커 컨테이너에 입출력을 할 수 있도록 하는 옵션

### 컨테이너 중단

```jsx
docker stop {container_id}
```

### 컨테이너 로그 출력

```jsx
docker logs -f {container_id}
```

- 도커 로그를 출력하는 명령어
- `-f` : 도커 로그를 tail 함

### 컨테이너의 표준 입출력 및 에러 확인하는 명령어

```jsx
docker attach [OPTIONS] CONTAINER
```

### 도커 옵션에 대한 메뉴얼

```jsx
docker --help
```

### 도커 컨테이너 접속

```jsx
docker exec -it {conatiner_id} {CMD}
```

- `-i` : 컨테이너에 입출력을 유지할 수 있게 하는 옵션
- `-t` : TTY 할당, 터미널을 생성하는 것을 의미
- `-it` : 터미널을 생성해서 입출력을 유지할  수 있게 해주는 옵션

### 컨테이너 삭제

```python
docker rm {container_id}
```

### 이미지 삭제

```python
docker rmi {image_id}
```

### 사용하지 않는 모든 이미지 제거

```python
docker image prune -a
```

### 이미지 검사 및 상세 정보 출력

```python
docker image inspect {image_id}
```

### 컨테이너 / 컨테이너로부터 파일 복사

```python
# 외부에 있는 파일을 컨테이너 내부로 복사
docker cp {대상외부파일} {conatiner_name}:{컨테이너내부위치하고자하는 경로}

# 컨테이너 내부에 있는 파일을 컨테이너 외부에 복사
docker cp {conatiner_name}:{컨테이너내부위치} {외부위치하고자하는 경로}
```