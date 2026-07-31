# SearXNG Deployment

A professional, security-hardened deployment of SearXNG, a privacy-respecting metasearch engine.

## About SearXNG

SearXNG is a [metasearch engine](https://en.wikipedia.org/wiki/Metasearch_engine) that aggregates results from other search engines while ensuring user privacy by not storing any information about its users. It is designed to be hackable, open-source, and decentralized, allowing users to reclaim their digital freedom and avoid the profiling common in mainstream search engines.

This deployment comes with **+310 search engines** pre-configured to provide comprehensive results across various categories.

## Security Hardening

This instance is built with a security-first approach. The current configuration is the result of **five rounds penetration testing (pentest)**, ensuring maximum security and privacy for all users.

### Configuration Highlights

- **Security Headers**: Implemented via Nginx to prevent common web vulnerabilities:
  - `Content-Security-Policy` (CSP): Restricts resources to trusted sources.
  - `Strict-Transport-Security` (HSTS): Forces secure HTTPS connections.
  - `X-Frame-Options`: Prevents clickjacking by restricting framing to the same origin.
  - `X-Content-Type-Options`: Prevents MIME-type sniffing.
  - `Permissions-Policy`: Disables access to geolocation, microphone, and camera.
  - `Referrer-Policy`: Set to `no-referrer` to ensure maximum privacy.

- **Endpoint Protection**: Nginx is configured to block direct access to sensitive endpoints like `/config` and `/stats`.

- **Bot Detection & Rate Limiting**: Integrated bot detection system using a custom limiter configuration to mitigate abuse.
  - General settings are configured in `config/limiter.toml`.
  - Rate limits are implemented via sliding windows in `config/ip_limit.py`, ensuring that temporary blocks do not exceed one minute to allow normal user recovery.

## Project Structure

The deployment uses a containerized architecture for isolation and scalability:

- **Nginx**: Acts as a reverse proxy, handling SSL termination and applying security headers.
- **SearXNG**: The core metasearch engine service.
- **Valkey**: A high-performance data store used for caching to improve response times.

### Architecture & Security Flow

```text
      +---------------------------+
      |      Internet / User      |
      +-------------+-------------+
                    |
                    v
      +---------------------------+
      |      Nginx (Proxy)        | <--- [ Security Layer: SSL & Security Headers ]
      +-------------+-------------+
                    |
                    v
      +---------------------------+
      |       SearXNG (Core)      | <--- [ Security Layer: Rate Limiting & Bot Detection ]
      +------+--------------+-----+
              |              |
              v              v
+--------------+---+  +-------+----------------+
| Valkey (Caching) |  | External Search Engines|
+------------------+  +------------------------+
```

### Request Flow in config/ip_limit.py
 
```text
[ Incoming Request ]
        |
        v
+--------------------------+
|  Is it link-local &      | --(Yes)--> [ Allow Request ]
|  FILTER_LINK_LOCAL=false?|
+--------------------------+
        |
       (No)
        |
        v
+------------------------+
|  Is link_token enabled?| --(No)--> [ Vanilla Limiter ]
+------------------------+            - Window: SEARXNG_BURST_WINDOW / Max: SEARXNG_BURST_MAX
        |                             - Window: SEARXNG_LONG_WINDOW  / Max: SEARXNG_LONG_MAX
      (Yes)
        |
        v
+------------------------+
|    Is it suspicious?   | --(No)--> [ Allow Request ]
+------------------------+
        |
      (Yes)
        |
        v
[ Suspicious Limiter ]
1. Window: SEARXNG_SUSPICIOUS_IP_WINDOW / Max: SEARXNG_SUSPICIOUS_IP_MAX (Redirects to / if exceeded)
2. Window: SEARXNG_BURST_WINDOW         / Max: SEARXNG_BURST_MAX_SUSPICIOUS
3. Window: SEARXNG_LONG_WINDOW          / Max: SEARXNG_LONG_MAX_SUSPICIOUS
```

## Getting Started

### Prerequisites

- Docker and Docker Compose (or Podman and podman-compose) installed on your system.

### Commands

- **Start and stay same console**:

```bash
podman-compose up
```

- **Start with detached process**:

```bash
docker compose up -d
```

- **Stop**:

```bash
podman-compose down
```

- **Show live logs**:

```bash
podman-compose logs -f
```

### Example request command

You can use `curl` to perform searches and receive results in JSON format:

```bash
curl -kv "http://localhost:8888/search?q=python+test&format=json" -o python-test-result.json
```
