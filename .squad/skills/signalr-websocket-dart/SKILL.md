# Skill: SignalR WebSocket Client in Dart (Manual JSON Protocol)

## When to Use
When you need real-time communication with an ASP.NET Core SignalR hub from Flutter/Dart and no dedicated SignalR Dart package is available.

## Pattern
Implement the SignalR JSON protocol manually over `web_socket_channel`:

1. **Handshake:** Send `{"protocol":"json","version":1}` + record separator (0x1E)
2. **Messages:** JSON terminated by 0x1E character
3. **Message types:** 1=Invocation, 6=Ping, 7=Close
4. **Invocations:** `{"type":1,"target":"MethodName","arguments":[...]}`
5. **Reconnect:** Exponential backoff (2s, 4s, 8s, 16s, 32s), max 5 attempts
6. **Auth:** JWT via query string `?access_token={token}`

## Reference Implementation
`sheetstorm_app/lib/features/song_broadcast/data/services/broadcast_service.dart`

## Key Dependencies
- `web_socket_channel: ^3.0.2`
