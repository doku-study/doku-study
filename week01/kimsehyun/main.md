## 컨테이너(Container)란?

- "표준화된 소프트웨어 단위"
- 즉 다시 말해서 어떤 실행 가능한 코드뿐만 아니라 그 코드를 실행하기 위한 모듈, 패키지, 가상환경들을 모두 합쳐놓은 것을 말한다.
- 컨테이너의 가장 큰 특징은 독립(또는 고립, isolated)되어 있고 자기 충족적(self-contained)이라는 점이다. 그래서 스스로 기능한다는 의미에서 단위(unit)라는 말을 쓰는 것 같다.

![컨테이너의 특성](kimsehyun/attachments/container1.png?raw=true)

<p float="center">
<img src="kimsehyun/attachments/container1.png?raw=true" width="75%" />
</p>

### Reproducibility

- 컨테이너 안에 담긴 코드는 누가 실행하든, 어떤 OS나 환경 안에서 실행하든 (이상적으로는?) 항상 동일한 실행 결과를 보장한다.

### 도커(Docker) 개요

- 도커는 컨테이너를 생성하고 관리하기 위한 기술이다.
- 도커가 실행되는 환경이라면 어디서든 내가 원하는 application을 동일한 조건으로 실행할 수 있다.
- 다른 부가적인 의존성이나 툴에 대해 신경 쓸 필요가 없어진다.
- 오늘날 우리가 쓰는 OS는 모두 컨테이너 기술을 지원하고 있다.

## 도커를 써야 하는 이유

### 서로 다른 개발 및 배포 환경

사람들이 개발하는 application과 프로그램은 사용하는 패키지의 버전, 환경 등이 모두 다르다.
우리가 나중에 앱을 수정하거나 테스트할 때 기존 개발자가 실행한 결과를 그대로 재현하는 게 첫 단계다.

이때, 기존 개발자가 사용했던 모듈과 환경을 일일이 다운로드하고 설치한다면 시간이 너무 오래 걸릴 것이다.
시간은 둘째 치고 내 컴퓨터 환경에서 다른 개발자의 환경을 정확하게 구현할 수 있을지 확실하지도 않다.
(툴이나 라이브러리의 버전 충돌, 설치 오류 문제 등등)

이때 재현 가능한 개발 환경을 '패키징'해서 제공하는 게 바로 도커(Docker)이다.

## 가상 머신 vs. 도커

특정 앱에 맞는 환경을 구축하기 위해 가상 머신(virtual machine)을 쓸 수는 있다.
그러나 가상 머신은 "machine(=컴퓨터 시스템)"이라는 말 그대로 컴퓨터 환경을 하나 통째로 복사하는 것과 비슷하기 때문에 오버헤드가 엄청나게 발생한다.

혼자 작동하는 standalone computer, machine을 구축하는 것과 비슷하기 때문에 한 프로그램을 구동하기 위해 갖춰야 하는 메모리와 CPU 자원이 엄청나다.

### 가상 머신의 장단점

- 분리, 독립된 실행 환경
- 앱을 구동하기 위한 특정 환경 구성이 가능
- 안정적으로 환경 구성을 공유하고 재현할 수 있음
- 하지만 너무 비효율적이다! 즉, 중복된 메모리와 자원 사용 + 속도와 성능 저하 + 부팅 시간 소모 등

## 컨테이너 기술

![컨테이너 기술 개요도](kimsehyun/attachments/container_and_OS.png?raw=true)

<p float="center">
  <img src="kimsehyun/attachments/container_and_OS.png?raw=true" width="75%" />
</p>

컨테이너는 사용자의 OS 위에서 작동한다.
반면 가상 머신은 아예 별도의 OS를 하나씩 꾸려놓는 것이기 때문에 컨테이너는 훨씬 더 무거울 수밖에 없다.

## 가상 머신과 컨테이너의 비교

![가상머신 vs. 컨테이너](kimsehyun/attachments/vm_container.png?raw=true)

<p float="center">
<img src="kimsehyun/attachments/vm_container.png?raw=true" width="75%" />
</p>

### 도커는 가상 머신과 이 점에서 다르다

- 앱을 구동하기 위한 기기의 전체 환경을 구축하는 게 아니라 앱과 그것에 필요한 환경만 분리하여 구축
- OS를 직접 구축하지 않음
- 빠르고 디스크 사용량도 적음
- 공유, 배포, 재사용이 효율적이고 빠름

## 도커 사용법

본격적으로 도커를 사용하려면 일단 자신의 OS가 무엇인지 파악해야 한다.

- 1번 옵션: macOS나 Windows일 경우 **Docker Desktop**을 설치하기
- 2번 옵션: requirements 충족하지 못한다면, Docker Toolbox를 통해 설치하기 (이게 무슨 뜻일까?)
- 3번 옵션: 다 필요없고 난 리눅스 쓸래! 그러면 바로 사용 가능.

### 내가 리눅스로 실습을 하기로 한 이유

리눅스에선 아래 명령어로 바로 Docker 설치 및 사용이 가능하기 때문

```
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```

사실 저 명령어 입력 이전에 더 거쳐야 하는 단계가 있다. 다음 링크를 참조할 것: <https://docs.docker.com/engine/install/ubuntu/>

리눅스는 자체적으로(natively) Docker Engine을 지원한다.

## 도커 구성 요소

![도커 구성 요소](kimsehyun/attachments/components_of_docker.png?raw=true)

<p float="center">
<img src="kimsehyun/attachments/components_of_docker.png?raw=true" width="75%" />
</p>

- Docker Engine: 도커 컨테이너가 사용자의 OS에 맞게 실행이 가능하도록 OS 레벨에서 지원하는 기술
- Docker Desktop: Docker Engine을 알아서 설치. Daemon & CLI이 실행 가능하도록 세팅
- Docker Hub: Docker image를 웹에서 가져와 사용하거나 우리가 만든 image를 다른 사용자에게 공개할 수 있는 웹 호스팅 서비스
- Docker: multi-container를 위한 서비스?

## 도커 사용을 위한 기본 IDE

- VS Code + Docker 익스텐션은 필수로 설치할 것

## 도커  기본 명령어

### Dockerfile 생성

```dockerfile
# 명령어가 더 다양함. 모두 대문자로 쓰는 게 convention

# Docker Hub에서 어떤 이미지를 가져올지 지정
FROM node:14

# 도커 이미지를 build 하고 나면 컨테이너 내에 자체적으로 디렉터리를 생성하는데, 그때 파일을 생성하고 실행하기 위한 작업 디렉토리를 지정하는 걸 의미한다.
WORKDIR /app

# 순서: target_directory destination_directory
# 어떤 파일을 복사할지 지정
# 왼쪽에는 복사하고자 하는 (도커 컨테이너 바깥의) 파일을, 띄어쓰기하고 오른쪽에는 파일을 붙여넣고자 하는 도커 컨테이너 내의 디렉토리를 의미
# .으로 지정한다면 위에서 설정한 WORKDIR에 해당한다
COPY package.json .
# COPY . .

# 도커 이미지를 빌드할 때 실행하는 명령어
RUN npm install

# 컨테이너 밖에서도 컨테이너 구동 앱에 접근 가능하도록 포트 번호를 지정. 
EXPOSE 3000

# 도커 이미지 빌드가 아닌, 도커 컨테이너를 실행할 때의 명령어
CMD ["node", "app.mjs"]
```

```bash
# 현재 폴더에 Dockerfile이 있어야 가능
docker build .
```

```
# : 앞쪽은 내 localhost의 포트번호, : 뒤쪽은 컨테이너의 exposed된 포트번호
docker run -p 3000:3000 docker_container_own_id
```

```
# 현재 실행되고 있는 docker container의 상태, ID 등을 확인
docker ps
```

```
# 실행 중인 도커 컨테이너를 중지하려면 docker stop 명령어를 실행
docker stop docker_name
```
