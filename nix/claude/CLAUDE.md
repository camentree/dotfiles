# User-Level Instructions

## Curl

Always use explicit HTTP method flags when writing curl commands (e.g., `curl -X GET`, `curl -X POST`). This ensures permission rules can distinguish read-only requests from mutating ones.

## HTTP GETs

Prefer `WebFetch` over `curl | python`/`jq` pipelines for read-only HTTP GETs against public APIs or web pages. WebFetch can parse JSON/HTML and extract fields via its prompt argument, avoiding extra shell permission prompts.
