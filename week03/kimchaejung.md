# 새롭게 알게된 점

## Docker에서의 데이터 유형

| 애플리케이션<br>(코드 + 환경)            | 임시 앱 데이터<br>(ex. user input 입력값) | 영구 앱 데이터<br>(ex. user 계정)             |
| ---------------------------------------- | ----------------------------------------- | --------------------------------------------- |
| 개발자가 제공                            | 실행 컨테이너에서 데이터 가져와 생성      | 실행 컨테이너에서 데이터 가져와 생성          |
| 빌드 단계에서 이미지와 컨테이너에 추가됨 | 메모리 또는 임시 파일에 저장됨            | 파일 또는 데이터베이스에 저장됨               |
| 이미지 빌드 이후 수정 불가               | 동적이고 수정 가능하지만 정기적으로 삭제  | 컨테이너 중지, 재시작 후여도 삭제되면 안됨    |
| 읽기 전용<br>→ 이미지에 저장             | 읽고 쓰기(임시적)<br>→ 컨테이너에 저장    | 읽고 쓰기(영구적)<br>→ 컨테이너와 볼륨에 저장 |

- 컨테이너 레이어는 이미지를 인식하고, 이미지의 파일 시스템을 인식하며, 복사하지 않고 파일 시스템을 미러링하는 로직을 가진다
- 도커는 컨테이너의 변경 사항을 추적하고, 이미지의 파일 시스템을 가져와 최종 파일 시스템을 파생시켜 read-write 레이어에 저장된 변경 사항과 결합시킨다.

## 볼륨(Volume)

- 볼륨은 도커가 인식하는 호스트 머신인 컴퓨터에 있는 폴더
- 도커 컨테이너 내부의 폴더와 컨테이너 외부의 특정 폴더가 매핑된다

> 👩‍💻 COPY와 VOLUME의 차이점<br>
> COPY: 실제로 복사하도록 명령한 경로와 파일의 스냅샷을 취한 다음 이 파일과 폴더를 이미지에 복사하는 게 전부<br>
> VOLUME: 컨테이너 내부 폴더를 호스트 머신 상의 컨테이너 외부 폴더에 연결

- 볼륨은 컨테이너가 중지/제거되어도 남아있다
- 컨테이너는 볼륨에 데이터를 읽고 쓸 수 있다

### 볼륨의 두 가지 유형

- 익명 볼륨
  - 컨테이너가 작동할 때만 존재
  - 컨테이너 간 데이터 공유 불가
  - Dockerfile에서 생성 가능
  ```bash
  docker run -v /app/data
  ```
  - 사용하지 않는 볼륨 삭제
  ```bash
  docker volume rm VOLUME_NAME
  docker volume prune
  ```
- 명명 볼륨
  - 컨테이너가 종료돼도 유지
  - 편집하거나 직접 볼 필요 없는 중요한 데이터에 적합
  - 다수의 다양한 컨테이너에 동일하게 명명된 볼륨 하나 마운트 가능
  - Dockerfile에서 생성 불가능
  ```bash
  docker run -v data:/app/data
  // ex)
  docker run -d -p 3000:80 --rm --name feedback-app -v feedback:/app/feedback feedback-node:volumes
  ```
  ```bash
  docker volume create VOLUME_NAME
  ```
- 도커가 호스트 머신의 폴더/경로를 설정하는데 사용자는 그 정확한 위치를 모르기 때문에 docker volume으로 관리한다
  ```bash
  docker volume inspect VOLUME_NAME
  [
      {
          "CreatedAt": "2023-12-30T08:02:46Z",
          "Driver": "local",
          "Labels": null,
          // 가상 머신 내부에 있는 경로, 호스트 머신에서 찾을 수 있는 경로가 아님
          "Mountpoint": "/var/lib/docker/volumes/feedback/_data",
          "Name": "feedback",
          // 읽기 전용임을 알 수 있는 옵션
          "Options": null,
          "Scope": "local"
      }
  ]
  ```

## 바인드 마운트(Bind Mount)

- 도커에 의해 관리되는 볼륨이 호스트 머신에 어디있는지 알 수 없다
- 컨테이너 중지, 제거 이후에도 유지
- 컨테이너에 리빌드할 필요없이 ‘라이브 데이터’를 제공하려고 하는 것이 일반적인 사용 사례
- 바인드 마운트 데이터를 삭제하려면 직접 삭제하는 수 밖에 없다, 도커 명령으로는 삭제 불가능
- 사용자는 바인드 마운트를 통해 호스트 머신의 폴더/경로를 지정할 수 있다
  - 그래서 바인드 마운트로 공유 중인 폴더에 도커가 액세스할 수 있는지 docker desktop setting으로 확인해야 한다
- 영구적이고 편집 가능한 데이터를 저장하기에 적합

```bash
docker run -v /path/to/code:/app/code
// ex)
docker run -d -p 3000:80 --rm --name feedback-app -v feedback:/app/feedback -v "/Users/chaejungkim/Desktop/23-12-doku/section03/data-volumes-01-starting-setup:/app" feedback-node:volumes
```

> 항상 전체 경로를 복사하여 사용하고 싶지 않은 경우, 다음 바로 가기를 사용 가능<br>
> macOS / Linux: `-v $(pwd):/app`<br>
> Windows: `-v "%cd%":/app``

## 바인드 마운트 vs Dockerfile `COPY`

> 👩‍💻 바인드 마운트를 사용해서 코드 전체의 변경 사항을 컨테이너에 반영하도록 하고 있는데 COPY를 쓰는 이유?

- 개발 환경에서는 COPY를 쓰지 않아도 정상적으로 컨테이너가 실행된다
- 프로덕션 환경에서는 바인드 마운트가 아니라 스냅샷 컨테이너를 배포하는 것이 필요하기 때문에 COPY를 써야 한다

## `.dockerignore`

- 로컬 호스트 머신에 있는 빌드 후 종속성 관련 파일(ex. `node_modules`)은 이미지 내부에 생성된 동일 폴더를 덮어쓸 것이기 때문에 `.dockerignore`로 해당 폴더가 복사되지 않도록 할 수 있다
  - 로컬의 종속성 파일이 오래되었을수도 있고, 이미지 내부에 추가한 중요한 종속성이 누락될 수도 있기 때문

> 👩‍💻 그러면 어떻게 보면 로컬의 스냅샷을 유지하지 않는 것 아닌가?<br>
> 종속성 warning으로 발생한 디버깅을 해결하기 어려울 듯
> dockerignore를 써야 하는 명확한 이유가 궁금하다

> 자문자답<br> `node_modules`의 경우 파일 크기가 상당히 크기때문에 이미지 push/pull할 때 시간을 줄이기 위해 `.dockerignore`에 추가한다고 한다.<br>

- NodeJS example
  ```
  // .dockerignore
  **/node_modules/
  **/dist
  .git
  npm-debug.log
  .coverage
  .coverage.*
  .env
  .aws
  ```

[참고: How to use .dockerignore and its importance](https://shisho.dev/blog/posts/how-to-use-dockerignore/)

## 유연한 이미지와 컨테이너를 만드는 방법

- 서로 다른 모드, 다른 구성에서 하나의 동일한 이미지를 기반으로 하나의 동일한 컨테이너를 실행하는데 도움이 된다
- 도커는 빌드 타임 ARGument와 런타임 ENVironment 변수를 지원한다

  - ARG

    - Dockerfile 내부에서 다른 값을 추출하는데 사용할 수 있는 변수
    - CMD 명령, 애플리케이션 코드에서는 접근할 수 없다

    ```bash
    docker build -—build-arg
    // ex)
    docker build -f feedback-node:dev --build-arg DEFAULT_PORT=8000 .
    ```

  - ENV

    - Dockerfile 내부에서 사용 가능, 전체 애플리케이션 코드에서 사용 가능
    - `--env` 대신 `-e`도 가능

    ```bash
    docker run -d -p 3000:8000 --env PORT=8000 --rm --name feedback-app -v feedback:/app/feedback -v "/Users/chaejungkim/Desktop/23-12-doku/section03/data-volumes-01-starting-setup:/app:ro" -v /app/temp -v /app/node_modules feedback-node:env
    ```

- .env 파일이 있는 경우
  ```bash
  docker run -d -p 3000:8000 --env-file ./.env --rm --name feedback-app -v feedback:/app/feedback -v "/Users/chaejungkim/Desktop/23-12-doku/section03/data-volumes-01-starting-setup:/app:ro" -v /app/temp -v /app/node_modules feedback-node:env
  ```
  > ✋ 자격 증명, 개인 키와 같은 값들은 이미지에 포함되지 않도록 해야한다<br>
  > 이럴 땐 별도의 파일로 관리하며, 소스 컨트롤 저장소 일부분으로 커밋하지 않도록 주의해야한다

# 함께 이야기하고 싶은 점

> .gitignore, .dockerignore로 소스 컨트롤에 반영되지 않는 파일들을 어떻게 관리하시나요?<br>
> 프로젝트, 현업 때도 .env를 Notion에서 관리했었는데, 이게 과연 올바른 방법인지 의문이 생기더라구요.<br>
> 다른 분들께선 환경 변수 데이터를 어떻게 관리하는지 궁금합니다!
