# Eyevinn Open Source Cloud - Processing History

This file tracks when this project was processed by the Eyevinn Open Source Cloud service builder.

## Changelog

- **2026-06-01T07:52:00.000Z**: Added OSC containerization artifacts (`Dockerfile.osc`, `osc-entrypoint.sh`, `.dockerignore`) by the OSC Supply Pipeline agent. Multi-stage build pins the official Keycloak 26.6.2 distribution onto a `ubi9-minimal` runtime with JDK 21 + bash. Build verified and runtime smoke-tested (Keycloak boots in prod profile, HTTP 302 -> /admin/).
- **2026-05-28T08:03:01.317Z**: Project synchronized with upstream by OSaaS Service Builder

---

*This changelog is automatically maintained by the [OSaaS Service Builder](https://www.osaas.io)*