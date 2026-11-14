# Itinerea Sync Server — protocol outline

**Status: outline only. Nothing here is implemented or final.** The protocol is designed at the start of phase 2, together with the choice of technology (PRD 4.7).

What is already decided by the PRD:

| Topic | Decision | PRD |
|---|---|---|
| Transport | WebSocket | 4.7, 9.4 |
| Payload | The same operations as file mode: `create`, `set`, `delete`, one JSON object each | 8.6 |
| Delivery | The server stores operations, snapshots and attachments and forwards operations at once to the connected participants | 9.4 |
| Latency | Changes reach the other participants within 2 seconds | 4.3 |
| Offline | The app queues operations and sends them when it reconnects | 9.4 |
| Roles | Owner, editor, viewer, enforced by the server | 4.4 |
| Extras | Presence and soft locking of notes | 4.7 |
| Encryption | Optional end-to-end encryption per trip: the server then stores data it cannot read | 4.3 |
| Hosting | Self-hosted only; the project runs no public instance | 1.4, 4.7 |

Still to design in phase 2:

- authentication of users and devices;
- message types and versioning;
- how a new device catches up (snapshot, then later operations);
- upload and download of attachments;
- limits (message size, rate) and error codes.
