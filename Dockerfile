FROM bats/bats:1.11.0

RUN \ 
  apk \
  --no-cache \
  --update \
  --repository=https://dl-cdn.alpinelinux.org/alpine/edge/community \
  add \
  nodejs=20.12.1-r0 \
  openjdk11=11.0.23_p9-r0 \
  curl=8.5.0-r0 \
  npm=10.2.5-r0 \
  ca-certificates=20240226-r0 \
  dotnet8-sdk=8.0.106-r0 \
  && update-ca-certificates
