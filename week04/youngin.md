# 네트워킹: (교차)컨테이너 통신 (강의 내용 + 도커 공식 문서 내용 추가.)

## 컨테이너 <-> WWW

- 컨테이너는 특별한 설정이나 코드 변경 없이 인터넷에 접속할 수 있음.
  - 기본적으로 outgoing 네트워크 연결을 지원함. (incoming은 아님.)
- HOW?
  - https://docs.docker.com/network/drivers/
    - 네트워크 드라이버를 플러그인 형태로 설치하여 사용함.
    - 기본값으로 사용하는 드라이버는 `bridge`.
      - 단 이는 도커의 레거시 중 하나로, 프로덕션 레벨에서는 권장하지 않는다고 함. (https://docs.docker.com/network/drivers/bridge/#use-the-default-bridge-network)

## 컨테이너 <-> 로컬 호스트 머신

- 컨테이너에서 단순히 `localhost` 로는 접근할 수 없음.
- 도커가 알아들을 수 있는 DNS명을 사용해야 함: `host.docker.internal`
  - 참고) gateway의 DNS명: `gateway.docker.internal` (https://docs.docker.com/desktop/networking/#i-want-to-connect-from-a-container-to-a-service-on-the-host)
  - 참고) 도커에 DNS 설정 추가하고 싶으면 `~/.docker/daemon.json` 에 dns 필드를 추가한다. (https://dockerlabs.collabnix.com/intermediate/networking/Configuring_DNS.html)
    ```json
    { "dns": ["114.114.114.114", "8.8.8.8"] }
    ```

## 컨테이너 <-> 컨테이너

### 컨테이너의 IP 주소로 바로 접근

- container inspection 통해서 컨테이너의 IP 주소를 알아낼 수 있음. 이 IP 주소로 다른 컨테이너에 접근 가능.

### 사용자 정의 bridge 네트워크로 접근

- 도커에서 기본으로 제공하는 bridge 네트워크는 레거시의 일종임.
- 사용자 정의 bridge 네트워크를 사용하면
  - 컨테이너 간 DNS resolution 수행
    - DNS명은 컨테이너명과 동일함.
  - 원하는대로 네트워크 격리
  - 실행 중인 컨테이너를 재실행하지 않고도 네트워크에 연결 혹은 연결을 끊을 수 있음
  - (https://docs.docker.com/network/drivers/bridge/#differences-between-user-defined-bridges-and-the-default-bridge)
- 사용자 정의 bridge 네트워크를 사용하려면
  - 먼저 `docker network create <네트워크명>` 로 네트워크를 생성하고 (다른 설정값은 필요 없음)
    - 이 때 생성되는 네트워크는 도커 내부 네트워크임.
    - `docker network ls` 로 도커 네트워크 목록 확인 가능.
  - 컨테이너 실행 시 옵션을 준다: `docker run --network <네트워크명>`

---

# 도커로 다중 컨테이너 애플리케이션 구축하기

4주차 이론 실습.

## 목표: 컨테이너 3개 띄워서 서로 통신하게 만들기

### 요구사항

- FE 서버(React 앱), BE 서버(node.js 앱), DB 서버(MongoDB) 컨테이너 총 3개를 띄운다.
- DB는 컨테이너가 종료 후 재실행되더라도 데이터를 잃으면 안된다.
- FE <-> BE <-> DB 는 서로 통신할 수 있어야 한다.
- FE 코드를 수정하면 이미지를 다시 빌드하지 않아도 바로 반영되어야 한다.

### 컨테이너끼리 통신하기 위해

- 처음 썼던 방법: 모든 컨테이너를 호스트 머신 포트에 연결
  - --> 다른 컨테이너에 접근하기 위해 `host.docker.internal:<포트번호>` 사용
- 좀 더 나은 방법: 사용자 정의 bridge 네트워크 사용
  - --> 다른 컨테이너에 접근하기 위해 `<컨테이너명>` 사용

#### ⚠️ 도커가 아닌 브라우저에서 HTTP 요청을 보낼 때

- 요청을 보내는 컨테이너가 destination 과 동일한 네트워크에 있어도 `<컨테이너명>`으로 접근할 수 없음.
- 도커가 아닌 브라우저가 요청을 보내기 때문에 `<컨테이너명>`을 해석할 수 없기 때문.
- 따라서 FE 서버와 BE 서버 간 통신을 위해 다시 첫번째 방법으로 돌아갔음.
  - BE 서버는 호스트 머신의 포트에 연결하고
  - FE 코드에서는 `localhost`로 호스트 머신에 접근

### DB 데이터를 잃지 않고 안전하게 관리하기 위해

- Named volume 사용: MongoDB에서 데이터를 저장하는 파일을 마운트
- 보안 레이어 추가: MongoDB 컨테이너 이미지에서 제공하는 환경 변수 값 설정

### FE 코드를 실시간으로 반영하기 위해

- 바인드 마운트 사용
  - 이 방식은 개발환경에서 사용하기 편함!

## 이번 주차의 개선점 2가지

- 각 서버를 띄우기 위해 `docker run`으로 시작하는 긴 명령어를 기억하고 입력해야 함.
- 프로덕션용이 아님.
