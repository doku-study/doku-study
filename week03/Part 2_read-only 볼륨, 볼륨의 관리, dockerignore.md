앞서 설명했던 것처럼 볼륨은 컨테이너의 수명 주기에 상관없이 데이터를 저장하고 유지하는 역할을 한다고 했다.
더불어 컨테이너 내부의 경로와 외부(로컬, host machine) 경로를 연결(mount)한다는 개념도 배웠다.

그럼 볼륨에 저장된 데이터를 수정할 때 이런 의문이 들 수 있다.

1) 컨테이너 안에서 데이터를 수정하면 host machine의 경로 안에 있는 데이터도 수정되는가?
2) 반대로, host machine 안의 데이터를 수정하면 컨테이너 안의 데이터가 수정되는 건가?

결국 host machine의 데이터가 원천(source)이고 지속적으로 유지되어야 하는 것이기 때문에 1번은 바람직하지 않다.
또한 컨테이너라는 것도 결국 host machine에 저장된 image를 바탕으로 생성하는 것이기 때문에 2번이 더 타당하다고 납득할 수 있다.

그렇지만 어쨌든 bind mount에서는 1번도 일어날 수 있기 때문에, 컨테이너 안 볼륨에서 데이터를 수정할 수 없도록 별도로 조치를 취할 수 있다. 이때 등장하는 게 바로 read-only volume(읽기 전용 볼륨)이다.

### Read-Only volume(읽기 전용 볼륨)

bind mount의 매핑하고자 하는 경로 인자 뒤에 :ro(read-only)를 붙여주었다.
이렇게 하면 컨테이너 내 /app 이라는 경로는 데이터를 읽어올 수만 있을 뿐, 수정(write)하지 못한다. (정말?)

```bash
docker run -d -p 3000:80 --rm --name feedback-app -v feedback:/app/feedback -v "/Users/my_user_name/udemy/docker-practice/:/app:ro" -v /app/node_modules -v feedback-node:volumes
```

### 읽기 전용으로 만들었다, 하지만 일부 하위 디렉토리는...

위 명령어로 컨테이너 내부의 /app 폴더를 모두 읽기 전용으로 만든 것 같다. 

하지만 우리가 익명 볼륨에 대해 직전에 배웠던 걸 상기해보자. 익명 볼륨을 /app/node_modules 경로로 지정해주면 앞서 /app 경로로 bind mount를 지정해도 /app/node_modules 는 /app의 하위 경로이기 때문에 /app/node_modules 폴더는 host machine 경로의 덮어쓰기로부터 살아남게 된다.

마찬가지로, 위 명령어에선 bind mount로 /app 폴더에 대해 읽기 전용으로 지정했지만 /app/node_modules에 대해 익명 볼륨을 지정하고 /app/feedback에 대해서는 named volume으로 지정했기 때문에 두 경로 모두 read-write, 읽기와 쓰기가 모두 가능한 경로로 살아남게 된다.

