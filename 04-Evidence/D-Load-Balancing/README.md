# D — Load balancing

**CONFIGURATION AVAILABLE.** The nginx site file lists both upstream servers:

- `10.7.22.54:3001` (Backend A)
- `10.7.17.154:3002` (Backend B)

Each has `max_fails=1` and `fail_timeout=10s`. The file is `02-Configuration-Bundle/edge/nginx-servers-team1.conf`.

**DEMONSTRATION SCREENSHOT NOT RETAINED.** The final verified series was six consecutive HTTPS requests. `X-Backend` came back A, B, A, B, A, B. The terminal output was not saved.

This folder does not contain a screenshot, and none is marked available.
