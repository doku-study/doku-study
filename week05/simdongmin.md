# 새롭게 



> Chapter 6. Docker Compose: 우아한 다중 컨테이너 오케스트레이션



## 0. 들어가며

- 도커 컴포즈 개념 
  - 다중 컨테이너 설정을 쉽게 관리 
  - 설정 프로세스를 자동화하는데 도움
  - 단 하나의 명령으로 각각의 모든 컨테이너와 
- 도커 컴포즈 사용 방법





## 1. Docker Compose?

개별 혹은 다수의 `docker build` 와 `docker run` 명령을 단 **하나의 구성파일**으로 명령 셋을 **오케스트레이션 **할 수 있도록 도와주는 도구.



**도커 컴포즈의 사용 이유 & 강점**

- 도커 이미지 빌드와 도커 컨테이너를 띄움에 있어서 사용하는 긴 명령어들을 사용하는데 있어 피로 감소 -> 편리성 측면
- 여러 명령어들 간의 순서와 배치를 기록&저장할 수 있어 외우지 않아도 됨. -> 안정성 측면:실수 확률이 줄어듦
- 명령어들을 직접 작성하고 실행하는 시간을 줄여줄 수 있음 -> 효율성 측면



**도커 컴포즈 특성**

- 도커 컴포즈는 Dockerfile을 대체하지 않고, 이미지나, 컨테이너를 대신하는 개념이 아님. -> 일종의 유틸리티 툴이라고 생각

- 하나의 호스트 머신: 여러개의 컨테이너 (1:N) 에는 유용하지만

- 여러개의 호스트 머신: 여러개의 컨테이너 (N:N) 에는 적합하지 않음







## 2. 도커 컴포즈 파일 

도커 컴포즈를 사용하기 위해서는 컴포즈 파일을 작성해야함. 

컴포즈 파일에는 멀티컨테이너 애플리케이션을 구성하는 핵심 구성 요소를 정의하면 됨. 



컴포즈 파일에서 정의해야하는 여러 항목중 핵심 항목은 **Service**임. 서비스는 "**컨테이너**" 개념에 대칭되는 항목임. 

따라서 앞서 컨테이너를 띄우기 위해 사용했던 여러가지 설정 명령들을 서비스 항목 내부에서 지정할 수 있음.

- 서비스 
  - 포트 지정
  - 환경 변수 
  - 볼륨 지정
  - 네트워크 지정 
  - 등등



**도커 컴포즈 사용하기**

도커 컴포즈 파일을 작성하기 위해서는 `.yaml` 파일을 생성해준다. 

❗️강의에서는  `docker-compose.yaml`으로 작성했지만,  `compose.yaml` 가 최신 버전인듯함. 하단 참고

>Compose 파일의 기본 경로는 `compose.yaml`(선호)이거나 `compose.yml`작업 디렉터리에 배치됩니다. 
>Compose는 이전 버전의 이전 버전 `docker-compose.yaml`과 `docker-compose.yml`의 호환성도 지원합니다. 두 파일이 모두 존재하는 경우 Compose는 표준 `compose.yaml`.



The Compose file은 [YAML](http://yaml.org/) file 로 다음과 같은 항목들로 구성되어 있음.

- [Version](https://docs.docker.com/compose/compose-file/04-version-and-name/) (Optional)
- [Services](https://docs.docker.com/compose/compose-file/05-services/) (Required)
- [Networks](https://docs.docker.com/compose/compose-file/06-networks/)
- [Volumes](https://docs.docker.com/compose/compose-file/07-volumes/)
- [Configs](https://docs.docker.com/compose/compose-file/08-configs/)
- [Secrets](https://docs.docker.com/compose/compose-file/09-secrets/)



## 3. 도커 파일 구성요소 

### Version 

- 버전은 사용자 앱이나 파일의 버전을 의미하는 것이 아님. 
- 사용하려는 도커 컴포즈 사양 버전을 지정하는 것. -> 버전마다 사용할 수 있는 기능이 다르기 때문에 버전 확인 필요.
  -  이전 버전과의 호환성을 위해
- 도커 내부에서 도커 컴포즈 파일의 유효성을 검사하기 위해.

```docker
version: "3.8"
```

### Services

> A service is an **abstract definition of a computing resource** within an application which can be scaled or replaced independently from other components. Services are backed by **a set of containers**, run by the platform according to **replication requirements** and **placement constraints**. As services are backed by containers, they are defined by a Docker image and set of runtime arguments. 

- 중첩된 값들을 추가하여 작성함. `yaml`  파일은 들여쓰기를 기준으로 구분하기 때문에 작성에 유의
- 여러 하위 요소를 가질 수 있는 최소 한개 이상의 하위 요소가 필요함 -> 요소가 바로 컨테이너를 의미. 

- 도커 컴포즈의 기본값으로 `--rm` 모드와 `-d` 모드(detached)를 사용함, 백그라운드로 동작하며, 컴포즈가 내려가면 서비스(컨테이너)도 삭제됨.

```yaml
version: "3.8"
services:
  mongodb:
    image: "mongo"
    container_name: "mongodb"
    volumes:
      - data:/data/db
    environment:
      - MONGO_INITDB_ROOT_USERNAME=admin
      - MONGO_INITDB_ROOT_PASSWORD=secret
    networks:
      - goals_net
      
  backend:
      build: ./backend
      container_name: "goals-backend"
      ports:
        - "80:80"
      volumes:
        - logs:/app/logs
        - ./backend:/app
        - /app/node_modules
      env_file:
        - ./env/backend.env
      depends_on:
        - mongodb

```





**서비스 하위 항목**

- 서비스 이름 : 서비스를 구분하기 위한 용도의 문자열

  - `image` 이미지 

    - 서비스(컨테이너)를 시작할 이미지를 지정

    -  `image` 반드시 Open Container Specification을 따라야함. [addressable image format](https://github.com/opencontainers/org/blob/master/docs/docs/introduction/digests.md), as `[<registry>/][<project>/]<image>[:<tag>|@<digest>]`.

      ```yml
          image: redis
          image: redis:5
          image: redis@sha256:0ed5d5928d4737458944eb604cc8509e245c3e19d02ad8393...
          image: library/redis
          image: docker.io/library/redis
          image: my_private.registry:5000/redis
      ```

  - `container_name` 컨테이너 이름

  - `volumes` 볼륨

    - 서비스(컨테이너)에 연결할 볼륨을 지정 

    - 익명 볼륨 지정방법

      - ```yaml
        services:
        	service_name:
        		...
        		volumes:
        			- /app/node_modules
        			- [container path]
        ```

    - 바인드 마운트 지정방법

      - ```
        services:
        	service_name:
        		...
        		volumes:
        			- ./backend:/app/node_modules
        			- [host path(reltive path)]:[container path]
        ```

    - 다음과 같이 지정도 가능하다. [Service-volume](https://docs.docker.com/compose/compose-file/05-services/#volumes)

      ```yml
      services:
        backend:
          image: example/backend
          volumes:
            - type: volume
              source: db-data
              target: /data
              volume:
                nocopy: true
            - type: bind
              source: /var/run/postgres/postgres.sock
              target: /var/run/postgres/postgres.sock
      
      volumes:
        db-data:
      ```

  - `environment` 환경 변수 

    - 서비스(컨테이너) 구동에 필요한 환경변수를 지정
    - 문법은 다음 2가지 모두 사용 가능하다.
    - `      - MONGO_INITDB_ROOT_USERNAME=admin` `      MONGO_INITDB_ROOT_USERNAME:admin`
    - `yml` 파일에서는 `:` 을 인식하여 첫번째 문법처럼 변경해 준다. 

  - `env_file` 환경 변수 파일

    - 환경 변수 대신에 변수들이 `key:value` 형식으로 되어있는 `env` 파일을 지정할 수 있다.
    - `compose` 경로는 상대경로를 사용한다.

  - `port` 포트 

    - 연결하고자 하는 포트지정

  - `network` 네트워크 

    - 도커 컴포즈를 사용하면 도커가 이컴포즈 파일에 특정된 모든 서비스에 대해 새 환경을 자동으로 생성, 즉시 네트워크에 추가 
    - 동일한 컴포즈 파일에 포함된 모든 서비스는 동일한 네트워크의 일부가 됨.
    - 따라서 굳이 지정하지 않아도 되지만, 특정 네트워크를 직접 지정하는 것도 가능함. 

  - `build` 빌드 

    - 빌드하고자 하는 Dockerfile의 경로를 입력하여 이미지를 빌드할 수 있음.

    - 이때 compose 파일을 기준으로 상대경로 가능

    - ```
      # short syntax
      build: ./backend
      ```

    - ```
      # long syntax
      build: 
      	context: ./backend
      	dockerfile: Dockerfile
      	args:
        	- name=value
      ```

  - `depends_on` 의존관계 
    - 서비스 간의 의존관계를 지정할 수 있다. 해당 서비스가 동작하기 위해 필요한 서비스가 있다면. 이 옵션을 사용해 서비스들 간의 실행 순서를 조율할 수 있다. 
  - `stdin_open` 인터렉티브
    - 개방형 입력 연결 옵션 `-i` 에 대응
  - `tty` 터미널
    - 터미널 옵션 `-t` 에 대응

### Volumes

- **명명된 볼륨**을 인식하기 위한 구문
- 서비스에서 Volumes에 명시한 명명 볼륨의 이름을 사용할 경우 해당 볼륨은 두 개의 서비스에서 공유할 수 있음.
- 익명 볼륨과 바인드 마운트는 지정할 필요 없음.

```yaml
version: "3.8"
services:
  mongodb:
    image: "mongo"
    container_name: "mongodb"
    volumes:
      - data:/data/db
    environment:
      - MONGO_INITDB_ROOT_USERNAME=admin
      - MONGO_INITDB_ROOT_PASSWORD=secret
    networks:
      - goals_net

volumes:
  data:
```



## 도커 컴포즈 Up, Down

컴포즈 파일을 이용하기 위해서는 `compose.yml` 파일 있는 경로에서 다음 명령어를 사용하여 실행할 수 있음.

```bash
docker-compose up
docker compose up
```

- `-d` 옵션으로 백그라운드 동작 가능함.
- `--build`  옵션으로 강제 이미지 재빌드가 가능함.



모든 서비스를 중지하고 모든 컨테이너 등을 제거하려면 다음 명령어를 사용하여 중지함.

```
docker-compose down
docker compose down
```

- 모든 컨테이너와 생성된 디폴트 네트워크크가 삭제됨.
- 그러나 볼륨은 삭제되지 않음. 볼륨을 삭제하려면 `-v` 옵션을 함께 사용.



---



> Chapter 7. "유틸리티 컨테이너"로 작업하기 & 컨테이너에서 명령 실행하기



## 0. 들어가며

- 유틸리티 컨테이너 (저자의 개인 표현)
  - 특정 환경만 포함하는 컨테이너




## 1. 유틸리티 컨테이너

왜 사용하는가? 

- 일종의 **가상 개발 환경을 구성**하는데 도커 컨테이너를(유틸리티 컨테이너) 활용 -> 프로젝트(언어, 프레임워크 등) 별 가상환경을 호스트에 직접 구축하지 않아도 됨.
- 제일 어렵고 까다로운 부분이 개발환경 구축 단계 이러한 단계를 컨테이너를 활용하여 보다 간단하고, 깔끔하게 구축할 수 있다는 것이 장점



구동중인 컨테이너에 직접적인 콘솔 명령어 

```bash
docker exec (-it) [container name] [command]
```

- `-it` 옵션으로 해당 프로세스에 입력을 제공할 수 있음



```bash
docker run -it [image name] [command]
```

- 뒤의 커맨드로 디폴트 명령을 오버라이드 할 수 있음.
- 인터렉티브 입력 모드가 아닌 command를 실행함.
- 대신 명령어가 종료되면 컨테이너도 같이 종료됨. 



1. 바인드 마운트를 활용하여 컨테이너에서 개발환경을 구축하고 
2. 구축된 세팅값을 호스트 머신에 미러링하여 활용



**도커파일을 활용하여** 

```dockerfile
FROM node:14-alpine

WORKDIR /app

ENTRYPOINT [ "npm" ]
```

- `ENTRYPOINT` 는 컨테이너를 띄우고 나서 실행해야될 명령어의 시작을 명시할 수 있음 
- `CMD`와의 차이는 CMD는 컨테이너를 띄울 이미지 이름 뒤에 오는 명령어로 덮어쓰여질 수 있음. 
- `docker run (options) image [ENTRYPOINT]` 
  - Ex) `docker run -it -v ./:/app node init`



**도커 컴포즈를 활용하여**

```yaml
version: '3.8'
services:
  npm:
    build: ./
    stdin_open: true
    tty: true
    volumes:
      - ./:/app
```

- `docker compose run [service] [command]` 로 도커파일을 사용했을때와 같이 `ENTRYPOINT` 이후 명령어를 추가할 수 있음.
  - Ex) `docker compose run --rm npm init`
- 런 명령어는 업 다운과 다르게 컨테이너를 제거하지 않음.
- --rm 옵션으로 실행 후 제거할 수 있음.


# 나누고
- 컴포즈는 어떻게 동작할까? 스크립트와 다를까 ?
- compose watch? https://github.com/dockersamples/avatars