

## Laravel & PHP Setup 이라는 1시간 남짓 강의

- 일단 Laravel, PHP가 뭘까?
    - 역시나 관련 개념이 필요 없다고 함.. 찝찝
- 강사는 Laravel이라는 애플리케이션을 만들기 위해 도커 외에 어떤 도구도 설치할 필요가 없는걸 보여준다고 함


### Target 설정

- 도커는 모든 기술, 특히 모든 웹 기술에 적용 가능
- Laravel은 대표적인 PHP 프레임워크라고 함
- Laravel은 매우 복잡한 설정을 요구함
    - 먼저 PHP 설치 후 서버 구축 필요. 이 서버에 DB도 붙여야 함
    - 강의에선 PHP interpreter, Nginx Web server, Mysql DB를 각 컨테이너로 구성할 계획
    - 이건 상시 실행되는 컨테이너
    - 기본적인 유틸리티 컨테이너도 필요
        - Composer, Laravel Artisan, npm
    - 총 6개의 컨테이너
- 이 모듈에서 달성하려는 타겟: Laravel이라는 애플리케이션을 만들기 위해 도커 외에 어떤 도구도 설치할 필요가 없다는걸 확인


### 실습

- 빈 폴더에 docker-compose.yaml 작성 시작
    - 앞에서 6개 컨테이너 필요하다고 했음 -> composer에서도 6개 services 작성

- server
    - nginx라는 웹 서버 기반. 공식 이미지 있음
    - `image: nginx:stable-alpine`
    - 이 웹 서버의 포트를 노출시켜야 함. 공식 이미지 페이지가면 80 포트 노출 언급되어 있음
    - 이 이미지에 의해 내부적으로 노출되는 포트가 80이라는 것
    - 로컬 호스트 머신의 8000번 포트와 컨테이너의 80번 포트를 연결시켜줌
    - 이제 무슨 액션을 해야할지 입력해줘야 함
    - volumes 키로 바인드 마운트 시킴. 읽기 전용으로 설정 `ro` 태그 추가
    - nginx.conf 파일에선 포트 80에서 수신 대기하는 구성이 있음
    - 나머지는 결국 사용자가 특정 url에 접근하면 이러이런 액션을 하겠다~ 정도의 내용인 것 같은데
    - **처음부터 하기 어려울텐데, 결국 공식 문서 보면서 빌드하는게 정답**

- php
    - `php.dockerfile`을 `dockerfile` 폴더 내 하위 경로에 생성
    - CMD, ENTRYPOINT가 없이 RUN으로만 끝남
    - 이러면 베이스 이미지의 디폴트 CMD를 실행함.
    - 이제 composer에서 이 dockerfile 참조할 수 있게 해야함
    - `context`와 `dockerfile`로 각각 폴더, 파일명 지정해줌
        - `dockerfile` 플래그에 그냥 전체 경로/파일명을 지정하면 안되나? 왜 context 가 필요할까?
    - 중요한건 PHP가 소스 코드에 접근할 수 있게 해야함 (지금은 없음)
        - 바인드 마운트 필요!
        - `src`란 폴더 생성. 여기에 바인드 마운트 시킴
    - 포트도 중요함. nginx.conf에서 설정한 포트는 `php:3000`임. composer에 올릴거라 `php`라는 서비스 명칭을 그대로 가져다 씀
    - 근데 왜 3000번? 깃헙 내 php 도커 이미지 페이지에서는 9000번 노출시킴
    - nginx 파일의 3000번 포트를 9000번 포트로 변경 필요
        - 왜..? 이해 못했음

- mysql
    - 몽고디비와 매우 유사함
    - `image: mysql:5.7`
    - 아이디, 비밀번호 등의 환경 변수 설정 필요 -> `.env`에서 관리

- composer
    - entrypoint 지정하기 위해 custom dockerfile 필요
    - workdir로 아까와 같이 html 폴더로 설정. 이 html 폴더에 소스코드가 들어갈 예정

- 일단 여기까지 한걸로 Laravel 애플리케이션 만들 수 있음

***

- composer 컨테이너 먼저 실행하면서 Laravel 페이지에서 복사한 코드도 같이 실행
    - `docker-compose run --rm composer create-project --prefer-dist laravel/laravel .`
    - 중간에 entrypoint 잘못 입력해서 다시 빌드 후 run 시킴
    - 설치 끝나면 src 폴더에 뭐가 여러개 생김. 이게 Laravel 프로젝트라는건가...
    - 뭔가 app도 있고 하는 것 보니 장고와 유사한 구조인 것 같아 익숙하다

***

- `src/.env` 먼저 탐색. 여기에 mysql DB 연결에 필요한 정보 나와있음
    - DB_DATABASE, DB_USERNAME, DB_PASSWORD 수정
    - DB_HOST 도 mysql 로 수정
- 이제 이 앱 실행
- 그 전에 server 서비스에서 소스코드를 참조할 수 있게 볼륨 추가 필요
    - `./src:/var/www/html`
- 다시 서비스 시작
    - server, php, mysql 만 실행시키고자 함
    - `docker-compose up server php mysql`
    - nginx 만 종료됨. 이거 수정은 이해 못함.
    - 여튼 수정 후 `docker-compose down`으로 컨테이너 종료시키고 다시 시작
    - `localhost:8000` 접근하면 Laravel 시작화면 표시됨

***

- server만 up 시키면 나머지 두 개 시작되게 하면 더 편리할 듯
    - `depends_on` 추가
    - server 서비스 불러올 때 의존하는 서비스도 자동으로 실행
    - 내가 잘못알고 있었구나.. depends on하는 서비스가 실행되어야 해당 서비스가 실행되는 의미인줄 알았다. 이 서비스 실행 전 depends on에 있는 서비스 시작한다는 의미

***

- docker compose 단에서 작업한게 이미지 재빌드 필요한 경우, 아래 옵션 추가
    - `--build`
    - `docker-compose up -d --build server`

***

- 에러 대응
    - (오타) nginx.conf의 php 포트가 9000 바라봐야 하는데 0000으로 되어 있었음
    - `Parse error: syntax error, unexpected '|', expecting variable (T_VARIABLE) in /var/www/html/vendor/nunomaduro/termwind/src/Functions.php on line 17`
        - 이건 php 버전 이슈라고 함. php.dockerfile 에서 8.1 버전 불러오도록 하니 해결됨

***

- artisan 컨테이너
    - 이것도 유틸리티 컨테이너
    - 커스텀 도커파일 필요한데 그냥 php.dockerfile 가져다 써도 무방
    - 소스코드에 대한 볼륨도 붙여야 함. 바인드마운트 시킴
    - php 이미지에 entrypoint 추가로 필요한 상황
    - docker-compose에서 이걸 해결
    - `entrypoint: ["php", "/var/www/html/artisan"]`

- npm
    - 노드 이미지 가져오고
    - `working_dir: /var/www/html`
    - `entrypoint: ["npm"]`
    - 볼륨도 붙임

***

- artisan 실행
    - `docker-compose run --rm artisan migrate`
- npm은 따로 실행 x

***

- Dockerfile 명령어를 docker-compose에 추가하는 것에 대해
    - working_dir, entrypoint 같은 것들
    - 강사 개인적으론 extra dockerfile을 선호한다고 함

- server 서비스의 nginx에 대해
    - 두 폴더를 바인드 마운트 시킴
    - `/src` 폴더는 다른 서비스에서도 바인드 마운트 되어 있음
    - 컨테이너 배포할거면 바인드마운트 신중해야 함
    - 배포한 환경에서의 경로는 지금 입력된 로컬 경로와 다르기 떄문
    - 컨테이너의 근본적 취지는 **필요한 모든 것을 컨테이너 안에서 해결하자**는 데에 있음
    - 바인드마운트는 필수거나 있어보이는 그런게 아니라, 개발을 편하게 하기 위한 장치에 불과함

***

- `nginx.dockerfile` 생성.
- 이걸 왜 하는거지? 바인드 마운트로부터 독립하기 위해! dockefile로 소스 코드 스냅샷을 이미지에 복사하게끔 설정
- 자세한건 건너뜀..
    - 개발을 깊게 못하기 때문에 바인드 마운트 심화보다는 배포에 더 신경쓰는게 맞음.
