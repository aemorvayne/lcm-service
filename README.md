# LCM Service

A minimal Ruby GET endpoint that calculates the lowest common multiple (LCM) of two non-negative integers. Its HTTP response is plain text, never HTML or JSON.

## Run locally

Install the pinned tools and dependencies:

```bash
mise install
mise run setup
```

Set an example endpoint identifier and start the server:

```bash
EMAIL_ADDRESS='your.name@example.com' PORT=8080 mise run dev
```

All characters other than `A-Z`, `a-z`, and `0-9` in `EMAIL_ADDRESS` become underscores in the endpoint path. Use a reserved example address for public demonstrations: this value is reflected in the public URL, so it is not a secret.

```bash
curl -i 'http://localhost:8080/your_name_example_com?x=12&y=18'
```

Response HTTP status: `200`, `Content-Type: text/plain; charset=utf-8` and body exactly `36` (no newline).

An invalid number, duplicate `x` or `y`, or a missing argument produces the exact text `NaN`. Valid zero values return `0`.

Other paths return `404`. Methods other than `GET` return `405` with `Allow: GET` at the configured endpoint. Responses use plain text; `HEAD` responses have no body.

## Deploy with Docker

Connect a Docker-capable host to this repository and build its root `Dockerfile`. Set `EMAIL_ADDRESS` to a public example identifier such as `your.name@example.com`. The application reads the host's `PORT` and defaults to `8080`. Configure the health check to use the resulting endpoint with valid query parameters, for example `/your_name_example_com?x=12&y=18`.

No hosted deployment URL is configured yet.

## Test

```bash
mise run test
mise run privacy
```

Bundler installs `webrick` and the test dependency `minitest`. The tests cover LCM calculations, invalid and missing inputs, custom and default email paths, exact HTTP responses, and unsupported methods. The Docker image installs only runtime dependencies from `Gemfile.lock`.

The mise tasks keep Bundler and subprocesses on the pinned Ruby. The container uses the same pinned Ruby version.

## Public repository hygiene

`mise run setup` enables local Git hooks. The commit hook scans staged changes with pinned Gitleaks rules; the push hook and CI also scan the complete Git history. Findings are redacted. The rules detect supported credential formats, non-example email addresses, and private file paths; manual review remains necessary for personal data, metadata, and identifying prose.

Keep original briefs, supplied contact data, credentials, environment files, private notes, and unsanitized backups outside the repository and Docker build context. Public fixtures use reserved example domains. Store deployment secrets in the hosting provider's secret store.

Related project: [Marketline](https://github.com/aemorvayne/marketline).
