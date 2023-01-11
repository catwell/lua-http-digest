# http-digest CHANGELOG

## 1.3

- Drop initial 401 response body instead of concatenating both responses.

- Allow unauthenticated requests. If no credentials are provided, return the original 401 response.

- HTTP client is now configurable, which makes it possible to use Copas or LuaSec clients.
