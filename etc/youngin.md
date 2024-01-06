# Docker Commands

- `<CONTAINER>`: 컨테이너명 혹은 컨테이너 ID
- `<IMAGE>`: 이미지명 혹은 이미지 ID

## 컨테이너

### 컨테이너 목록

#### 현재 실행 중인 컨테이너

```
docker ps
```

#### 상태에 관계 없이 모든 컨테이너 조회

```
docker ps -a
```

### 컨테이너 생성

#### 도커 컨테이너 내부에서 호스팅 머신으로 대화형 세션 노출하며 실행하기

```
docker run -it <IMAGE>
```

위 명령어는 아래 명령어와 동일함.

- `-i`: 인터랙티브 모드로 컨테이너 실행
- `-t`: 컨테이너 실행하면서 터미널 생성

```
docker run -i -t <IMAGE>
```

#### 중지되면 자동으로 삭제되는 컨테이너 실행하기

```
docker run --rm <IMAGE>
```

### 컨테이너 종료

```
docker stop <CONTAINER>
```

### Detached 모드로 시작한 컨테이너에 연결하기

```
docker attach <CONTAINER>
```

### 파일 복사 from/to 컨테이너

```
docker cp <from> <to>
```

- `<from>`, `<to>` 는 각각 컨테이너 혹은 호스트의 파일 경로.
  - 호스트 파일 경로는 prefix 없이 그냥 입력.
  - 컨테이너 파일 경로는 `<컨테이너명>:` 를 prefix 로 입력.
