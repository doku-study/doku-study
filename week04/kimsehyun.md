
컨테이너는 어떻게 외부와 소통할까? 어떤 대상과 통신하느냐에 따라 세 가지 케이스로 나눌 수 있다. 

1. 컨테이너와 web API(www, world wide web) 간 통신
2. 컨테이너와 로컬 호스트 머신 간 통신
3. 컨테이너와 컨테이너 간 통신


## 1. 컨테이너 - www 통신
여기서 말하는 www 통신이란 컨테이너도 아니고 로컬 호스트 머신도 아닌, 인터넷으로 평소에 접속하는 web API를 말한다.

컨테이너에서 web API 요청은 별다른 조치를 취하지 않아도 코드에 web API 주소만 잘 입력하면 아무 문제 없이 통신할 수 있다.

```node
app.get('/movies', async (req, res) => {
  try {
    const response = await axios.get('https://swapi.dev/api/films');
    res.status(200).json({ movies: response.data });
  } catch (error) {
    res.status(500).json({ message: 'Something went wrong.' });
  }
});
```



## 2. 컨테이너 - 로컬 호스트 머신 간 통신

그렇다면 컨테이너에서 로컬 호스트 머신 사이 통신도 가능할까?
가능하다. 하지만 web API 요청처럼 아무 문제 없이 바로 작동하지는 않는다.

```node
mongoose.connect(
  'mongodb://localhost:27017/swfavorites',
  { useNewUrlParser: true },
  (err) => {
    if (err) {
      console.log(err);
    } else {
      app.listen(3000);
    }
  }
);
```

위 코드 그대로 컨테이너를 실행하면 에러가 발생한다.
MongoDB 데이터베이스는 호스트 머신에서 돌아가는 것이기 때문이다. 
강의자가 자기 로컬에 MongoDB를 사전에 설치했다고 말하지만, 강의 영상을 따라하기 위해 꼭 MongoDB를 내 로컬에 설치할 필요는 없다. 어차피 있다가 MongoDB가 포함된 도커 컨테이너를 쓸 것이기 때문이다.

컨테이너에서 로컬로 통신하는 해법은 간단하다.
주소에 localhost 대신 host.docker.internal를 넣으면 된다.

```node
mongoose.connect(
  'mongodb://host.docker.internal:27017/swfavorites',
  ...
```



## 3. 컨테이너 - 컨테이너 간 통신

MongoDB를 포함한 컨테이너를 Docker Hub에서 다운로드받자.
이미지 이름은 mongo.

```bash
docker run mongo
```

컨테이너에서 컨테이너를 접속하려면 host.docker.internal이나 localhost라는 이름 대신 접속하고자 하는 컨테이너의 IP 주소를 알아야 한다.
그리고 그 IP 주소를 알려면 `docker container inspect CONTAINER_NAME` 명령어로 확인해야 한다.

```node
mongoose.connect(
// 접속하고자 하는 컨테이너의 IP 주소는 172.17.0.2이었다.
  'mongodb://172.17.0.2:27017/swfavorites',
  ...
```

하지만 매번 컨테이너의 IP 주소를 찾아서 확인하는 건 번거롭고 힘들다.
특히 이미지를 새로 빌드할 때마다 컨테이너의 IP 주소가 바뀌기 때문에 이렇게 하드 코딩(컨테이너 안의 코드에 직접 IP 주소를 입력하는 방식)하는 건 비효율적이다.


## 컨테이너 네트워크 생성하기

도커에서 컨테이너끼리 통신하는 네트워크를 만드는 방법이다.
이 네트워크 안에선 모든 컨테이너가 서로 통신할 수 있고, 각 컨테이너의 IP 주소는 자동으로 할당된다. 컨테이너 이름만 알면 IP 주소를 굳이 코드에 입력할 필요가 없게 된다.

```bash
docker run -d --name mongodb --network favorites-net mongo
```

근데 무작정 이렇게 네트워크 옵션을 주어서 실행하면 다음 에러가 발생한다.

```
docker: Error response from daemon: network favorites-net not found.
```

볼륨과 달리 도커는 네트워크를 명령어에서 옵션으로 주었을 때 자동으로 생성하지 않기 때문이다.
그래서 명령어 실행 전에 원하는 이름의 네트워크를 미리 만들어두어야 한다.

```bash
docker network create favorites-net
```

만들어진 네트워크 목록은 `docker network ls` 명령어로 확인할 수 있다.



## 코드에서 통신하고자 하는 컨테이너를 지정하는 법

IP 주소를 직접 코드에 적는 건 비효율적인 방법이라고 했다. 만약 도커 네트워크를 만들었고 컨테이너들도 모두 네트워크 안에 있다면, 코드에서 어떻게 다른 컨테이너에 접근할 수 있을까?

-> **이름으로 접근한다**. 통신하려는 컨테이너 이름이 mongodb라면

```node
mongoose.connect(
	'mongodb://mongodb:27017/swafavorites',
	...
)
```

라고 쓰면 된다. 단, 이 코드가 들어있는 컨테이너는 mongodb라는 컨테이너와 같은 네트워크에 있을 때만 제대로 접속된다.

### port 번호는 따로 지정하지 않는 이유
애초에 port 번호를 docker run 명령어에서 지정하는 이유는 우리 로컬 호스트 머신에서 컨테이너를 접근하려고 지정하는 건데, 이제 컨테이너끼리 통신하게 설정했으니 따로 포트번호를 둘 이유가 없다.



## 도커가 IP 주소를 해결(resolve)하는 방법

도커는 IP 주소가 들어야 하는 부분의 소스코드를 직접 컨테이너 이름으로 뜯어고치는 게 아니다.
대신, 만약 내 app이 HTTP 요청(또는 아무 요청)을 보내면 도커가 이를 outgoing request가 있다고 감지하고 그 이후에 해결한다. 다시 말해서 요청이 컨테이너를 떠난 이후에야 도커가 IP 주소 부분을 해결한다는 것.



## 질문
- 컨테이너를 이미 실행하고 나서도 네트워크에 새로 추가할 수 있을까? 컨테이너를 네트워크 안에 포함시키려면 중지시키고 그 다음에 다시 실행시킬 때 옵션을 주어야 하나?
- 한 컨테이너를 로컬 호스트 머신과 통신하면서 동시에 컨테이너끼리도 통신하게 할 수 있을까?
- 마지막 설명에서, 도커는 요청이 컨테이너를 떠날 때 IP 주소를 치환(? 해결?)한다고 했다. 그런데 이 개념을 굳이 강조한 이유는 뭘까? 언뜻 보면 당연한 소리 같은데



