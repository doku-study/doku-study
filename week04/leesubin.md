# 섹션 4: 네트워킹: (교차) 컨테이너 통신
- 컨테이너는 외부 네트워크와 통신할 수 있나?
	- ex. https://api.kingsubin.com 
	- 특별한 네트워크 설정 없이도 가능함.
	- fetch("https://api.kingsubin.com")
- 컨테이너는 로컬 호스트 머신과 통신할 수 있나?
	- ex. 로컬 호스트 머신에 설치된 DB
	- db.connect("localhost:3306") 실패함.
	- localhost 대신 `host.internal.network` 를 사용하면 가능함.
		- db.connect("host.internal.network:3306")
		- Docker 가 소스 코드를 수정하는 게 아니라, 요청을 감지하고 IP 를 리졸빙함.
- 컨테이너끼리 서로 통신할 수 있나?
	- 서로 통신하려는 컨테이너의 IP 를 알면 할 수 있음.
		- `docker container inspect CONTAINER_NAME`
		- 매번 컨테이너의 IP 주소가 바뀌고, 찾기도 번거로움.
		- 그럼 어떻게 쉽게?
			- Docker network 를 써라.
				- `docker network create my-network`
				- `docker run --network my-network ...`
				- 통신하려는 컨테이너들이 같은 네트워크에 있으면 IP 대신 container name 을 사용할 수 있음.
				- db.connect("my-mysql-container:3306")


# 섹션 5: Docker로 다중 컨테이너 애플리케이션 구축하기
- api-server, client, db 3가지로 이루어진 container 를 실행해보자.
1. 컨테이너를 연결할 네트워크 생성
	- 컨테이너끼리 통신할 네트워크 생성
	- `docker network create my-network`
2. 컨테이너 이미지 빌드
	- `docker build -t api-server --env DB_USERNAME=something --env DB_PASSWORD=something .`
	- `docker build -t client .`
	- `docker build -t db .`
4. 실행
	- db
		- 데이터를 저장할 볼륨 설정
		- api-server container 와 통신할 네트워크 설정
		- `docker run --name db -v data:/data/db --rm -d --network my-network db`
	- api-server
		- 로깅을 저장할 볼륨 설정
		- db container 와 통신할 네트워크 설정
        - client container 와 통신하기 위한 포트 설정
		- `docker run --name api-server -v logs:/app/logs --rm -d -p 80:80 --network my-network api-server`
	- client
		- 외부와 통신하기 위한 포트 설정
		- `docker run --name client -p 3000:3000 client`