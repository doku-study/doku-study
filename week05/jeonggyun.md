# 도커 컴포즈

---

- **도커 컴포즈가 없을 때는**
    - 각각의 애플리케이션마다 이미지로 빌드하고, 컨테이너를 실행해야한다.
    - 그 과정에서 `네트워크 설정`, `환경변수` 설정 등등 작성할 명령어가 길어지고 실수 유발.
- **도커 컴포즈를 사용하면**
    - 다중 컨테이너를 한번에 정의하고 실행할 하나의 파일로 관리 가능.
    - 도커 컴포즈는 다중 호스트로 작동하는 컨테이너들에게는 적합하지 않다. 
    단일 호스트에서 운영되는 컨테이너에 적합

### 도커 컴포즈 파일 만드는 법

---

```yaml
version: "3.8"
# 도커 컴포즈의 버전에 따라 달라지는 기능들이 있는데, 특정 컴포즈의 버전을 도커에게 명시한다.

services: 
	mongodb:
		image: "mongo" # 사용할 이미지(특정 이미지의 주소가될 수 있다.)
		volumes: 
			- data:/data/db
		environment: 
			MONGO_INITDB_ROOT_USERNAME: max
			MONGO_INITDB_ROOT_PASSWORD: secret 
		env_file:
			- ./env/mongo.env
			#(환경변수 파일을 가져올 수도 있다. 도커 컴포즈파일 자체에서 환경변수가 노출되지 않는 장점)
		networks:
			
  backend:
		build: ./backend # 이미지 빌드를 위한 backend 도커파일이 있는 상대경로(도커파일과 빌드시 필요한 폴더가 모두 존재하는 폴더 경로여야 한다.)
										 # context와 dockerfile이라는 키워드로, 언급할 수 있다.(도커파일 이름이 Dockerfile이 아닌경우와 다른 예외적인 상황을 위해서)
										 # 만약 도커 컴포즈를 재 실행 했을 때, 이 빌드를 매번 하는것이 아니다. 빌드때 사용할 dockerfile에 변경이 있을 때만, 이를 감지해서 다시 새롭게 빌드하는 과정을 가진다. 도커는 이를 스마트하게 관리한다.
										 # 위의 말은 틀린것 같다. -> 이게 사실이라면, docker-compose up --build 라는 파라미터의 존재가 필요 없다.
		ports: 
			- "80:80"
		volumes:
			- logs:/app/logs #명명된 볼륨
			- ./backend:/app #바인드 마운트
			- /app/node_modules
		environment:
			MONGO_INITDB_ROOT_USERNAME: max
			MONGO_INITDB_ROOT_PASSWORD: secret 
		depends_on: # 특정 다른 컨테이너에 의존적일 때, 사전에 그 컨테이너를 실행시키기 위해
			- mongodb	
		
	frontend:
		build: ./frontend
		ports:
			- "3000:3000"
		volumes:
			- ./frontend/src:/app/src
		stdin_open: true # 개방형 입력 연결이 필요함을 의미
		tty: true # 터미널에 연결하기 위함
					    # 위의 stdin_open과 tty가 -it를 대체
		depends_on:
			- backend		 
		

volumes:
	data:
	logs: 
```

- **docker-compose는 default로 `--rm`과 `-d` 파라미터가 적용된다.**
- **docker-compose에서는 `network`를 따로 지정해줄 필요가 없다.**
    - 도커 컴포즈가 모든 서비스에 대해 새 환경을 자동으로 생성하고, 그 환경(네트워크)에 모든 서비스(컨테이너)를 구성하기 때문이다.
    - 물론, `networks`라는 키워드로 특정 네트워크를 지정해 줄 수도 있다.  이렇게 하면, 도커 컴포즈가 생성한 네트워크 뿐 아니라, 명시한 특정 네트워크에 대해서도 연결이 된다.
- **`volumes`라는 항목에 명명된 볼륨들을 등록시켜 주어야 한다.**
    - 이것은 도커가 services를 위해 생성해야 하는 명명된 볼륨을 알려준다.
    (익명 볼륨과 바인드 마운트는 따로 지정해줄 필요가 없다. )
    따로 작성 함으로써, 아래와 같은 이점들이 있음
    1. 해당 항목에서 명명된 볼륨에 대한 옵션(드라이버, 라벨 등)을 지정할 수 있다.
    2. 해당 명명된 볼륨을 다른 컨테이너에서도 재사용할 수 있다.
    3. 컨테이너와 명명된 볼륨의 생명주기를 분리시킬 수 있다.(서비스가 삭제되어도, 명명된 볼륨은 유지)
- **service의 이름이 container의 이름과 다르다.**
    - 하지만, 도커는 service의 이름을 기억한다. 
    즉, 네트워크 연결 같은 경우에, service의 이름으로 컨테이너끼리 네트워크 주소를 공유할 수 있다.
    - 더 구체적으로, 컨테이너 이름은 {폴더이름}_{서비스이름}_{증가되는 숫자}로 정해진다.
    - 도커 컴포즈에서 자체 컨테이너 이름을 지정해 주고 싶다면, `containder_name` 파라미터를 추가하면 된다.

### 도커 컴포즈 실행

---

- 아래 명령어로 작성한 docker-compose.yaml 파일을 실행
    
    ```yaml
    docker-compose up -d
    # -d : detached 모드
    # --build : 이미지를 리빌드하는것을 강제할 수 있다.(원래는 기존에 있는 이미지를 사용한다. )
    ```
    
- 아래 명령어로 실행된 docker-compose의 서비스들을 중단 → 실행된 컨테이너, 네트워크가 삭제됨
(기본적으로, volume은 삭제되지 않음)
    
    ```yaml
    docker-compose down -v
    # -v : 삭제시 볼륨도 함께 삭제
    ```
    

# Utility Container

---

- utility container란?
    - 특정 애플리케이션 실행에 대한 요소 없이, 특정 환경만 포함한 컨테이너
    - npm 실행 환경이 호스트머신에 존재하지 않아도, npm 실행 환경을 제공해 주는 container가 있으면, 그 실행환경을 차용해서 작업을 진행할 수 있다.
- utility container를 사용하는 이유
    - 실행 환경을 얻기 위해
    - 복잡한 환경 구성을, 도커로 편리하게 구성할 수 있음(개발 시 많이 사용하는 듯?)
- 실행 중인 컨테이너에게 명령 내리기
    
    ```yaml
    docker exec <container> <명령어>
    # -it : docker run 의 -it와 동일한 역할
    ```
    

### CMD와 ENTRYPOINT 차이

- `CMD`
    - docker run 시 작성하는 명령어가 이를 대체(오버라이딩)할 수 있다.
- `ENTRYPOINT`
    - docker run 시 작성하는 명령어가 이를 대체(오버라이딩)하지 않고, 뒤에 파라미터로 추가하는 방식
    - 컨테이너가 시작될 때 **필수적으로** 특정 명령을 실행해야 하는 경우에 적합
- 보편적으로 이 둘을 함께 사용함.
    
    ```yaml
    FROM centos:7
    ENTRYPOINT ["echo", "Hello,"]
    CMD ["World"]
    ```
    
    ```yaml
    docker build -t hello
    
    docker run hello:together
    Hello, World 
    
    docker run hello:together Doku
    Hello, Doku 
    # 매개변수 넘겨주면 CMD값은 오버라이딩됨
    ```