




## 컨테이너 배포

- 배포 시 가장 핵심적인 단계
    - 리모트 시스템 구축
    - 리모트 호스팅 서버 구축
    - SSH로 리모트 서버와 연결
    - 리모트 호스트에 Docker 설치
    - 도커 이미지 pushing and pulling
    - 컨테이너 실행

세가지 유명 hosting providers
    - AWS
    - Microsoft Azure
    - Google Cloud


## 이미지 빌드 & 컨테이너 실행

- `docker build -t node-dep-example .`
- `docker run -d --rm --name node-dep -p 80:80 node-dep-example`

- 바인드마운트, 볼륨을 사용하지 않는 이유? 결국 dev 환경과 prod 환경을 맞추기 위해
    - prod 환경에선 컨테이너만으로 애플리케이션을 실행시킬 수 있어야 함 (standalone하다고 표현)
    - 볼륨, 바인드 마운트 등은 호스팅 머신 외부에 의존하는 어떤 장치. 컨테이너의 목적에 어긋난다고 함
    - dev 단계에서 이걸 설정한 것은 단순히 개발 편의를 위해
- 그럼 prod 환경에서 소스 코드 접근은 어떻게? dockerfile의 COPY 구문으로 가능!
    - 볼륨, 바인드마운트 설정을 dockerfile에서 할 수 없었던 이유가 결국 prod, dev에서 동일한 dockerfile을 사용하기 위함이었다니..! 큰그림 그리고 있었구나


## AWS EC2

- EC2는 기본적으롴 클라우드 상의 자체 컴퓨터를 의미함
- 인스턴스 시작하는건 프리티어 & 디폴트 옵션으로 하되, 키페어가 중요
    - 나중에 인스턴스에 SSH로 연결할 때 이 키페어가 필요함
    - 다르게 말하면 키페어만 가지고 있으면 내 EC2 자원을 쓸 수 있음

- SSH는 로컬 머신에 있는 CLI, 터미널 통해 리모트 머신에 연결하기 위한 프로토콜
    - 리눅스, 맥OS에선 SSH 이미 설치되어 있어 일반 터미널에서 사용 가능 (어쩐지,,)
    - 예전에 회사 윈도우 컴퓨터 기반으로 로깅 프로젝트 강의 따라한적 있는데 그 때 PuTTY를 뭔지도 모르고 썼었다.
- `chmod 400 example-1.pem` 실행. 키를 공개적으로 볼 수 없게 하는 역할.
- `ssh -i "example-1.pem" ec2-user@ec2-44-206-228-98.compute-1.amazonaws.com`
    - 이제 이 터미널에서 실행하는 명령은 리모트 머신에서 실행하는 셈

## 리모트 머신에 도커 설치

- `sudo yum update -y`: 리모트 머신의 필수 패키지가 업데이트 되고, 최신 버전 사용하는지 확인 가능
- `sudo yum -y install docker`: 도커 설치
- `sudo service docker start`: 도커 실행
- `sudo usermod -a -G docker ec2-user`: ec2-user라는 사용자를 docker 그룹에 추가하는 명령. 이러면 ec2-user가 sudo 없이 Docker 명령을 실행할 수 있음
- AWS 콘솔 로그아웃,인 후 `sudo systemctl enable docker` 실행
- `docker version`으로 정상 출력되는지 확인
    - 뭔가 출력은 되는데 permission denied도 같이뜸. 이건 터미널 다시 돌리니까 해결됨


## 로컬 이미지 -> 리모트 머신

1. 소스 코드를 배포, 리모트에서 이미지 구축, 빌드
    - `docker build`, `docker run` 필요
    - 불필요하게 복잡함
2. 로컬에서 이미지 구축, 구축된 이미지를 리모트 머신에 배포, 빌드
    - `docker run` 필요
    - 리모트 서버에서의 불필요한 작업 없음

- 도커 허브 접속 -> create repository
- 로컬에서 이미지 빌드
    - `.dockerignore` 파일 작성 (pem 등 제외시킴)
    - `docker build -t node-dep-example-1 .`
- `docker login`
- 로컬에서 만든 이미지를 이 레포에 push
    - `docker tag node-dep-example-1 baoro9394/node-example-1`
    - `docker push baoro9394/node-example-1`

## 리모트 머신에서 이미지 run

- `docker run -d --rm -p 80:80 baoro9394/node-example-1`
- AWS EC2 인스턴스의 IPv$ Public IP 찾음. 여기에 80 포트로 접근하면 됨
- 그전에 보안그룹 설정해야 함
    - EC2 인스턴스는 기본적으로 WWW의 모든 것과 연결이 끊어져 있음

## 보안그룹 설정

- 'launch-wizard-4'로 시작하는 보안 그룹이 할당된 것 확인
- 아웃바운드 규칙: 다른 곳에 있는 인스턴스 대기열로부터 허용되는 트래픽을 제어
    - 모든 트래픽 허용 중. 그래서 허브에 있는 이미지 run 할 수 있었던 것
    - 인스턴스에서 다른 www 접근하는 것에 대한건가
- 인바운드 규칙: 어딘가에 있는 이 인스턴스의 대기열(큐)에 허용된 모든 트래픽을 제어
    - 외부에서 인스턴스로 접근하려는 것에 대해,,?
    - 22번 포트가 SSH로 열려 있음. 그래서 모두가 22번으로 접근할 수 있기에 키페어가 필요함
    - HTTP 트래픽이 이 인스턴스의 80번 포트에 접근할 수 있도록 허용해야 함
    - 유형 - HTTP, 소스 유형 - Anywhere-IPv4
    - 스터디 때 이걸 몰라서 IP 주소를 일일히 추가햇었다. 바보같았지만 그래서 지금 이걸 적용해볼 수 있음을 긍정적으로..
- 다시 IP 주소에 80번 포트로 접근하면 잘 표시됨
    - 이것의 의미는, 리모트 머신에 nodeJS 설치하지도 않고 도커만 설치해서 애플리케이션을 실행했다는 것. 대단한 것 같긴함

## 리모트 머신에서의 컨테이너, 이미지 관리 & 업데이트

- 로컬 소스코드 변경한 상황
- 이미지 다시 빌드 hub에 푸시 리모트 서버에서 업데이트된 이미지 사용하게 처리하면 됨
    - 간단하다는데 왜 전혀 안 간단해보이는지. 귀찮다
- 인스턴스 종료는 콘솔에서 할 수 있는 방법만 알려줌. 인스턴스를 터미널 단에서 종료할 수는 없나? 없다면 왜 못하게 한걸까

- 지금까지의 방식의 주요 단점: 모든게 수동. 수동인 만큼 자율과 책임을 가짐
- 이런거 필요없는 배포 작업절차가 있음
    - 로컬에서 몇몇 명령 실행해서 자동으로 이미지가 리모트로 이동하고
    - 리모트는 뭐 안해도 자동으로 시스템 소프트웨어가 운영 체제를 업데이트 하도록 관리됨
- 이 방식에서는 굳이 EC2 사용 안해도 됨. 대신 managed service라는 솔루션 사용

## AWS ECS (Managed Service)

- Elastic Container Service의 약자. 컨테이너 관리를 도와주는 서비스
- 도커 사용 안하는 것임을 명심. ECS를 사용하되 컨테이너 사용하는건 똑같음
- 강의의 클러스터 생성 과정이 현재 ECS와 매우 다른 것 같은데
    - 일단 강의 내용 그냥 정리

- custom container로 설정해서 이것저것 옵션 설정해줌
- task definition으로 넘어감
    - task에선 AWS에 컨테이너 실행하는 방법을 정의함. 여러 컨테이너를 하나의 task에서 다룰 수 있음
    - task는 일종의 EC2 인스턴스와 비슷. 직접 관리하지 않는다는 차이
    - FARGATE를 디폴트로 하는데, 이건 서버리스 모드로 컨테이너가 실행 중인 시간에 대해서만 비용 지불하는 형식
- 서비스를 정의함
    - task를 실행하는 방법을 정의
    - 로드 밸런서 추가 가능
    - 모든 태스트는 서비스에 의해 시작됨. 하나의 서비스에 여러 태스크 할당 가능
- 클러스터 정의
    - 서비스가 실행되는 전체 네트워크
    - 다중 컨테이너 앱인 경우엔 하나의 클러스터에 여러 컨테이너 할당 가능
        - 도커 네트워크가 떠오름
    - 실제로 클러스터 네트워크라고 언급함
- 이렇게 클러스터 시작 후 task 탭에 들어가 IP 주소로 이동하면 애플리케이션 실행되는 것 확인 가능
    - AWS에서 컨테이너 실행한 셈


- 이 환경에서 컨테이너 업데이트 하는 방법
- 로컬 소스 코드 업데이트 -> 이미지 빌드 -> 태그 지정 -> 허브 push -> 이후?
- clusters -> default -> task -> create new division
    - 새 태스크 만들면 AWS에서 업데이트 된 이미지 가져옴

## AWS ECS (New Version)

- [Docker-image를-AWS-ECS에-등록하여-서버-띄우기](https://velog.io/@millwheel/Docker-image%EB%A5%BC-AWS-ECS%EC%97%90-%EB%93%B1%EB%A1%9D%ED%95%98%EC%97%AC-%EC%84%9C%EB%B2%84-%EB%9D%84%EC%9A%B0%EA%B8%B0) 글 참고함

- ECS는 cluster, task, task definition, service로 구성됨
    - cluster: 강의 개념과 마찬가지로 여러 컨테이너 실행할 수 있는 가상 공간
    - task: 생성한 컨테이너 실행하는 단위
    - task definition: task의 설정을 모아놓은 집합 단위
    - service: 여러 task 동시에 실행하는 것

- 클러스터 생성
    - 클러스터 이름 입력 (node-example-1)
    - 생성. 끝
- 태스크 정의 생성
    - 태스크 정의 패밀리 입력 (node-example-1-family)
    - 인프라 요구 사항에선 Fargate로 두고 태스크 크기를 가장 작게 설정해줘야 함
    - 컨테이너 이름과 URI (baoro9394/node-example-1) 입력
    - 컨테이너 포트는 기본으로 88 설정되어 있음. 이름만 등록 (node-example-1-port)
- 서비스 생성
    - 작성한 태스크 정의를 토대로 태스크를 돌릴 차례
    - 태스크는 서비스로 묶어서 실행 가능. 그러려면 먼저 서비스 생성 필요
    - auto scale 없는 '시작 유형' 선택. 굳이 필요 없을 정도의 미미한 트래픽이니까?
    - 배포 구성에선 '서비스' 선택. '태스크'는 자동 종료되어 번거롭다고 함
    - 태스크 정의 패밀리 선택
    - 서비스 이름 입력 (node-example-1-service)
    - 네트워킹 - 보안 그룹에서 EC2 작업 당시 인바운드 규칙 열어뒀던 보안 그룹 선택 (launch - wizard-1)
    - 생성하면 배포 진행됨 (ECS가 도커 허브 이미지 가지고 와서 컨테이너 배포 실행)
- 배포 확인
    - 클러스터 - 태스크 탭 들어가서 실행 중인 태스크 클릭
    - 퍼블릭 IP 주소 클릭

<img width="558" alt="image" src="https://github.com/doku-study/doku-study/assets/48575810/722bdc4f-aa49-4893-a686-b10987ebe8ec">

