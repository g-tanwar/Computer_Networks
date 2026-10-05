# D — Load balancing

**CONFIGURATION AVAILABLE.** The nginx site file lists both upstream servers:

- `10.7.4.38:3001` (Backend A)
- `10.7.17.154:3002` (Backend B)

Each has `max_fails=1` and `fail_timeout=10s`. The file is `02-Configuration-Bundle/edge/nginx-servers-team1.conf`.

**DEMONSTRATION SCREENSHOT NOT RETAINED.** Round-robin load balancing was tested during the lab session using eight consecutive HTTPS requests and produced alternating Backend A/B responses. The original terminal screenshot/output was not retained in the final evidence bundle.

This folder does not contain a screenshot, and none is marked available.
