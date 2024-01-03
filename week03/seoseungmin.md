

## 배울 것

### 이미지와 컨테이너의 데이터를 관리하는 방법

### 볼륨

### Arguments, Environments Variables


***

- Application data
    - 읽기 전용. 이미지에 저장됨
- Temporary App Data
    - 컨테이너에 저장됨. 컨테이너는 read-write 가능하기 때문에
    - 파일이 무엇이던 간에 컨테이너의 extra layer에 저장됨
    - 내가 지금 카프카를 도커 위에 올려서 하고 있는 것도 이 부분과 연관 있지 않을까?
- Permanet App Data
    - 마찬가지로 컨테이너에 저장되지만, 컨테이너 중지 되어도 손실되어선 안되는 종류
    - 컨테이너와 볼륨에 저장됨 (볼륨이 이런 목적이었구나)


- 강의 자료에서
    - 임시 자료는 temp, 영구 데이터는 feedback에
    - 이 앱을 dockerize 시킬 것
- 먼저 Dockerfile 작성

```Dockerfile
FROM node:14

WORKDIR /app

COPY package.json .

RUN npm install

COPY . .

EXPOSE 80

CMD ["node", "server.js"]
```

- 태그 추가하기 위해 `-t` 달아서 이미지 빌드
    - `docker build -t feedback-node .`
- 빌드한 이미지 기반으로 컨테이너 시작할 수 있음
    - `docker run -p 3000:80 -d --name feedback-app --rm feedback-node`
    - `-d`: detached 모드로 컨테이너 시작. 이러면 컨테이너 실행시켜도 터미널 사용 가능
    - `--name`: 컨테이너에 이름 부여
    - `--rm`: 컨테이너 중지 할 때마다 자동으로 제거
- localhost:3000 접속하면 됨
- 제목과 내용 입력해서 save하면 `/feedback/{제목}.txt`로 확인 가능
    - 이 데이터는 도커 위에서만 존재
- 강조하는건, 컨테이너 - 이미지 - 로컬 데이터간 독립. 
    - 이미지 빌드할 때 로컬 폴더, 파일의 스냅샷을 복사하는 것이 마지막 연결    


- 일단 컨테이너 중지
    - `docker stop feedback-app`
    - 컨테이너 자동으로 제거됨
- 자동으로 삭제 안되게 다시 시작
    - `docker run -p 3000:80 -d --name feedback-app feedback-node`
- 이걸 다시 중지
    - `docker stop feedback-app`
    - 다시 실행하면 파일이 삭제되지 않았음을 확인 가능
- 이미지에는 호스팅 시스템 파일 시스템에서 분리된 자체 내부 파일 시스템이 있음
    - 이 이미지를 기반으로 컨테이너 시작하면, 이미지 위에 얇은 read-write 레이어로 컨테이너가 추가됨
    - 이 레이어가 있어서 이미지 파일 시스템에 액세스 할 수 있는 것.
    - *컨테이너의 파일 시스템과 이미지의 파일 시스템. 이 두 개는 엄연히 다른, 독립된 것인지 헷갈림. 차원 자체가 다른 개념 같다고 느껴지는데, 이유를 생각해보면 read-only와 read-write 간 차이에서 나온게 아닐까.* 
- 내가 이해한건, 두 개가 같은 파일 시스템을 바라봄. 다만 컨테이너에 데이터가 추가된다면, 컨테이너의 read-write 레이어에 저장됨. 이미지는 read-only이므로
    - 그래서 컨테이너가 제거되면 변경되지 않는 이미지만 남음
- 이게 도커의 핵심 개념. 동일한 이미지에 기반한 다수의 컨테이너가 서로 완전히 격리되어 있다는 것
- 컨테이너 중지시켜도 데이터가 살아있어야 한다면?
    - 실제로는 컨테이너 자주 삭제할 것. 소스 코드 변경만해도 이미지를 다시 빌드해야 하니까
    - 해결 방법은? 볼륨


- 볼륨은 데이터를 유지하도록 돕는 기능. 근데 어떻게?
    - 볼륨은 호스트 머신의 **폴더**. 볼륨은 컨테이너나 이미지에 있는게 아님
    - 컨테이너 내부의 폴더를 호스트 머신 상의 폴더와 연결 할 수 있음
    - 컨테이너는 볼륨에 read-write 할 수 있음
    - 근데 왜 이름이 볼륨인걸까? 컨테이너, 이미지는 단어가 가리키는 사물의 특징을 담았는데, 볼륨은?
- Dockerfile 에 `VOLUME ["{매핑시킬 컨테이너 내부 폴더 경로}"]` 추가하면 볼륨 생성
    - `VOLUME ["/app/feedback"]`
    - 강의에선 이걸 EXPOSE 다음에 썼는데, 순서는 상관없는걸까?
    - 내가 작성한 Dockerfile 보니 저 구문은 없지만, docker-compose에 아래와 같이 있긴함

```
volumes:
    - /var/run/docker.sock:/var/run/docker.sock
```

- 이미지 다시 빌드
    - `docker build -t feedback-node:volumes .`
    - volumes라는 태그 부여
- 컨테이너 실행
    - `docker run -d -p 3000:80 --rm --name feedback-app feedback-node:volumes`
    - 볼륨 덕분에 `--rm` 붙여도 괜찮음
    - 실행 전 기존 컨테이너 stop, rm 시켜야 함. 안그럼 포트 겹쳐서 run 불가능
- 버그 있어서 node 코드 수정함
    - 소스코드 변경한거니 이미지 다시 빌드해야 함
    - `docker rmi feedback-node:volumes`
    - 그전에 컨테이너 먼저 중지해야 함
    - `docker build -t feedback-node:volumes .`
    - `docker run -d -p 3000:80 --rm --name feedback-app feedback-node:volumes`
- 컨테이너 중지 후 삭제 시킨 뒤 다시 실행시켜서 데이터 남아있는지 확인
    - 그래도 확인되지 않음. 왜 작동 안하나?

- volumes vs bind mounts
    - 일반적으로 볼륨은 anonymous. 이 경우는 도커가 관리함. 컨테이너가 존재하는 동안에만 볼륨이 존재함
    - 아니 그럼 애초에 익명 볼륨이란걸 왜 만든거지? 볼륨이란 개념 자체가 컨테이너 종료돼도 데이터 저장하기 위해서 만든거 아닌가
    - `VOLUME ["/app/feedback"]` 이 경로는 호스트 머신의 어떤 폴더에 매핑되는데 그걸 모름. 도커가 관리하기 때문. 우리가 액세스 할 수 없게 일부러 만들어 놓은 것.
    - `docker volume ls`으로 현재 볼륨 확인 가능. 익명이라 name이 도커가 자동으로 명명한 값
- named volumes를 사용하면 컨테이너 종료 되어도 볼륨 유지됨. 도커가 관리하는 것은 같음. 직접 편집 불가능
    - Dockerfile에서 name volume을 만들 수는 없음. 그래서 VOLUME 명령 제거
    - 이미지 제거, 다시 빌드 후, 컨테이너 실행하는데, 이 때
    - `docker run -d -p 3000:80 --rm --name feedback-app -v feedbaack:/app/feedback feedback-node:volumes`
    - {이름}:{컨테이너 내부 경로} 라고 생각하면 될 것 같다
- 이 컨테이너 종료 후에 다시 실행하되, 위의 naemd volume을 그대로 사용
    - `docker volume ls` 로 볼륨 그대로 남아있는 것 확인 가능
- run은 새로운 컨테이너 실행하는 명령어. 기존에 볼륨 붙인 컨테이너와는 다른 독립된 컨테이너가 실행되는 것
    - 둘이 어쨌건 같은 name volume을 바라보게 하는 것 아닌가
- 사용하지 않는 익명 볼륨은 `docker volume prune`으로 가능


- bind mounts는 다른 종류의 데이터 스토리지?
    - 소스코드 변경 사항은 이미지에 자동으로 반영하는 방법인가?
    - 볼륨과 차이라면 내가 매핑할 폴더와 경로를 직접 지정한다는 것.
    - 소스 코드를 스냅샷이 아닌 바인드 마운트에서 가져옴
    - 컨테이너는 항상 최신 코드를 가져올 수 있음
    - 영구적이고 편집 가능한 데이터에 적합함
- name volume은 편집이 불가능. 어디에 있는지 모르니까
- 이미지에 영향 주지 않고 컨테이너에만 영향 미침
- 컨테이너 중지, 다시 실행
    - `docker stop feedback-app`
    - `docker run -d -p 3000:80 --rm --name feedback-app -v feedbaack:/app/feedback -v "{프로젝트 폴더의 절대 경로}:/app" feedback-node:volumes`
    - 도커가 해당 폴더에 접근 가능한지 미리 확인 필요. 데스크롭 환경 설정의 file sharing에서 'Users' 하위 경로 모두 접근 가능한 것 확인 가능
- 컨테이너 실행해서 다시 3000 접속하면 충돌하는데, 원인이 뭘까?
    - `docker logs feedback-app` 으로 발생한 오류 확인
    - 특정 모듈을 찾을 수 없다는데, 바인드 마운트 사용한 것만으로 왜 이렇게 되는걸까?

- 로컬의 폴더를 /app 폴더에 바인딩 하는 것
    - 처음 이미지 생성 시 app 폴더의 모든 것을 해당 로컬 폴더로 덮어씌움
    - 이걸 마지막에 하면 이전에 설치한 디펜던시 등이 다 날라가는 셈
    - 위에서 내가 생각했던 순서가 여기서 나오네. 그럼 앞에서 볼륨 붙이면 되는거 아닌가?
- 도커에게 내부 파일 시스템에 특정 부분이 있어 이건 덮어쓰지 말아야 함을 알려줘서 해결
    - 또다른 볼륨으로 해결
    - `docker run -d -p 3000:80 --rm --name feedback-app -v feedbaack:/app/feedback -v "{프로젝트 폴더의 절대 경로}:/app" -v /app/node_modules feedback-node:volumes`
    - 볼륨 앞에 콜론으로 이름 안 붙이면 익명 볼륨이 됨
    - 이래서 익명 볼륨을 사용하는구나.. 근데 왜 굳이 익명 볼륨?
    - 설명은 정말 헷갈리는데 그냥 한번 더 꼬아서 저 부분은 살린다 생각해도 되지 않을까
    - 순서만 위로 올려서 다시 이미지 빌드 해봤는데, 역시 안됨. (html 수정해도 바로 반영 안됨)
    - 강의에서 하란대로 했더니 잘됨. 신기하네
- 소스코드를 편집할 일이 생길 땐 이런 식으로 bind mount를 걸어서 편집한게 실시간으로 반영되게 할 수 있구나
    - 익명 볼륨으로 덮어씌우지 않을 폴더를 설정해줘야 함. 어떤 것을 익명 볼륨으로 해줘야 할지 어떻게 판단할까?


- 다음 강의는 nodeJS, 특히 로그 관련 특화된 내용이라 메모 안 함

- 볼륨, 바인드 마운트 요약
    - `docker run -v /app/data ...` -> anonymous volume : 컨테이너 제거 되면 같이 제거. 컨테이너에 이미 존재하는 특정 데이터를 잠그는데 유용함. 즉, 다른 모듈에 의해 덮어쓰여지는 것을 방지할 수 있음. 성능과 효율도 좋음. 다르게 말하면, 외부 경로보다 컨테이너 내부 경로의 우선 순위를 높이는데 사용할 수 있음. (도커 내부 로직 상 더 구체적이고 깊은 경로를 우선시 하기 때문에)
    - `docker run -v data:/app/data ...` -> named volume : 컨테이너 제거해도 살아남음. 여러 컨테이너 간에 데이터 공유 가능. 
    - `docker run -v /path/to/code:/app/code ...` -> bind mount : 호스트 머신의 폴더를 직접 지정할 수 있음. 우리가 이 경로를 아니까 이걸 변경할 수 있고, 변경한게 컨테이너에 바로 적용됨. 컨테이너가 이 로컬 폹더를 매핑하도록 되어 있으니까. 일반적으로는 컨테이너에 '라이브 데이터'를 제공하려고 할 때.


- 읽기 전용 볼륨
    - 기본적으로 볼륨은 read-write. 이걸 읽기 전용으로 바꾸려면 `:ro` 추가하면 됨
    - `docker run -d -p 3000:80 --rm --name feedback-app -v feedbaack:/app/feedback -v "{프로젝트 폴더의 절대 경로}:/app:ro" -v /app/node_modules feedback-node:volumes`
    - 이러면 feedback 폴더만 read-write 할 수 있음
    - `docker run -d -p 3000:80 --rm --name feedback-app -v feedbaack:/app/feedback -v "{프로젝트 폴더의 절대 경로}:/app:ro" -v /app/temp -v /app/node_modules feedback-node:volumes`
    - 이러면 temp에 대해서도 read-write 할 수 있음
    - 일단 다 read-only로 두고 write 해야 하는 것만 볼륨으로 관리하는 방법

- `docker volume ls` 실행하면 현재 존재하는 볼륨 목록을 보여주는데, 바인드 마운트는 도커에 의해 관리되는 것이 아니기 때문에 여기에 표시되지 않음
- 만약 feedback 볼륨을 지운다면, 현재 앱의 구조 상 웹에서 생성된 모든 텍스트 파일이 삭제됨


- 전체 폴더를 바인드 마운트 시키는건데, dockerfile에서 여전히 COPY 시키는 이유는? 어쨌건 덮어쓰는데?
    - `COPY . .` 주석 처리 후 이미지 다시 빌드해보면 여전히 잘 작동함.
- 만약 개발을 마치고 라이브로 옮겼다면, 프로덕트가 실행되는 동안 소스코드에 라이브로 연결해서 업데이트 시키지는 않을 것
    - 라이브 프로덕션 환경에선 코드 스냅샷을 따는 것이 중요. 버전 관리가 괜히 중요한게 아님
    - `COPY . .`가 있으면 라이브 환경에서도 여전히 스냅샷 이미지를 만들 수 있음


- `COPY . .`에서 복사하는 내용을 제한할 수 있음. .dockerignore 파일로 가능
    - 깃과 비슷함
    - COPY 되어선 안되는 파일을 리스팅 할 수 있음


- ARG & ENV
    - arg를 사용하면, Dockerfile 에서 변수를 설정할 수 있음. 이미지 빌드 할 때 태그로 부여함
    - env는 말 그대로 환경 변수. docker run 할 때 --env 로 이 환경 변수를 사용할 수 있음
- 포트 80을 arg로 두면, 나중에 변경할 일 생길 때 필요함
- 포트 값 같은 것을 환경 변수로 두면, 컨테이너 실행 중일 때도 포트를 변경 할 수 있음
- `--env PORT=8000` 을 run 할 때 같이 실행. 
- .env 파일을 만들어서 `--env-file ./.env`로 이 파일을 참조할 수도 있음
    - 이게 내가 했던 방법. 신기하네
- 인수, 환경 변수는 서로 다른 모드, 구성에서 하나의 동일한 이미지를 기반으로 하나의 동일한 컨테이너를 실행하는데 유용함
- 보안 관련해서, 지금 내가 하는 방법은 .env로 관리하고, gitignore에 .env 추가해서 깃에는 커밋 안되게. 문제 없을까?
- 환경 변수는 되도록 Dockerfile 후반에 두는게 좋은데, 이건 변경할 일이 잦을 수 있음. Dockerfile의 계층적 특성 상 변경 된 레이어의 후속 레이어도 리빌드, 재실행 되기 때문에 비효율적임


- 요약
    - 결국 볼륨은 컨테이너가 실행된느 호스트 머신 상의 폴더에 불과함. 도커에 의해 관리되고, 도커 컨테이너에 마운트 됨
    - 컨테이너가 제거되도 볼륨에 있는 데이터가 남는 원리는, 결국 컨테이너 데이터가 호스트 머신 내 어떤 경로에 미러링 되거나 복사되기 때문
    - 바인드 마운트는 named volume과 비슷하긴 하나 호스트 머신 내의 경로를 안다는 점이 가장 중요한 차이점. 이 경로를 알기 때문에 컨테이너가 바라보는 데이터를 변경해서 컨테이너에서 항상 최신 데이터를 사용할 수 있게 만드는 것

