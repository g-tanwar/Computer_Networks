# A — LAN setup

No ping or `netinfo` transcript was retained from the lab session. That output is optional. The lab addresses used everywhere else in this repository are:

| Person | Machine | IP | MAC | Role |
| --- | --- | --- | --- | --- |
| Piyush | Mac 1 | 10.7.17.154 | 10:9f:41:c0:9e:e5 | DNS and Backend B `:3002` |
| Gourav | Mac 2 | 10.7.18.35 | e6:09:91:27:22:3b | nginx, TLS, reverse proxy `:443` |
| Alok | Mac 3 | 10.7.4.38 | 72:36:67:c5:54:98 | Backend A `:3001`, client, Wireshark |

Network `10.7.0.0/19`. Gateway `10.7.0.1`. Mask `255.255.224.0`. Interface `en0`.
