# 데이터 관리 및 볼륨으로 작업하기

### 컨테이너에서 저장되는 데이터는?

---

컨테이너를 실행시키면, 이미지 레이어 위에 컨테이너 레이어가 구성되어 있는 구조를 가진다.

→ 컨테이너를 실행한다는 것이, 이미지 레이어에 컨테이너 레이어를 씌우는 구조라는것을 알게 되었다.

이때, 컨테이너에 저장되는 데이터는 컨테이너의 레이어에 저장이 된다. (컨테이너의 레이어는  read&write)

이 컨테이너 레이어는 이미지 레이어, 로컬 시스템과 독립적이다.

즉, 컨테이너에 저장된 데이터는 로컬에 저장되는것도, 이미지에 저장되는 것도 아닌, 컨테이너 레이어에 저장되는 것이다.

### 볼륨을 사용하는 이유

---

이때 컨테이너를 삭제하게 되면 컨테이너의 layer가 제거되며, 저장되어있던 데이터도 함께 사라진다.

(실제로 컨테이너를 삭제하는 일은 매우 빈번함!)

이러한 위험성을 방지하고자, 컨테이너에서 저장되는 데이터를 외부에 따로 저장하여 영속적으로 보관하기 위해 볼륨을 사용한다.

### 볼륨

---

볼륨 → 호스트 머신의 특정 폴더

컨테이너 내의 특정 폴더와 호스트 머신의 특정 폴더를 마운트 하는것

이로써 컨테이너 내의 특정 폴더에 저장되는 데이터 들은, 

컨테이너가 삭제 되어도 여전히 호스트 머신의 폴더에 남아 있기에, 영속적인 데이터 보관이 가능

- 익명 볼륨 - Dockerfile에서 volume 정의 하기(익명된 볼륨)
    
    ```python
    VOLUME ["/app/feedback"]
    # dockerfile에서 말고, docker run 시 익명 볼륨을 주고 싶으면 아래와 같이 파라미터를 주자
    -v /app/node_modules
    ```
    
    - 하지만, 컨테이너가 삭제되면, 이 익명 볼륨은 함께 사라진다.
- 명명된 볼륨
    
    ```python
    docker run -v feedback:/app/feedback <container>
    ```
    
    - 명명된 볼륨은 컨테이너가 삭제 되더라도, 데이터가 살아있다.
    - 컨테이너를 삭제하고, 다시 동일한 볼륨 feedback으로 연결하면, 데이터들을 여전히 조회할 수 있다.
    - Docker가 관리하는 volume들 확인
        
        ```python
        docker volume ls # 도커가 관리하고 있는 볼륨들의 리스트
        ```
        
- 바인드 마운트
    - 개발 도중 도커를 사용한다면, 잦은 코드 변경과 파일 변경에 의해 이미지와 컨테이너를 다시 시작해야하는 경우가 있다.
    - 이때 바인드 마운트를 활용할 수 있다.
    - 볼륨과 비슷하지만, 호스트의 특정 폴더를 마운트 하는것이다(원하는 폴더)
    - 그럼으로써, 호스트의 특정 폴더 내의 코드와 파일을 변경하게 되면, 이는 컨테이너에도 그대로 반영된다.
    
    ```python
    docker run -v <호스트 머신의 위치>:<컨테이너 내의 위치> <container>
    # 만약 경로에 특수문자나 띄어쓰기가 있는 경우, "<>:<>" 처럼 따옴표로 묶자
    ```
    
    - 이때, `컨테이너 내의 위치에 있는 파일과 폴더들`이 `호스트 머신의 위치에 있는 파일과 폴더`들을 덮어쓰지 않는다.(만약 그렇게 된다명 엉망이 될 것)
    - 대신 반대로, 호스트가 컨테이너를 덮어쓰게 된다.
    

### 읽기 전용 볼륨?

---

기본적으로 볼륨마운트를 할 때, 볼륨의 상태는 read-write이다.

컨테이너가 폴더 내의 파일을 읽을 수도 있고, 쓸 수도 있다.

하지만, 컨테이너가 호스트의 파일을 건드리거나 수정하지 않도록 해야하는 상황이 있을 것이다.

이럴 때는 읽기 전용으로 볼륨을 마운트 해야한다.

```python
docker run <호스트 주소>:<컨테이너 내의 주소>:ro
# 여기서 ro는 read-only 라는 듯이다.
```

여기서 만약, 특정 폴더에 쓰기 기능이 있는 컨테이너 같은 경우는 

익명이나 명명 볼륨을 통해 더 깊은 주소(sub volume)를 마운트 하면,

이는 바인드 마운트 된 폴더 말고, 기존의 이미지에 있던 폴더를 마운트하게 되기 때문에

read-only의 제한을 받지 않게 될 수 있다. 

### docker volume 관리

---

- `docker volume ls`
    - docker가 관리하고 있는 volume 들을 확인 할 수 있다.
    - 다만, 바인드마운트 같은 경우는 도커가 관리하는 게 아니라, 호스트 머신의 특정 폴더와 마운트 된거기에 따로 리스트에 나오지 않는다.
- `docker volume create`
    - docker 볼륨을 직접 생성할 수 있다.
- `docker volume rm or prune`
    - volume을 삭제할 수 잇다.
    - 사용중인 볼륨을 제거할 순 없다.
- `docker volume inspect`
    - 특정 볼륨의 자세한 내용을 검사할 수 있다.
    - 검사 내용 중 mountpoint는, 해당 볼륨이 호스트 내의 어떤 폴더에 위치해 있는지 파악할 수 있다.

### COPY vs Volume

---

Q. 볼륨마운트 하면 되지, 왜 도커 파일에서 굳이 COPY를 할까?

- 개발 단계와 배포 단계로 볼 수 있다.
    - 개발 단계에서는 각종 코드 수정과 파일 수정이 있을 수 있다. 이럴 때는 볼륨을 통해 컨테이너의 폴더 상태와 호스트의 폴더 상태을 마운트하면 편리하다.
    - 하지만 배포 단계에는 마운트를 하지 않는다. 모든 준비를 마치고 모든 준비물을 함께 들고 가야한다. 이럴 때는 도커파일의 copy를 통해 필요한 준비물들을 모두 이미지 안에 갖추도록 해줘야 한다.

### docker ignore 파일

---

`.dockerignore` 파일을 통해, COPY 명령 시 복사 되지 않아야 할 파일, 폴더를 지정할 수 있다.

(깃의 .gitignore와 동일)

### 환경 변수

---

- 컨테이너 실행 시 ENV를 줄 수 있음
    - 이미지를 빌드 하거나, 컨테이너를 실행 할 때, 동적으로 특정 환경변수를 지정할 수 있음
    - 예를 들어, 이미지 내에 특정 포트를 사용하는 코드를 하드 코딩 하는 일이 있을 때, 이 포트를 동적으로도 제공할 수 있다.
    
    ```python
    ENV PORT 80 
    # PORT를 인자로 받을 것이며, 디폴트로 80을 두겠다.
    # 그러면, 이 컨테이너 내의 애플리케이션에 PORT를 환경 변수로 사용할 수 있게 된다. 
    EXPOSE $PORT
    # 이렇게 도커 파일에서 사용할 수 도 있다.
    # $ 달러 표시로 환경 변수임을 알려줘야 한다.
    ```
    
    ```python
    docker run --env PORT=8000 --env PORT1=8001 --env PORT2=8002
    docker run --e PORT=8000
    # 이렇게 컨테이너 실행 시 환경변수를 넘겨줄 수 있다.
    # 키=값 쌍으로 여러개 줄 수 있다.
    docker run --env-file .env
    # --env-file 인자로 ./.env 파일을 넘겨줄 수도 있다.
    # 긴밀한 환경 변수 같은 경우는 절대 이미지에 포함되면 안되므로, 이렇게 run 실행 시 넘겨주는게 좋다.
    ```
    
    - 긴밀한 환경 변수 같은 경우는 절대 이미지에 포함되면 안되므로, 이렇게 run 실행 시 넘겨주는게 좋다.
    
- 이미지 빌드시 사용하는 ARG를 줄 수 있음
    
    ```python
    ARG DEFAULT_PORT=80
    
    ENV PORT $DEFAULT_PORT
    # 이런식으로 빌드시 디폴트 값을 미리 하드코딩 하지 않고, arg로 줄 수 있다.
    ```
    
    ```python
    docker build --build-arg DEFAULT_PORT=8000
    # 이렇게 빌드시 arg를 넘겨 줄 수 있다.
    ```
    
    - 이때 ARG 명령어를 도커파일 앞에 지정하는것은 좋지 않다. 이 ARG가 변경되면 아래 것들도 다시 새로운 레이어로 생성하기 때문이다.
    - 도커 파일을 아래쪽에 두어서 도커 레이어 생태계를 효율적으로 활용하자.

---

### 궁금했던 것(하지만 해결 된 것..)

- 익명된 볼륨(볼륨될 폴더를 명명하지 않은 경우)을 사용하는 경우가 있을까?
    - 익명된 볼륨은 폴더의 위치를 알기 어렵고,
    - 컨테이너 삭제시 해당 폴더도 삭제된다.
    - 굳이 이렇게 익명된 볼륨을 사용하도록 두는 이유는?..
    → 바인드 마운트 하는 경우, 호스트가 컨테이너를 덮어쓰지 말아야 할 파일이나 폴더를 위해
    
    ```python
    docker run -v wjdrbs51/test:app -v app/node_modules
    # 위와 같이, wjdrbs51/test폴더가 컨테이너 내의 app 폴더를 마운트하겠지만(덮어쓰겠지만)
    # 기존에 컨테이너 내에 있던 app/node_modules는 익명의 볼륨이 따로 관리하여, 
    # app/node_modules위치로 오는
    # 요청은 기존의 컨테이너 내에 있던 app/node_modules를 내놓아 준다.
    # 덮어 씌어질 app 보다, app/node_modules가 더 길고 깊은 경로이기 때문에 가능한 일
    ```
    
    → 컨테이너에 이미 존재하는 특정 데이터를 잠그는데 유용하다.
    
- 도커 볼륨을 하는 방법이 한가지가 아니었구나. 그리고 왜 다양한 방법이 있는지도 알겠다. 상황별로 어떤걸 추가하고 사용해야하는지 알게 됨