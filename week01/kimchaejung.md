# 새롭게 알게된 점

## 도커?

> 👩‍💻 컨테이너를 생성하고 관리하는 도구

## 컨테이너?

> 👩‍💻 소프트웨어의 표준화된 단위
> 코드 패키지, 의존성

- 동일한 컨테이너는 언제 어디서든, 누가 실행했던 간데 항상 동일한 애플리케이션과 동작과 결과를 제공
- 최신 운영 체제에서 지원 가능
- 시작하기 용이

## 왜 컨테이너인가?

왜 독립적이고 표준화된 애플리케이션 패키지가 필요한가?

1. 개발 제품 생산 환경이 다를 경우

   ex) 로컬과 배포된 환경의 애플리케이션 버전이 다를 경우

2. 팀, 회사 내에서 개발 환경이 다를 경우
3. 동일한 로컬임에도 프로젝트끼리 버전이 다를 경우

## 컨테이너 vs 가상 머신

| 도커 컨테이너                                                     | 가상 머신                                                                  |
| ----------------------------------------------------------------- | -------------------------------------------------------------------------- |
| 운영 체제에 미치는 영향 적음 <br> 빠르고, 디스크 공간 사용 최소화 | 운영 체제에 미치는 영향 큼<br>느리고, 디스크 공간 사용 높음                |
| 공유, 재구축 및 배포 용이<br>(이미지, 구성 파일)                  | 공유, 재구축 및 배포 까다로움                                              |
| 캡슐화된 애플리케이션과 환경 보유<br>+ 쓸데없는 부가적인 것 제외  | 애플리케이션, 환경에 필요한 것만 캡슐화하는 것이 아닌 컴퓨터 전체를 캡슐화 |

## Docker 설정 하는 법(macOS)

[Install Docker Desktop on Mac](https://docs.docker.com/desktop/install/mac-install/)

# 함께 이야기하고 싶은 점

> 🙋‍♀️ 각자 이번 스터디 이후 얻어가고 싶은 것 / 도전해보고 싶은 것이 궁금합니다.

저는 이번 스터디에서 가상머신보다 도커 컨테이너가 더 좋은 이유를 몸소 느껴보고 싶습니다.
더불어서 제가 이전에 했던 프로젝트를 도커 컨테이너로 올려보고 싶어요.
