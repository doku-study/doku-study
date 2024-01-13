# 4주차: 네트워킹: (교차)컨테이너 통신

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
