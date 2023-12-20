# 새롭게 알게된 점

---
## Docker

- 하나의 서버에 여러 프로그램이 동작하는 경우가 많다.
- 각 프로그램별 필요로 하는 도구들이 다르기 때문에 여러 의존성, 라이브러리들이 충돌될 수 있다.
    - ex) 서버 호스트에 설치된 Java 버전으로 인해 애플리케이션의 JDK 를 올릴 수 없는 상황이 발생한다.
- 프로그램 설치 및 전환이 쉽다.
    - 배포 및 롤백


## Virtual Machine 과 Container 의 차이

---

- Virtual Machine
    - Linux
    - Window
- 여러 Virtual Machine 에서 발생하는 오버헤드가 문제가 된다.
    - Virtual Machine 에 공통된 의존성과 라이브러리들을 중복으로 설치하게 되며, 이는 Resource 문제로 이어진다.
- Virtual Machine 은 설치 방식이 까다롭다
    - 커널 …

## Container

- 컨테이너를 사용하면 하나의 OS 위에 도커 엔진을 실행시킨다.
- 리눅스 커널, 라이브러리 등과 같은 도구들은 공유하여 중복 설치를 제거하며, 그 위에 컨테이너를 생성하여 애플리케이션 단위로 라이브러리들을 독립적으로 설치한다.
- 도커엔진은 하나의 도구로, 여러개의 컨테이너를 관리하게 도와준다.
- 컨테이너는 구성파일을 이미지로 만들어 다른 사람과 공유하여 사용할 수 있게 한다.


![a1](https://github.com/doku-study/doku-study/assets/41246605/7d6ea9e3-398d-4dc4-adaa-75cb95e2c0e2)


## Golang-Dockerfile Example

```go
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
- RUN : Shell Script 또는 명령을 실행
- CMD : 컨테니어가 실행되었을 때 명령이 실행
- LABEL : 라벨 작성 (docker inspect 명령으로 label 확인 가능)
- EXPOSE : 호스트와 연결할 포트 번호를 설정
- ENV : 환경변수 설정
- ADD : 파일 / 디렉터리 추가
- COPY : 파일 복사
- ENTRYPOINT : 컨테니어가 시작되었을 때 스크립트 실행
- VOLUME : 볼륨 마운트
- USER : 명령 실행할 사용자 권한 지정
- WORKDIR : “RUN” , “CMD” , “ENTRYPOINT” 명령이 실행될 작업 디렉터리
- ARG : Dockerfile 내부 변수
- ONBUILD : 다른 이미지의 Base Image 로 쓰이는 경우 실행될 명령 수행
- SHELL : Default Shell 지정

<br />

# 함께 이야기하고 싶은 점

- 이번 강의 섹션에서 Container 개념과 이미지 Build 에 대한 주제로, Build 자동화 관련 내용을 공유하고자 합니다.



## Makefile

---

- Makefile 은 linux 상에서 반복적으로 발생하는 컴파일을 쉽게하기 위해서 사용하는 make 프로그램의 설정 파일이다.
- Makefile 을 통해 다양한 버전 정보, 빌드 옵션을 `make` 명령어로 자동화할 수 있다.

![a2](https://github.com/doku-study/doku-study/assets/41246605/c17555cd-c4c7-4f8d-b29f-e6c9abd10118)

- Makefile 은 위의 이미지와 같이 해당 프로젝트 최상단에 Makefile 을 생성한다.
- build.num 파일을 생성한다.

```shell
0
```

- version.txt 파일을 생성한다.

```shell
1.0
```

- Makefile 예시

```go
PROJECT_PATH=$(shell pwd)
MODULE_NAME=sample

BUILD_NUM_FILE=build.num
BUILD_NUM=$$(cat ./build.num)
APP_VERSION=$$(cat ./version.txt)
TARGET_VERSION=$(APP_VERSION).$(BUILD_NUM)
IMAGE_REPOSITORY="{image repository}"

TARGET_DIR=bin
OUTPUT=$(PROJECT_PATH)/$(TARGET_DIR)/$(MODULE_NAME)
MAIN_DIR=/main.go
LDFLAGS=-X main.BUILD_TIME=`date -u '+%Y-%m-%d_%H:%M:%S'`
LDFLAGS+=-X main.GIT_HASH=`git rev-parse HEAD`
LDFLAGS+=-s -w

all: config target-version docker-build docker-push

config:
  @if [ ! -d $(TARGET_DIR) ]; then mkdir $(TARGET_DIR); fi

build:
  CGO_ENABLED=0 GOOS=linux go build -ldflags "$(LDFLAGS)" -o $(OUTPUT) $(PROJECT_PATH)$(MAIN_DIR)
  cp $(OUTPUT) ./$(MODULE_NAME)

docker-build:
  docker build -f Dockerfile --tag $(IMAGE_REPOSITORY):$(TARGET_VERSION) .

docker-push:
  docker push $(IMAGE_REPOSITORY):$(TARGET_VERSION)

docker-release:
  docker build -f Dockerfile --tag $(IMAGE_REPOSITORY):latest .
  docker push $(IMAGE_REPOSITORY):latest

target-version:
  @echo "========================================"
  @echo "APP_VERSION    : $(APP_VERSION)"
  @echo "BUILD_NUM      : $(BUILD_NUM)"
  @echo "TARGET_VERSION : $(TARGET_VERSION)"
  @echo "========================================"

build-num:
  @echo $$(($$(cat $(BUILD_NUM_FILE)) + 1 )) > $(BUILD_NUM_FILE)

clean:
  rm -f $(PROJECT_PATH)/$(TARGET_DIR)/$(MODULE_NAME)*
	
```

- Makefile 은 최상단에 사용할 변수들을 선언한다.
    - `CC` 는 Makefile 에서 goalng compiler 를 의미한다.
    - `TARGET_DIR` 은 해당 Makefile 로 만든 bulid 파일을 보관할 디렉터리를 의미한다.
    - `MAIN_DIR` 은 go 어플리케이션에서 패키징할 패키지를 의미한다.
    - `LDFLAGS` 는 golang 의 build 옵션으로 빌드 정보를 담아주는 역할을 한다.
    - `OUTPUT` 은 go 어플리케이션을 패키징할 때 생성되는 파일의 위치이다.


- 그 후 매크로로 등록할 키워드와 명령어를 입력해준다.
    - all : `make all` 명령어를 통해 `all` 에 표기된 `clean` 과 `reporter` 를 실행시켜준다.
    - $(BUILD_NUM_FILE) : 다른 키워드가 실행되기 전에 먼저 실행되는 명령어이다.
    - reporter : build 번호를 업데이트하며 go 프로젝트의 빌드 명령어를 수행한다.
        - reporter 에서 생성되는 파일은 배포를 용이하게 하기 위해 /docker 디렉터리에 복사해준다.
    - clean : 기존 build 했던 파일이 있는 디렉터리는 삭제한다.


- `make`  키워드를 해당 프로젝트 위치에서 실행시키면 Makefile 로 실행되는 명령어에 대한 로그와 함께 `/bin/reporter`실행파일이 생성됨을 알 수 있다.


