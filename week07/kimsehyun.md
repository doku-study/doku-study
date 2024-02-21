### Development에서 Production까지

컨테이너에 대한 개념 복습.
independent and standardized application package, 어디서나 동일한 환경에서 코드 구현을 보장.

different development & production environments이라는 문제를 해결해준다.
환경이 컨테이너 내에 있다. 툴을 따로 설치하거나 우리 호스트 머신을 따로 구성해줄 필요가 없다. 대신 application에 필요한 모든 건 다 컨테이너에 있다.

isolated, standalone environment이라는 원칙은 production에서도 적용된다. local host machine에서 운영했던 똑같은 container를 remote machine에서도 shipping하기 때문이다.
reproducible한 environment이고, 공유하고 사용하기 쉽다는 장점이 있다.

그래서 목표는, 우리가 local machine에서 컨테이너 안 application을 가동했을 때와, remote machine에서 deployment했을 때 똑같이 작동해야 한다는 것.
이게 도커의 존립 이유고 지난 강의에서도 계속 강조했던 것. 

### 주의해야 할 점

- local에서는 bind mount를 많이 사용했지만, deployment 단계에서는 이걸 사용해서는 안된다.
- containerized app은 development and production에서 build step이 좀 다를 수 있다. (예: React app)
- 지금까지는 docker-compose를 사용하더라도 하나의 local host machine에서 작동했다. 하지만 배포  단계의 multi-container project에서는 컨테이너도 여러 개이기 때문에 이 컨테이너들을 여러 개의 remote host로 분배해야 할 수도 있다. (might need to be splitted, or should be splitted across multiple hosts / remote machines). 
- Trade-off between control and responsibility might be worth it: 만약 내가 remote machine을 혼자 다 감당하고 관리해야 한다면 그만큼 책임도 늘어나도 관리 부담도 늘어난다. 그래서 less control, less responsibility인 방식을 배울 것이다.


---

### A Basic first example: Standalone NodeJS App

처음엔 아주 간단한 걸로 시작하자. 하나의 이미지, 하나의 컨테이너로만 구성된 아주 간단한 예시다.

- development machine이 있고
- container registry
- remote machine / host
- end user machine

1. remote host에 Docker를 설치하고(SSH를 통해)
2. 이미지 push & pull하기
3. remote host에서 이미지 베이스로 컨테이너 실행
4. 그리고 www에 웹 서비스를 공개, 웹 브라우저에서 테스트

### Hosting Provider 알아보기

도커를 지원하는 hosting provider는 굉장히 많다. 그러나 이 중에 3대장은 다음과 같다.
1. AWS
2. Microsoft Azure
3. Google Cloud

단순한 hosting provider가 아니라 cloud service provider이다. web hosting 뿐만 아니라 web development, machine learning features 등 아주 다양한 기능을 제공한다.

이 중에 본 강의에서는 AWS를 사용할 것이다. 이유는? 가장 점유율이 높은 클라우드 서비스이기 때문.

### AWS EC2
EC2(Amazon Elastic Compute Cloud)는 remote hosting machine 기능을 제공하는 가장 기본적인 클라우드 서비스다.

본 강의 순서는 다음과 같다.

1. EC2 인스턴스(instance)를 생성하고 시작하기. 이때 VPC, 보안 그룹도 생성한다.
2. EC2의 웹 서버를 특정 포트번호로 www에 공개하기 위해 보안 그룹을 설정하기
3. 이 인스턴스에 연결(SSH)한 후, 도커 설치하고 컨테이너 실행하기


### 첨부 파일 참고해서 실행해보자

이미지 빌드한 후,

```bash
# node deployment example image
docker build -t node-dep-example .
```

일단 컨테이너 돌아가는지 테스트해보자.

```bash
docker run -d --rm --name node-dep -p 80:80 node-dep-example
```


### Development vs. In Production: production 과정에서 bind mount를 사용하지 않는 이유

- development 과정(local machine에서 코드 짜고 테스트하는 과정)에선 컨테이너가 실행 환경을 encapsulate해야 하지만 코드 자체는 꼭 그럴 필요가 없었다. 어차피 로컬에서 개발하는 것이니 로컬 폴더에 저장된 소스코드를 그대로 가져다 쓰기만 하면 되기 때문
- 그리고 이미지를 재빌드하거나 컨테이너 다시 실행하지 않고도 bind mount를 통해 가장 최신의 코드를 컨테이너에 업데이트할 수 있었다.
- 그리고 development에선 이런 방식이 편리하고, 또 권장된다. 컨테이너 재실행할 필요없이, 코드에 업데이트된 내용을 실시간으로 반영할 수 있기 때문이다.

하지만 production에서는 다르다.
- remote machine의 환경 설정에 전혀 의존하지 않고, 컨테이너 그 자체로(standalone) 동작해야 한다.
- 즉 앱 구동에 필요한 코드가 remote machine에 있을 거라 기대해선 안된다.
- "Image / Container is the 'single source of truth'"
- 그래서 production에서는 bind mount 대신에 쓰는 방식이 COPY 명령어다. (이전 강의에서도 설명) 
- dockerfile로 development이든 production이든 똑같이 작동하는 이미지를 빌드할 수 있어야 한다. (Ensures that every image runs without any extra, surrounding configuration or code)



### AWS EC2로 실습해보기
1. Amazon Linux AMI 2023으로 실행
2. Free tier를 사용할 수 있다면 free tier 지원 가능한 인스턴스로
3. VPC 선택(default)
4. 키 페어 생성(Create a new key pair). SSH로 인스턴스 연결할 때 꼭 필요한 비밀번호 같은 것(절대 외부에 복사, 공유하지 말 것)
5. 보안 그룹 설정은 인스턴스에 도커 설치 후 컨테이너 실행한 다음에 할 수도 있다.




### AWS EC2 인스턴스 SSH 연결이 되지 않을 때

1. 인스턴스 IP 주소 확인(중지-stop-하고 다시 켤 때마다 바뀌어 있다)
2. username 확인(Amazon Linux이라면 ec2-user)
3. 보안 그룹 인바운드 룰 설정(EC2 인스턴스 > 보안Security > 보안 그룹 > Inbound rules 선택 > Edit inbound rules > Source Type을 내 IP로 설정)


### AWS EC2 인스턴스에 도커 설치하기
채정 님이 알려주신 대로(https://blcklamb.notion.site/137-Docker-0d7032b7e51b4891b62a8cd496a6f97d)

먼저 키 페어(.pem 파일) 권한을 바꿔야 한다. 소유자(owner)만 읽을 수 있고 나머지 그룹이나 외부 사용자는 읽기 쓰기 실행이 모두 불가능하도록 바꾸자.

```bash
sudo chmod 400 ~/.ssh/my_key_pair.pem
```

그 다음에 yum으로 패키지 업데이트한 후 도커를 설치하자.

```bash
sudo yum update -y 
sudo yum -y install docker

sudo service docker start

# docker라는 그룹(-G)에 ec2-user라는 user를 추가(append, -a)함
sudo usermod -a -G docker ec2-user

# ssh 로그아웃 후
exit

# ssh 재로그인했다고 가정, 아래 명령어를 실행
sudo systemctl enable docker
# sudo 붙여서 실행하기
sudo docker version
```


### 소스 코드 배포 vs. 빌드된 이미지 배포: 둘 중에 더 나은 선택지는?

1. remote machine에 이미지를 빌드하고,
2. remote machine에 소스 코드 푸쉬, docker build와 docker run 명령어로 컨테이너 실행

또는

1. 배포 전에 이미지 빌드
2. remote machine에서 배포받은 이미지러 docker run

이미지 자체를 배포한다면, remote server에서 별도로 이미지를 빌드하는 과정을 할 필요가 없다. 

비유: 이미 조립된 가구(=이미지)를 굳이 해체된 상태(=소스코드)로 다른 곳에 가져가서, 다시 조립한 다음 설치할 필요가 없다.


### Docker Hub로 이미지 push하기

```bash
docker build -t node-dep-example-1

# 이미지 tag를 변경
docker tag node-dep-example-1 my_docker_username/node-example-1

# docker hub에 로그인하고 나서 실행
docker push my_docker_username/node-example-1
```

### EC2에서 실행

아까 Docker Hub에 push할 때 public repository로 설정했기 때문에 docker run으로 바로 실행할 수 있다.

```bash
docker run -d --rm -p 80:80 my_docker_username/node-example-1
```

### EC2에서 실행한 컨테이너(웹 서비스)를 테스트

이제 EC2 인스턴스의 보안 그룹 설정을 바꿔야 할 차례다. 테스트하려면 내 컨테이너를 www에 공개해야 하고, 그러기 위해서는 inbound rule에 HTTP, port 번호(아까 80으로 설정했으므로)는 80으로 룰을 추가해야 한다.

- outbound rule: EC2 인스턴스 -> 외부 endpoint
- inbound rule: 외부 machine -> EC2 인스턴스


---

### 컨테이너 또는 이미지 관리, 업데이트

1. 로컬 머신에서 컨테이너 안 내용을 업데이트한 후
2. 이미지 리빌드: `docker build -t node-example-1`
3. 태그 변경 후 `docker tag node-dep-example-1 my_docker_user_name/node-example-1` push: `docker push my_docker_user_name/node-example-1`

EC2에서 새로 업데이트된 이미지로 컨테이너를 실행하려면, 단순히 docker run만 해서는 안되고 이미지를 다시 pull해야 한다: `docker pull my_docker_username/node-example-1`


### 도커 배포: EC2 vs. ECS 장단점 비교

### EC2로 배포했을 때의 단점
- do-it-yourself approach라고 할 수 있다. 인스턴스를 생성하고 구성, 연결, 도커 설치까지 사용자가 직접 해야 하기 때문이다.
- 이 remote machine에 대한 권한을 독점적으로 가진다. 그렇기 때문에 특히 보안 문제에 대해서 사용자가 전적으로 책임을 지게 된다.
	- 네트워크, 보안 그룹 설정, 방화벽 등
- SSH로 연결 접속해서 명령어 실행하는 게 번거롭다.

### ECS(Elastic Container Service)을 써야 하는 이유
less control, less responsibility. 책임이 적다는 건 그만큼 번거로운 작업에서 벗어날 수 있다는 뜻!

remote server의 업데이트, 모니터링, scaling -> managed service가 다 알아서 해준다. 사용자가 app/container 배포에만 집중할 수 있도록 한다.

단, AWS의 ECS든 마이크로소프트나 구글 제품이든 cloud provider의 서비스를 사용할면 그들의 룰을 따라야 한다(자유도는 낮아짐).

그리고 ECS에는 free tier가 없으니 비용 주의할 것(삭제하고 나서도 load balancer나 NAT Gateway 등도 제거했는지 꼭 확인해야)!

---

### ECS 생성 단계

1. Image: Docker Hub에 올려놓은 repository name으로 입력. Docker Hub의 리포는 자동으로 이름을 찾지만, Docker Hub이 아니라면 repository 전체 URL 주소를 입력해야 함.
2. Port
3. Environment

모두 Docker run 명령어에서 직접 태그 붙여서 실행할 수 있는 옵션들이다. 실습에서는 Dockerfile 안에 다 적을 것이기 때문에 굳이 ECS 설정 단계에서 따로 설정하지 않는다.

### Task란?
- Task란 application을 위한 blueprint과 같다.
- task = 하나의 remote server(EC2 인스턴스 같은 것)에 대응한다고 보자.
- FARGATE: "serverless 모드". 요청이 있을 때에만 컨테이너가 그 요청을 다루도록 한다. 이렇게 하면 비용을 아낄 수 있다.
- 실습에서는 하나의 task에 하나의 service만 실행하도록 설정

### ECS로 웹 서비스 테스트
task ID를 클릭해서 들어가면 task에 대한 정보를 볼 수 있고, public IP 주소도 확인할 수 있다.
웹 브라우저에서 이 public IP 주소를 입력하면 웹 서비스가 작동하는 걸 볼 수 있다.


### AWS에 대해 더 알아보기: VPC, Subnet, FARGATE

FARGATE란, EC2 인스턴스를 항상 가지고 있는 게 아니라 이 서버가 필요할 때만 작동하는 방식을 말한다.

- Task memory
- Task CPU
- Auto Scaling -> 여러 개의 컨테이너를 쓰고 요청이 많아질 때(workload의 증가) scaling을 하기 쉽도록 자동화한다. (나중에 사용)


### Cluster 설정
어떻게 ECS는 이미지 업데이트를 반영할까?

Cluster 설정 > Task > Task Definition > Create new revision

Acions > Update service (설정은 그대로 유지)
이렇게 하면 이미지를 새로 pull하고 다시 빌드한다.

AWS는 task를 새로 launch할 때마다 public IP를 바꾼다.



### 다중 컨테이너 앱 준비하기
첨부파일을 이용하자.
이 부분에서는 docker compose 파일을 이용하지 않는다. 왜 사용하지 않을까?
하나의 머신에서 다중 컨테이너를 관리하고 생성하기 위해선 docker compose가 유용하지만, 배포 단계에서는 remote server의 CPU 성능이나 메모리 크기 등을 고려해야 하는 등 더양한 요소를 고려해야 한다. 그리고 cloud 서비스는 하나의 머신만 가동하는 게 아니라 여러 서로 다른 서버를 가동한다.

```bash
docker build
```

### AWS ECS에서는 별도의 네트워크 설정이 필요하다
이전 실습에서는 docker compose로 실행하면 알아서 네트워크를 생성하고, 각 컨테이너 이름으로 IP 주소를 대체할 수 있었다.

하지만 ECS에서는 그게 불가능하다. 클라우드에서 사용자의 컨테이너를 같은 머신으로 실행한다는 보장이 없기 때문이다.
하지만 여러 컨테이너가 같은 task에 등록되어 있다면 그 컨테이너들은 서로 같은 머신에서 돌아가긴 한다.

대신에 DB 컨테이너의 app.js에서는 환경변수로 설정하자.

1. 이미지 빌드
```bash
docker build -t goals-node ./backend
```

2. Docker Hub에 push


### 백엔드 컨테이너: 클러스터 생성

1. networking only 클러스터 선택
2. 이름 설정(goals-app)
3. Create a new VPC에 체크 표시하기. 기본 설정으로 두기

클러스터란 컨테이너를 둘러싼 네트워크를 말한다.

이제 task를 새로 생성하자.

1. 아까처럼Task definition으로 가서 new task definition 선택
2. FARGATE으로 설정한 후 next
3. 이름 설정(goals)
4. Task role: ecs task role로 선택
5. Task memory, Task CPU 가장 작은 걸로 선택(현재는 데모용이기도 하고 비용을 아끼기 위해서)
6. 컨테이너 추가(add container)
7. 컨테이너 이름 생성, Image 등록
8. Port mapping
9. environment > command에 "node, app.js"

nodemon을 쓰는 대신 그냥 node를 쓰고 싶다(어차피 bind mount를 쓰지 않기 때문)

### 환경변수 설정

환경변수에 이렇게 추가: `MONGODB_URL=mongodb`

그리고 이미지를 재빌드

```bash
docker build -t goals-node ./backend
```

이미지를 push한다.

```bash
docker tag goals-node my_docker_username/goals-node
docker push my_docker_username/goals-node
```

컨테이너를 로컬에서 작업할 떈 docker compose 파일에서 env_file 키워드로 환경변수 파일을 명시하거나 아니면 --env-file 옵션으로 환경변수 설정을 해주었다.

이제 AWS ECS에서는 처음 클러스터 설정할 때 environment variable에 직접 원하는 변수를 추가할 수 있다.

### localhost
- 똑같은 task에 있는 컨테이너를 지칭하기 위해서 MONGODB_URL localhost로 쓴다. 
- development 단계에서는 localhost를 쓸 수 없었다.

나머지 다른 설정은 지금 당장 건드릴 필요 없다.