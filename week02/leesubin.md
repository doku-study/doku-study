## Images & Image Layers
- 모든 커맨드는 레이어
- 레이어는 이미지끼리 공유됨.
- 이미지 다시 빌드할 때, 바뀐 레이어만 재빌드됨.
- 이미지는 docker hub 에서 가져올 수 있음.

## Understanding Image Tags
- name : tag
- name: defines a group of, possible more specialized, images / ex. node
- tag: defines a specialized image within a gorup of images / ex. 14

## Sharing Images & Containers
- Dockerfile
    - sourecode 가 필요함.
- Docker Image
    - 빌드 단계 필요없음.
    - 모든것이 이미지에 담겨있음.

## Sharing via Docker Hub or Private Registry
- Docker Hub
    - Official Docker Image Registry
    - public, private, official images
- Private Registry
    - Any provider / registry you want to use
    - Only your own Images

## Commands
- Dockerfile: EXPOSE (ex. EXPOSE 8000)
    - 문서를 위함, 실행에는 영향 주지 않고 따로 -p 옵션을 사용해야함.
- command: build
    - image 이름 지정
    - ex. docker build . -t kingsubin:231227
- command: run
    - attached default
    - ex. docker run --name mycontainer --rm -d -p 8000:8000 myimage:latest
- command: start
    - detached default
- command: cp
    - 호스트에서 컨테이너로, 컨테이너에서 호스트로 파일 복사
    - docker cp {source} {target}
        - docker cp {host file path} {container name}:{container file path}
        - docker cp {container name}:{container file path} {host file path}