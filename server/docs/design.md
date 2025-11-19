# General Concepts
- Use eio than lwt/async
- Use caqti/ppx_rapper

# 階層
- domain層
    - `domains`
        - `objects`
        - `values`

## Challenging
- use effects in a web app

  effect-tsを参考にする
- domain-wide effect handling

  channelでeffect argumentsを送って､cps functionを返す-> 呼び出す?
