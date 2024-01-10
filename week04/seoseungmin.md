

## 다룰 것

- 컨테이너 내부에서 네트워크 사용하는 방법
- 다중 컨테이너끼리 통신하는 방법


## 네트워크와 request

- 애플리케이션이 포함된 컨테이너 가정
- 이 app이 www의 웹 사이트와 통신하려고 함 (데이터 가져오기 위함)
- GET HTTP 요청을 해당 웹 API로 보낼 수 있음
- 도커화된 앱에서 가능한 한가지 통신 방법: HTTP 요청을 다른 웹사이트나 웹 API로 전송하는 방법

- 또는 호스팅 머신, DB 등과도 통신 가능
- 공통점은 컨테이너 외부와의 뭔가와 주고 받는 것

- 호스트 머신의 몽고 디비에 연결하는 부분

`mongoose.connect('mongodb://localhost:27017/xxx)...`

- 컨테이너 내부를 바라본다면 경로가 어떻게 될까?

- 컨테이너 -> www
- 컨테이너 -> 호스트 머신
- 컨테이너 -> 다른 컨테이너

- 도커에선 한 컨테이너가 하나를 수행하는 것이 강력히 권장됨
- 그러다보니 다중 컨테이너간 네트워킹이 필수



- 몽고DB 설치. 이미지로 다운 받을 수 없나?
    - 설치하고 노드 코드 실행하면 DB에 연결 바로 된 것 같은데, 뭐 DB를 생성 안해도 되는건가?
- postman 으로 요청-응답 테스트 (로컬에서!)
- 이 어플리케이션으로 뭘 하려는지 보여주기 위함
- 곧 컨테이너에 넣을 것

## 도커화

- 먼저 도커 데스크탑 실행
- 강의 자료 압축 푼 경로로 이동해서 `docker build -t favorites-node .`로 미리 작성된 Dockerfile로 이미지 빌드함
- `docker run --name favorites --rm -p 3000:3000 favorites-node`
    - 볼륨 불필요. 컨테이너 종료 및 제거에서 살아남을 파일이 없음. 몽고DB에 필요한건 저장하는데 이 DB는 컨테이너의 일부가 아님
    - 로그 보기 위해 attached 모드로 시작
- `app.listen(3000)`만 몽고DB 커넥트 함수 밖으로 빼내고, 이 커넥트 코드 주석처리해서 다시 컨테이너 실행해보면? 나머지 API 요청이 잘 되는지 확인하고자 함
- 소스코드 변경 했으니 이미지 다시 빌드해야 함
    - `docker run --name favorites -d --rm -p 3000:3000 favorites-node`
    - 그리고 컨테이너 생성 & 실행
- postman 설치하고 'New' 클릭해서 `localhost:3000/people`에 GET 요청을 보내면 응답이 옴
    - 이 경로는 방금 실행시킨 컨테이너의 내부 3000 포트와 닿아있음. 그래서 API 응답이 오는 것
    - 네트워크 참 신기해..
- 기본적으로 컨테이너는 www에 요청을 보낼 수 있음. 왜?
    - 강의에선 이 개념이 중요하다는데, 왜?
    - 아마 컨테이너를 배포하면 웹 상에서 배포된 컨테이너의 앤드포인트에 닿을테니까..?
    - 로컬에 있는 다른 컨테이너와 통신할 일보단 배포된 컨테이너와 통신할 일이 많을까?


- 원래 코드를 실행하려면, 몽고DB가 설치된 별개의 컨테이너를 띄워야 하나?
    - 그럴 필요 없이 `localhost`를 도커가 이해하는 구문으로 바꾸면 된다고 함
    - `host.docker.internal`
    - localhost로 이미지 빌드할 경우, 해당 컨테이너를 로컬로 인식, 컨테이너의 포트를 가져다 쓰는 셈. 호스트 머신이 아니라..!
    - 일단 코드 바꿨으니 이미지 다시 빌드 (바인드 마운트하면 다시 빌드할 필요 없음)
- 몽고DB가 로컬에 설치되어 있어야 하는데, 방법을 모르겠음. 그래서 컨테이너 강제 종료됨
- 여튼 이런 방식으로 컨테이너 -> 호스트 머신으로 통신할 수 있다고 함


### 컨테이너 - 컨테이너

- 마지막 통신은 컨테이너 - 컨테이너 통신
    - 모든 컨테이너는 한 가지에만 집중하는게 좋음. 하나는 노드앱, 하나는 몽고DB
- 몽고DB를 컨테이너에 넣어야 함
    - 다른 Dockerfile을 작성? 그럴 필요 없음. 몽고DB 이미지를 가져다 쓰면 됨
- `docker run -d --name mongodb mongo`: 몽고DB 이미지 기반으로 새 컨테이너 생성함
- 이제 노드앱 있는 소스코드 변경하면 됨
- `docker container inspect {컨테이너 이름}`로 컨테이너의 `IPAdress`를 찾을 수 있음. 이걸로 연결하는 것
    - "172.17.0.2"를 `host.docker.internal`에 덮어씌움
- 다시 이미지 빌드 후 컨테이너 실행하면 두 개 컨테이너 확인 가능해야 함
- postman에서 `localhost:3000/favorites`에 GET 요청
    - mongodb 컨테이너에 있는 새로운 몽고DB 데이터베이스라 빈 값을 응답함
- 강사는 번거롭다고 하는데 공감 못함. 여튼 IP 주소 찾는 것도 실무에선 번거로울 수 있으니..!
    - mongodb 컨테이너 ip 주소가 변할 때 마다 이걸 하드코딩 해줘야 하니까
- 이걸 유연하게 통신하는 방법을 다음 강의에서 다룸


## 유연한 다중 컨테이너 통신

- `docker run` 명령에 `-=network` 옵션을 추가하면, 모든 컨테이너를 하나의 동일한 네트워크에 밀어넣을 수 있음
    - ip 주소를 하드코딩 할 필요 없음
- 두 컨테이너 중지 & 제거 필요
    - `docker stop {}`
    - `docker container prune`: 중지된 모든 컨테이너 제거
- 네트워크 옵션 주기 전에 네트워크 생성해야 함
    - `docker network create favorites-net`
- `docker run -d --name mongodb --network favorites-net mongo`
- 다른 컨테이너도 이 네트워크에 속한 채로 run 시킴
- 남은건 NodeJS 코드를 어떻게 수정할지?
    - 그냥 이름! 그럴 줄 알았다
- `docker run --name favorites --network favorites-net -d --rm -p 3000:3000 favorites-node`

- 컨테이너 간에는 일반적으로 서로 통신할 수 없음
    - 동일한 컨테이너 네트워크 생성 & 집어넣거나
    - 컨테이너 IP를 수동으로 조회하면 됨
- 이게 일반적이며 흔한 케이스라고 함. 보통 이렇게 한다고 생각하면 됨

- mongodb 컨테이너 생성 & 실행 할 때 포트 노출시키지 않았는데, 그 이유?
    - 일반적으로 포트 노출은 로컬 호스트 머신이나 컨테이너 외부에서 컨테이너에 연결하려는 경우에만 필요함



## 5강. Docker로 다중 컨테이너 애플리케이션 구축하기

- 제목만 봐도 힘들겠다..
- 일반적으로 애플리케이션은 함께 작동하는 여러 서비스로 구성됨
    - 데이터베이스, 백엔드 웹 서버, 프론트엔드 애플리케이션 등
- 이걸 도커화하는 방법에 대해!


- 세 개의 빌딩 블록
    - 데이터베이스. 애플리케이션에서 생성된 데이터 저장용
    - 백엔드. NodeJS로 만들어진 웹 서버. 단순히 JSON 데이터를 다루는 용도
    - 프론트엔드. React로 구축된 단일 페이지 애플리케이션
- 뭔 말인지 모르곘음. 다만 이게 매우 일반적인 방법이라고 함


- 백엔드는 얼추 이해했으나 프론트는 진짜 뭐라는겨
    - src/App.js 가 프론트엔드 React 코드라고 함
- 로컬에서 실행하는 방법
    - 터미널 여러개 사용해서 backend, frontend 각각 실행시킴
- 독립적인 두 개발 서버가 있는셈

- 이러한 세 개의 빌딩 블록을 도커화 할 때 고려해야 할 것?
    - 몽고DB를 컨테이너에 넣으면, 데이터가 유지되어야 함.
    - 몽고DB의 액세스를 제한해야함
    - 백엔드에서도 데이터가 지속되어야 함. 로그 데이터
    - 백엔드 소스 코드 변경 사항이 즉각 반영되어야 편리함
    - 프론트에서도 소스 코드 변경 시 실시간 업데이트 되게끔

### 데이터베이스 도커화

- `docker run --name mongodb --rm -d -p 27017:27017 mongo`
    - 포트 노출 필요. 백이랑 프론트 아직 도커화하지 않아서
- 백으로 돌아가 `node app.js` 실행하면 연결된다고 함

### 백엔드 도커화

- 백엔드 폴더에 Dockerfile 작성 후 이미지 빌드 
    - `docker build -t goals-node .`로 태그 같이 부여
- 생성된 이미지로 컨테이너 실행 가능
    - `docker run --name goals-backend --rm goals-node`
    - 몽고디비에 연결하지 못해 에러
    - app.js 살펴보면 도커화된 백엔드 애플리케이셔인데 localhost에 접근하려고 해서 발생한 에러
    - `host.docker.internal`로 변경하면 된다고 하는데, 난 몽고디비 로컬에 없음
    - 여튼 이렇게 백엔드 도커화 성공
- 문제는 React 프론트가 백엔드와 통신할 수 없다는 것
    - 백엔드 컨테이너의 포트를 노출시키지 않아서.
    - Dockerfile에 `EXPOSE 80`만으롣ㄴ 안되고, 컨테이너 실행 할 때 옵션으로 줘야함
    - `docker run --name goals-backend --rm -d -p 80:80 goals-node`: 애플리케이션이 컨테이너 내부에서 수신 대기하는 포트:로컬 호스트 포트
- 프론트가 다시 로컬 포트 80에 닿고, 로컬 포트 80은 백엔드 컨테이너 포트 80에 닿으니까 되긴함
- 내 경우엔 몽고디비 커넥션 실패. 로컬에 설치 안되어 있어서 그럼

### 프론트 도커화

- 프론트 용 Dockerfile 작성
- `docker build -t goals-react .`
- `docker run --name goals-frontend --rm -d -p 3000:3000 goals-react`
    - 왜 3000:3000일까? 브라우저에서 접근하려는 포트는 3000인데 이건 localhost를 바라봄. 그럼 프론트 컨테이너의 포트와 로컬 포트 3000을 연결시켜줘해서 3000:3000이 된 것
- `-d` 빼고 실행해서 상태 보면, 개발 서버 가동된 직후에 컨테이너가 중지됨. 왜?
    - React 프로젝트 설정과 관련
    - `-it` 옵셥 넣어서 인터렉티브 모드로 실행햇야 함. React는 이거 안하면 즉시 서버 중지함.
- 난 애초에 백엔드 컨테이너가 안 띄워져있어서 -it 해도 안됨
- 여튼 여기까지만 하면 프론트도 도커화 완료
- 근데 포트 맞닿는건 좀 귀찮고 복잡함
    - 컨테이너 네트워크 생성해서 관리할 필요가 확실히 생김


### 네트워크

- `docker network create goals-net`
- 이제 세 빌딩 블록을 포트 없이 컨테이너 실행
- `docker run --name mongodb --rm -d --network goals-net mongo`
- 백엔드 폴더로 경로 이동 `docker run ~` 하기 전 근데 소스코드 먼저 수정 후 이미지 빌드해야 하지 않나?
    - `backend/app.js`의 몽고디비 커넥트 코드 수정
    - `docker build -t goals-node .`
    - `docker run --name goals-backend --rm -d --network goals-net goals-node`
- 프론트 폴더로 경로 이동
    - `src/App.js`에서 `localhost`라고 되어 있는 부분을 백엔드 컨테이너 이름 `goals-backend`으로 변경
    - `docker build -t goals-react .`
    - 포트는 여전히 필요한게 브라우저에서 localhost:3000으로 통신하기 때문
    - `docker run --name goals-frontend --rm -p 3000:3000 --network goals-net -it goals-react`
- 강의에 표시된 에러를 확인하려면..?
- 프론트 코드는 브라우저에서 실행됨. 브라우저는 `goals-backend`가 뭔지 모름. 이건 그냥 React 특징
    - 백엔드 컨테이너를 로컬과 닿게 해야함
    - 즉, 백엔드 애플리케이션에 포트 80을 게시해야함
- 프론트 소스코드 다시 localhost로 수정 후 이미지 빌드
- 컨테이너 시작 `docker run --name goals-frontend --rm -p 3000:3000 -it goals-react`
- 백엔드 경로로 가서, 백엔드 컨테이너 일단 중지. 다시 시작하되 포트 80 게시하게끔
    - `docker run --name goals-backend --rm -d --network goals-net -p 80:80 goals-node`

- Node.js 버전 관련 에러
    - 강의에선 node:latest 괜찮다 했는데 node:14로 해주면 해결됨

- 코드가 컨테이너에서 실행되지 않고 브라우저에서 실행되는데 이건 React 자체 특징
    - 이 특징 때문에 도커 네트워크로 묶어줘서 포트 붙여줘야 함


### 몽고DB에 볼륨 넣기

- 몽고디비 담긴 컨테이너 중지하면 제거되고, 제거되면 모든 데이터 없어짐
- 컨테이너는 제거되도 데이터는 어딘가에 저장되어야 함
- 몽고디비 컨테이너 문서에서 볼륨 관련 내용 탐색
    - 내부 경로를 찾아서 이걸 로컬에 연결시켜야 함
    - 그 경로가 `/data/db`임
    - named volume을 사용함
- `-v data:/data/db` 옵션 추가
    - `docker run --name mongodb -v data:/data/db --rm -d --network goals-net mongo`
- 이제 아무거나 입력해서 볼륨에 데이터 저장함
- 몽고디비 컨테이너 중지 후 다시 실행
- 이전에 저장한 값이 다시 표시되는 것 확인 가능

### 몽고DB 액세스 제한

- 두 환경 변수 사용할 것
- `docker run --name mongodb -v data:/data/db --rm -d --network goals-net -e MONGO_INITDB_ROOT_USERNAME=max -e MONGO_INITDB_ROOT_PASSWORD=secret mongo`
- 이걸로 컨테이너 실행하고 브라우저 탐색해보면 데이터 가져오기 실패함. 노드 애플리케이션에서 몽고디비 접근할 때 이름, 비밀번호 값이 없어서 실패한 것
- 백엔드 app.js 파일에서 몽고디비 연결 코드의 연결 문자열 조작
    - `mongodb://max:secret@mongodb:27017/course-goals?authSource=admin`
- 이미지 빌드 후 컨테이너 실행
    - 계속 auth 에러 뜨는데 원인을 모르겠네
    - 그냥 auth 부분 들어내고 실행함


### 백엔드 소스코드 라이브 업데이트

- 두가지 할 것: logs 폴더 내 데이터 볼륨 붙이고, 소스코드 바인드 마운트
- 기존 백엔드 컨테이너 중지
- 볼륨 옵션 붙이기
    - `docker run --name goals-backend -v logs:/app/logs --rm -d --network goals-net -p 80:80 goals-node`
    - 컨테이너 내부의 `/app/logs`에 남는 것들을 named volume으로 로컬에 복사함
- 바인드 마운트도 필요함
    - 컨테이너 `/app` 폴더에 있는 모든 것을 로컬 호스팅 디렉토리에 바인딩하려고 함
    - `-v {로컬 경로}:{컨테이너 경로}`
    - `docker run --name goals-backend -v /Users/krafton/doku_study/multi-01-starting-setup/backend/:/app -v logs:/app/logs --rm -d --network goals-net -p 80:80 goals-node`
    - 구체적인 경로가 더 순위가 높다고 배운 기억은 있는데, 그게 여기서 어떻게 영향을 미친다는 걸까?
- 로컬에 node_modules가 없으면 이거 덮어씌우지 않게 조작 필요.
    - `-v /app/node_modules` 로 익명 볼륨 추가
    - `docker run --name goals-backend -v /Users/krafton/doku_study/multi-01-starting-setup/backend/:/app -v logs:/app/logs -v /app/node_modules --rm -d --network goals-net -p 80:80 goals-node`
- `backend/app.js` 코드 수정해도 라이브 업데이트 안됨. 왜?
    - 노드 프로세스는 모든 코드를 로드한 다음 코드 실행
    - 코드 변경되어도 이미 실행 중인 노드 서버에는 영향 없음
    - 그럼 라이브 업데이트 시키리면 코드 변경 될 때 마다 노드 서버 다시 시작시키면 됨.. 천재인데?
- backend 폴더의 package-lock.json 삭제
- packange.json에 뭘 추가로 넣음.
- Dockerfile도 수정 .여기 CMD는 왜 건드릴까?
- 이미지 다시 빌드 & 컨테이너 실행
- `docker logs goals-backend`로 nodemon 로그 확인 가능

- 몽고디비 액세스 키 하드코딩 하는 것 위험
    - Docerfile 와 연결 문자열 수정해서 환경 변수로 키 처리 가능
    - 건너뜀

- .dockerignore 파일까지.
    - node_modules
    - Dockerfile
    - .git

### 프론트 소스코드 라이브 업데이트

- 프론트 실행 중인 터미널 돌아감
- ctrl+C 하면 컨테이너 종료됨
- 컨테이너 실행 시 바인드마운트만 지정
    - `docker run -v /Users/krafton/doku_study/multi-01-starting-setup/frontend/src/:/app/src --name goals-frontend --rm -p 3000:3000 -it goals-react`
- nodemon 불필요. 이것도 React 특징
- 변경 사항 라이브 업데이트 되는 것 확인 가능


- 이미지 빌딩 프로세스
    - 프론트 쪽이 더 오래걸림. 왜?
    - Dockerfile에서 node_modules 중복 복사
    - .dockerignore 파일로 처리 (위와 동일한 내용)


## 요약

- 도커화를 왜 하는걸까
    - 환경을 캡슐화 할 수 있어서
    - 배포 할 수 있어서?
- 꽤 긴 `docker run` 명령어를 여기서도 짚네
    - 다른 스터디원은 .sh 파일로 처리한다고 했는데 강의에선?
    - 같은 방향. 구체적인 방법은 다음 강의에서.

