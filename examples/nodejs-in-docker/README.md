# Node.js in Docker

The following example demonstrates how you can add `otelify.sh` to an existing
containerized application, without changing the code of that application.

Before getting started, verify that you can run the application without instrumentation
using `docker` and `docker compose`:

```shell
docker compose up 
```

This will start a [Node.js application](./app.js) that you can connect to via
HTTP on port 8080:

```shell
$ curl localhost:8080
Hello world!
```

To instrument this application, update the [`docker-compose.yml`](./docker-compose.yml)
as follows:

```Dockerfile
version: "3"

services:
  app:
    image: otelify/nodejs-http-server
    build: .
    ports:
      - 8080:8080
    ### add otelify.sh via a mount and change entrypoint and command
    ### to wrap it around the application
    volumes:
     - ../../otelify.sh:/usr/bin/otelify.sh
    entrypoint: /usr/bin/otelify.sh
    command: ["app.js"]
    environment:
     - OTEL_TRACES_EXPORTER=otlp
     - OTEL_EXPORTER_OTLP_ENDPOINT=http://otel-collector:4318
     - OTEL_NODE_RESOURCE_DETECTORS=env,host,os,process,serviceinstance
     - OTEL_NODE_DISABLED_INSTRUMENTATIONS=fs

  # add an OpenTelemetry collector 
  otel-collector:
    image: otel/opentelemetry-collector
    volumes:
    - ./otel-collector-config.yaml:/etc/otelcol/config.yaml
    ports:
      - 4317:4317
      - 4318:4318
```

Next, re-run `docker compose up`. It will take a little longer to get the app
(and the collector) up and running, since the Node.js packages will be downloaded
at runtime. When you see the message `listening on port 8080` printed, run
`curl localhost:8080` once again. After a few seconds the OpenTelemetry Collector
will output detailed trace information.
