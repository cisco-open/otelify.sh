FROM bats/bats:1.11.0

RUN \ 
  apk \
  --no-cache \
  --update \
  --repository=https://dl-cdn.alpinelinux.org/alpine/edge/community \
  add \
  nodejs-current=21.7.3-r0 \
  openjdk11=11.0.24_p8-r0 \
  curl=8.5.0-r0 \
  npm=10.2.5-r0 \
  ca-certificates=20240226-r0 \
  dotnet8-sdk=8.0.107-r0 \
  && update-ca-certificates
