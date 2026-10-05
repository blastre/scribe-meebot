# Contributing

Thanks for your interest in the project.

## Issues

GitHub Issues is the main feedback channel. When filing a bug, please include:

- What you ran (`make lite` / `make all`, or the specific service)
- The platform and meeting type involved
- Relevant logs — `docker compose logs <service>` is usually enough
- What you expected versus what happened

Look for `good-first-issue` if you want somewhere to start.

## Pull requests

1. Fork and branch from `main`.
2. Keep the change focused — one concern per PR.
3. Run the tests before opening: `make test`, and `make smoke` for anything
   touching the bot lifecycle or transcription path.
4. Match the style of the code you are editing.
5. Describe what changed and why in the PR body.

## Development setup

See [README.md](./README.md) for the quickstart. Service-specific notes live in
each `services/*/README.md`, and the test suite is documented in
[`tests3/README.md`](./tests3/README.md).

## License

By contributing, you agree that your contributions are licensed under the
Apache License 2.0, the same license that covers this project. See
[LICENSE](./LICENSE) and [NOTICE](./NOTICE).
