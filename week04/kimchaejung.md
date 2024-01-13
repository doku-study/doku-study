# 새롭게 알게된 점

## 컨테이너 간 통신 시나리오 세 가지

### 1. 컨테이너 → www 통신 요청

별도의 설정이 필요없다.

### 2. 컨테이너 → 호스트 머신에서 실행되는 다른 애플리케이션 요청

- Docker 컨테이너 내부에서 인식하는 URL로 변경한다.

  `host.docker.internal`

  ```javascript
    # as-is
    mongoose.connect(
      "mongodb://localhost:27017/swfavorites",
      { useNewUrlParser: true },
      (err) => {
        if (err) {
          console.log(err);
        } else {
          app.listen(3000);
        }
      }
    );

    # to-be
    mongoose.connect(
      "mongodb://host.docker.internal:27017/swfavorites",
      { useNewUrlParser: true },
      (err) => {
        if (err) {
          console.log(err);
        } else {
          app.listen(3000);
        }
      }
    );
  ```

### 3. 컨테이너 → 다른 컨테이너 요청

- `docker container inspect CONTAINER_NAME`으로 컨테이너의 IP 주소를 알 수 있다.
- < 네트워크 >

  컨테이너 간 통신을 허용하는 공간.

  Docker 네트워크에서는 모든 컨테이너가 서로 통신할 수 있으며 IP 조회 및 해결 작업을 자동으로 수행한다.

  #### 3-1. 네트워크 생성

  - Docker는 네트워크를 자동으로 만들지 않기 때문에 미리 생성한다

  - `docker network create NETWORK_NAME `

  #### 3-2. IP 주소를 연결하고 싶은 컨테이너 이름으로 변경한다.

  ```javascript
    # as-is
    mongoose.connect(
      "mongodb://172.17.0.2:27017/swfavorites",
      { useNewUrlParser: true },
      (err) => {
        if (err) {
          console.log(err);
        } else {
          app.listen(3000);
        }
      }
    );

    # to-be
    mongoose.connect(
      "mongodb://mongodb:27017/swfavorites",
      { useNewUrlParser: true },
      (err) => {
        if (err) {
          console.log(err);
        } else {
          app.listen(3000);
        }
      }
    );
  ```

  #### 3-3. 컨테이너 빌드 시 네트워크를 연결한다.

  `docker run --name CONTAINER_NAME --network NETWORK_NAME -d --rm IMAGE_NAME`

  > [Docker가 IP 주소를 다루는 방법]<br>
  > Docker는 소스 코드를 내부적으로 교체하지 않는다.<br>
  > Docker는 컨테이너의 이름을 보고 코드에 플러그인된 컨테이너의 IP 주소를 연결한다.<br>
  > 애플리케이션이 HTTP 요청이나 mongoDB 요청 또는 컨테이너에서 다른 종류의 요청을 보내는 경우 Docker가 이를 인식한다.<br>
  > 이 때, `host.docker.internal`, 주소, 컨테이너 이름을 실제 IP 주소로 변경한다.

### TMI: mongodb install

```bash
brew tap mongodb/brew
brew update
```

를 했더니 다음과 같은 오류가 떴다.

```bash
fatal: couldn't find remote ref refs/heads/master
Error: Fetching /opt/homebrew/Library/Taps/heroku/homebrew-brew failed!
Error: Some taps failed to update!
The following taps can not read their remote branches:
  heroku/brew
This is happening because the remote branch was renamed or deleted.
Reset taps to point to the correct remote branches by running `brew tap --repair`
```

그래서 하라는 대로 했더니 됐다!

```bash
brew tap --repair
brew install mongodb-community@7.0
brew services start mongodb-community@7.0
brew services list
```

# 함께 이야기하고 싶은 점

(작성 중입니다)
