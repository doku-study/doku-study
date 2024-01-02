<!-- 주차 내용 -->

# 시작하기

## Docker란?

- Docker > 컨테이너 생성 및 관리 도구
    - 컨테이너 > 표준화된 소프트웨어 유닛
    - 코드 패키지 + 실행에 필요한 종속성
    - 다시말해, 소스코드 + 런타임 + 기타 필요도구
    - Standalone으로 작동가능 > 모든 환경에서, 동일한 작동 보장

## 왜 Docker와 컨테이너인가?

- 왜 독립화되고, 표준화된 어플리케이션을 원하는가?

    1. 개발과 운영 환경 간 차이 가능성 (로컬 및 개발서버 vs 운영서버)
    2. 팀/사내 개발 환경 간 차이 가능성 (팀원 A vs 팀원 B)
    3. 프로젝트 간 차이 가능성 (담당 프로젝트 A vs 프로젝트 B)

## 가상 머신 vs Docker 컨테이너

- 가상머신

    \+) 독립된 실행환경 보장
    - 호스트 OS 내부의 별도 게스트 OS
    - 필요한 라이브러리, 종속성, 도구 설치가능
    - 컨테이너와 유사하게 캡슐화된 환경 구성 가능

    \-) 운영 오버헤드
    - CPU, MEM, Disk등 리소스 낭비
    - 설치되어있지만, 코드 작동에 필요하지않은 디폴트 도구

- 컨테이너

    \+) 적은 리소스 사용
    - 호스트 OS를 공유하는 컨테이너 런타임
    - 불필요한 추가 도구 다이어트
    - 구성파일 공유를 통한 빠른 공유 가능

## Docker 설정 – 개요

- Linux
    - Native하게 지원
    - Docker Engine 설치 > 끝

- Win/Mac
    - Docker Toolbox/Desktop 설치 필요
    
## Docker 설정 – macOS

https://docs.docker.com/desktop/install/mac-install/  
다음 딸깍딸깍

## Docker 설정 – Windows

https://docs.docker.com/desktop/install/windows-install/  
Hyper V/WSL2 활성화 후  
다음 딸깍딸깍

## Docker 설정 - 구 시스템용 Docker Toolbox
웬만하면 Docker Desktop  
Mac 10.14 / Win10 이전 버전 용

## Docker 놀이터
https://labs.play-with-docker.com/  
웹 도커환경 제공

## Docker Tools 개요
강의를 통해 다음의 도구/페이지를 사용할것
- Docker Engine
- Docker Desktop
- Docker Hub
- Docker Compose

## IDE 설치 & 구성하기
- 킹갓 VS Code
- \+ Docker Extension

## 실전에 참여하기
- 갑자기 난이도가?

- Sample NodeJS앱을 실행할때
    - 기존 방식 > 번거롭다
        - 버전에 맞는 NodeJS 설치
        - npm install (packages.json)
        - node app.mjs
    - 컨테이너 > 간편하다
        - 특정 Node버전의 이미지를 기반으로
        - 컨테이너내에 종속성을 설치하고
        - 연결할 포트를 지정하여 패키징

- 컨테이너 생성
    - docker build . 
    - docker run -p 3000:3000 [IMAGE ID] 
    - curl localhost:3000
    
- 컨테이너 조회 및 중지
    - docker ps
    - docker stop [CONTAINER ID]

## 강의 개요

- 기초
    - 이미지 & 컨테이너
    - 데이터 & 볼륨
    - 컨테이너 네트워크

- 실사례
    - 멀티 컨테이너
    - docker compose
    - Utility containers?
    - 컨테이너 배포

- Kubernetes
    - k8s 기초
    - 데이터 & 볼륨
    - 네트워크
    - 클러스터 배포

# 이야깃거리

- 컨테이너 단점?
    - 가상머신만 장단점하고 컨테이너는 장점만 말하다니 불공평합니다.

- 가상화의 오버헤드는 구체적으로 어느정도인가
    - 가상화vs컨테이너하면 항상 리소스 낭비가 있다는 말은 나옵니다
    - 구체적으로 얼마나 차이가 날까요?
    - [쿠버네티스 컨테이너와 가상화 기술 집적도 비교, openmaru](https://www.openmaru.io/%EC%BF%A0%EB%B2%84%EB%84%A4%ED%8B%B0%EC%8A%A4-%EC%BB%A8%ED%85%8C%EC%9D%B4%EB%84%88-%EC%99%80-%EA%B0%80%EC%83%81%ED%99%94-%EA%B8%B0%EC%88%A0-%EC%A7%91%EC%A0%81%EB%8F%84-%EB%B9%84%EA%B5%90/) 중 `데모 시나리오 : 같은 하드웨어에서 웹서버와 WAS 를 가상화 와 컨테이너 에 얼마나 올릴 수 있는 지 비교`
    - 동일스펙(4Core/16GB)의 톰캣 인스턴스 14대 vs 40대