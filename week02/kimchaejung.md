# 새롭게 알게된 점

## Docker에서의 컨테이너와 이미지

> 🐳 Docker<br>
> 애플리케이션을 포함하는 격리된 환경과 그 앱을 실행하는데 필요한 모든 것(환경, 도구)을 격리된 컨테이너 내부에 모두 포함하는 것<br>

> 🗂️ 이미지<br>

    - 템플릿(코드와 애플리케이션), 컨테이너의 블루프린트<br>
    - 모든 설정 명령과 코드, 코드를 실행하는데 필요한 도구를 포함하는 공유 가능한 패키지<br>
    - 여러 컨테이너를 생성 가능<br>

> 📦 컨테이너<br>

    - 코드(unit of software)를 실행하는 역할<br>
    - 이미지의 구체적인 실행 인스턴스
    - 실행 애플리케이션<br>

- Docker는 궁극적으로 컨테이너를 위한 것이다.

## 이미지의 사용 및 실행

> 👩‍💻 Node에 의해 노출된 인터렉티브 쉘은 컨테이너에 의해 자동으로 우리에게 노출되지 않는다는 게 무슨 의미지?<br>

> -> Node를 담은 컨테이너를 올렸음에도 Node를 바로 실행시킬 수 없다는 것을 의미

- 컨테이너 내부에서 호스팅 머신으로 대화형 세션을 노출하고 싶을 때

  ```bash
  docker run -it IMAGE_NAME
  # ex) docker run -it node
  ```

## Dockerfile을 사용하여 자체 이미지 빌드

```dockerfile
# 시스템에 존재하거나 docker hub에 있는 이미지
FROM node

# 다음 실행 명령이 해당 경로에서 실행된다
WORKDIR /app

# 두가지 경로:
  # 1. 컨테이너의 외부, 이미지의 외부 경로 이미지로 복사되어야 할 파일들이 있는 곳
    # Host file system
    # (컨테이너 또한 이미지는 환경과 코드를 갖고 있으며, 거기에서 실행된다)
# 2. 파일을 저장해야하는 이미지 내부의 경로
    # Image/container file system
    # (모든 이미지, 이미지 기반으로 생성된 컨테이너는 로컬 머신의 파일 시스템에서 완전히 분리된 자체 내부 파일 시스템이 있다)
# 절대 경로
COPY . /app
# 상대 경로
COPY . ./

RUN npm install

# (선택) 로컬 시스템에 특정 포트를 노출하는 동작을 문서화하는 역할
EXPOSE 80

# 이미지 기반으로 컨테이너가 실행될 때 실행
CMD ["node", "server.js"]

```

## ⭐️ 이미지는 레이어 기반 아키텍쳐

![이미지 첨부](https://phoenixnap.com/kb/wp-content/uploads/2021/04/container-layers.png)
(출처: [Docker Image vs Container: The Major Differences - phoenixNAP](https://phoenixnap.com/kb/docker-image-vs-container))

- 이미지는 읽기 전용이고, 업데이트된 코드를 컨테이너에 반영하기 위해서는 이미지 다시 빌드
  <br>(나중에 코드에서 변경 사항을 선택하는 우아하고 빠른 방법을 배우게 될 것)\*
- 이미지는 읽기/쓰기 권한이 있는 인스턴스를 실행하는 컨테이너의 블루프린트
- 컨테이너는 이미지 위에 추가된 레이어일 뿐이기에 컨테이너가 새롭게 코드와 환경을 새로운 파일로 복사하는 것이 아니라 이미지에 저장된 환경을 사용하는 것이다.
- 이미지와 컨테이너가 독립적인 개념으로 있는 이유는 동일한 이미지를 기반으로 하지마나 서로 완전히 격리되어 있다는 사실에 기인한다.
- 이미지의 모든 명령은 캐시 가능한 레이어를 생성하고, 이 레이어는 이미지 재구축 및 공유를 돕는다.<br>(변경 사항이 업으면 레이어를 재실행하지 않는다)
- 이러한 레이어 개념은 빌드 속도를 최적화하기 위해 존재한다.

> 👩‍💻 \* github CI/CD로 자동화하는 게 아닐까?!

## 주요 실행 command

```bash
# Dockerfile 기반 새로운 커스텀 이미지 빌드
docker build .
```

```bash
# 컨테이너 생성 및 실행
docker run IMAGE_NAME
docker run IMAGE_ID
# ex) docker run 9f3bd09c3ac3af2f57fb013a521a163be56c897770dcf

# 포트 연결
# A: 애플리케이션에 액세스하려는 로컬 포트
# B: 내부 컨테이너 노출 포트
docker run -p A:B IMAGE_ID
# ex) docker run -p 3000:80 9f3bd09c3ac3af2f57fb013a521a163be56c897770dcf

# container가 중지되면 자동으로 제거되도록 설정
docker run -d --rm IMAGE_ID
# ex) docker run -p 3000:80 -d --rm ba58d99529397ab61435fd33d9d36816a36652cd2971bce54a16b25b60b6bd47
```

```bash
# 컨테이너가 백업되어 실행
docker start CONTAINER_NAME
```

```bash
# 인터렉티브 모드로 컨테이너 실행
docker run -it IMAGE_ID
docker start -ai CONTAINER_NAME
```

```bash
# 이미지 정보 확인(컨테이너 설정, 환경 변수, entry point, layer 등)
docker image inspect IMAGE_ID
```

```bash
# 현재 실행 중인 프로세스 확인
docker ps
# 생성된 모든 컨테이너, 모든 프로세스를 표시
docker ps -a
```

```bash
# 컨테이너 종료
docker stop CONTAINER_NAME
# ex) docker stop sad_jepsen
```

```bash
# 컨테이너 삭제
docker rm CONTAINER_NAME
# ex) docker rm musing_chatterjee epic_perlman sad_jepsen amazing_joliot compassionate_clarke pensive_carver friendly_cannon

# 이미지 삭제
docker rmi IMAGE_ID
# ex) docker rmi ddd21fc18ed3
# 사용하지 않는 이미지 삭제
docker image prune
```

> 💡 이미지, 컨테이너의 고유 식별자<br>
> ID를 사용하는 docker 명령일 경우 항상 전체 ID로 실행할 필요는 없다<br>
> 첫 번째 몇 개 문자가 고유 식별자로 존재한다면 그 몇 개만 사용해도 된다.

> ⛔️ 이미지 제거 시 유의사항<br>
> 중지된 컨테이너에 포함된 이미지만 제거 가능<br>
> 따라서 이미지 전에 컨테이너를 먼저 제거 필수

## Attached-Detached mode

- attached: 실행되고 있는 컨테이너의 출력 로그를 수신한다.
- detached: 컨테이너가 실행되고 있지만 로그를 수신하지 않는다.

```bash
# default: attached
docker run image-id
# detached mode
docker run -d image-id
---
# default: detached
docker start NAME
# attached mode
docker attach NAME
docker logs NAME
```

## 로컬 호스트 - 컨테이너 간 파일 복사

- 사용 사례
  - 컨테이너에 붙여넣기할 때: 웹 서버의 구성 파일을 변경하려할 때
  - 컨테이너로부터 복사할 때: 로그 파일 추출

```bash
// local host -> container
docker cp LOCAL_HOST_DIRECTORY CONTAINER_NAME:CONTAINER_DIRECTORY
docker cp dummy/. hopeful_wright:/tes

// container -> local host
docker cp CONTAINER_NAME:CONTAINER_DIRECTORY LOCAL_HOST_DIRECTORY
docker cp hopeful_wright:/test dummy
```

## 이미지의 고유 식별자

- name: 일반적인 이름. 더 특정회된 이미지 그룹 정의
- tag: 동일한 이미지 그룹 내의 이미지 버전 관리 가능
- `IMAGE_ID` -> `NAME:TAG`로 대체 가능
- 커스텀 이름 설정 방법 두 가지
  ```bash
  docker run --name CUSTOM_NAME
  ```
  ```bash
  docker build -t NAME:TAG .
  docker build -t goals:latest .
  ```

## Docker 이미지를 공유하는 방법

- Dockerfile을 공유한다
  - 소스 코드 별도 필요
- Built 이미지를 공유한다

  - 이미지를 다운받으면 바로 컨테이너 실행 가능

  1. Docker Hub

  - 공식 Docker 이미지 레지스트리
  - 공개 / 비공개 / 공식 이미지

  2. Private Registry

  - 공급자 선택에 따라 팀 단위 이미지 공개 가능

### Docker Hub로 이미지 push-pull하는 법

1. Docker Hub에서 repository 생성

2. 로컬 이미지 이름 설정

   2-1. 위 단계에서 생성한 repository 이름으로 이미지를 다시 빌드

   2-2. 이미 생성된 이미지의 이름을 변경

   ```bash
   docker tag AS_IS_NAME TO_BE_NAME
   ```

   - 이전 이미지는 삭제되지 않고 이전 이미지의 복제본을 생성하는 것이다.

3. 이미지 push

   ```bash
   docker push REPOSITORY_NAME
   ```

4. 이미지 pull
   ```bash
   docker push REPOSITORY_NAME
   ```
   - docker pull 을 실행하면 항상 컨테이너 레지스트리에서 그 이름의 최신 이미지를 가져온다
   ```bash
   docker run REPOSITORY_NAME
   ```
   - 로컬 컴퓨터에서 이미지를 찾지 못하면 이미지 이름이 사용한 컨테이너 히스토리에 자동으로 접근
   - 이미지가 로컬에 있는 경우 최신 버전이 로컬 시스템이 있는지 체크하지 않는다

> 👩‍💻 레지스트리와 레포지토리의 차이점?<br>

> - 레지스트리: Docker Hub, Google Container Registry, AWS Container Registry와 같이 Docker 이미지의 호스팅, 배포를 담당하는 서비스

> - 레포지토리: 동일한 이미지가 가진 다른 태그들의 모음

(출처: [Difference between Docker registry and repository - StackOverflow](https://stackoverflow.com/questions/34004076/difference-between-docker-registry-and-repository))

# 함께 이야기하고 싶은 점
