# Ruby LCM HTTP Service

A minimal Ruby GET endpoint that calculates the lowest common multiple (LCM) of two non-negative integers. Its HTTP response is plain text, never HTML or JSON.

## Run locally

Ruby 3.3 or newer is recommended. With Ruby selected in mise, install dependencies:

```bash
mise exec -- bundle install
```

Set your email and start the server:

```bash
EMAIL_ADDRESS='your.name@example.com' PORT=8080 mise exec -- bundle exec ruby server.rb
```

Use **your own email address** for `EMAIL_ADDRESS`. All characters other than `A-Z`, `a-z`, and `0-9` become underscores in the endpoint path.

```bash
curl -i 'http://localhost:8080/your_name_example_com?x=12&y=18'
```

Response HTTP status: `200`, `Content-Type: text/plain; charset=utf-8` and body exactly `36` (no newline).

An invalid number, duplicate `x` or `y`, or a missing argument produces the exact text `NaN`. Valid zero values return `0`.

Other paths return `404`. Methods other than `GET` return `405` with `Allow: GET` at the configured endpoint. Responses use plain text; `HEAD` responses have no body.

## Deploy with Docker

1. Upload this directory as a GitHub repository (with `Dockerfile`, `Gemfile`, `Gemfile.lock` and `server.rb` at the root).
2. Connect a Docker-capable host to this repository and build the root Dockerfile.
3. Under service **Variables**, set `EMAIL_ADDRESS` to your actual email address, e.g. `your.name@example.com`. The application reads the `PORT` variable provided by the host, and defaults to 8080.
4. Under service **Settings > Networking**, choose **Generate Domain** to expose the service publicly.
5. For a service hosted at `https://lcm.example.com`, the example endpoint is:

   `https://lcm.example.com/your_name_example_com?x=12&y=18`

The host/domain above is an **example**, not a deployed URL.

## Test

```bash
mise exec -- bundle exec ruby test/test_server.rb
```

Bundler installs `webrick` and the test dependency `minitest`. The tests cover LCM calculations, invalid and missing inputs, custom and default email paths, exact HTTP responses, and unsupported methods. The Docker image installs only runtime dependencies from `Gemfile.lock`.

If Ruby is already active in your shell, you can omit `mise exec --` from these commands.
