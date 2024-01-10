# 데이터 관리 및 볼륨으로 작업하기

- 어떤 다양한 방식으로 데이터를 관리하는지
- 다른 폴더에 연결하는 방식
- 도커 내 볼륨
- 이미지와 컨테이너 내에서 arguments & environment variables 사용하는 방법

## 데이터의 종류

1. Application(Code+ENV)
    - 실행 중인 app에서 소스코드, 환경 변경 X → Read Only여야 한다
    : 이미지에 저장되는 이유
    - **이미지 == Read Only**
        - 이미지를 build 할 때, 소스 코드가 이미지에 복사됨(by Dockerfile) 
        → 소스코드 fixed(고정됨) :  `변경할 수 X`
        - 모든 명령 실행이 완료되면 이미지가 잠겨서 닫힘, 변경이 필요하면 새 이미지 빌드 필요!
2. Temporary App Data
    - app 실행 중에 생성되는 데이터(fetched/produced)
    ex) 사용자 입력 데이터
        - 메모리, 데이터베이스, 파일 등에 저장
        - 데이터를 잃어도 O
    - 그러나, app 실행 시에는 일시적으로 read-write를 함 
    → 컨테이너의 extra layer에 저장됨 (이미지는 Read Only이므로)
    
    - 도커 ) extra layer(read-write layer) → 일종의 로직
        - 이 레이어의 도움을 받아 어떤 데이터든 저장
            - 컨테이너 안에만 존재
            - 로컬 시스템, 이미지에도 모두 없음
        - read-write access 권한 + 파일 시스템 조작 O
        - 컨테이너의 변경 사항 추적, 최종 파일 시스템에 extra layer에 저장된 변경 사항을 결함
        - 이미지, 이미지의 파일 시스템 인식하여  미러링(복사X)
3. Permanent App Data
- app 실행 중에 생성되는 데이터(fetched/produced) + **컨테이너가 제거(삭제)되더라도 기억되어야 하는 데이터**
    - 데이터베이스, 파일에 저장
    - 잃으면 안됨!
- 영구 App데이터도 read-write데이터 : 컨테이너에 저장함(extra layer)
- 그러나, 영구적으로 저장되어야 함 → `도커의 볼륨`

## 볼륨 (Volume)

- 데이터를 유지하기 위해 필요한 기능
- 호스트와 상관업이 도커에 의해 관리됨
- 호스트 머신(로컬)의 폴더 ↔ 컨테이너 매핑
    - 호스트 머신 내에 생성된 경로는 알기 어려움
        
        ```bash
        # 생성된 볼륨 확인하기 
        docker volume ls
        
        docker volume --help # 관련 명령어 정보 볼 수 있음
        docker volume inspect feedback # 볼륨정보
        ```
        
- 두 폴더의 변경 사항은 다른 폴더에 반영
    - 컨테이너 내부, 외부(호스트 머신)에서도 변경 가능
- 컨테이너가 종료 혹은 제거되어도 볼륨의 데이터 유지
- 컨테이너에 볼륨을 추가하는 형태 → 컨테이너는 볼륨에 데이터를 읽고 쓸 수 있음
- 볼륨의 종류
    - **anonymous volumes(익명 볼륨)**
        - `-v /app/data`
        - 컨테이너 종료 시에 바로 사라질 수 있음(`--rm`)
        - 하나의 컨테이너와 밀접하게 연결(컨테이너 간 데이터 공유X)
        - 컨테이너에 이미 존재하는 특정 데이터를 잠그는데 유용
        - Dockerfile에서 생성 가능
    - **named volumes(명명된 볼륨)**
        - `v data:/app/data`
        - persistent but, can not editing
            - 생성된 경로를 알기 어려우므로
        - Dockerfile에서 생성 불가능
        - 컨테이너 종료 시에도 하드 드라이브 폴더가 그대로 유지
        - 여러 개의 컨테이너에 연결될 수 있음

## Bind Mounts(바인드 마운트)

- `-v /absolute_path_code:/app/data`
- 영구적이고 편집 가능한 데이터
- 호스트 머신의 파일 시스템 상에 어디에 존재하는지 그 위치를 알 수 있음
    - 호스트 머신 상에 매핑될 컨테이너 경로를 설정
- 여러 개의 컨테이너에 연결될 수 있음
- 저장된 데이터를 삭제하려면 로컬 데이터를 직접 삭제 해야 함
- 도커에 의해 관리되는 볼륨이 아니기 때문에 볼륨 리스트에 없음
- Copy와의 차이
    - Copy는 스냅샷 →  배포 시에 필요(로컬 환경을 참조할 수 없음)
    - 바인드 마운트 → 실시간 반영(개발환경)

## APP에 적용하기: Permanent Data

### DockerFile

```docker
FROM node:14 # 가져올 기반 app : ver

WORKDIR /app # 작업 dir

COPY package.json . # app의 종속성을 포함하는 package.json파일 작업 dir에 복사

RUN npm install # package.json에 언급된 모든 종속성 설치

COPY . . # 나머지 코드 복사, 첫번째 . : 현재 dir - 두번째 . : 작업 dir

EXPOSE 80 # 포트 노드<-포트 80에서 수신대기

CMD [ "node", "server.js" ] # node 실행파일을 사용하여 server.js실행
```

### Terminal

```bash
docker build -t feedback-node . # feedback-node라는 이미지 태그를 담(-t)
# latest태그는 고유태그 없으면 자동할당, 항상 한개의 latest만 존재
docker run -p 3000:80 -d --name feedback-app --rm feedback-node 
# -p 내부포트 80을 외부포트 3000에 게시
# -d detached mode, 컨테이너를 실행한 직후 터미널 사용 가능
# --nmae 이름지정
# --rm 컨테이너를 중지할 떄마다 자동제거
docker ps # 현재 실행중인 컨테이너 확인 가능
docker stop # 
```

### awsome.txt

- feedback에 저장하는 코드를 활성화해서 웹(실행중인 컨테이너)에서는 접근이 가능
    - 그러나, 로컬에서는 찾을 수 없음 → 도커 컨테이너 내부에만 존재
    - 로컬 폴더를 이미지에 복사 → 그 복사한 이미지 기반으로 컨테이너가 실행됨
        - `COPY . .` : 일회성 스냅샷 복사
        - 로컬폴더를 기반으로 하는 자체 파일 시스템 존재(로컬과의 연결X) : 컨테이너는 격리되어야
        - 스냅샷이 복사된 격리된 파일 시스템을 가짐
            - 스냅샷이란
                
                특정 시점에 데이터 저장 장치(스토리지)의 파일 시스템을 포착해 별도의 파일이나 이미지로 저장, 보관하는 기술
                
                [참고] [스냅샷과 백업의 차이](https://leinoi.tistory.com/9)
                

### 볼륨 추가하기

```docker
FROM node:14 # 가져올 기반 app : ver

WORKDIR /app # 작업 dir

COPY package.json . # app의 종속성을 포함하는 package.json파일 작업 dir에 복사

RUN npm install # package.json에 언급된 모든 종속성 설치

COPY . . # 나머지 코드 복사, 첫번째 . : 현재 dir - 두번째 . : 작업 dir

EXPOSE 80 # 포트 노드<-포트 80에서 수신대기

VOLUME ["/app/feedback"] # **anonymous vloume**

CMD [ "node", "server.js" ] # node 실행파일을 사용하여 server.js실행
```

```bash
docker logs feedback-app # 실행결과 확인, err 확인
docker run -d -p 3000:80 --rm --name feedback-app -v feedback:/app/feedback feedback-node
# named volume : feedback이라는 볼륨 
```

### 바인드 마운트 추가하기

```bash
docker run -d -p 3000:80 --rm --name feedback-app -v feedback:/app/feedback -v :/app feedback-node
# 두번째 -v: -v "컨테이너의 app과 바인딩할 호스트머신 폴더의 절대경로:/app"
# 바로가기 : 절대경로 대신 사용 가능
macOS / Linux: -v $(pwd):/app
Windows: -v "%cd%":/app
```

- 도커가 컨테이너의 app과 바인딩할 호스트 머신 폴더에 접근할 수 있는지 확인
    - docker Preferences - resources - file sharing 여기에 리스팅 되는지 확인
        - 없다면 추가

### .dockerignore

이미지 Copy 목록에서 제외하기 위해 적는 것(`.gitignore`와 같은 기능)

### ENV와 ARG

- **ENV(environment variables)** : run-time `--env or --ENV`
    - Dockerfile 내부, 소스코드(app) 내에서 접근 가능
    - Dockerfile 내부 ENV로 설정
    - 환경변수를 여러 개 지정할 때는 `-e`
    - 지정할 환경변수가 많을때는 `.env`파일로 지정
        - `--env-file .env`  을 cmd 명령어 뒤에 붙여주면 됨
- **ARG(arguments)** : build-time `--build-arg`
    - 이미지 빌드 과정에서 설정
    - Dockerfile 내부에서만 접근 가능
        - 프로그램 코드나 cmd 상에서는 접근 불가
    - Dockerfile 내부 ARG로 설정
- 코드를 쓸 때 순서를 신경 쓰는 것이 좋음
    - ARG를 `npm install` 전에 사용하면 ARG를 바꿀때마다 다시 설치해줘야함
        - ex) port번호

### Errors &

- cross-device link not permitted
    - 도커는 실제로 파일 컨테이너 파일 시스템 내부의 다른 폴더로 이동하지 X → 밖으로 이동
    
    ```bash
    docker rmi [image_name]
    ```
    
- 익명 볼륨 제거 하기
    - docker 실행 시,  `--rm` 옵션을 주지 않으면 익명 볼륨이 자동 제거되지 않음
    - `docker rm [container_name]` 으로 컨테이너를 제거해도 제거되지 X
    
    ```bash
    docker volume rm [VOL_NAME]
    docker volume prune
    ```
    
    - 실행 중인 컨테이너에서 볼륨을 사용하고 있으면 그 볼륨은 삭제 불가
- cannot find module ‘express’
    - 노드 코드가 실행되지 X → 중요한 종속성 X : 바인드 마운트 추가 시에 생기는 문제
    - 마운트를 컨테이너에 바인딩하면 필요한 종속성을 설치한 이후에  app폴더의 모든것을 로컬 폴더로 덮음 → 로컬에 필요한 종속성이 없기 때문
    - 도커 컨테이너에 익명 볼륨을 추가하는 형태로 해결이 가능
    
    ```bash
    docker run -d -p 3000:80 --rm --name feedback-app -v feedback:/app/feedback \
    -v "%cd%":/app feedback-node\
    -v /app/node_modules # dockerfile에 VOLUMNE [ "app/node_modules"]락 작성하는것과 같음
    # 위의 장점은 이미지 리빌드를 하지 않아도 됨!
    ```
    
- Nodemon : NodeJs
    - 파일이 변경될 때마다 자동으로 서버 재실행
- 읽기 전용
    - 해당 폴더 혹은 하위 폴더에 write 할 수 없음
    
    ```bash
    -v "%cd%":/app:ro
    ```
