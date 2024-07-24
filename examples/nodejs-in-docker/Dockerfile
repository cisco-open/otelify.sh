FROM node:22-alpine3.19

RUN apk add --no-cache bash~=5.2.21

WORKDIR /app
COPY package.json /app
RUN npm install
COPY . /app

ENTRYPOINT [ "node" ]
CMD ["app.js"]