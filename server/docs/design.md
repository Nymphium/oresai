# General Concepts
- Use eio than lwt/async
- Use caqti/ppx_rapper

### Not intented
- postgresql, pgx driver

  caqti-driver-{mysql,postgresql} がうまくビルドできなかったため一旦見送る

### Undetermined
- logger

## Challenging
- use effects in a web app

  effect-tsを参考にする
- domain-wide effect handling

  channelでeffect argumentsを送って､cps functionを返す-> 呼び出す?
