### 22. 자체 이미지를 기반으로 컨테이너 실행하기

<br/>

```
FROM  node 

WORKDIR /app

COPY . /app

RUN npm install 

EXPOSE 80

CMD ["node", "server.js"]

PS C:\Users\userpc\Downloads\docker_study\nodejs-app-starting-setup> docker build .

=> ERROR: error during connect: this error may indicate that the docker daemon is not running:
Get "http://%2F%2F.%2Fpipe%2Fdocker_engine/_ping": open //./pipe/docker_engine: The system cannot find the file specified.
```
도커 이미지를 생성하기 위해 `docker build .` 빌드를 해줬으나 위와 같은 에러가 발생함.

<br/>

[Docker Run시 발생한 오류](https://chaelin1211.github.io/study/2021/04/01/docker-error.html)


⇒ docker 접속을 위해 local에서 docker Desktop 앱을 실행해서 연결 해주기! 리눅스와 달리 데스크탑에서는 도커를 사용하기 위해선 도커 데스크앱이 실행되어야하는 것 같음. 

노드 라이브러리랑 현재 디렉토리에 있는 파일들을 이미지로 빌드하는것 까지는 오케이.

그럼 이제 `docker run image-id` 로 실행시켜서 localhost:3000 웹과 통신이 되는지 확인해보면 안됨.

Dockfile에서 EXPOSE 80 으로 적은 것은 해당 포트를 사용하겠다고 명시한 것일 뿐 실제로 포트를 노출시킨 것이 아니다.

따라서 ```docker run -p 3000:80 image-id``` 이렇게 포트를 열어주는 것이 필요하다


---

### 24. 이미지는 읽기 전용! 

server.js 중 웹 localhost:3000에 뜨는 문장인 My Course Goal 뒤에 느낌표를 붙이고 싶어서 수정하였다. 이것은 실행중인 어플리케이션에 반영되어야하는 HTML 코드에 대한 작은 변경사항이다.

수정 후 `docker run -p 3000:80 image-id` 해당 명령을 다시 실행하여 우리가 구축한 어플리케이션인 이 이미지를 기반으로 이 컨테이너를 다시 시작하면 노드 어플리케이션이 다시 시작된다

이제 localhost:3000을 다시 로드하면 이 애플리케이션이 다시 표시됩니다.
하지만 문제점이 있다면 이전에 수정했던 코드 변경사항이 반영되지 않는다. 
My Course Goal 뒤에 느낌표를 추가했었는데 여기에 여전히 느낌표 없이 My Course Goal이라고 표시된다. 그렇다면 이 변경 사항이 반영되지 않은 이유는 무엇일까??

이를 이해하기 위해선 이미지가 작동하는 방식을 이해해야 한다.

우리는 Dockerfile에서 현재 디렉토리의 소스 코드, server.js 파일을 포함한 모든 파일을 도커 이미지 내의 app 폴더에 복사하고 npm install 을 실행하고 포트 80을 열라고 명시하고 컨테이너가 시작될 때 server.js를 실행하도록 설정하였다.  

여기서 소스코드를 이미지에 복사하고 복사한 시점에서 소스 코드의 스냅샷을 만든다. 이 느낌표를 추가할 때 여기에서 수행한 것처럼 이후에 소스 코드를 편집하면 이 변경 사항은 이미지의 소스 코드에 포함되지 않는다. 

⇒ 업데이트된 소스 코드를 새 이미지로 복사하려면 이미지를 다시 빌드해야 한다. 

그렇다면 코드를 변경할때마다 이미지를 다시 빌드해야 하는가…? 이 방법에 대해서는 뒤의 강의에서 다룬다.

여기서 알아야할 이미지의 특징으로는

- 기본적으로 잠겨 있음
- 이미지의 모든 것은 읽기 전용
- 과거에 해당 코드를 복사했기 때문에 빌드 후 단순히 코드 업데이트로는 외부에서 편집할 수 없음
- 업데이트된 모든 코드를 기본적으로 이미지에 복사하려면 이미지를 다시 빌드해야함

⇒ **이미지는 닫힌 템플릿임을 이해하는 것이 매우 중요하다.**

---

### 25. 이미지 레이어 이해하기

이미지는 레이어 기반임을 이해하는 것이 중요하다!
```
FROM  node 

WORKDIR /app

COPY . /app

RUN npm install 

EXPOSE 80

CMD ["node", "server.js"]
```

- 이미지를 빌드할 때마다 도커는 모든 명령 결과를 캐시하고 다시 빌드할 때 명령을 다시 실행할 필요가 없으면 이전에 캐시로 남은 결과를 사용한다. 이것을 레이어 기반 아키텍쳐라 한다.
- Dockerfile의 하나하나 커맨드 라인이 레이어를 나타내며 server.js쪽에서 일부 코드를 수정한뒤에 다시 빌드했을 경우 이전 빌드에서 사용된 동일한 내용들, 캐시를 사용하기 때문에 처음 빌드할 때보다 더 빠르게 처리가 된다.
- 하나의 레이어(커맨드 라인)가 변경될 때마다 모든 후속 레이어도 다시 실행되므로 코드를 수정할 때마다 비효율적이지만 npm install이 다시 실행된다. 종속성을 관리하는 package.json에서 수정이 없다면 npm install을 다시 실행할 필요가 없음에도 말이다.
- 이러한 비효율적인 처리는 레이어의 처리 순서를 변경해주는 것으로 최적화할 수 있다!


```
FROM  node 

WORKDIR /app

COPY package.json /app

RUN npm install 

COPY . /app

EXPOSE 80

CMD ["node", "server.js"]
```
- 이전에 먼저 소스코드를 복사후 npm install을 실행하는 대신 npm install 후에 소스코드를 복사하는 것으로 순서를 바꾸면 매번 npm install을 실행시킬 필요가 없다. 코드를 수정할때마다 디피션시에 변동이 있는것이 아니기 때문이다.
- 이렇게 레이어를 짠다음 소스 코드에서 수정후 디피션시의 변동이 없다면 이미지를 재빌드 할 때 마다 npm install을 실행할 필요가 없으므로 이미지 생성 속도가 더 빨라질 것이다.
- 실제로도 레이어를 변경 후 재빌드해보면 npm install 이전 단계가 변경되지 않았기 때문에 다시 복사하고 npm install을 실행할 필요가 없으므로 빌드 속도가 매우 빨라진 것을 확인할 수 있다.

---
### 27. 이미지 & 컨테이너 관리

- Images
    - tag (name) : -t, docker tag ~
    - listing : docker images
    - analyed : docker image inspect
    - remove : docker rmi, docker prune
- Containers
    - name : —name
    - config in detail : see —help
    - listing : docker ps
    - remove : docker rm

---


### 28. 컨테이너 중지-재시작 & 29. Attached & Detached 컨테이너 이해하기

- 컨테이너 확인 : docker ps / docker ps -a(중지된 컨테이너 포함)
- 매번 docker run을 사용할 필요는 없음. run 명령어는 이미지를 기반으로 새 컨테이너를 만들기 때문에 불필요한 컨테이너가 만들어지는 것을 원하지 않으면 기존의 컨테이너를 재시작하는 것이 적합함 
(ex: 어플리케이션, 디피션시와 소스코드, 이미지가 변경되지 않을 경우)
    - `docker ps -a` : 중지된 컨테이너 확인
    - `docker start [container id or name]`
    - `docker run -p 3000:80 image id`은 포어그라운드에서 실행되는 것과 달리 `docker start [container id or name]` 를 실행하면 터미널에 로그가 남지 않고 백그라운드로 실행됨.
        - 이러한 기능은 Attached & Detached 직접 설정 가능. 
        docker start의 경우 detached 모드가 디폴트
        docker run의 경우 attached 모드가 디폴트 (attached 모드는 컨테이너의 출력 결과를 수신함의 의미. 콘솔의 출력내용)
        - `ddocker run -p 8000:80 -d imageID` : detached모드로 변경하 컨테이너를 백그라운드로 돌림.
        - 백그라운드에서 돌아가고 있는 컨테이너의 ID나 이름을 확인 후 `docker attach [containerID or name`] 을 실행하면 백그라운드에서 포어그라운드로 변경하여 콘솔에 로그값을 출력할 수 있다.
        - `docker logs [container ID or name]` : 해당 컨테이너의 출력된 과거의 로그들을 확인할 수 있음. `docker logs -f [container ID or name]`  이렇게 실행하면 이전의 로그들을 출력할 뿐 아니라 수신대기상태로, 포어그라운드로 변경함.
    - 만약 여러개의 컨테이너를 실행시키고 싶다면 `docker run -p 8000:80 image id` 새로운 포트번호로 변경한다음 새로운 컨테이너를 실행시키면된다.
  

---

### 31. 인터렉티브 모드로 들어가기


```
from random import randint

min_number = int(input('Please enter the min number: '))
max_number = int(input('Please enter the max number: '))

if (max_number < min_number): 
  print('Invalid input - shutting down...')
else:
  rnd_number = randint(min_number, max_number)
  print(rnd_number)
```

지금까지 예제로 사용해왔던 Node의 경우 터미널에서 직접 인터렉티브하게 입력하거나 출력하는 기능이 필요없었기에 포어그라운드든 백그라운드든 형태가 상관없었지만 이렇게 input으로 인터렉티브한 입력을 필요로 할 경우 이전처럼 docker run image-id 를 실행하면 

```
PS C:\Users\userpc\Downloads\docker_study\python-app-starting-setup> docker run d345ae0c5aed24d3ceb234f3b22ea00c87f
Please enter the min number: Traceback (most recent call last):
  File "/app/rng.py", line 3, in <module>
    min_number = int(input('Please enter the min number: '))
                     ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
EOFError: EOF when reading a line
```
다음과 같은 에러가 발생한다. 

이 실행중인 컨테이너와 컨테이너로 실행중인 어플리케이션이 상호 작용할 수 없다.

docker run을 사용하면 디폴트로 컨테이너에 연결되며 우리는 컨테이너에 의한 출력 결과를 받을 수 있지만 컨테이너나 컨테이너로 실행되는 어플리케이션은 그 어떤 것도 입력받을 수 없다. 

위와 같은 문제를 해결하기 위해 도커의 여러 설정을 사용하면 된다. 

- -i 모드 : 표준 입력을 열린 상태로 유지하여 attached 모드가 아니여도 컨테이너에 입력 가능
- -t 모드 : 터미널을 생성
    
    ⇒ i 모드와 t 모드를 결합하여 컨테이느가 입력을 수신하고 컨테이너에 의해 노출되는 터미널을 생성함. 컨테이너가 실제로 입력받는 장치가 된다. 
    
    => `docker run -it image-id`
    
    터미널에 무언가를 입력할 수 있고 사용자 입력을 수신하는 컨테이너 프로세스에도 연결된다. 컨테이너 실행후 자동으로 종료된다.
    
- docker start로 기존의 컨테이너를 실행할 경우 어떻게 인터렉티브 모드로 들어가야 하는가??
    - `docker start -a container ID or name` : 입력이 가능하지만 컨테이너 작동 후 한번만 입력이 가능함. 어플리케이션의 제대로된 기능을 사용할 수 없음.
    - `docker start -a -i container ID or name` : -i 설정을 추가해줌으로써 인터렉티브 모드 사용.
    

이와 같은 어플리케이션 처럼 출력결과를 수신하기 위해 연결할 뿐 아니라 입력을 제공하기 위해 연결하는 이유는 도커가 웹 서버와 웹 어플리케이션 같은 장기적인 실행 프로세스에만 적용되는 것이 아니기 때문이다.

도커는 간단한 유틸리티 어플리케이션이나 입력이 필요하고 일부 출력을 제공해야 하는 어플리케이션을 만드는데 사용될 수 있다.



---

### 32. 이미지 & 컨테이너 삭제하기 

- 컨테이너 삭제하기
    - `docker rm [container name]` 을 통해 실행중인 컨테이너를 삭제하려하면 실행 중인 컨테이너를 제거할 수 없다는 에러가 발생. 컨테이너 실행 중지 후 삭제해야함.
    - `docker rm [container name] [container name] [container name]...` : 한번에 여러개의 컨테이너 삭제 가능. 하지만 하나씩 복사 붙여넣기 하는건 불편하므로 정지된 컨테이너를 자동으로 삭제하는 기능은 다음 강의에서 진행.
- 이미지 삭제하기
    - `docker rmi [image-ID]` : 이미지 내부의 모든 레이어를 삭제.
    - 이미지를 삭제하기 위한 선행 조건이 존재한다
        - 해당 이미지로 생성된 컨테이너가 존재할 경우 이미지를 삭제할 수 없다.  종속된 컨테이너들을 먼저 삭제한 뒤에 이미지 삭제가 가능하다.
    - `docker image prune` : 사용되지 않는 모든 이미지 제거함.
 
---

### 33. 중지된 컨테이너 자동 삭제하기
- —rm 플래그 : 컨테이너가 종료될 때 자동으로 제거되는 플래그. 매번 중지된 모든 컨테이너를 수동으로 정리할 필요가 없어짐.
- 위에서 사용한 파이썬 어플리케이션의 경우 - `docker run -it image-id` 을 실행할경우 작동 후 새로운 컨테이너가 생성되기에 불필요한 컨테이너들이 많아지는데 이 때 `docker run --rm -it image-id` 이렇게 —rm 을 추가해주면 작동 후 자동으로 컨테이너가 중지 후 삭제된다!

  

---

### 34. 작동 배경 살펴보기 : 이미지 검사



- `docker image inspect [image-ID]` :
    - 이미지 전체 ID
    - 생성된 날짜
    - 컨테이너 정보 (컨테이너 ID, 노출 포트, 환경 변수 등등….)
    - 도커 버젼
    - 운영 체제
    - 이미지의 다른 레이어. Dockerfile의 레이어와 갯수가 다른데 그 이유는 Dockerfile에 정의된 레이어에만 국한되지 않기 때문. 노드 예제의 경우 노드 기본 이미지에 의해 제공되는 2개의 레이어가 추가됨.
    - 이외에 이미지에 대한 다양한 정보들을 담고 있음.
 

---

### 35. 컨테이너에/컨테이너로부터 파일 복사하기
- `docker cp [local-file-path] [container-name : copy-to-path]` : 실행 중인 컨테이너로 파일이나 폴더를 복사할 수 있음. 
ex) `docker cp dummy/. boring_vaughan:/test`
로컬의 dummy디렉토리 안의 모든 내용을 boring_vaughan 컨테이너의 test폴더로 복사
- `docker cp [container-name : copy-to-path] [loacl-file-path]` : 실행 중인 컨테이너에서 로컬로 파일이나 폴더를 복사할 수 있음. 
ex) `docker cp boring_vaughan:/test dummy` : 컨테이너의 test폴더 내용을 dummy 로컬 폴더로 복사

- 컨테이너 안 어플리케이션 소스코드에 수정이 필요해서 복사를 통해 업데이트하는 방법은 좋은 방법이 아니. 오류가 발생하기 쉽고 변경한 파일들이 헷갈리기 쉬우며 현재 실행중인 파일을 교체하는건 불가능함.
- docker cp를 사용하면 적합한 케이스로는
    - 컨테이너가 많은 로그 파일을 생성할 경우 docker cp 커맨드를 통해 로그 파일들을 컨테이너에서 로컬로 복사하여 확인 및 모니터링이 가능함.
 

---


### 36. 컨테이너와 이미지에 이름 및 태그 지정하기



- docker run을 통해 컨테이너를 생성할 경우 컨테이너의 이름은 랜덤으로 지정된다. 하지만 특정 목적을 위해서 컨테이너를 분류 및 지정하여 사용한다면 컨테이너에 고유 이름과 고유 태그를 지정하는 것이 사용하는데 더 편리할 것이다.

- 컨테이너 고유 이름 지정
    - `docker run -p 3000:80 —rm —name [custom-name] [image-id]`

- 이미지 이름 : 고유 태그 지정
    - 이름(name) : 이미지의 리포지터리.
    - 태그(tag) : 해당 이미지에 대한 다양한 버젼, 옵션을 지정하여 가져오거나 혹은 관리할 때 명시하고자 사용. 노드 이미지를 예로 들자면 태그를 통해 특정 버젼, 특정 구의 노드 이미지를 사용할 수 있음.
    - `docker build -t goals:latest .` : 이미지 빌드시 -t 설정을 통해 이름은 goals, 태그는 latest로 지정하여 생성할 수 있음
    - `docker run -p 3000:80 -d —rm —name goals goals:latest` : 컨테이너 생성시 이미지 id 대신 이름과 태그를 지정하여 사용가능.
 

---

### 37. 이미지 공유하기

- 이미지만 있다면 이미지를 기반으로 컨테이너를 실행할 수 있으므로 실질적으로는 이미지를 공유한다. 이미지를 공유할 때 두가지 주요 방식이 존재한다
    - Dockerfile & 소스코드 공유하기 : 해당 파일들로 자체 이미지를 빌드하여 컨테이너를 실행할 수 있다.
    - 빌드된 전체 이미지 공유하기 : 완성된 이미지를 공유함. node 이미지를 가져와서 사용하는 것처럼. 따라서 Dockerfile을 가져와 직접 빌드하지 않음.
    
    ⇒ 실제로 팀간의 공유 혹은 배포를 할 때는 로우 파일인 Dockerfile이 아니라 완성된 이미지로 작업한다.


---
### 38. DockerHub에 이미지 푸시(push)하기 & 공유 이미지 가져오기(pull)


- 이미지를 푸시할 수 있는 두 가지 주요 위치
    - 도커 허브 : 공식 도커 이미지 레지스트리.
    - 개인 레지스트리
    
- 이미지 push/pull 커맨드
    - docker push image-name
    - docker pull image-name
    
- 도커 허브 레포 생성 후 업로드
    - docker login 으로 도커 허브에 로그인하기
    - `docker push academind/node-hello-world` : 도커 허브의 레포는 로컬에 존재하지 않기 때문에 해당 명령어로는 바로 업로드를 할 수 없음.
        - `docker build -t academind/node-hello-world .` : academind/node-hello-world 태그로 이미지 다시 빌드하기
        - `docker tag node-demo:latest academind/node-hello-world` : 기존의 이미지의 이름과 태그 변경하기. 기존 이미지 이름:태그인 node-demo:latest 에서 이름을 academind/node-hello-world로 변경. 태그는 추가하지 않음. 이미지 이름을 변경할 경우 해당 이미지의 이름이 변경된 복사본을 생성한다.
    - 이미지를 푸시할 경우 이미지 전체를 업로드하지 않는다.
        - 강의에서는 도커 허브에 있는 노드 이미지를 가져와서 사용했기 때문에 도커 허브에 존재하는 노드 이미지에 대한 연결을 설정하여 추가 정보만 푸시한다.
     
- - `docker pull academind/node-hello-world` : 공개된 도커 허브 이미지이므로 로그아웃 상태에서도 작동함.
- 레포에 푸시하기 위해서는 로그인이 필요하지만 공개되어 있다면 모든 사람들이 접근하여 이미지를 가져갈 수 있음.








