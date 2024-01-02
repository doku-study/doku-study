# 정리 및 새롭게 알게된 점
    - dockerbuild 파일에 오타가 있어서 docker run을 실패했다. 그러나 마지막 command만 실패한거라서 process는 이미 만들어져있었다.
    - docker ps -a 명령어를 사용하면 종료되어있는 container도 확인할 수 있다.
    - docker image는 종료된 container를 삭제하지 않으면 삭제할 수 없다.
    - node를 몰라서 디버깅을 하는데 시간이 걸렸다.
# 함께 이야기하고 싶은 점, 느낀점
    - 