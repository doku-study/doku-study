
- 이미지&컨테이너란 ? 왜 사용하는가 ? 

이미지는 모든 설정 명령과 모든 코드가 포함된 공유 가능한 패키지입니다.
컨테이너는 그러한 이미지의 구체적인 실행 인스턴스입니다.
즉, 우리는 이미지를 기반으로 하는 컨테이너를 실행

- 이미지를 생성하고 가져오는 방법 
    - Docker Hub 이미지 활용 
    - docker run node : node 라는 이미지를 기반으로 하는 컨테이너 실행 

- Dockerfile
    - docker 에 의해 식별되는 이름 
    - 역할 : 자체 이미지를 빌드할 때 실행하는 명령어와 설정이 저장되는 파일
    - 예시
    - FROM node:12
    - 
    - WORKDIR /app
    - 
    - COPY package.json /app
    - 
    - RUN npm install
    - 
    - COPY . /app
    - 
    - EXPOSE 80
    - 
    - CMD ["node", "server.js"]
    - 명령어 설명 :  https://docs.docker.com/reference/dockerfile/
        - FROM [이미지 이름] : 해당 이미지를 기반으로 이미지 생성 - 로컬에 다운로드 됨 
        - COPY [경로1] [경로2] : 이미지의 특정 경로로 복사되어야할 파일이 있는 host file system 경로를 알려주는 역할 
            - 경로1 : host file system , 경로 2: Image/container file system  
            - 만약 경로1에 .을 적으면 Dockerfile이 있는 경로와 동일함을 의미함, 
            - 경로 1에 있는 모든 파일과 하부 파일이 컨테이너 내부 파일 시스템의 경로2에 복사됨 
        - WORKDIR [디렉토리]: 도커 컨테이더의 작업 디렉토리 설정, 해당 명령어 이후의 모든 명령어는 여기에서 설정한 작업 디렉토리에서 실행됨
        - RUN [명령어]: 도커 컨테이너 내부에서 실행하고자 하는 명령어 
            - 도커 컨테이너 및 이미지의 작업 디렉도리(container file system의 root 폴더)에서 실행됨 
        - CMD [명령어] : 컨테이너가 시작될 때 실행되는 명령어 
            - RUN과의 차이점 : RUN은 이미지가 생성될 때 실행, CMD는 컨테이너가 시작될 때 실행 
            - 명령어 형태는 띄어쓰기를 기준으로 str을 리스트에 담아서 전달 
        - EXPOSE [포트번호] : 로컬 시스템에 노출하고자 하는 특정 포트번호 전달 
            - 컨테이너와 로컬 머신은 격리되어 있음, 만약 컨테이너 내부의 애플리케이션에서 포트 80을 통해 수신하고 있다면 해당 포트번호를 로컬머신에도 알려줘야함 
            - 하지만 EXPOSE 명령어는 단지 문서화를 위한 목적, 따라서 EXPOSE 에 컨테이너 포트번호를 추가하는 것만으로는 애플리케이션이 제대로 실행되지 않음 
            - 컨테이너 실행시 run 명령어에 -p 인자로 전달해줘야 함, -p [로컬 포트번호]:[컨테이너 포트번호] ex: -p 3000:80 

    - Dockerfile을 이용하여 이미지 build 하기
        - dockerfile이 있는 경로에서 docker build .
        - 또는 -f, --file 인자로 dockerfile 경로 전달 

- 이미지에서 컨테이너 만들기 : docker run 
    - 실행 시 항상 모든 도커 이미지의 이름/아이디를 다 쓸 필요 없음 , a로 시작하는 다른 이미지 id가 없으면 docker run a 만 쳐도 됨 
    - run 명령어 인자 
        - -it : 컨테이너 내부에서 호스팅 머신으로 대화형 세션을 노출하고 싶다 - 컨테이너 터미널로 들어가고 싶다

- 코드 변경 이후 컨테이너를 다시 시작했는데도 변경사항이 적용이 안된다면 ? 
    - Dockerifile 의 COPY 명령어를 통해 이미지가 빌드 될 때 당시의 코드 스냅샷을 저장하기 때문. 
    - 따라서 기본적으로는 이미지는 읽기 전용, 코드는 빌드 당시의 스냅샷이므로 코드를 변경했디면 이미지를 재빌드해야함 
    - 이 방법만 있는 건 아니고 코드 변경시 복사할 수 있는 다른 방법 있음 

- 이미지 레이어 
    - 코드를 변경하지 않고 이미지를 재빌드하면 Using cache라는 메시지와 함께 빌드가 매우 빠르게 끝남 
    - 도커는 이미지를 빌드할 때 마다 모든 명령에 대한 결과를 캐싱하고 명령을 다시 실행할 필요가 없으면 캐시된 결과를 사용함 
    - 이를 “레이어 기반 아키텍쳐”라고 부름 , Dockerfile의 모든 명령은 Dockerfile의 레이어를 나타냄 
    - 만약 하나의 레이어가 변경된다면, 해당 레이어 변경 이후의 다른 후속 레이어가 다시 빌드됨 (이전과 다른 결과를 낼 수 있으므로)
    - 이미지 생성속도를 높이기 위해 도커는 다시 실행해야하는 부분만 다시 빌드하여 실행 
        - ex ) 코드를 변경한 후 이미지를 재빌드한다면 COPY 명령어에서는 cache를 사용하지 못함, COPY 명령어 다음에 작성된 RUN npm install 명령어도 재빌드 

- Dockerfile 최적화 방법 
    - 이미지 재빌드 시 다시 빌드되지 않아도 되는 명령어는 재빌드 되어야하는 명령어보다 위에 작성 
        - ex ) 일부 코드 변경 이후 프로젝트의 종속성이 변화하지 않는다면 RUN npm install 은 COPY 명령어 이전에 적으면 됨
    - 이는 이미지가 레이어기반으로 동작하기 때문에 가능하다!  

- 이미지&컨테이너 관리

    - 이름 지정 
        - 컨테이너 : docker run 시에 --name 인자 사용 
        - 이미지 : 
            - 이미지 이름의 구성 -  name : tag 형태 , tag는 같은 name을 가지는 이미지 그룹의 보다 특정화된 버전 정의 
            - docker build 시에 -t 인자 사용 
    - 실행중인 컨테이너 보기 : docker ps 
    - 중지된 컨테이터까지 모든 컨테이너 보기 : docker ps -a 
    - 컨테이너 중지 : docker stop [container name / id]
    - 중지된 컨테이너 재시작 : docker start [container name / id]
        - docker run  : attached 모드가 디폴트(컨테이너의 출력 결과(로그)를 수신하여 터미널에서 확인할 수 있음) / docker start : detached 모드가 디폴트 
        - docker run -d  : detached mode run 
        - docker start -a : attached mode start 
    - docker logs [컨테이너 name / id] : 해당 컨테이너의 로그 결과 가져올 수 있음 , -f 인자: follow - 향후 로그 출력결과 계속 가져옴 

    - 컨테이너 interactive mode
        - run 할 때 
        - -i : interative mode , attached mode가 아닐 때에도 컨테이너에 입력 가능 
        - -t : pseudo tty 터미널 할당 
        - -it 결합 : 입력 수신 및 터미널 생성 
        - start 할 때 : docker start -a -i 

    - 삭제 
        - docker rm [컨테이너 name / id] [컨테이너 name / id] ... 
        - 이미지 삭제 : rmi / 컨테이너 삭제 : rm
        - 사용하지 않는 모든 이미지 삭제 : docker prune 
        - 중지된 컨테이너 자동 제거 : --rm  인자 run 명령어에 추가 , docker stop 하면 바로 삭제됨 

    - 파일 복사 
        - docker cp : 실행 중인 컨테이너로 / 컨테이너 밖으로 파일/폴더 복사 
        - docker cp [컨테이너]:[컨테이너 경로] [로컬 경로]
        - 코드 변경 시 이미지 재빌드 작업 대신 변경 파일 컨테이너로 복사 가능 (추천 안함)

    - 이미지 검사 
        - docker image inspect [이미지 이름 / id]
        - 이미지 전체 id, 생성 날짜, 이미지를 기반으로 시작되고 실행될 컨테이너의 구성(포트, 환경변수, ENTRYPOINT 명령어 등), 레이어 구성 

    - 이미지 공유 
        - Dockerfile 공유 또는 docker hub 에 이미지 공유 
        - docker hub에 이미지 push 하기 - 이미지 명에 dockerhub user name 들어가있어야 함 - 이름 포함해서 재빌드하기 
            - docker push [dockerhub user name]/[name:tag]
        - 이미지를 push 할 때에는 전체 이미지를 push 하는 것이 아님 
        - 만약 base 이미지가 docker hub 에 있다면 해당 이미지에 대한 연결을 설정하여 필요한 추가 정보만 push 
    - 이미지 다운 
        - docker pull 
        - 'docker run'은 로컬 시스템에 찾는 이미지가 없다면 히스토리를 검색해 자동으로 이미지를 풀링
        - 로컬 시스템이 찾는 이미지가 있다면 그게 최신 버전인지 아닌지 상관없이 풀링하지 않고 그걸 사용