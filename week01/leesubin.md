### 도커
- container technology: A tool for creating and managing containers

**컨테이너: A standardized unit of software**
- 코드를 실행하는데 필요한 의존 패키지 (ex. nodejs code + nodejs runtime)
- 같은 컨테이너 -> 같은 실행결과
- 피크닉 박스를 예시로 듬.

**왜 독립적이고 표준화된 애플리케이션 패키지를 원하는데?**
- 다른 개발, 상용 환경
  - 같은 환경에서 테스트하고 실행하기를 원함.
- 다른 팀원
  - 팀내에서도 모든 멤버가 동일한 환경으로 실행해야함.
- 다른 프로젝트
  - 프로젝트 변경할 때 마다, 버전, 툴이 다르면 충돌 일어나는 경우 많음.

**Environment: The runtimes, languages, frameworks you need for developement**
- 언제나 같은 환경
- 공유할 수 있음. 내 환경을
- 매번 환경을 지웠다가 다시 설치했다가 싫음


### 비교
**Docker Container**
- OS 에 임팩트 적고, 빠르고, 적은 용량
- 쉐어링, 리빌딩, 배포 쉬움

**Virtual Machines / Virtual Operating Systems**
- OS 에 큰 영향, 느림, disk 차지 많이함.
- 쉐어링, 리빌딩, 배포 챌린징하다.

### 결론
- 도커 쓰세요.