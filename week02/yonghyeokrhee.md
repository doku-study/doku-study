# 새롭게 알게된 점
`25` 
  - image는 레이어를 기반으로 만들어졌다. read-only 이다. container는 CMD를 수행함으로써 read-write를 할 수 있는 layer가 추가로 붙었다.
  - 따라서 하나의 docker execute command가 변경 되면 그 이후의 모든 layer는 새롭게 build되어야 한다. 
  - 개발자는 영향도를 파악하여 cache를 이용할 수 있도록 최적화를 할 수 있을 것이다.

`28`
  - docker container를 새로 만들지 않고 이전에 만들어둔 container를 사용하는 것도 된다. 
    - docker start [name]

`29`
- detached mode 가 가능하다. `docker run -d`
- attached mode 도 가능하다. 
- docker start 는 detach mode가 default, docker run 은 attach mode 가 default
  



`34` docker command 하나에 layer가 하나씩 추가된다고 생각하면 된다.
`35` cp command는 동작중인 host container에 파일을 복사할 수 있다.(에러에 취약하므로 잘쓰지 않음)
    1. 
# 함께 이야기하고 싶은 점
  - 2주차 강의 수강 완료
  - image SHA와 image ID의 차이점
  - image tag를 설정하지 않았을 때 <none>으로 표시되는 것을 방지할 수 있는 방법