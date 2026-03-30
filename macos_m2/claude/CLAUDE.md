# User-Level Instructions

## Curl

Always use explicit HTTP method flags when writing curl commands (e.g., `curl -X GET`, `curl -X POST`). This ensures permission rules can distinguish read-only requests from mutating ones.
