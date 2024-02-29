FROM bats/bats:latest

RUN \ 
  apk \
  --no-cache \
  --update \
  add \
  nodejs \
  openjdk11 \
  curl \
  npm

RUN apk add dotnet8-sdk --repository=https://dl-cdn.alpinelinux.org/alpine/edge/community

RUN apk --no-cache add ca-certificates && update-ca-certificates