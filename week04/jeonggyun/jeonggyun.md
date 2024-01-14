# 도커 네트워크 한눈에 보기

---

<p float="center">
  <img src="images/image_1.png?raw=true" width="50%" />
</p>

- `eth0`
    - 호스트의 네트워크 인터페이스
- `docker0`
    - 도커의 네트워크 브리지(도커가 설치될 때, 기본적으로 구성됨)
    - 호스트의 eth0과 컨테이너의 veth와 연결해 주는 역할을 해줌
    - 묶여있는 서로 다른 컨테이너들 끼리 연결해 주는 역할을 해줌
- `veth`
    - 컨테이너의 가상 인터페이스(virtual ethernet)
    - 컨테이너의 내부 IP를 외부와 연결해 주는 역할

### 컨테이너 ↔ 호스트머신

<p float="center">
  <img src="images/image_2.png?raw=true" width="50%" />
</p>

- 컨테이너는 docker0이라는 네트워크를 통해 호스트 머신과 통신이 가능하다.
- 컨테이너 내부에서 호스트 주소는 `localhost`가 아니라, `host.docker.internal`으로 변환해주면 됨

### 컨테이너 ↔ 컨테이너

- 컨테이너의 IPAddress로 접근을 하면, 해당 컨테이너와 통신을 할 수 있다. `docker container inspect`를 통해 특정 컨테이너의 ip주소를 알 수 있다. 그 ip주소는 속해 있는 브리지 네트워크와 동일한 대역대임
- ip주소를 귀찮게 찾을 필요 없이, ip주소에 `<컨테이너의 이름>`을 대체할 수 있음

<p float="center">
  <img src="images/image_3.png?raw=true" width="50%" />
</p>

- 동일한 네트워크 환경에 있는 컨테이너라면 서로 통신이 가능하다.

<p float="center">
  <img src="images/image_4.png?raw=true" width="50%" />
</p>

- 서로 다른 네트워크 환경에 있는 컨테이너끼리는 통신이 불가능

<p float="center">
  <img src="images/image_5.png?raw=true" width="50%" />
</p>

- 같은 네트워크 환경으로 가져오면 통신이 다시 가능

### 컨테이너 ↔ WWW(World WideWeb)

- 기본적으로 컨테이너는 WWW와 통신이 가능하다.
- 이것이 가능한 이유는, 컨테이너의 `veth`가 `docker0`이라는 네트워크를 통해 호스트머신의 네트워크 인프라를 사용할 수 있기 때문

<p float="center">
  <img src="images/image_6.png?raw=true" width="50%" />
</p>

### 네트워크 생성 방법

```python
docker network create new_bridge
```

<p float="center">
  <img src="images/image_7.png?raw=true" width="50%" />
</p>

컨테이너 실행 시, 특정 network에 연결시킬 수 있음

```python
docker run --network new_bridge
```

### 새롭게 알게된것(또는 주의해야할 점)

---

- **프론트단의 컨테이너는, api요청이 컨테이너 내부가 아니라, 사용자의 브라우저 환경에서 요청이 된다.**
    - 때문에, 요청 api 주소가 컨테이너주소라면, 브라우저 환경에선 이를 이해하지 못하고 에러를 발생 시킨다.
- **바인드마운트를 했다고 해서, 항상 서버가 최신 코드를 반영하고 있을까?! → 아니다**
    - 로컬 호스트와 바인드마운트를 했더라도, 특정 애플리케이션이 매번 최신의 코드를 반영하지는 않을 수 있다.
    - fastapi로 치면, 서버 실행 시 `--reload` 파라미터를 추가해 주어야만 변경된 코드를 반영할 수 있다.
- **MongoDB 데이터를 영구적으로 저장하기**
    - 데이터베이스의 데이터를 영구적으로 저장하기 위해서는, 해당 데이터베이스가 컨테이너 내의 어떤 위치에 데이터를 저장하는지 알아야 한다.
    - 보통 데이터베이스 이미지의 docs를 보면 해당 위치가 나와 있다.
    - mongodb같은 경우는 /data/db
    - 이를 도커의 명명된 볼륨에 마운트 하거나, 호스터 머신의 폴더로 바인드 마운트 해도 된다.
- **MongoDB 보안**
    - docs에 보면, 환경변수로 이름과 패스워드를 설정할 수 있는 부분이 있다.
    - 이를 설정한 후, 백엔드에서 요청할 때, 요청문 앞에 이를 심어주면 된다.(간단하다.)

### 회상(복습!)

---

- **바인드 마운트를 할 때,**
    - 호스트 머신의 특정 폴더가, 컨테이너 내의 특정 폴더를 덮어쓰지 않게 하기 위해, 명명된 볼륨이나 익명된 볼륨으로 마운트를 시켜놓다. 이때, 바인드 마운트를 하는 컨테이너의 경로보다 더 구체적인(더 깊은 경로)로 마운트를 해주어야, 덮어씌여지지 않는다.
- **하드코딩을 피해**
    - DB와 연결하기 위한 ID, PW,, 네트워크 연결을 위한 PORT,,
    - 이러한 요소는 상시적으로 변경될 수 있어야 한다.
    - 이를 변경하기 위해 매번 이미지를 빌드하고 컨테이너를 실행시키는건 초보다!
    - docker file의 ENV로 환경변수 파라미터를 넣어놓자.
        
        ```python
        ENV MONGODB_USERNAME=hi
        ENV MONGODB_PASSWORD=secret
        ```
        
    - 이때 이 환경변수는, 당연히 해당 컨테이너 내에서만 적용되는 환경변수다.
- **컨테이너에 들어갈 필요없는(들어가서는 안되는) 폴더 및 파일은 dockerignore 파일로 걸러내자.**
    - node_modul과 같은 폴더 들은, npm install 명령어로 새롭게 생성되는 폴더다.
    - 이미 기존에 있는 node_module 폴더가 `DOCKER COPY`명령어로 인해, `npm install` 명령어로 새롭게 생성된 폴더를 대체하지 않도록 해야한다. (항상 최신의 node_module 폴더를 얻기 위해)
    - 또한,  node_module은 굉장히 무겁기 때문에, 굳이 필요없는 복사로 이미지 빌드가 오래걸린다.