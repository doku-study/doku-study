## 모듈 요약

![multi_containers_with_network_001.jpeg](https://s3.ap-northeast-2.amazonaws.com/blog.resource/images/multi_containers_with_network_001.jpeg)







<br />

## 컨테이너의 다양한 통신 케이스

이 글에서는 통신 대상에 따라 컨테이너가 어떻게 통신하는지 알아본다.







<br />

## case 1 : 컨테이너 내부의 애플리케이션에서 (WWW) 외부 웹 API 에 HTTP 요청을 보내는 케이스

* 컨테이너 내부에서 WWW 에 HTTP 요청을 보낼 수 있다. (별다른 설정이 필요하지 않음)



<br />

## case 2 : 컨테이너 내부의 애플리케이션에서 로컬 호스트 머신의 DB 등에 데이터 저장 요청을 보내는 케이스

* `[scheme]://host.docker.internal:[port]/[path]`  로 로컬 호스트 머신의 웹 서버 또는 DB 와 통신할 수 있다.
* `host.docker.internal` 은 도커에 의해 인식되는 도메인으로, 도커 컨테이너 내부에서 알 수 있는 호스트 머신의 IP 주소로 변환된다.
* ex (로컬 호스트 머신의 mongoDB 와 연결) : `mongodb://host.docker.internal:27017`
* ex (로컬 호스트 머신의 웹서버와 연결) :  `http://host.docker.internal:8080`



<br />

## case 3 : 컨테이너 내부의 애플리케이션이 다른 컨테이너의 애플리케이션과 통신하는 케이스 (다중 컨테이너)

* 각각의 컨테이너는 하나의 역할만 하는 것이 바람직함 (SRP) 
* ex : 서버 컨테이너와 DB 컨테이너를 나눠서 관리



<br />

### mongoDB 컨테이너와 웹서버 컨테이너 간의 통신

1. mongoDB 컨테이너 실행  (DockerHub 에서 자동으로 받아와지므로, 별도의 Dockerfile 이 필요하지 않다)

```shell
docker run -d --name mongodb mongo
```



2. 방금 시작한 mongoDB 컨테이너 검사에서 `NetworkSettings.IPAdress` 조회하여 컨테이너의 IP 주소를 얻어온다.

```shell
docker container inspect mongodb
```

조회 결과 mongoDB 의 IPAdress 는 `170.17.0.2`

3. 웹 서버 컨테이너의 mongoDB 연결 코드의 IP 에 위의 IPAdress 를 넣는다.

그러나 이 방법은 **IPAdress 를 직접 조회하고, 코드에 넣어야 하는 불편함**이 있다.

이를 해결하기 위해 Docker Networks 가 등장했다.



<br />

### Docker Networks 로 컨테이너 간 통신 우아하게 처리하기

도커에서 제공하는 네트워크로, 다중 컨테이너 간의 통신을 허용하는 방법이다.

```shell
docker run --network my_network ...
```



이전의 mongoDB 컨테이너를 삭제하고, 아래 명령으로 도커 네트워크를 생성해보자.

```shell
docker network create favorites-net
```



이제 해당 네트워크에 컨테이너를 할당, 실행해보자.

```shell
docker run -d --name mongodb --network favorites-net mongo
```

> 같은 네트워크에 위치한 컨테이너끼리 통신할 때에는 -p 플래그로 포트를 열어주지 않아도 된다.



이후 `docker container inspect mongodb` 명령어를 입력하면, `HostConfig.NetworkMode` 에서 `favorites-net` 이라는 네트워크 이름을 찾을 수 있다.

이제 위에서 로컬 호스트 머신에 있는 mongoDB 와 웹 서버 컨테이너를 연결했던 URL 을 다시 보자.

 `mongodb://host.docker.internal:27017` 

이랬던 URL 을...

`mongodb://mongodb:27017`

이렇게 바꿔주면된다. 



host.docker.internal 자리에 들어간 mongodb 는 위에서 실행한 컨테이너 이름임에 주의하자. 같은 docker networks 에 속해 있으므로, **컨테이너 이름으로 IP 주소 를 대체**할 수 있는 것이다.



**여기서 중요한 것은, 도커는 외부를 향한 각각의 리퀘스트를 감지하고, IP 를 해결하는 것이지, 소스 코드를 대체하는게 아니라는 점이다.**



<br />



## 브라우저에서 실행되는 React 를 컨테이너에 넣을 때 주의할 점

리액트는 도커 컨테이너 내부에서 실행되는 javascript 가 아니라, 브라우저에서 실행되기 때문에, 컨테이너 이름을 http 통신에 사용할 수 없다



<br />



## DB + 백엔드 + 프론트엔드 컨테이너 실행 명령 정리

* mongoDB 컨테이너

```shell
docker run --name mongodb -v data:/data/db --rm -d --network goals-net -e MONGO_INITDB_ROOT_USERNAME=jun -e MONGO_INITDB_ROOT_PASSWORD=1234 mongo
```

* nodejs 컨테이너

```shell
docker run --name goals-backend -v path-to-project-root:/app -v logs:/app/logs -v app/node_modules -d --rm -p 80:80 --network goals-net goals-node
```

`-v path-to-project-root:/app` : 바인드 마운트로 소스 코드 수정이 컨테이너에 바로 반영되도록 함

`-v logs:/app/logs` : 기명 볼륨 logs 와 컨테이너 내부의 logs 폴더를 연결한다. log 는 컨테이너가 삭제되어도 유지되어야 하므로 기명 볼륨으로 한다.

`-v app/node_modules ` : 컨테이너 내부의 node_modules 폴더를 익명 볼륨에 연결한다. 이를 통해 로컬에 node_modules 폴더가 없더라도 바인딩 마운트로 인해 로컬과 컨테이너의 바인딩으로 인해 컨테이너 내부의 node_modules 가 삭제되지 않는다.  

* React 컨테이너 

```shell
docker run -v path-to-project-root/src:/app --name goals-fronted --rm -p 3000:3000 -it goals-react
```





1. 위 내용은 컨테이너 내부의 코드를 변경하는 바인딩 마운트를 사용하므로, 개발용으로만 적합하다는 문제가 있다.
2. 도커 컨테이너 실행 명령어가 너무 길다는 문제가 있다.
