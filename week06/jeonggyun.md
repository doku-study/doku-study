# 새롭게 알게된 것

- Dockerfile에 CMD나 ENTRYPOINT가 따로 명시되어 있지 않다면, FROM에 사용된 베이스이미지의 CMD나 ENTRYPOINT가 적용된다.
- docker compose에서 Dockerfile을 build할 때, Dockerfile의 이름이 “dockerfile”이 아니라면, 아래와 같이 작성해준다.
    
    ```yaml
    php:
    	build:
    		context: <dockerfile이 있는 폴더>
    		dockerfile: php.dockerfile
    ```
    
- docker-compose에 포함된 컨테이너들은 모두 동일한 네트워크에서 실행 되며, service의 이름으로 서로의 통신이 가능하다.
- docker-compose run <service> 를 통해, docker-compose.yaml파일에 있는 특정 service를 개별적으로 실행시킬 수 있다.
- `docker-compose up` 명령어를 사용할 때, 특정 컨테이너를 제외한 다른 컨테이너들만을 실행하고 싶을때는, `docker-compose up server php mysql` 이렇게 뒤에 원하는 서비스들을 명시하면 된다.
- 특정 서비스만 실행하면 다른 서비스도 실행될 수 있도록 하기 위해 종속성을 넣을 수 있다.
    
    ```yaml
    depends_on:
          - php
          - mysql
    ```
    
- 기본적으로 docker-compose는 서비스에서 빌드를 필요로할 때 dockerfile의 변경사항을 트래킹하지 않고, dockerfile로 빌드된 이미지가 있다면 새롭게 빌드하지 않는다. 수동적으로 리빌딩 해 줄 필요가 있다.
    
    ```yaml
    docker-compose up -d ***--build*** server
    ```
    
- docker-compose에서 특정 dockerfile을 빌드 할 때, 해당 dockerfile을 수정하지 않고, docker-compose에서 dockerfile에 적용될 entrypoint를 작성할 수 있다.(오버라이드 할 수 있다.)
    - 동일한 개념으로 WORKDIR → working_dir로 접근할 수 있다.
- 바운드 마운트는 개발할 때만 지향. 배포시에는 모든 필요 리소스들이 이미지내에 구축되어 있어야 한다.
- docker-compose에서 dockerfile을 빌드하는 service가 있을 때,
    
    ```yaml
    services:
    	server:
    		build:
    			context: ./dockerfiles
    			dockerfile : server.dockerfile
    ```
    
    - 만약 server.dockerfile에 COPY나 WORKDIR과 같이 경로가 포함되어 있을 때, 그 경로가 context보다 더 상위 경로 일 때, dockerfile은 이미지로 빌드될때 해당 상위경로를 찾을 수 없어 빌드가 실패된다.
    
    ```yaml
    services:
    	server:
    		build:
    			context: .
    			dockerfile : dockerfiles/server.dockerfile
    ```
    
    - 이렇게 context는 dockerfile에 있는 그 어떤 경로보다 더 상위폴더에 두도록 하자.
- 컨테이너가 실행되고, 해당 컨테이너 내에 있는 폴더나 파일에 대한 수정이 필요할 때, 권한이 거부될 수 있다. 이럴 때는 아래와 같이 권한을 풀어주자
    
    ```yaml
    RUN chown -R www-data:www-data var/www/html# php에서 기본 유저는 www-data이다. 일기:쓰기 권한을 부여해 준것
    ```
    
    - 이는 php.dockerfile에서 COPY명령어에 대한 권한이 막혀있어서 난 에러를 해결하기 위한 솔루션이다.