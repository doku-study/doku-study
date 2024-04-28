# Section1 

## 도커란
컨테이너를 관리하기 위한 도구 
##  컨테이너란
이는 기본적으로 코드 패키지이며 해당 코드를 실행하는데 필요한 종속성과
도구가 포함되어 있는 표준화된 소프트웨어 유닛 

##  컨테이너를 사용하는 이유와 효과
- 언제 어디서든 같은 개발/배포 환경을 구축하여 코드가 항상 정확한 버전으로 실행될 수 있음   
- 타인과 함께 개발할 때 같은 코드 기반에서 작동하도록 할 수 있음
- 각 프로젝트 마다 필요한 환경(특정 소프트웨어 버전 설치, 다른 라이브러리들과의 호환)을 따로 구성할 수 있음 

##  가상머신 vs 도커 컨테이너 
환경 설정은 가상머신으로도 할 수 있지 않나? 왜 꼭 도커와 컨테이너를 사용해야할까?

##  가상머신이란
호스트 운영 체제에 독립적인 자체 셀(shell)을 지닌 캡슐화된 가상 운영 체제를 지닌 버츄얼 머신  
가상머신의 설치 : 호스트 운영 체제, 즉 Windows 또는 macOS 또는 Linux가 있고 그 위에 버츄얼 머신을 설치한다는 것

가상머신 역시 각 프로젝트 마다 다른 환경설정이 가능하고,   
팀원에게 가상머신 구성을 공유하여 같은 환경에서 개발하고 있는지 체크 가능

문제는 여러 가상머신에서 발생하는 오버헤드  
하나의 가상머신은 호스트에서 실행되는 각각의 standalone   
따라서 특히 이러한 머신이 여러 대 있는 경우에는
매번 새로운 컴퓨터를 머신 내부에 설치해야 하고
그에 따라 메모리, CPU, 또한 우리 하드 드라이브의 공간을 낭비하게 됨

장점 : 분리된 환경, 환경 별 구성, 공유 및 재생산 가능  
단점 : 중복 복제 (리눅스 환경이 필요하다면 호스트위에 리눅스 OS를 가지는 가상머신을 여러대 설치 해야함 ) -> 호스트 시스템 성능 저하

##  가상머신과 달리 컨테이너는 어떻게 환경을 구축할까
도커는 컨데이터를 만들기 위한 관리 도구   
컨테이너는 하나의 머신에 몇 대의 머신을 설치하지는 않음  
대신 운영체제가 기본적으로 가지고 있거나 컨테이너 에뮬레이트를 지원하는 내장 컨테이너 사용, 도커는 이것이 작동하도록 처리   

이 위에 도커 엔진 실행  
도커 엔진 기반으로 컨테이너 실행  
이 컨테이너 안에는 작은 운영체제 레이어는 있을 수 있지만 가상머신에 비해 훨씬 가벼움  

## 실습
도커를 사용해서 로컬에 node를 설치하지 않아도 node로 동작하는 어플리케이션 제작 가능  
> FROM node:14  
WORKDIR /app  
COPY package.json .  
RUN npm install  
COPY . .  
EXPOSE 3000  
CMD [ "node", "app.mjs" ]  