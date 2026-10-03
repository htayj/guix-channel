;;; npm source tarballs for pi-coding-agent 0.84.2
;;; Generated from packages/coding-agent/install-lock/package-lock.json.
;;; Integrity provenance: 133 packages verified against lockfile sha512
;;; integrity; 7 @earendil-works packages (all 0.84.2) lack lockfile
;;; integrity and were verified against npm registry dist metadata
;;; sha512 values (pinned in files/pi-coding-agent-notices.py).
;;; Every path is the original lockfile node_modules path; duplicates are
;;; preserved and platform-specific optional dependencies are all present.

(define-module (tay packages pi-coding-agent-npm-sources)
  #:export (%pi-coding-agent-npm-sources)
  #:use-module (guix download)
  #:use-module (guix packages))

(define-public %pi-coding-agent-npm-sources
  (list
    (list "node_modules/@anthropic-ai/sdk"
          (origin
            (method url-fetch)
            (uri "https://registry.npmjs.org/@anthropic-ai/sdk/-/sdk-0.91.1.tgz")
            (file-name "sdk-0.91.1.tgz")
            (sha256
             (base32 "1hpv308b2yvcn35abq8nsb5zc30bcmxdxshgr3xhv60py86dj75w"))))
    (list "node_modules/@aws-crypto/crc32"
          (origin
            (method url-fetch)
            (uri "https://registry.npmjs.org/@aws-crypto/crc32/-/crc32-5.2.0.tgz")
            (file-name "crc32-5.2.0.tgz")
            (sha256
             (base32 "0zal3pj8lrh9f1g5wh3f8hgsl94i8qs1lrdfdia95lv1mzqc6s7d"))))
    (list "node_modules/@aws-crypto/sha256-browser"
          (origin
            (method url-fetch)
            (uri "https://registry.npmjs.org/@aws-crypto/sha256-browser/-/sha256-browser-5.2.0.tgz")
            (file-name "sha256-browser-5.2.0.tgz")
            (sha256
             (base32 "13f23v4d91h48a6j6j9517vzywa6rp9y3hdsb7ns9z04g2y38900"))))
    (list "node_modules/@aws-crypto/sha256-js"
          (origin
            (method url-fetch)
            (uri "https://registry.npmjs.org/@aws-crypto/sha256-js/-/sha256-js-5.2.0.tgz")
            (file-name "sha256-js-5.2.0.tgz")
            (sha256
             (base32 "0sm9wi14sj7qsscgdwpfkss1slc5s8r4by7glvi5kqdi9y5n6l2p"))))
    (list "node_modules/@aws-crypto/supports-web-crypto"
          (origin
            (method url-fetch)
            (uri "https://registry.npmjs.org/@aws-crypto/supports-web-crypto/-/supports-web-crypto-5.2.0.tgz")
            (file-name "supports-web-crypto-5.2.0.tgz")
            (sha256
             (base32 "1f3x1j89zi8hdnf8sdyidslklcf8kvgvl3clixj50rb10z6r216l"))))
    (list "node_modules/@aws-crypto/util"
          (origin
            (method url-fetch)
            (uri "https://registry.npmjs.org/@aws-crypto/util/-/util-5.2.0.tgz")
            (file-name "util-5.2.0.tgz")
            (sha256
             (base32 "1lvjyz8d2g5lpy6wxfhqgyji61nz8qzl62g04awjhnfvgayrmaj2"))))
    (list "node_modules/@aws-sdk/client-bedrock-runtime"
          (origin
            (method url-fetch)
            (uri "https://registry.npmjs.org/@aws-sdk/client-bedrock-runtime/-/client-bedrock-runtime-3.1048.0.tgz")
            (file-name "client-bedrock-runtime-3.1048.0.tgz")
            (sha256
             (base32 "0ayqqflicslxm612s8bcc5gg23a5nxlkfz7n8h6g161k9lbvhkkj"))))
    (list "node_modules/@aws-sdk/core"
          (origin
            (method url-fetch)
            (uri "https://registry.npmjs.org/@aws-sdk/core/-/core-3.974.11.tgz")
            (file-name "core-3.974.11.tgz")
            (sha256
             (base32 "149kvc57n2prn2y56i4q104jr7i36asl0nfhn3pb5k2cpq70qphn"))))
    (list "node_modules/@aws-sdk/credential-provider-env"
          (origin
            (method url-fetch)
            (uri "https://registry.npmjs.org/@aws-sdk/credential-provider-env/-/credential-provider-env-3.972.37.tgz")
            (file-name "credential-provider-env-3.972.37.tgz")
            (sha256
             (base32 "09wf2fv7p3nxz8cic4aiwzwckalk49z1xhfyyyqcp0pkjmxddlni"))))
    (list "node_modules/@aws-sdk/credential-provider-http"
          (origin
            (method url-fetch)
            (uri "https://registry.npmjs.org/@aws-sdk/credential-provider-http/-/credential-provider-http-3.972.39.tgz")
            (file-name "credential-provider-http-3.972.39.tgz")
            (sha256
             (base32 "1hkfkgwjbg083xprhnx2a1kwsg80bad358gn6bn5xz5n25rjlr6l"))))
    (list "node_modules/@aws-sdk/credential-provider-ini"
          (origin
            (method url-fetch)
            (uri "https://registry.npmjs.org/@aws-sdk/credential-provider-ini/-/credential-provider-ini-3.972.41.tgz")
            (file-name "credential-provider-ini-3.972.41.tgz")
            (sha256
             (base32 "181qh870azhj8yxzf9cm79n538mzccsgxv3a6iny9jfz1hbw5hjn"))))
    (list "node_modules/@aws-sdk/credential-provider-login"
          (origin
            (method url-fetch)
            (uri "https://registry.npmjs.org/@aws-sdk/credential-provider-login/-/credential-provider-login-3.972.41.tgz")
            (file-name "credential-provider-login-3.972.41.tgz")
            (sha256
             (base32 "1mw0sg5sr7szwm1xczbmysmk0ai4f2cbw015p5dxwndkliqk0n64"))))
    (list "node_modules/@aws-sdk/credential-provider-node"
          (origin
            (method url-fetch)
            (uri "https://registry.npmjs.org/@aws-sdk/credential-provider-node/-/credential-provider-node-3.972.42.tgz")
            (file-name "credential-provider-node-3.972.42.tgz")
            (sha256
             (base32 "1wshapg573sa5iq1zsg16hw0n4380m2xiwphmwmf18nr9vyz09h4"))))
    (list "node_modules/@aws-sdk/credential-provider-process"
          (origin
            (method url-fetch)
            (uri "https://registry.npmjs.org/@aws-sdk/credential-provider-process/-/credential-provider-process-3.972.37.tgz")
            (file-name "credential-provider-process-3.972.37.tgz")
            (sha256
             (base32 "0ar6jwwrgvlyrs8anqyfkijpsj9l9glyy7chd8q2whviys6nilmx"))))
    (list "node_modules/@aws-sdk/credential-provider-sso"
          (origin
            (method url-fetch)
            (uri "https://registry.npmjs.org/@aws-sdk/credential-provider-sso/-/credential-provider-sso-3.972.41.tgz")
            (file-name "credential-provider-sso-3.972.41.tgz")
            (sha256
             (base32 "1p78jrwi2f4pinqx7m2nc10k2fgm7zlmy9mimzb7rk20s3pdrjks"))))
    (list "node_modules/@aws-sdk/credential-provider-web-identity"
          (origin
            (method url-fetch)
            (uri "https://registry.npmjs.org/@aws-sdk/credential-provider-web-identity/-/credential-provider-web-identity-3.972.41.tgz")
            (file-name "credential-provider-web-identity-3.972.41.tgz")
            (sha256
             (base32 "0fxywvih07mp7fpzm5jg0j31by90anjyxylgihs5znf03jk7g854"))))
    (list "node_modules/@aws-sdk/eventstream-handler-node"
          (origin
            (method url-fetch)
            (uri "https://registry.npmjs.org/@aws-sdk/eventstream-handler-node/-/eventstream-handler-node-3.972.16.tgz")
            (file-name "eventstream-handler-node-3.972.16.tgz")
            (sha256
             (base32 "0ssbxgc64jwvw8m19hi3a70nds5wyc57aqn2i6zw6zw04s0a10bv"))))
    (list "node_modules/@aws-sdk/middleware-eventstream"
          (origin
            (method url-fetch)
            (uri "https://registry.npmjs.org/@aws-sdk/middleware-eventstream/-/middleware-eventstream-3.972.12.tgz")
            (file-name "middleware-eventstream-3.972.12.tgz")
            (sha256
             (base32 "15m84laq94wcyp02w5kkp1b2wwf8x6s1hk4zkyx0clvsh9q8pc7k"))))
    (list "node_modules/@aws-sdk/middleware-websocket"
          (origin
            (method url-fetch)
            (uri "https://registry.npmjs.org/@aws-sdk/middleware-websocket/-/middleware-websocket-3.972.19.tgz")
            (file-name "middleware-websocket-3.972.19.tgz")
            (sha256
             (base32 "10hb6d2diw1l7mjp847x0ixbmwsb18w8jmmc9skgc5z5l1ml38rq"))))
    (list "node_modules/@aws-sdk/nested-clients"
          (origin
            (method url-fetch)
            (uri "https://registry.npmjs.org/@aws-sdk/nested-clients/-/nested-clients-3.997.9.tgz")
            (file-name "nested-clients-3.997.9.tgz")
            (sha256
             (base32 "0hp2zml431476dgy8jrq1sksb0ll96isldhvzx4clil2fi51byvl"))))
    (list "node_modules/@aws-sdk/signature-v4-multi-region"
          (origin
            (method url-fetch)
            (uri "https://registry.npmjs.org/@aws-sdk/signature-v4-multi-region/-/signature-v4-multi-region-3.996.27.tgz")
            (file-name "signature-v4-multi-region-3.996.27.tgz")
            (sha256
             (base32 "1clp1mbxb4418b7yprfi08vmscphjszcddzcvvksl9srnmdjd7h4"))))
    (list "node_modules/@aws-sdk/token-providers"
          (origin
            (method url-fetch)
            (uri "https://registry.npmjs.org/@aws-sdk/token-providers/-/token-providers-3.1048.0.tgz")
            (file-name "token-providers-3.1048.0.tgz")
            (sha256
             (base32 "1bsk3lx3iry076imksh7n2s1cfminlvx1vfqw5qgw0z6fz1rbvlw"))))
    (list "node_modules/@aws-sdk/types"
          (origin
            (method url-fetch)
            (uri "https://registry.npmjs.org/@aws-sdk/types/-/types-3.973.8.tgz")
            (file-name "types-3.973.8.tgz")
            (sha256
             (base32 "1fv6gsigs2agiiv82y8ssgaycj4ladw7lnjz5q8w5ph87hhxxvpz"))))
    (list "node_modules/@aws-sdk/util-locate-window"
          (origin
            (method url-fetch)
            (uri "https://registry.npmjs.org/@aws-sdk/util-locate-window/-/util-locate-window-3.965.5.tgz")
            (file-name "util-locate-window-3.965.5.tgz")
            (sha256
             (base32 "07kk7mvc8mjqzvpp5w4fm1dvcarkqigx2k0wmqaizkj7qyy1v1nd"))))
    (list "node_modules/@aws-sdk/xml-builder"
          (origin
            (method url-fetch)
            (uri "https://registry.npmjs.org/@aws-sdk/xml-builder/-/xml-builder-3.972.24.tgz")
            (file-name "xml-builder-3.972.24.tgz")
            (sha256
             (base32 "1i7hp581gg590c4a04wic8hg8i4ay2nld6jfp3c4fxbqnffkgrl0"))))
    (list "node_modules/@aws/lambda-invoke-store"
          (origin
            (method url-fetch)
            (uri "https://registry.npmjs.org/@aws/lambda-invoke-store/-/lambda-invoke-store-0.2.4.tgz")
            (file-name "lambda-invoke-store-0.2.4.tgz")
            (sha256
             (base32 "0n9ivba53975rf6fl5j7jafnv5nzsmf7srpsd2n751vl7bvsxg7n"))))
    (list "node_modules/@babel/runtime"
          (origin
            (method url-fetch)
            (uri "https://registry.npmjs.org/@babel/runtime/-/runtime-7.29.2.tgz")
            (file-name "runtime-7.29.2.tgz")
            (sha256
             (base32 "1rc71zqm9k7cwhhqrn7v0njgk04vw5ppznlbbshcq545kskdvmli"))))
    (list "node_modules/@earendil-works/pi-agent-core"
          (origin
            (method url-fetch)
            (uri "https://registry.npmjs.org/@earendil-works/pi-agent-core/-/pi-agent-core-0.84.2.tgz")
            (file-name "pi-agent-core-0.84.2.tgz")
            (sha256
             (base32 "1kxxsgx4pfr2nhgy9nx78gfdwwjxl698dlhmv5lzy2bcdwn5snsn"))))
    (list "node_modules/@earendil-works/pi-ai"
          (origin
            (method url-fetch)
            (uri "https://registry.npmjs.org/@earendil-works/pi-ai/-/pi-ai-0.84.2.tgz")
            (file-name "pi-ai-0.84.2.tgz")
            (sha256
             (base32 "0hfgv921j2jg3hhv26zgsa4yygp25smsgn3cb7n2xsxhfrd7hqh2"))))
    (list "node_modules/@earendil-works/pi-client"
          (origin
            (method url-fetch)
            (uri "https://registry.npmjs.org/@earendil-works/pi-client/-/pi-client-0.84.2.tgz")
            (file-name "pi-client-0.84.2.tgz")
            (sha256
             (base32 "0v7nspgqjn1zq7gy53s2dsr5mapd60p5r03h6rs8bssnanl60yyi"))))
    (list "node_modules/@earendil-works/pi-coding-agent"
          (origin
            (method url-fetch)
            (uri "https://registry.npmjs.org/@earendil-works/pi-coding-agent/-/pi-coding-agent-0.84.2.tgz")
            (file-name "pi-coding-agent-0.84.2.tgz")
            (sha256
             (base32 "1ylglvqwga8scrb4f7vx79ay6dbl8amk7gy7fh0iy30sgg6rkf4m"))))
    (list "node_modules/@earendil-works/pi-protocol"
          (origin
            (method url-fetch)
            (uri "https://registry.npmjs.org/@earendil-works/pi-protocol/-/pi-protocol-0.84.2.tgz")
            (file-name "pi-protocol-0.84.2.tgz")
            (sha256
             (base32 "1pidcriarncpvkgls5q58zfrvzbjjv6k2rav4gr8kdnpigzczz6y"))))
    (list "node_modules/@earendil-works/pi-telemetry"
          (origin
            (method url-fetch)
            (uri "https://registry.npmjs.org/@earendil-works/pi-telemetry/-/pi-telemetry-0.84.2.tgz")
            (file-name "pi-telemetry-0.84.2.tgz")
            (sha256
             (base32 "0w25g2j6mzzxjpbnxjwmn359lbkj029gb1cgv3082z5g91zaq2zx"))))
    (list "node_modules/@earendil-works/pi-tui"
          (origin
            (method url-fetch)
            (uri "https://registry.npmjs.org/@earendil-works/pi-tui/-/pi-tui-0.84.2.tgz")
            (file-name "pi-tui-0.84.2.tgz")
            (sha256
             (base32 "0glrvz01zk0r9kgn00vsnnmnvivz4y24k2qv6kyp959ahmnw5gis"))))
    (list "node_modules/@google/genai"
          (origin
            (method url-fetch)
            (uri "https://registry.npmjs.org/@google/genai/-/genai-1.52.0.tgz")
            (file-name "genai-1.52.0.tgz")
            (sha256
             (base32 "108rbj4inq67nxc61vlrwdsb3z033k16fsvp853qw46ynb1g8285"))))
    (list "node_modules/@mariozechner/clipboard"
          (origin
            (method url-fetch)
            (uri "https://registry.npmjs.org/@mariozechner/clipboard/-/clipboard-0.3.9.tgz")
            (file-name "clipboard-0.3.9.tgz")
            (sha256
             (base32 "0fandgc1s8qwyg3njw3xqdj4nzh5d6c1kyfm3lyxzymgxjz6x615"))))
    (list "node_modules/@mariozechner/clipboard-darwin-arm64"
          (origin
            (method url-fetch)
            (uri "https://registry.npmjs.org/@mariozechner/clipboard-darwin-arm64/-/clipboard-darwin-arm64-0.3.9.tgz")
            (file-name "clipboard-darwin-arm64-0.3.9.tgz")
            (sha256
             (base32 "0grv8f63dvj0nrz13mf6w9xpfdx8mq03zcx3zvns137pzyszb2sg"))))
    (list "node_modules/@mariozechner/clipboard-darwin-universal"
          (origin
            (method url-fetch)
            (uri "https://registry.npmjs.org/@mariozechner/clipboard-darwin-universal/-/clipboard-darwin-universal-0.3.9.tgz")
            (file-name "clipboard-darwin-universal-0.3.9.tgz")
            (sha256
             (base32 "1wrf9iilmrfn7xl6p9gay0y8f67idnzvqpwq0jw80ghvsqb206j2"))))
    (list "node_modules/@mariozechner/clipboard-darwin-x64"
          (origin
            (method url-fetch)
            (uri "https://registry.npmjs.org/@mariozechner/clipboard-darwin-x64/-/clipboard-darwin-x64-0.3.9.tgz")
            (file-name "clipboard-darwin-x64-0.3.9.tgz")
            (sha256
             (base32 "0rgq3v6a0a6ibi888aczngxxl31by6zj828xj01cbjbhkizkiar4"))))
    (list "node_modules/@mariozechner/clipboard-linux-arm64-gnu"
          (origin
            (method url-fetch)
            (uri "https://registry.npmjs.org/@mariozechner/clipboard-linux-arm64-gnu/-/clipboard-linux-arm64-gnu-0.3.9.tgz")
            (file-name "clipboard-linux-arm64-gnu-0.3.9.tgz")
            (sha256
             (base32 "0bfljkdmgjwbvh9nwkn8h6v8bfd459r0ijwq6sd0jd5mb9bvfbk5"))))
    (list "node_modules/@mariozechner/clipboard-linux-arm64-musl"
          (origin
            (method url-fetch)
            (uri "https://registry.npmjs.org/@mariozechner/clipboard-linux-arm64-musl/-/clipboard-linux-arm64-musl-0.3.9.tgz")
            (file-name "clipboard-linux-arm64-musl-0.3.9.tgz")
            (sha256
             (base32 "0zs5c9pc7xbr1x8c1rm091brkzakz6slx57jpvx9m3pvivc9vc3i"))))
    (list "node_modules/@mariozechner/clipboard-linux-riscv64-gnu"
          (origin
            (method url-fetch)
            (uri "https://registry.npmjs.org/@mariozechner/clipboard-linux-riscv64-gnu/-/clipboard-linux-riscv64-gnu-0.3.9.tgz")
            (file-name "clipboard-linux-riscv64-gnu-0.3.9.tgz")
            (sha256
             (base32 "0abj2qgv4zwh5wl6jlgy8fs8ah6c7i9znlmza4c3lc3fr875p3dh"))))
    (list "node_modules/@mariozechner/clipboard-linux-x64-gnu"
          (origin
            (method url-fetch)
            (uri "https://registry.npmjs.org/@mariozechner/clipboard-linux-x64-gnu/-/clipboard-linux-x64-gnu-0.3.9.tgz")
            (file-name "clipboard-linux-x64-gnu-0.3.9.tgz")
            (sha256
             (base32 "0pmhprb9cmb5ly99c31nvxfiscd2nz3dydr9j5b1168qj954ysqh"))))
    (list "node_modules/@mariozechner/clipboard-linux-x64-musl"
          (origin
            (method url-fetch)
            (uri "https://registry.npmjs.org/@mariozechner/clipboard-linux-x64-musl/-/clipboard-linux-x64-musl-0.3.9.tgz")
            (file-name "clipboard-linux-x64-musl-0.3.9.tgz")
            (sha256
             (base32 "0f1kvckka4pcc18idm17dvky9asdbd8ph48ns4qsma840clgbv09"))))
    (list "node_modules/@mariozechner/clipboard-win32-arm64-msvc"
          (origin
            (method url-fetch)
            (uri "https://registry.npmjs.org/@mariozechner/clipboard-win32-arm64-msvc/-/clipboard-win32-arm64-msvc-0.3.9.tgz")
            (file-name "clipboard-win32-arm64-msvc-0.3.9.tgz")
            (sha256
             (base32 "0058h1g643cwvb76akyq4v26rk5gw9jphgzjaijk50jfwcihl18w"))))
    (list "node_modules/@mariozechner/clipboard-win32-x64-msvc"
          (origin
            (method url-fetch)
            (uri "https://registry.npmjs.org/@mariozechner/clipboard-win32-x64-msvc/-/clipboard-win32-x64-msvc-0.3.9.tgz")
            (file-name "clipboard-win32-x64-msvc-0.3.9.tgz")
            (sha256
             (base32 "1cb53pj9skdk67xcqcc5mwaqx77z975f97hrznfsddjjj9haqs6x"))))
    (list "node_modules/@nodable/entities"
          (origin
            (method url-fetch)
            (uri "https://registry.npmjs.org/@nodable/entities/-/entities-2.1.0.tgz")
            (file-name "entities-2.1.0.tgz")
            (sha256
             (base32 "13aiwcxyma79khgisbsna0i0rg886fg8a42na3jyq64syl2l71lw"))))
    (list "node_modules/@opentelemetry/api"
          (origin
            (method url-fetch)
            (uri "https://registry.npmjs.org/@opentelemetry/api/-/api-1.9.0.tgz")
            (file-name "api-1.9.0.tgz")
            (sha256
             (base32 "12yslgc9dpvx2kcmj687mw8wg8qn940wccr2acjapd47zcdk58qr"))))
    (list "node_modules/@protobufjs/aspromise"
          (origin
            (method url-fetch)
            (uri "https://registry.npmjs.org/@protobufjs/aspromise/-/aspromise-1.1.2.tgz")
            (file-name "aspromise-1.1.2.tgz")
            (sha256
             (base32 "06f1w67bgnw3zr7hbhv0yfbzz5mwbqsnc1jyri5zmwh9ha5qfh80"))))
    (list "node_modules/@protobufjs/base64"
          (origin
            (method url-fetch)
            (uri "https://registry.npmjs.org/@protobufjs/base64/-/base64-1.1.2.tgz")
            (file-name "base64-1.1.2.tgz")
            (sha256
             (base32 "0shs0f28zn7q7vprwlh6kzfrnmsg2h94rhyzii3i4ma4w7k6wznn"))))
    (list "node_modules/@protobufjs/codegen"
          (origin
            (method url-fetch)
            (uri "https://registry.npmjs.org/@protobufjs/codegen/-/codegen-2.0.5.tgz")
            (file-name "codegen-2.0.5.tgz")
            (sha256
             (base32 "009sl5cds5r1ikixc091pib9mvysiscl3a2h4hxa5jqv4b8zxfi0"))))
    (list "node_modules/@protobufjs/eventemitter"
          (origin
            (method url-fetch)
            (uri "https://registry.npmjs.org/@protobufjs/eventemitter/-/eventemitter-1.1.1.tgz")
            (file-name "eventemitter-1.1.1.tgz")
            (sha256
             (base32 "0z3r58vyqxn745pq700l9w1l1gif6n785ldd3lf7fbh6ny6bjdjm"))))
    (list "node_modules/@protobufjs/fetch"
          (origin
            (method url-fetch)
            (uri "https://registry.npmjs.org/@protobufjs/fetch/-/fetch-1.1.1.tgz")
            (file-name "fetch-1.1.1.tgz")
            (sha256
             (base32 "0s3jicdxhgqjsrdi18qvpgvp6fzbiqsz4f82ig1y3g6ycaf1sj2l"))))
    (list "node_modules/@protobufjs/float"
          (origin
            (method url-fetch)
            (uri "https://registry.npmjs.org/@protobufjs/float/-/float-1.0.2.tgz")
            (file-name "float-1.0.2.tgz")
            (sha256
             (base32 "0bbivv9vgs7myqayb6akklb35470lvkahlidc1abg09jsl9ddcr0"))))
    (list "node_modules/@protobufjs/path"
          (origin
            (method url-fetch)
            (uri "https://registry.npmjs.org/@protobufjs/path/-/path-1.1.2.tgz")
            (file-name "path-1.1.2.tgz")
            (sha256
             (base32 "131jr8ykzasqh4hjg7r15mnyirxqafxs4da5fgakcg0p23llwdnc"))))
    (list "node_modules/@protobufjs/pool"
          (origin
            (method url-fetch)
            (uri "https://registry.npmjs.org/@protobufjs/pool/-/pool-1.1.0.tgz")
            (file-name "pool-1.1.0.tgz")
            (sha256
             (base32 "00r7ffp1skf16ad4dzl2z2ffzhrwl3vyj6mzqb8wgll2fb9dn8gp"))))
    (list "node_modules/@protobufjs/utf8"
          (origin
            (method url-fetch)
            (uri "https://registry.npmjs.org/@protobufjs/utf8/-/utf8-1.1.1.tgz")
            (file-name "utf8-1.1.1.tgz")
            (sha256
             (base32 "1vvk8s39nfi6sjhaf2fwsqkrh5q33qvv965fl7hak5ar09nlxsj6"))))
    (list "node_modules/@silvia-odwyer/photon-node"
          (origin
            (method url-fetch)
            (uri "https://registry.npmjs.org/@silvia-odwyer/photon-node/-/photon-node-0.3.4.tgz")
            (file-name "photon-node-0.3.4.tgz")
            (sha256
             (base32 "02n55fjxr7nj92whzzyja8pvjisjk0lnkn9d94y8xhyj3if028ss"))))
    (list "node_modules/@smithy/core"
          (origin
            (method url-fetch)
            (uri "https://registry.npmjs.org/@smithy/core/-/core-3.24.3.tgz")
            (file-name "core-3.24.3.tgz")
            (sha256
             (base32 "0ka6190g26iq2j7n7qazlf8jjp75v5j0lvzx1gprdyykb75myxhh"))))
    (list "node_modules/@smithy/credential-provider-imds"
          (origin
            (method url-fetch)
            (uri "https://registry.npmjs.org/@smithy/credential-provider-imds/-/credential-provider-imds-4.3.3.tgz")
            (file-name "credential-provider-imds-4.3.3.tgz")
            (sha256
             (base32 "16mc723n3ymhi6hqxvsvg9qrglp6cxhdb30c8w8gp9sjpyblb2iv"))))
    (list "node_modules/@smithy/fetch-http-handler"
          (origin
            (method url-fetch)
            (uri "https://registry.npmjs.org/@smithy/fetch-http-handler/-/fetch-http-handler-5.4.3.tgz")
            (file-name "fetch-http-handler-5.4.3.tgz")
            (sha256
             (base32 "0yr6m5spd2dz0hy61dc30la4wyrn5jiaaai5vdzjasr7ildcmi7i"))))
    (list "node_modules/@smithy/is-array-buffer"
          (origin
            (method url-fetch)
            (uri "https://registry.npmjs.org/@smithy/is-array-buffer/-/is-array-buffer-2.2.0.tgz")
            (file-name "is-array-buffer-2.2.0.tgz")
            (sha256
             (base32 "1ggpdqnyl7yrvmskk8n624awp9wj9br8kfqw4p0plvbmn03jdx1l"))))
    (list "node_modules/@smithy/node-http-handler"
          (origin
            (method url-fetch)
            (uri "https://registry.npmjs.org/@smithy/node-http-handler/-/node-http-handler-4.7.3.tgz")
            (file-name "node-http-handler-4.7.3.tgz")
            (sha256
             (base32 "0qa4c9v6mkiha90cbryfpraf23s9147px9jl5nfavq3klbksz0rp"))))
    (list "node_modules/@smithy/signature-v4"
          (origin
            (method url-fetch)
            (uri "https://registry.npmjs.org/@smithy/signature-v4/-/signature-v4-5.4.3.tgz")
            (file-name "signature-v4-5.4.3.tgz")
            (sha256
             (base32 "0ixdppjn287gfl5gv3dx1g6yjw4bf5xn8b8ps2qkyhxivyk2836r"))))
    (list "node_modules/@smithy/types"
          (origin
            (method url-fetch)
            (uri "https://registry.npmjs.org/@smithy/types/-/types-4.14.2.tgz")
            (file-name "types-4.14.2.tgz")
            (sha256
             (base32 "0ia2gj6splzym92rsfccs5ax1d27pck9jk06jghipmbffmgf2604"))))
    (list "node_modules/@smithy/util-buffer-from"
          (origin
            (method url-fetch)
            (uri "https://registry.npmjs.org/@smithy/util-buffer-from/-/util-buffer-from-2.2.0.tgz")
            (file-name "util-buffer-from-2.2.0.tgz")
            (sha256
             (base32 "1y5ifi0nicvi35k0vf8663limqa387vq0qyywi8qq64b6v9in515"))))
    (list "node_modules/@smithy/util-utf8"
          (origin
            (method url-fetch)
            (uri "https://registry.npmjs.org/@smithy/util-utf8/-/util-utf8-2.3.0.tgz")
            (file-name "util-utf8-2.3.0.tgz")
            (sha256
             (base32 "06h2zai4w7sv0d8cd5830bbza4zl9g0y2ch37n49r91j79ngadxi"))))
    (list "node_modules/@types/node"
          (origin
            (method url-fetch)
            (uri "https://registry.npmjs.org/@types/node/-/node-22.19.19.tgz")
            (file-name "node-22.19.19.tgz")
            (sha256
             (base32 "1i6mb3p72r2rkyfwpd7v5551x3z4p34g82yy89ify85p1as3faf3"))))
    (list "node_modules/agent-base"
          (origin
            (method url-fetch)
            (uri "https://registry.npmjs.org/agent-base/-/agent-base-7.1.4.tgz")
            (file-name "agent-base-7.1.4.tgz")
            (sha256
             (base32 "0zmmkk3xhnkwb6djnvri7zyxllsdz5aa5w83x7afi959d0badm3x"))))
    (list "node_modules/balanced-match"
          (origin
            (method url-fetch)
            (uri "https://registry.npmjs.org/balanced-match/-/balanced-match-4.0.4.tgz")
            (file-name "balanced-match-4.0.4.tgz")
            (sha256
             (base32 "05pva90symmxg31miw4msmd9g0q1aspf7764pcqybvi5j66m09ch"))))
    (list "node_modules/base64-js"
          (origin
            (method url-fetch)
            (uri "https://registry.npmjs.org/base64-js/-/base64-js-1.5.1.tgz")
            (file-name "base64-js-1.5.1.tgz")
            (sha256
             (base32 "118a46skxnrgx5bdd68ny9xxjcvyb7b1clj2hf82d196nm2skdxi"))))
    (list "node_modules/bignumber.js"
          (origin
            (method url-fetch)
            (uri "https://registry.npmjs.org/bignumber.js/-/bignumber.js-9.3.1.tgz")
            (file-name "bignumber.js-9.3.1.tgz")
            (sha256
             (base32 "10ifa4ic5in9v44xgafclh1fxi5py4pyvamdp56gcrhf57m47agm"))))
    (list "node_modules/bowser"
          (origin
            (method url-fetch)
            (uri "https://registry.npmjs.org/bowser/-/bowser-2.14.1.tgz")
            (file-name "bowser-2.14.1.tgz")
            (sha256
             (base32 "186a857fp2d7sh47byjd1qffcmfrsiwqk920jyphqnz2l5bs40cp"))))
    (list "node_modules/brace-expansion"
          (origin
            (method url-fetch)
            (uri "https://registry.npmjs.org/brace-expansion/-/brace-expansion-5.0.9.tgz")
            (file-name "brace-expansion-5.0.9.tgz")
            (sha256
             (base32 "1byvabmks50gs4l1w563hjwi2xxmnz2lvnwn1klvwp6jvlgh01jx"))))
    (list "node_modules/buffer-equal-constant-time"
          (origin
            (method url-fetch)
            (uri "https://registry.npmjs.org/buffer-equal-constant-time/-/buffer-equal-constant-time-1.0.1.tgz")
            (file-name "buffer-equal-constant-time-1.0.1.tgz")
            (sha256
             (base32 "0np7kzq65a7yvs7ch5vrhm6i9ayv7v3lqspdaiw3w422wdcm2icg"))))
    (list "node_modules/chalk"
          (origin
            (method url-fetch)
            (uri "https://registry.npmjs.org/chalk/-/chalk-5.6.2.tgz")
            (file-name "chalk-5.6.2.tgz")
            (sha256
             (base32 "1zagawvlzqw1xwp9hzs0bh1dh9w297aj53qcnsfkpal3lhapg5cl"))))
    (list "node_modules/cross-spawn"
          (origin
            (method url-fetch)
            (uri "https://registry.npmjs.org/cross-spawn/-/cross-spawn-7.0.6.tgz")
            (file-name "cross-spawn-7.0.6.tgz")
            (sha256
             (base32 "1siqxlydjwpihy7klgd15cah56vsmxrdm3q90gndyfj1vh63530q"))))
    (list "node_modules/data-uri-to-buffer"
          (origin
            (method url-fetch)
            (uri "https://registry.npmjs.org/data-uri-to-buffer/-/data-uri-to-buffer-4.0.1.tgz")
            (file-name "data-uri-to-buffer-4.0.1.tgz")
            (sha256
             (base32 "18a22rwk14m78xxhh8kkqkhp9651ghpy3xrgavxjj2sxfwdjnx55"))))
    (list "node_modules/debug"
          (origin
            (method url-fetch)
            (uri "https://registry.npmjs.org/debug/-/debug-4.4.3.tgz")
            (file-name "debug-4.4.3.tgz")
            (sha256
             (base32 "19z48fpic8jbb2833gh3bviylzp9512i2dsqhxd91s3fjjfarhc9"))))
    (list "node_modules/diff"
          (origin
            (method url-fetch)
            (uri "https://registry.npmjs.org/diff/-/diff-8.0.4.tgz")
            (file-name "diff-8.0.4.tgz")
            (sha256
             (base32 "1mlkjmimccf2yw8wrbqgpn0940m5p9g9y8966d9wyhw2smx34lgg"))))
    (list "node_modules/ecdsa-sig-formatter"
          (origin
            (method url-fetch)
            (uri "https://registry.npmjs.org/ecdsa-sig-formatter/-/ecdsa-sig-formatter-1.0.11.tgz")
            (file-name "ecdsa-sig-formatter-1.0.11.tgz")
            (sha256
             (base32 "1zj8r1gp6vg3as5d0qs2qsycn0qwwkjaaj5n7cn7f514zx6vjz28"))))
    (list "node_modules/extend"
          (origin
            (method url-fetch)
            (uri "https://registry.npmjs.org/extend/-/extend-3.0.2.tgz")
            (file-name "extend-3.0.2.tgz")
            (sha256
             (base32 "1ckjrzapv4awrafybcvq3n5rcqm6ljswfdx97wibl355zaqd148x"))))
    (list "node_modules/fast-xml-builder"
          (origin
            (method url-fetch)
            (uri "https://registry.npmjs.org/fast-xml-builder/-/fast-xml-builder-1.2.0.tgz")
            (file-name "fast-xml-builder-1.2.0.tgz")
            (sha256
             (base32 "11zliaf1pf2ngssk4zk0p5nx71453jcq6j31sk9v42mqf6k4wd5r"))))
    (list "node_modules/fast-xml-parser"
          (origin
            (method url-fetch)
            (uri "https://registry.npmjs.org/fast-xml-parser/-/fast-xml-parser-5.7.3.tgz")
            (file-name "fast-xml-parser-5.7.3.tgz")
            (sha256
             (base32 "1d34x6rlfra3m91c6h7ln0m7ddijdz5wcwcnca377h8glszpzg8c"))))
    (list "node_modules/fetch-blob"
          (origin
            (method url-fetch)
            (uri "https://registry.npmjs.org/fetch-blob/-/fetch-blob-3.2.0.tgz")
            (file-name "fetch-blob-3.2.0.tgz")
            (sha256
             (base32 "0lhcwk678vgadhilyfjmx5im77y55c52i37080icwzwplic0vgsa"))))
    (list "node_modules/formdata-polyfill"
          (origin
            (method url-fetch)
            (uri "https://registry.npmjs.org/formdata-polyfill/-/formdata-polyfill-4.0.10.tgz")
            (file-name "formdata-polyfill-4.0.10.tgz")
            (sha256
             (base32 "1sc7hip8lwxbz2jg2k0snyqqwb4s8087kdj11zyz0cza710kpxqz"))))
    (list "node_modules/gaxios"
          (origin
            (method url-fetch)
            (uri "https://registry.npmjs.org/gaxios/-/gaxios-7.1.4.tgz")
            (file-name "gaxios-7.1.4.tgz")
            (sha256
             (base32 "1ckyy5x8c0kkq2smsmw6sqh91as7bskf2amhmj3vg30hclzva7r3"))))
    (list "node_modules/gcp-metadata"
          (origin
            (method url-fetch)
            (uri "https://registry.npmjs.org/gcp-metadata/-/gcp-metadata-8.1.2.tgz")
            (file-name "gcp-metadata-8.1.2.tgz")
            (sha256
             (base32 "156v633mndhk6r6c7102idkkdian7irr3lpca90hfp3md34g5hzr"))))
    (list "node_modules/get-east-asian-width"
          (origin
            (method url-fetch)
            (uri "https://registry.npmjs.org/get-east-asian-width/-/get-east-asian-width-1.6.0.tgz")
            (file-name "get-east-asian-width-1.6.0.tgz")
            (sha256
             (base32 "1mz6xqcd840s6aj191nw2f23lzg99fv2bfmlx1xg4kjs5y7gala4"))))
    (list "node_modules/glob"
          (origin
            (method url-fetch)
            (uri "https://registry.npmjs.org/glob/-/glob-13.0.6.tgz")
            (file-name "glob-13.0.6.tgz")
            (sha256
             (base32 "0w49ggh984wkrj0myy3gbzh5hnmjljxisg9wydf91qn4m57ih3q2"))))
    (list "node_modules/google-auth-library"
          (origin
            (method url-fetch)
            (uri "https://registry.npmjs.org/google-auth-library/-/google-auth-library-10.6.2.tgz")
            (file-name "google-auth-library-10.6.2.tgz")
            (sha256
             (base32 "198vxvsblk58fqx68lgnd4lr9as5hzgbhn1p1apaa5z6vbijcykh"))))
    (list "node_modules/google-logging-utils"
          (origin
            (method url-fetch)
            (uri "https://registry.npmjs.org/google-logging-utils/-/google-logging-utils-1.1.3.tgz")
            (file-name "google-logging-utils-1.1.3.tgz")
            (sha256
             (base32 "1g8bjykjsax507xazrgsz23qspq2237c1hkgfaz98grk9q6ir4is"))))
    (list "node_modules/graceful-fs"
          (origin
            (method url-fetch)
            (uri "https://registry.npmjs.org/graceful-fs/-/graceful-fs-4.2.11.tgz")
            (file-name "graceful-fs-4.2.11.tgz")
            (sha256
             (base32 "1709vla02prpbf34xqsvkqngvsmp5ypnljvg1pcgxrk1l553fq9r"))))
    (list "node_modules/grok-mermaid"
          (origin
            (method url-fetch)
            (uri "https://registry.npmjs.org/grok-mermaid/-/grok-mermaid-0.2.2.tgz")
            (file-name "grok-mermaid-0.2.2.tgz")
            (sha256
             (base32 "0d19jjp06g4xcf8b24nhfnr25p18lxb9ksyaz2sg1r9vm4v85yb1"))))
    (list "node_modules/highlight.js"
          (origin
            (method url-fetch)
            (uri "https://registry.npmjs.org/highlight.js/-/highlight.js-10.7.3.tgz")
            (file-name "highlight.js-10.7.3.tgz")
            (sha256
             (base32 "07m9prr3bz7vygcl80kfbwg65pwvinlp6k9fvl7r2vqh3p1nha99"))))
    (list "node_modules/hosted-git-info"
          (origin
            (method url-fetch)
            (uri "https://registry.npmjs.org/hosted-git-info/-/hosted-git-info-9.0.3.tgz")
            (file-name "hosted-git-info-9.0.3.tgz")
            (sha256
             (base32 "0wxnrvdfn0sm0kfg3ama55xii7rsf3ak9jy2hb264qizb7x1rfmm"))))
    (list "node_modules/http-proxy-agent"
          (origin
            (method url-fetch)
            (uri "https://registry.npmjs.org/http-proxy-agent/-/http-proxy-agent-7.0.2.tgz")
            (file-name "http-proxy-agent-7.0.2.tgz")
            (sha256
             (base32 "00kgi96l0vs04g2vl2xw3g53saxb4n9za2x23pbaiyrbm7x76pvq"))))
    (list "node_modules/https-proxy-agent"
          (origin
            (method url-fetch)
            (uri "https://registry.npmjs.org/https-proxy-agent/-/https-proxy-agent-7.0.6.tgz")
            (file-name "https-proxy-agent-7.0.6.tgz")
            (sha256
             (base32 "1q603cjw6z348j2i7k7s5zb3kp91hi9lml298bv84214wpl8j3wn"))))
    (list "node_modules/ignore"
          (origin
            (method url-fetch)
            (uri "https://registry.npmjs.org/ignore/-/ignore-7.0.5.tgz")
            (file-name "ignore-7.0.5.tgz")
            (sha256
             (base32 "1062hjm3bgg9013nvl33mmz3cchvcjhndq6gj61sgzazvqwnqbg8"))))
    (list "node_modules/isexe"
          (origin
            (method url-fetch)
            (uri "https://registry.npmjs.org/isexe/-/isexe-2.0.0.tgz")
            (file-name "isexe-2.0.0.tgz")
            (sha256
             (base32 "0nc3rcqjgyb9yyqajwlzzhfcqmsb682z7zinnx9qrql8w1rfiks7"))))
    (list "node_modules/jiti"
          (origin
            (method url-fetch)
            (uri "https://registry.npmjs.org/jiti/-/jiti-2.7.0.tgz")
            (file-name "jiti-2.7.0.tgz")
            (sha256
             (base32 "1ji8rzdyqd7w8r1hk4j4q9phba9dzgv0v86n8b6fgh29zdjx7l4d"))))
    (list "node_modules/json-bigint"
          (origin
            (method url-fetch)
            (uri "https://registry.npmjs.org/json-bigint/-/json-bigint-1.0.0.tgz")
            (file-name "json-bigint-1.0.0.tgz")
            (sha256
             (base32 "1dh3z67vh5084b07y8sklacnidzrddkqjjbc3kz6rcygaclm0ksc"))))
    (list "node_modules/json-schema-to-ts"
          (origin
            (method url-fetch)
            (uri "https://registry.npmjs.org/json-schema-to-ts/-/json-schema-to-ts-3.1.1.tgz")
            (file-name "json-schema-to-ts-3.1.1.tgz")
            (sha256
             (base32 "0r639hff6d5z17lzkzqb0c8p1blpl97ssi7nx59qgjis8m74xwzn"))))
    (list "node_modules/jwa"
          (origin
            (method url-fetch)
            (uri "https://registry.npmjs.org/jwa/-/jwa-2.0.1.tgz")
            (file-name "jwa-2.0.1.tgz")
            (sha256
             (base32 "079lm1m5malvssgz4lxiqvp300gpq6wpmygknvqx5jdxzgwhrg68"))))
    (list "node_modules/jws"
          (origin
            (method url-fetch)
            (uri "https://registry.npmjs.org/jws/-/jws-4.0.1.tgz")
            (file-name "jws-4.0.1.tgz")
            (sha256
             (base32 "04ifx47v412kfslgqgl7shj9im3wivl3f2p3r0311kpq4yq5yfpd"))))
    (list "node_modules/long"
          (origin
            (method url-fetch)
            (uri "https://registry.npmjs.org/long/-/long-5.3.2.tgz")
            (file-name "long-5.3.2.tgz")
            (sha256
             (base32 "09kbcinla92p75h69i90v5n730wxfaxl34z5r597vpvkcx33w0v8"))))
    (list "node_modules/lru-cache"
          (origin
            (method url-fetch)
            (uri "https://registry.npmjs.org/lru-cache/-/lru-cache-11.4.0.tgz")
            (file-name "lru-cache-11.4.0.tgz")
            (sha256
             (base32 "0g8p31ysmy1ip2r43mkibahyin9g249ni3gssyaakm0zvdm371j1"))))
    (list "node_modules/marked"
          (origin
            (method url-fetch)
            (uri "https://registry.npmjs.org/marked/-/marked-18.0.5.tgz")
            (file-name "marked-18.0.5.tgz")
            (sha256
             (base32 "1hnsg6i2n71ha8p62a3hr8cnh4w9h2nn4pk6qpgfdh19iipsa3kx"))))
    (list "node_modules/minimatch"
          (origin
            (method url-fetch)
            (uri "https://registry.npmjs.org/minimatch/-/minimatch-10.2.5.tgz")
            (file-name "minimatch-10.2.5.tgz")
            (sha256
             (base32 "1rd99j1d6x4lfb5ajnda6d16m7agx81x16qgwvxc7imz2mls9km6"))))
    (list "node_modules/minipass"
          (origin
            (method url-fetch)
            (uri "https://registry.npmjs.org/minipass/-/minipass-7.1.3.tgz")
            (file-name "minipass-7.1.3.tgz")
            (sha256
             (base32 "04kxs8if6f6vj9vkhhrnzp3y58fls2300mlfr7yy6m9pfjz63b2j"))))
    (list "node_modules/ms"
          (origin
            (method url-fetch)
            (uri "https://registry.npmjs.org/ms/-/ms-2.1.3.tgz")
            (file-name "ms-2.1.3.tgz")
            (sha256
             (base32 "1ii24v83yrryzmj9p369qxmpr53337kkqbdaklpmbv9hwlanwqgn"))))
    (list "node_modules/node-domexception"
          (origin
            (method url-fetch)
            (uri "https://registry.npmjs.org/node-domexception/-/node-domexception-1.0.0.tgz")
            (file-name "node-domexception-1.0.0.tgz")
            (sha256
             (base32 "0wf9c2mxlzvr2cjwdlg1kgml40idsdyccaswp03pi2ch909k98pb"))))
    (list "node_modules/node-fetch"
          (origin
            (method url-fetch)
            (uri "https://registry.npmjs.org/node-fetch/-/node-fetch-3.3.2.tgz")
            (file-name "node-fetch-3.3.2.tgz")
            (sha256
             (base32 "1ardip9x9gicwpbpv1nqw7f8cdngcg0ydy2l9dmjg3rz6q7gjnk1"))))
    (list "node_modules/openai"
          (origin
            (method url-fetch)
            (uri "https://registry.npmjs.org/openai/-/openai-6.40.0.tgz")
            (file-name "openai-6.40.0.tgz")
            (sha256
             (base32 "16q54kyb1nbylq7vgl1bns9bq7j3xi9i40l2gbkih9qa0ryyjpn2"))))
    (list "node_modules/p-retry"
          (origin
            (method url-fetch)
            (uri "https://registry.npmjs.org/p-retry/-/p-retry-4.6.2.tgz")
            (file-name "p-retry-4.6.2.tgz")
            (sha256
             (base32 "0n5mgwrr69i01n5y8ah793dcyphjcrmbw7jzx3lj0cfyhjs2n491"))))
    (list "node_modules/p-retry/node_modules/@types/retry"
          (origin
            (method url-fetch)
            (uri "https://registry.npmjs.org/@types/retry/-/retry-0.12.0.tgz")
            (file-name "retry-0.12.0.tgz")
            (sha256
             (base32 "1j7qm574gpf1favz78qzn79ky5g6xbflkwwz3f8wps51mdsxp5vw"))))
    (list "node_modules/partial-json"
          (origin
            (method url-fetch)
            (uri "https://registry.npmjs.org/partial-json/-/partial-json-0.1.7.tgz")
            (file-name "partial-json-0.1.7.tgz")
            (sha256
             (base32 "08k35xv5dhx2k0mlamp1yl5qzyfrjrvw6d2gl8ngn9fwdznzxsih"))))
    (list "node_modules/path-expression-matcher"
          (origin
            (method url-fetch)
            (uri "https://registry.npmjs.org/path-expression-matcher/-/path-expression-matcher-1.5.0.tgz")
            (file-name "path-expression-matcher-1.5.0.tgz")
            (sha256
             (base32 "0wxix71mpn0wk4nam7wqxbd4024z216bfvyg4w46dr6s6dzzyl8k"))))
    (list "node_modules/path-key"
          (origin
            (method url-fetch)
            (uri "https://registry.npmjs.org/path-key/-/path-key-3.1.1.tgz")
            (file-name "path-key-3.1.1.tgz")
            (sha256
             (base32 "14kvp849wnkg6f3dqgmcb73nnb5k6b3gxf65sgf0x0qlp6n9k2ab"))))
    (list "node_modules/path-scurry"
          (origin
            (method url-fetch)
            (uri "https://registry.npmjs.org/path-scurry/-/path-scurry-2.0.2.tgz")
            (file-name "path-scurry-2.0.2.tgz")
            (sha256
             (base32 "1h9yq8i7j1hl3vixpqnx23hwfl10n0ri26w7npy2h360n7df78yy"))))
    (list "node_modules/proper-lockfile"
          (origin
            (method url-fetch)
            (uri "https://registry.npmjs.org/proper-lockfile/-/proper-lockfile-4.1.2.tgz")
            (file-name "proper-lockfile-4.1.2.tgz")
            (sha256
             (base32 "0s49g8x645nacdxwmyy0w4rgl08ba5lv73wjpgnwpbkwlm5r2y7x"))))
    (list "node_modules/proper-lockfile/node_modules/retry"
          (origin
            (method url-fetch)
            (uri "https://registry.npmjs.org/retry/-/retry-0.12.0.tgz")
            (file-name "retry-0.12.0.tgz")
            (sha256
             (base32 "0a5l61f1aqn124j25m2q6m0j60mv7d9h74a8gfqnmp5ajz8wcqfz"))))
    (list "node_modules/protobufjs"
          (origin
            (method url-fetch)
            (uri "https://registry.npmjs.org/protobufjs/-/protobufjs-7.6.5.tgz")
            (file-name "protobufjs-7.6.5.tgz")
            (sha256
             (base32 "0vzqgzx4m74ghgc6zsdra7jr07g3xnfp62hqjhkfa1xb6v8hhsyn"))))
    (list "node_modules/retry"
          (origin
            (method url-fetch)
            (uri "https://registry.npmjs.org/retry/-/retry-0.13.1.tgz")
            (file-name "retry-0.13.1.tgz")
            (sha256
             (base32 "1140kg3sia3i6fi3bzpypam1gysa7i3szdyci3l7am44br2dh8bm"))))
    (list "node_modules/safe-buffer"
          (origin
            (method url-fetch)
            (uri "https://registry.npmjs.org/safe-buffer/-/safe-buffer-5.2.1.tgz")
            (file-name "safe-buffer-5.2.1.tgz")
            (sha256
             (base32 "1s5kvjpwqsc682zcy71h9c6pxla21sysfwj270x6jjkca421h62x"))))
    (list "node_modules/semver"
          (origin
            (method url-fetch)
            (uri "https://registry.npmjs.org/semver/-/semver-7.8.0.tgz")
            (file-name "semver-7.8.0.tgz")
            (sha256
             (base32 "017wsvynr31d9zgw0p0jnng5kvf25465jnap9r136g4cm0r0rw7l"))))
    (list "node_modules/shebang-command"
          (origin
            (method url-fetch)
            (uri "https://registry.npmjs.org/shebang-command/-/shebang-command-2.0.0.tgz")
            (file-name "shebang-command-2.0.0.tgz")
            (sha256
             (base32 "0vjmdpwcz23glkhlmxny8hc3x01zyr6hwf4qb3grq7m532ysbjws"))))
    (list "node_modules/shebang-regex"
          (origin
            (method url-fetch)
            (uri "https://registry.npmjs.org/shebang-regex/-/shebang-regex-3.0.0.tgz")
            (file-name "shebang-regex-3.0.0.tgz")
            (sha256
             (base32 "13wmb23w5srjpn9xx1c85yk5jbc5z9ypg0iz33h6nv5jdnmapnzy"))))
    (list "node_modules/signal-exit"
          (origin
            (method url-fetch)
            (uri "https://registry.npmjs.org/signal-exit/-/signal-exit-3.0.7.tgz")
            (file-name "signal-exit-3.0.7.tgz")
            (sha256
             (base32 "1a10ixkiak24yy6s7p9m7c6v9jkz2fm7wxgc2l3614dbdbx275j3"))))
    (list "node_modules/strnum"
          (origin
            (method url-fetch)
            (uri "https://registry.npmjs.org/strnum/-/strnum-2.3.0.tgz")
            (file-name "strnum-2.3.0.tgz")
            (sha256
             (base32 "0lvsrf8p7dnkmg2g5p2nky8x66rfim1kk5bddi15smmxbkgzcb4y"))))
    (list "node_modules/ts-algebra"
          (origin
            (method url-fetch)
            (uri "https://registry.npmjs.org/ts-algebra/-/ts-algebra-2.0.0.tgz")
            (file-name "ts-algebra-2.0.0.tgz")
            (sha256
             (base32 "0p669fivm6k85ip9n54rv6bh70lcalrv43l6jhp9bdqyv27rdhzl"))))
    (list "node_modules/tslib"
          (origin
            (method url-fetch)
            (uri "https://registry.npmjs.org/tslib/-/tslib-2.8.1.tgz")
            (file-name "tslib-2.8.1.tgz")
            (sha256
             (base32 "17hiw9pawyczkhsnhlq4k9dn3kq2l49nk5rlfn049bmbxvakbxk6"))))
    (list "node_modules/typebox"
          (origin
            (method url-fetch)
            (uri "https://registry.npmjs.org/typebox/-/typebox-1.3.7.tgz")
            (file-name "typebox-1.3.7.tgz")
            (sha256
             (base32 "0fl6l3ylrdgbgvdss4c5s3l5i0kcbadr8a73kk53cjg6c0jr9l5i"))))
    (list "node_modules/undici"
          (origin
            (method url-fetch)
            (uri "https://registry.npmjs.org/undici/-/undici-8.9.0.tgz")
            (file-name "undici-8.9.0.tgz")
            (sha256
             (base32 "176n8ls7jgfvc58ivfq8hhyicaf24mm0c22j6ay08bimx6rsnm7m"))))
    (list "node_modules/undici-types"
          (origin
            (method url-fetch)
            (uri "https://registry.npmjs.org/undici-types/-/undici-types-6.21.0.tgz")
            (file-name "undici-types-6.21.0.tgz")
            (sha256
             (base32 "0vfidx8iwc7ab1p13fxy6bf35njqkii6nkwgah78b249w6jsk8fg"))))
    (list "node_modules/web-streams-polyfill"
          (origin
            (method url-fetch)
            (uri "https://registry.npmjs.org/web-streams-polyfill/-/web-streams-polyfill-3.3.3.tgz")
            (file-name "web-streams-polyfill-3.3.3.tgz")
            (sha256
             (base32 "0m5v1r411b7vlziw4bgk1vxc8mkxbnklsq20bk9ylqq2vk9kiq8y"))))
    (list "node_modules/which"
          (origin
            (method url-fetch)
            (uri "https://registry.npmjs.org/which/-/which-2.0.2.tgz")
            (file-name "which-2.0.2.tgz")
            (sha256
             (base32 "1p2fkm4lr36s85gdjxmyr6wh86dizf0iwmffxmarcxpbvmgxyfm1"))))
    (list "node_modules/ws"
          (origin
            (method url-fetch)
            (uri "https://registry.npmjs.org/ws/-/ws-8.21.0.tgz")
            (file-name "ws-8.21.0.tgz")
            (sha256
             (base32 "1kxl9vlkizjmvdqr4fj5mpa7b3dcnajdk80qabnhyfmf79mp52yh"))))
    (list "node_modules/xml-naming"
          (origin
            (method url-fetch)
            (uri "https://registry.npmjs.org/xml-naming/-/xml-naming-0.1.0.tgz")
            (file-name "xml-naming-0.1.0.tgz")
            (sha256
             (base32 "0msggwgl9w627xkvaccird3hmqzgk1clxki70hj9z7j2pay7qd0r"))))
    (list "node_modules/yaml"
          (origin
            (method url-fetch)
            (uri "https://registry.npmjs.org/yaml/-/yaml-2.9.0.tgz")
            (file-name "yaml-2.9.0.tgz")
            (sha256
             (base32 "14ggs4m6rb3wm5mi9s2n6kkgz9h9pymlb81b4zh019qvrc2a53q0"))))
))
