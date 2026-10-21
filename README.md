# LCM Service

Give it two numbers and get their least common multiple back. This small Ruby service turns `12` and `18` into a plain-text `36` with a single HTTP request.

## Try it locally

With [mise](https://mise.jdx.dev/) installed:

```sh
mise install
mise run setup
mise run dev
```

In another terminal:

```sh
curl 'http://localhost:8080/your_name_example_com?x=12&y=18'
```

You'll get `36`. Non-negative integers are accepted; zero returns `0`. Missing, invalid, or repeated parameters return `NaN`.

`PORT` defaults to `8080`. `EMAIL_ADDRESS` sets the endpoint name, replacing characters outside `A–Z`, `a–z`, and `0–9` with underscores. Its default is `your.name@example.com`; keep using an example address for public demos, since it appears in the URL.

## Run the checks

```sh
mise run check
```

This runs the tests and privacy checks.

## Run with Docker

```sh
docker build -t lcm-service .
docker run --rm -p 8080:8080 lcm-service
```

On a container host, build the root `Dockerfile` and use `/your_name_example_com?x=12&y=18` as the health check when using the default endpoint.

Also built with Ruby: [Marketline](https://github.com/aemorvayne/marketline), a stock explorer.
