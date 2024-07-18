# otelify.sh - zero-code instrumentation for every application

[`otelify.sh`](./otelify.sh) is a shell script that allows you to instrument
almost any application without the need to touch the application's code. This
way you can extract telemetry out of an application within seconds. It utilizes
different zero-code instrumentation solutions provided by the
[OpenTelemetry project](https://opentelemetry.io/).

## Prerequisites

- [bash](https://www.gnu.org/software/bash/)
- [curl](https://curl.se/)

Depending on the applications you want to instrument, you will also need:

- `node`
- `dotnet`
- `java`

The supported versions of these depends on the used zero-code instrumentations,
provided by the OpenTelemetry project.

## Usage

Download `otelify.sh` and make it executable:

```bash
curl -v -L -O https://github.com/cisco-open/otelify.sh/releases/latest/download/otelify.sh
chmod +x otelify.sh
```

Then, use it as a wrapper around your instructions to run the application, e.g.

```bash
otelify.sh -- java -jar YourApplication.jar
```

This will automatically download the
[OpenTelemetry Java agent](https://opentelemetry.io/docs/languages/java/automatic/)
and add it to the Java application via the `javaagent` parameter.

Besides Java `otelify.sh` can also instrument .NET and Node.js applications for
you.

For Node.js you also use `otelify.sh` before calling `node`:

```bash
otelify.sh -- node your-app.js
```

This will automatically install the
[@opentelemetry/auto-instrumentations-node](https://www.npmjs.com/package/@opentelemetry/auto-instrumentations-node)
package and use the build in capabilities to instrument a Node.js application
without touching the code.

For .NET as well you only need to put `otelify.sh` in front of your command:

```bash
otelify.sh -- dotnet YourApplication.dll
```

This will automatically install the
[OpenTelemetry .NET Automatic Instrumentation](https://opentelemetry.io/docs/languages/net/automatic/)
and use it to instrument your application.

`otelify.sh` tries to detect the language of your application using different
information points. If it is not possible to detect the language, it will apply
**all** instrumentations at once. This way it may be lucky and pick the right
instrumentation by chance. If you do not want this behavior, run `otelify.sh` in
_strict mode_:

```bash
otelify.sh -s -- ./unknown-language.sh
```

This call will fail, because `otelify.sh` will not be able to detect any of the
support languages.

## More Documentation

Run `otelify.sh -h` to get a list of available options and environment
variables.

## Contributing

Pull requests and bug reports are welcome. For larger changes please create an
issue first to discuss your proposed changes and possible implications.

More more details please see the [CONTRIBUTING.md](./CONTRIBUTING.md)

## License

See [LICENSE](./LICENSE)
