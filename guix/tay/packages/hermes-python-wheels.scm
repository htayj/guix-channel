;;; Pinned Python 3.11 / x86_64-linux runtime artifacts for Hermes f97608.
;;; Every artifact was fetched and SHA256-verified against uv.lock, except
;;; sherpa-onnx-core: the published sherpa-onnx wheel requires it but uv.lock
;;; omits it; its version and SHA256 come from the official PyPI release JSON.
;;; These origins are an artifact inventory, not a blanket license grant.
;;; Preserve wheel data, dist-info, LICENSE and third-party notices on install.
;;; In particular, pvporcupine bundles proprietary engine/models: its Apache
;;; wrapper metadata does not authorize redistribution of those components.

(define-module (tay packages hermes-python-wheels)
  #:use-module (guix download)
  #:use-module (guix packages)
  #:export (%hermes-python-wheels %hermes-python-sources
            %hermes-python-notices))

(define %hermes-python-wheels
  (list
   (cons "agent-client-protocol"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/8f/ed/c284543c08aa443a4ef2c8bd120be51da8433dd174c01749b5d87c333f22/agent_client_protocol-0.9.0-py3-none-any.whl")
           (file-name "agent_client_protocol-0.9.0-py3-none-any.whl")
           (sha256
            (base32 "1vlq8wcnyp4chk1wpzl8xwwxpry53zh2nkjl2a8vd30xnl01b486"))))
   (cons "aiofiles"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/a5/45/30bb92d442636f570cb5651bc661f52b610e2eec3f891a5dc3a4c3667db0/aiofiles-24.1.0-py3-none-any.whl")
           (file-name "aiofiles-24.1.0-py3-none-any.whl")
           (sha256
            (base32 "1rb0haxzh3lsafw1y8sl97fn9s332w37xgyimgbvagjy37s5bv5l"))))
   (cons "aiohappyeyeballs"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/0f/15/5bf3b99495fb160b63f95972b81750f18f7f4e02ad051373b669d17d44f2/aiohappyeyeballs-2.6.1-py3-none-any.whl")
           (file-name "aiohappyeyeballs-2.6.1-py3-none-any.whl")
           (sha256
            (base32 "1f0z6c4iydxh09w5ka82556j11g4jzlq8bawkk4jbjvm9f7vljgk"))))
   (cons "aiohttp"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/a5/b9/2b8f0c0ce09c87a1daf80fd483431b56b1435d3f62789bc86f572e1245de/aiohttp-3.14.3-cp311-cp311-manylinux2014_x86_64.manylinux_2_17_x86_64.manylinux_2_28_x86_64.whl")
           (file-name "aiohttp-3.14.3-cp311-cp311-manylinux2014_x86_64.manylinux_2_17_x86_64.manylinux_2_28_x86_64.whl")
           (sha256
            (base32 "1nw26kvljwwbscnckjwjypbs2z0ppmf7mdmkf768njmmhb7b9rsk"))))
   (cons "aiohttp-retry"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/1a/99/84ba7273339d0f3dfa57901b846489d2e5c2cd731470167757f1935fffbd/aiohttp_retry-2.9.1-py3-none-any.whl")
           (file-name "aiohttp_retry-2.9.1-py3-none-any.whl")
           (sha256
            (base32 "0m6wwrmysvp1nnmyanz3hgq3cjbjgsnq0gssl1b850r136fpblk6"))))
   (cons "aiohttp-socks"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/bf/7d/4b633d709b8901d59444d2e512b93e72fe62d2b492a040097c3f7ba017bb/aiohttp_socks-0.11.0-py3-none-any.whl")
           (file-name "aiohttp_socks-0.11.0-py3-none-any.whl")
           (sha256
            (base32 "1hcymf55m8v7w44h6hrm3fbmphz4mwycycykyvwgpf1ir5bwxb4s"))))
   (cons "aiosignal"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/fb/76/641ae371508676492379f16e2fa48f4e2c11741bd63c48be4b12a6b09cba/aiosignal-1.4.0-py3-none-any.whl")
           (file-name "aiosignal-1.4.0-py3-none-any.whl")
           (sha256
            (base32 "0bp81wd9xc9z1xxmkq5v1q5wzw4zhc596qwyji8hb69bp7w46ch5"))))
   (cons "aiosqlite"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/00/b7/e3bf5133d697a08128598c8d0abc5e16377b51465a33756de24fa7dee953/aiosqlite-0.22.1-py3-none-any.whl")
           (file-name "aiosqlite-0.22.1-py3-none-any.whl")
           (sha256
            (base32 "1szwnkn48ppvhwgllzlypm1n4bz6v3ls5icn05sasgw22gmh5h11"))))
   (cons "alibabacloud-credentials"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/a9/24/7c47501b24897a1379cd57cc8b8de376161f2487548fc8233b2b74ab25c7/alibabacloud_credentials-1.0.8-py3-none-any.whl")
           (file-name "alibabacloud_credentials-1.0.8-py3-none-any.whl")
           (sha256
            (base32 "0a3ymzhmz0bcpjhbz6yh0j5g6d3mg15dm5ycp77ndssallzpqrv6"))))
   (cons "alibabacloud-dingtalk"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/9d/80/7d1c1438e17c1fc90d037f1b73debe3fc2dfa348eb91e12818c2584d1865/alibabacloud_dingtalk-2.2.42-py3-none-any.whl")
           (file-name "alibabacloud_dingtalk-2.2.42-py3-none-any.whl")
           (sha256
            (base32 "1r6k0dzscydd40lzgmaim962x02gw64i1w8ahzmjcy8v6prjwp2z"))))
   (cons "alibabacloud-openapi-util"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/08/46/9b217343648b366eb93447f5d93116e09a61956005794aed5ef95a2e9e2e/alibabacloud_openapi_util-0.2.4-py3-none-any.whl")
           (file-name "alibabacloud_openapi_util-0.2.4-py3-none-any.whl")
           (sha256
            (base32 "1gf5nsqzcv35ha0hplh2in98ga1jc740svi8ijdawrar1cilyix2"))))
   (cons "alibabacloud-tea-openapi"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/8d/ec/6b368a10e9c2e8b1b394c69b96ac213ae66e8c4895e0baa1ffaf7178fd32/alibabacloud_tea_openapi-0.4.5-py3-none-any.whl")
           (file-name "alibabacloud_tea_openapi-0.4.5-py3-none-any.whl")
           (sha256
            (base32 "02f61z7ggr629z7f9pb9430zvjlj50k32g21bc5aivbvbh4pk29k"))))
   (cons "alibabacloud-tea-util"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/72/9e/c394b4e2104766fb28a1e44e3ed36e4c7773b4d05c868e482be99d5635c9/alibabacloud_tea_util-0.3.14-py3-none-any.whl")
           (file-name "alibabacloud_tea_util-0.3.14-py3-none-any.whl")
           (sha256
            (base32 "1zivp5nyifq7vxg54hjphw3sn7aszjr5wd17vmlyrxyq831yblqh"))))
   (cons "annotated-doc"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/1e/d3/26bf1008eb3d2daa8ef4cacc7f3bfdc11818d111f7e2d0201bc6e3b49d45/annotated_doc-0.0.4-py3-none-any.whl")
           (file-name "annotated_doc-0.0.4-py3-none-any.whl")
           (sha256
            (base32 "086kpsmvma2gq88x3db76jjyfajyf2iq8bcwbar51i4id7fc26jp"))))
   (cons "annotated-types"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/78/b6/6307fbef88d9b5ee7421e68d78a9f162e0da4900bc5f5793f6d3d0e34fb8/annotated_types-0.7.0-py3-none-any.whl")
           (file-name "annotated_types-0.7.0-py3-none-any.whl")
           (sha256
            (base32 "0lrab0f3lgvpbj79p178xd7cn6qkr2zz9w6lw3rw7fwg7asfh0hz"))))
   (cons "anthropic"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/0d/02/99bf351933bdea0545a2b6e2d812ed878899e9a95f618351dfa3d0de0e69/anthropic-0.87.0-py3-none-any.whl")
           (file-name "anthropic-0.87.0-py3-none-any.whl")
           (sha256
            (base32 "0dm203xb83qqjy91g19x78k2wm8r2z2p7y33y4yrswrcsj39nrp2"))))
   (cons "anyio"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/38/0e/27be9fdef66e72d64c0cdc3cc2823101b80585f8119b5c112c2e8f5f7dab/anyio-4.12.1-py3-none-any.whl")
           (file-name "anyio-4.12.1-py3-none-any.whl")
           (sha256
            (base32 "0v5b0sv3vb6n3c1vlhpcxpgz2xyjxs5pnriw1al0l57whj4841fl"))))
   (cons "apscheduler"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/9f/64/2e54428beba8d9992aa478bb8f6de9e4ecaa5f8f513bcfd567ed7fb0262d/apscheduler-3.11.2-py3-none-any.whl")
           (file-name "apscheduler-3.11.2-py3-none-any.whl")
           (sha256
            (base32 "0vfjpwang7d41mzdasfxp5bbizkn3d1sfh6xwjs9sh21yxvm206f"))))
   (cons "asyncpg"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/e6/35/c27719ae0536c5b6e61e4701391ffe435ef59539e9360959240d6e47c8c8/asyncpg-0.31.0-cp311-cp311-manylinux2014_x86_64.manylinux_2_17_x86_64.manylinux_2_28_x86_64.whl")
           (file-name "asyncpg-0.31.0-cp311-cp311-manylinux2014_x86_64.manylinux_2_17_x86_64.manylinux_2_28_x86_64.whl")
           (sha256
            (base32 "02gi0c1v7wa9z83nr5sccxzl2vimhskb6afk82p67j9jdkj7p060"))))
   (cons "attrs"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/3a/2a/7cc015f5b9f5db42b7d48157e23356022889fc354a2813c15934b7cb5c0e/attrs-25.4.0-py3-none-any.whl")
           (file-name "attrs-25.4.0-py3-none-any.whl")
           (sha256
            (base32 "0wrkgaslfj6iy65vlsp2rj6mpqddv2v5p0wpip26mcxk3wm7xkxd"))))
   (cons "av"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/d2/59/d19bc3257dd985d55337d7f0414c019414b97e16cd3690ebf9941a847543/av-17.0.0-cp311-abi3-manylinux_2_28_x86_64.whl")
           (file-name "av-17.0.0-cp311-abi3-manylinux_2_28_x86_64.whl")
           (sha256
            (base32 "0bjrx1apk7a9z9jhxjm5rx93852y1cndjs8i64vs7x4pbylcnq0h"))))
   (cons "azure-core"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/5b/db/325c6d7312d2200251c52323878281045aaffcb5586612296484e4280eaa/azure_core-1.41.0-py3-none-any.whl")
           (file-name "azure_core-1.41.0-py3-none-any.whl")
           (sha256
            (base32 "0bc9zrg0n8rx2r3xp5w5zcvsrsbz9rm3j910rlyil2qqx08l0asj"))))
   (cons "azure-identity"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/49/9a/417b3a533e01953a7c618884df2cb05a71e7b68bdbce4fbdb62349d2a2e8/azure_identity-1.25.3-py3-none-any.whl")
           (file-name "azure_identity-1.25.3-py3-none-any.whl")
           (sha256
            (base32 "0z24lxx5crabh71vibbkh3dppyiw3wbp84q77qrk0vqlm1bbkl7l"))))
   (cons "backoff"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/df/73/b6e24bd22e6720ca8ee9a85a0c4a2971af8497d8f3193fa05390cbd46e09/backoff-2.2.1-py3-none-any.whl")
           (file-name "backoff-2.2.1-py3-none-any.whl")
           (sha256
            (base32 "1s4n0g5av9lrrbrsd5jybk30vqkcbdypsyz4yxw65q180sd9ymv3"))))
   (cons "base58"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/4a/45/ec96b29162a402fc4c1c5512d114d7b3787b9d1c2ec241d9568b4816ee23/base58-2.1.1-py3-none-any.whl")
           (file-name "base58-2.1.1-py3-none-any.whl")
           (sha256
            (base32 "1hj5sb4br9ajbghfp74ifaqwxcafmj8qa8gk8c8gq7g57i6nz8qi"))))
   (cons "boto3"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/b9/33/55103ba5ef9975ea54b8d39e69b76eb6e9fded3beae5f01065e26951a3a1/boto3-1.42.89-py3-none-any.whl")
           (file-name "boto3-1.42.89-py3-none-any.whl")
           (sha256
            (base32 "0ci92q8i4aajb7j9fg26p1jxks7lgyjymms3bx9mbinhyj4v2132"))))
   (cons "botocore"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/91/f1/90a7b8eda38b7c3a65ca7ee0075bdf310b6b471cb1b95fab6e8994323a50/botocore-1.42.89-py3-none-any.whl")
           (file-name "botocore-1.42.89-py3-none-any.whl")
           (sha256
            (base32 "0dazm6gny8fld7xnmg874c4838z6lw5vxiac7c376r6vv748ddyr"))))
   (cons "brotlicffi"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/06/78/076419ed6c2c6aa3eaac6fd6b076502b4be89d50625fcdc513cd4aeca718/brotlicffi-1.2.0.2-cp39-abi3-manylinux2014_x86_64.manylinux_2_17_x86_64.manylinux_2_28_x86_64.whl")
           (file-name "brotlicffi-1.2.0.2-cp39-abi3-manylinux2014_x86_64.manylinux_2_17_x86_64.manylinux_2_28_x86_64.whl")
           (sha256
            (base32 "0fis0qydvvrxchvqgag9i8xqb4amm194pxgdy8szazqfvq0n3492"))))
   (cons "cbor2"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/3d/c5/4dad6125eea17b35ca5580a4f7308226c8a4511dfb91b94c329b167b6218/cbor2-6.1.3-cp311-cp311-manylinux_2_28_x86_64.whl")
           (file-name "cbor2-6.1.3-cp311-cp311-manylinux_2_28_x86_64.whl")
           (sha256
            (base32 "1gwi6qbp6pcjppl26g3knr8j4n6n2drzc099k23w71594fa1a52z"))))
   (cons "certifi"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/59/8c/57e832b7af6d7c5abe66eb3fbe3a3a32f4d11ea23a1aa7131371035be991/certifi-2026.5.20-py3-none-any.whl")
           (file-name "certifi-2026.5.20-py3-none-any.whl")
           (sha256
            (base32 "15sqs8m90ip54511731fc0g9xhs9nd56lhv0pspdfjhap84y4liw"))))
   (cons "cffi"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/d7/91/500d892b2bf36529a75b77958edfcd5ad8e2ce4064ce2ecfeab2125d72d1/cffi-2.0.0-cp311-cp311-manylinux2014_x86_64.manylinux_2_17_x86_64.whl")
           (file-name "cffi-2.0.0-cp311-cp311-manylinux2014_x86_64.manylinux_2_17_x86_64.whl")
           (sha256
            (base32 "09mcg4gfyhlqkki4g6whknhk5lzffwvq1hz8rqj64937mynslhc9"))))
   (cons "charset-normalizer"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/6d/fc/de9cce525b2c5b94b47c70a4b4fb19f871b24995c728e957ee68ab1671ea/charset_normalizer-3.4.4-cp311-cp311-manylinux2014_x86_64.manylinux_2_17_x86_64.manylinux_2_28_x86_64.whl")
           (file-name "charset_normalizer-3.4.4-cp311-cp311-manylinux2014_x86_64.manylinux_2_17_x86_64.manylinux_2_28_x86_64.whl")
           (sha256
            (base32 "1093qwm24sydmsgmdwh1k4xvc0gik6kn81dbrd2ia8wac7xja344"))))
   (cons "click"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/fb/e2/79c688af8b210d232694e31e59da9f6ec747bae31c3f5946e4e9b98860d5/click-8.4.2-py3-none-any.whl")
           (file-name "click-8.4.2-py3-none-any.whl")
           (sha256
            (base32 "0xkv35d3qmaj0p6lsbp02vxmgnb13nlpv0b5kmdp85n86rhzdyg6"))))
   (cons "croniter"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/07/4b/290b4c3efd6417a8b0c284896de19b1d5855e6dbdb97d2a35e68fa42de85/croniter-6.0.0-py2.py3-none-any.whl")
           (file-name "croniter-6.0.0-py2.py3-none-any.whl")
           (sha256
            (base32 "0s5kx7pd4pawhg61bsii94vkxj093yx7jhrakfbrcy7iaqw8r1rg"))))
   (cons "cryptography"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/da/3a/f05e32c99d440c9bb891ea0e36c9091891e36be5a9a87ab2ee6ea20729f6/cryptography-50.0.0-cp311-abi3-manylinux_2_34_x86_64.whl")
           (file-name "cryptography-50.0.0-cp311-abi3-manylinux_2_34_x86_64.whl")
           (sha256
            (base32 "0prc56ayxxp90558wgxr5h1gm5pqfm899hdklm8hphyspp2qw542"))))
   (cons "ctranslate2"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/ed/4e/b48f79fd36e5d3c7e12db383aa49814c340921a618ef7364bd0ced670644/ctranslate2-4.7.1-cp311-cp311-manylinux_2_27_x86_64.manylinux_2_28_x86_64.whl")
           (file-name "ctranslate2-4.7.1-cp311-cp311-manylinux_2_27_x86_64.manylinux_2_28_x86_64.whl")
           (sha256
            (base32 "0is36zh4waaph7wigawp13dhmj0lhzb87gj2b40cfsxcn2d2vn8f"))))
   (cons "darabonba-core"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/6d/88/38800ca22f39a31fdb75c7b2867c61d3af5e2792cee0b72942a639c88a79/darabonba_core-1.0.8-py3-none-any.whl")
           (file-name "darabonba_core-1.0.8-py3-none-any.whl")
           (sha256
            (base32 "10wlnskdyknjk1y3jnzk66q3qnj98g0ppzdvzffjz3zq83fky2dc"))))
   (cons "davey"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/b3/7b/db98b09d160e3d2f750486fcf90ee8d244cf582ab10d88b2016a6972348c/davey-0.1.4-cp311-cp311-manylinux_2_17_x86_64.manylinux2014_x86_64.whl")
           (file-name "davey-0.1.4-cp311-cp311-manylinux_2_17_x86_64.manylinux2014_x86_64.whl")
           (sha256
            (base32 "0h6b7a0iys00zm3dw6zxv9cba1h8vxniyjws0bdb9xwxpprjy22n"))))
   (cons "daytona"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/10/6b/b9d28ca18588bd18c4fba97055c857a63d95555a3b590d370f5e156f3ea3/daytona-0.155.0-py3-none-any.whl")
           (file-name "daytona-0.155.0-py3-none-any.whl")
           (sha256
            (base32 "0cwpcwbf1nshjmhvdax2ax3v342dkacg5r7pfm4zhlcv62ardlg7"))))
   (cons "daytona-api-client"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/48/e6/f3ae6371bb70f4e5d11e4d7e7255df856975411d52b0da87f21c4482450b/daytona_api_client-0.155.0-py3-none-any.whl")
           (file-name "daytona_api_client-0.155.0-py3-none-any.whl")
           (sha256
            (base32 "0xdp7gvsslxb9n2d4n9mqqwxy8l38ks2rrijaclv2vklwjqqydmv"))))
   (cons "daytona-api-client-async"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/f8/26/63aa1e38b79092648f6df1dde76764061a126b8b18f74b51b7965cdbacf2/daytona_api_client_async-0.155.0-py3-none-any.whl")
           (file-name "daytona_api_client_async-0.155.0-py3-none-any.whl")
           (sha256
            (base32 "0w69g7mk4qh2r9hyqj7df5p51sg0lh670f10f2xpxsqw70inaffk"))))
   (cons "daytona-toolbox-api-client"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/33/f9/fcbfe2fbd342ccc38356f35a87cdd344d92ef57df97ca644253683e7c205/daytona_toolbox_api_client-0.155.0-py3-none-any.whl")
           (file-name "daytona_toolbox_api_client-0.155.0-py3-none-any.whl")
           (sha256
            (base32 "1i4hwgq8alp5f90niai0fyh80vi7blpg5d9z03c7dcyqr8i1fjv1"))))
   (cons "daytona-toolbox-api-client-async"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/c6/45/e6dd0c6c740c67c07474f2eb5175bb5656598488db444c4abd2a4e948393/daytona_toolbox_api_client_async-0.155.0-py3-none-any.whl")
           (file-name "daytona_toolbox_api_client_async-0.155.0-py3-none-any.whl")
           (sha256
            (base32 "0l998507jnp1rahwkdhq81bmpi3rw9lxnm7h7zixi1hnld8n7kvf"))))
   (cons "defusedxml"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/07/6c/aa3f2f849e01cb6a001cd8554a88d4c77c5c1a31c95bdf1cf9301e6d9ef4/defusedxml-0.7.1-py2.py3-none-any.whl")
           (file-name "defusedxml-0.7.1-py2.py3-none-any.whl")
           (sha256
            (base32 "0qca37v5iv0304hrl9pzad4jpnxfrnv449cyi768c0kp53jfflm3"))))
   (cons "dependency-injector"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/7f/97/b3b144c96e1f7fff0a7e2e83eb0767bd23b6bacffd0ac8cff397d350e94d/dependency_injector-4.49.0-cp310-abi3-manylinux1_x86_64.manylinux_2_28_x86_64.manylinux_2_5_x86_64.whl")
           (file-name "dependency_injector-4.49.0-cp310-abi3-manylinux1_x86_64.manylinux_2_28_x86_64.manylinux_2_5_x86_64.whl")
           (sha256
            (base32 "1fxa5b107cqpq5aaazi3qric32qj0igycbzkd0qbs5yv3ccjl7zr"))))
   (cons "deprecated"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/84/d0/205d54408c08b13550c733c4b85429e7ead111c7f0014309637425520a9a/deprecated-1.3.1-py2.py3-none-any.whl")
           (file-name "deprecated-1.3.1-py2.py3-none-any.whl")
           (sha256
            (base32 "0gszkmr84v48g6s9bwkra1x17kk593jgnaasaf0h3xmnhvqzwysr"))))
   (cons "dingtalk-stream"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/4c/44/102dede3f371277598df6aa9725b82e3add068c729333c7a5dbc12764579/dingtalk_stream-0.24.3-py3-none-any.whl")
           (file-name "dingtalk_stream-0.24.3-py3-none-any.whl")
           (sha256
            (base32 "1ba3b6zyxix70xpy0j3k0qhryqa1vxddy37nif3n4ncqaqv40q11"))))
   (cons "discord-py"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/f7/a7/17208c3b3f92319e7fad259f1c6d5a5baf8fd0654c54846ced329f83c3eb/discord_py-2.7.1-py3-none-any.whl")
           (file-name "discord_py-2.7.1-py3-none-any.whl")
           (sha256
            (base32 "0fbl9wl5yx7j7k714d10wvlri0140k68lgvz79pi8wdiccncm7c4"))))
   (cons "distro"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/12/b3/231ffd4ab1fc9d679809f356cebee130ac7daa00d6d6f3206dd4fd137e9e/distro-1.9.0-py3-none-any.whl")
           (file-name "distro-1.9.0-py3-none-any.whl")
           (sha256
            (base32 "1ch2xz4c16sq4fi701l4bc9midnsppv9mnnq4x8ghs2isqjxkzvv"))))
   (cons "docstring-parser"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/55/e2/2537ebcff11c1ee1ff17d8d0b6f4db75873e3b0fb32c2d4a2ee31ecb310a/docstring_parser-0.17.0-py3-none-any.whl")
           (file-name "docstring_parser-0.17.0-py3-none-any.whl")
           (sha256
            (base32 "0247cm8lak7mv8rxa7vkv8nmiscih7xb9y80nfcq1kixsamnj9fg"))))
   (cons "edge-tts"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/bf/89/92ac6b154ab87d236c15e5e0c73cb99be58efb1ea3eb9318c266bf9a36bf/edge_tts-7.2.7-py3-none-any.whl")
           (file-name "edge_tts-7.2.7-py3-none-any.whl")
           (sha256
            (base32 "1n8d93v2rdwkwnqi9glmwz2d6rgxdyjyhwmy5kk5wzil6kldj4dc"))))
   (cons "elevenlabs"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/b0/1f/eaf5dc72edad9124f16daf36b9226c57893e21280d25e94b6b5c7011c86b/elevenlabs-1.59.0-py3-none-any.whl")
           (file-name "elevenlabs-1.59.0-py3-none-any.whl")
           (sha256
            (base32 "1vbilwyl82wx6g0mwf8v93lq6mgpk6b63a5l11vqdg50h7dlb0a6"))))
   (cons "environs"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/97/a8/c070e1340636acb38d4e6a7e45c46d168a462b48b9b3257e14ca0e5af79b/environs-14.6.0-py3-none-any.whl")
           (file-name "environs-14.6.0-py3-none-any.whl")
           (sha256
            (base32 "04h8zifgkkj47mhjj863ny28jywcba7s4xxhdl62p1smd9n3vyzq"))))
   (cons "eval-type-backport"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/cf/22/fdc2e30d43ff853720042fa15baa3e6122722be1a7950a98233ebb55cd71/eval_type_backport-0.3.1-py3-none-any.whl")
           (file-name "eval_type_backport-0.3.1-py3-none-any.whl")
           (sha256
            (base32 "1a6z3w0prp86dw7qcas0hddm261m967sga2nkw9137syj10vd6i7"))))
   (cons "exa-py"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/e2/bc/7a34e904a415040ba626948d0b0a36a08cd073f12b13342578a68331be3c/exa_py-2.10.2-py3-none-any.whl")
           (file-name "exa_py-2.10.2-py3-none-any.whl")
           (sha256
            (base32 "0isaj36km499c2mb49j13pnr43y4pghwqjj3dgmqlyjb3xcagcpc"))))
   (cons "fal-client"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/6a/48/265c2935467ac1dbcb7c5b54cd8a2f579cbb263db6bfc0e0c8fe4bc79c02/fal_client-0.13.1-py3-none-any.whl")
           (file-name "fal_client-0.13.1-py3-none-any.whl")
           (sha256
            (base32 "0dy0kykk1z2w660d9idrks8mpzy6g3ka1wzq61d4hb8ilkrh2yln"))))
   (cons "fastapi"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/d2/c9/a175a7779f3599dfa4adfc97a6ce0e157237b3d7941538604aadaf97bfb6/fastapi-0.133.1-py3-none-any.whl")
           (file-name "fastapi-0.133.1-py3-none-any.whl")
           (sha256
            (base32 "1qn2gp7iwygzcc6hi8zkkbdip431ckmg5bb5g9hv21a66fx393v5"))))
   (cons "faster-whisper"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/05/99/49ee85903dee060d9f08297b4a342e5e0bcfca2f027a07b4ee0a38ab13f9/faster_whisper-1.2.1-py3-none-any.whl")
           (file-name "faster_whisper-1.2.1-py3-none-any.whl")
           (sha256
            (base32 "19r698ibaq5y25c5xygp89ijm69nlx0c67ahvnabgh480vanm9kr"))))
   (cons "filelock"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/9c/0f/5d0c71a1aefeb08efff26272149e07ab922b64f46c63363756224bd6872e/filelock-3.24.3-py3-none-any.whl")
           (file-name "filelock-3.24.3-py3-none-any.whl")
           (sha256
            (base32 "0b80krikfzclysqjld6cl6q0i46fbdav0w8dh657y7rrc139lvj2"))))
   (cons "fire"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/e5/4c/93d0f85318da65923e4b91c1c2ff03d8a458cbefebe3bc612a6693c7906d/fire-0.7.1-py3-none-any.whl")
           (file-name "fire-0.7.1-py3-none-any.whl")
           (sha256
            (base32 "10hqmfsp2fb8sjbcy3if5zqvk5060ybanfwpwbkh341s0fjxhgz4"))))
   (cons "firecrawl-anydoc"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/fc/16/feeca9705bfdb237f1cb69ede0b373b144c0d51df4297e595a74b815557e/firecrawl_anydoc-0.2.4-cp310-abi3-manylinux_2_17_x86_64.manylinux2014_x86_64.whl")
           (file-name "firecrawl_anydoc-0.2.4-cp310-abi3-manylinux_2_17_x86_64.manylinux2014_x86_64.whl")
           (sha256
            (base32 "1lqbrybkg6dsw0r9li00xfgypkpjjf18hqrkimc5qkkdpw0ysnhf"))))
   (cons "firecrawl-py"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/07/33/97a53f155c2dec843afb0925b77d715b328134b0fe2fef142c0ff810ff49/firecrawl_py-4.17.0-py3-none-any.whl")
           (file-name "firecrawl_py-4.17.0-py3-none-any.whl")
           (sha256
            (base32 "186cqbd21qph28llz8nla5braka04a7p66dz32k30xms3cp178q4"))))
   (cons "flatbuffers"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/e8/2d/d2a548598be01649e2d46231d151a6c56d10b964d94043a335ae56ea2d92/flatbuffers-25.12.19-py2.py3-none-any.whl")
           (file-name "flatbuffers-25.12.19-py2.py3-none-any.whl")
           (sha256
            (base32 "1d105va4cj7hk69k5rh70sdik7cf2v8s6rid3h1bnf3q886gad3n"))))
   (cons "frozenlist"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/11/b1/71a477adc7c36e5fb628245dfbdea2166feae310757dea848d02bd0689fd/frozenlist-1.8.0-cp311-cp311-manylinux1_x86_64.manylinux_2_28_x86_64.manylinux_2_5_x86_64.whl")
           (file-name "frozenlist-1.8.0-cp311-cp311-manylinux1_x86_64.manylinux_2_28_x86_64.manylinux_2_5_x86_64.whl")
           (sha256
            (base32 "07qxxc9idm9z21sl9qfz4jixcj4h3x6bwwz5cslgni5p0i1g8li5"))))
   (cons "fsspec"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/e6/ab/fb21f4c939bb440104cc2b396d3be1d9b7a9fd3c6c2a53d98c45b3d7c954/fsspec-2026.2.0-py3-none-any.whl")
           (file-name "fsspec-2026.2.0-py3-none-any.whl")
           (sha256
            (base32 "0dr4ka6fa1rw3capnw2dpyiy3psgggl7jijwvnz6dgdkbidlgplq"))))
   (cons "google-api-core"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/03/15/e56f351cf6ef1cfea58e6ac226a7318ed1deb2218c4b3cc9bd9e4b786c5a/google_api_core-2.30.3-py3-none-any.whl")
           (file-name "google_api_core-2.30.3-py3-none-any.whl")
           (sha256
            (base32 "1s5zsvzv7nx2rilwl7jjw9mjn2s86c325hhisvaxli64fax62mx8"))))
   (cons "google-api-python-client"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/b0/34/5a624e49f179aa5b0cb87b2ce8093960299030ff40423bfbde09360eb908/google_api_python_client-2.194.0-py3-none-any.whl")
           (file-name "google_api_python_client-2.194.0-py3-none-any.whl")
           (sha256
            (base32 "05z7jxvfz1jz81bipk0rffrx2hhk7ny7my4aq08xz3zwp31smsk1"))))
   (cons "google-auth"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/e8/1d/f6d3ca1ad0725f2e08a1c6915640748a52de2e66596160a4d53b010cccf0/google_auth-2.55.1-py3-none-any.whl")
           (file-name "google_auth-2.55.1-py3-none-any.whl")
           (sha256
            (base32 "159rkiv5alyw1milnlqqr102b89z1hm1wq1730cq2frbspgninpa"))))
   (cons "google-auth-httplib2"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/97/e9/93afb14d23a949acaa3f4e7cc51a0024671174e116e35f42850764b99634/google_auth_httplib2-0.3.1-py3-none-any.whl")
           (file-name "google_auth_httplib2-0.3.1-py3-none-any.whl")
           (sha256
            (base32 "0p17pimaiha4lq1h66x1jl1w0vza5q8yjdwcah33vfpl1slmc8v8"))))
   (cons "google-auth-oauthlib"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/2a/e0/cb454a95f460903e39f101e950038ec24a072ca69d0a294a6df625cc1627/google_auth_oauthlib-1.3.1-py3-none-any.whl")
           (file-name "google_auth_oauthlib-1.3.1-py3-none-any.whl")
           (sha256
            (base32 "1y779vd4i0i1g0lrlcjmjv9gz2r3bijmzsdh0ml7a60k7zr9w4qs"))))
   (cons "google-cloud-pubsub"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/93/20/dd0b27d4ad4577c062e77ff968ca3e2d404186cd78c8a2a53a0ef5fe5389/google_cloud_pubsub-2.39.0-py3-none-any.whl")
           (file-name "google_cloud_pubsub-2.39.0-py3-none-any.whl")
           (sha256
            (base32 "069y5p8x4kdyndj4jqlvw8yyccdpdsz9x2cnjrancykdlj8xc43j"))))
   (cons "googleapis-common-protos"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/69/28/23eea8acd65972bbfe295ce3666b28ac510dfcb115fac089d3edb0feb00a/googleapis_common_protos-1.73.0-py3-none-any.whl")
           (file-name "googleapis_common_protos-1.73.0-py3-none-any.whl")
           (sha256
            (base32 "1s5l88lxpaki8c1wpyrcw0d59wf5nmn6s7jnpr32090ghqpamnnz"))))
   (cons "greenlet"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/78/2b/28ed29463522fdbe4c15b1f63922041626a7478316b34ab4adda3f0a4aba/greenlet-3.5.3-cp311-cp311-manylinux_2_24_x86_64.manylinux_2_28_x86_64.whl")
           (file-name "greenlet-3.5.3-cp311-cp311-manylinux_2_24_x86_64.manylinux_2_28_x86_64.whl")
           (sha256
            (base32 "1mq3b6nvijf65391a2hsnjhm9jhrf81q2mb8rsh3rlav43kg2h45"))))
   (cons "grpc-google-iam-v1"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/84/ab/be3ad0d46cffe35fd1e7cc3f9947edd6cb3c552229de3be2742f15f7ea47/grpc_google_iam_v1-0.14.5-py3-none-any.whl")
           (file-name "grpc_google_iam_v1-0.14.5-py3-none-any.whl")
           (sha256
            (base32 "1jl1f5mamf5bv211lxa39v50zmwl9nh9sxlcwr0r82ma405nhphg"))))
   (cons "grpcio"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/23/d6/abeda5c2b896a0b341584fe5ac411bbf72e197a9a374c355fb90965e08d2/grpcio-1.81.1-cp311-cp311-manylinux2014_x86_64.manylinux_2_17_x86_64.whl")
           (file-name "grpcio-1.81.1-cp311-cp311-manylinux2014_x86_64.manylinux_2_17_x86_64.whl")
           (sha256
            (base32 "1hhf8z26hx1d9n84rr3s8q86l49q9hxfd0xkhj1kc6hbr1f1cdqa"))))
   (cons "grpcio-status"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/e5/5e/5abfec5f7e89d3b7993d57cfb025ca5f968a2c18656d7fcda2b6919440b9/grpcio_status-1.81.1-py3-none-any.whl")
           (file-name "grpcio_status-1.81.1-py3-none-any.whl")
           (sha256
            (base32 "0cpj711i2q7j63gspg47038765a1wa2lyvzw8z39ajjzk6ljy1q8"))))
   (cons "grpclib"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/5c/90/b0cbbd9efcc82816c58f31a34963071aa19fb792a212a5d9caf8e0fc3097/grpclib-0.4.9-py3-none-any.whl")
           (file-name "grpclib-0.4.9-py3-none-any.whl")
           (sha256
            (base32 "03ng4k53a93h54z28byambn1mlfb6pfm4la7jzazlkfriqffqqkp"))))
   (cons "h11"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/04/4b/29cac41a4d98d144bf5f6d33995617b185d14b22401f75ca86f384e87ff1/h11-0.16.0-py3-none-any.whl")
           (file-name "h11-0.16.0-py3-none-any.whl")
           (sha256
            (base32 "11kcrcqlp99djdajvrnsngzn883pqbcs3z9jb7v3ppi2fnz8pkv3"))))
   (cons "h2"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/69/b2/119f6e6dcbd96f9069ce9a2665e0146588dc9f88f29549711853645e736a/h2-4.3.0-py3-none-any.whl")
           (file-name "h2-4.3.0-py3-none-any.whl")
           (sha256
            (base32 "1p9b1svk2546xvd82aa1ysjp6gywa6whzkqckv34ayazl8lz0f64"))))
   (cons "hf-xet"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/d3/35/db860aa3a0780660324a506ad4b3d322ddc6ecbba4b9340aed0942cbf21c/hf_xet-1.5.2-cp38-abi3-manylinux2014_x86_64.manylinux_2_17_x86_64.whl")
           (file-name "hf_xet-1.5.2-cp38-abi3-manylinux2014_x86_64.manylinux_2_17_x86_64.whl")
           (sha256
            (base32 "131yy2y1miaf5d3l4vamhl39if1s6y7j7qlqvjnrs9ynhffc6y6v"))))
   (cons "honcho-ai"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/d0/c6/66af5f7ba3d75796f4523eac1e069fbdc759c3f0b8adab9fb7ae04e15784/honcho_ai-2.2.0-py3-none-any.whl")
           (file-name "honcho_ai-2.2.0-py3-none-any.whl")
           (sha256
            (base32 "1wk12wmfwn475k7g5l39f348v9jjpjqdlkcry2445zmwr2j9iw1j"))))
   (cons "hpack"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/07/c6/80c95b1b2b94682a72cbdbfb85b81ae2daffa4291fbfa1b1464502ede10d/hpack-4.1.0-py3-none-any.whl")
           (file-name "hpack-4.1.0-py3-none-any.whl")
           (sha256
            (base32 "15mlw7mcgghv4xrddj69y0ad2pjkni31y4ckgmjmr6cdcs9cfyhm"))))
   (cons "httpcore"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/7e/f5/f66802a942d491edb555dd61e3a9961140fd64c90bce1eafd741609d334d/httpcore-1.0.9-py3-none-any.whl")
           (file-name "httpcore-1.0.9-py3-none-any.whl")
           (sha256
            (base32 "0mdzl73j982lss7w7a20ns2482xlfa82644qxjfzqs06li30fh1d"))))
   (cons "httpcore2"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/6f/6c/62e2e279e63fc4f7a5ee841ef13175a8bbc613f258e9dcc186e9de803a42/httpcore2-2.7.0-py3-none-any.whl")
           (file-name "httpcore2-2.7.0-py3-none-any.whl")
           (sha256
            (base32 "0azr30nxa7vn3avw0awhmwq978j19hlq9n3cai25px93zs4zalhl"))))
   (cons "httplib2"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/33/a0/550eec327e5f5c7b732531c489f5307efec41f047b0d703bd4ca1e5ad2db/httplib2-0.32.0-py3-none-any.whl")
           (file-name "httplib2-0.32.0-py3-none-any.whl")
           (sha256
            (base32 "05j8gqbvw9jq69bw3c2x0cq3xn8gr4rzlabnp8m0myzkrp50aryw"))))
   (cons "httptools"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/cc/cc/10935db22fda0ee34c76f047590ca0a8bd9de531406a3ccb10a90e12ea21/httptools-0.7.1-cp311-cp311-manylinux1_x86_64.manylinux_2_28_x86_64.manylinux_2_5_x86_64.whl")
           (file-name "httptools-0.7.1-cp311-cp311-manylinux1_x86_64.manylinux_2_28_x86_64.manylinux_2_5_x86_64.whl")
           (sha256
            (base32 "1pyrd79zz35m1nvws635jfihkh6phdhk4lxjyd3pyx5q12a4g6rp"))))
   (cons "httpx"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/2a/39/e50c7c3a983047577ee07d2a9e53faf5a69493943ec3f6a384bdc792deb2/httpx-0.28.1-py3-none-any.whl")
           (file-name "httpx-0.28.1-py3-none-any.whl")
           (sha256
            (base32 "1barpaw8as8xb7b2bsmzdmdbq5nqljlq5jhlz3xcgy0hq76gq2fr"))))
   (cons "httpx-sse"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/d2/fd/6668e5aec43ab844de6fc74927e155a3b37bf40d7c3790e49fc0406b6578/httpx_sse-0.4.3-py3-none-any.whl")
           (file-name "httpx_sse-0.4.3-py3-none-any.whl")
           (sha256
            (base32 "1z1hi1bcblpsg7vr29krc0xq5izlb5596nmjxghd5yha7kzckh8a"))))
   (cons "httpx2"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/1d/b8/c341bba6411bdfda786020343c47a75ef472f6085caf82391b142b1a3ad9/httpx2-2.7.0-py3-none-any.whl")
           (file-name "httpx2-2.7.0-py3-none-any.whl")
           (sha256
            (base32 "1x3v5w9xwnn2kqw6hsz2qrf95gfqqfzf5n1v944rwy4nqqcjfapd"))))
   (cons "huggingface-hub"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/5f/c3/aeaaf3911d2529614be18d1c8b5496afc185560e76568063d517283318af/huggingface_hub-1.24.0-py3-none-any.whl")
           (file-name "huggingface_hub-1.24.0-py3-none-any.whl")
           (sha256
            (base32 "0nbxzf0vvj2xxxpm4h8y6jvscrnpdcs7xaj00s8frgm6hh515m3f"))))
   (cons "hyperframe"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/48/30/47d0bf6072f7252e6521f3447ccfa40b421b6824517f82854703d0f5a98b/hyperframe-6.1.0-py3-none-any.whl")
           (file-name "hyperframe-6.1.0-py3-none-any.whl")
           (sha256
            (base32 "1ra2387yiz2zhfhgg5jm8ayzjyri8952xx2sx9ccx7si794q0cxh"))))
   (cons "idna"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/1e/5e/d4e9f1a599fb8e573b7b87160658329fbf28d19eac2718f51fc3def3aa5a/idna-3.18-py3-none-any.whl")
           (file-name "idna-3.18-py3-none-any.whl")
           (sha256
            (base32 "18j9x2fnijkp81f9ha1rpjldlprybi7y2zgqwdaq0s0bfaz2r5bz"))))
   (cons "importlib-metadata"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/fa/5e/f8e9a1d23b9c20a551a8a02ea3637b4642e22c2626e3a13a9a29cdea99eb/importlib_metadata-8.7.1-py3-none-any.whl")
           (file-name "importlib_metadata-8.7.1-py3-none-any.whl")
           (sha256
            (base32 "0lb12x9kn1j429c9khlbibr4qqsssyav1yqy0yar8j5a3nzq07ss"))))
   (cons "jinja2"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/62/a1/3d680cbfd5f4b8f15abc1d571870c5fc3e594bb582bc3b64ea099db13e56/jinja2-3.1.6-py3-none-any.whl")
           (file-name "jinja2-3.1.6-py3-none-any.whl")
           (sha256
            (base32 "0rrgdp707wfs11wk8prswvx6ma418sk16z6xql9hqba93x2y9v45"))))
   (cons "jiter"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/6e/09/9fe4c159358176f82d4390407a03f506a8659ed13ca3ac93a843402acecf/jiter-0.13.0-cp311-cp311-manylinux_2_17_x86_64.manylinux2014_x86_64.whl")
           (file-name "jiter-0.13.0-cp311-cp311-manylinux_2_17_x86_64.manylinux2014_x86_64.whl")
           (sha256
            (base32 "062h1gjaa2lsmym48y0iq7308czjn8gf3a1n7baz61aydl947ar4"))))
   (cons "jmespath"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/14/2f/967ba146e6d58cf6a652da73885f52fc68001525b4197effc174321d70b4/jmespath-1.1.0-py3-none-any.whl")
           (file-name "jmespath-1.1.0-py3-none-any.whl")
           (sha256
            (base32 "0r3wx7sf0shirl8dx0wfd6r6wljnransr85y54bwj229vqc32rm5"))))
   (cons "joblib"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/7b/91/984aca2ec129e2757d1e4e3c81c3fcda9d0f85b74670a094cc443d9ee949/joblib-1.5.3-py3-none-any.whl")
           (file-name "joblib-1.5.3-py3-none-any.whl")
           (sha256
            (base32 "04z733ngkivblzd34rpy6ymvgmjrpn5ihfikfq18rjn5kw1wbhsz"))))
   (cons "jsonpath-python"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/55/8a/1270a6803bd821cbfcdda387eaa13cb41a7b1f7b9bd145979b3bfb9d6cb7/jsonpath_python-1.1.6-py3-none-any.whl")
           (file-name "jsonpath_python-1.1.6-py3-none-any.whl")
           (sha256
            (base32 "1m52663lv13xjwkh60jwdylmvhdkvj8chfw7li3szfrzipyhmid1"))))
   (cons "jsonschema"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/69/90/f63fb5873511e014207a475e2bb4e8b2e570d655b00ac19a9a0ca0a385ee/jsonschema-4.26.0-py3-none-any.whl")
           (file-name "jsonschema-4.26.0-py3-none-any.whl")
           (sha256
            (base32 "1kjhmcnmylpvznwdwwzvb6an41jzlz1v8r3y73w01lmqcd9g32fl"))))
   (cons "jsonschema-specifications"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/41/45/1a4ed80516f02155c51f51e8cedb3c1902296743db0bbc66608a0db2814f/jsonschema_specifications-2025.9.1-py3-none-any.whl")
           (file-name "jsonschema_specifications-2025.9.1-py3-none-any.whl")
           (sha256
            (base32 "1zn61hhky48v2lw2h3qan2cgy6x4m3yjji54mkn7dvhi7bp2z04q"))))
   (cons "lark-oapi"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/4a/ad/1ab04db5d549ad1a7a2cd33682b1c38dee1d65019cb24fd7a23270e6337d/lark_oapi-1.6.8-py3-none-any.whl")
           (file-name "lark_oapi-1.6.8-py3-none-any.whl")
           (sha256
            (base32 "1s75yxynv020q545rr48az1pq23midn8jh6w8bfh9lm78xfkli4v"))))
   (cons "markdown"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/de/1f/77fa3081e4f66ca3576c896ae5d31c3002ac6607f9747d2e3aa49227e464/markdown-3.10.2-py3-none-any.whl")
           (file-name "markdown-3.10.2-py3-none-any.whl")
           (sha256
            (base32 "0djch8ri2xnly69dp652v67ibbqbxxcg7n8p63ypmvp33avn8579"))))
   (cons "markdown-it-py"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/94/54/e7d793b573f298e1c9013b8c4dade17d481164aa517d1d7148619c2cedbf/markdown_it_py-4.0.0-py3-none-any.whl")
           (file-name "markdown_it_py-4.0.0-py3-none-any.whl")
           (sha256
            (base32 "0iw1axnqrd1vjyjdg350012pbdj32fl570q3jqc03ibjn5cpqcl7"))))
   (cons "markupsafe"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/30/ac/0273f6fcb5f42e314c6d8cd99effae6a5354604d461b8d392b5ec9530a54/markupsafe-3.0.3-cp311-cp311-manylinux2014_x86_64.manylinux_2_17_x86_64.manylinux_2_28_x86_64.whl")
           (file-name "markupsafe-3.0.3-cp311-cp311-manylinux2014_x86_64.manylinux_2_17_x86_64.manylinux_2_28_x86_64.whl")
           (sha256
            (base32 "1gwxpn9k4vf7w5h98ysywa49hsx62v36xhjdlg4yaxkysrjaiwhb"))))
   (cons "marshmallow"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/aa/70/bb89f807a6a6704bdc4d6f850d5d32954f6c1965e3248e31455defdf2f30/marshmallow-4.2.2-py3-none-any.whl")
           (file-name "marshmallow-4.2.2-py3-none-any.whl")
           (sha256
            (base32 "08f19mmrvcqgnvdfpigdky8syfc7fpnmm9m37hccfzhv25k98jh8"))))
   (cons "mautrix"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/ea/a0/b6a97878fba55003065f389b08856de63a84c7f3b6bb378dcc71b60ed740/mautrix-0.21.1-py3-none-any.whl")
           (file-name "mautrix-0.21.1-py3-none-any.whl")
           (sha256
            (base32 "08v89f7rh168v8cn6zfx1503cf6qs9nhw08f79dnqvz2xacbk1bn"))))
   (cons "mcp"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/67/72/7d7897418912c1d12e87556630dfb7bf0eac71160e9bef8b447960804ee3/mcp-2.0.0-py3-none-any.whl")
           (file-name "mcp-2.0.0-py3-none-any.whl")
           (sha256
            (base32 "1mj94dcs6z0x0ni24gpiqwn85wir5bcfamb3flfqqyrc5mfwgd0w"))))
   (cons "mcp-types"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/f5/4c/c78d78c3d52b0ac594ad7cc8ef5972adfe070e3597a8a4c6ce0cd39196ea/mcp_types-2.0.0-py3-none-any.whl")
           (file-name "mcp_types-2.0.0-py3-none-any.whl")
           (sha256
            (base32 "1c4f3dnrl0zizs1bvh5w27jlvqs8b6rf2acmnxlgb5r7rabyfbbb"))))
   (cons "mdurl"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/b3/38/89ba8ad64ae25be8de66a6d463314cf1eb366222074cfda9ee839c56a4b4/mdurl-0.1.2-py3-none-any.whl")
           (file-name "mdurl-0.1.2-py3-none-any.whl")
           (sha256
            (base32 "1y5qjqhmq2nm7xj6w5rrp503r7jhj7zr2qcnr6gs858nwm0ql044"))))
   (cons "mem0ai"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/a4/58/9c25e77f06ec3483267f898c42fba783f2dcc411c7234dd34830bef8a372/mem0ai-2.0.10-py3-none-any.whl")
           (file-name "mem0ai-2.0.10-py3-none-any.whl")
           (sha256
            (base32 "0qj0wg4i7zqyyr1aqp6pnh16id4f8lz1j2vqmgvbmgsp5hf416cs"))))
   (cons "microsoft-teams-api"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/27/15/e1a1369a22c265b52da3ac4b3ee67b5c02911300db045894868bd7be932f/microsoft_teams_api-2.0.13.4-py3-none-any.whl")
           (file-name "microsoft_teams_api-2.0.13.4-py3-none-any.whl")
           (sha256
            (base32 "0cmmcj8dk6q242p91s3lzj2rr1lj25mzzq9dk3h52n7acmvyylmy"))))
   (cons "microsoft-teams-apps"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/3a/d4/3c4205258642035d160c09f598a302260776dcb6d5bdf659eea7c6066d5e/microsoft_teams_apps-2.0.13.4-py3-none-any.whl")
           (file-name "microsoft_teams_apps-2.0.13.4-py3-none-any.whl")
           (sha256
            (base32 "0v59zshwv651cnpghch7hirvp41fg4lnlf6654lmk2v5xhagf5nv"))))
   (cons "microsoft-teams-cards"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/20/09/95cad44d4417e33df11a15c82ca1bde442c1f1f77396f936f18896f116c1/microsoft_teams_cards-2.0.13.4-py3-none-any.whl")
           (file-name "microsoft_teams_cards-2.0.13.4-py3-none-any.whl")
           (sha256
            (base32 "02br7lvw3gr5kammh9ij9pgyphsyy3d68h3hymgnfi41di38gf5q"))))
   (cons "microsoft-teams-common"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/cb/04/859b3d7fadd1d61ab581f79afb6125c16c60cecf2a2e6bbb2ebbcfd34f80/microsoft_teams_common-2.0.13.4-py3-none-any.whl")
           (file-name "microsoft_teams_common-2.0.13.4-py3-none-any.whl")
           (sha256
            (base32 "10hdzmh82iik5p5155fk6f7xbdi156vyjy2sgk89gmw7ap3lwlhr"))))
   (cons "mistralai"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/74/2a/d9952a97596ff9570ff7f486084ebfc5637b1bcf62084b97c0f8415713fc/mistralai-2.4.8-py3-none-any.whl")
           (file-name "mistralai-2.4.8-py3-none-any.whl")
           (sha256
            (base32 "0wk4gw8wbgb976zyilm5xgk64gsd3v6hiixnbpa35wzdnp44bi7d"))))
   (cons "modal"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/2c/aa/f0ffbe6bf679a597e8be692ca3cde47de6156435c2b72cf752fec719bb1f/modal-1.3.4-py3-none-any.whl")
           (file-name "modal-1.3.4-py3-none-any.whl")
           (sha256
            (base32 "101k96agay06xg1xvvki26l1rkimhiqc7w8j6mmr6izld4cqasnn"))))
   (cons "msal"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/2a/d3/414d1f0a5f6f4fe5313c2b002c54e78a3332970feb3f5fed14237aa17064/msal-1.36.0-py3-none-any.whl")
           (file-name "msal-1.36.0-py3-none-any.whl")
           (sha256
            (base32 "1i4fwnqapp2fp64svcdcy0liqc427k7ap6h2avcj4hzzw8qarv1n"))))
   (cons "msal-extensions"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/5e/75/bd9b7bb966668920f06b200e84454c8f3566b102183bc55c5473d96cb2b9/msal_extensions-1.3.1-py3-none-any.whl")
           (file-name "msal_extensions-1.3.1-py3-none-any.whl")
           (sha256
            (base32 "1jkbpsfwlbmgly7lr3jnqssp70vc23lbm1aymilyj1250d6xxlwn"))))
   (cons "msgpack"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/03/8d/671d81534ea0e2b0e8a121be100020da09eb78861fe3aa8f3ef7dcd3bed1/msgpack-1.2.1-cp311-cp311-manylinux2014_x86_64.manylinux_2_17_x86_64.manylinux_2_28_x86_64.whl")
           (file-name "msgpack-1.2.1-cp311-cp311-manylinux2014_x86_64.manylinux_2_17_x86_64.manylinux_2_28_x86_64.whl")
           (sha256
            (base32 "1d39a4wk5f0y4kj51vcb0dbrai49fhabg45d523rqay8lxn0g3d2"))))
   (cons "multidict"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/5a/56/21b27c560c13822ed93133f08aa6372c53a8e067f11fbed37b4adcdac922/multidict-6.7.1-cp311-cp311-manylinux2014_x86_64.manylinux_2_17_x86_64.manylinux_2_28_x86_64.whl")
           (file-name "multidict-6.7.1-cp311-cp311-manylinux2014_x86_64.manylinux_2_17_x86_64.manylinux_2_28_x86_64.whl")
           (sha256
            (base32 "0i4il6c577qqc04x51mf96kxyqd1ra56l0ckcymfk4lz96yvx723"))))
   (cons "narwhals"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/7e/85/a5bfaebfd305ac18b57b0854d74e37e586809061a91fda62f0bd50c8518e/narwhals-2.24.0-py3-none-any.whl")
           (file-name "narwhals-2.24.0-py3-none-any.whl")
           (sha256
            (base32 "12blvx9338iccphrzfjw93c3i3q5qd55pm1har8afb2v9vsfvza2"))))
   (cons "nemo-relay"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/18/00/15705b941df64443e50c49139140dd84603f23125ab48f9c122942911439/nemo_relay-0.8.3-cp311-abi3-manylinux_2_17_x86_64.manylinux2014_x86_64.whl")
           (file-name "nemo_relay-0.8.3-cp311-abi3-manylinux_2_17_x86_64.manylinux2014_x86_64.whl")
           (sha256
            (base32 "0xmijvf5cyarx5a4ibly4rgx3yjg8n3b0prfs15gbn3qjs9qmc0h"))))
   (cons "nest-asyncio"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/a0/c4/c2971a3ba4c6103a3d10c4b0f24f461ddc027f0f09763220cf35ca1401b3/nest_asyncio-1.6.0-py3-none-any.whl")
           (file-name "nest_asyncio-1.6.0-py3-none-any.whl")
           (sha256
            (base32 "071fhnqhaagz3bhcl0qpslsjyarfqrjyyxq40n0pr2aydgynxbw7"))))
   (cons "numpy"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/78/51/9f5d7a41f0b51649ddf2f2320595e15e122a40610b233d51928dd6c92353/numpy-2.4.3-cp311-cp311-manylinux_2_27_x86_64.manylinux_2_28_x86_64.whl")
           (file-name "numpy-2.4.3-cp311-cp311-manylinux_2_27_x86_64.manylinux_2_28_x86_64.whl")
           (sha256
            (base32 "0wdav9k3cgi3jz554q82is7mj5xdjxyk8yjhbap8qbhr5vwffpbi"))))
   (cons "oauthlib"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/be/9c/92789c596b8df838baa98fa71844d84283302f7604ed565dafe5a6b5041a/oauthlib-3.3.1-py3-none-any.whl")
           (file-name "oauthlib-3.3.1-py3-none-any.whl")
           (sha256
            (base32 "18dp4dsyndiifh9ggcbv5daqvk68xvh6wpxgc62vi3rbin9rq4c8"))))
   (cons "obstore"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/14/7a/5fc63b41526587067537fb1498c59a210884664c65ccf0d1f8f823b0875a/obstore-0.8.2-cp311-cp311-manylinux_2_17_x86_64.manylinux2014_x86_64.whl")
           (file-name "obstore-0.8.2-cp311-cp311-manylinux_2_17_x86_64.manylinux2014_x86_64.whl")
           (sha256
            (base32 "14lzm8wy8gi9717p5k5iqrflj7h7ca65bdf8k2z93h8cc8w9rynv"))))
   (cons "onnxruntime"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/e0/cd/74bb804170ceb622fda9111df31a07b3024f7491472256d3a90b5391a4d2/onnxruntime-1.27.0-cp311-cp311-manylinux_2_27_x86_64.manylinux_2_28_x86_64.whl")
           (file-name "onnxruntime-1.27.0-cp311-cp311-manylinux_2_27_x86_64.manylinux_2_28_x86_64.whl")
           (sha256
            (base32 "1x1ndnrchfidl675bv6k2nw3l60n2qlwi9pa5ln2w89d1plv1xz4"))))
   (cons "openai"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/c9/30/844dc675ee6902579b8eef01ed23917cc9319a1c9c0c14ec6e39340c96d0/openai-2.24.0-py3-none-any.whl")
           (file-name "openai-2.24.0-py3-none-any.whl")
           (sha256
            (base32 "151xlyvk78mlkb7zngsmc1xi6jqak1jfigc768q89j6nsy009lzy"))))
   (cons "opentelemetry-api"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/cf/df/d3f1ddf4bb4cb50ed9b1139cc7b1c54c34a1e7ce8fd1b9a37c0d1551a6bd/opentelemetry_api-1.39.1-py3-none-any.whl")
           (file-name "opentelemetry_api-1.39.1-py3-none-any.whl")
           (sha256
            (base32 "0l4rghc9hf6iwqlws02ml3bfg5did4hrg46fxm1q8zra8diq9p9f"))))
   (cons "opentelemetry-exporter-otlp-proto-common"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/8c/02/ffc3e143d89a27ac21fd557365b98bd0653b98de8a101151d5805b5d4c33/opentelemetry_exporter_otlp_proto_common-1.39.1-py3-none-any.whl")
           (file-name "opentelemetry_exporter_otlp_proto_common-1.39.1-py3-none-any.whl")
           (sha256
            (base32 "1pjgfq67snanrnl48s7q05bxqr8kdhhx11jn20sk9k345n3aby08"))))
   (cons "opentelemetry-exporter-otlp-proto-http"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/95/f1/b27d3e2e003cd9a3592c43d099d2ed8d0a947c15281bf8463a256db0b46c/opentelemetry_exporter_otlp_proto_http-1.39.1-py3-none-any.whl")
           (file-name "opentelemetry_exporter_otlp_proto_http-1.39.1-py3-none-any.whl")
           (sha256
            (base32 "11crslppbyqg6xn9qvmy2fxfrv3mi3569mac5i0jlxfxhdqj1xfr"))))
   (cons "opentelemetry-instrumentation"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/77/d2/6788e83c5c86a2690101681aeef27eeb2a6bf22df52d3f263a22cee20915/opentelemetry_instrumentation-0.60b1-py3-none-any.whl")
           (file-name "opentelemetry_instrumentation-0.60b1-py3-none-any.whl")
           (sha256
            (base32 "0bb3g1y768iig6iw3sn3wxxjn096xvq25y3k03nv33xlaawhsj04"))))
   (cons "opentelemetry-instrumentation-aiohttp-client"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/ca/f4/1a1ec632c86269750ae833c8fbdd4c8d15316eb1c21e3544e34791c805ee/opentelemetry_instrumentation_aiohttp_client-0.60b1-py3-none-any.whl")
           (file-name "opentelemetry_instrumentation_aiohttp_client-0.60b1-py3-none-any.whl")
           (sha256
            (base32 "18f2g1520bb3hln22hsc94m9g4ibv2g412m8lb2ic2x3arr0ki9l"))))
   (cons "opentelemetry-proto"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/51/95/b40c96a7b5203005a0b03d8ce8cd212ff23f1793d5ba289c87a097571b18/opentelemetry_proto-1.39.1-py3-none-any.whl")
           (file-name "opentelemetry_proto-1.39.1-py3-none-any.whl")
           (sha256
            (base32 "01v0wkgdk1rk89mhpzcah74m9hjg1l0vvgv8kv86adrvzn7cgk92"))))
   (cons "opentelemetry-sdk"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/7c/98/e91cf858f203d86f4eccdf763dcf01cf03f1dae80c3750f7e635bfa206b6/opentelemetry_sdk-1.39.1-py3-none-any.whl")
           (file-name "opentelemetry_sdk-1.39.1-py3-none-any.whl")
           (sha256
            (base32 "077h8lzkzbzkx6z7c9ncw1k70r2f75hwr3ckbl5cngjig3284m2d"))))
   (cons "opentelemetry-semantic-conventions"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/7a/5e/5958555e09635d09b75de3c4f8b9cae7335ca545d77392ffe7331534c402/opentelemetry_semantic_conventions-0.60b1-py3-none-any.whl")
           (file-name "opentelemetry_semantic_conventions-0.60b1-py3-none-any.whl")
           (sha256
            (base32 "1ywkg1cnhzcp3q126sjjq59pnfhd4a8haar916c2inhhq6qcia4z"))))
   (cons "opentelemetry-util-http"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/16/5c/d3f1733665f7cd582ef0842fb1d2ed0bc1fba10875160593342d22bba375/opentelemetry_util_http-0.60b1-py3-none-any.whl")
           (file-name "opentelemetry_util_http-0.60b1-py3-none-any.whl")
           (sha256
            (base32 "16gizaqb95j5cck94q7dy5548hz4miwqkfnw2kp1pjahhni1nf36"))))
   (cons "openwakeword"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/8a/33/dafd6822bebe463a9098951d06a0d88fb4f8c946ce087025bc4fa132e533/openwakeword-0.6.0-py3-none-any.whl")
           (file-name "openwakeword-0.6.0-py3-none-any.whl")
           (sha256
            (base32 "17dw5871q0icr3blkcsagdl9yrv9py5gyl1bs4y0xpg97973lhkg"))))
   (cons "packaging"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/b7/b9/c538f279a4e237a006a2c98387d081e9eb060d203d8ed34467cc0f0b9b53/packaging-26.0-py3-none-any.whl")
           (file-name "packaging-26.0-py3-none-any.whl")
           (sha256
            (base32 "0abmlgvky3d8mbirsssynpr23r8ldb9bry36865mi99ljgpiyvxk"))))
   (cons "parallel-web"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/a0/3e/2218fa29637781b8e7ac35a928108ff2614ddd40879389d3af2caa725af5/parallel_web-0.4.2-py3-none-any.whl")
           (file-name "parallel_web-0.4.2-py3-none-any.whl")
           (sha256
            (base32 "0iikyp7zjc1yk9yjgpglvxrk740p94fjf0wkrv2p52f0xjd4lfma"))))
   (cons "pathspec"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/f1/d9/7fb5aa316bc299258e68c73ba3bddbc499654a07f151cba08f6153988714/pathspec-1.1.1-py3-none-any.whl")
           (file-name "pathspec-1.1.1-py3-none-any.whl")
           (sha256
            (base32 "12di42dhpbympdw8q4jkvyzzii1b45b80c9j753pzgvpym1fc350"))))
   (cons "pillow"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/3b/2d/ede717bc1144f63886c21fd349bb95860b0d1a21149ff16f2bb362b612b6/pillow-12.3.0-cp311-cp311-manylinux_2_27_x86_64.manylinux_2_28_x86_64.whl")
           (file-name "pillow-12.3.0-cp311-cp311-manylinux_2_27_x86_64.manylinux_2_28_x86_64.whl")
           (sha256
            (base32 "1gd5xsirhsp7yjfy3sq4fl4qv9lsj5xjirsiri225v070cz7mli3"))))
   (cons "pillow-heif"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/84/69/a8f1a432263632db6e633d87a1658265b09a1760020cb7dc711490b871c6/pillow_heif-1.5.0-cp311-cp311-manylinux_2_27_x86_64.manylinux_2_28_x86_64.whl")
           (file-name "pillow_heif-1.5.0-cp311-cp311-manylinux_2_27_x86_64.manylinux_2_28_x86_64.whl")
           (sha256
            (base32 "1fsvnkrw7gaga5ln43z37l71ykx0809jqmcj8ld8vwxa4jjavxw5"))))
   (cons "portalocker"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/4b/a6/38c8e2f318bf67d338f4d629e93b0b4b9af331f455f0390ea8ce4a099b26/portalocker-3.2.0-py3-none-any.whl")
           (file-name "portalocker-3.2.0-py3-none-any.whl")
           (sha256
            (base32 "0s4rfw8ryjpgp5cczfv3yc7bm2s246ykg4y4f32ln8hjadb5zp1w"))))
   (cons "posthog"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/c3/07/ca761fd0e3b23e9bfeaaeeffa5df4c235fd0c5086d89934553583e6902f3/posthog-7.21.0-py3-none-any.whl")
           (file-name "posthog-7.21.0-py3-none-any.whl")
           (sha256
            (base32 "1h0yipdkrdc30i1y4wjfkazxvp58byab07vm45kwpv9bfzls3p0i"))))
   (cons "prompt-toolkit"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/84/03/0d3ce49e2505ae70cf43bc5bb3033955d2fc9f932163e84dc0779cc47f48/prompt_toolkit-3.0.52-py3-none-any.whl")
           (file-name "prompt_toolkit-3.0.52-py3-none-any.whl")
           (sha256
            (base32 "0mcrl7bgr58hqavkkp32ly8ln16civbdhnny8x1jhcxx7fd67b4s"))))
   (cons "propcache"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/52/6a/57f43e054fb3d3a56ac9fc532bc684fc6169a26c75c353e65425b3e56eef/propcache-0.4.1-cp311-cp311-manylinux2014_x86_64.manylinux_2_17_x86_64.manylinux_2_28_x86_64.whl")
           (file-name "propcache-0.4.1-cp311-cp311-manylinux2014_x86_64.manylinux_2_17_x86_64.manylinux_2_28_x86_64.whl")
           (sha256
            (base32 "0j2szj2gz81x3zw534kx9l71d1m0ipqm9nilpl5agqlsrzyk0vzx"))))
   (cons "proto-plus"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/84/f3/1fba73eeffafc998a25d59703b63f8be4fe8a5cb12eaff7386a0ba0f7125/proto_plus-1.27.2-py3-none-any.whl")
           (file-name "proto_plus-1.27.2-py3-none-any.whl")
           (sha256
            (base32 "0617s8hii81cmqa3syab2vxi2nzn0cpisbs1kh5ygffkjdcgfck4"))))
   (cons "protobuf"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/9b/53/a9443aa3ca9ba8724fdfa02dd1887c1bcd8e89556b715cfbacca6b63dbec/protobuf-6.33.5-cp39-abi3-manylinux2014_x86_64.whl")
           (file-name "protobuf-6.33.5-cp39-abi3-manylinux2014_x86_64.whl")
           (sha256
            (base32 "1w0wabivw628r9v7jp5k4p0jsyb7b4hznn58zj4vidqg6ninpwfb"))))
   (cons "psutil"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/b5/70/5d8df3b09e25bce090399cf48e452d25c935ab72dad19406c77f4e828045/psutil-7.2.2-cp36-abi3-manylinux2010_x86_64.manylinux_2_12_x86_64.manylinux_2_28_x86_64.whl")
           (file-name "psutil-7.2.2-cp36-abi3-manylinux2010_x86_64.manylinux_2_12_x86_64.manylinux_2_28_x86_64.whl")
           (sha256
            (base32 "1yf6bg578msswkw8akh1r46sjgajb7q8kfpm8hb85m1zj8pjssh7"))))
   (cons "ptyprocess"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/22/a6/858897256d0deac81a172289110f31629fc4cee19b6f01283303e18c8db3/ptyprocess-0.7.0-py2.py3-none-any.whl")
           (file-name "ptyprocess-0.7.0-py2.py3-none-any.whl")
           (sha256
            (base32 "0dgg5x4nvdpfiz552diy11xg72y14s38hjz9qxygafnfgybg6hab"))))
   (cons "pvporcupine"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/2a/ef/1c4b8e47d8248fe1b615772028265ca65d9ff3ea98022d84cd973d46db87/pvporcupine-4.0.3-py3-none-any.whl")
           (file-name "pvporcupine-4.0.3-py3-none-any.whl")
           (sha256
            (base32 "1yzby8bfn5gqj42p7vqr9ziswldirv5h41z23kdmc2pq7jynsycj"))))
   (cons "pyasn1"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/9a/3b/6163796d69c3977d1e4287bea4a6979161cbbdd170ebb430511e8e1999ce/pyasn1-0.6.4-py3-none-any.whl")
           (file-name "pyasn1-0.6.4-py3-none-any.whl")
           (sha256
            (base32 "12q8bxb3v3fdrlrm4ww84qx6l842vyv7y80bqh70hm6lrxvr5nny"))))
   (cons "pyasn1-modules"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/47/8d/d529b5d697919ba8c11ad626e835d4039be708a35b0d22de83a269a6682c/pyasn1_modules-0.4.2-py3-none-any.whl")
           (file-name "pyasn1_modules-0.4.2-py3-none-any.whl")
           (sha256
            (base32 "0jn1w8fmnsxx8c8gvs06753ri3rnfpf0wq66796bccnf0y93l999"))))
   (cons "pycparser"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/0c/c3/44f3fbbfa403ea2a7c779186dc20772604442dde72947e7d01069cbe98e3/pycparser-3.0-py3-none-any.whl")
           (file-name "pycparser-3.0-py3-none-any.whl")
           (sha256
            (base32 "14m9c1hjci38clwg0bvvil3ja5sjka1k2ghw9i97ssx3d50l29xp"))))
   (cons "pycryptodome"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/5f/e9/a09476d436d0ff1402ac3867d933c61805ec2326c6ea557aeeac3825604e/pycryptodome-3.23.0-cp37-abi3-manylinux_2_17_x86_64.manylinux2014_x86_64.whl")
           (file-name "pycryptodome-3.23.0-cp37-abi3-manylinux_2_17_x86_64.manylinux2014_x86_64.whl")
           (sha256
            (base32 "0x95ymwaml8m9h7ln13zid8w7i70icyhx3jwvw1vqfbs639pp668"))))
   (cons "pydantic"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/fd/7b/122376b1fd3c62c1ed9dc80c931ace4844b3c55407b6fb2d199377c9736f/pydantic-2.13.4-py3-none-any.whl")
           (file-name "pydantic-2.13.4-py3-none-any.whl")
           (sha256
            (base32 "1fls9n964p1kmg2d34xk725kqr98n4cxkabyzlv8500xwg6q58j5"))))
   (cons "pydantic-core"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/80/50/540cd3aeefc041beb111125c4bff779831a2111fc6b15a9138cda277d32c/pydantic_core-2.46.4-cp311-cp311-manylinux_2_17_x86_64.manylinux2014_x86_64.whl")
           (file-name "pydantic_core-2.46.4-cp311-cp311-manylinux_2_17_x86_64.manylinux2014_x86_64.whl")
           (sha256
            (base32 "1i5ybm4f459a70s2453z1m5myggvrqlmi9cf2cyjsdmz7238dypr"))))
   (cons "pydantic-settings"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/77/c1/6e422f34e569cf8e18df68d1939c81c099d2b61e4f7d9621c8a77560799c/pydantic_settings-2.14.2-py3-none-any.whl")
           (file-name "pydantic_settings-2.14.2-py3-none-any.whl")
           (sha256
            (base32 "0h4lki0nkl3372vp0w6mikjyyz8qsk1bq3x5bq6mbdhhg6rrf352"))))
   (cons "pygments"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/f4/7e/a72dd26f3b0f4f2bf1dd8923c85f7ceb43172af56d63c7383eb62b332364/pygments-2.20.0-py3-none-any.whl")
           (file-name "pygments-2.20.0-py3-none-any.whl")
           (sha256
            (base32 "0xh1dna5yy5lixlx97mmz3i4cfy0g9nxhsfil8iqmligsiny5ac1"))))
   (cons "pyjwt"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/a3/5e/ecf12fdb62546d64385c158514e9b2b671f7832108ef2ecd2020ce0af2d1/pyjwt-2.13.0-py3-none-any.whl")
           (file-name "pyjwt-2.13.0-py3-none-any.whl")
           (sha256
            (base32 "0a2pmj8a5j046ga2ymbqr4iqgb7qgmby3hazv6xz3cq9zwmcrbb6"))))
   (cons "pynacl"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/c9/a8/b917096b1accc9acd878819a49d3d84875731a41eb665f6ebc826b1af99e/pynacl-1.6.2-cp38-abi3-manylinux_2_34_x86_64.whl")
           (file-name "pynacl-1.6.2-cp38-abi3-manylinux_2_34_x86_64.whl")
           (sha256
            (base32 "1xjrmhfhp12gsbz4234s67hfsvp3hv1mhhxdqhcb1jn2dvik38n8"))))
   (cons "pyparsing"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/10/bd/c038d7cc38edc1aa5bf91ab8068b63d4308c66c4c8bb3cbba7dfbc049f9c/pyparsing-3.3.2-py3-none-any.whl")
           (file-name "pyparsing-3.3.2-py3-none-any.whl")
           (sha256
            (base32 "07cid767w02ss3kfbqj0kj1jf0sg3rx28zjq24j7x3chpm4a22w5"))))
   (cons "pypng"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/3e/b9/3766cc361d93edb2ce81e2e1f87dd98f314d7d513877a342d31b30741680/pypng-0.20220715.0-py3-none-any.whl")
           (file-name "pypng-0.20220715.0-py3-none-any.whl")
           (sha256
            (base32 "0b4hxpz4qapknpapz59zdb6l3qy7iqd6qlqmljrazapmp1lyjhsa"))))
   (cons "python-dateutil"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/ec/57/56b9bcc3c9c6a792fcbaf139543cee77261f3651ca9da0c93f5c1221264b/python_dateutil-2.9.0.post0-py2.py3-none-any.whl")
           (file-name "python_dateutil-2.9.0.post0-py2.py3-none-any.whl")
           (sha256
            (base32 "09q48zvsbagfa3w87zkd2c5xl54wmb9rf2hlr20j4a5fzxxvrcm8"))))
   (cons "python-dotenv"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/0b/d7/1959b9648791274998a9c3526f6d0ec8fd2233e4d4acce81bbae76b44b2a/python_dotenv-1.2.2-py3-none-any.whl")
           (file-name "python_dotenv-1.2.2-py3-none-any.whl")
           (sha256
            (base32 "0ni8rfxr9rk8bn78mak47mg9mdn6wdpsxn4bidd4bpi4k9w190hx"))))
   (cons "python-multipart"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/e1/04/e8135ebd1ad02c56ec633277529b2602ff99ff634be76cdba5744cf554fd/python_multipart-0.0.32-py3-none-any.whl")
           (file-name "python_multipart-0.0.32-py3-none-any.whl")
           (sha256
            (base32 "08rfzqhjhkn4qr71l6v17j8hx2gwdwlhgqaj9s4qr1qndxvkyvgz"))))
   (cons "python-olm"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/a8/50/da98e66dee3f0384fa0d350aa3e60865f8febf86e14dae391f89b626c4b7/python_olm-3.2.16-cp311-cp311-manylinux_2_17_x86_64.manylinux2014_x86_64.whl")
           (file-name "python_olm-3.2.16-cp311-cp311-manylinux_2_17_x86_64.manylinux2014_x86_64.whl")
           (sha256
            (base32 "1qbanyfpmvrf3wyab9fpvpwb1yq8516x11i9h1n9iq5z0k7yh76l"))))
   (cons "python-socks"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/15/fe/9a58cb6eec633ff6afae150ca53c16f8cc8b65862ccb3d088051efdfceb7/python_socks-2.8.1-py3-none-any.whl")
           (file-name "python_socks-2.8.1-py3-none-any.whl")
           (sha256
            (base32 "0dg0gffmndk385w0z48w7z93sx4lw5dx3g6d4pkn904qqhwjf8r8"))))
   (cons "python-telegram-bot"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/60/7c/ed7d4dd94280bd434173cae9f7a7aedaaab9af128ae4f494423a5687c820/python_telegram_bot-22.8-py3-none-any.whl")
           (file-name "python_telegram_bot-22.8-py3-none-any.whl")
           (sha256
            (base32 "1qah7kkfaxhcbfxi5ivy958rd9wyq64da5z7qiy866vz14c3jds2"))))
   (cons "pytz"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/81/c4/34e93fe5f5429d7570ec1fa436f1986fb1f00c3e0f43a589fe2bbcd22c3f/pytz-2025.2-py2.py3-none-any.whl")
           (file-name "pytz-2025.2-py2.py3-none-any.whl")
           (sha256
            (base32 "001gxkq46b96nzhdwymxzgvcng4g90snyjwgxck4ri6qdllpdpsx"))))
   (cons "pyyaml"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/71/60/917329f640924b18ff085ab889a11c763e0b573da888e8404ff486657602/pyyaml-6.0.3-cp311-cp311-manylinux2014_x86_64.manylinux_2_17_x86_64.manylinux_2_28_x86_64.whl")
           (file-name "pyyaml-6.0.3-cp311-cp311-manylinux2014_x86_64.manylinux_2_17_x86_64.manylinux_2_28_x86_64.whl")
           (sha256
            (base32 "07gk2821a6mf9722dcf02pracnkwr11w8cm6r3x29052qmj0ifxq"))))
   (cons "qdrant-client"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/d6/10/c437bd2ac41ef30d3019063e6ce537dc111e9214473b337ee88f7fa6359a/qdrant_client-1.18.0-py3-none-any.whl")
           (file-name "qdrant_client-1.18.0-py3-none-any.whl")
           (sha256
            (base32 "1karyrs2c5zwjg0m62qfc2r94ycd6zhhgc385any63j2ib7shfh9"))))
   (cons "qrcode"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/24/79/aaf0c1c7214f2632badb2771d770b1500d3d7cbdf2590ae62e721ec50584/qrcode-7.4.2-py3-none-any.whl")
           (file-name "qrcode-7.4.2-py3-none-any.whl")
           (sha256
            (base32 "0fk406fwbsl24650jqaa1gq0xs4kj3inh46hypp2vjwv09xcl7aq"))))
   (cons "referencing"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/2c/58/ca301544e1fa93ed4f80d724bf5b194f6e4b945841c5bfd555878eea9fcb/referencing-0.37.0-py3-none-any.whl")
           (file-name "referencing-0.37.0-py3-none-any.whl")
           (sha256
            (base32 "0c92d73yqnl26l1wn7a6dvvlmnaasf8nhwb1jc3cja4nz6ljj4rq"))))
   (cons "requests"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/56/5d/c814546c2333ceea4ba42262d8c4d55763003e767fa169adc693bd524478/requests-2.33.0-py3-none-any.whl")
           (file-name "requests-2.33.0-py3-none-any.whl")
           (sha256
            (base32 "16z6rr47vrnd7l9ypmrkz75b9iyfrq8fhra8w92m467sara6691k"))))
   (cons "requests-oauthlib"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/3b/5d/63d4ae3b9daea098d5d6f5da83984853c1bbacd5dc826764b249fe119d24/requests_oauthlib-2.0.0-py2.py3-none-any.whl")
           (file-name "requests_oauthlib-2.0.0-py2.py3-none-any.whl")
           (sha256
            (base32 "0dlv4vk2gx9dhlaxx73l4b7yr3bnz7g4nh4chsq7kdr60k2abn3x"))))
   (cons "requests-toolbelt"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/3f/51/d4db610ef29373b879047326cbf6fa98b6c1969d6f6dc423279de2b1be2c/requests_toolbelt-1.0.0-py2.py3-none-any.whl")
           (file-name "requests_toolbelt-1.0.0-py2.py3-none-any.whl")
           (sha256
            (base32 "01mxyv66hm8sv7gr56vvcfq2n9wxcdjhysbffbsgq90abxkdvkyc"))))
   (cons "rich"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/14/25/b208c5683343959b670dc001595f2f3737e051da617f66c31f7c4fa93abc/rich-14.3.3-py3-none-any.whl")
           (file-name "rich-14.3.3-py3-none-any.whl")
           (sha256
            (base32 "0b9nsnw2sqcpad86njqdx98bjqlmhpncvcjj7dyzm6k1z30k2d3r"))))
   (cons "rpds-py"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/f8/1e/372195d326549bb51f0ba0f2ecb9874579906b97e08880e7a65c3bef1a99/rpds_py-0.30.0-cp311-cp311-manylinux_2_17_x86_64.manylinux2014_x86_64.whl")
           (file-name "rpds_py-0.30.0-cp311-cp311-manylinux_2_17_x86_64.manylinux2014_x86_64.whl")
           (sha256
            (base32 "12dg0caiwbxzllbc5c356w9k6p9zlf9nnrmv8im5012523rmkx9k"))))
   (cons "ruamel-yaml"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/af/fe/b6045c782f1fd1ae317d2a6ca1884857ce5c20f59befe6ab25a8603c43a7/ruamel_yaml-0.18.17-py3-none-any.whl")
           (file-name "ruamel_yaml-0.18.17-py3-none-any.whl")
           (sha256
            (base32 "178b55g2ks1dv211nvwwrgq5p7c640c543dn4kwzsgkr7vmsk2ww"))))
   (cons "ruamel-yaml-clib"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/aa/ed/3fb20a1a96b8dc645d88c4072df481fe06e0289e4d528ebbdcc044ebc8b3/ruamel_yaml_clib-0.2.15-cp311-cp311-manylinux2014_x86_64.manylinux_2_17_x86_64.manylinux_2_28_x86_64.whl")
           (file-name "ruamel_yaml_clib-0.2.15-cp311-cp311-manylinux2014_x86_64.manylinux_2_17_x86_64.manylinux_2_28_x86_64.whl")
           (sha256
            (base32 "0gq5fp66l4sn1314wba55j1mb412wkhxmk63z23gl5apfvf3azb1"))))
   (cons "s3transfer"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/fc/51/727abb13f44c1fcf6d145979e1535a35794db0f6e450a0cb46aa24732fe2/s3transfer-0.16.0-py3-none-any.whl")
           (file-name "s3transfer-0.16.0-py3-none-any.whl")
           (sha256
            (base32 "1zmjyg9ilj09pyjl9y2n5kflgybz88zjnmy1in3f62fmzrk5vqhq"))))
   (cons "scikit-learn"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/8d/da/4810a28e473185429e45a57eebcc91fc991b33d889cc0676063e671db03d/scikit_learn-1.9.0-cp311-cp311-manylinux_2_27_x86_64.manylinux_2_28_x86_64.whl")
           (file-name "scikit_learn-1.9.0-cp311-cp311-manylinux_2_27_x86_64.manylinux_2_28_x86_64.whl")
           (sha256
            (base32 "1f6fwplps9xx1klhx7haqjcfp3s7wpw2fnki8yl0s2b4c5im9qpp"))))
   (cons "scipy"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/09/7d/af933f0f6e0767995b4e2d705a0665e454d1c19402aa7e895de3951ebb04/scipy-1.17.1-cp311-cp311-manylinux_2_27_x86_64.manylinux_2_28_x86_64.whl")
           (file-name "scipy-1.17.1-cp311-cp311-manylinux_2_27_x86_64.manylinux_2_28_x86_64.whl")
           (sha256
            (base32 "1r1dv4islamwswwibgggg24jl68ikd7fdpwy05cjar7a7cgqvbs3"))))
   (cons "sentencepiece"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/06/5f/9117bf854aef817ad0d0ee9310eed0308a7e529e7eaf2e80ad9cd281ef82/sentencepiece-0.2.2-cp311-cp311-manylinux_2_27_x86_64.manylinux_2_28_x86_64.whl")
           (file-name "sentencepiece-0.2.2-cp311-cp311-manylinux_2_27_x86_64.manylinux_2_28_x86_64.whl")
           (sha256
            (base32 "01s1wrjnfywn3s2b069297mda88icg96wc76dxw360q15wpvj5hl"))))
   (cons "setuptools"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/5d/40/e1e72872c6354b306daef1703549e8e83b4d43cfea356311bf722a043752/setuptools-83.0.0-py3-none-any.whl")
           (file-name "setuptools-83.0.0-py3-none-any.whl")
           (sha256
            (base32 "1cxb36x9vw3kw76k69zd45hbzg67ihbkkfrnfgf19x121wv3rci9"))))
   (cons "shellingham"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/e0/f9/0595336914c5619e5f28a1fb793285925a8cd4b432c9da0a987836c7f822/shellingham-1.5.4-py2.py3-none-any.whl")
           (file-name "shellingham-1.5.4-py2.py3-none-any.whl")
           (sha256
            (base32 "11l69qr2049dhm093j2n1bwqmgxjcmd4fh0h93vic9np5y7zzkvy"))))
   (cons "sherpa-onnx"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/e0/ac/88b4e1ce614ddebe2484e95cad4b19d7db24f3b489d04f9877667cb48ccb/sherpa_onnx-1.13.4-cp311-cp311-manylinux2014_x86_64.manylinux_2_17_x86_64.whl")
           (file-name "sherpa_onnx-1.13.4-cp311-cp311-manylinux2014_x86_64.manylinux_2_17_x86_64.whl")
           (sha256
            (base32 "048176zkrcqfhddv3mkvzgj6ff5y0k399p0j3c70hc6pk1dkiz7v"))))
   (cons "sherpa-onnx-core"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/41/be/38c57721d71ee74d984b1ca21720a8ca8477d6d341026af24ff658866ef9/sherpa_onnx_core-1.13.4-py3-none-manylinux2014_x86_64.whl")
           (file-name "sherpa_onnx_core-1.13.4-py3-none-manylinux2014_x86_64.whl")
           (sha256
            (base32 "0amfwsg13hz5hx4rnfdgb6w105w2zkb73q6lb5wzvcwhxrna0yin"))))
   (cons "six"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/b7/ce/149a00dd41f10bc29e5921b496af8b574d8413afcd5e30dfa0ed46c2cc5e/six-1.17.0-py2.py3-none-any.whl")
           (file-name "six-1.17.0-py2.py3-none-any.whl")
           (sha256
            (base32 "0x1jdic712dylbnyiqdj4xyxrlx0gaacynmbmkfiym4hxn8z68a7"))))
   (cons "slack-bolt"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/2f/ee/1a7a286cf98fa3f4eeffaabc090e82f58f058ab4812aa1d7421d92c2637a/slack_bolt-1.30.0-py2.py3-none-any.whl")
           (file-name "slack_bolt-1.30.0-py2.py3-none-any.whl")
           (sha256
            (base32 "1i32w80xim9i5wzhih3jdf5ipp84cgnxsc9abqyx45lmwx3brxc1"))))
   (cons "slack-sdk"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/ab/fc/67352b742fc6fa520a550581b0284f5757e4e31a32327c2a00276747fd30/slack_sdk-3.44.1-py2.py3-none-any.whl")
           (file-name "slack_sdk-3.44.1-py2.py3-none-any.whl")
           (sha256
            (base32 "1cj2giniip8c78n4fibhbdj8md01cdl9vjamr75gkv1zpq7hmwnn"))))
   (cons "sniffio"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/e9/44/75a9c9421471a6c4805dbf2356f7c181a29c1879239abab1ea2cc8f38b40/sniffio-1.3.1-py3-none-any.whl")
           (file-name "sniffio-1.3.1-py3-none-any.whl")
           (sha256
            (base32 "18i50l85yppn9w1ily8m342yd577h0bg8y24hkfzvq7is4ca8v9g"))))
   (cons "snowballstemmer"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/4c/07/2ebca9b11fb9be7340a818d8d6f63feaebb146be2c4afbd6061701d6df6e/snowballstemmer-3.1.1-py3-none-any.whl")
           (file-name "snowballstemmer-3.1.1-py3-none-any.whl")
           (sha256
            (base32 "0ljp3zvkkdjm6zzwki8z5gwxayl2qg73x7g5vsfa07blg2hpy83y"))))
   (cons "socksio"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/37/c3/6eeb6034408dac0fa653d126c9204ade96b819c936e136c5e8a6897eee9c/socksio-1.0.0-py3-none-any.whl")
           (file-name "socksio-1.0.0-py3-none-any.whl")
           (sha256
            (base32 "1wxirdfiqxh8imh3rcrayfd613zlrjw78vgh2rxqskmkz4aizp4m"))))
   (cons "sounddevice"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/1e/0a/478e441fd049002cf308520c0d62dd8333e7c6cc8d997f0dda07b9fbcc46/sounddevice-0.5.5-py3-none-any.whl")
           (file-name "sounddevice-0.5.5-py3-none-any.whl")
           (sha256
            (base32 "07sv82ka68dr0si82gnxpjhja76rv2n5r90nmljrvx07q7v9kzrh"))))
   (cons "sqlalchemy"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/90/54/44012d32fd77d991256d2ff793ba3807c51d40cb27a85b4796224f6744df/sqlalchemy-2.0.51-cp311-cp311-manylinux2014_x86_64.manylinux_2_17_x86_64.manylinux_2_28_x86_64.whl")
           (file-name "sqlalchemy-2.0.51-cp311-cp311-manylinux2014_x86_64.manylinux_2_17_x86_64.manylinux_2_28_x86_64.whl")
           (sha256
            (base32 "1g9dl4f48z2s34k1lvvn42przpif5h8wc771l58nj3x83372hrs3"))))
   (cons "sse-starlette"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/61/28/8cb142d3fe80c4a2d8af54ca0b003f47ce0ba920974e7990fa6e016402d1/sse_starlette-3.3.2-py3-none-any.whl")
           (file-name "sse_starlette-3.3.2-py3-none-any.whl")
           (sha256
            (base32 "0qmqzfncky5nzk51fw7m8d34jx4vd0kjzbr6cwih3ii5skda6gjw"))))
   (cons "starlette"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/ec/bb/2799cc2ede3ed41131f8975621e7213dfc7ef4acbbaadfa440f32500c370/starlette-1.3.1-py3-none-any.whl")
           (file-name "starlette-1.3.1-py3-none-any.whl")
           (sha256
            (base32 "1ihl6yjib9hnjlv1s9ix901pvx62rqkdcyyz89mg5hy326p2ldy7"))))
   (cons "supermemory"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/4c/be/caf3b7d4b21851c7d8ddec7661f22089d95bb55bc7b4bdd79dea1001604e/supermemory-3.50.0-py3-none-any.whl")
           (file-name "supermemory-3.50.0-py3-none-any.whl")
           (sha256
            (base32 "1412rbs063s4jgnq96rk9nihir2f2sqaw50laqyj3v1l54advqpn"))))
   (cons "synchronicity"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/3f/b9/71153db12f4ad029cfe9b7fbf9792ef3fc9ade4485d31a13470b52954e62/synchronicity-0.11.1-py3-none-any.whl")
           (file-name "synchronicity-0.11.1-py3-none-any.whl")
           (sha256
            (base32 "1clxl1glpjsjhh7wz943wkni0hx08w52jgadxasjz1cvidzrr5ak"))))
   (cons "tabulate"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/40/44/4a5f08c96eb108af5cb50b41f76142f0afa346dfa99d5296fe7202a11854/tabulate-0.9.0-py3-none-any.whl")
           (file-name "tabulate-0.9.0-py3-none-any.whl")
           (sha256
            (base32 "13wls6g5n09hi0z83wqlpb6nspzzihlqavs8c4339s92vxwa8k02"))))
   (cons "tenacity"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/d7/c1/eb8f9debc45d3b7918a32ab756658a0904732f75e555402972246b0b8e71/tenacity-9.1.4-py3-none-any.whl")
           (file-name "tenacity-9.1.4-py3-none-any.whl")
           (sha256
            (base32 "0mcxga39nr703a4gln9nna4ss1kawwlyazajqql5y20rr5ha75b0"))))
   (cons "termcolor"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/33/d1/8bb87d21e9aeb323cc03034f5eaf2c8f69841e40e4853c2627edf8111ed3/termcolor-3.3.0-py3-none-any.whl")
           (file-name "termcolor-3.3.0-py3-none-any.whl")
           (sha256
            (base32 "19a3dz1ck4l1n35lqvvjkwdg5dgrqb732ymwyjxypa7hvbx2wr6g"))))
   (cons "tflite-runtime"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/8f/a6/02d68cb62cd221589a0ff055073251d883936237c9c990e34a1d7cecd06f/tflite_runtime-2.14.0-cp311-cp311-manylinux2014_x86_64.whl")
           (file-name "tflite_runtime-2.14.0-cp311-cp311-manylinux2014_x86_64.whl")
           (sha256
            (base32 "0k8fm4vk4ah4vkqf06zzkf5qibcz8gakvpalisk2jwz5wx9bfnhr"))))
   (cons "threadpoolctl"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/32/d5/f9a850d79b0851d1d4ef6456097579a9005b31fea68726a4ae5f2d82ddd9/threadpoolctl-3.6.0-py3-none-any.whl")
           (file-name "threadpoolctl-3.6.0-py3-none-any.whl")
           (sha256
            (base32 "1yx7qh9rzay3inj3w237i68hnj6qxsjl77h3200m0a19bbyvi823"))))
   (cons "tokenizers"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/2e/76/932be4b50ef6ccedf9d3c6639b056a967a86258c6d9200643f01269211ca/tokenizers-0.22.2-cp39-abi3-manylinux_2_17_x86_64.manylinux2014_x86_64.whl")
           (file-name "tokenizers-0.22.2-cp39-abi3-manylinux_2_17_x86_64.manylinux2014_x86_64.whl")
           (sha256
            (base32 "0rrcszl91qiyksc7235qgcjyxf4b8fahsfl78d0v4361ikyck71n"))))
   (cons "toml"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/44/6f/7120676b6d73228c96e17f1f794d8ab046fc910d781c8d151120c3f1569e/toml-0.10.2-py2.py3-none-any.whl")
           (file-name "toml-0.10.2-py2.py3-none-any.whl")
           (sha256
            (base32 "16sgpg57kxx5jh467d9qwc2hwshfvdbl0xkafdp3qspvbfp46qc0"))))
   (cons "tornado"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/6e/de/f2e733f386b85962d1b1dc82cd63d169b5b4580062b35397eac9244a41fe/tornado-6.5.8-cp39-abi3-manylinux1_x86_64.manylinux_2_28_x86_64.manylinux_2_5_x86_64.whl")
           (file-name "tornado-6.5.8-cp39-abi3-manylinux1_x86_64.manylinux_2_28_x86_64.manylinux_2_5_x86_64.whl")
           (sha256
            (base32 "0n3vlid9arv2b096cjiva31d3fy92kxjrnz8w17w2w6ma3s66zal"))))
   (cons "tqdm"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/16/e1/3079a9ff9b8e11b846c6ac5c8b5bfb7ff225eee721825310c91b3b50304f/tqdm-4.67.3-py3-none-any.whl")
           (file-name "tqdm-4.67.3-py3-none-any.whl")
           (sha256
            (base32 "1gr6d0h47wp57dnngjazr0ks2wbpnqjhpn293hl6500lb474q7pf"))))
   (cons "truststore"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/19/97/56608b2249fe206a67cd573bc93cd9896e1efb9e98bce9c163bcdc704b88/truststore-0.10.4-py3-none-any.whl")
           (file-name "truststore-0.10.4-py3-none-any.whl")
           (sha256
            (base32 "10frc4rvbc4wx1cxnsk6n6r5gavg3za456wmn7ilspxv3k7sxbmd"))))
   (cons "typer"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/4a/91/48db081e7a63bb37284f9fbcefda7c44c277b18b0e13fbc36ea2335b71e6/typer-0.24.1-py3-none-any.whl")
           (file-name "typer-0.24.1-py3-none-any.whl")
           (sha256
            (base32 "17jcm2d4xw11p88nclqnqay6wh9iy1lbrnpzp75b9gvqwl61yb0i"))))
   (cons "types-certifi"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/b5/63/2463d89481e811f007b0e1cd0a91e52e141b47f9de724d20db7b861dcfec/types_certifi-2021.10.8.3-py3-none-any.whl")
           (file-name "types_certifi-2021.10.8.3-py3-none-any.whl")
           (sha256
            (base32 "12p8fr0zadysygfy8cpgn1xp1d2hwq8d8hsriv3zfwczwqjy7ldj"))))
   (cons "types-toml"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/da/a2/d32ab58c0b216912638b140ab2170ee4b8644067c293b170e19fba340ccc/types_toml-0.10.8.20240310-py3-none-any.whl")
           (file-name "types_toml-0.10.8.20240310-py3-none-any.whl")
           (sha256
            (base32 "0pf0mrxdxx9f5w0hr3cd5kri9wxkp86dqw4wgnbjkyi5bmvlfyv2"))))
   (cons "typing-extensions"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/18/67/36e9267722cc04a6b9f15c7f3441c2363321a3ea07da7ae0c0707beb2a9c/typing_extensions-4.15.0-py3-none-any.whl")
           (file-name "typing_extensions-4.15.0-py3-none-any.whl")
           (sha256
            (base32 "0j75qhcc0p627f464gd7kjcirdzcga5zl32a0w4ann2phk31kyph"))))
   (cons "typing-inspection"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/dc/9b/47798a6c91d8bdb567fe2698fe81e0c6b7cb7ef4d13da4114b41d239f65d/typing_inspection-0.4.2-py3-none-any.whl")
           (file-name "typing_inspection-0.4.2-py3-none-any.whl")
           (sha256
            (base32 "1rs52m95pbfbs31ykx2fshs6z8fahx9fsjfj3c7j5319vk5wmlaf"))))
   (cons "tzlocal"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/c2/14/e2a54fabd4f08cd7af1c07030603c3356b74da07f7cc056e600436edfa17/tzlocal-5.3.1-py3-none-any.whl")
           (file-name "tzlocal-5.3.1-py3-none-any.whl")
           (sha256
            (base32 "0pdq3fwqmvxwxj34zrq8aqxnh6sq004bxw9lm3vssisqxz1nc6pb"))))
   (cons "unpaddedbase64"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/4c/a7/563b2d8fb7edc07320bf69ac6a7eedcd7a1a9d663a6bb90a4d9bd2eda5f7/unpaddedbase64-2.1.0-py3-none-any.whl")
           (file-name "unpaddedbase64-2.1.0-py3-none-any.whl")
           (sha256
            (base32 "1imis3dxyxcdfdgifdkzdxk1xxfz20iqvkghsqn5s5rhkh9gypj8"))))
   (cons "uritemplate"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/a9/99/3ae339466c9183ea5b8ae87b34c0b897eda475d2aec2307cae60e5cd4f29/uritemplate-4.2.0-py3-none-any.whl")
           (file-name "uritemplate-4.2.0-py3-none-any.whl")
           (sha256
            (base32 "11m6p2ypjf2kplda4qk65mfzqbg844w0v6hgwq1app2f3jx028ln"))))
   (cons "urllib3"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/7f/3e/5db95bcf282c52709639744ca2a8b149baccf648e39c8cc87553df9eae0c/urllib3-2.7.0-py3-none-any.whl")
           (file-name "urllib3-2.7.0-py3-none-any.whl")
           (sha256
            (base32 "15v84zvqw9yy7rarmjhqpir08dpiqsxp8xp3rhqrbkmipcgcid4z"))))
   (cons "uvicorn"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/83/e4/d04a086285c20886c0daad0e026f250869201013d18f81d9ff5eada73a88/uvicorn-0.41.0-py3-none-any.whl")
           (file-name "uvicorn-0.41.0-py3-none-any.whl")
           (sha256
            (base32 "11w113g3js7jnfpcdmnzzf2jmcxwwgnhfh0d32g4p81n5hfmpqr9"))))
   (cons "uvloop"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/74/4f/256aca690709e9b008b7108bc85fba619a2bc37c6d80743d18abad16ee09/uvloop-0.22.1-cp311-cp311-manylinux2014_x86_64.manylinux_2_17_x86_64.manylinux_2_28_x86_64.whl")
           (file-name "uvloop-0.22.1-cp311-cp311-manylinux2014_x86_64.manylinux_2_17_x86_64.manylinux_2_28_x86_64.whl")
           (sha256
            (base32 "00ppwhh3aglfs825myxrpghsnghb65kw6lwcrfbj3n2zwvxd38jn"))))
   (cons "vercel"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/77/40/836f9b42b0c1bcf371f26a9eb571e4bc47269404ac61165dd79a4a3c28fd/vercel-0.7.2-py3-none-any.whl")
           (file-name "vercel-0.7.2-py3-none-any.whl")
           (sha256
            (base32 "0rhh22991yhgw5998bddpmqyqn0kkwy3sinn5n70i7d1ajrvgspw"))))
   (cons "vercel-cache"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/70/94/349467bc8b9388763ce17bd4393db239719ea5f89d06ea56f814397715fa/vercel_cache-0.7.1-py3-none-any.whl")
           (file-name "vercel_cache-0.7.1-py3-none-any.whl")
           (sha256
            (base32 "1jbgz5k9maw4jimkvfjxps9mpll18miwk6ck0vic55z6dgbhzvy0"))))
   (cons "vercel-headers"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/28/b8/5484e7ecf876c031831623efc547edcf94e2e33db4251d17c2d117c18cb0/vercel_headers-0.7.1-py3-none-any.whl")
           (file-name "vercel_headers-0.7.1-py3-none-any.whl")
           (sha256
            (base32 "1g3sqx0x6v80yhj266gvaqa2a9g131hms9lknrsrgwgxmw5mzxkf"))))
   (cons "vercel-internal-telemetry"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/91/e7/9fb15e1be9a7c3384948fb09285a54f56f2e4d7aeff41758310b8686d89d/vercel_internal_telemetry-0.7.1-py3-none-any.whl")
           (file-name "vercel_internal_telemetry-0.7.1-py3-none-any.whl")
           (sha256
            (base32 "0jf2biypc3ldb5540zsgsnnpyvg32ccd5av8wcd2x25sj6zjxvi8"))))
   (cons "vercel-oidc"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/3c/bc/d62d569e508eb48131d001a49b1b62a98c1fa84217e845106fc7c63b88c6/vercel_oidc-0.7.1-py3-none-any.whl")
           (file-name "vercel_oidc-0.7.1-py3-none-any.whl")
           (sha256
            (base32 "0g3kcpvp9ypgmy5c11mvygqbixf4lq30j6f0s8zgpwns04mvi7yv"))))
   (cons "watchfiles"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/af/b9/a419292f05e302dea372fa7e6fda5178a92998411f8581b9830d28fb9edb/watchfiles-1.1.1-cp311-cp311-manylinux_2_17_x86_64.manylinux2014_x86_64.whl")
           (file-name "watchfiles-1.1.1-cp311-cp311-manylinux_2_17_x86_64.manylinux2014_x86_64.whl")
           (sha256
            (base32 "01i6pgm9ahdr5czbwhp58r95b1j4f1aasy0b278w7rl33a3d1gxf"))))
   (cons "wcwidth"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/68/5a/199c59e0a824a3db2b89c5d2dade7ab5f9624dbf6448dc291b46d5ec94d3/wcwidth-0.6.0-py3-none-any.whl")
           (file-name "wcwidth-0.6.0-py3-none-any.whl")
           (sha256
            (base32 "1bdxzxw19nwc11w3s6vkmpzn8qpvyij4gia6w7w1acsm1d8iwfhs"))))
   (cons "websocket-client"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/34/db/b10e48aa8fff7407e67470363eac595018441cf32d5e1001567a7aeba5d2/websocket_client-1.9.0-py3-none-any.whl")
           (file-name "websocket_client-1.9.0-py3-none-any.whl")
           (sha256
            (base32 "1vy33wffxvi9llq24nlygfsd60xabz621vgnzcg5kvrpa218l95g"))))
   (cons "websockets"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/93/1f/5d6dbf551766308f6f50f8baf8e9860be6182911e8106da7a7f73785f4c4/websockets-15.0.1-cp311-cp311-manylinux_2_5_x86_64.manylinux1_x86_64.manylinux_2_17_x86_64.manylinux2014_x86_64.whl")
           (file-name "websockets-15.0.1-cp311-cp311-manylinux_2_5_x86_64.manylinux1_x86_64.manylinux_2_17_x86_64.manylinux2014_x86_64.whl")
           (sha256
            (base32 "04rljmdgi30m2nmsi4122x4c3p71r8yn1yk0jwhkygjvg5y35n4d"))))
   (cons "wrapt"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/5d/8f/a32a99fc03e4b37e31b57cb9cefc65050ea08147a8ce12f288616b05ef54/wrapt-1.17.3-cp311-cp311-manylinux1_x86_64.manylinux_2_28_x86_64.manylinux_2_5_x86_64.whl")
           (file-name "wrapt-1.17.3-cp311-cp311-manylinux1_x86_64.manylinux_2_28_x86_64.manylinux_2_5_x86_64.whl")
           (sha256
            (base32 "049kxmq2jn0zyjyp4i2llw19fipmclqvzk7xm21qzrmnv2m8ha5k"))))
   (cons "yarl"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/46/00/71b90ed48e895667ecfb1eaab27c1523ee2fa217433ed77a73b13205ca4b/yarl-1.22.0-cp311-cp311-manylinux2014_x86_64.manylinux_2_17_x86_64.manylinux_2_28_x86_64.whl")
           (file-name "yarl-1.22.0-cp311-cp311-manylinux2014_x86_64.manylinux_2_17_x86_64.manylinux_2_28_x86_64.whl")
           (sha256
            (base32 "0gb8wqh49zqmigk56zcv6x9kkxdbam3r73pgk1xg8p7gibkscljc"))))
   (cons "youtube-transcript-api"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/be/95/129ea37efd6cd6ed00f62baae6543345c677810b8a3bf0026756e1d3cf3c/youtube_transcript_api-1.2.4-py3-none-any.whl")
           (file-name "youtube_transcript_api-1.2.4-py3-none-any.whl")
           (sha256
            (base32 "1zs3pjkwig8mc14x88cc7pxlh55rh0bl6xxcxpswm9bd6mcqg1q3"))))
   (cons "zipp"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/2e/54/647ade08bf0db230bfea292f893923872fd20be6ac6f53b2b936ba839d75/zipp-3.23.0-py3-none-any.whl")
           (file-name "zipp-3.23.0-py3-none-any.whl")
           (sha256
            (base32 "0kmishxksv9559qyklb08s46mzddq0vc6d0xrvsk5m2y27b545h7"))))))

;;; These five locked distributions publish no wheels.  Their setup.py files
;;; use setuptools and find_packages, with no native extensions or extra
;;; build backend; build/install them with the same Python 3.11 runtime.
(define %hermes-python-sources
  (list
   (cons "alibabacloud-credentials-api"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/a0/87/1d7019d23891897cb076b2f7e3c81ab3c2ba91de3bb067196f675d60d34c/alibabacloud-credentials-api-1.0.0.tar.gz")
           (file-name "alibabacloud-credentials-api-1.0.0.tar.gz")
           (sha256
            (base32 "0byxjxx8kr4vgny2rbvryby2p49iih4g9a0lfa6j3w04v4w00d4c"))))
   (cons "alibabacloud-endpoint-util"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/92/7d/8cc92a95c920e344835b005af6ea45a0db98763ad6ad19299d26892e6c8d/alibabacloud_endpoint_util-0.0.4.tar.gz")
           (file-name "alibabacloud_endpoint_util-0.0.4.tar.gz")
           (sha256
            (base32 "145zkdrqldcgwhhcmsfnzj4r2kql3c8k7k8n4bfdas41vn6yp4x5"))))
   (cons "alibabacloud-gateway-dingtalk"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/d2/40/751d8bdf133d7fcf053f10c98e8e506810e7bee06458a02eaaa14d30ac26/alibabacloud_gateway_dingtalk-1.0.2.tar.gz")
           (file-name "alibabacloud_gateway_dingtalk-1.0.2.tar.gz")
           (sha256
            (base32 "005krr8c5z2pkd260q3img7bzh0rvnfqkc7h2d4kkq0i3l5qpsmc"))))
   (cons "alibabacloud-gateway-spi"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/ab/98/d7111245f17935bf72ee9bea60bbbeff2bc42cdfe24d2544db52bc517e1a/alibabacloud_gateway_spi-0.0.3.tar.gz")
           (file-name "alibabacloud_gateway_spi-0.0.3.tar.gz")
           (sha256
            (base32 "12rv49450g34aqzjd824kdp7g2ikk1drid6nzcapky657wxcbl8h"))))
   (cons "alibabacloud-tea"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/9a/7d/b22cb9a0d4f396ee0f3f9d7f26b76b9ed93d4101add7867a2c87ed2534f5/alibabacloud-tea-0.4.3.tar.gz")
           (file-name "alibabacloud-tea-0.4.3.tar.gz")
           (sha256
            (base32 "0jjh32286rbpsl3hg2m1r6gb6fa3832xacmnvvhynhwdmb85707c"))))))

;;; Full upstream license terms and missing attribution notices.  Installed
;;; unchanged under share/doc/hermes-agent/third-party, together with any
;;; corresponding source archives required by the bundled native libraries.
(define %hermes-python-notices
  (list
   (cons "license-c5cd488c00dea64e"
         (origin
           (method url-fetch)
           (uri "https://raw.githubusercontent.com/fal-ai/fal/01170088b9e3f3de8a1966cdfd36d700bfc555f7/LICENSE")
           (file-name "LICENSE")
           (sha256
            (base32 "0iacgh8758pq1j4q391i5jgk5pnf69w5ljjdsqalx9ny0264ikf5"))))
   (cons "license-cfc7749b96f63bd3"
         (origin
           (method url-fetch)
           (uri "https://raw.githubusercontent.com/google/flatbuffers/7e163021e59cca4f8e1e35a7c828b5c6b7915953/LICENSE")
           (file-name "LICENSE")
           (sha256
            (base32 "0c1xaay1fd00xgri0z447q2i8s3mpxqw9da27hfd6fznjsdp9iyg"))))
   (cons "license-c71d239df91726fc"
         (origin
           (method url-fetch)
           (uri "https://raw.githubusercontent.com/open-telemetry/opentelemetry-python-contrib/b13d3500174be305f5962b8b2d139b535cb46e3a/LICENSE")
           (file-name "LICENSE")
           (sha256
            (base32 "1d0abprxr1wy46bggcijf9i20n66iqqjvdvfki8zq9hpz6fj67f7"))))
   (cons "license-b41b78f562a2e65b"
         (origin
           (method url-fetch)
           (uri "https://raw.githubusercontent.com/python/typeshed/95128e61ec82c2ca8ec32d6c03bd9dad9ab68e65/LICENSE")
           (file-name "LICENSE")
           (sha256
            (base32 "1q1gwbs0r4dc02b50r9hyx75shvgbwrm8hxlr9smprm2cbsph6xl"))))
   (cons "license-295f8538c94ae5c3"
         (origin
           (method url-fetch)
           (uri "https://raw.githubusercontent.com/python/typeshed/f94bbfbcc4c3b2b289425ea793beda0822e702f8/LICENSE")
           (file-name "LICENSE")
           (sha256
            (base32 "1gnabq6v8qg0f7jdx3bag1manbc53kzprkq16c2c7raar4w8apr9"))))
   (cons "license-c2cfccb812fe4821"
         (origin
           (method url-fetch)
           (uri "https://raw.githubusercontent.com/microsoft/teams.py/eaec265930e8770b2f177a14733d490bf10231ac/LICENSE")
           (file-name "LICENSE")
           (sha256
            (base32 "10skw6mabdlimi3nq9j84xmim6d9qpgrfighm00j2j7y2awcrky2"))))
   (cons "license-aefc84881757b27b"
         (origin
           (method url-fetch)
           (uri "https://raw.githubusercontent.com/aliyun/tea-util/245d3de02f02cbe53aeec748e4c54711af747ff0/LICENSE")
           (file-name "LICENSE")
           (sha256
            (base32 "0rskvr959lhxq5dzh5k8jlqdddvpx0ixp639xm17pcjp2y489z5f"))))
   (cons "license-975311f367d9ce9b"
         (origin
           (method url-fetch)
           (uri "https://raw.githubusercontent.com/exa-labs/exa-py/1194c159a40b7322699ef6701605b1b85ee766a8/LICENSE")
           (file-name "LICENSE")
           (sha256
            (base32 "0d784r8ysv3b4pdnf14c5ncs7zrq7hml8b41mkvrpknrczri2lwp"))))
   (cons "license-8486a10c4393cee1"
         (origin
           (method url-fetch)
           (uri "https://raw.githubusercontent.com/plastic-labs/honcho/63ea82c084ed494f2276cc91f42f28a1eb07dd51/LICENSE")
           (file-name "LICENSE")
           (sha256
            (base32 "1vq75zxpvzzg2ha8x4n7dqnj8v1d7gfrsxljag1f3klk8c6a31l4"))))
   (cons "license-3cfc9f01cdeec929"
         (origin
           (method url-fetch)
           (uri "https://raw.githubusercontent.com/python-hyper/uritemplate/e89ada10dd4e9deb8c576f3f0de8a813fbea9c02/LICENSE")
           (file-name "LICENSE")
           (sha256
            (base32 "0v74d6cvv75dphr3a9n40k9pwzm5zxvmdkr8y802kjgfrl0rzz1w"))))
   (cons "license-c03c6bc1445ed428"
         (origin
           (method url-fetch)
           (uri "https://raw.githubusercontent.com/python-hyper/uritemplate/e89ada10dd4e9deb8c576f3f0de8a813fbea9c02/LICENSE.BSD")
           (file-name "LICENSE.BSD")
           (sha256
            (base32 "0dd2rpsrxgizlf3bgbm1dp3a7fp3ip5limiljcyjim2y8k0nng60"))))
   (cons "license-27d4bf4eafa186fb"
         (origin
           (method url-fetch)
           (uri "https://raw.githubusercontent.com/open-telemetry/opentelemetry-python-contrib/b13d3500174be305f5962b8b2d139b535cb46e3a/LICENSE.BSD3")
           (file-name "LICENSE.BSD3")
           (sha256
            (base32 "194g72c2s9vqqwfzi6p4j46pj6xa5cfz35jx1mggp1m1mx7bzm17"))))
   (cons "attribution-alibabacloud-credentials-0"
         (origin
           (method url-fetch)
           (uri "https://raw.githubusercontent.com/aliyun/credentials-python/0bfdeb47b1a861e3cc25134eee76a444d58aece2/README.md")
           (file-name "README.md")
           (sha256
            (base32 "1w9cp2alwsh1vwk0x6mpmwicd8f7lqi3gzw8ksl9dbgd1w7i2w3k"))))
   (cons "attribution-alibabacloud-openapi-util-1"
         (origin
           (method url-fetch)
           (uri "https://raw.githubusercontent.com/aliyun/darabonba-openapi-util/ceff1ee93673d0cdebb1c4c0ce6e5f787ed6ae0f/README.md")
           (file-name "README.md")
           (sha256
            (base32 "1chbl0dyyh6yrzg2da3rg6bp1dfydl4g1yb09prbzhxw4021nrh7"))))
   (cons "attribution-alibabacloud-openapi-util-2"
         (origin
           (method url-fetch)
           (uri "https://raw.githubusercontent.com/aliyun/darabonba-openapi-util/ceff1ee93673d0cdebb1c4c0ce6e5f787ed6ae0f/python/README.md")
           (file-name "README.md")
           (sha256
            (base32 "1d78slmg01bpn280p55gpbnics9jzlsbii1qyx3vj6wlmiaqyzgf"))))
   (cons "attribution-alibabacloud-tea-openapi-3"
         (origin
           (method url-fetch)
           (uri "https://raw.githubusercontent.com/aliyun/darabonba-openapi/fbdb58a0df8f657f486e64bd416dd213f84fdffc/README.md")
           (file-name "README.md")
           (sha256
            (base32 "1ryapsdi9wgwc37ykn9yac3wqw8w37kjwpn0mbjx6lac6yf08s98"))))
   (cons "attribution-alibabacloud-tea-openapi-4"
         (origin
           (method url-fetch)
           (uri "https://raw.githubusercontent.com/aliyun/darabonba-openapi/fbdb58a0df8f657f486e64bd416dd213f84fdffc/python/README.md")
           (file-name "README.md")
           (sha256
            (base32 "0xz6q688mc6rfss0bzcpm1inj9l16i6pq9p9zb4fali1sy5jf4v3"))))
   (cons "attribution-alibabacloud-tea-util-5"
         (origin
           (method url-fetch)
           (uri "https://raw.githubusercontent.com/aliyun/tea-util/245d3de02f02cbe53aeec748e4c54711af747ff0/README.md")
           (file-name "README.md")
           (sha256
            (base32 "1ls990dmg9ciqjj46fs7ixwrb6qlqda3hzfis5fldjk2sswhhvhl"))))
   (cons "attribution-alibabacloud-tea-util-6"
         (origin
           (method url-fetch)
           (uri "https://raw.githubusercontent.com/aliyun/tea-util/245d3de02f02cbe53aeec748e4c54711af747ff0/python/README.md")
           (file-name "README.md")
           (sha256
            (base32 "0ksh1zm1nyrvxapwdh04wh7hy5xfkgwms87k9w89yvvzh0n3m2vh"))))
   (cons "attribution-darabonba-core-7"
         (origin
           (method url-fetch)
           (uri "https://raw.githubusercontent.com/aliyun/tea-python/93719e03b72ef0bcdcce0acbed6fd3ef4c5e2ae7/README.md")
           (file-name "README.md")
           (sha256
            (base32 "0zaylrl6j5nmfn6gjjzlsy42qn53gfsl080i0czlg7fhpra31dgr"))))
   (cons "attribution-alibabacloud-endpoint-util-8"
         (origin
           (method url-fetch)
           (uri "https://raw.githubusercontent.com/aliyun/endpoint-util/fab496bdbfeb1c10bb72bce02935775e0b75693c/README.md")
           (file-name "README.md")
           (sha256
            (base32 "01ryz7y4z32ffw0amh23gi1w94h8j0a4v9prciigfbzax0s4ynm7"))))
   (cons "attribution-alibabacloud-endpoint-util-9"
         (origin
           (method url-fetch)
           (uri "https://raw.githubusercontent.com/aliyun/endpoint-util/fab496bdbfeb1c10bb72bce02935775e0b75693c/python/README.md")
           (file-name "README.md")
           (sha256
            (base32 "1i29lmxaf1vpbc034ab6qj42svp8hj1g70zkzp42b45vwp6sl5vr"))))
   (cons "attribution-alibabacloud-gateway-dingtalk-10"
         (origin
           (method url-fetch)
           (uri "https://raw.githubusercontent.com/aliyun/alibabacloud-gateway/c9edeb88764c552a6c0aced536587478a5f7b14f/README.md")
           (file-name "README.md")
           (sha256
            (base32 "119lc05m6y1ji0fankd1x6xy299kn788f687x62k47ijbjz4bsg7"))))
   (cons "attribution-alibabacloud-gateway-spi-11"
         (origin
           (method url-fetch)
           (uri "https://raw.githubusercontent.com/aliyun/alibabacloud-gateway/418cee1b0489b5cfc58c7109877b62ed97916c8e/README.md")
           (file-name "README.md")
           (sha256
            (base32 "119lc05m6y1ji0fankd1x6xy299kn788f687x62k47ijbjz4bsg7"))))
   (cons "attribution-alibabacloud-tea-12"
         (origin
           (method url-fetch)
           (uri "https://raw.githubusercontent.com/aliyun/tea-python/0fd2e625eecea8e8c4ca9740086777da59556f14/README.md")
           (file-name "README.md")
           (sha256
            (base32 "03b4h7r82s846ixm37baqg1ixkvgslfvss7qwcyz4vj58ysjhz3j"))))
   (cons "libquadmath-centos-corresponding-source"
         (origin
           (method url-fetch)
           (uri "https://vault.centos.org/7.9.2009/os/Source/SPackages/gcc-4.8.5-44.el7.src.rpm")
           (file-name "gcc-4.8.5-44.el7.src.rpm")
           (sha256
            (base32 "0dmaqzb95a68mrs993lcvn9np7jxgaflmrc3jpinb5dgys2l0b34"))))
   (cons "scipy-gcc-runtime-corresponding-source"
         (origin
           (method url-fetch)
           (uri "https://vault.almalinux.org/8.10/BaseOS/Source/Packages/gcc-8.5.0-26.el8_10.alma.1.src.rpm")
           (file-name "gcc-8.5.0-26.el8_10.alma.1.src.rpm")
           (sha256
            (base32 "17y77dp4h1irp0577jg19kh5j4sygrp62i1i1w1swx8a4r68c489"))))
   (cons "lgpl-2.1-full-terms"
         (origin
           (method url-fetch)
           (uri "https://www.gnu.org/licenses/old-licenses/lgpl-2.1.txt")
           (file-name "lgpl-2.1.txt")
           (sha256
            (base32 "15axap9s8cp66d9k3pz4c475mx84x6fpshghxdw67rg3mbkhzr90"))))
   (cons "openblas-gfortran-centos-corresponding-source"
         (origin
           (method url-fetch)
           (uri "https://vault.centos.org/7.9.2009/os/Source/SPackages/gcc-libraries-8.3.1-2.1.1.el7.src.rpm")
           (file-name "gcc-libraries-8.3.1-2.1.1.el7.src.rpm")
           (sha256
            (base32 "1xcid3zzxnfb6k7ggqamfnq3vdv98zk3h9jw94pfnmjs5qn1sang"))))
   (cons "ctranslate2-54aa79d9fe3c"
         (origin
           (method url-fetch)
           (uri "https://raw.githubusercontent.com/OpenNMT/CTranslate2/226c95d94e660c48b11c62e108886b7ef76d589d/LICENSE")
           (file-name "LICENSE")
           (sha256
            (base32 "1jrfczvkr61n22izskhpxjk0ar37i2g5pnfw2rxfc29wzvcpkajl"))))
   (cons "ctranslate2-9b2019dae760"
         (origin
           (method url-fetch)
           (uri "https://codeload.github.com/google/cpu_features/tar.gz/8a494eb1e158ec2050e5f699a504fbc9b896a43b")
           (file-name "google-8a494eb1e158ec2050e5f699a504fbc9b896a43b.tar.gz")
           (sha256
            (base32 "0bl06p0bhcwcimd9c9ifz3j8iirz4v1saaaik2mk11k0wzd1j84v"))))
   (cons "ctranslate2-9fa1da6be3d2"
         (origin
           (method url-fetch)
           (uri "https://codeload.github.com/NVIDIA/cutlass/tar.gz/bbe579a9e3beb6ea6626d9227ec32d0dae119a49")
           (file-name "NVIDIA-bbe579a9e3beb6ea6626d9227ec32d0dae119a49.tar.gz")
           (sha256
            (base32 "0j4xgzs701jv6a14pj588hj2176mrv5nhmqxh1xj1nfjwdmxm8cz"))))
   (cons "ctranslate2-4530d53b86d4"
         (origin
           (method url-fetch)
           (uri "https://codeload.github.com/gabime/spdlog/tar.gz/76fb40d95455f249bd70824ecfcae7a8f0930fa3")
           (file-name "gabime-76fb40d95455f249bd70824ecfcae7a8f0930fa3.tar.gz")
           (sha256
            (base32 "1dwwjiz2qwv3yv9mhj4lw6l3npfrwx7qyalqp2jjhlnlhqxxac25"))))
   (cons "ctranslate2-940e45a615f6"
         (origin
           (method url-fetch)
           (uri "https://codeload.github.com/NVIDIA/thrust/tar.gz/d997cd37a95b0fa2f1a0cd4697fd1188a842fbc8")
           (file-name "NVIDIA-d997cd37a95b0fa2f1a0cd4697fd1188a842fbc8.tar.gz")
           (sha256
            (base32 "1q3afabjia60460aa6rfkdszamhrvb4n1bmbmpsgk47n2nk4a3ll"))))
   (cons "ctranslate2-dd12452e1ae1"
         (origin
           (method url-fetch)
           (uri "https://raw.githubusercontent.com/oneapi-src/oneDNN/v3.1.1/LICENSE")
           (file-name "LICENSE")
           (sha256
            (base32 "03vx81md56ckkwh2g81nx61nnabmh5fqk98s4y1347p138p4a4nx"))))
   (cons "ctranslate2-9117585dfc6b"
         (origin
           (method url-fetch)
           (uri "https://raw.githubusercontent.com/oneapi-src/oneDNN/v3.1.1/THIRD-PARTY-PROGRAMS")
           (file-name "THIRD-PARTY-PROGRAMS")
           (sha256
            (base32 "13j227yagapwrrnk2s5zjzmq5v46ibr14cq6zkxd0p3bzifmh5wi"))))
   (cons "ctranslate2-8fd38f51f543"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/d3/e7/5f8f78044b421f859f1a9f6aa4cc957c4733bee3e716a1d54b79797f241c/mkl_include-2025.3.0-py2.py3-none-manylinux_2_28_x86_64.whl")
           (file-name "mkl_include-2025.3.0-py2.py3-none-manylinux_2_28_x86_64.whl")
           (sha256
            (base32 "1rhpn1bpgqmvz2gnl3jvmzp7fqlq56aijjj5rwqp1kj3ym8qzlwg"))))
   (cons "ctranslate2-d1cd58f57b23"
         (origin
           (method url-fetch)
           (uri "https://codeload.github.com/oneapi-src/oneDNN/tar.gz/refs/tags/v3.1.1")
           (file-name "oneapi-src-v3.1.1.tar.gz")
           (sha256
            (base32 "1ml2mh7qyw8c8sdpgn7mkj3wn90mqb5llixwm5id6213ggsmikfi"))))
   (cons "ctranslate2-6722d4c310a2-499619a5"
         (origin
           (method url-fetch)
           (uri "https://docs.nvidia.com/cuda/archive/12.8.0/eula/index.html")
           (file-name "index.html")
           (sha256
            (base32 "0b3m0p6drq9m5k71x3mgpb1czqlgchd3gqzdd7c9mv52231x88k7"))))
   (cons "ctranslate2-2e15eba2e130"
         (origin
           (method url-fetch)
           (uri "https://raw.githubusercontent.com/NVIDIA/cub/ed040d585c3237d706973d7ad290bfee40958270/LICENSE.TXT")
           (file-name "LICENSE.TXT")
           (sha256
            (base32 "1csrjzyc202bylgnh93366cwx09prrylqwlikq6yiwrhw6ifn59f"))))
   (cons "ctranslate2-37737b4db911"
         (origin
           (method url-fetch)
           (uri "https://codeload.github.com/OpenNMT/CTranslate2/tar.gz/226c95d94e660c48b11c62e108886b7ef76d589d")
           (file-name "OpenNMT-226c95d94e660c48b11c62e108886b7ef76d589d.tar.gz")
           (sha256
            (base32 "1jvdhzv3bkk0w12nnlzg4hf5ib82d6yqmrhdk3f4ynhip56pnwrp"))))
   (cons "ctranslate2-3972dc9744f6"
         (origin
           (method url-fetch)
           (uri "https://www.gnu.org/licenses/gpl-3.0.txt")
           (file-name "gpl-3.0.txt")
           (sha256
            (base32 "11k9nggwk1mgsrkdwgdjz65avrradxlpdgrdkc7ryjgn8jbxqwir"))))
   (cons "ctranslate2-6722d4c310a2-908254f0"
         (origin
           (method url-fetch)
           (uri "https://docs.nvidia.com/cuda/archive/12.8.1/eula/index.html")
           (file-name "index.html")
           (sha256
            (base32 "0b3m0p6drq9m5k71x3mgpb1czqlgchd3gqzdd7c9mv52231x88k7"))))
   (cons "ctranslate2-7b81f5d2e034"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/6d/b4/ef531295ed33b929c6c5214421eeebe370f1be22536b6956b4aaf18fdbc5/mkl-2025.3.0-py2.py3-none-manylinux_2_28_x86_64.whl")
           (file-name "mkl-2025.3.0-py2.py3-none-manylinux_2_28_x86_64.whl")
           (sha256
            (base32 "0q7nd1jq8bp9dq5rxqvqiac8k22fij3nd1m5ghc7nqrlw39gb0bv"))))
   (cons "ctranslate2-8ceb4b9ee5ad"
         (origin
           (method url-fetch)
           (uri "https://raw.githubusercontent.com/gcc-mirror/gcc/releases/gcc-14.2.0/COPYING3")
           (file-name "COPYING3")
           (sha256
            (base32 "00xrcpmlbif7h36isnhnddxx4fn7j0fmr5qynd3xxvddwng4pswc"))))
   (cons "ctranslate2-9d6b43ce4d8d"
         (origin
           (method url-fetch)
           (uri "https://raw.githubusercontent.com/gcc-mirror/gcc/releases/gcc-14.2.0/COPYING.RUNTIME")
           (file-name "COPYING.RUNTIME")
           (sha256
            (base32 "0x0gr6yiba7n78z1ay2inx1bvn8hga74vd8npxwciq4d9p746swx"))))
   (cons "ctranslate2-8c7efc9fe0ee"
         (origin
           (method url-fetch)
           (uri "https://raw.githubusercontent.com/bshoshany/thread-pool/v3.5.0/LICENSE.txt")
           (file-name "LICENSE.txt")
           (sha256
            (base32 "07mj8jpk1f7ncssnmzx6z27vawqzb9yl7pf8vc7z71pfw2gzqzlc"))))
   (cons "davey-90760006b6e6"
         (origin
           (method url-fetch)
           (uri "https://raw.githubusercontent.com/Snazzah/davey/9ba30823c71e7f58dc1a0be7e8f66b3efffdd39f/LICENSE")
           (file-name "LICENSE")
           (sha256
            (base32 "1yla9vaxamakfq4ddigag535hbp44pp9pqvd8xknmiz6nq300xlh"))))
   (cons "davey-3f3d9e0024b1"
         (origin
           (method url-fetch)
           (uri "https://www.mozilla.org/media/MPL/2.0/index.txt")
           (file-name "index.txt")
           (sha256
            (base32 "014xkdvkpz6py7in8v77g1xbw356nkg8hzvggl31p4mi4h09wg9z"))))
   (cons "davey-d122413f284c"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/aead/aead-0.5.2.crate")
           (file-name "aead-0.5.2.crate")
           (sha256
            (base32 "1c32aviraqag7926xcb9sybdm36v5vh9gnxpn4pxdwjc50zl28ni"))))
   (cons "davey-b169f7a6d474"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/aes/aes-0.8.4.crate")
           (file-name "aes-0.8.4.crate")
           (sha256
            (base32 "1853796anlwp4kqim0s6wm1srl4ib621nm0cl2h3c8klsjkgfsdi"))))
   (cons "davey-831010a0f742"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/aes-gcm/aes-gcm-0.10.3.crate")
           (file-name "aes-gcm-0.10.3.crate")
           (sha256
            (base32 "1lgaqgg1gh9crg435509lqdhajg1m2vgma6f7fdj1qa2yyh10443"))))
   (cons "davey-c08606f8c3cb"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/autocfg/autocfg-1.5.0.crate")
           (file-name "autocfg-1.5.0.crate")
           (sha256
            (base32 "1s77f98id9l4af4alklmzq46f21c980v13z2r1pcxx6bqgw0d1n0"))))
   (cons "davey-4c7f02d4ea65"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/base16ct/base16ct-0.2.0.crate")
           (file-name "base16ct-0.2.0.crate")
           (sha256
            (base32 "1kylrjhdzk7qpknrvlphw8ywdnvvg39dizw9622w3wk5xba04zsc"))))
   (cons "davey-2af50177e190"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/base64ct/base64ct-1.8.3.crate")
           (file-name "base64ct-1.8.3.crate")
           (sha256
            (base32 "01nyyyx84bhwrcc168hn47d8gvz2pzpv3y3lmck7mq4hw5vh3x9a"))))
   (cons "davey-bef38d45163c"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/bitflags/bitflags-1.3.2.crate")
           (file-name "bitflags-1.3.2.crate")
           (sha256
            (base32 "12ki6w8gn1ldq7yz9y680llwk5gmrhrzszaa17g1sbrw2r2qvwxy"))))
   (cons "davey-812e12b5285c"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/bitflags/bitflags-2.10.0.crate")
           (file-name "bitflags-2.10.0.crate")
           (sha256
            (base32 "1lqxwc3625lcjrjm5vygban9v8a6dlxisp1aqylibiaw52si4bl1"))))
   (cons "davey-3078c7629b62"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/block-buffer/block-buffer-0.10.4.crate")
           (file-name "block-buffer-0.10.4.crate")
           (sha256
            (base32 "0w9sa2ypmrsqqvc20nhwr75wbb5cjr4kkyhpjm1z1lv2kdicfy1h"))))
   (cons "davey-5dd9dc738b7a"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/bumpalo/bumpalo-3.19.1.crate")
           (file-name "bumpalo-3.19.1.crate")
           (sha256
            (base32 "044555i277xcinmqs7nnv8n5y4fqfi4l4lp1mp3i30vsidrxrnax"))))
   (cons "davey-9330f8b2ff13"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/cfg-if/cfg-if-1.0.4.crate")
           (file-name "cfg-if-1.0.4.crate")
           (sha256
            (base32 "008q28ajc546z5p2hcwdnckmg0hia7rnx52fni04bwqkzyrghc4k"))))
   (cons "davey-c3613f74bd2e"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/chacha20/chacha20-0.9.1.crate")
           (file-name "chacha20-0.9.1.crate")
           (sha256
            (base32 "0678wipx6kghp71hpzhl2qvx80q7caz3vm8vsvd07b1fpms3yqf3"))))
   (cons "davey-10cd79432192"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/chacha20poly1305/chacha20poly1305-0.10.1.crate")
           (file-name "chacha20poly1305-0.10.1.crate")
           (sha256
            (base32 "0dfwq9ag7x7lnd0znafpcn8h7k4nfr9gkzm0w7sc1lcj451pkk8h"))))
   (cons "davey-773f3b9af644"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/cipher/cipher-0.4.4.crate")
           (file-name "cipher-0.4.4.crate")
           (sha256
            (base32 "1b9x9agg67xq5nq879z66ni4l08m6m3hqcshk37d4is4ysd3ngvp"))))
   (cons "davey-c2459377285a"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/const-oid/const-oid-0.9.6.crate")
           (file-name "const-oid-0.9.6.crate")
           (sha256
            (base32 "1y0jnqaq7p2wvspnx7qj76m7hjcqpz73qzvr9l2p9n2s51vr6if2"))))
   (cons "davey-633458d4ef8c"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/convert_case/convert_case-0.10.0.crate")
           (file-name "convert_case-0.10.0.crate")
           (sha256
            (base32 "1fff1x78mp2c233g68my0ag0zrmjdbym8bfyahjbfy4cxza5hd33"))))
   (cons "davey-bec549bc3a2b"
         (origin
           (method url-fetch)
           (uri "https://codeload.github.com/cryspen/libcrux/tar.gz/8ebe73237378c80b86a953ec8a77bdd3299918e7")
           (file-name "cryspen-8ebe73237378c80b86a953ec8a77bdd3299918e7.tar.gz")
           (sha256
            (base32 "0jfgv7nmnkpa9jgrbhsvja1nw7lsbl64pjfi17ji1q1b7ay4kidy"))))
   (cons "davey-59ed5838eebb"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/cpufeatures/cpufeatures-0.2.17.crate")
           (file-name "cpufeatures-0.2.17.crate")
           (sha256
            (base32 "10023dnnaghhdl70xcds12fsx2b966sxbxjq5sxs49mvxqw5ivar"))))
   (cons "davey-9dd111b7b7f7"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/crossbeam-deque/crossbeam-deque-0.8.6.crate")
           (file-name "crossbeam-deque-0.8.6.crate")
           (sha256
            (base32 "0l9f1saqp1gn5qy0rxvkmz4m6n7fc0b3dbm6q1r5pmgpnyvi3lcx"))))
   (cons "davey-5b82ac4a3c2c"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/crossbeam-epoch/crossbeam-epoch-0.9.18.crate")
           (file-name "crossbeam-epoch-0.9.18.crate")
           (sha256
            (base32 "03j2np8llwf376m3fxqx859mgp9f83hj1w34153c7a9c7i5ar0jv"))))
   (cons "davey-d0a5c400df28"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/crossbeam-utils/crossbeam-utils-0.8.21.crate")
           (file-name "crossbeam-utils-0.8.21.crate")
           (sha256
            (base32 "0a3aa2bmc8q35fb67432w16wvi54sfmb69rk9h5bhd18vw0c99fh"))))
   (cons "davey-0dc92fb57ca4"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/crypto-bigint/crypto-bigint-0.5.5.crate")
           (file-name "crypto-bigint-0.5.5.crate")
           (sha256
            (base32 "0xmbdff3g6ii5sbxjxc31xfkv9lrmyril4arh3dzckd4gjsjzj8d"))))
   (cons "davey-78c8292055d1"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/crypto-common/crypto-common-0.1.7.crate")
           (file-name "crypto-common-0.1.7.crate")
           (sha256
            (base32 "02nn2rhfy7kvdkdjl457q2z0mklcvj9h662xrq6dzhfialh2kj3q"))))
   (cons "davey-424e0138278f"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/ctor/ctor-0.6.3.crate")
           (file-name "ctor-0.6.3.crate")
           (sha256
            (base32 "03jrw316acxl3vld3wvl5m8jkj0mwwbssx7i06sb5blg4ww02kj2"))))
   (cons "davey-52560adf0960"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/ctor-proc-macro/ctor-proc-macro-0.0.7.crate")
           (file-name "ctor-proc-macro-0.0.7.crate")
           (sha256
            (base32 "1havwah6iryn0ang09y12xxr45jsp7ff27zflz4mhgk017ghlmjj"))))
   (cons "davey-0369ee1ad671"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/ctr/ctr-0.9.2.crate")
           (file-name "ctr-0.9.2.crate")
           (sha256
            (base32 "0d88b73waamgpfjdml78icxz45d95q7vi2aqa604b0visqdfws83"))))
   (cons "davey-97fb8b7c4503"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/curve25519-dalek/curve25519-dalek-4.1.3.crate")
           (file-name "curve25519-dalek-4.1.3.crate")
           (sha256
            (base32 "1gmjb9dsknrr8lypmhkyjd67p1arb8mbfamlwxm7vph38my8pywp"))))
   (cons "davey-f46882e17999"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/curve25519-dalek-derive/curve25519-dalek-derive-0.1.1.crate")
           (file-name "curve25519-dalek-derive-0.1.1.crate")
           (sha256
            (base32 "1cry71xxrr0mcy5my3fb502cwfxy6822k4pm19cwrilrg7hq4s7l"))))
   (cons "davey-e7c1832837b9"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/der/der-0.7.10.crate")
           (file-name "der-0.7.10.crate")
           (sha256
            (base32 "1jyxacyxdx6mxbkfw99jz59dzvcd9k17rq01a7xvn1dr6wl87hg7"))))
   (cons "davey-9ed9a281f7bc"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/digest/digest-0.10.7.crate")
           (file-name "digest-0.10.7.crate")
           (sha256
            (base32 "14p2n6ih29x81akj097lvz7wi9b6b9hvls0lwrv7b6xwyy0s5ncy"))))
   (cons "davey-404d02eeb088"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/dtor/dtor-0.1.1.crate")
           (file-name "dtor-0.1.1.crate")
           (sha256
            (base32 "00fkcw8zn0g10m4k8b0qgmn304g47xqwn1ihhzyjra48n3p04ka0"))))
   (cons "davey-f678cf4a922c"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/dtor-proc-macro/dtor-proc-macro-0.0.6.crate")
           (file-name "dtor-proc-macro-0.0.6.crate")
           (sha256
            (base32 "19fg0mivy9qyvbwmqj3ysj0qm5cay0gyp5fyw1imq89cj95cyy7n"))))
   (cons "davey-ee27f32b5c52"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/ecdsa/ecdsa-0.16.9.crate")
           (file-name "ecdsa-0.16.9.crate")
           (sha256
            (base32 "1jhb0bcbkaz4001sdmfyv8ajrv8a1cg7z7aa5myrd4jjbhmz69zf"))))
   (cons "davey-115531babc12"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/ed25519/ed25519-2.2.3.crate")
           (file-name "ed25519-2.2.3.crate")
           (sha256
            (base32 "0lydzdf26zbn82g7xfczcac9d7mzm3qgx934ijjrd5hjpjx32m8i"))))
   (cons "davey-70e796c081ce"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/ed25519-dalek/ed25519-dalek-2.2.0.crate")
           (file-name "ed25519-dalek-2.2.0.crate")
           (sha256
            (base32 "1agcwij1z687hg26ngzwhnmpz29b2w56m8z1ap3pvrnfh709drvh"))))
   (cons "davey-48c757948c5e"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/either/either-1.15.0.crate")
           (file-name "either-1.15.0.crate")
           (sha256
            (base32 "069p1fknsmzn9llaizh77kip0pqmcwpdsykv2x30xpjyija5gis8"))))
   (cons "davey-b5e6043086bf"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/elliptic-curve/elliptic-curve-0.13.8.crate")
           (file-name "elliptic-curve-0.13.8.crate")
           (sha256
            (base32 "0ixx4brgnzi61z29r3g1606nh2za88hzyz8c5r3p6ydzhqq09rmm"))))
   (cons "davey-c0b50bfb6536"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/ff/ff-0.13.1.crate")
           (file-name "ff-0.13.1.crate")
           (sha256
            (base32 "14v3bc6q24gbcjnxjfbq2dddgf4as2z2gd4mj35gjlrncpxhpdf0"))))
   (cons "davey-28dea519a969"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/fiat-crypto/fiat-crypto-0.2.9.crate")
           (file-name "fiat-crypto-0.2.9.crate")
           (sha256
            (base32 "07c1vknddv3ak7w89n85ik0g34nzzpms6yb845vrjnv9m4csbpi8"))))
   (cons "davey-b768c170dc04"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/fluvio-wasm-timer/fluvio-wasm-timer-0.2.5.crate")
           (file-name "fluvio-wasm-timer-0.2.5.crate")
           (sha256
            (base32 "0zqkgwqm9pxd2mi7qirh95vpzf6gkcgwjj7rm23sapq4viqc2s5p"))))
   (cons "davey-65bc07b1a8bc"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/futures/futures-0.3.31.crate")
           (file-name "futures-0.3.31.crate")
           (sha256
            (base32 "0xh8ddbkm9jy8kc5gbvjp9a4b6rqqxvc8471yb2qaz5wm2qhgg35"))))
   (cons "davey-2dff15bf788c"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/futures-channel/futures-channel-0.3.31.crate")
           (file-name "futures-channel-0.3.31.crate")
           (sha256
            (base32 "040vpqpqlbk099razq8lyn74m0f161zd0rp36hciqrwcg2zibzrd"))))
   (cons "davey-05f29059c0c2"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/futures-core/futures-core-0.3.31.crate")
           (file-name "futures-core-0.3.31.crate")
           (sha256
            (base32 "0gk6yrxgi5ihfanm2y431jadrll00n5ifhnpx090c2f2q1cr1wh5"))))
   (cons "davey-1e28d1d997f5"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/futures-executor/futures-executor-0.3.31.crate")
           (file-name "futures-executor-0.3.31.crate")
           (sha256
            (base32 "17vcci6mdfzx4gbk0wx64chr2f13wwwpvyf3xd5fb1gmjzcx2a0y"))))
   (cons "davey-9e5c1b78ca4a"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/futures-io/futures-io-0.3.31.crate")
           (file-name "futures-io-0.3.31.crate")
           (sha256
            (base32 "1ikmw1yfbgvsychmsihdkwa8a1knank2d9a8dk01mbjar9w1np4y"))))
   (cons "davey-162ee34ebcb7"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/futures-macro/futures-macro-0.3.31.crate")
           (file-name "futures-macro-0.3.31.crate")
           (sha256
            (base32 "0l1n7kqzwwmgiznn0ywdc5i24z72zvh9q1dwps54mimppi7f6bhn"))))
   (cons "davey-e575fab7d1e0"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/futures-sink/futures-sink-0.3.31.crate")
           (file-name "futures-sink-0.3.31.crate")
           (sha256
            (base32 "1xyly6naq6aqm52d5rh236snm08kw8zadydwqz8bip70s6vzlxg5"))))
   (cons "davey-f90f7dce0722"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/futures-task/futures-task-0.3.31.crate")
           (file-name "futures-task-0.3.31.crate")
           (sha256
            (base32 "124rv4n90f5xwfsm9qw6y99755y021cmi5dhzh253s920z77s3zr"))))
   (cons "davey-9fa08315bb61"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/futures-util/futures-util-0.3.31.crate")
           (file-name "futures-util-0.3.31.crate")
           (sha256
            (base32 "10aa1ar8bgkgbr4wzxlidkqkcxf77gffyj8j7768h831pcaq784z"))))
   (cons "davey-85649ca51fd7"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/generic-array/generic-array-0.14.7.crate")
           (file-name "generic-array-0.14.7.crate")
           (sha256
            (base32 "16lyyrzrljfq424c3n8kfwkqihlimmsg5nhshbbp48np3yjrqr45"))))
   (cons "davey-ff2abc00be7f"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/getrandom/getrandom-0.2.17.crate")
           (file-name "getrandom-0.2.17.crate")
           (sha256
            (base32 "1l2ac6jfj9xhpjjgmcx6s1x89bbnw9x6j9258yy6xjkzpq0bqapz"))))
   (cons "davey-899def5c37c4"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/getrandom/getrandom-0.3.4.crate")
           (file-name "getrandom-0.3.4.crate")
           (sha256
            (base32 "1zbpvpicry9lrbjmkd4msgj3ihff1q92i334chk7pzf46xffz7c9"))))
   (cons "davey-f0d8a4362ccb"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/ghash/ghash-0.5.1.crate")
           (file-name "ghash-0.5.1.crate")
           (sha256
            (base32 "1wbg4vdgzwhkpkclz1g6bs4r5x984w5gnlsj4q5wnafb5hva9n7h"))))
   (cons "davey-f0f9ef7462f7"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/group/group-0.13.0.crate")
           (file-name "group-0.13.0.crate")
           (sha256
            (base32 "0qqs2p5vqnv3zvq9mfjkmw3qlvgqb0c3cm6p33srkh7pc9sfzygh"))))
   (cons "davey-8ffe806dd325"
         (origin
           (method url-fetch)
           (uri "https://codeload.github.com/hacspec/hax/tar.gz/bf9a7e4b6a24aebf015910d62477103d010fd643")
           (file-name "hacspec-bf9a7e4b6a24aebf015910d62477103d010fd643.tar.gz")
           (sha256
            (base32 "15y5s3x84pgp86kw8d16ilnn8yq5a4k59cnbmdnxgj95sdnq1zlg"))))
   (cons "davey-2304e00983f8"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/heck/heck-0.5.0.crate")
           (file-name "heck-0.5.0.crate")
           (sha256
            (base32 "1sjmpsdl8czyh9ywl3qcsfsq9a307dg4ni2vnlwgnzzqhc4y0113"))))
   (cons "davey-7ebdb29d2ea9"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/hex-literal/hex-literal-0.3.4.crate")
           (file-name "hex-literal-0.3.4.crate")
           (sha256
            (base32 "1q54yvyy0zls9bdrx15hk6yj304npndy9v4crn1h1vd95sfv5gby"))))
   (cons "davey-7b5f8eb2ad72"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/hkdf/hkdf-0.12.4.crate")
           (file-name "hkdf-0.12.4.crate")
           (sha256
            (base32 "1xxxzcarz151p1b858yn5skmhyrvn8fs4ivx5km3i1kjmnr8wpvv"))))
   (cons "davey-6c49c37c09c1"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/hmac/hmac-0.12.1.crate")
           (file-name "hmac-0.12.1.crate")
           (sha256
            (base32 "0pmbr069sfg76z7wsssfk5ddcqd9ncp79fyz6zcm6yn115yc6jbc"))))
   (cons "davey-9845e78154c7"
         (origin
           (method url-fetch)
           (uri "https://codeload.github.com/cryspen/hpke-rs/tar.gz/88ecea6b3e89a60b507b32c980f1357e37d62793")
           (file-name "cryspen-88ecea6b3e89a60b507b32c980f1357e37d62793.tar.gz")
           (sha256
            (base32 "1r1b8wzxp3rxcx4847izqxshny9xw160zx3h45f8pm67aj0yficq"))))
   (cons "davey-ae594ac9bd8b"
         (origin
           (method url-fetch)
           (uri "https://codeload.github.com/cryspen/hpke-rs/tar.gz/6bb771df1f0f3fb76337329f5ebdcbfbfc4099fa")
           (file-name "cryspen-6bb771df1f0f3fb76337329f5ebdcbfbfc4099fa.tar.gz")
           (sha256
            (base32 "1iv119l41hs6p167jmy91427s29gg0aslwvkg39gv64bpp4llndf"))))
   (cons "davey-79cf5c93f932"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/indoc/indoc-2.0.7.crate")
           (file-name "indoc-2.0.7.crate")
           (sha256
            (base32 "01np60qdq6lvgh8ww2caajn9j4dibx9n58rvzf7cya1jz69mrkvr"))))
   (cons "davey-879f10e63c20"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/inout/inout-0.1.4.crate")
           (file-name "inout-0.1.4.crate")
           (sha256
            (base32 "008xfl1jn9rxsq19phnhbimccf4p64880jmnpg59wqi07kk117w7"))))
   (cons "davey-e0242819d153"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/instant/instant-0.1.13.crate")
           (file-name "instant-0.1.13.crate")
           (sha256
            (base32 "08h27kzvb5jw74mh0ajv0nv9ggwvgqm8ynjsn2sa9jsks4cjh970"))))
   (cons "davey-92ecc6618181"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/itoa/itoa-1.0.17.crate")
           (file-name "itoa-1.0.17.crate")
           (sha256
            (base32 "1lh93xydrdn1g9x547bd05g0d3hra7pd1k4jfd2z1pl1h5hwdv4j"))))
   (cons "davey-464a3709c7f5"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/js-sys/js-sys-0.3.83.crate")
           (file-name "js-sys-0.3.83.crate")
           (sha256
            (base32 "1n71vpxrzclly0530lwkcsx6mg73lipam2ak3rr1ypzmqw4kfjj6"))))
   (cons "davey-f6e3919bbaa2"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/k256/k256-0.13.4.crate")
           (file-name "k256-0.13.4.crate")
           (sha256
            (base32 "06s1lxjp49zgmbxnfdy2kajyklbkl4s3jvdvy0amg552padr3qzn"))))
   (cons "davey-bbd2bcb4c963"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/lazy_static/lazy_static-1.5.0.crate")
           (file-name "lazy_static-1.5.0.crate")
           (sha256
            (base32 "1zk6dqqni0193xg6iijh7i3i44sryglwgvx20spdvwk3r6sbrlmv"))))
   (cons "davey-bcc35a38544a"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/libc/libc-0.2.180.crate")
           (file-name "libc-0.2.180.crate")
           (sha256
            (base32 "1z2n7hl10fnk1xnv19ahhqxwnb4qi9aclnl6gigim2aaahw5mhxw"))))
   (cons "davey-1b89a0a47ca0"
         (origin
           (method url-fetch)
           (uri "https://codeload.github.com/cryspen/libcrux/tar.gz/c95c076b2bf0381229588902b4a21c234dd4f6f4")
           (file-name "cryspen-c95c076b2bf0381229588902b4a21c234dd4f6f4.tar.gz")
           (sha256
            (base32 "05afi1fxhg36bny5yzh1sj585bwjxpzibqzh82203mm0gjja128v"))))
   (cons "davey-2590f7871ae7"
         (origin
           (method url-fetch)
           (uri "https://codeload.github.com/cryspen/libcrux/tar.gz/2757e2e7d5d26aafd0e44ca5d79023ea875f2069")
           (file-name "cryspen-2757e2e7d5d26aafd0e44ca5d79023ea875f2069.tar.gz")
           (sha256
            (base32 "1g7582kf86i4bn54yv3h3qb3ai5s5cq344iqc5b1xdz73a3zg415"))))
   (cons "davey-a80915b75b7a"
         (origin
           (method url-fetch)
           (uri "https://codeload.github.com/cryspen/libcrux/tar.gz/4210c0e467625b4ca7ece899f303f091748eb14a")
           (file-name "cryspen-4210c0e467625b4ca7ece899f303f091748eb14a.tar.gz")
           (sha256
            (base32 "1837h8aw45z29pxia5dwbx0i9vvax6xnbg83p8hqkjksbfvia2d8"))))
   (cons "davey-754ca22de805"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/libloading/libloading-0.9.0.crate")
           (file-name "libloading-0.9.0.crate")
           (sha256
            (base32 "0q4bvhp4kqy2v3bw4cn2bmyq73hskqd1ansa9125gfq5x0ns4k3m"))))
   (cons "davey-224399e74b87"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/lock_api/lock_api-0.4.14.crate")
           (file-name "lock_api-0.4.14.crate")
           (sha256
            (base32 "0rg9mhx7vdpajfxvdjmgmlyrn20ligzqvn8ifmaz7dc79gkrjhr2"))))
   (cons "davey-5e5032e24019"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/log/log-0.4.29.crate")
           (file-name "log-0.4.29.crate")
           (sha256
            (base32 "15q8j9c8g5zpkcw0hnd6cf2z7fxqnvsjh3rw5mv5q10r83i34l2y"))))
   (cons "davey-f52b00d39961"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/memchr/memchr-2.7.6.crate")
           (file-name "memchr-2.7.6.crate")
           (sha256
            (base32 "0wy29kf6pb4fbhfksjbs05jy2f32r2f3r1ga6qkmpz31k79h0azm"))))
   (cons "davey-488016bfae45"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/memoffset/memoffset-0.9.1.crate")
           (file-name "memoffset-0.9.1.crate")
           (sha256
            (base32 "12i17wh9a9plx869g7j4whf62xw68k5zd4k0k5nh6ys5mszid028"))))
   (cons "davey-e43d8f2d234d"
         (origin
           (method url-fetch)
           (uri "https://codeload.github.com/napi-rs/napi-rs/tar.gz/73cfbdb605ec9d898207ac280cdb3b3807706dfd")
           (file-name "napi-rs-73cfbdb605ec9d898207ac280cdb3b3807706dfd.tar.gz")
           (sha256
            (base32 "1vgrb8qc6lp1h059dd6c21v7s01gbg4zpczs8x3a8p2d4cnqygg4"))))
   (cons "davey-37c9f71bdda3"
         (origin
           (method url-fetch)
           (uri "https://codeload.github.com/napi-rs/napi-rs/tar.gz/67e711d69b7e681807d157ea85cf8173fd923537")
           (file-name "napi-rs-67e711d69b7e681807d157ea85cf8173fd923537.tar.gz")
           (sha256
            (base32 "05a10w0sj2vsd8r7i96g30jd0z6g0j6fa2hanwfpgym3vldzgj9p"))))
   (cons "davey-2de3f6961a07"
         (origin
           (method url-fetch)
           (uri "https://codeload.github.com/napi-rs/napi-rs/tar.gz/be4b16ca00aa2cecd19be6ffe6de59495b471b14")
           (file-name "napi-rs-be4b16ca00aa2cecd19be6ffe6de59495b471b14.tar.gz")
           (sha256
            (base32 "0bfxvpymzdc8jxxvzs1g5b88kvr5k42i3dhpdlg6xch73abgdqrd"))))
   (cons "davey-2bf50223579d"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/nohash-hasher/nohash-hasher-0.2.0.crate")
           (file-name "nohash-hasher-0.2.0.crate")
           (sha256
            (base32 "0lf4p6k01w4wm7zn4grnihzj8s7zd5qczjmzng7wviwxawih5x9b"))))
   (cons "davey-7957b9740744"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/nu-ansi-term/nu-ansi-term-0.50.3.crate")
           (file-name "nu-ansi-term-0.50.3.crate")
           (sha256
            (base32 "1ra088d885lbd21q1bxgpqdlk1zlndblmarn948jz2a40xsbjmvr"))))
   (cons "davey-a5e44f723f11"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/num-bigint/num-bigint-0.4.6.crate")
           (file-name "num-bigint-0.4.6.crate")
           (sha256
            (base32 "1f903zd33i6hkjpsgwhqwi2wffnvkxbn6rv4mkgcjcqi7xr4zr55"))))
   (cons "davey-ed3955f1a9c7"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/num-derive/num-derive-0.4.2.crate")
           (file-name "num-derive-0.4.2.crate")
           (sha256
            (base32 "00p2am9ma8jgd2v6xpsz621wc7wbn1yqi71g15gc3h67m7qmafgd"))))
   (cons "davey-7969661fd295"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/num-integer/num-integer-0.1.46.crate")
           (file-name "num-integer-0.1.46.crate")
           (sha256
            (base32 "13w5g54a9184cqlbsq80rnxw4jj4s0d8wv75jsq5r2lms8gncsbr"))))
   (cons "davey-071dfc062690"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/num-traits/num-traits-0.2.19.crate")
           (file-name "num-traits-0.2.19.crate")
           (sha256
            (base32 "0h984rhdkkqd4ny9cif7y2azl3xdfb7768hb9irhpsch4q3gq787"))))
   (cons "davey-42f5e15c9953"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/once_cell/once_cell-1.21.3.crate")
           (file-name "once_cell-1.21.3.crate")
           (sha256
            (base32 "0b9x77lb9f1j6nqgf5aka4s2qj0nly176bpbrv6f9iakk5ff3xa2"))))
   (cons "davey-c08d65885ee3"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/opaque-debug/opaque-debug-0.3.1.crate")
           (file-name "opaque-debug-0.3.1.crate")
           (sha256
            (base32 "10b3w0kydz5jf1ydyli5nv10gdfp97xh79bgz327d273bs46b3f0"))))
   (cons "davey-bf0a991dd28f"
         (origin
           (method url-fetch)
           (uri "https://codeload.github.com/openmls/openmls//tar.gz/da647b93a7ec3446f4c999d6144f1a77f0d56a0c")
           (file-name "openmls-da647b93a7ec3446f4c999d6144f1a77f0d56a0c.tar.gz")
           (sha256
            (base32 "073q1zqr0876nln8ik8i32gc4sx61vqkx1lb7y7q1n4gs8frj2mz"))))
   (cons "davey-df1d4aebc2d3"
         (origin
           (method url-fetch)
           (uri "https://codeload.github.com/openmls/openmls/tar.gz/07290b76b091d051d81749248fb99e99424ebf07")
           (file-name "openmls-07290b76b091d051d81749248fb99e99424ebf07.tar.gz")
           (sha256
            (base32 "130i4in5yra2d8p8p91nf65fcycnxv1yc0671dp59yykqbmll7fz"))))
   (cons "davey-c9863ad85fa8"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/p256/p256-0.13.2.crate")
           (file-name "p256-0.13.2.crate")
           (sha256
            (base32 "0jyd3c3k239ybs59ixpnl7dqkmm072fr1js8kh7ldx58bzc3m1n9"))))
   (cons "davey-fe42f1670a52"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/p384/p384-0.13.1.crate")
           (file-name "p384-0.13.1.crate")
           (sha256
            (base32 "1dnnp133mbpp72mfss3fhm8wx3yp3p3abdhlix27v92j19kz2hpy"))))
   (cons "davey-7d17b78036a6"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/parking_lot/parking_lot-0.11.2.crate")
           (file-name "parking_lot-0.11.2.crate")
           (sha256
            (base32 "16gzf41bxmm10x82bla8d6wfppy9ym3fxsmdjyvn61m66s0bf5vx"))))
   (cons "davey-60a2cfe6f0ad"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/parking_lot_core/parking_lot_core-0.8.6.crate")
           (file-name "parking_lot_core-0.8.6.crate")
           (sha256
            (base32 "1p2nfcbr0b9lm9rglgm28k6mwyjwgm4knipsmqbgqaxdy3kcz8k0"))))
   (cons "davey-35fb2e5f958e"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/pastey/pastey-0.1.1.crate")
           (file-name "pastey-0.1.1.crate")
           (sha256
            (base32 "1v389jkifv757903flrrps67dvc6q6giwlyx3xi33hcfjmgjxyrm"))))
   (cons "davey-f8ed6a7761f7"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/pbkdf2/pbkdf2-0.12.2.crate")
           (file-name "pbkdf2-0.12.2.crate")
           (sha256
            (base32 "1wms79jh4flpy1zi8xdp4h8ccxv4d85adc6zjagknvppc5vnmvgq"))))
   (cons "davey-88b39c9bfcfc"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/pem-rfc7468/pem-rfc7468-0.7.0.crate")
           (file-name "pem-rfc7468-0.7.0.crate")
           (sha256
            (base32 "04l4852scl4zdva31c1z6jafbak0ni5pi0j38ml108zwzjdrrcw8"))))
   (cons "davey-3b3cff922bd5"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/pin-project-lite/pin-project-lite-0.2.16.crate")
           (file-name "pin-project-lite-0.2.16.crate")
           (sha256
            (base32 "16wzc7z7dfkf9bmjin22f5282783f6mdksnr0nv0j5ym5f9gyg1v"))))
   (cons "davey-8b870d8c151b"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/pin-utils/pin-utils-0.1.0.crate")
           (file-name "pin-utils-0.1.0.crate")
           (sha256
            (base32 "117ir7vslsl2z1a7qzhws4pd01cg2d3338c47swjyvqv2n60v1wb"))))
   (cons "davey-f950b2377845"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/pkcs8/pkcs8-0.10.2.crate")
           (file-name "pkcs8-0.10.2.crate")
           (sha256
            (base32 "1dx7w21gvn07azszgqd3ryjhyphsrjrmq5mmz1fbxkj5g0vv4l7r"))))
   (cons "davey-8159bd90725d"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/poly1305/poly1305-0.8.0.crate")
           (file-name "poly1305-0.8.0.crate")
           (sha256
            (base32 "1grs77skh7d8vi61ji44i8gpzs3r9x7vay50i6cg8baxfa8bsnc1"))))
   (cons "davey-9d1fe60d0614"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/polyval/polyval-0.6.2.crate")
           (file-name "polyval-0.6.2.crate")
           (sha256
            (base32 "09gs56vm36ls6pyxgh06gw2875z2x77r8b2km8q28fql0q6yc7wx"))))
   (cons "davey-f89776e4d69b"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/portable-atomic/portable-atomic-1.13.0.crate")
           (file-name "portable-atomic-1.13.0.crate")
           (sha256
            (base32 "0l79rf3pzlxmmrylr1c4k61qn8hzs6hzz69yk738pdcvsvj7d5zq"))))
   (cons "davey-85eae3c4ed2f"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/ppv-lite86/ppv-lite86-0.2.21.crate")
           (file-name "ppv-lite86-0.2.21.crate")
           (sha256
            (base32 "1abxx6qz5qnd43br1dd9b2savpihzjza8gb4fbzdql1gxp2f7sl5"))))
   (cons "davey-353e1ca18966"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/primeorder/primeorder-0.13.6.crate")
           (file-name "primeorder-0.13.6.crate")
           (sha256
            (base32 "1rp16710mxksagcjnxqjjq9r9wf5vf72fs8wxffnvhb6i6hiqgim"))))
   (cons "davey-96de42df36bb"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/proc-macro-error-attr2/proc-macro-error-attr2-2.0.0.crate")
           (file-name "proc-macro-error-attr2-2.0.0.crate")
           (sha256
            (base32 "1ifzi763l7swl258d8ar4wbpxj4c9c2im7zy89avm6xv6vgl5pln"))))
   (cons "davey-11ec05c52be0"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/proc-macro-error2/proc-macro-error2-2.0.1.crate")
           (file-name "proc-macro-error2-2.0.1.crate")
           (sha256
            (base32 "00lq21vgh7mvyx51nwxwf822w2fpww1x0z8z0q47p8705g2hbv0i"))))
   (cons "davey-535d180e0eca"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/proc-macro2/proc-macro2-1.0.105.crate")
           (file-name "proc-macro2-1.0.105.crate")
           (sha256
            (base32 "1rvgs5qdznlrqrgicmv24nybnrnv8kyvk2vi7s52ddna1q71hpak"))))
   (cons "davey-8970a78afe06"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/pyo3/pyo3-0.25.1.crate")
           (file-name "pyo3-0.25.1.crate")
           (sha256
            (base32 "0ak85gkxs2ylrpbgyq1ksk24asvbsxgzqxh38gis6a06zs5afw49"))))
   (cons "davey-458eb0c55e7e"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/pyo3-build-config/pyo3-build-config-0.25.1.crate")
           (file-name "pyo3-build-config-0.25.1.crate")
           (sha256
            (base32 "163m3jhd5mrql9qpq3b6adg63b7kiwjg4f5svrx03kkybv2v13j5"))))
   (cons "davey-7114fe5457c6"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/pyo3-ffi/pyo3-ffi-0.25.1.crate")
           (file-name "pyo3-ffi-0.25.1.crate")
           (sha256
            (base32 "0p2n08qhqr5jqnjl8dh810k82nr90vr5al3wnxm2f6y6axagw53i"))))
   (cons "davey-a8725c0a622b"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/pyo3-macros/pyo3-macros-0.25.1.crate")
           (file-name "pyo3-macros-0.25.1.crate")
           (sha256
            (base32 "0l3yxxmsmxcl7jf16djkg3vlhr3qhc4imlain1n4sdrbc855qwm8"))))
   (cons "davey-4109984c2249"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/pyo3-macros-backend/pyo3-macros-backend-0.25.1.crate")
           (file-name "pyo3-macros-backend-0.25.1.crate")
           (sha256
            (base32 "1k1cawx33hzm6g2lydxlywy5qh6w9p2xpc057hs8a4294969h2a1"))))
   (cons "davey-dc74d9a594b7"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/quote/quote-1.0.43.crate")
           (file-name "quote-1.0.43.crate")
           (sha256
            (base32 "02n41mlr81qmczac7m5kjy51y8b7yrb8ym4ncmjycampjjjxjx6w"))))
   (cons "davey-34af8d1a0e25"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/rand/rand-0.8.5.crate")
           (file-name "rand-0.8.5.crate")
           (sha256
            (base32 "013l6931nn7gkc23jz5mm3qdhf93jjf0fg64nz2lp4i51qd8vbrl"))))
   (cons "davey-6db2770f0611"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/rand/rand-0.9.2.crate")
           (file-name "rand-0.9.2.crate")
           (sha256
            (base32 "1lah73ainvrgl7brcxx0pwhpnqa3sm3qaj672034jz8i0q7pgckd"))))
   (cons "davey-e6c10a63a0fa"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/rand_chacha/rand_chacha-0.3.1.crate")
           (file-name "rand_chacha-0.3.1.crate")
           (sha256
            (base32 "123x2adin558xbhvqb8w4f6syjsdkmqff8cxwhmjacpsl1ihmhg6"))))
   (cons "davey-d3022b5f1df6"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/rand_chacha/rand_chacha-0.9.0.crate")
           (file-name "rand_chacha-0.9.0.crate")
           (sha256
            (base32 "1jr5ygix7r60pz0s1cv3ms1f6pd1i9pcdmnxzzhjc3zn3mgjn0nk"))))
   (cons "davey-ec0be4795e2f"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/rand_core/rand_core-0.6.4.crate")
           (file-name "rand_core-0.6.4.crate")
           (sha256
            (base32 "0b4j2v4cb5krak1pv6kakv4sz6xcwbrmy2zckc32hsigbrwy82zc"))))
   (cons "davey-4f1b3bc831f9"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/rand_core/rand_core-0.9.4.crate")
           (file-name "rand_core-0.9.4.crate")
           (sha256
            (base32 "1yks7mdfbq0036jnannkxvqj2yvwj45kbinriw0q28zr6743n6sg"))))
   (cons "davey-368f01d005bf"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/rayon/rayon-1.11.0.crate")
           (file-name "rayon-1.11.0.crate")
           (sha256
            (base32 "13x5fxb7rn4j2yw0cr26n7782jkc7rjzmdkg42qxk3xz0p8033rn"))))
   (cons "davey-22e18b0f0062"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/rayon-core/rayon-core-1.13.0.crate")
           (file-name "rayon-core-1.13.0.crate")
           (sha256
            (base32 "14dbr0sq83a6lf1rfjq5xdpk5r6zgzvmzs5j6110vlv2007qpq92"))))
   (cons "davey-fb5a58c1855b"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/redox_syscall/redox_syscall-0.2.16.crate")
           (file-name "redox_syscall-0.2.16.crate")
           (sha256
            (base32 "16jicm96kjyzm802cxdd1k9jmcph0db1a4lhslcnhjsvhp0mhnpv"))))
   (cons "davey-f8dd2a808d45"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/rfc6979/rfc6979-0.4.0.crate")
           (file-name "rfc6979-0.4.0.crate")
           (sha256
            (base32 "1chw95jgcfrysyzsq6a10b1j5qb7bagkx8h0wda4lv25in02mpgq"))))
   (cons "davey-357703d41365"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/rustc-hash/rustc-hash-2.1.1.crate")
           (file-name "rustc-hash-2.1.1.crate")
           (sha256
            (base32 "03gz5lvd9ghcwsal022cgkq67dmimcgdjghfb5yb5d352ga06xrm"))))
   (cons "davey-cfcb3a22ef46"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/rustc_version/rustc_version-0.4.1.crate")
           (file-name "rustc_version-0.4.1.crate")
           (sha256
            (base32 "14lvdsmr5si5qbqzrajgb6vfn69k0sfygrvfvr2mps26xwi3mjyg"))))
   (cons "davey-b39cdef0fa80"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/rustversion/rustversion-1.0.22.crate")
           (file-name "rustversion-1.0.22.crate")
           (sha256
            (base32 "0vfl70jhv72scd9rfqgr2n11m5i9l1acnk684m2w83w0zbqdx75k"))))
   (cons "davey-97a22f5af31f"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/salsa20/salsa20-0.10.2.crate")
           (file-name "salsa20-0.10.2.crate")
           (sha256
            (base32 "04w211x17xzny53f83p8f7cj7k2hi8zck282q5aajwqzydd2z8lp"))))
   (cons "davey-94143f377251"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/scopeguard/scopeguard-1.2.0.crate")
           (file-name "scopeguard-1.2.0.crate")
           (sha256
            (base32 "0jcz9sd47zlsgcnm1hdw0664krxwb5gczlif4qngj2aif8vky54l"))))
   (cons "davey-0516a385866c"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/scrypt/scrypt-0.11.0.crate")
           (file-name "scrypt-0.11.0.crate")
           (sha256
            (base32 "07zxfaqpns9jn0mnxm7wj3ksqsinyfpirkav1f7kc2bchs2s65h5"))))
   (cons "davey-d3e97a565f76"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/sec1/sec1-0.7.3.crate")
           (file-name "sec1-0.7.3.crate")
           (sha256
            (base32 "1p273j8c87pid6a1iyyc7vxbvifrw55wbxgr0dh3l8vnbxb7msfk"))))
   (cons "davey-d767eb0aabc8"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/semver/semver-1.0.27.crate")
           (file-name "semver-1.0.27.crate")
           (sha256
            (base32 "1qmi3akfrnqc2hfkdgcxhld5bv961wbk8my3ascv5068mc5fnryp"))))
   (cons "davey-9a8e94ea7f37"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/serde/serde-1.0.228.crate")
           (file-name "serde-1.0.228.crate")
           (sha256
            (base32 "17mf4hhjxv5m90g42wmlbc61hdhlm6j9hwfkpcnd72rpgzm993ls"))))
   (cons "davey-a5d440709e79"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/serde_bytes/serde_bytes-0.11.19.crate")
           (file-name "serde_bytes-0.11.19.crate")
           (sha256
            (base32 "1a1y1v0r9akqyvprxnmpgc0i8wybqqpvgi01mi8qxn3rkrq41m55"))))
   (cons "davey-41d385c7d4ca"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/serde_core/serde_core-1.0.228.crate")
           (file-name "serde_core-1.0.228.crate")
           (sha256
            (base32 "1bb7id2xwx8izq50098s5j2sqrrvk31jbbrjqygyan6ask3qbls1"))))
   (cons "davey-d540f220d318"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/serde_derive/serde_derive-1.0.228.crate")
           (file-name "serde_derive-1.0.228.crate")
           (sha256
            (base32 "0y8xm7fvmr2kjcd029g9fijpndh8csv5m20g4bd76w8qschg4h6m"))))
   (cons "davey-83fc039473c5"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/serde_json/serde_json-1.0.149.crate")
           (file-name "serde_json-1.0.149.crate")
           (sha256
            (base32 "11jdx4vilzrjjd1dpgy67x5lgzr0laplz30dhv75lnf5ffa07z43"))))
   (cons "davey-a7507d819769"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/sha2/sha2-0.10.9.crate")
           (file-name "sha2-0.10.9.crate")
           (sha256
            (base32 "10xjj843v31ghsksd9sl9y12qfc48157j1xpb8v1ml39jy0psl57"))))
   (cons "davey-f40ca3c46823"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/sharded-slab/sharded-slab-0.1.7.crate")
           (file-name "sharded-slab-0.1.7.crate")
           (sha256
            (base32 "1xipjr4nqsgw34k7a2cgj9zaasl2ds6jwn89886kww93d32a637l"))))
   (cons "davey-77549399552d"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/signature/signature-2.2.0.crate")
           (file-name "signature-2.2.0.crate")
           (sha256
            (base32 "1pi9hd5vqfr3q3k49k37z06p7gs5si0in32qia4mmr1dancr6m3p"))))
   (cons "davey-7a2ae44ef20f"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/slab/slab-0.4.11.crate")
           (file-name "slab-0.4.11.crate")
           (sha256
            (base32 "12bm4s88rblq02jjbi1dw31984w61y2ldn13ifk5gsqgy97f8aks"))))
   (cons "davey-67b1b7a3b5fe"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/smallvec/smallvec-1.15.1.crate")
           (file-name "smallvec-1.15.1.crate")
           (sha256
            (base32 "00xxdxxpgyq5vjnpljvkmy99xij5rxgh913ii1v16kzynnivgcb7"))))
   (cons "davey-d91ed6c858b0"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/spki/spki-0.7.3.crate")
           (file-name "spki-0.7.3.crate")
           (sha256
            (base32 "17fj8k5fmx4w9mp27l970clrh5qa7r5sjdvbsln987xhb34dc7nr"))))
   (cons "davey-13c2bddecc57"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/subtle/subtle-2.6.1.crate")
           (file-name "subtle-2.6.1.crate")
           (sha256
            (base32 "14ijxaymghbl1p0wql9cib5zlwiina7kall6w7g89csprkgbvhhk"))))
   (cons "davey-d4d107df263a"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/syn/syn-2.0.114.crate")
           (file-name "syn-2.0.114.crate")
           (sha256
            (base32 "0akw62dizhyrkf3ym1jsys0gy1nphzgv0y8qkgpi6c1s4vghglfl"))))
   (cons "davey-b1dd07eb858a"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/target-lexicon/target-lexicon-0.13.4.crate")
           (file-name "target-lexicon-0.13.4.crate")
           (sha256
            (base32 "1fnh3md1p3bsxviyydvg9qk5q9i9x5a5s5f7ygi6f84ahpmhgpdi"))))
   (cons "davey-f63587ca0f12"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/thiserror/thiserror-2.0.17.crate")
           (file-name "thiserror-2.0.17.crate")
           (sha256
            (base32 "1j2gixhm2c3s6g96vd0b01v0i0qz1101vfmw0032mdqj1z58fdgn"))))
   (cons "davey-3ff15c8ecd7d"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/thiserror-impl/thiserror-impl-2.0.17.crate")
           (file-name "thiserror-impl-2.0.17.crate")
           (sha256
            (base32 "04y92yjwg1a4piwk9nayzjfs07sps8c4vq9jnsfq9qvxrn75rw9z"))))
   (cons "davey-f60246a4944f"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/thread_local/thread_local-1.1.9.crate")
           (file-name "thread_local-1.1.9.crate")
           (sha256
            (base32 "1191jvl8d63agnq06pcnarivf63qzgpws5xa33hgc92gjjj4c0pn"))))
   (cons "davey-0de2e01245e2"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/tls_codec/tls_codec-0.4.2.crate")
           (file-name "tls_codec-0.4.2.crate")
           (sha256
            (base32 "0sxzj0pdinn7fsc8aihqgfylsqi7z9jca0aqy3b8kfz28l9f1qhd"))))
   (cons "davey-2d2e76690929"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/tls_codec_derive/tls_codec_derive-0.4.2.crate")
           (file-name "tls_codec_derive-0.4.2.crate")
           (sha256
            (base32 "1gglj5cxkpv7i3jazffksrfy5h5242kdvsqawjm2yh1915lpcbid"))))
   (cons "davey-63e71662fa4b"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/tracing/tracing-0.1.44.crate")
           (file-name "tracing-0.1.44.crate")
           (sha256
            (base32 "006ilqkg1lmfdh3xhg3z762izfwmxcvz0w7m4qx2qajbz9i1drv3"))))
   (cons "davey-7490cfa5ec96"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/tracing-attributes/tracing-attributes-0.1.31.crate")
           (file-name "tracing-attributes-0.1.31.crate")
           (sha256
            (base32 "1np8d77shfvz0n7camx2bsf1qw0zg331lra0hxb4cdwnxjjwz43l"))))
   (cons "davey-db97caf9d906"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/tracing-core/tracing-core-0.1.36.crate")
           (file-name "tracing-core-0.1.36.crate")
           (sha256
            (base32 "16mpbz6p8vd6j7sf925k9k8wzvm9vdfsjbynbmaxxyq6v7wwm5yv"))))
   (cons "davey-ee855f1f400b"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/tracing-log/tracing-log-0.2.0.crate")
           (file-name "tracing-log-0.2.0.crate")
           (sha256
            (base32 "1hs77z026k730ij1a9dhahzrl0s073gfa2hm5p0fbl0b80gmz1gf"))))
   (cons "davey-2f30143827dd"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/tracing-subscriber/tracing-subscriber-0.3.22.crate")
           (file-name "tracing-subscriber-0.3.22.crate")
           (sha256
            (base32 "07hz575a0p1c2i4xw3gs3hkrykhndnkbfhyqdwjhvayx4ww18c1g"))))
   (cons "davey-562d481066bd"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/typenum/typenum-1.19.0.crate")
           (file-name "typenum-1.19.0.crate")
           (sha256
            (base32 "1fw2mpbn2vmqan56j1b3fbpcdg80mz26fm53fs16bq5xcq84hban"))))
   (cons "davey-9312f7c4f6ff"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/unicode-ident/unicode-ident-1.0.22.crate")
           (file-name "unicode-ident-1.0.22.crate")
           (sha256
            (base32 "1x8xrz17vqi6qmkkcqr8cyf0an76ig7390j9cnqnk47zyv2gf4lk"))))
   (cons "davey-f6ccf2512121"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/unicode-segmentation/unicode-segmentation-1.12.0.crate")
           (file-name "unicode-segmentation-1.12.0.crate")
           (sha256
            (base32 "14qla2jfx74yyb9ds3d2mpwpa4l4lzb9z57c6d2ba511458z5k7n"))))
   (cons "davey-7264e107f553"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/unindent/unindent-0.2.4.crate")
           (file-name "unindent-0.2.4.crate")
           (sha256
            (base32 "1wvfh815i6wm6whpdz1viig7ib14cwfymyr1kn3sxk2kyl3y2r3j"))))
   (cons "davey-fc1de2c688dc"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/universal-hash/universal-hash-0.5.1.crate")
           (file-name "universal-hash-0.5.1.crate")
           (sha256
            (base32 "1sh79x677zkncasa95wz05b36134822w6qxmi1ck05fwi33f47gw"))))
   (cons "davey-e2e054861b4b"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/uuid/uuid-1.19.0.crate")
           (file-name "uuid-1.19.0.crate")
           (sha256
            (base32 "0jjbclx3f36fjl6jjh8f022q0m76v3cfh61y6z6jgl2b3f359q72"))))
   (cons "davey-3414d7860b88"
         (origin
           (method url-fetch)
           (uri "https://codeload.github.com/tokio-rs/valuable/tar.gz/9efc29b6e58cef28f6566a47aa7e142a55fead77")
           (file-name "tokio-rs-9efc29b6e58cef28f6566a47aa7e142a55fead77.tar.gz")
           (sha256
            (base32 "1q1px4ikgcn2m8f3s95xl8b5l1f3khmvndk1mjqldjc81f3df51l"))))
   (cons "davey-0b928f33d975"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/version_check/version_check-0.9.5.crate")
           (file-name "version_check-0.9.5.crate")
           (sha256
            (base32 "0nhhi4i5x89gm911azqbn7avs9mdacw2i3vcz3cnmz3mv4rqz4hb"))))
   (cons "davey-ccf3ec651a84"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/wasi/wasi-0.11.1+wasi-snapshot-preview1.crate")
           (file-name "wasi-0.11.1+wasi-snapshot-preview1.crate")
           (sha256
            (base32 "0jx49r7nbkbhyfrfyhz0bm4817yrnxgd3jiwwwfv0zl439jyrwyc"))))
   (cons "davey-8c7425b921e2"
         (origin
           (method url-fetch)
           (uri "https://codeload.github.com/bytecodealliance/wasi-rs/tar.gz/3da562c06214feafc14d37bf290671636caa6718")
           (file-name "bytecodealliance-3da562c06214feafc14d37bf290671636caa6718.tar.gz")
           (sha256
            (base32 "0pni7bjqilib3x05pdgdk1cyd98zlrm672yx72a8hmp246wjax4c"))))
   (cons "davey-0d759f433fa6"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/wasm-bindgen/wasm-bindgen-0.2.106.crate")
           (file-name "wasm-bindgen-0.2.106.crate")
           (sha256
            (base32 "1zc0pcyv0w1dhp8r7ybmmfjsf4g18q784h0k7mv2sjm67x1ryx8d"))))
   (cons "davey-836d9622d604"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/wasm-bindgen-futures/wasm-bindgen-futures-0.4.56.crate")
           (file-name "wasm-bindgen-futures-0.4.56.crate")
           (sha256
            (base32 "0z6f0zkylpgbfb7dkh7a85dxdwm57q7c2np2bngfxzh4sqi9cvc3"))))
   (cons "davey-48cb0d2638f8"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/wasm-bindgen-macro/wasm-bindgen-macro-0.2.106.crate")
           (file-name "wasm-bindgen-macro-0.2.106.crate")
           (sha256
            (base32 "1czfwzhqrkzyyhd3g58mdwb2jjk4q2pl9m1fajyfvfpq70k0vjs8"))))
   (cons "davey-cefb59d5cd5f"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/wasm-bindgen-macro-support/wasm-bindgen-macro-support-0.2.106.crate")
           (file-name "wasm-bindgen-macro-support-0.2.106.crate")
           (sha256
            (base32 "0h6ddq6cc6jf9phsdh2a3x8lpjhmkya86ihfz3fdk4jzrpamkyyf"))))
   (cons "davey-cbc538057e64"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/wasm-bindgen-shared/wasm-bindgen-shared-0.2.106.crate")
           (file-name "wasm-bindgen-shared-0.2.106.crate")
           (sha256
            (base32 "1d0dh3jn77qz67n5zh0s3rvzlbjv926p0blq5bvng2v4gq2kiifb"))))
   (cons "davey-9b32828d774c"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/web-sys/web-sys-0.3.83.crate")
           (file-name "web-sys-0.3.83.crate")
           (sha256
            (base32 "1b1pw450ig62xr0cy1wfjlbahvmi725jl64d150j0hacfy6q4clv"))))
   (cons "davey-5c839a674fcd"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/winapi/winapi-0.3.9.crate")
           (file-name "winapi-0.3.9.crate")
           (sha256
            (base32 "06gl025x418lchw1wxj64ycr7gha83m44cjr5sarhynd9xkrm0sw"))))
   (cons "davey-f0805222e57f"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/windows-link/windows-link-0.2.1.crate")
           (file-name "windows-link-0.2.1.crate")
           (sha256
            (base32 "1rag186yfr3xx7piv5rg8b6im2dwcf8zldiflvb22xbzwli5507h"))))
   (cons "davey-ae137229bcbd"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/windows-sys/windows-sys-0.61.2.crate")
           (file-name "windows-sys-0.61.2.crate")
           (sha256
            (base32 "1z7k3y9b6b5h52kid57lvmvm05362zv1v8w0gc7xyv5xphlp44xf"))))
   (cons "davey-f17a85883d4e"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/wit-bindgen/wit-bindgen-0.46.0.crate")
           (file-name "wit-bindgen-0.46.0.crate")
           (sha256
            (base32 "0ngysw50gp2wrrfxbwgp6dhw1g6sckknsn3wm7l00vaf7n48aypi"))))
   (cons "davey-c7e468321c81"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/x25519-dalek/x25519-dalek-2.0.1.crate")
           (file-name "x25519-dalek-2.0.1.crate")
           (sha256
            (base32 "0xyjgqpsa0q6pprakdp58q1hy45rf8wnqqscgzx0gyw13hr6ir67"))))
   (cons "davey-668f5168d10b"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/zerocopy/zerocopy-0.8.33.crate")
           (file-name "zerocopy-0.8.33.crate")
           (sha256
            (base32 "1z9d6z8p1ndf0yrvw99jr5zcjnd4270kv4rivqqyi7hbs5l533v6"))))
   (cons "davey-2c7962b26b0a"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/zerocopy-derive/zerocopy-derive-0.8.33.crate")
           (file-name "zerocopy-derive-0.8.33.crate")
           (sha256
            (base32 "1wbh4bil3kqfmiwxlpzhxba6fyh09nsy87k7idk8b1hadfr64y9c"))))
   (cons "davey-b97154e67e32"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/zeroize/zeroize-1.8.2.crate")
           (file-name "zeroize-1.8.2.crate")
           (sha256
            (base32 "1l48zxgcv34d7kjskr610zqsm6j2b4fcr2vfh9jm9j1jgvk58wdr"))))
   (cons "davey-85a5b4158499"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/zeroize_derive/zeroize_derive-1.4.3.crate")
           (file-name "zeroize_derive-1.4.3.crate")
           (sha256
            (base32 "0bl5vd1lz27p4z336nximg5wrlw5j7jc8fxh7iv6r1wrhhav99c5"))))
   (cons "davey-ac93432f5b76"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/zmij/zmij-1.0.13.crate")
           (file-name "zmij-1.0.13.crate")
           (sha256
            (base32 "1v69z4425x3cpxzc793qfs3zvh559wjaqjkp9j3246vnbcpl74xc"))))
   (cons "firecrawl-anydoc-3e29460272fe"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/35/54/ee43b1661a954e53eaed85878a7ccc37ed73e02e6577bb26437ec5f9de94/firecrawl_anydoc-0.2.4.tar.gz")
           (file-name "firecrawl_anydoc-0.2.4.tar.gz")
           (sha256
            (base32 "0cihr1i27xv7k29xqk9135cz07qgdcgz2npx13g1ra7yf814ca9y"))))
   (cons "firecrawl-anydoc-320119579fca"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/adler2/adler2-2.0.1.crate")
           (file-name "adler2-2.0.1.crate")
           (sha256
            (base32 "1ymy18s9hs7ya1pjc9864l30wk8p2qfqdi7mhhcc5nfakxbij09j"))))
   (cons "firecrawl-anydoc-c982642fa9e8"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/aho-corasick/aho-corasick-1.1.5.crate")
           (file-name "aho-corasick-1.1.5.crate")
           (sha256
            (base32 "1fhjkp2nbs7gg4y1b68hpc8028rpax8aiscfh9b60q78m4pn90n9"))))
   (cons "firecrawl-anydoc-819e7219dbd4"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/android_system_properties/android_system_properties-0.1.5.crate")
           (file-name "android_system_properties-0.1.5.crate")
           (sha256
            (base32 "04b3wrz12837j7mdczqd95b732gw5q7q66cv4yn4646lvccp57l1"))))
   (cons "firecrawl-anydoc-824a212faf96"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/anstream/anstream-1.0.0.crate")
           (file-name "anstream-1.0.0.crate")
           (sha256
            (base32 "13d2bj0xfg012s4rmq44zc8zgy1q8k9yp7yhvfnarscnmwpj2jl2"))))
   (cons "firecrawl-anydoc-940b3a0ca603"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/anstyle/anstyle-1.0.14.crate")
           (file-name "anstyle-1.0.14.crate")
           (sha256
            (base32 "0030szmgj51fxkic1hpakxxgappxzwm6m154a3gfml83lq63l2wl"))))
   (cons "firecrawl-anydoc-52ce7f38b242"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/anstyle-parse/anstyle-parse-1.0.0.crate")
           (file-name "anstyle-parse-1.0.0.crate")
           (sha256
            (base32 "03hkv2690s0crssbnmfkr76kw1k7ah2i6s5amdy9yca2n8w7zkjj"))))
   (cons "firecrawl-anydoc-40c48f72fd53"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/anstyle-query/anstyle-query-1.1.5.crate")
           (file-name "anstyle-query-1.1.5.crate")
           (sha256
            (base32 "1p6shfpnbghs6jsa0vnqd8bb8gd7pjd0jr7w0j8jikakzmr8zi20"))))
   (cons "firecrawl-anydoc-291e6a250ff8"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/anstyle-wincon/anstyle-wincon-3.0.11.crate")
           (file-name "anstyle-wincon-3.0.11.crate")
           (sha256
            (base32 "0zblannm70sk3xny337mz7c6d8q8i24vhbqi42ld8v7q1wjnl7i9"))))
   (cons "firecrawl-anydoc-f2032f911046"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/autocfg/autocfg-1.5.1.crate")
           (file-name "autocfg-1.5.1.crate")
           (sha256
            (base32 "0lqasy5i30flcgih1b50kvsk6z32g09r1q4ql7q81pj6228jy0zj"))))
   (cons "firecrawl-anydoc-b588b76d00fd"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/bitflags/bitflags-2.13.1.crate")
           (file-name "bitflags-2.13.1.crate")
           (sha256
            (base32 "1nl76mpykmwmb8rq1l5vw1azdh1wvxdrnsk4sy3rdrzx01nvg25m"))))
   (cons "firecrawl-anydoc-d2f6c7dbe95a"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/block-buffer/block-buffer-0.12.1.crate")
           (file-name "block-buffer-0.12.1.crate")
           (sha256
            (base32 "1ak0cvmxz3yifqmzv6aba9606brsz7d5g3piv5xdcvjsx7dwgxnj"))))
   (cons "firecrawl-anydoc-a8894febbff9"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/block-padding/block-padding-0.3.3.crate")
           (file-name "block-padding-0.3.3.crate")
           (sha256
            (base32 "14wdad0r1qk5gmszxqd8cky6vx8qg7c153jv981mixzrpzmlz2d8"))))
   (cons "firecrawl-anydoc-72f5acc6cb2b"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/bumpalo/bumpalo-3.20.3.crate")
           (file-name "bumpalo-3.20.3.crate")
           (sha256
            (base32 "0jc6va3nwcqikm7chnpdv1s87my3gs2j7g1sc7g3k91brg3arxbj"))))
   (cons "firecrawl-anydoc-26b52a9543ae"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/cbc/cbc-0.1.2.crate")
           (file-name "cbc-0.1.2.crate")
           (sha256
            (base32 "19l9y9ccv1ffg6876hshd123f2f8v7zbkc4nkckqycxf8fajmd96"))))
   (cons "firecrawl-anydoc-5add81bb678e"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/cc/cc-1.4.0.crate")
           (file-name "cc-1.4.0.crate")
           (sha256
            (base32 "1fc26n76n7gr37m2q0xw5l8jpn4sd33hvyppmwhv6v4fcyxq3pas"))))
   (cons "firecrawl-anydoc-a347dcabdae9"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/cfb/cfb-0.14.0.crate")
           (file-name "cfb-0.14.0.crate")
           (sha256
            (base32 "1qzckkss8bym4rqq4iwwp2nc5jay53nqnspx4l41phz9vamxqix3"))))
   (cons "firecrawl-anydoc-d524456ba66e"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/chacha20/chacha20-0.10.1.crate")
           (file-name "chacha20-0.10.1.crate")
           (sha256
            (base32 "108aajbvs3rwl4d0pdvq3p8ydy4pwh0rxy2z265ynwkflrmla96m"))))
   (cons "firecrawl-anydoc-1aa79e62e769"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/chrono/chrono-0.4.45.crate")
           (file-name "chrono-0.4.45.crate")
           (sha256
            (base32 "09rkcgk6is2sdhqs9142zv8xqnj8ryx8m9hknllqwyv9wxi9x9qs"))))
   (cons "firecrawl-anydoc-1d07550c9036"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/colorchoice/colorchoice-1.0.5.crate")
           (file-name "colorchoice-1.0.5.crate")
           (sha256
            (base32 "0w75k89hw39p0mnnhlrwr23q50rza1yjki44qvh2mgrnj065a1qx"))))
   (cons "firecrawl-anydoc-4fe5f465a4f6"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/console/console-0.16.4.crate")
           (file-name "console-0.16.4.crate")
           (sha256
            (base32 "0z5sik90c39ywvkdkdc5bqrkbj441ycmvf21mn7yizpnlijz9rag"))))
   (cons "firecrawl-anydoc-a6ef517f0926"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/const-oid/const-oid-0.10.2.crate")
           (file-name "const-oid-0.10.2.crate")
           (sha256
            (base32 "0p7m286mp8aai4sa72g7ji6qm0d4ns8wg4i4b2hj9p9615zm3vx6"))))
   (cons "firecrawl-anydoc-affbf0190ed2"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/convert_case/convert_case-0.11.0.crate")
           (file-name "convert_case-0.11.0.crate")
           (sha256
            (base32 "0jfv1ajyr65bjlx533n5alfkfjdl8ks4zxfywdiz1jnj1qcz1yxg"))))
   (cons "firecrawl-anydoc-773648b94d0e"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/core-foundation-sys/core-foundation-sys-0.8.7.crate")
           (file-name "core-foundation-sys-0.8.7.crate")
           (sha256
            (base32 "12w8j73lazxmr1z0h98hf3z623kl8ms7g07jch7n4p8f9nwlhdkp"))))
   (cons "firecrawl-anydoc-8b2a41393f66"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/cpufeatures/cpufeatures-0.3.0.crate")
           (file-name "cpufeatures-0.3.0.crate")
           (sha256
            (base32 "00fjhygsqmh4kbxxlb99mcsbspxcai6hjydv4c46pwb67wwl2alb"))))
   (cons "firecrawl-anydoc-9481c1c90cbf"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/crc32fast/crc32fast-1.5.0.crate")
           (file-name "crc32fast-1.5.0.crate")
           (sha256
            (base32 "04d51liy8rbssra92p0qnwjw8i9rm9c4m3bwy19wjamz1k4w30cl"))))
   (cons "firecrawl-anydoc-5181e0de7b61"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/crossbeam-deque/crossbeam-deque-0.8.7.crate")
           (file-name "crossbeam-deque-0.8.7.crate")
           (sha256
            (base32 "1sqcxia1mmz2fw8ba1v72jjrvbkvg7c6sz9l3sl07sv1gggf10ai"))))
   (cons "firecrawl-anydoc-2d6914041f25"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/crossbeam-epoch/crossbeam-epoch-0.9.20.crate")
           (file-name "crossbeam-epoch-0.9.20.crate")
           (sha256
            (base32 "0gzg0v8in20iajikalg5i5qgpp0m26r426f0fs8nwk953w218s9d"))))
   (cons "firecrawl-anydoc-61803da095be"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/crossbeam-utils/crossbeam-utils-0.8.22.crate")
           (file-name "crossbeam-utils-0.8.22.crate")
           (sha256
            (base32 "05vwf7pmjq8c8f3fp5qqdm0z3cnk4p62wi8spf0jms5yjnh3v031"))))
   (cons "firecrawl-anydoc-ce6e4c961d6c"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/crypto-common/crypto-common-0.2.2.crate")
           (file-name "crypto-common-0.2.2.crate")
           (sha256
            (base32 "0lql5wjlrjkd3r0w32rwbgqfmgg84ms3h65ldnlckmkc3nb4qvnf"))))
   (cons "firecrawl-anydoc-52cd9d68cf7e"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/csv/csv-1.4.0.crate")
           (file-name "csv-1.4.0.crate")
           (sha256
            (base32 "0f7r2ip0rbi7k377c3xmsh9xd69sillffhpfmbgnvz3yrxl9vkaj"))))
   (cons "firecrawl-anydoc-704a3c26996a"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/csv-core/csv-core-0.1.13.crate")
           (file-name "csv-core-0.1.13.crate")
           (sha256
            (base32 "10lppd3fdb1i5npgx9xqjs5mjmy2qbdi8n16i48lg03ak4k3qjkh"))))
   (cons "firecrawl-anydoc-2d83cb7e7a87"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/ctor/ctor-1.0.12.crate")
           (file-name "ctor-1.0.12.crate")
           (sha256
            (base32 "0zypq22kn415hyv6gwjbl5pjqnbasf6af0kbimq30f47g9zcp0rd"))))
   (cons "firecrawl-anydoc-e2953bfe4f93"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/defmt/defmt-1.1.1.crate")
           (file-name "defmt-1.1.1.crate")
           (sha256
            (base32 "1lc8xlfj700xqjmvp7n9hhc1czgpaqkq960iqw6d5fwk9zz3p5g2"))))
   (cons "firecrawl-anydoc-bad9c72e7ca2"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/defmt-macros/defmt-macros-1.1.1.crate")
           (file-name "defmt-macros-1.1.1.crate")
           (sha256
            (base32 "1s2zkcbaj1l306ph1n1gsfm6vzc2sah4acl1qc6pw4x2ghpcgnds"))))
   (cons "firecrawl-anydoc-0e5f4244d641"
         (origin
           (method url-fetch)
           (uri "https://codeload.github.com/knurling-rs/defmt/tar.gz/4a8cdb44891ed57b8ff5a023b6bec7137c48708f")
           (file-name "knurling-rs-4a8cdb44891ed57b8ff5a023b6bec7137c48708f.tar.gz")
           (sha256
            (base32 "1z4v8xlrxdl4adh19k244ykzybhygrnchqy3dznhb0s1sr244pqf"))))
   (cons "firecrawl-anydoc-7cd812cc2bc1"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/deranged/deranged-0.5.8.crate")
           (file-name "deranged-0.5.8.crate")
           (sha256
            (base32 "0711df3w16vx80k55ivkwzwswziinj4dz05xci3rvmn15g615n3w"))))
   (cons "firecrawl-anydoc-f1dd6dbb5841"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/digest/digest-0.11.3.crate")
           (file-name "digest-0.11.3.crate")
           (sha256
            (base32 "1hnmhd4rkybr11292w42pz9ppzx1h49glrhqg107k4s1b2xnvpgi"))))
   (cons "firecrawl-anydoc-1a8bfa975b1a"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/ecb/ecb-0.1.2.crate")
           (file-name "ecb-0.1.2.crate")
           (sha256
            (base32 "1iw1i0mwkvg3599mlw24iibid6i6zv3a3jhghm2j3v0sbfbzm2qs"))))
   (cons "firecrawl-anydoc-9e5e8f6c15a2"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/either/either-1.17.0.crate")
           (file-name "either-1.17.0.crate")
           (sha256
            (base32 "07dagpwcfdzpkb1n7fxkx0q3nv80rnf81v7gwlz9ljx22mn8yply"))))
   (cons "firecrawl-anydoc-34aa73646ffb"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/encode_unicode/encode_unicode-1.0.0.crate")
           (file-name "encode_unicode-1.0.0.crate")
           (sha256
            (base32 "1h5j7j7byi289by63s3w4a8b3g6l5ccdrws7a67nn07vdxj77ail"))))
   (cons "firecrawl-anydoc-75030f3c4f45"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/encoding_rs/encoding_rs-0.8.35.crate")
           (file-name "encoding_rs-0.8.35.crate")
           (sha256
            (base32 "1wv64xdrr9v37rqqdjsyb8l8wzlcbab80ryxhrszvnj59wy0y0vm"))))
   (cons "firecrawl-anydoc-900d271a0379"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/env_filter/env_filter-2.0.0.crate")
           (file-name "env_filter-2.0.0.crate")
           (sha256
            (base32 "05s267np8pphhpxzrzl4j956gjj87f4ik6yas7l1x6kr0cd2f3ch"))))
   (cons "firecrawl-anydoc-de671bd27a75"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/env_logger/env_logger-0.11.11.crate")
           (file-name "env_logger-0.11.11.crate")
           (sha256
            (base32 "1xnkbhnlwf45a6val2340bi7avi7fwgbm2g2kbf9g9vmgb91nryy"))))
   (cons "firecrawl-anydoc-877a4ace8713"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/equivalent/equivalent-1.0.2.crate")
           (file-name "equivalent-1.0.2.crate")
           (sha256
            (base32 "03swzqznragy8n0x31lqc78g2af054jwivp7lkrbrc0khz74lyl7"))))
   (cons "firecrawl-anydoc-39cab71617ae"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/errno/errno-0.3.14.crate")
           (file-name "errno-0.3.14.crate")
           (sha256
            (base32 "1szgccmh8vgryqyadg8xd58mnwwicf39zmin3bsn63df2wbbgjir"))))
   (cons "firecrawl-anydoc-da7c62ceae20"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/fastrand/fastrand-2.5.0.crate")
           (file-name "fastrand-2.5.0.crate")
           (sha256
            (base32 "08q2r30y62winysimnlpbvw9kiwn0rmdlidqlmzd6z90mv764z6s"))))
   (cons "firecrawl-anydoc-5baebc077415"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/find-msvc-tools/find-msvc-tools-0.1.9.crate")
           (file-name "find-msvc-tools-0.1.9.crate")
           (sha256
            (base32 "10nmi0qdskq6l7zwxw5g56xny7hb624iki1c39d907qmfh3vrbjv"))))
   (cons "firecrawl-anydoc-843fba2746e4"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/flate2/flate2-1.1.9.crate")
           (file-name "flate2-1.1.9.crate")
           (sha256
            (base32 "0g2pb7cxnzcbzrj8bw4v6gpqqp21aycmf6d84rzb6j748qkvlgw4"))))
   (cons "firecrawl-anydoc-3f9eec918d3f"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/fnv/fnv-1.0.7.crate")
           (file-name "fnv-1.0.7.crate")
           (sha256
            (base32 "1hc2mcqha06aibcaza94vbi81j6pr9a1bbxrxjfhc91zin8yr7iz"))))
   (cons "firecrawl-anydoc-a88cf1f829d9"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/futures/futures-0.3.33.crate")
           (file-name "futures-0.3.33.crate")
           (sha256
            (base32 "066j5aqz8an05xh4hn5ljdnjn80z3g335v4grx4gaifr57wg3358"))))
   (cons "firecrawl-anydoc-262590f4fe6a"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/futures-channel/futures-channel-0.3.33.crate")
           (file-name "futures-channel-0.3.33.crate")
           (sha256
            (base32 "1bn5hlhfkl1sgypmiachaqcgwmr6wmjal7dyhfyb1zkazvs90996"))))
   (cons "firecrawl-anydoc-2cd50c473c80"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/futures-core/futures-core-0.3.33.crate")
           (file-name "futures-core-0.3.33.crate")
           (sha256
            (base32 "1iqdbvcdlplfr2g43h7xrfkv2sg5p1a26x8acz1xgxl07i3hrm9c"))))
   (cons "firecrawl-anydoc-6754879cc9f2"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/futures-executor/futures-executor-0.3.33.crate")
           (file-name "futures-executor-0.3.33.crate")
           (sha256
            (base32 "0n3lpkmcfrsnh40i4armn040gnqbpd257hz5qs46zipjr6f8fm37"))))
   (cons "firecrawl-anydoc-4577ecaa3c4f"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/futures-io/futures-io-0.3.33.crate")
           (file-name "futures-io-0.3.33.crate")
           (sha256
            (base32 "0yjx13qdm9b2p4w00ddw85k6yccnnmqrlrrz8yfmi5jg7jmfqxs5"))))
   (cons "firecrawl-anydoc-2d6d3cde68c5"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/futures-macro/futures-macro-0.3.33.crate")
           (file-name "futures-macro-0.3.33.crate")
           (sha256
            (base32 "02xiyd5y1nk9b805aympj4wq2czgvxnhcml9w9xkc665d3g3qv9d"))))
   (cons "firecrawl-anydoc-e34418ac499d"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/futures-sink/futures-sink-0.3.33.crate")
           (file-name "futures-sink-0.3.33.crate")
           (sha256
            (base32 "01z38z344hpryw84b6r0rbwcb669d8pyvl2szg10aqwx96n1hi73"))))
   (cons "firecrawl-anydoc-b231ed28831e"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/futures-task/futures-task-0.3.33.crate")
           (file-name "futures-task-0.3.33.crate")
           (sha256
            (base32 "02f1y1yvjg1cv998zkgl1706pi9y4fyc9045l1hlmyqyhclfscdj"))))
   (cons "firecrawl-anydoc-a77a90a256fc"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/futures-util/futures-util-0.3.33.crate")
           (file-name "futures-util-0.3.33.crate")
           (sha256
            (base32 "1anyg40j5www5l22r2jbn1birsafz4q1w9qmcjk4vqzwasi90ym7"))))
   (cons "firecrawl-anydoc-300e883d756b"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/getrandom/getrandom-0.4.3.crate")
           (file-name "getrandom-0.4.3.crate")
           (sha256
            (base32 "16b0202fkdwz3p2cyll82dv24ljbn0wiyy829v4lwbkbflyqh3ih"))))
   (cons "firecrawl-anydoc-ed5909b6e89a"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/hashbrown/hashbrown-0.17.1.crate")
           (file-name "hashbrown-0.17.1.crate")
           (sha256
            (base32 "0jmqz7i4yl6cm7rbn0i2ffkfrmwi6xkmzkaldr2v8bcsx2v0jngd"))))
   (cons "firecrawl-anydoc-707114b52a15"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/hybrid-array/hybrid-array-0.4.14.crate")
           (file-name "hybrid-array-0.4.14.crate")
           (sha256
            (base32 "0srzagwa3b41ildy4x3d7ckng51dj7aprkchnaysfbqm5asi8wbh"))))
   (cons "firecrawl-anydoc-e31bc9ad994b"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/iana-time-zone/iana-time-zone-0.1.65.crate")
           (file-name "iana-time-zone-0.1.65.crate")
           (sha256
            (base32 "0w64khw5p8s4nzwcf36bwnsmqzf61vpwk9ca1920x82bk6nwj6z3"))))
   (cons "firecrawl-anydoc-f31827a206f5"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/iana-time-zone-haiku/iana-time-zone-haiku-0.1.2.crate")
           (file-name "iana-time-zone-haiku-0.1.2.crate")
           (sha256
            (base32 "17r6jmj31chn7xs9698r122mapq85mfnv98bb4pg6spm0si2f67k"))))
   (cons "firecrawl-anydoc-69bc614f22f8"
         (origin
           (method url-fetch)
           (uri "https://codeload.github.com/Michael-F-Bryan/include_dir/tar.gz/d742c6fffce99ee89da91b934e7ce6fb2a82680c")
           (file-name "Michael-F-Bryan-d742c6fffce99ee89da91b934e7ce6fb2a82680c.tar.gz")
           (sha256
            (base32 "019v4vzzib0g0isda6lib4s4ycc78ppldq2bb7zhwzpq497n3g39"))))
   (cons "firecrawl-anydoc-d466e9454f08"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/indexmap/indexmap-2.14.0.crate")
           (file-name "indexmap-2.14.0.crate")
           (sha256
            (base32 "1na9z6f0d5pkjr1lgsni470v98gv2r7c41j8w48skr089x2yjrnl"))))
   (cons "firecrawl-anydoc-86f0f8fee8c9"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/insta/insta-1.48.0.crate")
           (file-name "insta-1.48.0.crate")
           (sha256
            (base32 "10kbxza7vzj4nvkga8r3rfn6z8i3hnh47bnnb1f429n9x3zgiw46"))))
   (cons "firecrawl-anydoc-a6cb138bb79a"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/is_terminal_polyfill/is_terminal_polyfill-1.70.2.crate")
           (file-name "is_terminal_polyfill-1.70.2.crate")
           (sha256
            (base32 "15anlc47sbz0jfs9q8fhwf0h3vs2w4imc030shdnq54sny5i7jx6"))))
   (cons "firecrawl-anydoc-8f42a60cbdf9"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/itoa/itoa-1.0.18.crate")
           (file-name "itoa-1.0.18.crate")
           (sha256
            (base32 "10jnd1vpfkb8kj38rlkn2a6k02afvj3qmw054dfpzagrpl6achlg"))))
   (cons "firecrawl-anydoc-668b7183bd07"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/jiff/jiff-0.2.35.crate")
           (file-name "jiff-0.2.35.crate")
           (sha256
            (base32 "1k1d1n8k46192xz6ph8km43lcg68ql65phzmhm49mbq7pn1p32v6"))))
   (cons "firecrawl-anydoc-7feca88439ef"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/jiff-core/jiff-core-0.1.0.crate")
           (file-name "jiff-core-0.1.0.crate")
           (sha256
            (base32 "02axx56pkh2w4bw5rp94qlvcpwzd3n2w2025fnikvrgg762aiv3z"))))
   (cons "firecrawl-anydoc-3a69dcb3a21c"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/jiff-static/jiff-static-0.2.35.crate")
           (file-name "jiff-static-0.2.35.crate")
           (sha256
            (base32 "014jli8v46c8hzkndmvdfvq4la6a6y9icmnh3k735yqwlarxqs9s"))))
   (cons "firecrawl-anydoc-142bd39932ad"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/jiff-tzdb/jiff-tzdb-0.1.8.crate")
           (file-name "jiff-tzdb-0.1.8.crate")
           (sha256
            (base32 "07hl9sgzfb9as1x0n5bjk1qxishzcriapy9xa481y8xd6acx6aql"))))
   (cons "firecrawl-anydoc-875a5a69ac2b"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/jiff-tzdb-platform/jiff-tzdb-platform-0.1.3.crate")
           (file-name "jiff-tzdb-platform-0.1.3.crate")
           (sha256
            (base32 "1s1ja692wyhbv7f60mc0x90h7kn1pv65xkqi2y4imarbmilmlnl7"))))
   (cons "firecrawl-anydoc-53b44bfcdb3f"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/js-sys/js-sys-0.3.103.crate")
           (file-name "js-sys-0.3.103.crate")
           (sha256
            (base32 "00lib0b6hqmw56r2hjp7xrv730qacslirbkdlhvmi39zvgy4pd2k"))))
   (cons "firecrawl-anydoc-3eaf3ede3fee"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/libc/libc-0.2.189.crate")
           (file-name "libc-0.2.189.crate")
           (sha256
            (base32 "1whjfs375vlng2q6yrbzs73cvp5lm3w1n2gfqajb2vgf7zg3xbry"))))
   (cons "firecrawl-anydoc-32a66949e030"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/linux-raw-sys/linux-raw-sys-0.12.1.crate")
           (file-name "linux-raw-sys-0.12.1.crate")
           (sha256
            (base32 "0lwasljrqxjjfk9l2j8lyib1babh2qjlnhylqzl01nihw14nk9ij"))))
   (cons "firecrawl-anydoc-0ceec5bc1177"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/log/log-0.4.33.crate")
           (file-name "log-0.4.33.crate")
           (sha256
            (base32 "1bd9dmk22pxgnf0h0slba6rz99zb0a0b2mdhpk8p92bp26ycbvhc"))))
   (cons "firecrawl-anydoc-25aab26d9956"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/lopdf/lopdf-0.42.0.crate")
           (file-name "lopdf-0.42.0.crate")
           (sha256
            (base32 "0712gb1xrwnq67xfwqqj8336b2czcx12z834iq4njx2nk5nv5ai5"))))
   (cons "firecrawl-anydoc-d89e7ee0cfbe"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/md-5/md-5-0.10.6.crate")
           (file-name "md-5-0.10.6.crate")
           (sha256
            (base32 "1kvq5rnpm4fzwmyv5nmnxygdhhb2369888a06gdc9pxyrzh7x7nq"))))
   (cons "firecrawl-anydoc-cf8baf1c55e6"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/memchr/memchr-2.8.3.crate")
           (file-name "memchr-2.8.3.crate")
           (sha256
            (base32 "161xa63ipfanf8v3nb82xd5hqgydv55nzw59wyngqbz6alfaz2yg"))))
   (cons "firecrawl-anydoc-1fa76a2c86f7"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/miniz_oxide/miniz_oxide-0.8.9.crate")
           (file-name "miniz_oxide-0.8.9.crate")
           (sha256
            (base32 "05k3pdg8bjjzayq3rf0qhpirq9k37pxnasfn4arbs17phqn6m9qz"))))
   (cons "firecrawl-anydoc-c08da0431634"
         (origin
           (method url-fetch)
           (uri "https://codeload.github.com/napi-rs/napi-rs/tar.gz/58bd87fa524a837a7c962ab4103e5588557ccd81")
           (file-name "napi-rs-58bd87fa524a837a7c962ab4103e5588557ccd81.tar.gz")
           (sha256
            (base32 "02bmzdmmm0xgdv5d07bi9b8wb5zxjs6r43vx62dzb7il2r1s13f0"))))
   (cons "firecrawl-anydoc-1b6802e3e363"
         (origin
           (method url-fetch)
           (uri "https://codeload.github.com/napi-rs/napi-rs/tar.gz/e8e3bffa2dfa77a34b8c9cbd42ea4bfef0c29729")
           (file-name "napi-rs-e8e3bffa2dfa77a34b8c9cbd42ea4bfef0c29729.tar.gz")
           (sha256
            (base32 "1agi5w9clf0p73g29cf211wdfxh2g4ac8dxmbi4v80b3wgih4s0v"))))
   (cons "firecrawl-anydoc-5cea491b170c"
         (origin
           (method url-fetch)
           (uri "https://codeload.github.com/napi-rs/napi-rs/tar.gz/679eb79f5cf3c7c6b2850f4ab46092126f23dc5c")
           (file-name "napi-rs-679eb79f5cf3c7c6b2850f4ab46092126f23dc5c.tar.gz")
           (sha256
            (base32 "04v4gc617qdz2gn6lack6634083j5h9laayg8qhhrn8c2wdlksjw"))))
   (cons "firecrawl-anydoc-df9761775871"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/nom/nom-8.0.0.crate")
           (file-name "nom-8.0.0.crate")
           (sha256
            (base32 "01cl5xng9d0gxf26h39m0l8lprgpa00fcc75ps1yzgbib1vn35yz"))))
   (cons "firecrawl-anydoc-521739c6d2ba"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/num-conv/num-conv-0.2.2.crate")
           (file-name "num-conv-0.2.2.crate")
           (sha256
            (base32 "0hg4f9bwmy7cwpxdkm165dmkfc8jhkkayci234jsmi5ssb33j5sj"))))
   (cons "firecrawl-anydoc-9f7c3e4beb33"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/once_cell/once_cell-1.21.4.crate")
           (file-name "once_cell-1.21.4.crate")
           (sha256
            (base32 "0l1v676wf71kjg2khch4dphwh1jp3291ffiymr2mvy1kxd5kwz4z"))))
   (cons "firecrawl-anydoc-384b8ab6d372"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/once_cell_polyfill/once_cell_polyfill-1.70.2.crate")
           (file-name "once_cell_polyfill-1.70.2.crate")
           (sha256
            (base32 "1zmla628f0sk3fhjdjqzgxhalr2xrfna958s632z65bjsfv8ljrq"))))
   (cons "firecrawl-anydoc-1e024ae242c5"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/pdf-inspector/pdf-inspector-1.14.2.crate")
           (file-name "pdf-inspector-1.14.2.crate")
           (sha256
            (base32 "1jwkhm4v90b831cj3fygbqpdraqfirkqdqdfysny45658bi4l0hy"))))
   (cons "firecrawl-anydoc-a89322df9ebe"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/pin-project-lite/pin-project-lite-0.2.17.crate")
           (file-name "pin-project-lite-0.2.17.crate")
           (sha256
            (base32 "1kfmwvs271si96zay4mm8887v5khw0c27jc9srw1a75ykvgj54x8"))))
   (cons "firecrawl-anydoc-3d20d5497ef8"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/portable-atomic/portable-atomic-1.14.0.crate")
           (file-name "portable-atomic-1.14.0.crate")
           (sha256
            (base32 "1hyfma9n2cs2ibazpfwrbv61zwg7cv86g0pr5yjkg07qgr4xa81x"))))
   (cons "firecrawl-anydoc-c2a106d1259c"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/portable-atomic-util/portable-atomic-util-0.2.7.crate")
           (file-name "portable-atomic-util-0.2.7.crate")
           (sha256
            (base32 "0616j0fhy6y71hyxg3n86f6hng0fmsc269s3wp4gl8ww4p8hd8f2"))))
   (cons "firecrawl-anydoc-439ee305def1"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/powerfmt/powerfmt-0.2.0.crate")
           (file-name "powerfmt-0.2.0.crate")
           (sha256
            (base32 "14ckj2xdpkhv3h6l5sdmb9f1d57z8hbfpdldjc2vl5givq2y77j3"))))
   (cons "firecrawl-anydoc-985e7ec9bb74"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/proc-macro2/proc-macro2-1.0.107.crate")
           (file-name "proc-macro2-1.0.107.crate")
           (sha256
            (base32 "1nb6ly8kp65f724kj73ippc7lvydss24sm2vagk6qpklpg4pwplq"))))
   (cons "firecrawl-anydoc-fc153f5fd745"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/pyo3/pyo3-0.29.1.crate")
           (file-name "pyo3-0.29.1.crate")
           (sha256
            (base32 "0ad73lmm3wmapsbbqmsahcwqm7wn4lhn51pdbs5h7k25sxgky5gw"))))
   (cons "firecrawl-anydoc-bb77d9aa6d64"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/pyo3-build-config/pyo3-build-config-0.29.1.crate")
           (file-name "pyo3-build-config-0.29.1.crate")
           (sha256
            (base32 "1lb43rcmhzvmv1nvrw4gqwkcb13d4r6p3vk9bjshfxb4dnmdjxxv"))))
   (cons "firecrawl-anydoc-3160087aa573"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/pyo3-ffi/pyo3-ffi-0.29.1.crate")
           (file-name "pyo3-ffi-0.29.1.crate")
           (sha256
            (base32 "0lr2fbqbzvlf2w9rd8228yvm6ajsz1aqr7vjk9ywwfvklmx0hq1i"))))
   (cons "firecrawl-anydoc-91f9d455db76"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/pyo3-macros/pyo3-macros-0.29.1.crate")
           (file-name "pyo3-macros-0.29.1.crate")
           (sha256
            (base32 "1mfl831nzb3w2agxmyrxlxms7f4h2dgw5any1l5rl2knvdax9yci"))))
   (cons "firecrawl-anydoc-e343bcec300f"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/pyo3-macros-backend/pyo3-macros-backend-0.29.1.crate")
           (file-name "pyo3-macros-backend-0.29.1.crate")
           (sha256
            (base32 "098nb295bsc3rcpm2ps38s57l2bd3gjs8cvah3sn5whg63nbqhz3"))))
   (cons "firecrawl-anydoc-e660451e5512"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/quick-xml/quick-xml-0.41.0.crate")
           (file-name "quick-xml-0.41.0.crate")
           (sha256
            (base32 "1h9y8zry34r3mxfd5vqfj50vvvzvri4kzbx5d657jkqjalg4aq76"))))
   (cons "firecrawl-anydoc-1fbf4db142a4"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/quote/quote-1.0.47.crate")
           (file-name "quote-1.0.47.crate")
           (sha256
            (base32 "00ch0yyzvv6s671ik0kcsbw8nigdaj2g3fr61kcahwx48aqlvgqz"))))
   (cons "firecrawl-anydoc-c7f5fa3a058c"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/rand/rand-0.10.2.crate")
           (file-name "rand-0.10.2.crate")
           (sha256
            (base32 "105yqkdzqbgggd3r1yjm9jg0zvibfdsmxylvxxkmblwc0lxgmxf7"))))
   (cons "firecrawl-anydoc-63b8176103e1"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/rand_core/rand_core-0.10.1.crate")
           (file-name "rand_core-0.10.1.crate")
           (sha256
            (base32 "0s9wiacxrr100icl7i41308gcj85nlcclrc5jx1jd6p10dhigf33"))))
   (cons "firecrawl-anydoc-973443cf09a9"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/rangemap/rangemap-1.7.1.crate")
           (file-name "rangemap-1.7.1.crate")
           (sha256
            (base32 "0s7am2w72siggn668h03gn3g06gsinv6m1jaaxmnbj59177l6d4p"))))
   (cons "firecrawl-anydoc-fb39b166781f"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/rayon/rayon-1.12.0.crate")
           (file-name "rayon-1.12.0.crate")
           (sha256
            (base32 "0vcj63xgnk72c30vdrak7dhl53snnaqv9x2faf1d94hzg1kb2fgv"))))
   (cons "firecrawl-anydoc-f020237b6c8e"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/regex/regex-1.13.1.crate")
           (file-name "regex-1.13.1.crate")
           (sha256
            (base32 "1391a0a4100ik8cp7l577p3ip3haqq03rd9c5vdr7vcfdixj687h"))))
   (cons "firecrawl-anydoc-8fcfdb36bda0"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/regex-automata/regex-automata-0.4.16.crate")
           (file-name "regex-automata-0.4.16.crate")
           (sha256
            (base32 "1b8ihxq99g3hr8mr37bvhib4bfn8rlmpmp0wjg2q1j50plvdpkwg"))))
   (cons "firecrawl-anydoc-d6f6ff9a3784"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/regex-syntax/regex-syntax-0.8.11.crate")
           (file-name "regex-syntax-0.8.11.crate")
           (sha256
            (base32 "1m25h5q2wp976fb9gc3dsc9l99svcvd5cri8lncb51c46ydgzxnn"))))
   (cons "firecrawl-anydoc-6b1e7f9a4285"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/rustc-hash/rustc-hash-2.1.3.crate")
           (file-name "rustc-hash-2.1.3.crate")
           (sha256
            (base32 "0bbla578m87qmf3yr55q49l97gxn7z0ha1dwqlnvwwc58ad7y7kb"))))
   (cons "firecrawl-anydoc-b6fe4565b951"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/rustix/rustix-1.1.4.crate")
           (file-name "rustix-1.1.4.crate")
           (sha256
            (base32 "14511f9yjqh0ix07xjrjpllah3325774gfwi9zpq72sip5jlbzmn"))))
   (cons "firecrawl-anydoc-cf54715a573b"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/rustversion/rustversion-1.0.23.crate")
           (file-name "rustversion-1.0.23.crate")
           (sha256
            (base32 "07z2a843fs80fawwflj9jwn49k9b0bd0dhhbvy0ar69vaxd72m6g"))))
   (cons "firecrawl-anydoc-9774ba4a74de"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/ryu/ryu-1.0.23.crate")
           (file-name "ryu-1.0.23.crate")
           (sha256
            (base32 "0zs70sg00l2fb9jwrf6cbkdyscjs53anrvai2hf7npyyfi5blx4p"))))
   (cons "firecrawl-anydoc-8a7852d02fc8"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/semver/semver-1.0.28.crate")
           (file-name "semver-1.0.28.crate")
           (sha256
            (base32 "1kaimrpy876bcgi8bfj0qqfxk77zm9iz2zhn1hp9hj685z854y4a"))))
   (cons "firecrawl-anydoc-4148590afeba"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/serde/serde-1.0.229.crate")
           (file-name "serde-1.0.229.crate")
           (sha256
            (base32 "1fp04fq4a79bpm61xz1zy0pbz4kpc7d771zii1k3inmszq55jj21"))))
   (cons "firecrawl-anydoc-8302e169f0ed"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/serde-wasm-bindgen/serde-wasm-bindgen-0.6.5.crate")
           (file-name "serde-wasm-bindgen-0.6.5.crate")
           (sha256
            (base32 "0sz1l4v8059hiizf5z7r2spm6ws6sqcrs4qgqwww3p7dy1ly20l3"))))
   (cons "firecrawl-anydoc-67dca2c9c51e"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/serde_core/serde_core-1.0.229.crate")
           (file-name "serde_core-1.0.229.crate")
           (sha256
            (base32 "0j1ajiha76h3nmd976il9li6975k121xa7jb39ws8n0yqp4s5p37"))))
   (cons "firecrawl-anydoc-e7a5d71263a5"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/serde_derive/serde_derive-1.0.229.crate")
           (file-name "serde_derive-1.0.229.crate")
           (sha256
            (base32 "0j4k63i7h1bikxwz2c89ig0hrwbnl9mz1czn85xx99x5cc9dg9g7"))))
   (cons "firecrawl-anydoc-446ba7175095"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/sha2/sha2-0.11.0.crate")
           (file-name "sha2-0.11.0.crate")
           (sha256
            (base32 "1x15x22c5yf54ac0np5bfqnq5x0hdw4wqzpi48zwn94ma0bsfss4"))))
   (cons "firecrawl-anydoc-f8fadd59c855"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/shlex/shlex-2.0.1.crate")
           (file-name "shlex-2.0.1.crate")
           (sha256
            (base32 "1fjsll1cd7d2bcpdij9kd6w62rpbc7qqzvydvs021vsmr1cxvypq"))))
   (cons "firecrawl-anydoc-3a219298ac11"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/simd-adler32/simd-adler32-0.3.10.crate")
           (file-name "simd-adler32-0.3.10.crate")
           (sha256
            (base32 "1sny4y2qa5mwyxx5x59ln2p02vsdh92004njlslnx98imjc9489s"))))
   (cons "firecrawl-anydoc-bbbb5d965914"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/similar/similar-2.7.0.crate")
           (file-name "similar-2.7.0.crate")
           (sha256
            (base32 "1aidids7ymfr96s70232s6962v5g9l4zwhkvcjp4c5hlb6b5vfxv"))))
   (cons "firecrawl-anydoc-0c790de23124"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/slab/slab-0.4.12.crate")
           (file-name "slab-0.4.12.crate")
           (sha256
            (base32 "1xcwik6s6zbd3lf51kkrcicdq2j4c1fw0yjdai2apy9467i0sy8c"))))
   (cons "firecrawl-anydoc-7b4df3d392d8"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/stringprep/stringprep-0.1.5.crate")
           (file-name "stringprep-0.1.5.crate")
           (sha256
            (base32 "1cb3jis4h2b767csk272zw92lc6jzfzvh8d6m1cd86yqjb9z6kbv"))))
   (cons "firecrawl-anydoc-872831b642d1"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/syn/syn-2.0.119.crate")
           (file-name "syn-2.0.119.crate")
           (sha256
            (base32 "15vjy620l91a3q4n4f4gzhnflmdr6pnm38v2m6cpk86i8av32a47"))))
   (cons "firecrawl-anydoc-53e9bae58849"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/syn/syn-3.0.3.crate")
           (file-name "syn-3.0.3.crate")
           (sha256
            (base32 "18srnql3cd39j9q6hf1az02p67rlr1rf6njx9zx4vxj9i3jvmsak"))))
   (cons "firecrawl-anydoc-adb6935a6f5c"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/target-lexicon/target-lexicon-0.13.5.crate")
           (file-name "target-lexicon-0.13.5.crate")
           (sha256
            (base32 "1jm6lmf9hsn7ri2d6v9gg6fy24lylhskh6pbxh71f82wdxd97dmd"))))
   (cons "firecrawl-anydoc-32497e9a4c7b"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/tempfile/tempfile-3.27.0.crate")
           (file-name "tempfile-3.27.0.crate")
           (sha256
            (base32 "1gblhnyfjsbg9wjg194n89wrzah7jy3yzgnyzhp56f3v9jd7wj9j"))))
   (cons "firecrawl-anydoc-09a43598840e"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/thiserror/thiserror-2.0.19.crate")
           (file-name "thiserror-2.0.19.crate")
           (sha256
            (base32 "1ngwxsjsa64v1n7vb90h2b0i3fqk1piwaf0z6fqdacqfhjc3b909"))))
   (cons "firecrawl-anydoc-43cbfe0cf761"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/thiserror-impl/thiserror-impl-2.0.19.crate")
           (file-name "thiserror-impl-2.0.19.crate")
           (sha256
            (base32 "1ka10pqy1g8zy5al9m8yadg30jp8hx0q80j8awmd8131yw6gxjs3"))))
   (cons "firecrawl-anydoc-cdb87b95ec50"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/time/time-0.3.55.crate")
           (file-name "time-0.3.55.crate")
           (sha256
            (base32 "0d6iyws47z50zlksf5m3cflxvjrcgfhjglhn112gmpahxjappf6d"))))
   (cons "firecrawl-anydoc-9e1c906769ad"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/time-core/time-core-0.1.9.crate")
           (file-name "time-core-0.1.9.crate")
           (sha256
            (base32 "028ix0ax7ixp1h1k5zsqwgw85w6y1q32irslma7ci6ddd5kr074y"))))
   (cons "firecrawl-anydoc-7e689342a48d"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/time-macros/time-macros-0.2.32.crate")
           (file-name "time-macros-0.2.32.crate")
           (sha256
            (base32 "11gdd3b81mj8i0h114qfjjzm8j2rz2mhr9byr0ksjbldli196s3y"))))
   (cons "firecrawl-anydoc-bb4ebadaa0af"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/tinyvec/tinyvec-1.12.0.crate")
           (file-name "tinyvec-1.12.0.crate")
           (sha256
            (base32 "0zxaid976y60f4722vjhfnwcbydmzpwva7p03aqzl15gl3dblkmv"))))
   (cons "firecrawl-anydoc-1f3ccbac311f"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/tinyvec_macros/tinyvec_macros-0.1.1.crate")
           (file-name "tinyvec_macros-0.1.1.crate")
           (sha256
            (base32 "081gag86208sc3y6sdkshgw3vysm5d34p431dzw0bshz66ncng0z"))))
   (cons "firecrawl-anydoc-d2df906b0785"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/ttf-parser/ttf-parser-0.25.1.crate")
           (file-name "ttf-parser-0.25.1.crate")
           (sha256
            (base32 "0cbgqglcwwjg3hirwq6xlza54w04mb5x02kf7zx4hrw50xmr1pyj"))))
   (cons "firecrawl-anydoc-8e28f89b80c8"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/typed-path/typed-path-0.12.3.crate")
           (file-name "typed-path-0.12.3.crate")
           (sha256
            (base32 "03k051dafrnyg3lbm4c85zg0mpfhbn6l9aq4ryq8yyy8h2dzha4f"))))
   (cons "firecrawl-anydoc-b6f5e870be6c"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/typenum/typenum-1.20.1.crate")
           (file-name "typenum-1.20.1.crate")
           (sha256
            (base32 "086s9ly0906kw5yw41249fba97w5zfxf03pyfwdkffvcprqfixdn"))))
   (cons "firecrawl-anydoc-5c1cb5db3915"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/unicode-bidi/unicode-bidi-0.3.18.crate")
           (file-name "unicode-bidi-0.3.18.crate")
           (sha256
            (base32 "1xcxwbsqa24b8vfchhzyyzgj0l6bn51ib5v8j6krha0m77dva72w"))))
   (cons "firecrawl-anydoc-e6e4313cd5fc"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/unicode-ident/unicode-ident-1.0.24.crate")
           (file-name "unicode-ident-1.0.24.crate")
           (sha256
            (base32 "0xfs8y1g7syl2iykji8zk5hgfi5jw819f5zsrbaxmlzwsly33r76"))))
   (cons "firecrawl-anydoc-5fd4f6878c9c"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/unicode-normalization/unicode-normalization-0.1.25.crate")
           (file-name "unicode-normalization-0.1.25.crate")
           (sha256
            (base32 "1s76dcrxw7vs32yhpi0p074apdc3s7lak7809f3qvclwij3zdm2z"))))
   (cons "firecrawl-anydoc-7df058c71384"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/unicode-properties/unicode-properties-0.1.4.crate")
           (file-name "unicode-properties-0.1.4.crate")
           (sha256
            (base32 "07fpm3sqq7lm9gmgpxa93z31q933h3c3ypfwy4cdh6l42g3miw3x"))))
   (cons "firecrawl-anydoc-c6f5d3c3b1bf"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/unicode-segmentation/unicode-segmentation-1.13.3.crate")
           (file-name "unicode-segmentation-1.13.3.crate")
           (sha256
            (base32 "1a47zaq83p386r3baq4m018xd5q4q0grdg56i1x042dzn71x7xf6"))))
   (cons "firecrawl-anydoc-06abde361165"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/utf8parse/utf8parse-0.2.2.crate")
           (file-name "utf8parse-0.2.2.crate")
           (sha256
            (base32 "088807qwjq46azicqwbhlmzwrbkz7l4hpw43sdkdyyk524vdxaq6"))))
   (cons "firecrawl-anydoc-bf3923a6f5c4"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/uuid/uuid-1.24.0.crate")
           (file-name "uuid-1.24.0.crate")
           (sha256
            (base32 "0faj5x0zgri8m3i8dv9qgyhiwqwdyhbl2g351cp3iin4ynk26fdz"))))
   (cons "firecrawl-anydoc-4b067c0c1109"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/wasm-bindgen/wasm-bindgen-0.2.126.crate")
           (file-name "wasm-bindgen-0.2.126.crate")
           (sha256
            (base32 "197rma4qg1kb8l4bl7857pgszzval8s1w740g9myyjh92467q1jb"))))
   (cons "firecrawl-anydoc-167ce5e579f6"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/wasm-bindgen-macro/wasm-bindgen-macro-0.2.126.crate")
           (file-name "wasm-bindgen-macro-0.2.126.crate")
           (sha256
            (base32 "1cda6wl5zyiy7777cfgrix7fhpaqba55l5zpqj4zig7ng7jyaz0n"))))
   (cons "firecrawl-anydoc-f3997c783926"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/wasm-bindgen-macro-support/wasm-bindgen-macro-support-0.2.126.crate")
           (file-name "wasm-bindgen-macro-support-0.2.126.crate")
           (sha256
            (base32 "03iq412frl2py55skwb3ya08xha0cf6q22zr5kqlwbr675w7r6gk"))))
   (cons "firecrawl-anydoc-dc1b4cb0cc54"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/wasm-bindgen-shared/wasm-bindgen-shared-0.2.126.crate")
           (file-name "wasm-bindgen-shared-0.2.126.crate")
           (sha256
            (base32 "097a3kbjls447s1lwr41l21x5crrh5vq3h6zsxccz7slrjq4q6yw"))))
   (cons "firecrawl-anydoc-5a6580f308b1"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/web-time/web-time-1.1.0.crate")
           (file-name "web-time-1.1.0.crate")
           (sha256
            (base32 "1fx05yqx83dhx628wb70fyy10yjfq1jpl20qfqhdkymi13rq0ras"))))
   (cons "firecrawl-anydoc-a28ac98ddc8b"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/weezl/weezl-0.1.12.crate")
           (file-name "weezl-0.1.12.crate")
           (sha256
            (base32 "122a1dhha6cib5az4ihcqlh60ns2bi6rskdv875p94lbvj6wk2m2"))))
   (cons "firecrawl-anydoc-b8e83a14d34d"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/windows-core/windows-core-0.62.2.crate")
           (file-name "windows-core-0.62.2.crate")
           (sha256
            (base32 "1swxpv1a8qvn3bkxv8cn663238h2jccq35ff3nsj61jdsca3ms5q"))))
   (cons "firecrawl-anydoc-053e2e040ab5"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/windows-implement/windows-implement-0.60.2.crate")
           (file-name "windows-implement-0.60.2.crate")
           (sha256
            (base32 "1psxhmklzcf3wjs4b8qb42qb6znvc142cb5pa74rsyxm1822wgh5"))))
   (cons "firecrawl-anydoc-3f316c4a2570"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/windows-interface/windows-interface-0.59.3.crate")
           (file-name "windows-interface-0.59.3.crate")
           (sha256
            (base32 "0n73cwrn4247d0axrk7gjp08p34x1723483jxjxjdfkh4m56qc9z"))))
   (cons "firecrawl-anydoc-7781fa89eaf6"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/windows-result/windows-result-0.4.1.crate")
           (file-name "windows-result-0.4.1.crate")
           (sha256
            (base32 "1d9yhmrmmfqh56zlj751s5wfm9a2aa7az9rd7nn5027nxa4zm0bp"))))
   (cons "firecrawl-anydoc-7837d08f69c7"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/windows-strings/windows-strings-0.5.1.crate")
           (file-name "windows-strings-0.5.1.crate")
           (sha256
            (base32 "14bhng9jqv4fyl7lqjz3az7vzh8pw0w4am49fsqgcz67d67x0dvq"))))
   (cons "firecrawl-anydoc-2d04a6b53815"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/zip/zip-8.6.0.crate")
           (file-name "zip-8.6.0.crate")
           (sha256
            (base32 "16w0aiqiymyy6kjri0aykkmh45pbk6a6ck69hxhal0hm72ssc11d"))))
   (cons "firecrawl-anydoc-b142a20ec14a"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/zlib-rs/zlib-rs-0.6.6.crate")
           (file-name "zlib-rs-0.6.6.crate")
           (sha256
            (base32 "1i82vmjklrrmjsiayxxav09h2m8c10dw47ccf2ydb4aaq47a4hmi"))))
   (cons "firecrawl-anydoc-f05cd8797d63"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/zopfli/zopfli-0.8.3.crate")
           (file-name "zopfli-0.8.3.crate")
           (sha256
            (base32 "0jaj5dyh3mks0805h4ldrsh5pwq4i2jc9dc9zwjm91k3gmwxhp7h"))))
   (cons "obstore-db6dafed288e"
         (origin
           (method url-fetch)
           (uri "https://raw.githubusercontent.com/developmentseed/obstore/fbaeb7fa772f21e9b8f54b7eeb1f19a3f5b07336/LICENSE")
           (file-name "LICENSE")
           (sha256
            (base32 "0ybp6c2b2xk3r2rfx6c87hbsv5yxizrqh2qsyy3lv9cf53nsyvfv"))))
   (cons "obstore-dfbe277e56a3"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/addr2line/addr2line-0.24.2.crate")
           (file-name "addr2line-0.24.2.crate")
           (sha256
            (base32 "1hd1i57zxgz08j6h5qrhsnm2fi0bcqvsh389fw400xm3arz2ggnz"))))
   (cons "obstore-5a15f179cd60"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/ahash/ahash-0.8.12.crate")
           (file-name "ahash-0.8.12.crate")
           (sha256
            (base32 "0xbsp9rlm5ki017c0w6ay8kjwinwm8knjncci95mii30rmwz25as"))))
   (cons "obstore-8e60d3430d3a"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/aho-corasick/aho-corasick-1.1.3.crate")
           (file-name "aho-corasick-1.1.3.crate")
           (sha256
            (base32 "05mrpkvdgp5d20y2p989f187ry9diliijgwrs254fs9s1m1x6q4f"))))
   (cons "obstore-e999941b234f"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/android-tzdata/android-tzdata-0.1.1.crate")
           (file-name "android-tzdata-0.1.1.crate")
           (sha256
            (base32 "1w7ynjxrfs97xg3qlcdns4kgfpwcdv824g611fq32cag4cdr96g9"))))
   (cons "obstore-fd798aea3553"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/arrow/arrow-56.0.0.crate")
           (file-name "arrow-56.0.0.crate")
           (sha256
            (base32 "1dgb3iafnmbilfj8xziix422nb8ssdm9qgl1hrckm4ak6pm8lygx"))))
   (cons "obstore-508dafb53e58"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/arrow-arith/arrow-arith-56.0.0.crate")
           (file-name "arrow-arith-56.0.0.crate")
           (sha256
            (base32 "0bkz2kxbjralmfqi962drhhapgywknjrgzdpr8wa412q7sssz3ah"))))
   (cons "obstore-e2730bc045d6"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/arrow-array/arrow-array-56.0.0.crate")
           (file-name "arrow-array-56.0.0.crate")
           (sha256
            (base32 "0qc4s31rlnrrx0asrkj15w8cixa289ymnfgq7vjv4ayn8p00nwz2"))))
   (cons "obstore-54295b93beb7"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/arrow-buffer/arrow-buffer-56.0.0.crate")
           (file-name "arrow-buffer-56.0.0.crate")
           (sha256
            (base32 "078x89aqgxiwp3a54y993kn7ckbzml4fvg3gdydfw0mpps9mnaal"))))
   (cons "obstore-67e8bcb7dc97"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/arrow-cast/arrow-cast-56.0.0.crate")
           (file-name "arrow-cast-56.0.0.crate")
           (sha256
            (base32 "1dbmbvl54ic07q3hk282p0rkax62y0dklnc0fad7f7cpvjvvrs37"))))
   (cons "obstore-673fd2b5fb57"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/arrow-csv/arrow-csv-56.0.0.crate")
           (file-name "arrow-csv-56.0.0.crate")
           (sha256
            (base32 "0n64y54f453bx36c2l4rmi3wjm6gszpjbi7svd7pb8apzfsx4gv7"))))
   (cons "obstore-97c22fe3da84"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/arrow-data/arrow-data-56.0.0.crate")
           (file-name "arrow-data-56.0.0.crate")
           (sha256
            (base32 "1d7nl8akc1hz2l04jyq3axns6bh9g0gghqczkv33j044vbijzhlp"))))
   (cons "obstore-778de14c5a69"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/arrow-ipc/arrow-ipc-56.0.0.crate")
           (file-name "arrow-ipc-56.0.0.crate")
           (sha256
            (base32 "0sv3ckyk58yv2blvm7zfyvaq3i7rsmnx0gcy6lkxpbk9b96f33bp"))))
   (cons "obstore-3860db334fe7"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/arrow-json/arrow-json-56.0.0.crate")
           (file-name "arrow-json-56.0.0.crate")
           (sha256
            (base32 "150pkaigfdjldgal7r7z74w3y1cmkn6nzdgnh77rzcg79wrxnq1q"))))
   (cons "obstore-425fa0b42a39"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/arrow-ord/arrow-ord-56.0.0.crate")
           (file-name "arrow-ord-56.0.0.crate")
           (sha256
            (base32 "1nd5kfiff4q3szrxx1ziqc9g1rskap1ffch82razzlrr5asa0ps2"))))
   (cons "obstore-df9c9423c9e7"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/arrow-row/arrow-row-56.0.0.crate")
           (file-name "arrow-row-56.0.0.crate")
           (sha256
            (base32 "053ldaha3ypi6vra2wlfmjc2dfh3sby8ixx710dvs6p7r4ir976z"))))
   (cons "obstore-85fa1babc4a4"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/arrow-schema/arrow-schema-56.0.0.crate")
           (file-name "arrow-schema-56.0.0.crate")
           (sha256
            (base32 "0a6fqv0jl0pqxhprc1q0pkmsbsq0zx8yyx91m5jdqpx4qjmipyl5"))))
   (cons "obstore-d8854d15f1cf"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/arrow-select/arrow-select-56.0.0.crate")
           (file-name "arrow-select-56.0.0.crate")
           (sha256
            (base32 "0w0iv23kgxyklpf99l5xylghj5zammhfpasqnfs0al6gy4alv1fq"))))
   (cons "obstore-2c477e8b89e1"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/arrow-string/arrow-string-56.0.0.crate")
           (file-name "arrow-string-56.0.0.crate")
           (sha256
            (base32 "0pp9v6pim0kdssgmzwfvs16vzac4qdr4ma524xcks8g1i65pwirc"))))
   (cons "obstore-e539d3fca749"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/async-trait/async-trait-0.1.88.crate")
           (file-name "async-trait-0.1.88.crate")
           (sha256
            (base32 "1dgxvz7g75cmz6vqqz0mri4xazc6a8xfj1db6r9fxz29lzyd6fg5"))))
   (cons "obstore-f28d99ec8bfe"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/atoi/atoi-2.0.0.crate")
           (file-name "atoi-2.0.0.crate")
           (sha256
            (base32 "0a05h42fggmy7h0ajjv6m7z72l924i7igbx13hk9d8pyign9k3gj"))))
   (cons "obstore-1505bd5d3d11"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/atomic-waker/atomic-waker-1.1.2.crate")
           (file-name "atomic-waker-1.1.2.crate")
           (sha256
            (base32 "1h5av1lw56m0jf0fd3bchxq8a30xv0b4wv8s4zkp4s0i7mfvs18m"))))
   (cons "obstore-6806a6321ec5"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/backtrace/backtrace-0.3.75.crate")
           (file-name "backtrace-0.3.75.crate")
           (sha256
            (base32 "00hhizz29mvd7cdqyz5wrj98vqkihgcxmv2vl7z0d0f53qrac1k8"))))
   (cons "obstore-72b3254f1625"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/base64/base64-0.22.1.crate")
           (file-name "base64-0.22.1.crate")
           (sha256
            (base32 "1imqzgh7bxcikp5vx3shqvw9j09g9ly0xr0jma0q66i52r7jbcvj"))))
   (cons "obstore-1b8e56985ec6"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/bitflags/bitflags-2.9.1.crate")
           (file-name "bitflags-2.9.1.crate")
           (sha256
            (base32 "0rz9rpp5wywwqb3mxfkywh4drmzci2fch780q7lifbf6bsc5d3hv"))))
   (cons "obstore-46c5e41b57b8"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/bumpalo/bumpalo-3.19.0.crate")
           (file-name "bumpalo-3.19.0.crate")
           (sha256
            (base32 "0hsdndvcpqbjb85ghrhska2qxvp9i75q2vb70hma9fxqawdy9ia6"))))
   (cons "obstore-175812e0be2b"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/bytecount/bytecount-0.6.9.crate")
           (file-name "bytecount-0.6.9.crate")
           (sha256
            (base32 "0pinq0n8zza8qr2lyc3yf17k963129kdbf0bwnmvdk1bpvh14n0p"))))
   (cons "obstore-d71b6127be86"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/bytes/bytes-1.10.1.crate")
           (file-name "bytes-1.10.1.crate")
           (sha256
            (base32 "0smd4wi2yrhp5pmq571yiaqx84bjqlm1ixqhnvfwzzc6pqkn26yp"))))
   (cons "obstore-0da45bc31171"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/camino/camino-1.1.10.crate")
           (file-name "camino-1.1.10.crate")
           (sha256
            (base32 "1asw3160i5x2r98lsfym3my8dps0fyk25qi206bddn3i271mp90d"))))
   (cons "obstore-c06acb4f7140"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/cargo-lock/cargo-lock-10.1.0.crate")
           (file-name "cargo-lock-10.1.0.crate")
           (sha256
            (base32 "0m74y8w9wn7rl5mpzr0436r6fshf3qhm7d3wl02s4ys0f57wnsn0"))))
   (cons "obstore-e35af189006b"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/cargo-platform/cargo-platform-0.1.9.crate")
           (file-name "cargo-platform-0.1.9.crate")
           (sha256
            (base32 "1sinpmqjdk3q9llbmxr0h0nyvqrif1r5qs34l000z73b024z2np3"))))
   (cons "obstore-4acbb09d9ee8"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/cargo_metadata/cargo_metadata-0.14.2.crate")
           (file-name "cargo_metadata-0.14.2.crate")
           (sha256
            (base32 "1yl1y40vby9cas4dlfc44szrbl4m4z3pahv3p6ckdqp8ksfv1jsa"))))
   (cons "obstore-5c1599538de2"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/cc/cc-1.2.29.crate")
           (file-name "cc-1.2.29.crate")
           (sha256
            (base32 "0qlkaspjmywvjyfqhpv2x4kwrqs6b69zg33wfi2l8fg2im9rj5aw"))))
   (cons "obstore-9555578bc9e5"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/cfg-if/cfg-if-1.0.1.crate")
           (file-name "cfg-if-1.0.1.crate")
           (sha256
            (base32 "0s0jr5j797q1vqjcd41l0v5izlmlqm7lxy512b418xz5r65mfmcm"))))
   (cons "obstore-613afe47fcd5"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/cfg_aliases/cfg_aliases-0.2.1.crate")
           (file-name "cfg_aliases-0.2.1.crate")
           (sha256
            (base32 "092pxdc1dbgjb6qvh83gk56rkic2n2ybm4yvy76cgynmzi3zwfk1"))))
   (cons "obstore-c469d952047f"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/chrono/chrono-0.4.41.crate")
           (file-name "chrono-0.4.41.crate")
           (sha256
            (base32 "0k8wy2mph0mgipq28vv3wirivhb31pqs7jyid0dzjivz0i9djsf4"))))
   (cons "obstore-a6139a8597ed"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/chrono-tz/chrono-tz-0.10.4.crate")
           (file-name "chrono-tz-0.10.4.crate")
           (sha256
            (base32 "1hr6rmdvqwgk748g2f69mnk97fzhdkfzaczvdn0wz4pdjy2rl4x6"))))
   (cons "obstore-4a65ebfec4fb"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/comfy-table/comfy-table-7.1.4.crate")
           (file-name "comfy-table-7.1.4.crate")
           (sha256
            (base32 "16hxb4pa404r5h7570p58h3yx684sqbshi79j1phn6gvqkzfnraa"))))
   (cons "obstore-87e00182fe74"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/const-random/const-random-0.1.18.crate")
           (file-name "const-random-0.1.18.crate")
           (sha256
            (base32 "0n8kqz3y82ks8znvz1mxn3a9hadca3amzf33gmi6dc3lzs103q47"))))
   (cons "obstore-f9d839f2a20b"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/const-random-macro/const-random-macro-0.1.16.crate")
           (file-name "const-random-macro-0.1.16.crate")
           (sha256
            (base32 "03iram4ijjjq9j5a7hbnmdngj8935wbsd0f5bm8yw2hblbr3kn7r"))))
   (cons "obstore-b2a6cd9ae233"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/core-foundation/core-foundation-0.10.1.crate")
           (file-name "core-foundation-0.10.1.crate")
           (sha256
            (base32 "1xjns6dqf36rni2x9f47b65grxwdm20kwdg9lhmzdrrkwadcv9mj"))))
   (cons "obstore-460fbee9c2c2"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/crunchy/crunchy-0.2.4.crate")
           (file-name "crunchy-0.2.4.crate")
           (sha256
            (base32 "1mbp5navim2qr3x48lyvadqblcxc1dm0lqr0swrkkwy2qblvw3s6"))))
   (cons "obstore-1bfb12502f3f"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/crypto-common/crypto-common-0.1.6.crate")
           (file-name "crypto-common-0.1.6.crate")
           (sha256
            (base32 "1cvby95a6xg7kxdz5ln3rl9xh66nz66w46mm3g56ri1z5x815yqv"))))
   (cons "obstore-acdc4883a9c9"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/csv/csv-1.3.1.crate")
           (file-name "csv-1.3.1.crate")
           (sha256
            (base32 "1bzxgbbhy27flcyafxbj7f1hbn7b8wac04ijfgj34ry9m61lip5c"))))
   (cons "obstore-7d02f3b0da4c"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/csv-core/csv-core-0.1.12.crate")
           (file-name "csv-core-0.1.12.crate")
           (sha256
            (base32 "0gfrjjlfagarhyclxrqv6b14iaxgvgc8kmwwdvw08racvaqg60kx"))))
   (cons "obstore-97369cbbc041"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/displaydoc/displaydoc-0.2.5.crate")
           (file-name "displaydoc-0.2.5.crate")
           (sha256
            (base32 "1q0alair462j21iiqwrr21iabkfnb13d6x5w95lkdg21q2xrqdlp"))))
   (cons "obstore-778e2ac28f6c"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/errno/errno-0.3.13.crate")
           (file-name "errno-0.3.13.crate")
           (sha256
            (base32 "1bd5g3srn66zr3bspac0150bvpg1s7zi6zwhwhlayivciz12m3kp"))))
   (cons "obstore-2d2f06b9cac1"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/error-chain/error-chain-0.12.4.crate")
           (file-name "error-chain-0.12.4.crate")
           (sha256
            (base32 "1z6y5isg0il93jp287sv7pn10i4wrkik2cpyk376wl61rawhcbrd"))))
   (cons "obstore-37909eebbb50"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/fastrand/fastrand-2.3.0.crate")
           (file-name "fastrand-2.3.0.crate")
           (sha256
            (base32 "1ghiahsw1jd68df895cy5h3gzwk30hndidn3b682zmshpgmrx41p"))))
   (cons "obstore-efac5e331f54"
         (origin
           (method url-fetch)
           (uri "https://codeload.github.com/google/flatbuffers/tar.gz/1c514626e83c20fffa8557e75641848e1e15cd5e")
           (file-name "google-1c514626e83c20fffa8557e75641848e1e15cd5e.tar.gz")
           (sha256
            (base32 "1jaxwhzmg1jffjw72ycr15birqr3i2qlqsisl4gsqk2l3wrmxb7g"))))
   (cons "obstore-e13624c26275"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/form_urlencoded/form_urlencoded-1.2.1.crate")
           (file-name "form_urlencoded-1.2.1.crate")
           (sha256
            (base32 "0milh8x7nl4f450s3ddhg57a3flcv6yq8hlkyk6fyr3mcb128dp1"))))
   (cons "obstore-335ff9f135e4"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/getrandom/getrandom-0.2.16.crate")
           (file-name "getrandom-0.2.16.crate")
           (sha256
            (base32 "14l5aaia20cc6cc08xdlhrzmfcylmrnprwnna20lqf746pqzjprk"))))
   (cons "obstore-26145e563e54"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/getrandom/getrandom-0.3.3.crate")
           (file-name "getrandom-0.3.3.crate")
           (sha256
            (base32 "1x6jl875zp6b2b6qp9ghc84b0l76bvng2lvm8zfcmwjl7rb5w516"))))
   (cons "obstore-07e28edb8090"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/gimli/gimli-0.31.1.crate")
           (file-name "gimli-0.31.1.crate")
           (sha256
            (base32 "0gvqc0ramx8szv76jhfd4dms0zyamvlg4whhiz11j34hh3dqxqh7"))))
   (cons "obstore-a8d1add55171"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/glob/glob-0.3.2.crate")
           (file-name "glob-0.3.2.crate")
           (sha256
            (base32 "1cm2w34b5w45fxr522h5b0fv1bxchfswcj560m3pnjbia7asvld8"))))
   (cons "obstore-17da50a276f1"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/h2/h2-0.4.11.crate")
           (file-name "h2-0.4.11.crate")
           (sha256
            (base32 "118771sqbsa6cn48y9waxq24jx80f5xy8af0lq5ixq7ifsi51nhp"))))
   (cons "obstore-459196ed2954"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/half/half-2.6.0.crate")
           (file-name "half-2.6.0.crate")
           (sha256
            (base32 "1j83v0xaqvrw50ppn0g33zig0zsbdi7xiqbzgn7sd5al57nrd4a5"))))
   (cons "obstore-5971ac85611d"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/hashbrown/hashbrown-0.15.4.crate")
           (file-name "hashbrown-0.15.4.crate")
           (sha256
            (base32 "1mg045sm1nm00cwjm7ndi80hcmmv1v3z7gnapxyhd9qxc62sqwar"))))
   (cons "obstore-f4a85d31aea9"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/http/http-1.3.1.crate")
           (file-name "http-1.3.1.crate")
           (sha256
            (base32 "0r95i5h7dr1xadp1ac9453w0s62s27hzkam356nyx2d9mqqmva7l"))))
   (cons "obstore-1efedce1fb8e"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/http-body/http-body-1.0.1.crate")
           (file-name "http-body-1.0.1.crate")
           (sha256
            (base32 "111ir5k2b9ihz5nr9cz7cwm7fnydca7dx4hc7vr16scfzghxrzhy"))))
   (cons "obstore-b021d93e26be"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/http-body-util/http-body-util-0.1.3.crate")
           (file-name "http-body-util-0.1.3.crate")
           (sha256
            (base32 "0jm6jv4gxsnlsi1kzdyffjrj8cfr3zninnxpw73mvkxy4qzdj8dh"))))
   (cons "obstore-6dbf3de79e51"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/httparse/httparse-1.10.1.crate")
           (file-name "httparse-1.10.1.crate")
           (sha256
            (base32 "11ycd554bw2dkgw0q61xsa7a4jn1wb1xbfacmf3dbwsikvkkvgvd"))))
   (cons "obstore-9b112acc8b3a"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/humantime/humantime-2.2.0.crate")
           (file-name "humantime-2.2.0.crate")
           (sha256
            (base32 "17rz8jhh1mcv4b03wnknhv1shwq2v9vhkhlfg884pprsig62l4cv"))))
   (cons "obstore-cc2b571658e3"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/hyper/hyper-1.6.0.crate")
           (file-name "hyper-1.6.0.crate")
           (sha256
            (base32 "103ggny2k31z0iq2gzwk2vbx601wx6xkpjpxn40hr3p3b0b5fayc"))))
   (cons "obstore-e3c93eb61168"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/hyper-rustls/hyper-rustls-0.27.7.crate")
           (file-name "hyper-rustls-0.27.7.crate")
           (sha256
            (base32 "0n6g8998szbzhnvcs1b7ibn745grxiqmlpg53xz206v826v3xjg3"))))
   (cons "obstore-7f66d5bd4c6f"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/hyper-util/hyper-util-0.1.15.crate")
           (file-name "hyper-util-0.1.15.crate")
           (sha256
            (base32 "1pyi2h8idwyadljs95gpihjvkfkmcxi5vn7s882vy0kg9jyxarkz"))))
   (cons "obstore-b0c919e5debc"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/iana-time-zone/iana-time-zone-0.1.63.crate")
           (file-name "iana-time-zone-0.1.63.crate")
           (sha256
            (base32 "1n171f5lbc7bryzmp1h30zw86zbvl5480aq02z92lcdwvvjikjdh"))))
   (cons "obstore-200072f5d0e3"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/icu_collections/icu_collections-2.0.0.crate")
           (file-name "icu_collections-2.0.0.crate")
           (sha256
            (base32 "0izfgypv1hsxlz1h8fc2aak641iyvkak16aaz5b4aqg3s3sp4010"))))
   (cons "obstore-0cde2700ccae"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/icu_locale_core/icu_locale_core-2.0.0.crate")
           (file-name "icu_locale_core-2.0.0.crate")
           (sha256
            (base32 "02phv7vwhyx6vmaqgwkh2p4kc2kciykv2px6g4h8glxfrh02gphc"))))
   (cons "obstore-436880e8e18d"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/icu_normalizer/icu_normalizer-2.0.0.crate")
           (file-name "icu_normalizer-2.0.0.crate")
           (sha256
            (base32 "0ybrnfnxx4sf09gsrxri8p48qifn54il6n3dq2xxgx4dw7l80s23"))))
   (cons "obstore-00210d6893af"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/icu_normalizer_data/icu_normalizer_data-2.0.0.crate")
           (file-name "icu_normalizer_data-2.0.0.crate")
           (sha256
            (base32 "1lvjpzxndyhhjyzd1f6vi961gvzhj244nribfpdqxjdgjdl0s880"))))
   (cons "obstore-016c619c1eeb"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/icu_properties/icu_properties-2.0.1.crate")
           (file-name "icu_properties-2.0.1.crate")
           (sha256
            (base32 "0az349pjg8f18lrjbdmxcpg676a7iz2ibc09d2wfz57b3sf62v01"))))
   (cons "obstore-298459143998"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/icu_properties_data/icu_properties_data-2.0.1.crate")
           (file-name "icu_properties_data-2.0.1.crate")
           (sha256
            (base32 "0cnn3fkq6k88w7p86w7hsd1254s4sl783rpz4p6hlccq74a5k119"))))
   (cons "obstore-03c80da27b5f"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/icu_provider/icu_provider-2.0.0.crate")
           (file-name "icu_provider-2.0.0.crate")
           (sha256
            (base32 "1bz5v02gxv1i06yhdhs2kbwxkw3ny9r2vvj9j288fhazgfi0vj03"))))
   (cons "obstore-686f825264d6"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/idna/idna-1.0.3.crate")
           (file-name "idna-1.0.3.crate")
           (sha256
            (base32 "0zlajvm2k3wy0ay8plr07w22hxkkmrxkffa6ah57ac6nci984vv8"))))
   (cons "obstore-3acae9609540"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/idna_adapter/idna_adapter-1.2.1.crate")
           (file-name "idna_adapter-1.2.1.crate")
           (sha256
            (base32 "0i0339pxig6mv786nkqcxnwqa87v4m94b2653f6k3aj0jmhfkjis"))))
   (cons "obstore-fe4cd85333e2"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/indexmap/indexmap-2.10.0.crate")
           (file-name "indexmap-2.10.0.crate")
           (sha256
            (base32 "0qd6g26gxzl6dbf132w48fa8rr95glly3jhbk90i29726d9xhk7y"))))
   (cons "obstore-f4c7245a0850"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/indoc/indoc-2.0.6.crate")
           (file-name "indoc-2.0.6.crate")
           (sha256
            (base32 "1gbn2pkx5sgbd9lp05d2bkqpbfgazi0z3nvharh5ajah11d29izl"))))
   (cons "obstore-b86e202f0009"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/io-uring/io-uring-0.7.8.crate")
           (file-name "io-uring-0.7.8.crate")
           (sha256
            (base32 "04whnj5a4pml44jhsmmf4p87bpgr7swkcijx4yjcng8900pj0vmq"))))
   (cons "obstore-469fb0b9cefa"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/ipnet/ipnet-2.11.0.crate")
           (file-name "ipnet-2.11.0.crate")
           (sha256
            (base32 "0c5i9sfi2asai28m8xp48k5gvwkqrg5ffpi767py6mzsrswv17s6"))))
   (cons "obstore-dbc5ebe9c3a1"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/iri-string/iri-string-0.7.8.crate")
           (file-name "iri-string-0.7.8.crate")
           (sha256
            (base32 "1cl0wfq97wq4s1p4dl0ix5cfgsc5fn7l22ljgw9ab9x1qglypifv"))))
   (cons "obstore-2b192c782037"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/itertools/itertools-0.14.0.crate")
           (file-name "itertools-0.14.0.crate")
           (sha256
            (base32 "118j6l1vs2mx65dqhwyssbrxpawa90886m3mzafdvyip41w2q69b"))))
   (cons "obstore-4a5f13b858c8"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/itoa/itoa-1.0.15.crate")
           (file-name "itoa-1.0.15.crate")
           (sha256
            (base32 "0b4fj9kz54dr3wam0vprjwgygvycyw8r0qwg7vp19ly8b2w16psa"))))
   (cons "obstore-1cfaf33c695f"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/js-sys/js-sys-0.3.77.crate")
           (file-name "js-sys-0.3.77.crate")
           (sha256
            (base32 "13x2qcky5l22z4xgivi59xhjjx4kxir1zg7gcj0f1ijzd4yg7yhw"))))
   (cons "obstore-b765c3180960"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/lexical-core/lexical-core-1.0.5.crate")
           (file-name "lexical-core-1.0.5.crate")
           (sha256
            (base32 "0n49vqm7njn1ia0z9jkyvap864i808abgd3hb9b7b43014cc6rdp"))))
   (cons "obstore-de6f9cb01fb0"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/lexical-parse-float/lexical-parse-float-1.0.5.crate")
           (file-name "lexical-parse-float-1.0.5.crate")
           (sha256
            (base32 "1wmhcndf7gvfqvmd5v61nhbqgaybiw27q1cs41h81c5h3yq9qvyy"))))
   (cons "obstore-72207aae22fc"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/lexical-parse-integer/lexical-parse-integer-1.0.5.crate")
           (file-name "lexical-parse-integer-1.0.5.crate")
           (sha256
            (base32 "0bpidpb0viqj9wx3z727y6d59smz5kj7km5nlwdi42pw4ap7l83j"))))
   (cons "obstore-5a82e24bf537"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/lexical-util/lexical-util-1.0.6.crate")
           (file-name "lexical-util-1.0.6.crate")
           (sha256
            (base32 "1cx0974y9x63ikra6l2vqcr4gmf8pipdrfzzfz0j9z9pym5y50js"))))
   (cons "obstore-c5afc668a27f"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/lexical-write-float/lexical-write-float-1.0.5.crate")
           (file-name "lexical-write-float-1.0.5.crate")
           (sha256
            (base32 "1gb2ip3r9wmbsgfa5d8cwgbw4hrgpyv5g9w1bas0yikzl9lcdby5"))))
   (cons "obstore-629ddff1a914"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/lexical-write-integer/lexical-write-integer-1.0.5.crate")
           (file-name "lexical-write-integer-1.0.5.crate")
           (sha256
            (base32 "0y7rl3pkac4lhcfiwxzsb2p3m432if4af5jn4kxkda0lm7qxz7b2"))))
   (cons "obstore-117169329309"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/libc/libc-0.2.174.crate")
           (file-name "libc-0.2.174.crate")
           (sha256
            (base32 "0xl7pqvw7g2874dy3kjady2fjr4rhj5lxsnxkkhr5689jcr6jw8i"))))
   (cons "obstore-f9fbbcab5105"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/libm/libm-0.2.15.crate")
           (file-name "libm-0.2.15.crate")
           (sha256
            (base32 "1plpzf0p829viazdj57yw5dhmlr8ywf3apayxc2f2bq5a6mvryzr"))))
   (cons "obstore-cd945864f07f"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/linux-raw-sys/linux-raw-sys-0.9.4.crate")
           (file-name "linux-raw-sys-0.9.4.crate")
           (sha256
            (base32 "04kyjdrq79lz9ibrf7czk6cv9d3jl597pb9738vzbsbzy1j5i56d"))))
   (cons "obstore-241eaef5fd12"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/litemap/litemap-0.8.0.crate")
           (file-name "litemap-0.8.0.crate")
           (sha256
            (base32 "0mlrlskwwhirxk3wsz9psh6nxcy491n0dh8zl02qgj0jzpssw7i4"))))
   (cons "obstore-96936507f153"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/lock_api/lock_api-0.4.13.crate")
           (file-name "lock_api-0.4.13.crate")
           (sha256
            (base32 "0rd73p4299mjwl4hhlfj9qr88v3r0kc8s1nszkfmnq2ky43nb4wn"))))
   (cons "obstore-13dc2df351e3"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/log/log-0.4.27.crate")
           (file-name "log-0.4.27.crate")
           (sha256
            (base32 "150x589dqil307rv0rwj0jsgz5bjbwvl83gyl61jf873a7rjvp0k"))))
   (cons "obstore-112b39cec0b2"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/lru-slab/lru-slab-0.1.2.crate")
           (file-name "lru-slab-0.1.2.crate")
           (sha256
            (base32 "0m2139k466qj3bnpk66bwivgcx3z88qkxvlzk70vd65jq373jaqi"))))
   (cons "obstore-a06de3016e9f"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/matrixmultiply/matrixmultiply-0.3.10.crate")
           (file-name "matrixmultiply-0.3.10.crate")
           (sha256
            (base32 "020sqwg3cvprfasbszqbnis9zx6c3w9vlkfidyimgblzdq0y6vd0"))))
   (cons "obstore-32a282da65fa"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/memchr/memchr-2.7.5.crate")
           (file-name "memchr-2.7.5.crate")
           (sha256
            (base32 "1h2bh2jajkizz04fh047lpid5wgw2cr9igpkdhl3ibzscpd858ij"))))
   (cons "obstore-78bed444cc8a"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/mio/mio-1.0.4.crate")
           (file-name "mio-1.0.4.crate")
           (sha256
            (base32 "073n3kam3nz8j8had35fd2nn7j6a33pi3y5w3kq608cari2d9gkq"))))
   (cons "obstore-882ed72dce93"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/ndarray/ndarray-0.16.1.crate")
           (file-name "ndarray-0.16.1.crate")
           (sha256
            (base32 "0ha8sg5ad501pgkxw0wczh8myc2ma3gyxgcny4mq8rckrqnxfbl8"))))
   (cons "obstore-35bd024e8b2f"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/num/num-0.4.3.crate")
           (file-name "num-0.4.3.crate")
           (sha256
            (base32 "08yb2fc1psig7pkzaplm495yp7c30m4pykpkwmi5bxrgid705g9m"))))
   (cons "obstore-73f88a130763"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/num-complex/num-complex-0.4.6.crate")
           (file-name "num-complex-0.4.6.crate")
           (sha256
            (base32 "15cla16mnw12xzf5g041nxbjjm9m85hdgadd5dl5d0b30w9qmy3k"))))
   (cons "obstore-1429034a0490"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/num-iter/num-iter-0.1.45.crate")
           (file-name "num-iter-0.1.45.crate")
           (sha256
            (base32 "1gzm7vc5g9qsjjl3bqk9rz1h6raxhygbrcpbfl04swlh0i506a8l"))))
   (cons "obstore-f83d14da3905"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/num-rational/num-rational-0.4.2.crate")
           (file-name "num-rational-0.4.2.crate")
           (sha256
            (base32 "093qndy02817vpgcqjnj139im3jl7vkq4h68kykdqqh577d18ggq"))))
   (cons "obstore-9b2dba356160"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/numpy/numpy-0.26.0.crate")
           (file-name "numpy-0.26.0.crate")
           (sha256
            (base32 "12z74x5afv9syfrlcvjcidqm82hkg1dmfl5mf59lzdb0c4svlbcv"))))
   (cons "obstore-62948e14d923"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/object/object-0.36.7.crate")
           (file-name "object-0.36.7.crate")
           (sha256
            (base32 "11vv97djn9nc5n6w1gc6bd96d2qk2c8cg1kw5km9bsi3v4a8x532"))))
   (cons "obstore-efc4f07659e1"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/object_store/object_store-0.12.3.crate")
           (file-name "object_store-0.12.3.crate")
           (sha256
            (base32 "15kl8dhgwy0n0r8827zzv5jvxqw3wrqlvlhw6idd8771b5vg1i7g"))))
   (cons "obstore-d05e27ee2136"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/openssl-probe/openssl-probe-0.1.6.crate")
           (file-name "openssl-probe-0.1.6.crate")
           (sha256
            (base32 "0bl52x55laalqb707k009h8kfawliwp992rlsvkzy49n47p2fpnh"))))
   (cons "obstore-70d58bf43669"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/parking_lot/parking_lot-0.12.4.crate")
           (file-name "parking_lot-0.12.4.crate")
           (sha256
            (base32 "04sab1c7304jg8k0d5b2pxbj1fvgzcf69l3n2mfpkdb96vs8pmbh"))))
   (cons "obstore-bc838d2a56b5"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/parking_lot_core/parking_lot_core-0.9.11.crate")
           (file-name "parking_lot_core-0.9.11.crate")
           (sha256
            (base32 "19g4d6m5k4ggacinqprnn8xvdaszc3y5smsmbz1adcdmaqm8v0xw"))))
   (cons "obstore-e3148f504620"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/percent-encoding/percent-encoding-2.3.1.crate")
           (file-name "percent-encoding-2.3.1.crate")
           (sha256
            (base32 "0gi8wgx0dcy8rnv1kywdv98lwcx67hz0a0zwpib5v2i08r88y573"))))
   (cons "obstore-913273894cec"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/phf/phf-0.12.1.crate")
           (file-name "phf-0.12.1.crate")
           (sha256
            (base32 "1dz85g1wshfca83mrq3va9rm9n8qcdjlpv1i3908y5zc9j4p6cli"))))
   (cons "obstore-06005508882f"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/phf_shared/phf_shared-0.12.1.crate")
           (file-name "phf_shared-0.12.1.crate")
           (sha256
            (base32 "10cr16wpmbjxd7w6k98sxw9yw3zxnzscybl9jzyq3digi045a006"))))
   (cons "obstore-f84267b20a16"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/portable-atomic/portable-atomic-1.11.1.crate")
           (file-name "portable-atomic-1.11.1.crate")
           (sha256
            (base32 "10s4cx9y3jvw0idip09ar52s2kymq8rq9a668f793shn1ar6fhpq"))))
   (cons "obstore-d8a2f0d8d040"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/portable-atomic-util/portable-atomic-util-0.2.4.crate")
           (file-name "portable-atomic-util-0.2.4.crate")
           (sha256
            (base32 "01rmx1li07ixsx3sqg2bxqrkzk7b5n8pibwwf2589ms0s3cg18nq"))))
   (cons "obstore-e5a7c3083727"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/potential_utf/potential_utf-0.1.2.crate")
           (file-name "potential_utf-0.1.2.crate")
           (sha256
            (base32 "11dm6k3krx3drbvhgjw8z508giiv0m09wzl6ghza37176w4c79z5"))))
   (cons "obstore-02b3e5e68a3a"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/proc-macro2/proc-macro2-1.0.95.crate")
           (file-name "proc-macro2-1.0.95.crate")
           (sha256
            (base32 "0y7pwxv6sh4fgg6s715ygk1i7g3w02c0ljgcsfm046isibkfbcq2"))))
   (cons "obstore-57206b407293"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/pulldown-cmark/pulldown-cmark-0.9.6.crate")
           (file-name "pulldown-cmark-0.9.6.crate")
           (sha256
            (base32 "0av876a31qvqhy7gzdg134zn4s10smlyi744mz9vrllkf906n82p"))))
   (cons "obstore-7ba0117f4212"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/pyo3/pyo3-0.26.0.crate")
           (file-name "pyo3-0.26.0.crate")
           (sha256
            (base32 "10vkw1a27ymxbi5rrcp71k9q645ybbjdli20akk1w40j89zi383v"))))
   (cons "obstore-a6ccb4f00b24"
         (origin
           (method url-fetch)
           (uri "https://codeload.github.com/kylebarron/arro3/tar.gz/b8dfd858de44fb754eb9ec4f55c20774e04f668b")
           (file-name "kylebarron-b8dfd858de44fb754eb9ec4f55c20774e04f668b.tar.gz")
           (sha256
            (base32 "0m6s5vnbfqgxr8kj9r5hnb7afdjb98wl0hwvnaczw5r41gqb9k56"))))
   (cons "obstore-e6ee6d4cb3e8"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/pyo3-async-runtimes/pyo3-async-runtimes-0.26.0.crate")
           (file-name "pyo3-async-runtimes-0.26.0.crate")
           (sha256
            (base32 "08vf096h7ry98508s15j5q91izz0hfhqvcydyljvkmg8nd66vvp6"))))
   (cons "obstore-4fc6ddaf2494"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/pyo3-build-config/pyo3-build-config-0.26.0.crate")
           (file-name "pyo3-build-config-0.26.0.crate")
           (sha256
            (base32 "0pyzhzxsn7lhhbhjcm1nyjw53f5i3x1nbb1imali4zcl4jpxvijg"))))
   (cons "obstore-f01f356a8686"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/pyo3-bytes/pyo3-bytes-0.4.0.crate")
           (file-name "pyo3-bytes-0.4.0.crate")
           (sha256
            (base32 "09ppz7x7iz9084yi2smj3z7a7ggz8aj79b65dv723j46hrm3a7zh"))))
   (cons "obstore-025474d39287"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/pyo3-ffi/pyo3-ffi-0.26.0.crate")
           (file-name "pyo3-ffi-0.26.0.crate")
           (sha256
            (base32 "01a137mrhpg442g1k5km3j80qh2alx24fvf3iaryyf47jb9p8m02"))))
   (cons "obstore-2e64eb489f22"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/pyo3-macros/pyo3-macros-0.26.0.crate")
           (file-name "pyo3-macros-0.26.0.crate")
           (sha256
            (base32 "1vgx5z2csmznj371rj1g13rijz0yqi6c8xqvj6airzi2kx4fnr1f"))))
   (cons "obstore-100246c0ecf4"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/pyo3-macros-backend/pyo3-macros-backend-0.26.0.crate")
           (file-name "pyo3-macros-backend-0.26.0.crate")
           (sha256
            (base32 "1kqg5q8563i754fq8g4syad5ci1k46lmb10v6isv807lxk04c0hh"))))
   (cons "obstore-8927b0664f5c"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/quick-xml/quick-xml-0.38.0.crate")
           (file-name "quick-xml-0.38.0.crate")
           (sha256
            (base32 "06vvgd9arm1nrsd4d0ii6lhnp6m11bwy7drqa4k9hnjw9xkb09w9"))))
   (cons "obstore-626214629cda"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/quinn/quinn-0.11.8.crate")
           (file-name "quinn-0.11.8.crate")
           (sha256
            (base32 "1j02h87nfxww5mjcw4vjcnx8b70q0yinnc8xvjv82ryskii18qk2"))))
   (cons "obstore-49df843a9161"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/quinn-proto/quinn-proto-0.11.12.crate")
           (file-name "quinn-proto-0.11.12.crate")
           (sha256
            (base32 "0bj2yyrf1mrg2bcj19ipsspvrj5sq0di0pz5maw5pj31j4x89ps9"))))
   (cons "obstore-fcebb1209ee2"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/quinn-udp/quinn-udp-0.5.13.crate")
           (file-name "quinn-udp-0.5.13.crate")
           (sha256
            (base32 "0w0ri3wv5g419i5dfv4qmjxh4ayc4hp77y2gy4p3axp2kqhb3szw"))))
   (cons "obstore-1885c039570d"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/quote/quote-1.0.40.crate")
           (file-name "quote-1.0.40.crate")
           (sha256
            (base32 "1394cxjg6nwld82pzp2d4fp6pmaz32gai1zh9z5hvh0dawww118q"))))
   (cons "obstore-9fbfd9d094a4"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/rand/rand-0.9.1.crate")
           (file-name "rand-0.9.1.crate")
           (sha256
            (base32 "15yxfcxbgmwba5cv7mjg9bhc1r5c9483dfcdfspg62x4jk8dkgwz"))))
   (cons "obstore-99d9a13982dc"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/rand_core/rand_core-0.9.3.crate")
           (file-name "rand_core-0.9.3.crate")
           (sha256
            (base32 "0f3xhf16yks5ic6kmgxcpv1ngdhp48mmfy4ag82i1wnwh8ws3ncr"))))
   (cons "obstore-60a357793950"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/rawpointer/rawpointer-0.2.1.crate")
           (file-name "rawpointer-0.2.1.crate")
           (sha256
            (base32 "1qy1qvj17yh957vhffnq6agq0brvylw27xgks171qrah75wmg8v0"))))
   (cons "obstore-0d04b7d0ee6b"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/redox_syscall/redox_syscall-0.5.13.crate")
           (file-name "redox_syscall-0.5.13.crate")
           (sha256
            (base32 "1mlzna9bcd7ss1973bmysr3hpjrys82b3bd7l03h4jkbxv8bf10d"))))
   (cons "obstore-b544ef1b4eac"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/regex/regex-1.11.1.crate")
           (file-name "regex-1.11.1.crate")
           (sha256
            (base32 "148i41mzbx8bmq32hsj1q4karkzzx5m60qza6gdw4pdc9qdyyi5m"))))
   (cons "obstore-809e8dc61f6d"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/regex-automata/regex-automata-0.4.9.crate")
           (file-name "regex-automata-0.4.9.crate")
           (sha256
            (base32 "02092l8zfh3vkmk47yjc8d631zhhcd49ck2zr133prvd3z38v7l0"))))
   (cons "obstore-2b15c43186be"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/regex-syntax/regex-syntax-0.8.5.crate")
           (file-name "regex-syntax-0.8.5.crate")
           (sha256
            (base32 "0p41p3hj9ww7blnbwbj9h7rwxzxg0c1hvrdycgys8rxyhqqw859b"))))
   (cons "obstore-cbc931937e6c"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/reqwest/reqwest-0.12.22.crate")
           (file-name "reqwest-0.12.22.crate")
           (sha256
            (base32 "0cbmfrcrk6wbg93apmji0fln1ca9322af2kc7dpa18vcgs9k3jfb"))))
   (cons "obstore-a4689e6c2294"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/ring/ring-0.17.14.crate")
           (file-name "ring-0.17.14.crate")
           (sha256
            (base32 "1dw32gv19ccq4hsx3ribhpdzri1vnrlcfqb2vj41xn4l49n9ws54"))))
   (cons "obstore-989e6739f80c"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/rustc-demangle/rustc-demangle-0.1.25.crate")
           (file-name "rustc-demangle-0.1.25.crate")
           (sha256
            (base32 "0kxq6m0drr40434ch32j31dkg00iaf4zxmqg7sqxajhcz0wng7lq"))))
   (cons "obstore-11181fbabf24"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/rustix/rustix-1.0.8.crate")
           (file-name "rustix-1.0.8.crate")
           (sha256
            (base32 "1j6ajqi61agdnh1avr4bplrsgydjw1n4mycdxw3v8g94pyx1y60i"))))
   (cons "obstore-2491382039b2"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/rustls/rustls-0.23.29.crate")
           (file-name "rustls-0.23.29.crate")
           (sha256
            (base32 "1lcvzvzqk8xx8jzg0x5v3mkqgwkwr7v6zdq8zw8rp6xj74h3i494"))))
   (cons "obstore-7fcff2dd52b5"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/rustls-native-certs/rustls-native-certs-0.8.1.crate")
           (file-name "rustls-native-certs-0.8.1.crate")
           (sha256
            (base32 "1ls7laa3748mkn23fmi3g4mlwk131lx6chq2lyc8v2mmabfz5kvz"))))
   (cons "obstore-dce314e5fee3"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/rustls-pemfile/rustls-pemfile-2.2.0.crate")
           (file-name "rustls-pemfile-2.2.0.crate")
           (sha256
            (base32 "0l3f3mrfkgdjrava7ibwzgwc4h3dljw3pdkbsi9rkwz3zvji9qyw"))))
   (cons "obstore-229a4a4c2210"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/rustls-pki-types/rustls-pki-types-1.12.0.crate")
           (file-name "rustls-pki-types-1.12.0.crate")
           (sha256
            (base32 "0yawbdpix8jif6s8zj1p2hbyb7y3bj66fhx0y7hyf4qh4964m6i2"))))
   (cons "obstore-0a17884ae0c1"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/rustls-webpki/rustls-webpki-0.103.4.crate")
           (file-name "rustls-webpki-0.103.4.crate")
           (sha256
            (base32 "1z4jmmgasjgk9glb160a66bshvgifa64mgfjrkqp7dy1w158h5qa"))))
   (cons "obstore-8a0d197bd2c9"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/rustversion/rustversion-1.0.21.crate")
           (file-name "rustversion-1.0.21.crate")
           (sha256
            (base32 "07bb1xx05hhwpnl43sqrhsmxyk5sd5m5baadp19nxp69s9xij3ca"))))
   (cons "obstore-28d3b2b1366e"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/ryu/ryu-1.0.20.crate")
           (file-name "ryu-1.0.20.crate")
           (sha256
            (base32 "07s855l8sb333h6bpn24pka5sp7hjk2w667xy6a0khkf6sqv5lr8"))))
   (cons "obstore-93fc1dc3aaa9"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/same-file/same-file-1.0.6.crate")
           (file-name "same-file-1.0.6.crate")
           (sha256
            (base32 "00h5j1w87dmhnvbv9l8bic3y7xxsnjmssvifw2ayvgx9mb1ivz4k"))))
   (cons "obstore-1f29ebaa345f"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/schannel/schannel-0.1.27.crate")
           (file-name "schannel-0.1.27.crate")
           (sha256
            (base32 "0gbbhy28v72kd5iina0z2vcdl3vz63mk5idvkzn5r52z6jmfna8z"))))
   (cons "obstore-271720403f46"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/security-framework/security-framework-3.2.0.crate")
           (file-name "security-framework-3.2.0.crate")
           (sha256
            (base32 "05mkrddi9i18h9p098d0iimqv1xxz0wd8mbgpbvh9jj67x0205r7"))))
   (cons "obstore-49db231d56a1"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/security-framework-sys/security-framework-sys-2.14.0.crate")
           (file-name "security-framework-sys-2.14.0.crate")
           (sha256
            (base32 "0chwn01qrnvs59i5220bymd38iddy4krbnmfnhf4k451aqfj7ns9"))))
   (cons "obstore-56e6fa9c48d2"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/semver/semver-1.0.26.crate")
           (file-name "semver-1.0.26.crate")
           (sha256
            (base32 "1l5q2vb8fjkby657kdyfpvv40x2i2xqq9bg57pxqakfj92fgmrjn"))))
   (cons "obstore-5f0e2c6ed660"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/serde/serde-1.0.219.crate")
           (file-name "serde-1.0.219.crate")
           (sha256
            (base32 "1dl6nyxnsi82a197sd752128a4avm6mxnscywas1jq30srp2q3jz"))))
   (cons "obstore-5b0276cf7f2c"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/serde_derive/serde_derive-1.0.219.crate")
           (file-name "serde_derive-1.0.219.crate")
           (sha256
            (base32 "001azhjmj7ya52pmfiw4ppxm16nd44y15j2pf5gkcwrcgz7pc0jv"))))
   (cons "obstore-20068b6e96dc"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/serde_json/serde_json-1.0.140.crate")
           (file-name "serde_json-1.0.140.crate")
           (sha256
            (base32 "0wwkp4vc20r87081ihj3vpyz5qf7wqkqipq17v99nv6wjrp8n1i0"))))
   (cons "obstore-bf41e0cfaf72"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/serde_spanned/serde_spanned-0.6.9.crate")
           (file-name "serde_spanned-0.6.9.crate")
           (sha256
            (base32 "18vmxq6qfrm110caszxrzibjhy2s54n1g5w1bshxq9kjmz7y0hdz"))))
   (cons "obstore-d3491c14715c"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/serde_urlencoded/serde_urlencoded-0.7.1.crate")
           (file-name "serde_urlencoded-0.7.1.crate")
           (sha256
            (base32 "1zgklbdaysj3230xivihs30qi5vkhigg323a9m62k8jwf4a1qjfk"))))
   (cons "obstore-0fda2ff0d084"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/shlex/shlex-1.3.0.crate")
           (file-name "shlex-1.3.0.crate")
           (sha256
            (base32 "0r1y6bv26c1scpxvhg2cabimrmwgbp4p3wy6syj9n0c4s3q2znhg"))))
   (cons "obstore-e3a9fe34e3e7"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/simdutf8/simdutf8-0.1.5.crate")
           (file-name "simdutf8-0.1.5.crate")
           (sha256
            (base32 "0vmpf7xaa0dnaikib5jlx6y4dxd3hxqz6l830qb079g7wcsgxag3"))))
   (cons "obstore-56199f7ddabf"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/siphasher/siphasher-1.0.1.crate")
           (file-name "siphasher-1.0.1.crate")
           (sha256
            (base32 "17f35782ma3fn6sh21c027kjmd227xyrx06ffi8gw4xzv9yry6an"))))
   (cons "obstore-16d23b015676"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/skeptic/skeptic-0.13.7.crate")
           (file-name "skeptic-0.13.7.crate")
           (sha256
            (base32 "1a205720pnss0alxvbx0fcn3883cg3fbz5y1047hmjbnaq0kplhn"))))
   (cons "obstore-04dc19736151"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/slab/slab-0.4.10.crate")
           (file-name "slab-0.4.10.crate")
           (sha256
            (base32 "03f5a9gdp33mngya4qwq2555138pj74pl015scv57wsic5rikp04"))))
   (cons "obstore-e22376abed35"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/socket2/socket2-0.5.10.crate")
           (file-name "socket2-0.5.10.crate")
           (sha256
            (base32 "0y067ki5q946w91xlz2sb175pnfazizva6fi3kfp639mxnmpc8z2"))))
   (cons "obstore-a8f112729512"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/stable_deref_trait/stable_deref_trait-1.2.0.crate")
           (file-name "stable_deref_trait-1.2.0.crate")
           (sha256
            (base32 "1lxjr8q2n534b2lhkxd6l6wcddzjvnksi58zv11f9y0jjmr15wd8"))))
   (cons "obstore-a2eb9349b644"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/static_assertions/static_assertions-1.1.0.crate")
           (file-name "static_assertions-1.1.0.crate")
           (sha256
            (base32 "0gsl6xmw10gvn3zs1rv99laj5ig7ylffnh71f9l34js4nr4r7sx2"))))
   (cons "obstore-17b6f7059634"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/syn/syn-2.0.104.crate")
           (file-name "syn-2.0.104.crate")
           (sha256
            (base32 "0h2s8cxh5dsh9h41dxnlzpifqqn59cqgm0kljawws61ljq2zgdhp"))))
   (cons "obstore-0bf256ce5efd"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/sync_wrapper/sync_wrapper-1.0.2.crate")
           (file-name "sync_wrapper-1.0.2.crate")
           (sha256
            (base32 "0qvjyasd6w18mjg5xlaq5jgy84jsjfsvmnn12c13gypxbv75dwhb"))))
   (cons "obstore-728a70f3dbaf"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/synstructure/synstructure-0.13.2.crate")
           (file-name "synstructure-0.13.2.crate")
           (sha256
            (base32 "1lh9lx3r3jb18f8sbj29am5hm9jymvbwh6jb1izsnnxgvgrp12kj"))))
   (cons "obstore-e502f78cdbb8"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/target-lexicon/target-lexicon-0.13.2.crate")
           (file-name "target-lexicon-0.13.2.crate")
           (sha256
            (base32 "16m6smfz533im9dyxfhnzmpi4af75g2iii36ylc4gfmqvf6gf0p5"))))
   (cons "obstore-e8a64e398534"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/tempfile/tempfile-3.20.0.crate")
           (file-name "tempfile-3.20.0.crate")
           (sha256
            (base32 "18fnp7mjckd9c9ldlb2zhp1hd4467y2hpvx9l50j97rlhlwlx9p8"))))
   (cons "obstore-b6aaf5339b57"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/thiserror/thiserror-1.0.69.crate")
           (file-name "thiserror-1.0.69.crate")
           (sha256
            (base32 "0lizjay08agcr5hs9yfzzj6axs53a2rgx070a1dsi3jpkcrzbamn"))))
   (cons "obstore-567b8a2dae58"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/thiserror/thiserror-2.0.12.crate")
           (file-name "thiserror-2.0.12.crate")
           (sha256
            (base32 "024791nsc0np63g2pq30cjf9acj38z3jwx9apvvi8qsqmqnqlysn"))))
   (cons "obstore-4fee6c4efc90"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/thiserror-impl/thiserror-impl-1.0.69.crate")
           (file-name "thiserror-impl-1.0.69.crate")
           (sha256
            (base32 "1h84fmn2nai41cxbhk6pqf46bxqq1b344v8yz089w1chzi76rvjg"))))
   (cons "obstore-7f7cf42b4507"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/thiserror-impl/thiserror-impl-2.0.12.crate")
           (file-name "thiserror-impl-2.0.12.crate")
           (sha256
            (base32 "07bsn7shydaidvyyrm7jz29vp78vrxr9cr9044rfmn078lmz8z3z"))))
   (cons "obstore-2c9d3793400a"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/tiny-keccak/tiny-keccak-2.0.2.crate")
           (file-name "tiny-keccak-2.0.2.crate")
           (sha256
            (base32 "0dq2x0hjffmixgyf6xv9wgsbcxkd65ld0wrfqmagji8a829kg79c"))))
   (cons "obstore-5d4f6d1145dc"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/tinystr/tinystr-0.8.1.crate")
           (file-name "tinystr-0.8.1.crate")
           (sha256
            (base32 "12sc6h3hnn6x78iycm5v6wrs2xhxph0ydm43yyn7gdfw8l8nsksx"))))
   (cons "obstore-09b3661f17e8"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/tinyvec/tinyvec-1.9.0.crate")
           (file-name "tinyvec-1.9.0.crate")
           (sha256
            (base32 "0w9w8qcifns9lzvlbfwa01y0skhr542anwa3rpn28rg82wgndcq9"))))
   (cons "obstore-0cc3a2344daf"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/tokio/tokio-1.46.1.crate")
           (file-name "tokio-1.46.1.crate")
           (sha256
            (base32 "05sxldy7kcgysnxyzz1h1l8j3d9mjyqfh7r48ni27gmg9lsa5hqc"))))
   (cons "obstore-6e06d43f1345"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/tokio-macros/tokio-macros-2.5.0.crate")
           (file-name "tokio-macros-2.5.0.crate")
           (sha256
            (base32 "1f6az2xbvqp7am417b78d1za8axbvjvxnmkakz9vr8s52czx81kf"))))
   (cons "obstore-8e727b36a1a0"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/tokio-rustls/tokio-rustls-0.26.2.crate")
           (file-name "tokio-rustls-0.26.2.crate")
           (sha256
            (base32 "16wf007q3584j46wc4s0zc4szj6280g23hka6x6bgs50l4v7nwlf"))))
   (cons "obstore-66a539a9ad6d"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/tokio-util/tokio-util-0.7.15.crate")
           (file-name "tokio-util-0.7.15.crate")
           (sha256
            (base32 "1pypd9lm1fdnpw0779pqvc16qqrxjy63dgfm20ajhpbdmnlkk9b6"))))
   (cons "obstore-dc1beb996b9d"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/toml/toml-0.8.23.crate")
           (file-name "toml-0.8.23.crate")
           (sha256
            (base32 "0qnkrq4lm2sdhp3l6cb6f26i8zbnhqb7mhbmksd550wxdfcyn6yw"))))
   (cons "obstore-22cddaf88f4f"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/toml_datetime/toml_datetime-0.6.11.crate")
           (file-name "toml_datetime-0.6.11.crate")
           (sha256
            (base32 "077ix2hb1dcya49hmi1avalwbixmrs75zgzb3b2i7g2gizwdmk92"))))
   (cons "obstore-41fe8c660ae4"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/toml_edit/toml_edit-0.22.27.crate")
           (file-name "toml_edit-0.22.27.crate")
           (sha256
            (base32 "16l15xm40404asih8vyjvnka9g0xs9i4hfb6ry3ph9g419k8rzj1"))))
   (cons "obstore-5d99f8c9a772"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/toml_write/toml_write-0.1.2.crate")
           (file-name "toml_write-0.1.2.crate")
           (sha256
            (base32 "008qlhqlqvljp1gpp9rn5cqs74gwvdgbvs92wnpq8y3jlz4zi6ax"))))
   (cons "obstore-d039ad9159c9"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/tower/tower-0.5.2.crate")
           (file-name "tower-0.5.2.crate")
           (sha256
            (base32 "1ybmd59nm4abl9bsvy6rx31m4zvzp5rja2slzpn712y9b68ssffh"))))
   (cons "obstore-adc82fd73de2"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/tower-http/tower-http-0.6.6.crate")
           (file-name "tower-http-0.6.6.crate")
           (sha256
            (base32 "1wh51y4rf03f91c6rvli6nwzsarx7097yx6sqlm75ag27pbjzj5d"))))
   (cons "obstore-121c2a6cda46"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/tower-layer/tower-layer-0.3.3.crate")
           (file-name "tower-layer-0.3.3.crate")
           (sha256
            (base32 "03kq92fdzxin51w8iqix06dcfgydyvx7yr6izjq0p626v9n2l70j"))))
   (cons "obstore-8df9b6e13f2d"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/tower-service/tower-service-0.3.3.crate")
           (file-name "tower-service-0.3.3.crate")
           (sha256
            (base32 "1hzfkvkci33ra94xjx64vv3pp0sq346w06fpkcdwjcid7zhvdycd"))))
   (cons "obstore-784e0ac535de"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/tracing/tracing-0.1.41.crate")
           (file-name "tracing-0.1.41.crate")
           (sha256
            (base32 "1l5xrzyjfyayrwhvhldfnwdyligi1mpqm8mzbi2m1d6y6p2hlkkq"))))
   (cons "obstore-81383ab64e72"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/tracing-attributes/tracing-attributes-0.1.30.crate")
           (file-name "tracing-attributes-0.1.30.crate")
           (sha256
            (base32 "00v9bhfgfg3v101nmmy7s3vdwadb7ngc8c1iw6wai9vj9sv3lf41"))))
   (cons "obstore-b9d12581f227"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/tracing-core/tracing-core-0.1.34.crate")
           (file-name "tracing-core-0.1.34.crate")
           (sha256
            (base32 "0y3nc4mpnr79rzkrcylv5f5bnjjp19lsxwis9l4kzs97ya0jbldr"))))
   (cons "obstore-e421abadd41a"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/try-lock/try-lock-0.2.5.crate")
           (file-name "try-lock-0.2.5.crate")
           (sha256
            (base32 "0jqijrrvm1pyq34zn1jmy2vihd4jcrjlvsh4alkjahhssjnsn8g4"))))
   (cons "obstore-1dccffe3ce07"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/typenum/typenum-1.18.0.crate")
           (file-name "typenum-1.18.0.crate")
           (sha256
            (base32 "0gwgz8n91pv40gabrr1lzji0b0hsmg0817njpy397bq7rvizzk0x"))))
   (cons "obstore-75b844d17643"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/unicase/unicase-2.8.1.crate")
           (file-name "unicase-2.8.1.crate")
           (sha256
            (base32 "0fd5ddbhpva7wrln2iah054ar2pc1drqjcll0f493vj3fv8l9f3m"))))
   (cons "obstore-5a5f39404a5d"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/unicode-ident/unicode-ident-1.0.18.crate")
           (file-name "unicode-ident-1.0.18.crate")
           (sha256
            (base32 "04k5r6sijkafzljykdq26mhjpmhdx4jwzvn1lh90g9ax9903jpss"))))
   (cons "obstore-4a1a07cc7db3"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/unicode-width/unicode-width-0.2.1.crate")
           (file-name "unicode-width-0.2.1.crate")
           (sha256
            (base32 "0k0mlq7xy1y1kq6cgv1r2rs2knn6rln3g3af50rhi0dkgp60f6ja"))))
   (cons "obstore-8ecb6da28b8a"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/untrusted/untrusted-0.9.0.crate")
           (file-name "untrusted-0.9.0.crate")
           (sha256
            (base32 "1ha7ib98vkc538x0z60gfn0fc5whqdd85mb87dvisdcaifi6vjwf"))))
   (cons "obstore-32f8b686cadd"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/url/url-2.5.4.crate")
           (file-name "url-2.5.4.crate")
           (sha256
            (base32 "0q6sgznyy2n4l5lm16zahkisvc9nip9aa5q1pps7656xra3bdy1j"))))
   (cons "obstore-b6c140620e7f"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/utf8_iter/utf8_iter-1.0.4.crate")
           (file-name "utf8_iter-1.0.4.crate")
           (sha256
            (base32 "1gmna9flnj8dbyd8ba17zigrp9c4c3zclngf5lnb5yvz1ri41hdn"))))
   (cons "obstore-29790946404f"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/walkdir/walkdir-2.5.0.crate")
           (file-name "walkdir-2.5.0.crate")
           (sha256
            (base32 "0jsy7a710qv8gld5957ybrnc07gavppp963gs32xk4ag8130jy99"))))
   (cons "obstore-bfa7760aed19"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/want/want-0.3.1.crate")
           (file-name "want-0.3.1.crate")
           (sha256
            (base32 "03hbfrnvqqdchb5kgxyavb9jabwza0dmh2vw5kg0dq8rxl57d9xz"))))
   (cons "obstore-9683f9a5a998"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/wasi/wasi-0.14.2+wasi-0.2.4.crate")
           (file-name "wasi-0.14.2+wasi-0.2.4.crate")
           (sha256
            (base32 "1cwcqjr3dgdq8j325awgk8a715h0hg0f7jqzsb077n4qm6jzk0wn"))))
   (cons "obstore-1edc8929d749"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/wasm-bindgen/wasm-bindgen-0.2.100.crate")
           (file-name "wasm-bindgen-0.2.100.crate")
           (sha256
            (base32 "1x8ymcm6yi3i1rwj78myl1agqv2m86i648myy3lc97s9swlqkp0y"))))
   (cons "obstore-2f0a0651a5c2"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/wasm-bindgen-backend/wasm-bindgen-backend-0.2.100.crate")
           (file-name "wasm-bindgen-backend-0.2.100.crate")
           (sha256
            (base32 "1ihbf1hq3y81c4md9lyh6lcwbx6a5j0fw4fygd423g62lm8hc2ig"))))
   (cons "obstore-555d470ec0bc"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/wasm-bindgen-futures/wasm-bindgen-futures-0.4.50.crate")
           (file-name "wasm-bindgen-futures-0.4.50.crate")
           (sha256
            (base32 "0q8ymi6i9r3vxly551dhxcyai7nc491mspj0j1wbafxwq074fpam"))))
   (cons "obstore-7fe63fc6d09e"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/wasm-bindgen-macro/wasm-bindgen-macro-0.2.100.crate")
           (file-name "wasm-bindgen-macro-0.2.100.crate")
           (sha256
            (base32 "01xls2dvzh38yj17jgrbiib1d3nyad7k2yw9s0mpklwys333zrkz"))))
   (cons "obstore-8ae87ea40c9f"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/wasm-bindgen-macro-support/wasm-bindgen-macro-support-0.2.100.crate")
           (file-name "wasm-bindgen-macro-support-0.2.100.crate")
           (sha256
            (base32 "1plm8dh20jg2id0320pbmrlsv6cazfv6b6907z19ys4z1jj7xs4a"))))
   (cons "obstore-1a05d73b933a"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/wasm-bindgen-shared/wasm-bindgen-shared-0.2.100.crate")
           (file-name "wasm-bindgen-shared-0.2.100.crate")
           (sha256
            (base32 "0gffxvqgbh9r9xl36gprkfnh3w9gl8wgia6xrin7v11sjcxxf18s"))))
   (cons "obstore-15053d8d85c7"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/wasm-streams/wasm-streams-0.4.2.crate")
           (file-name "wasm-streams-0.4.2.crate")
           (sha256
            (base32 "0rddn007hp6k2cm91mm9y33n79b0jxv0c3znzszcvv67hn6ks18m"))))
   (cons "obstore-33b6dd2ef918"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/web-sys/web-sys-0.3.77.crate")
           (file-name "web-sys-0.3.77.crate")
           (sha256
            (base32 "1lnmc1ffbq34qw91nndklqqm75rasaffj2g4f8h1yvqqz4pdvdik"))))
   (cons "obstore-cf221c93e13a"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/winapi-util/winapi-util-0.1.9.crate")
           (file-name "winapi-util-0.1.9.crate")
           (sha256
            (base32 "1fqhkcl9scd230cnfj8apfficpf5c9vhwnk4yy9xfc1sw69iq8ng"))))
   (cons "obstore-c0fdd3ddb906"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/windows-core/windows-core-0.61.2.crate")
           (file-name "windows-core-0.61.2.crate")
           (sha256
            (base32 "1qsa3iw14wk4ngfl7ipcvdf9xyq456ms7cx2i9iwf406p7fx7zf0"))))
   (cons "obstore-a47fddd13af0"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/windows-implement/windows-implement-0.60.0.crate")
           (file-name "windows-implement-0.60.0.crate")
           (sha256
            (base32 "0dm88k3hlaax85xkls4gf597ar4z8m5vzjjagzk910ph7b8xszx4"))))
   (cons "obstore-bd9211b69f8d"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/windows-interface/windows-interface-0.59.1.crate")
           (file-name "windows-interface-0.59.1.crate")
           (sha256
            (base32 "1a4zr8740gyzzhq02xgl6vx8l669jwfby57xgf0zmkcdkyv134mx"))))
   (cons "obstore-5e6ad25900d5"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/windows-link/windows-link-0.1.3.crate")
           (file-name "windows-link-0.1.3.crate")
           (sha256
            (base32 "12kr1p46dbhpijr4zbwr2spfgq8i8c5x55mvvfmyl96m01cx4sjy"))))
   (cons "obstore-56f42bd332cc"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/windows-result/windows-result-0.3.4.crate")
           (file-name "windows-result-0.3.4.crate")
           (sha256
            (base32 "1il60l6idrc6hqsij0cal0mgva6n3w6gq4ziban8wv6c6b9jpx2n"))))
   (cons "obstore-56e6c93f3a0c"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/windows-strings/windows-strings-0.4.2.crate")
           (file-name "windows-strings-0.4.2.crate")
           (sha256
            (base32 "0mrv3plibkla4v5kaakc2rfksdd0b14plcmidhbkcfqc78zwkrjn"))))
   (cons "obstore-282be5f36a8c"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/windows-sys/windows-sys-0.52.0.crate")
           (file-name "windows-sys-0.52.0.crate")
           (sha256
            (base32 "0gd3v4ji88490zgb6b5mq5zgbvwv7zx1ibn8v3x83rwcdbryaar8"))))
   (cons "obstore-1e38bc4d79ed"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/windows-sys/windows-sys-0.59.0.crate")
           (file-name "windows-sys-0.59.0.crate")
           (sha256
            (base32 "0fw5672ziw8b3zpmnbp9pdv1famk74f1l9fcbc3zsrzdg56vqf0y"))))
   (cons "obstore-f2f500e4d282"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/windows-sys/windows-sys-0.60.2.crate")
           (file-name "windows-sys-0.60.2.crate")
           (sha256
            (base32 "1jrbc615ihqnhjhxplr2kw7rasrskv9wj3lr80hgfd42sbj01xgj"))))
   (cons "obstore-9b724f72796e"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/windows-targets/windows-targets-0.52.6.crate")
           (file-name "windows-targets-0.52.6.crate")
           (sha256
            (base32 "0wwrx625nwlfp7k93r2rra568gad1mwd888h1jwnl0vfg5r4ywlv"))))
   (cons "obstore-c66f69fcc9ce"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/windows-targets/windows-targets-0.53.2.crate")
           (file-name "windows-targets-0.53.2.crate")
           (sha256
            (base32 "1vwanhx2br7dh8mmrszdbcf01bccjr01mcyxcscxl4ffr7y6jvy6"))))
   (cons "obstore-32a4622180e7"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/windows_aarch64_gnullvm/windows_aarch64_gnullvm-0.52.6.crate")
           (file-name "windows_aarch64_gnullvm-0.52.6.crate")
           (sha256
            (base32 "1lrcq38cr2arvmz19v32qaggvj8bh1640mdm9c2fr877h0hn591j"))))
   (cons "obstore-86b8d5f90ddd"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/windows_aarch64_gnullvm/windows_aarch64_gnullvm-0.53.0.crate")
           (file-name "windows_aarch64_gnullvm-0.53.0.crate")
           (sha256
            (base32 "0r77pbpbcf8bq4yfwpz2hpq3vns8m0yacpvs2i5cn6fx1pwxbf46"))))
   (cons "obstore-09ec2a7bb152"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/windows_aarch64_msvc/windows_aarch64_msvc-0.52.6.crate")
           (file-name "windows_aarch64_msvc-0.52.6.crate")
           (sha256
            (base32 "0sfl0nysnz32yyfh773hpi49b1q700ah6y7sacmjbqjjn5xjmv09"))))
   (cons "obstore-c7651a1f62a1"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/windows_aarch64_msvc/windows_aarch64_msvc-0.53.0.crate")
           (file-name "windows_aarch64_msvc-0.53.0.crate")
           (sha256
            (base32 "0v766yqw51pzxxwp203yqy39ijgjamp54hhdbsyqq6x1c8gilrf7"))))
   (cons "obstore-8e9b5ad5ab80"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/windows_i686_gnu/windows_i686_gnu-0.52.6.crate")
           (file-name "windows_i686_gnu-0.52.6.crate")
           (sha256
            (base32 "02zspglbykh1jh9pi7gn8g1f97jh1rrccni9ivmrfbl0mgamm6wf"))))
   (cons "obstore-c1dc67659d35"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/windows_i686_gnu/windows_i686_gnu-0.53.0.crate")
           (file-name "windows_i686_gnu-0.53.0.crate")
           (sha256
            (base32 "1hvjc8nv95sx5vdd79fivn8bpm7i517dqyf4yvsqgwrmkmjngp61"))))
   (cons "obstore-0eee52d38c09"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/windows_i686_gnullvm/windows_i686_gnullvm-0.52.6.crate")
           (file-name "windows_i686_gnullvm-0.52.6.crate")
           (sha256
            (base32 "0rpdx1537mw6slcpqa0rm3qixmsb79nbhqy5fsm3q2q9ik9m5vhf"))))
   (cons "obstore-9ce6ccbdedbf"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/windows_i686_gnullvm/windows_i686_gnullvm-0.53.0.crate")
           (file-name "windows_i686_gnullvm-0.53.0.crate")
           (sha256
            (base32 "04df1in2k91qyf1wzizvh560bvyzq20yf68k8xa66vdzxnywrrlw"))))
   (cons "obstore-240948bc05c5"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/windows_i686_msvc/windows_i686_msvc-0.52.6.crate")
           (file-name "windows_i686_msvc-0.52.6.crate")
           (sha256
            (base32 "0rkcqmp4zzmfvrrrx01260q3xkpzi6fzi2x2pgdcdry50ny4h294"))))
   (cons "obstore-581fee95406b"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/windows_i686_msvc/windows_i686_msvc-0.53.0.crate")
           (file-name "windows_i686_msvc-0.53.0.crate")
           (sha256
            (base32 "0pcvb25fkvqnp91z25qr5x61wyya12lx8p7nsa137cbb82ayw7sq"))))
   (cons "obstore-147a5c80aabf"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/windows_x86_64_gnu/windows_x86_64_gnu-0.52.6.crate")
           (file-name "windows_x86_64_gnu-0.52.6.crate")
           (sha256
            (base32 "0y0sifqcb56a56mvn7xjgs8g43p33mfqkd8wj1yhrgxzma05qyhl"))))
   (cons "obstore-2e55b5ac9ea3"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/windows_x86_64_gnu/windows_x86_64_gnu-0.53.0.crate")
           (file-name "windows_x86_64_gnu-0.53.0.crate")
           (sha256
            (base32 "1flh84xkssn1n6m1riddipydcksp2pdl45vdf70jygx3ksnbam9f"))))
   (cons "obstore-24d5b23dc417"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/windows_x86_64_gnullvm/windows_x86_64_gnullvm-0.52.6.crate")
           (file-name "windows_x86_64_gnullvm-0.52.6.crate")
           (sha256
            (base32 "03gda7zjx1qh8k9nnlgb7m3w3s1xkysg55hkd1wjch8pqhyv5m94"))))
   (cons "obstore-0a6e035dd059"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/windows_x86_64_gnullvm/windows_x86_64_gnullvm-0.53.0.crate")
           (file-name "windows_x86_64_gnullvm-0.53.0.crate")
           (sha256
            (base32 "0mvc8119xpbi3q2m6mrjcdzl6afx4wffacp13v76g4jrs1fh6vha"))))
   (cons "obstore-589f6da84c64"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/windows_x86_64_msvc/windows_x86_64_msvc-0.52.6.crate")
           (file-name "windows_x86_64_msvc-0.52.6.crate")
           (sha256
            (base32 "1v7rb5cibyzx8vak29pdrk8nx9hycsjs4w0jgms08qk49jl6v7sq"))))
   (cons "obstore-271414315aff"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/windows_x86_64_msvc/windows_x86_64_msvc-0.53.0.crate")
           (file-name "windows_x86_64_msvc-0.53.0.crate")
           (sha256
            (base32 "11h4i28hq0zlnjcaqi2xdxr7ibnpa8djfggch9rki1zzb8qi8517"))))
   (cons "obstore-f3edebf492c8"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/winnow/winnow-0.7.12.crate")
           (file-name "winnow-0.7.12.crate")
           (sha256
            (base32 "159y8inpy86xswmr4yig9hxss0v2fssyqy1kk12504n8jbsfpvgk"))))
   (cons "obstore-ee4f61950cfe"
         (origin
           (method url-fetch)
           (uri "https://codeload.github.com/bytecodealliance/wit-bindgen/tar.gz/f2393e6e98fa5f9236cac580db8a3fc9de6a4b70")
           (file-name "bytecodealliance-f2393e6e98fa5f9236cac580db8a3fc9de6a4b70.tar.gz")
           (sha256
            (base32 "17gvgw8fib2f1i01j69wlsvlynn837yf9pqmjz59cbpy1jan2kzf"))))
   (cons "obstore-ea2f10b9bb09"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/writeable/writeable-0.6.1.crate")
           (file-name "writeable-0.6.1.crate")
           (sha256
            (base32 "1fx29zncvbrqzgz7li88vzdm8zvgwgwy2r9bnjqxya09pfwi0bza"))))
   (cons "obstore-5f41bb01b822"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/yoke/yoke-0.8.0.crate")
           (file-name "yoke-0.8.0.crate")
           (sha256
            (base32 "1k4mfr48vgi7wh066y11b7v1ilakghlnlhw9snzz8vi2p00vnhaz"))))
   (cons "obstore-38da3c9736e1"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/yoke-derive/yoke-derive-0.8.0.crate")
           (file-name "yoke-derive-0.8.0.crate")
           (sha256
            (base32 "1dha5jrjz9jaq8kmxq1aag86b98zbnm9lyjrihy5sv716sbkrniq"))))
   (cons "obstore-1039dd0d3c31"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/zerocopy/zerocopy-0.8.26.crate")
           (file-name "zerocopy-0.8.26.crate")
           (sha256
            (base32 "0bvsj0qzq26zc6nlrm3z10ihvjspyngs7n0jw1fz031i7h6xsf8h"))))
   (cons "obstore-9ecf5b4cc536"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/zerocopy-derive/zerocopy-derive-0.8.26.crate")
           (file-name "zerocopy-derive-0.8.26.crate")
           (sha256
            (base32 "10aiywi5qkha0mpsnb1zjwi44wl2rhdncaf3ykbp4i9nqm65pkwy"))))
   (cons "obstore-50cc42e0333e"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/zerofrom/zerofrom-0.1.6.crate")
           (file-name "zerofrom-0.1.6.crate")
           (sha256
            (base32 "19dyky67zkjichsb7ykhv0aqws3q0jfvzww76l66c19y6gh45k2h"))))
   (cons "obstore-d71e5d6e06ab"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/zerofrom-derive/zerofrom-derive-0.1.6.crate")
           (file-name "zerofrom-derive-0.1.6.crate")
           (sha256
            (base32 "00l5niw7c1b0lf1vhvajpjmcnbdp2vn96jg4nmkhq2db0rp5s7np"))))
   (cons "obstore-ced3678a2879"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/zeroize/zeroize-1.8.1.crate")
           (file-name "zeroize-1.8.1.crate")
           (sha256
            (base32 "1pjdrmjwmszpxfd7r860jx54cyk94qk59x13sc307cvr5256glyf"))))
   (cons "obstore-36f0bbd47858"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/zerotrie/zerotrie-0.2.2.crate")
           (file-name "zerotrie-0.2.2.crate")
           (sha256
            (base32 "15gmka7vw5k0d24s0vxgymr2j6zn2iwl12wpmpnpjgsqg3abpw1n"))))
   (cons "obstore-4a05eb080e01"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/zerovec/zerovec-0.11.2.crate")
           (file-name "zerovec-0.11.2.crate")
           (sha256
            (base32 "0a2457fmz39k9vrrj3rm82q5ykdhgxgbwfz2r6fa6nq11q4fn1aa"))))
   (cons "obstore-5b96237efa0c"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/zerovec-derive/zerovec-derive-0.11.1.crate")
           (file-name "zerovec-derive-0.11.1.crate")
           (sha256
            (base32 "13zms8hj7vzpfswypwggyfr4ckmyc7v3di49pmj8r1qcz9z275jv"))))
   (cons "obstore-dbbe9647ede6"
         (origin
           (method url-fetch)
           (uri "https://codeload.github.com/alex/pyo3-file/tar.gz/82b96dc188a48b88421f41b24cb13da114fd2fe8")
           (file-name "alex-82b96dc188a48b88421f41b24cb13da114fd2fe8.tar.gz")
           (sha256
            (base32 "1j5zr744nn5y5i13q604ffp551wql2jb0lx0spxih0z6xm3rdgnv"))))
   (cons "python-olm-0d542e0c8804"
         (origin
           (method url-fetch)
           (uri "https://gitlab.matrix.org/matrix-org/olm/-/raw/3.2.16/LICENSE")
           (file-name "LICENSE")
           (sha256
            (base32 "1525x4wbj4by518r90nphb39s532lyjhvc3yyfkrmqq4i062wm0d"))))
   (cons "python-olm-a1c47fce2505"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/b8/eb/23ca73cbdc8c7466a774e515dfd917d9fbe747c1257059246fdc63093f04/python-olm-3.2.16.tar.gz")
           (file-name "python-olm-3.2.16.tar.gz")
           (sha256
            (base32 "1ja3jsj4b5g8x5pfkva6jr8q9m2fxp5r8xp185la3dq54p77zi51"))))
   (cons "sentencepiece-3d2b5e824b56"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/cc/33/ea3cb3839607eb175da835244a798f797f478c5ddf0e8ecdf57ea85a4c70/sentencepiece-0.2.2.tar.gz")
           (file-name "sentencepiece-0.2.2.tar.gz")
           (sha256
            (base32 "1xmxz6g7ij7cyd1c23rmwywvpsq5zrz8k45lqy6h68jn9f15warx"))))
   (cons "tflite-runtime-71c6915d0426"
         (origin
           (method url-fetch)
           (uri "https://raw.githubusercontent.com/tensorflow/tensorflow/4dacf3f368eb7965e9b5c3bbdd5193986081c3b2/LICENSE")
           (file-name "LICENSE")
           (sha256
            (base32 "0rgc3byq8sdy1qhk85f0bjs7iij2d4klgvcv6fh74mr60ifr3iki"))))
   (cons "tflite-runtime-832274d627f3"
         (origin
           (method url-fetch)
           (uri "https://codeload.github.com/tensorflow/tensorflow/tar.gz/4dacf3f368eb7965e9b5c3bbdd5193986081c3b2")
           (file-name "tensorflow-4dacf3f368eb7965e9b5c3bbdd5193986081c3b2.tar.gz")
           (sha256
            (base32 "1nz8iz6js64f53l1m2bycyr5c238mk3qshyfpabyqw7k4zb788l3"))))
   (cons "tokenizers-473b83b915e5"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/73/6f/f80cfef4a312e1fb34baf7d85c72d4411afde10978d4657f8cdd811d3ccc/tokenizers-0.22.2.tar.gz")
           (file-name "tokenizers-0.22.2.tar.gz")
           (sha256
            (base32 "05zr50g7y1ql1an10qz1gghikx7adn013vhydlvaliz52nwq6fs7"))))
   (cons "tokenizers-ddd31a130427"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/aho-corasick/aho-corasick-1.1.4.crate")
           (file-name "aho-corasick-1.1.4.crate")
           (sha256
            (base32 "00a32wb2h07im3skkikc495jvncf62jl6s96vwc7bhi70h9imlyx"))))
   (cons "tokenizers-43d5b281e737"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/anstream/anstream-0.6.21.crate")
           (file-name "anstream-0.6.21.crate")
           (sha256
            (base32 "0jjgixms4qjj58dzr846h2s29p8w7ynwr9b9x6246m1pwy0v5ma3"))))
   (cons "tokenizers-5192cca8006f"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/anstyle/anstyle-1.0.13.crate")
           (file-name "anstyle-1.0.13.crate")
           (sha256
            (base32 "0y2ynjqajpny6q0amvfzzgw0gfw3l47z85km4gvx87vg02lcr4ji"))))
   (cons "tokenizers-4e7644824f0a"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/anstyle-parse/anstyle-parse-0.2.7.crate")
           (file-name "anstyle-parse-0.2.7.crate")
           (sha256
            (base32 "1hhmkkfr95d462b3zf6yl2vfzdqfy5726ya572wwg8ha9y148xjf"))))
   (cons "tokenizers-9e1b586273c5"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/base64/base64-0.13.1.crate")
           (file-name "base64-0.13.1.crate")
           (sha256
            (base32 "1s494mqmzjb766fy1kqlccgfg2sdcjb6hzbvzqv2jw65fdi5h6wy"))))
   (cons "tokenizers-dec551ab6e75"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/castaway/castaway-0.2.4.crate")
           (file-name "castaway-0.2.4.crate")
           (sha256
            (base32 "0nn5his5f8q20nkyg1nwb40xc19a08yaj4y76a8q2y3mdsmm3ify"))))
   (cons "tokenizers-c481bdbf0ed3"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/cc/cc-1.2.48.crate")
           (file-name "cc-1.2.48.crate")
           (sha256
            (base32 "0fk37741p34v904a49zcli9b65fmmir7sa06z3v95f6k1szvv0f4"))))
   (cons "tokenizers-b05b61dc5112"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/colorchoice/colorchoice-1.0.4.crate")
           (file-name "colorchoice-1.0.4.crate")
           (sha256
            (base32 "0x8ymkz1xr77rcj1cfanhf416pc4v681gmkc9dzb3jqja7f62nxh"))))
   (cons "tokenizers-3fdb1325a1ce"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/compact_str/compact_str-0.9.0.crate")
           (file-name "compact_str-0.9.0.crate")
           (sha256
            (base32 "0ykhh2scg32lmzxak107pmby6fmnz7qbhsi9i8g9iknfl4ji7nrz"))))
   (cons "tokenizers-b430743a6eb1"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/console/console-0.16.1.crate")
           (file-name "console-0.16.1.crate")
           (sha256
            (base32 "1x4x6vfi1s55nbr4i77b9r87s213h46lq396sij9fkmidqx78c5l"))))
   (cons "tokenizers-fc7f46116c46"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/darling/darling-0.20.11.crate")
           (file-name "darling-0.20.11.crate")
           (sha256
            (base32 "1vmlphlrlw4f50z16p4bc9p5qwdni1ba95qmxfrrmzs6dh8lczzw"))))
   (cons "tokenizers-0d00b9596d18"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/darling_core/darling_core-0.20.11.crate")
           (file-name "darling_core-0.20.11.crate")
           (sha256
            (base32 "0bj1af6xl4ablnqbgn827m43b8fiicgv180749f5cphqdmcvj00d"))))
   (cons "tokenizers-fc34b93ccb38"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/darling_macro/darling_macro-0.20.11.crate")
           (file-name "darling_macro-0.20.11.crate")
           (sha256
            (base32 "1bbfbc2px6sj1pqqq97bgqn6c8xdnb2fmz66f7f40nrqrcybjd7w"))))
   (cons "tokenizers-06d2e3287df1"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/dary_heap/dary_heap-0.3.8.crate")
           (file-name "dary_heap-0.3.8.crate")
           (sha256
            (base32 "010zfln7257vq9fsgcslkqs5gmcm1ahrri118bkhgh7igllf7lh6"))))
   (cons "tokenizers-507dfb09ea8b"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/derive_builder/derive_builder-0.20.2.crate")
           (file-name "derive_builder-0.20.2.crate")
           (sha256
            (base32 "0is9z7v3kznziqsxa5jqji3ja6ay9wzravppzhcaczwbx84znzah"))))
   (cons "tokenizers-2d5bcf7b024d"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/derive_builder_core/derive_builder_core-0.20.2.crate")
           (file-name "derive_builder_core-0.20.2.crate")
           (sha256
            (base32 "1s640r6q46c2iiz25sgvxw3lk6b6v5y8hwylng7kas2d09xwynrd"))))
   (cons "tokenizers-ab63b0e2bf4d"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/derive_builder_macro/derive_builder_macro-0.20.2.crate")
           (file-name "derive_builder_macro-0.20.2.crate")
           (sha256
            (base32 "0g1zznpqrmvjlp2w7p0jzsjvpmw5rvdag0rfyypjhnadpzib0qxb"))))
   (cons "tokenizers-1bf3c259d255"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/env_filter/env_filter-0.1.4.crate")
           (file-name "env_filter-0.1.4.crate")
           (sha256
            (base32 "1qk8yn4lsqzxsz025kf4kaabika6aidykqih3c2p1jjms9cw5wqv"))))
   (cons "tokenizers-13c863f09040"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/env_logger/env_logger-0.11.8.crate")
           (file-name "env_logger-0.11.8.crate")
           (sha256
            (base32 "17q6zbjam4wq75fa3m4gvvmv3rj3ch25abwbm84b28a0j3q67j0k"))))
   (cons "tokenizers-d817e038c303"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/esaxx-rs/esaxx-rs-0.1.10.crate")
           (file-name "esaxx-rs-0.1.10.crate")
           (sha256
            (base32 "1rm6vm5yr7s3n5ly7k9x9j6ra5p2l2ld151gnaya8x03qcwf05yq"))))
   (cons "tokenizers-3a3076410a55"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/find-msvc-tools/find-msvc-tools-0.1.5.crate")
           (file-name "find-msvc-tools-0.1.5.crate")
           (sha256
            (base32 "0i1ql02y37bc7xywkqz10kx002vpz864vc4qq88h1jam190pcc1s"))))
   (cons "tokenizers-b9e0384b6195"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/ident_case/ident_case-1.0.1.crate")
           (file-name "ident_case-1.0.1.crate")
           (sha256
            (base32 "0fac21q6pwns8gh1hz3nbq15j8fi441ncl6w4vlnd1cmc55kiq5r"))))
   (cons "tokenizers-9375e112e4b4"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/indicatif/indicatif-0.18.3.crate")
           (file-name "indicatif-0.18.3.crate")
           (sha256
            (base32 "126b1nzklazk3mc5pazvch0s6rawai9ij0bc3hdyqqxlwh9f2xck"))))
   (cons "tokenizers-49cce2b81f20"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/jiff/jiff-0.2.16.crate")
           (file-name "jiff-0.2.16.crate")
           (sha256
            (base32 "0ddvdlmg7a3glbbq70hj6jfyraxplvhc4ny3xziyg6103ywf5k29"))))
   (cons "tokenizers-980af8b43c3a"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/jiff-static/jiff-static-0.2.16.crate")
           (file-name "jiff-static-0.2.16.crate")
           (sha256
            (base32 "0sgsa0cgx2p036x37lj279srz0vhh7n6gqdc979xim9s7jsgh2lq"))))
   (cons "tokenizers-2874a2af47a2"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/libc/libc-0.2.177.crate")
           (file-name "libc-0.2.177.crate")
           (sha256
            (base32 "0xjrn69cywaii1iq2lib201bhlvan7czmrm604h5qcm28yps4x18"))))
   (cons "tokenizers-df1d3c3b53da"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/linux-raw-sys/linux-raw-sys-0.11.0.crate")
           (file-name "linux-raw-sys-0.11.0.crate")
           (sha256
            (base32 "0fghx0nn8nvbz5yzgizfcwd6ap2pislp68j8c1bwyr6sacxkq7fz"))))
   (cons "tokenizers-34080505efa8"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/log/log-0.4.28.crate")
           (file-name "log-0.4.28.crate")
           (sha256
            (base32 "0cklpzrpxafbaq1nyxarhnmcw9z3xcjrad3ch55mmr58xw2ha21l"))))
   (cons "tokenizers-65049d792369"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/macro_rules_attribute/macro_rules_attribute-0.2.2.crate")
           (file-name "macro_rules_attribute-0.2.2.crate")
           (sha256
            (base32 "0835cx5bdsj06yffaspqqlids57bn3cwxp0x1g6l10394dwrs135"))))
   (cons "tokenizers-670fdfda8975"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/macro_rules_attribute-proc_macro/macro_rules_attribute-proc_macro-0.2.2.crate")
           (file-name "macro_rules_attribute-proc_macro-0.2.2.crate")
           (sha256
            (base32 "0c1s3lgkrdl5l2zmz6jc5g90zkq5w9islgn19alc86vmi7ddy3v7"))))
   (cons "tokenizers-68354c5c6bd3"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/minimal-lexical/minimal-lexical-0.2.1.crate")
           (file-name "minimal-lexical-0.2.1.crate")
           (sha256
            (base32 "16ppc5g84aijpri4jzv14rvcnslvlpphbszc7zzp6vfkddf4qdb8"))))
   (cons "tokenizers-69d83b0086dc"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/mio/mio-1.1.0.crate")
           (file-name "mio-1.1.0.crate")
           (sha256
            (base32 "0wr816q3jrjwiajvw807lgi540i9s6r78a5fx4ycz3nwhq03pn39"))))
   (cons "tokenizers-3341a273f6c9"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/monostate/monostate-0.1.18.crate")
           (file-name "monostate-0.1.18.crate")
           (sha256
            (base32 "0rzgfqn1p7lfrx6hv6pnkdffkc5sgckbf5wgj3qvxmf9yrrs4h9k"))))
   (cons "tokenizers-e4db6d5580af"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/monostate-impl/monostate-impl-0.1.18.crate")
           (file-name "monostate-impl-0.1.18.crate")
           (sha256
            (base32 "1sg7wsfnz8smn8wpd3gl9xbiimbgl978s1jr5ycvymxgh1anvnz4"))))
   (cons "tokenizers-d273983c5a65"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/nom/nom-7.1.3.crate")
           (file-name "nom-7.1.3.crate")
           (sha256
            (base32 "0jha9901wxam390jcf5pfa0qqfrgh8li787jx2ip0yk5b8y9hwyj"))))
   (cons "tokenizers-336b9c63443a"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/onig/onig-6.5.1.crate")
           (file-name "onig-6.5.1.crate")
           (sha256
            (base32 "1w63vbzamn2v9jpnlj3wkglapqss0fcvhhd8pqafzkis8iirqsrk"))))
   (cons "tokenizers-c7f86c6eef3d"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/onig_sys/onig_sys-69.9.1.crate")
           (file-name "onig_sys-69.9.1.crate")
           (sha256
            (base32 "1p17cxzqnpqzpzamh7aqwpagxlnbhzs6myxw4dgz2v9xxxp6ry67"))))
   (cons "tokenizers-57c0d7b74b56"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/paste/paste-1.0.15.crate")
           (file-name "paste-1.0.15.crate")
           (sha256
            (base32 "02pxffpdqkapy292harq6asfjvadgp1s005fip9ljfsn9fvxgh2p"))))
   (cons "tokenizers-7edddbd0b52d"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/pkg-config/pkg-config-0.3.32.crate")
           (file-name "pkg-config-0.3.32.crate")
           (sha256
            (base32 "0k4h3gnzs94sjb2ix6jyksacs52cf1fanpwsmlhjnwrdnp8dppby"))))
   (cons "tokenizers-5ee95bc4ef87"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/proc-macro2/proc-macro2-1.0.103.crate")
           (file-name "proc-macro2-1.0.103.crate")
           (sha256
            (base32 "1s29bz20xl2qk5ffs2mbdqknaj43ri673dz86axdbf47xz25psay"))))
   (cons "tokenizers-a338cc41d27e"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/quote/quote-1.0.42.crate")
           (file-name "quote-1.0.42.crate")
           (sha256
            (base32 "0zq6yc7dhpap669m27rb4qfbiywxfah17z6fwvfccv3ys90wqf53"))))
   (cons "tokenizers-2964d0cf57a3"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/rayon-cond/rayon-cond-0.4.0.crate")
           (file-name "rayon-cond-0.4.0.crate")
           (sha256
            (base32 "13s38wvsmmb2ak6ljdcqnw3cg5biaa5lmlc3h5pa1rx3az7x0r19"))))
   (cons "tokenizers-843bc0191f75"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/regex/regex-1.12.2.crate")
           (file-name "regex-1.12.2.crate")
           (sha256
            (base32 "1m14zkg6xmkb0q5ah3y39cmggclsjdr1wpxfa4kf5wvm3wcw0fw4"))))
   (cons "tokenizers-5276caf25ac8"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/regex-automata/regex-automata-0.4.13.crate")
           (file-name "regex-automata-0.4.13.crate")
           (sha256
            (base32 "070z0j23pjfidqz0z89id1fca4p572wxpcr20a0qsv68bbrclxjj"))))
   (cons "tokenizers-7a2d987857b3"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/regex-syntax/regex-syntax-0.8.8.crate")
           (file-name "regex-syntax-0.8.8.crate")
           (sha256
            (base32 "0n7ggnpk0r32rzgnycy5xrc1yp2kq19m6pz98ch3c6dkaxw9hbbs"))))
   (cons "tokenizers-cd15f8a2c555"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/rustix/rustix-1.1.2.crate")
           (file-name "rustix-1.1.2.crate")
           (sha256
            (base32 "0gpz343xfzx16x82s1x336n0kr49j02cvhgxdvaq86jmqnigh5fd"))))
   (cons "tokenizers-402a6f66d8c7"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/serde_json/serde_json-1.0.145.crate")
           (file-name "serde_json-1.0.145.crate")
           (sha256
            (base32 "1767y6kxjf7gwpbv8bkhgwc50nhg46mqwm9gy9n122f7v1k6yaj0"))))
   (cons "tokenizers-7664a098b8e6"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/signal-hook-registry/signal-hook-registry-1.4.7.crate")
           (file-name "signal-hook-registry-1.4.7.crate")
           (sha256
            (base32 "1bgdimrfqcldbplryknv87gywcdj9v29l3nwqbybs5p6p2ca0r3n"))))
   (cons "tokenizers-5851699c4033"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/spm_precompiled/spm_precompiled-0.1.4.crate")
           (file-name "spm_precompiled-0.1.4.crate")
           (sha256
            (base32 "09pkdk2abr8xf4pb9kq3rk80dgziq6vzfk7aywv3diik82f6jlaq"))))
   (cons "tokenizers-7da8b5736845"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/strsim/strsim-0.11.1.crate")
           (file-name "strsim-0.11.1.crate")
           (sha256
            (base32 "0kzvqlw8hxqb7y598w1s0hxlnmi84sg5vsipp3yg5na5d1rvba3x"))))
   (cons "tokenizers-390cc9a294ab"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/syn/syn-2.0.111.crate")
           (file-name "syn-2.0.111.crate")
           (sha256
            (base32 "11rf9l6435w525vhqmnngcnwsly7x4xx369fmaqvswdbjjicj31r"))))
   (cons "tokenizers-df7f62577c25"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/target-lexicon/target-lexicon-0.13.3.crate")
           (file-name "target-lexicon-0.13.3.crate")
           (sha256
            (base32 "0355pbycq0cj29h1rp176l57qnfwmygv7hwzchs7iq15gibn4zyz"))))
   (cons "tokenizers-2d31c77bdf42"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/tempfile/tempfile-3.23.0.crate")
           (file-name "tempfile-3.23.0.crate")
           (sha256
            (base32 "05igl2gml6z6i2va1bv49f9f1wb3f752c2i63lvlb9s2vxxwfc9d"))))
   (cons "tokenizers-ff360e02eab1"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/tokio/tokio-1.48.0.crate")
           (file-name "tokio-1.48.0.crate")
           (sha256
            (base32 "0244qva5pksy8gam6llf7bd6wbk2vkab9lx26yyf08dix810wdpz"))))
   (cons "tokenizers-af4078572095"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/tokio-macros/tokio-macros-2.6.0.crate")
           (file-name "tokio-macros-2.6.0.crate")
           (sha256
            (base32 "19czvgliginbzyhhfbmj77wazqn2y8g27y2nirfajdlm41bphh5g"))))
   (cons "tokenizers-43f613e4fa04"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/unicode-normalization-alignments/unicode-normalization-alignments-0.1.12.crate")
           (file-name "unicode-normalization-alignments-0.1.12.crate")
           (sha256
            (base32 "1pk2f3arh3qvdsmrsiri0gr5y5vqpk2gv1yjin0njvh4zbj17xj3"))))
   (cons "tokenizers-b4ac048d71ed"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/unicode-width/unicode-width-0.2.2.crate")
           (file-name "unicode-width-0.2.2.crate")
           (sha256
            (base32 "0m7jjzlcccw716dy9423xxh0clys8pfpllc5smvfxrzdf66h9b5l"))))
   (cons "tokenizers-39ec24b3121d"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/unicode_categories/unicode_categories-0.1.1.crate")
           (file-name "unicode_categories-0.1.1.crate")
           (sha256
            (base32 "0kp1d7fryxxm7hqywbk88yb9d1avsam9sg76xh36k5qx2arj9v1r"))))
   (cons "tokenizers-81e544489bf3"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/unit-prefix/unit-prefix-0.5.2.crate")
           (file-name "unit-prefix-0.5.2.crate")
           (sha256
            (base32 "18xr6yhdvlxrv51y6js9npa3qhkzc5b1z4skr5kfzn7kkd449rc1"))))
   (cons "tokenizers-fd74ec98b925"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/zerocopy/zerocopy-0.8.31.crate")
           (file-name "zerocopy-0.8.31.crate")
           (sha256
            (base32 "1hwqn8f0zd8h1a7qz2hxym4iaqyzk8kdxgalllydn2i5p6cfqx7x"))))
   (cons "tokenizers-d8a8d209fdf4"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/zerocopy-derive/zerocopy-derive-0.8.31.crate")
           (file-name "zerocopy-derive-0.8.31.crate")
           (sha256
            (base32 "0sjw20qqxbax8z8k9ifcmwjjlljjddpm0nmvih9zap7lzl4x5a6q"))))
   (cons "sherpa-onnx-core-cfc7749b96f6"
         (origin
           (method url-fetch)
           (uri "https://raw.githubusercontent.com/k2-fsa/sherpa-onnx/142807252687d81b40d6315f23470a1512a00de3/LICENSE")
           (file-name "LICENSE")
           (sha256
            (base32 "0c1xaay1fd00xgri0z447q2i8s3mpxqw9da27hfd6fznjsdp9iyg"))))
   (cons "sherpa-onnx-core-9f0c0a6998f1"
         (origin
           (method url-fetch)
           (uri "https://github.com/csukuangfj/onnxruntime-libs/releases/download/v1.27.0/onnxruntime-linux-x64-glibc2_17-Release-1.27.0.zip")
           (file-name "onnxruntime-linux-x64-glibc2_17-Release-1.27.0.zip")
           (sha256
            (base32 "002xjfhngpnnkkf1yhzxlk4j5adlpr1v9p7dkqwlrfgik1lhl34z"))))
   (cons "sherpa-onnx-core-cbcaaba0f667"
         (origin
           (method url-fetch)
           (uri "https://github.com/chriskohlhoff/asio/archive/refs/tags/asio-1-24-0.tar.gz")
           (file-name "asio-1-24-0.tar.gz")
           (sha256
            (base32 "0nwagadqqsqgzykpvbgkb8mh2fpvpvhsycvw39xph8k7yshapjnb"))))
   (cons "sherpa-onnx-core-ddba25bd35e9"
         (origin
           (method url-fetch)
           (uri "https://github.com/likle/cargs/archive/refs/tags/v1.0.3.tar.gz")
           (file-name "v1.0.3.tar.gz")
           (sha256
            (base32 "12zb6vl66sdawr871wqfsj2f1s4c3c02dh86qxdwgip96nyjbfnx"))))
   (cons "sherpa-onnx-core-e4e262cbe34f"
         (origin
           (method url-fetch)
           (uri "https://github.com/csukuangfj/espeak-ng/archive/ed530aa113046142eb5115cf2fc9157854d0ffe1.zip")
           (file-name "ed530aa113046142eb5115cf2fc9157854d0ffe1.zip")
           (sha256
            (base32 "1pgh2gnsjlxpy99pibpvx8q1z3kjyabk7fpij4gy4zsgwg5n5qp4"))))
   (cons "sherpa-onnx-core-8f14e024c709"
         (origin
           (method url-fetch)
           (uri "https://github.com/csukuangfj/hclust-cpp/archive/refs/tags/2026-02-25.tar.gz")
           (file-name "2026-02-25.tar.gz")
           (sha256
            (base32 "0mmb760xl4w8a4p0zr5wgjkdnwsbvqicnsdf83xkmmq9qwjf054g"))))
   (cons "sherpa-onnx-core-4b92eb0c06d1"
         (origin
           (method url-fetch)
           (uri "https://github.com/nlohmann/json/archive/refs/tags/v3.12.0.tar.gz")
           (file-name "v3.12.0.tar.gz")
           (sha256
            (base32 "11q1q4jz1cpp429jgmqqpr9v9m3wp5n41sbw8kvq61ni0q6fp4jb"))))
   (cons "sherpa-onnx-core-b9f34cfb4fd3"
         (origin
           (method url-fetch)
           (uri "https://github.com/k2-fsa/kaldi-decoder/archive/refs/tags/v0.3.0.tar.gz")
           (file-name "v0.3.0.tar.gz")
           (sha256
            (base32 "1c51fqgh4ig3dl2y7fbl4ab1baip9pppkbgf010k9cfk9zxlrwxr"))))
   (cons "sherpa-onnx-core-9176cc66fc7c"
         (origin
           (method url-fetch)
           (uri "https://github.com/csukuangfj/kaldi-native-fbank/archive/refs/tags/v1.22.3.tar.gz")
           (file-name "v1.22.3.tar.gz")
           (sha256
            (base32 "0qfgjf44d0siaxzjfx6zjxidnmqc69pb0mgkbkwfvqbwzikcqxli"))))
   (cons "sherpa-onnx-core-57fbc4b950ae"
         (origin
           (method url-fetch)
           (uri "https://github.com/csukuangfj/openfst/archive/refs/tags/v1.8.5-2026-04-11.tar.gz")
           (file-name "v1.8.5-2026-04-11.tar.gz")
           (sha256
            (base32 "1d55h1x05d79fiw2nn9sfak6ia9dclasz672w6hb30dfa2ww9ysp"))))
   (cons "sherpa-onnx-core-d9cca4e2bdc7"
         (origin
           (method url-fetch)
           (uri "https://github.com/csukuangfj/piper-phonemize/archive/f3ff95afc03640bc1399e113e83361192a2fafb4.zip")
           (file-name "f3ff95afc03640bc1399e113e83361192a2fafb4.zip")
           (sha256
            (base32 "0pba82lyps6163js7561m5vkzg9x51l4csmrzy6xvmn7ppia9k6r"))))
   (cons "sherpa-onnx-core-1748a822060a"
         (origin
           (method url-fetch)
           (uri "https://github.com/pkufool/simple-sentencepiece/archive/refs/tags/v0.7.tar.gz")
           (file-name "v0.7.tar.gz")
           (sha256
            (base32 "1bvmvjgi3dv74gcf7v5rfh7dqm7br3pq97v0yslvld8a0qiahj0p"))))
   (cons "sherpa-onnx-core-1385135ede81"
         (origin
           (method url-fetch)
           (uri "https://github.com/zaphoyd/websocketpp/archive/b9aeec6eaf3d5610503439b4fae3581d9aff08e8.zip")
           (file-name "b9aeec6eaf3d5610503439b4fae3581d9aff08e8.zip")
           (sha256
            (base32 "10zmcw2nklbc45c3j50cvx43srss7jg0kj4yxzxsg4c1vrg1718k"))))
   (cons "sherpa-onnx-core-497103e66416"
         (origin
           (method url-fetch)
           (uri "https://github.com/mborgerding/kissfft/archive/febd4caeed32e33ad8b2e0bb5ea77542c40f18ec.zip")
           (file-name "febd4caeed32e33ad8b2e0bb5ea77542c40f18ec.zip")
           (sha256
            (base32 "1z8kmg845g573icaywk5l62wzxhnwvdplx8bb0wvx3hnckk06wa9"))))
   (cons "sherpa-onnx-core-3f247b7e5a24"
         (origin
           (method url-fetch)
           (uri "https://github.com/k2-fsa/kaldifst/archive/refs/tags/v1.8.0.tar.gz")
           (file-name "v1.8.0.tar.gz")
           (sha256
            (base32 "1cs0w0ijgb9377046d0aiir6c3q601ibrqpm0890f294b9z7n91z"))))
   (cons "sherpa-onnx-core-b41d09905a3c"
         (origin
           (method url-fetch)
           (uri "https://codeload.github.com/microsoft/onnxruntime/tar.gz/refs/tags/v1.27.0")
           (file-name "microsoft-v1.27.0.tar.gz")
           (sha256
            (base32 "0sjyqkmvpdp79gvlc44xg71a8hirxzlcq7cxf0jklbrwba80j7dl"))))
   (cons "davey-source"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/65/b7/814a62dadd9f2b9009b73be172409517371493496ea5947043c98ff2d7a4/davey-0.1.4.tar.gz")
           (file-name "davey-0.1.4.tar.gz")
           (sha256
            (base32 "1gymqdd8hbyish1i08lp2aqknp06fjj75imx5rz40vgdqd6cdq3r"))))
   (cons "obstore-source"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/a3/8c/9ec984edd0f3b72226adfaa19b1c61b15823b35b52f311ca4af36d009d15/obstore-0.8.2.tar.gz")
           (file-name "obstore-0.8.2.tar.gz")
           (sha256
            (base32 "0zrpdwdnnlr8alxbhgwgkf6l45b0jg84y6wq96kjp7hnjx7bqrx4"))))
   (cons "sherpa-onnx-core-source"
         (origin
           (method url-fetch)
           (uri "https://codeload.github.com/k2-fsa/sherpa-onnx/tar.gz/142807252687d81b40d6315f23470a1512a00de3")
           (file-name "k2-fsa-142807252687d81b40d6315f23470a1512a00de3.tar.gz")
           (sha256
            (base32 "1cknmxs8fkz86y6rlm902gx4cfdjds11wrzfv89i6sdq86dprp7h"))))
   (cons "davey-hpke-rs-0.3.0-alpha.2-source"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/hpke-rs/hpke-rs-0.3.0-alpha.2.crate")
           (file-name "hpke-rs-0.3.0-alpha.2.crate")
           (sha256
            (base32 "1whgrhwmm6zgs2za4cc5yxw1lmlk7bbj16hfvp5illsqxa6paidj"))))
   (cons "davey-hpke-rs-crypto-0.3.0-source"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/hpke-rs-crypto/hpke-rs-crypto-0.3.0.crate")
           (file-name "hpke-rs-crypto-0.3.0.crate")
           (sha256
            (base32 "0xlq4wk11i9nlir7nbc4dx8vh68gj6k28sp5ya83z0069qqgs7ym"))))
   (cons "davey-hpke-rs-libcrux-0.3.0-alpha.2-source"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/hpke-rs-libcrux/hpke-rs-libcrux-0.3.0-alpha.2.crate")
           (file-name "hpke-rs-libcrux-0.3.0-alpha.2.crate")
           (sha256
            (base32 "1y3gl8d1122bq6j5c9affndghii49zcza2f29sh6h83y2j571yln"))))
   (cons "davey-hpke-rs-rust-crypto-0.3.0-source"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/hpke-rs-rust-crypto/hpke-rs-rust-crypto-0.3.0.crate")
           (file-name "hpke-rs-rust-crypto-0.3.0.crate")
           (sha256
            (base32 "0ifgdm2g9l0iydn9z0fqkjlcclvl24f53fq502ws0a2597gw0zgz"))))
   (cons "davey-94950e87ea55"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/core-models/core-models-0.0.3.crate")
           (file-name "core-models-0.0.3.crate")
           (sha256
            (base32 "1w5kl0x5q6a6glrq9zvv2lsp5jy8xdxkwgwry5l6s3amxa3hx5cl"))))
   (cons "davey-74d9ba66d173"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/hax-lib/hax-lib-0.3.5.crate")
           (file-name "hax-lib-0.3.5.crate")
           (sha256
            (base32 "11mfaa9s2qdmdaf1n65z3r4my564nlw24awv47h6i73ks5kbmnbl"))))
   (cons "davey-24ba777a231a"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/hax-lib-macros/hax-lib-macros-0.3.5.crate")
           (file-name "hax-lib-macros-0.3.5.crate")
           (sha256
            (base32 "1wcbd2djp2jvyih3vwnydabcgz3adgx170ynw6yd2n0s4dx7gfi4"))))
   (cons "davey-867e19177d74"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/hax-lib-macros-types/hax-lib-macros-types-0.3.5.crate")
           (file-name "hax-lib-macros-types-0.3.5.crate")
           (sha256
            (base32 "05fm1bl98wcbz1l87sc2wrz743ij0lp7rlkw845i89blglbijzl6"))))
   (cons "davey-4e0683aedd90"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/libcrux-chacha20poly1305/libcrux-chacha20poly1305-0.0.3-alpha.3.crate")
           (file-name "libcrux-chacha20poly1305-0.0.3-alpha.3.crate")
           (sha256
            (base32 "04ql74amqpc4ih8dsbvn8njlw8pwaqzshgw6j2nvwj4hvnp861jf"))))
   (cons "davey-1a39960483f2"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/libcrux-curve25519/libcrux-curve25519-0.0.3-alpha.3.crate")
           (file-name "libcrux-curve25519-0.0.3-alpha.3.crate")
           (sha256
            (base32 "12z2yp4zxi6c0hqpk645h0gngp38hsxi388sbfhzwkpjhc29cf8s"))))
   (cons "davey-9e5ecef729c9"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/libcrux-ecdh/libcrux-ecdh-0.0.3-alpha.3.crate")
           (file-name "libcrux-ecdh-0.0.3-alpha.3.crate")
           (sha256
            (base32 "1jj84g4ah7nj650hj39jx2rxhv33d8c8jfqka7vv56y957vwwply"))))
   (cons "davey-d8a141e79dce"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/libcrux-hacl-rs/libcrux-hacl-rs-0.0.3-alpha.3.crate")
           (file-name "libcrux-hacl-rs-0.0.3-alpha.3.crate")
           (sha256
            (base32 "0g0w4fpz473bdqy8b34ckfkdcbi32hqphcc8ns8imynfkpkl38fq"))))
   (cons "davey-2663b258d1a4"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/libcrux-hkdf/libcrux-hkdf-0.0.3-alpha.3.crate")
           (file-name "libcrux-hkdf-0.0.3-alpha.3.crate")
           (sha256
            (base32 "19d6sk0h6q9y3ndgws0yvb965y1hrx4vjswl7sh27854s5cb4qr6"))))
   (cons "davey-29c8d021153a"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/libcrux-hmac/libcrux-hmac-0.0.3-alpha.3.crate")
           (file-name "libcrux-hmac-0.0.3-alpha.3.crate")
           (sha256
            (base32 "0m11j615cwlwjjdwx04035vlwc774d6dvim7mg9amzrs2lhx1j19"))))
   (cons "davey-5d3b41dcbc21"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/libcrux-intrinsics/libcrux-intrinsics-0.0.3.crate")
           (file-name "libcrux-intrinsics-0.0.3.crate")
           (sha256
            (base32 "0ccd66001z1sn684x4j3wjzw8y9fbd0gfnmvzdzgp991pkf42fsx"))))
   (cons "davey-fc932402ccd8"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/libcrux-kem/libcrux-kem-0.0.3-alpha.3.crate")
           (file-name "libcrux-kem-0.0.3-alpha.3.crate")
           (sha256
            (base32 "166gqbmh2vh4566m2qdl0c5mlnzg596jmzr8w9jc00yqrh1294zw"))))
   (cons "davey-dc8e38ec9c49"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/libcrux-macros/libcrux-macros-0.0.3-alpha.3.crate")
           (file-name "libcrux-macros-0.0.3-alpha.3.crate")
           (sha256
            (base32 "1fmkv36ja5y2czjj53vjcyyaylkmag1pilkjgv5q7fj9kkn3i3nw"))))
   (cons "davey-6206bb81fc3e"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/libcrux-ml-kem/libcrux-ml-kem-0.0.3-alpha.3.crate")
           (file-name "libcrux-ml-kem-0.0.3-alpha.3.crate")
           (sha256
            (base32 "1gpklrwhycnrivgl3j5sfy79ljnl7407cixqsjabsl9yzj0vn1k2"))))
   (cons "davey-6fb56de31fa1"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/libcrux-p256/libcrux-p256-0.0.3-alpha.3.crate")
           (file-name "libcrux-p256-0.0.3-alpha.3.crate")
           (sha256
            (base32 "08dmgbds4d6r8pxqv099g4ff3ws46ry580c4hfmbsdm13zinvdbg"))))
   (cons "davey-db82d058aa76"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/libcrux-platform/libcrux-platform-0.0.2.crate")
           (file-name "libcrux-platform-0.0.2.crate")
           (sha256
            (base32 "0y07ih2kzmyww43a4f108q7dnzfnzffzd4i07dd33sknm9cd10nv"))))
   (cons "davey-7a8907194cd2"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/libcrux-poly1305/libcrux-poly1305-0.0.3-alpha.3.crate")
           (file-name "libcrux-poly1305-0.0.3-alpha.3.crate")
           (sha256
            (base32 "1wzfkyqbq2mid2wkzdn9993gaqk0dh1qk4aicgbmvlyj9hchg2bs"))))
   (cons "davey-332737e629fe"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/libcrux-secrets/libcrux-secrets-0.0.3.crate")
           (file-name "libcrux-secrets-0.0.3.crate")
           (sha256
            (base32 "0gz3rfw6mwg8za7i766gprfmv1mckrar03swgxaafszy57k3f9rk"))))
   (cons "davey-df0c0266cc2b"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/libcrux-sha2/libcrux-sha2-0.0.3-alpha.3.crate")
           (file-name "libcrux-sha2-0.0.3-alpha.3.crate")
           (sha256
            (base32 "0r7v33k76b3d64myk84szz7y5nm5iqkb22sln7rj029brik0436z"))))
   (cons "davey-84c076a07a2d"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/libcrux-sha3/libcrux-sha3-0.0.3-alpha.3.crate")
           (file-name "libcrux-sha3-0.0.3-alpha.3.crate")
           (sha256
            (base32 "0ggpnzgv7w6bnbhb9gjirrxhbh2jwwijh103cs7wrwidgah7dh44"))))
   (cons "davey-477d39395a82"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/libcrux-traits/libcrux-traits-0.0.3-alpha.3.crate")
           (file-name "libcrux-traits-0.0.3-alpha.3.crate")
           (sha256
            (base32 "1nkp3bm4wd3iwj41bhz439865fxw2grqihhkjc3kwac2b8wkjza7"))))
   (cons "davey-909805cbad4d"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/napi/napi-3.8.2.crate")
           (file-name "napi-3.8.2.crate")
           (sha256
            (base32 "0ys4nwpv50qy1hxk77ms8abjpsbjzs81440fp1lrwmjdmp5hb64h"))))
   (cons "davey-d376940fd5b7"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/napi-build/napi-build-2.3.1.crate")
           (file-name "napi-build-2.3.1.crate")
           (sha256
            (base32 "1cfkqhxjljmh7aghgv6i3k5nmn5zmcrkzvni7j4wc8xpsl7r8xnk"))))
   (cons "davey-04ba21bbdf40"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/napi-derive/napi-derive-3.5.1.crate")
           (file-name "napi-derive-3.5.1.crate")
           (sha256
            (base32 "11pg3wnqic0pj5a33kapvrn6lynickyasvpfnjb39cs0vyxj3fh4"))))
   (cons "davey-e9a63791e230"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/napi-derive-backend/napi-derive-backend-5.0.1.crate")
           (file-name "napi-derive-backend-5.0.1.crate")
           (sha256
            (base32 "0xz00ixnv46gcyjvxg4l8b39ylm0l1ndib5730r2qmrhwa8kg9p9"))))
   (cons "davey-8eb602b84d7c"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/napi-sys/napi-sys-3.2.1.crate")
           (file-name "napi-sys-3.2.1.crate")
           (sha256
            (base32 "0aqcp55khzjpgxkgm78pmqv8ym4n8qvz3fshbvjdl7kw9nw05dlf"))))
   (cons "davey-692e9c6b7d72"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/openmls/openmls-0.7.2.crate")
           (file-name "openmls-0.7.2.crate")
           (sha256
            (base32 "0rvbw1ah7p27s2xwzwawydyxc3vpcq08gyni8b656pkjgmmrqbk9"))))
   (cons "davey-e3e6454b2b1b"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/openmls_basic_credential/openmls_basic_credential-0.4.1.crate")
           (file-name "openmls_basic_credential-0.4.1.crate")
           (sha256
            (base32 "0k63237z9xg9fb9pw648ps9pfzrqxds7yb8l5zy4jrqv5d5lbrp3"))))
   (cons "davey-9e7b071ea557"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/openmls_memory_storage/openmls_memory_storage-0.4.1.crate")
           (file-name "openmls_memory_storage-0.4.1.crate")
           (sha256
            (base32 "1snlgl7wr1fnpa9fj3zgc95n9g6fh4zcbdvjmbprffjpllg0fywy"))))
   (cons "davey-3faef09e17a1"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/openmls_rust_crypto/openmls_rust_crypto-0.4.1.crate")
           (file-name "openmls_rust_crypto-0.4.1.crate")
           (sha256
            (base32 "13k7i6hr82h1dxmn62l1rg2b1p0r1haiwszcp5jq0p512ygg1biz"))))
   (cons "davey-e21d8877bacd"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/openmls_traits/openmls_traits-0.4.1.crate")
           (file-name "openmls_traits-0.4.1.crate")
           (sha256
            (base32 "04raj15s6rw0ms3rn2d0ixm8ifs5n5cvyafzc1q41g6dp9vqh7g2"))))
   (cons "davey-69cdb34c158c"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/r-efi/r-efi-5.3.0.crate")
           (file-name "r-efi-5.3.0.crate")
           (sha256
            (base32 "03sbfm3g7myvzyylff6qaxk4z6fy76yv860yy66jiswc2m6b7kb9"))))
   (cons "davey-ba73ea9cf16a"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/valuable/valuable-0.1.1.crate")
           (file-name "valuable-0.1.1.crate")
           (sha256
            (base32 "0r9srp55v7g27s5bg7a2m095fzckrcdca5maih6dy9bay6fflwxs"))))
   (cons "davey-0562428422c6"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/wasip2/wasip2-1.0.1+wasi-0.2.4.crate")
           (file-name "wasip2-1.0.1+wasi-0.2.4.crate")
           (sha256
            (base32 "1rsqmpspwy0zja82xx7kbkbg9fv34a4a2if3sbd76dy64a244qh5"))))
   (cons "davey-ac3b87c63620"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/winapi-i686-pc-windows-gnu/winapi-i686-pc-windows-gnu-0.4.0.crate")
           (file-name "winapi-i686-pc-windows-gnu-0.4.0.crate")
           (sha256
            (base32 "1dmpa6mvcvzz16zg6d5vrfy4bxgg541wxrcip7cnshi06v38ffxc"))))
   (cons "davey-712e227841d0"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/winapi-x86_64-pc-windows-gnu/winapi-x86_64-pc-windows-gnu-0.4.0.crate")
           (file-name "winapi-x86_64-pc-windows-gnu-0.4.0.crate")
           (sha256
            (base32 "0gqq64czqb64kskjryj8isp62m2sgvx25yyj3kpc2myh85w24bki"))))
   (cons "firecrawl-anydoc-10d60334b3b2"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/defmt-parser/defmt-parser-1.0.0.crate")
           (file-name "defmt-parser-1.0.0.crate")
           (sha256
            (base32 "0gpfky9sssil5qfaix5wxcwiqk7snszhl5gq3vcwkrxjncs07mhh"))))
   (cons "firecrawl-anydoc-923d117408f1"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/include_dir/include_dir-0.7.4.crate")
           (file-name "include_dir-0.7.4.crate")
           (sha256
            (base32 "1pfh3g45z88kwq93skng0n6g3r7zkhq9ldqs9y8rvr7i11s12gcj"))))
   (cons "firecrawl-anydoc-7cab85a7ed0b"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/include_dir_macros/include_dir_macros-0.7.4.crate")
           (file-name "include_dir_macros-0.7.4.crate")
           (sha256
            (base32 "0x8smnf6knd86g69p19z5lpfsaqp8w0nx14kdpkz1m8bxnkqbavw"))))
   (cons "firecrawl-anydoc-6f71d6bc097c"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/napi/napi-3.12.0.crate")
           (file-name "napi-3.12.0.crate")
           (sha256
            (base32 "0dky46118m3ma4q9ww8zgpsm17wcmf8lkwn3afw6wjkw16ydcwbg"))))
   (cons "firecrawl-anydoc-5282704fbe8d"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/napi-build/napi-build-2.4.0.crate")
           (file-name "napi-build-2.4.0.crate")
           (sha256
            (base32 "075iw0nmhfz6mkjwf1gjb2354sj16crg7qq8ig7v0jcdpr7p10jj"))))
   (cons "firecrawl-anydoc-6d9002b2940f"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/napi-derive/napi-derive-3.6.2.crate")
           (file-name "napi-derive-3.6.2.crate")
           (sha256
            (base32 "0hkw714xa6dhd0ckhvwfjib2y60mrl7nwm2l8x28808gjjr0543d"))))
   (cons "firecrawl-anydoc-d60b5d773ad4"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/napi-derive-backend/napi-derive-backend-6.1.1.crate")
           (file-name "napi-derive-backend-6.1.1.crate")
           (sha256
            (base32 "1g938jxbvirkwsz0877pnz5kjg981gg9zkf2ij66jv6l79vms2yn"))))
   (cons "firecrawl-anydoc-85fbf1fa9f1b"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/napi-sys/napi-sys-3.3.0.crate")
           (file-name "napi-sys-3.3.0.crate")
           (sha256
            (base32 "16pw1mzsyk2xf530nnwg7qj70dv4nd9bzfvldlwzxaqvkzxg3yw5"))))
   (cons "firecrawl-anydoc-f8dcc9c7d52a"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/r-efi/r-efi-6.0.0.crate")
           (file-name "r-efi-6.0.0.crate")
           (sha256
            (base32 "1gyrl2k5fyzj9k7kchg2n296z5881lg7070msabid09asp3wkp7q"))))
   (cons "obstore-1045398c1bfd"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/flatbuffers/flatbuffers-25.2.10.crate")
           (file-name "flatbuffers-25.2.10.crate")
           (sha256
            (base32 "1wdbcfa89pnk8iywh033yvv382z7yq8zrwfkby5id2gx3f63ji8h"))))
   (cons "obstore-cbbf9d6d0573"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/pyo3-arrow/pyo3-arrow-0.12.0.crate")
           (file-name "pyo3-arrow-0.12.0.crate")
           (sha256
            (base32 "0yh0pwfi2pdx64ck3n6q0caa3kxmssar0y2f32039wbk0mnrvgyb"))))
   (cons "obstore-6f42320e61fe"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/wit-bindgen-rt/wit-bindgen-rt-0.39.0.crate")
           (file-name "wit-bindgen-rt-0.39.0.crate")
           (sha256
            (base32 "1hd65pa5hp0nl664m94bg554h4zlhrzmkjsf6lsgsb7yc4734hkg"))))
   (cons "corresponding-source-gcc-8.5.0-28.el8_10.alma.1"
         (origin
           (method url-fetch)
           (uri "https://vault.almalinux.org/8.10/BaseOS/Source/Packages/gcc-8.5.0-28.el8_10.alma.1.src.rpm")
           (file-name "gcc-8.5.0-28.el8_10.alma.1.src.rpm")
           (sha256
            (base32 "1l6vabkdaiymh937pqc0bb144jg3ij7s2bl2lsjh2pbdrp9bnkf9"))))
   (cons "corresponding-source-openblas-libs-5d42cb49eae09aa502283ff53f91067d8e778f83"
         (origin
           (method url-fetch)
           (uri "https://codeload.github.com/MacPython/openblas-libs/tar.gz/5d42cb49eae09aa502283ff53f91067d8e778f83")
           (file-name "openblas-libs-5d42cb49eae09aa502283ff53f91067d8e778f83.tar.gz")
           (sha256
            (base32 "16r0wjcr5h6619c5rqap99faxvi4n1vchqr382cs1kn870vpf64i"))))
   (cons "corresponding-source-openblas-libs-v0.3.30.0.8"
         (origin
           (method url-fetch)
           (uri "https://codeload.github.com/MacPython/openblas-libs/tar.gz/refs/tags/v0.3.30.0.8")
           (file-name "openblas-libs-v0.3.30.0.8.tar.gz")
           (sha256
            (base32 "0h3cgvvsi9ikw7jdfnpbz8y9h17aq68cp764jx295brjjxxwsg71"))))
   (cons "corresponding-source-numpy-v2.4.3"
         (origin
           (method url-fetch)
           (uri "https://codeload.github.com/numpy/numpy/tar.gz/refs/tags/v2.4.3")
           (file-name "numpy-v2.4.3.tar.gz")
           (sha256
            (base32 "15q32gs3nj3bi6xx075rhaqzyfs46bv00mgh0zv07xv2amqb1m7c"))))
   (cons "corresponding-source-scipy-v1.17.1"
         (origin
           (method url-fetch)
           (uri "https://codeload.github.com/scipy/scipy/tar.gz/refs/tags/v1.17.1")
           (file-name "scipy-v1.17.1.tar.gz")
           (sha256
            (base32 "1pmmc05njr413favi510dlmav385ljvv4d412xy4mixg85dgmdh0"))))
   (cons "corresponding-source-edge_tts-7.2.7"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/16/d2/1ce38f6e4fe7275207f4033b0971db489a0b594340ae6bac2320127e71ee/edge_tts-7.2.7.tar.gz")
           (file-name "edge_tts-7.2.7.tar.gz")
           (sha256
            (base32 "09gkmwslgrdl6p1p8lhqc298bxr4hd5v58x2y27w8avlgajzn9q1"))))
   (cons "corresponding-source-python_telegram_bot-22.8"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/ba/77/153517bb1ac1bba670c6fb1dbf09e1fd0730494b1705934e715391413a0d/python_telegram_bot-22.8.tar.gz")
           (file-name "python_telegram_bot-22.8.tar.gz")
           (sha256
            (base32 "1vzixjfqggjh42fn3q3k3a2xyjmv6c5q0hp4fws61vi3rdzq9lzr"))))
   (cons "corresponding-source-certifi-2026.5.20"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/f3/ce/ee2ecad540810a79593028e88299baeae54d346cc7a0d94b6199988b89b1/certifi-2026.5.20.tar.gz")
           (file-name "certifi-2026.5.20.tar.gz")
           (sha256
            (base32 "0k9llmiwgn1anixb3wf0s5458smv92zwd8dbyswsgjk4mf1a9pk9"))))
   (cons "silero-vad-v6-mit-license"
         (origin
           (method url-fetch)
           (uri "https://raw.githubusercontent.com/snakers4/silero-vad/v6.0/LICENSE")
           (file-name "LICENSE")
           (sha256
            (base32 "02sj4plqbdygjxbayvbchmq2i1m1mi61gkippk3w13vfifiyjqrf"))))
   (cons "honcho-ai-sdk-corresponding-source"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/f2/1d/322649dbc8e9b21726a3a3e9b6a4975f2d122ca4b2450612f9ff2a9023b6/honcho_ai-2.2.0.tar.gz")
           (file-name "honcho_ai-2.2.0.tar.gz")
           (sha256
            (base32 "185p0rkwkp372xmldsy8l8zlml24dr5dsw4nspyz4ldcmwjniq8n"))))
   (cons "jetbrains-mono-font-ofl-1.1"
         (origin
           (method url-fetch)
           (uri "https://raw.githubusercontent.com/JetBrains/JetBrainsMono/v2.304/OFL.txt")
           (file-name "OFL.txt")
           (sha256
            (base32 "1bf4rbc4w3gzy96c76vjm5a903w771rdkb4i0wnl53n8wcvc3w1h"))))
   (cons "retained-rust-cryptography-source"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/de/41/6cbdcf9142d00fe82836fbb51e503e58088575cf7a0fe1dbff6695bf0840/cryptography-50.0.0.tar.gz")
           (file-name "cryptography-50.0.0.tar.gz")
           (sha256
            (base32 "1jd6j7bda9cgfw8nssr60js7h2sj3a4zj7bdmph2bv90bb5jmb7f"))))
   (cons "retained-rust-hf-xet-source"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/63/39/67be8d71f900d9a55761b6022821d6679fb56c64f1b6063d5af2c2606727/hf_xet-1.5.2.tar.gz")
           (file-name "hf_xet-1.5.2.tar.gz")
           (sha256
            (base32 "0iyg048nwq8xv7drvvlga5kzppx0ab3ijbc3my2cjcxf3g9ln13k"))))
   (cons "retained-rust-jiter-source"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/0d/5e/4ec91646aee381d01cdb9974e30882c9cd3b8c5d1079d6b5ff4af522439a/jiter-0.13.0.tar.gz")
           (file-name "jiter-0.13.0.tar.gz")
           (sha256
            (base32 "1x0lmqnk9vz7349gsrckpr3akq2cw48aaaarpk0zybby5jf9z0zj"))))
   (cons "retained-rust-nemo-relay-source"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/03/73/ac90ccb08faca19b2c8470bdd4d5b9bae89fc5edfde8dae72ee7b1a2d8df/nemo_relay-0.8.3.tar.gz")
           (file-name "nemo_relay-0.8.3.tar.gz")
           (sha256
            (base32 "1zvrs0yb486x61liicn2sx6a87phwqqh2im1d103a287kxlc0w1n"))))
   (cons "retained-rust-pydantic-core-source"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/9d/56/921726b776ace8d8f5db44c4ef961006580d91dc52b803c489fafd1aa249/pydantic_core-2.46.4.tar.gz")
           (file-name "pydantic_core-2.46.4.tar.gz")
           (sha256
            (base32 "1hg1nrj1z9sfnsr6vmlj4b4br0ph54pds8q5y98hh9vz7lwpby32"))))
   (cons "retained-rust-rpds-py-source"
         (origin
           (method url-fetch)
           (uri "https://files.pythonhosted.org/packages/20/af/3f2f423103f1113b36230496629986e0ef7e199d2aa8392452b484b38ced/rpds_py-0.30.0.tar.gz")
           (file-name "rpds_py-0.30.0.tar.gz")
           (sha256
            (base32 "110y8k62b9xb3slny7gf89943xpbji3s7vl7yz0g0jh1j37zg3yx"))))
   (cons "retained-rust-asn1-0.24.1"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/asn1/asn1-0.24.1.crate")
           (file-name "asn1-0.24.1.crate")
           (sha256
            (base32 "1c8z0dp8iq7avj8hbja7ngvix3n310l8hkyflzwv630cc8854yf9"))))
   (cons "retained-rust-asn1_derive-0.24.1"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/asn1_derive/asn1_derive-0.24.1.crate")
           (file-name "asn1_derive-0.24.1.crate")
           (sha256
            (base32 "06m11z9il657glrs8lvv1yikzw0vdmp493yrrfybhay33izk17lh"))))
   (cons "retained-rust-base64-0.23.0"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/base64/base64-0.23.0.crate")
           (file-name "base64-0.23.0.crate")
           (sha256
            (base32 "1a9x0g0gsi1iqh5c7mxdvnr340w8rn5bi4xjwp2q7p9w5kgmammj"))))
   (cons "retained-rust-foreign-types-0.3.2"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/foreign-types/foreign-types-0.3.2.crate")
           (file-name "foreign-types-0.3.2.crate")
           (sha256
            (base32 "1cgk0vyd7r45cj769jym4a6s7vwshvd0z4bqrb92q1fwibmkkwzn"))))
   (cons "retained-rust-foreign-types-shared-0.1.1"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/foreign-types-shared/foreign-types-shared-0.1.1.crate")
           (file-name "foreign-types-shared-0.1.1.crate")
           (sha256
            (base32 "0jxgzd04ra4imjv8jgkmdq59kj8fsz6w4zxsbmlai34h26225c00"))))
   (cons "retained-rust-openssl-0.10.81"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/openssl/openssl-0.10.81.crate")
           (file-name "openssl-0.10.81.crate")
           (sha256
            (base32 "0ibsv2ppsjrp62jqyzprhay9vczk1bw9xvdr3h4h7fxsy0kkm0kp"))))
   (cons "retained-rust-openssl-macros-0.1.1"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/openssl-macros/openssl-macros-0.1.1.crate")
           (file-name "openssl-macros-0.1.1.crate")
           (sha256
            (base32 "173xxvfc63rr5ybwqwylsir0vq6xsj4kxiv4hmg4c3vscdmncj59"))))
   (cons "retained-rust-openssl-sys-0.9.117"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/openssl-sys/openssl-sys-0.9.117.crate")
           (file-name "openssl-sys-0.9.117.crate")
           (sha256
            (base32 "159nf6jsqnmsynkh6gjzx088q1ifll7v88sss8qdk363n9mpwzml"))))
   (cons "retained-rust-pem-4.0.0"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/pem/pem-4.0.0.crate")
           (file-name "pem-4.0.0.crate")
           (sha256
            (base32 "087i4xarp8mhlxir1xc23g1p6md0zn5dv3wyx5fmal8j7n5ajm6k"))))
   (cons "retained-rust-pkg-config-0.3.33"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/pkg-config/pkg-config-0.3.33.crate")
           (file-name "pkg-config-0.3.33.crate")
           (sha256
            (base32 "17jnqmcbxsnwhg9gjf0nh6dj5k0x3hgwi3mb9krjnmfa9v435w8r"))))
   (cons "retained-rust-pyo3-0.29.0"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/pyo3/pyo3-0.29.0.crate")
           (file-name "pyo3-0.29.0.crate")
           (sha256
            (base32 "0707cvmc6h6hbhsj8wr8d5gl5nqy5jb8fxd4l0kgqjqxn984c9yd"))))
   (cons "retained-rust-pyo3-build-config-0.29.0"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/pyo3-build-config/pyo3-build-config-0.29.0.crate")
           (file-name "pyo3-build-config-0.29.0.crate")
           (sha256
            (base32 "0y4h23a97v60ajicbcam98axbb9pjb8ql12w54pk84yhy39agqn5"))))
   (cons "retained-rust-pyo3-ffi-0.29.0"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/pyo3-ffi/pyo3-ffi-0.29.0.crate")
           (file-name "pyo3-ffi-0.29.0.crate")
           (sha256
            (base32 "0nw40nfdlnz66vd1fjh5hmvmzsi9rzwyypgads38vg0vv9kw91fa"))))
   (cons "retained-rust-pyo3-macros-0.29.0"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/pyo3-macros/pyo3-macros-0.29.0.crate")
           (file-name "pyo3-macros-0.29.0.crate")
           (sha256
            (base32 "0w8pj0nk3ay40j9imz80h4c3lydx71x362fxjhqslp86zmi3gics"))))
   (cons "retained-rust-pyo3-macros-backend-0.29.0"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/pyo3-macros-backend/pyo3-macros-backend-0.29.0.crate")
           (file-name "pyo3-macros-backend-0.29.0.crate")
           (sha256
            (base32 "0qmkacg1d4i23nvmdficacr7f59mm3y9rwsvvir32y4rfdas38sc"))))
   (cons "retained-rust-self_cell-1.3.0"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/self_cell/self_cell-1.3.0.crate")
           (file-name "self_cell-1.3.0.crate")
           (sha256
            (base32 "04x883z7awzkmn5lqb67n51xynrj2pa9339jgq4j1qa94yh2rd1a"))))
   (cons "retained-rust-vcpkg-0.2.15"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/vcpkg/vcpkg-0.2.15.crate")
           (file-name "vcpkg-0.2.15.crate")
           (sha256
            (base32 "09i4nf5y8lig6xgj3f7fyrvzd3nlaw4znrihw8psidvv5yk4xkdc"))))
   (cons "retained-rust-addr2line-0.25.1"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/addr2line/addr2line-0.25.1.crate")
           (file-name "addr2line-0.25.1.crate")
           (sha256
            (base32 "0jwb96gv17vdr29hbzi0ha5q6jkpgjyn7rjlg5nis65k41rk0p8v"))))
   (cons "retained-rust-aligned-vec-0.6.4"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/aligned-vec/aligned-vec-0.6.4.crate")
           (file-name "aligned-vec-0.6.4.crate")
           (sha256
            (base32 "16vnf78hvfix5cwzd5xs5a2g6afmgb4h7n6yfsc36bv0r22072fw"))))
   (cons "retained-rust-anyhow-1.0.103"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/anyhow/anyhow-1.0.103.crate")
           (file-name "anyhow-1.0.103.crate")
           (sha256
            (base32 "1wsav2g6vxcvf2c0fv3jhxfr55l0p2g8nygy7rmmvcsfwgi8ahra"))))
   (cons "retained-rust-approx-0.5.1"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/approx/approx-0.5.1.crate")
           (file-name "approx-0.5.1.crate")
           (sha256
            (base32 "1ilpv3dgd58rasslss0labarq7jawxmivk17wsh8wmkdm3q15cfa"))))
   (cons "retained-rust-arrayref-0.3.9"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/arrayref/arrayref-0.3.9.crate")
           (file-name "arrayref-0.3.9.crate")
           (sha256
            (base32 "1jzyp0nvp10dmahaq9a2rnxqdd5wxgbvp8xaibps3zai8c9fi8kn"))))
   (cons "retained-rust-arrayvec-0.7.6"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/arrayvec/arrayvec-0.7.6.crate")
           (file-name "arrayvec-0.7.6.crate")
           (sha256
            (base32 "0l1fz4ccgv6pm609rif37sl5nv5k6lbzi7kkppgzqzh1vwix20kw"))))
   (cons "retained-rust-async-trait-0.1.89"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/async-trait/async-trait-0.1.89.crate")
           (file-name "async-trait-0.1.89.crate")
           (sha256
            (base32 "1fsxxmz3rzx1prn1h3rs7kyjhkap60i7xvi0ldapkvbb14nssdch"))))
   (cons "retained-rust-aws-lc-rs-1.16.2"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/aws-lc-rs/aws-lc-rs-1.16.2.crate")
           (file-name "aws-lc-rs-1.16.2.crate")
           (sha256
            (base32 "1z6i8qs0xjnzvslxnkhvywzzwfkafb1s4nrpg3f2k1nii4i92m50"))))
   (cons "retained-rust-aws-lc-sys-0.39.0"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/aws-lc-sys/aws-lc-sys-0.39.0.crate")
           (file-name "aws-lc-sys-0.39.0.crate")
           (sha256
            (base32 "02jga4605vwqcxzd4k3ikd01x27k4gqwd8hh2rs7qm2w9hmfb9qz"))))
   (cons "retained-rust-axum-0.8.8"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/axum/axum-0.8.8.crate")
           (file-name "axum-0.8.8.crate")
           (sha256
            (base32 "1f4p0m04mgwpn8b40i9r5mgqxk6w11sv4yri6xfqk305nhyayllb"))))
   (cons "retained-rust-axum-core-0.5.6"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/axum-core/axum-core-0.5.6.crate")
           (file-name "axum-core-0.5.6.crate")
           (sha256
            (base32 "1lcjhxysnbc64rh21ag9m9fpiryd1iwcdh9mwxz1yadiswqqziq8"))))
   (cons "retained-rust-backtrace-0.3.76"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/backtrace/backtrace-0.3.76.crate")
           (file-name "backtrace-0.3.76.crate")
           (sha256
            (base32 "1mibx75x4jf6wz7qjifynld3hpw3vq6sy3d3c9y5s88sg59ihlxv"))))
   (cons "retained-rust-base64-0.21.7"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/base64/base64-0.21.7.crate")
           (file-name "base64-0.21.7.crate")
           (sha256
            (base32 "0rw52yvsk75kar9wgqfwgb414kvil1gn7mqkrhn9zf1537mpsacx"))))
   (cons "retained-rust-bitflags-2.11.0"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/bitflags/bitflags-2.11.0.crate")
           (file-name "bitflags-2.11.0.crate")
           (sha256
            (base32 "1bwjibwry5nfwsfm9kjg2dqx5n5nja9xymwbfl6svnn8jsz6ff44"))))
   (cons "retained-rust-blake3-1.8.3"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/blake3/blake3-1.8.3.crate")
           (file-name "blake3-1.8.3.crate")
           (sha256
            (base32 "0b9ay320z90xs5hyk48l1v3208yyvdy3gs3nnlb7xyxkaxyyys14"))))
   (cons "retained-rust-bstr-1.12.1"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/bstr/bstr-1.12.1.crate")
           (file-name "bstr-1.12.1.crate")
           (sha256
            (base32 "1arc1v7h5l86vd6z76z3xykjzldqd5icldn7j9d3p7z6x0d4w133"))))
   (cons "retained-rust-bumpalo-3.20.2"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/bumpalo/bumpalo-3.20.2.crate")
           (file-name "bumpalo-3.20.2.crate")
           (sha256
            (base32 "1jrgxlff76k9glam0akhwpil2fr1w32gbjdf5hpipc7ld2c7h82x"))))
   (cons "retained-rust-bytemuck-1.25.0"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/bytemuck/bytemuck-1.25.0.crate")
           (file-name "bytemuck-1.25.0.crate")
           (sha256
            (base32 "1v1z32igg9zq49phb3fra0ax5r2inf3aw473vldnm886sx5vdvy8"))))
   (cons "retained-rust-byteorder-1.5.0"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/byteorder/byteorder-1.5.0.crate")
           (file-name "byteorder-1.5.0.crate")
           (sha256
            (base32 "0jzncxyf404mwqdbspihyzpkndfgda450l0893pz5xj685cg5l0z"))))
   (cons "retained-rust-bytes-1.11.1"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/bytes/bytes-1.11.1.crate")
           (file-name "bytes-1.11.1.crate")
           (sha256
            (base32 "0czwlhbq8z29wq0ia87yass2mzy1y0jcasjb8ghriiybnwrqfx0y"))))
   (cons "retained-rust-cc-1.2.57"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/cc/cc-1.2.57.crate")
           (file-name "cc-1.2.57.crate")
           (sha256
            (base32 "08q464b62d03zm7rgiixavkrh5lzfq18lwf884vgycj9735d23bs"))))
   (cons "retained-rust-cesu8-1.1.0"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/cesu8/cesu8-1.1.0.crate")
           (file-name "cesu8-1.1.0.crate")
           (sha256
            (base32 "0g6q58wa7khxrxcxgnqyi9s1z2cjywwwd3hzr5c55wskhx6s0hvd"))))
   (cons "retained-rust-cfg-if-0.1.10"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/cfg-if/cfg-if-0.1.10.crate")
           (file-name "cfg-if-0.1.10.crate")
           (sha256
            (base32 "08h80ihs74jcyp24cd75wwabygbbdgl05k6p5dmq8akbr78vv1a7"))))
   (cons "retained-rust-chacha20-0.10.0"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/chacha20/chacha20-0.10.0.crate")
           (file-name "chacha20-0.10.0.crate")
           (sha256
            (base32 "00bn2rn8l68qvlq93mhq7b4ns4zy9qbjsyjbb9kljgl4hqr9i3bg"))))
   (cons "retained-rust-chrono-0.4.44"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/chrono/chrono-0.4.44.crate")
           (file-name "chrono-0.4.44.crate")
           (sha256
            (base32 "1c64mk9a235271j5g3v4zrzqqmd43vp9vki7vqfllpqf5rd0fwy6"))))
   (cons "retained-rust-cmake-0.1.57"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/cmake/cmake-0.1.57.crate")
           (file-name "cmake-0.1.57.crate")
           (sha256
            (base32 "0zgg10qgykig4nxyf7whrqfg7fkk0xfxhiavikmrndvbrm23qi3m"))))
   (cons "retained-rust-colored-3.1.1"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/colored/colored-3.1.1.crate")
           (file-name "colored-3.1.1.crate")
           (sha256
            (base32 "0d5cpbgvyvmmky199s885s6385ykd75q6qg3d2kcxjxq563ldygs"))))
   (cons "retained-rust-combine-4.6.7"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/combine/combine-4.6.7.crate")
           (file-name "combine-4.6.7.crate")
           (sha256
            (base32 "1z8rh8wp59gf8k23ar010phgs0wgf5i8cx4fg01gwcnzfn5k0nms"))))
   (cons "retained-rust-console-api-0.9.0"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/console-api/console-api-0.9.0.crate")
           (file-name "console-api-0.9.0.crate")
           (sha256
            (base32 "1lr09fzbaq8gf8wmlbd5k3v3y5h1d7zhs78cj462yzk6nr4rfng8"))))
   (cons "retained-rust-console-subscriber-0.5.0"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/console-subscriber/console-subscriber-0.5.0.crate")
           (file-name "console-subscriber-0.5.0.crate")
           (sha256
            (base32 "14kmygqvdrks4jmr8ln6wwlgfi199h8q1hxnl5bh95nxv2viajgv"))))
   (cons "retained-rust-const-str-1.1.0"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/const-str/const-str-1.1.0.crate")
           (file-name "const-str-1.1.0.crate")
           (sha256
            (base32 "0br169v5x31pljc2wg5yrh0r83r7dv4cgpfd61161ncfjk4jrw8q"))))
   (cons "retained-rust-const_panic-0.2.15"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/const_panic/const_panic-0.2.15.crate")
           (file-name "const_panic-0.2.15.crate")
           (sha256
            (base32 "0lp6i96dnbpal6k6zdmlpmwa2zgbrpwnjff46jpf7514qjmcsqp2"))))
   (cons "retained-rust-constant_time_eq-0.4.2"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/constant_time_eq/constant_time_eq-0.4.2.crate")
           (file-name "constant_time_eq-0.4.2.crate")
           (sha256
            (base32 "16zamq60dq80k3rqlzh9j9cpjhishmh924lnwbplgrnmkkvfylix"))))
   (cons "retained-rust-core-foundation-0.9.4"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/core-foundation/core-foundation-0.9.4.crate")
           (file-name "core-foundation-0.9.4.crate")
           (sha256
            (base32 "13zvbbj07yk3b61b8fhwfzhy35535a583irf23vlcg59j7h9bqci"))))
   (cons "retained-rust-countio-0.3.0"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/countio/countio-0.3.0.crate")
           (file-name "countio-0.3.0.crate")
           (sha256
            (base32 "1jyyxxpvjwy7cia3h0s90678j3wm9xj1as9gv00lqx0xbpp2lw5r"))))
   (cons "retained-rust-cpp_demangle-0.5.1"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/cpp_demangle/cpp_demangle-0.5.1.crate")
           (file-name "cpp_demangle-0.5.1.crate")
           (sha256
            (base32 "1vwx8a999mpqywx0736v54909y52x77w1myjsr6cnmpa69630rq6"))))
   (cons "retained-rust-crossbeam-channel-0.5.15"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/crossbeam-channel/crossbeam-channel-0.5.15.crate")
           (file-name "crossbeam-channel-0.5.15.crate")
           (sha256
            (base32 "1cicd9ins0fkpfgvz9vhz3m9rpkh6n8d3437c3wnfsdkd3wgif42"))))
   (cons "retained-rust-ctor-1.0.3"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/ctor/ctor-1.0.3.crate")
           (file-name "ctor-1.0.3.crate")
           (sha256
            (base32 "1051dzxswyb03dqd78hgc2s19jm7rl6zvj65nzzjyan1nyrd492w"))))
   (cons "retained-rust-debugid-0.8.0"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/debugid/debugid-0.8.0.crate")
           (file-name "debugid-0.8.0.crate")
           (sha256
            (base32 "13f15dfvn07fa7087pmacixqqv0lmj4hv93biw4ldr48ypk55xdy"))))
   (cons "retained-rust-dirs-6.0.0"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/dirs/dirs-6.0.0.crate")
           (file-name "dirs-6.0.0.crate")
           (sha256
            (base32 "0knfikii29761g22pwfrb8d0nqpbgw77sni9h2224haisyaams63"))))
   (cons "retained-rust-dirs-sys-0.5.0"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/dirs-sys/dirs-sys-0.5.0.crate")
           (file-name "dirs-sys-0.5.0.crate")
           (sha256
            (base32 "1aqzpgq6ampza6v012gm2dppx9k35cdycbj54808ksbys9k366p0"))))
   (cons "retained-rust-dunce-1.0.5"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/dunce/dunce-1.0.5.crate")
           (file-name "dunce-1.0.5.crate")
           (sha256
            (base32 "04y8wwv3vvcqaqmqzssi6k0ii9gs6fpz96j5w9nky2ccsl23axwj"))))
   (cons "retained-rust-equator-0.4.2"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/equator/equator-0.4.2.crate")
           (file-name "equator-0.4.2.crate")
           (sha256
            (base32 "1z760z5r0haxjyakbqxvswrz9mq7c29arrivgq8y1zldhc9v44a7"))))
   (cons "retained-rust-equator-macro-0.4.2"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/equator-macro/equator-macro-0.4.2.crate")
           (file-name "equator-macro-0.4.2.crate")
           (sha256
            (base32 "1cqzx3cqn9rxln3a607xr54wippzff56zs5chqdf3z2bnks3rwj4"))))
   (cons "retained-rust-findshlibs-0.10.2"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/findshlibs/findshlibs-0.10.2.crate")
           (file-name "findshlibs-0.10.2.crate")
           (sha256
            (base32 "0r3zy2r12rxzwqgz53830bk38r6b7rl8kq2br9n81q7ps2ffbfa0"))))
   (cons "retained-rust-foldhash-0.1.5"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/foldhash/foldhash-0.1.5.crate")
           (file-name "foldhash-0.1.5.crate")
           (sha256
            (base32 "1wisr1xlc2bj7hk4rgkcjkz3j2x4dhd1h9lwk7mj8p71qpdgbi6r"))))
   (cons "retained-rust-form_urlencoded-1.2.2"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/form_urlencoded/form_urlencoded-1.2.2.crate")
           (file-name "form_urlencoded-1.2.2.crate")
           (sha256
            (base32 "1kqzb2qn608rxl3dws04zahcklpplkd5r1vpabwga5l50d2v4k6b"))))
   (cons "retained-rust-fs_extra-1.3.0"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/fs_extra/fs_extra-1.3.0.crate")
           (file-name "fs_extra-1.3.0.crate")
           (sha256
            (base32 "075i25z70j2mz9r7i9p9r521y8xdj81q7skslyb7zhqnnw33fw22"))))
   (cons "retained-rust-futures-0.3.32"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/futures/futures-0.3.32.crate")
           (file-name "futures-0.3.32.crate")
           (sha256
            (base32 "0b9q86r5ar18v5xjiyqn7sb8sa32xv98qqnfz779gl7ns7lpw54b"))))
   (cons "retained-rust-futures-channel-0.3.32"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/futures-channel/futures-channel-0.3.32.crate")
           (file-name "futures-channel-0.3.32.crate")
           (sha256
            (base32 "07fcyzrmbmh7fh4ainilf1s7gnwvnk07phdq77jkb9fpa2ffifq7"))))
   (cons "retained-rust-futures-core-0.3.32"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/futures-core/futures-core-0.3.32.crate")
           (file-name "futures-core-0.3.32.crate")
           (sha256
            (base32 "07bbvwjbm5g2i330nyr1kcvjapkmdqzl4r6mqv75ivvjaa0m0d3y"))))
   (cons "retained-rust-futures-executor-0.3.32"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/futures-executor/futures-executor-0.3.32.crate")
           (file-name "futures-executor-0.3.32.crate")
           (sha256
            (base32 "17aplz3ns74qn7a04qg7qlgsdx5iwwwkd4jvdfra6hl3h4w9rwms"))))
   (cons "retained-rust-futures-io-0.3.32"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/futures-io/futures-io-0.3.32.crate")
           (file-name "futures-io-0.3.32.crate")
           (sha256
            (base32 "063pf5m6vfmyxj74447x8kx9q8zj6m9daamj4hvf49yrg9fs7jyf"))))
   (cons "retained-rust-futures-macro-0.3.32"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/futures-macro/futures-macro-0.3.32.crate")
           (file-name "futures-macro-0.3.32.crate")
           (sha256
            (base32 "0ys4b1lk7s0bsj29pv42bxsaavalch35rprp64s964p40c1bfdg8"))))
   (cons "retained-rust-futures-sink-0.3.32"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/futures-sink/futures-sink-0.3.32.crate")
           (file-name "futures-sink-0.3.32.crate")
           (sha256
            (base32 "14q8ml7hn5a6gyy9ri236j28kh0svqmrk4gcg0wh26rkazhm95y3"))))
   (cons "retained-rust-futures-task-0.3.32"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/futures-task/futures-task-0.3.32.crate")
           (file-name "futures-task-0.3.32.crate")
           (sha256
            (base32 "14s3vqf8llz3kjza33vn4ixg6kwxp61xrysn716h0cwwsnri2xq3"))))
   (cons "retained-rust-futures-util-0.3.32"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/futures-util/futures-util-0.3.32.crate")
           (file-name "futures-util-0.3.32.crate")
           (sha256
            (base32 "1mn60lw5kh32hz9isinjlpw34zx708fk5q1x0m40n6g6jq9a971q"))))
   (cons "retained-rust-gearhash-0.1.3"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/gearhash/gearhash-0.1.3.crate")
           (file-name "gearhash-0.1.3.crate")
           (sha256
            (base32 "04yj8ni60v8756qfc2qsky671kkmqxvi6ni9arg4h5ndfv7q5ky8"))))
   (cons "retained-rust-getrandom-0.4.2"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/getrandom/getrandom-0.4.2.crate")
           (file-name "getrandom-0.4.2.crate")
           (sha256
            (base32 "0mb5833hf9pvn9dhvxjgfg5dx0m77g8wavvjdpvpnkp9fil1xr8d"))))
   (cons "retained-rust-gimli-0.32.3"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/gimli/gimli-0.32.3.crate")
           (file-name "gimli-0.32.3.crate")
           (sha256
            (base32 "1iqk5xznimn5bfa8jy4h7pa1dv3c624hzgd2dkz8mpgkiswvjag6"))))
   (cons "retained-rust-git-version-0.3.9"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/git-version/git-version-0.3.9.crate")
           (file-name "git-version-0.3.9.crate")
           (sha256
            (base32 "06ddi3px6l2ip0srn8512bsh8wrx4rzi65piya0vrz5h7nm6im8s"))))
   (cons "retained-rust-git-version-macro-0.3.9"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/git-version-macro/git-version-macro-0.3.9.crate")
           (file-name "git-version-macro-0.3.9.crate")
           (sha256
            (base32 "1h1s08fgh9bkwnc2hmjxcldv69hlxpq7a09cqdxsd5hb235hq0ak"))))
   (cons "retained-rust-h2-0.4.13"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/h2/h2-0.4.13.crate")
           (file-name "h2-0.4.13.crate")
           (sha256
            (base32 "0m6w5gg0n0m1m5915bxrv8n4rlazhx5icknkslz719jhh4xdli1g"))))
   (cons "retained-rust-hashbrown-0.15.5"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/hashbrown/hashbrown-0.15.5.crate")
           (file-name "hashbrown-0.15.5.crate")
           (sha256
            (base32 "189qaczmjxnikm9db748xyhiw04kpmhm9xj9k9hg0sgx7pjwyacj"))))
   (cons "retained-rust-hashbrown-0.16.1"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/hashbrown/hashbrown-0.16.1.crate")
           (file-name "hashbrown-0.16.1.crate")
           (sha256
            (base32 "004i3njw38ji3bzdp9z178ba9x3k0c1pgy8x69pj7yfppv4iq7c4"))))
   (cons "retained-rust-hdrhistogram-7.5.4"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/hdrhistogram/hdrhistogram-7.5.4.crate")
           (file-name "hdrhistogram-7.5.4.crate")
           (sha256
            (base32 "07ai0r66l1n53f2757gv07za1l5g1bprb7zz4v75kpbky6c92p3n"))))
   (cons "retained-rust-heapify-0.2.0"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/heapify/heapify-0.2.0.crate")
           (file-name "heapify-0.2.0.crate")
           (sha256
            (base32 "0bn5bky8dnbp1zhanlba29h40i7y8wmv4xalnadcl0gjnxjv4j80"))))
   (cons "retained-rust-hermit-abi-0.5.2"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/hermit-abi/hermit-abi-0.5.2.crate")
           (file-name "hermit-abi-0.5.2.crate")
           (sha256
            (base32 "1744vaqkczpwncfy960j2hxrbjl1q01csm84jpd9dajbdr2yy3zw"))))
   (cons "retained-rust-http-1.4.0"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/http/http-1.4.0.crate")
           (file-name "http-1.4.0.crate")
           (sha256
            (base32 "06iind4cwsj1d6q8c2xgq8i2wka4ps74kmws24gsi1bzdlw2mfp3"))))
   (cons "retained-rust-httpdate-1.0.3"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/httpdate/httpdate-1.0.3.crate")
           (file-name "httpdate-1.0.3.crate")
           (sha256
            (base32 "1aa9rd2sac0zhjqh24c9xvir96g188zldkx0hr6dnnlx5904cfyz"))))
   (cons "retained-rust-humantime-2.3.0"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/humantime/humantime-2.3.0.crate")
           (file-name "humantime-2.3.0.crate")
           (sha256
            (base32 "092lpipp32ayz4kyyn4k3vz59j9blng36wprm5by0g2ykqr14nqk"))))
   (cons "retained-rust-hyper-1.8.1"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/hyper/hyper-1.8.1.crate")
           (file-name "hyper-1.8.1.crate")
           (sha256
            (base32 "04cxr8j5y86bhxxlyqb8xkxjskpajk7cxwfzzk4v3my3a3rd9cia"))))
   (cons "retained-rust-hyper-timeout-0.5.2"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/hyper-timeout/hyper-timeout-0.5.2.crate")
           (file-name "hyper-timeout-0.5.2.crate")
           (sha256
            (base32 "1c431l5ckr698248yd6bnsmizjy2m1da02cbpmsnmkpvpxkdb41b"))))
   (cons "retained-rust-hyper-tls-0.6.0"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/hyper-tls/hyper-tls-0.6.0.crate")
           (file-name "hyper-tls-0.6.0.crate")
           (sha256
            (base32 "1q36x2yps6hhvxq5r7mc8ph9zz6xlb573gx0x3yskb0fi736y83h"))))
   (cons "retained-rust-hyper-util-0.1.20"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/hyper-util/hyper-util-0.1.20.crate")
           (file-name "hyper-util-0.1.20.crate")
           (sha256
            (base32 "186zdc58hmm663csmjvrzgkr6jdh93sfmi3q2pxi57gcaqjpqm4n"))))
   (cons "retained-rust-icu_collections-2.1.1"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/icu_collections/icu_collections-2.1.1.crate")
           (file-name "icu_collections-2.1.1.crate")
           (sha256
            (base32 "0hsblchsdl64q21qwrs4hvc2672jrf466zivbj1bwyv606bn8ssc"))))
   (cons "retained-rust-icu_locale_core-2.1.1"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/icu_locale_core/icu_locale_core-2.1.1.crate")
           (file-name "icu_locale_core-2.1.1.crate")
           (sha256
            (base32 "1djvdc2f5ylmp1ymzv4gcnmq1s4hqfim9nxlcm173lsd01hpifpd"))))
   (cons "retained-rust-icu_normalizer-2.1.1"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/icu_normalizer/icu_normalizer-2.1.1.crate")
           (file-name "icu_normalizer-2.1.1.crate")
           (sha256
            (base32 "16dmn5596la2qm0r3vih0bzjfi0vx9a20yqjha6r1y3vnql8hv2z"))))
   (cons "retained-rust-icu_normalizer_data-2.1.1"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/icu_normalizer_data/icu_normalizer_data-2.1.1.crate")
           (file-name "icu_normalizer_data-2.1.1.crate")
           (sha256
            (base32 "02jnzizg6q75m41l6c13xc7nkc5q8yr1b728dcgfhpzw076wrvbs"))))
   (cons "retained-rust-icu_properties-2.1.2"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/icu_properties/icu_properties-2.1.2.crate")
           (file-name "icu_properties-2.1.2.crate")
           (sha256
            (base32 "1v3lbmhhi7i6jgw51ikjb1p50qh5rb67grlkdnkc63l7zq1gq2q2"))))
   (cons "retained-rust-icu_properties_data-2.1.2"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/icu_properties_data/icu_properties_data-2.1.2.crate")
           (file-name "icu_properties_data-2.1.2.crate")
           (sha256
            (base32 "1bvpkh939rgzrjfdb7hz47v4wijngk0snmcgrnpwc9fpz162jv31"))))
   (cons "retained-rust-icu_provider-2.1.1"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/icu_provider/icu_provider-2.1.1.crate")
           (file-name "icu_provider-2.1.1.crate")
           (sha256
            (base32 "0576b7dizgyhpfa74kacv86y4g1p7v5ffd6c56kf1q82rvq2r5l5"))))
   (cons "retained-rust-id-arena-2.3.0"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/id-arena/id-arena-2.3.0.crate")
           (file-name "id-arena-2.3.0.crate")
           (sha256
            (base32 "0m6rs0jcaj4mg33gkv98d71w3hridghp5c4yr928hplpkgbnfc1x"))))
   (cons "retained-rust-idna-1.1.0"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/idna/idna-1.1.0.crate")
           (file-name "idna-1.1.0.crate")
           (sha256
            (base32 "1pp4n7hppm480zcx411dsv9wfibai00wbpgnjj4qj0xa7kr7a21v"))))
   (cons "retained-rust-indexmap-2.13.0"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/indexmap/indexmap-2.13.0.crate")
           (file-name "indexmap-2.13.0.crate")
           (sha256
            (base32 "05qh5c4h2hrnyypphxpwflk45syqbzvqsvvyxg43mp576w2ff53p"))))
   (cons "retained-rust-inferno-0.11.21"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/inferno/inferno-0.11.21.crate")
           (file-name "inferno-0.11.21.crate")
           (sha256
            (base32 "126v1njhhx1shw0ammn3ngxxp20dmlb78p1xd9brks2zszhjja93"))))
   (cons "retained-rust-inventory-0.3.22"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/inventory/inventory-0.3.22.crate")
           (file-name "inventory-0.3.22.crate")
           (sha256
            (base32 "09vjkq51bsm08f7i1p0x2h0dsxg03b8crc6sfb5q4w3yr12y16h0"))))
   (cons "retained-rust-ipnet-2.12.0"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/ipnet/ipnet-2.12.0.crate")
           (file-name "ipnet-2.12.0.crate")
           (sha256
            (base32 "1qpq2y0asyv0jppw7zww9y96fpnpinwap8a0phhqqgyy3znnz3yr"))))
   (cons "retained-rust-iri-string-0.7.11"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/iri-string/iri-string-0.7.11.crate")
           (file-name "iri-string-0.7.11.crate")
           (sha256
            (base32 "1sz5y5a9zqhh1n5fb25k2vipl8b5yskpj4hn2s1wh0fcb67l3ryq"))))
   (cons "retained-rust-is-terminal-0.4.17"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/is-terminal/is-terminal-0.4.17.crate")
           (file-name "is-terminal-0.4.17.crate")
           (sha256
            (base32 "0ilfr9n31m0k6fsm3gvfrqaa62kbzkjqpwcd9mc46klfig1w2h1n"))))
   (cons "retained-rust-itertools-0.12.1"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/itertools/itertools-0.12.1.crate")
           (file-name "itertools-0.12.1.crate")
           (sha256
            (base32 "0s95jbb3ndj1lvfxyq5wanc0fm0r6hg6q4ngb92qlfdxvci10ads"))))
   (cons "retained-rust-jni-0.21.1"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/jni/jni-0.21.1.crate")
           (file-name "jni-0.21.1.crate")
           (sha256
            (base32 "15wczfkr2r45slsljby12ymf2hij8wi5b104ghck9byjnwmsm1qs"))))
   (cons "retained-rust-jni-sys-0.3.1"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/jni-sys/jni-sys-0.3.1.crate")
           (file-name "jni-sys-0.3.1.crate")
           (sha256
            (base32 "0n1j8fbz081w1igfrpc79n6vgm7h3ik34nziy5fjgq5nz7hm59j1"))))
   (cons "retained-rust-jni-sys-0.4.1"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/jni-sys/jni-sys-0.4.1.crate")
           (file-name "jni-sys-0.4.1.crate")
           (sha256
            (base32 "1wlahx6f2zhczdjqyn8mk7kshb8x5vsd927sn3lvw41rrf47ldy6"))))
   (cons "retained-rust-jni-sys-macros-0.4.1"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/jni-sys-macros/jni-sys-macros-0.4.1.crate")
           (file-name "jni-sys-macros-0.4.1.crate")
           (sha256
            (base32 "0r32gbabrak15a7p487765b5wc0jcna2yv88mk6m1zjqyi1bkh1q"))))
   (cons "retained-rust-jobserver-0.1.34"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/jobserver/jobserver-0.1.34.crate")
           (file-name "jobserver-0.1.34.crate")
           (sha256
            (base32 "0cwx0fllqzdycqn4d6nb277qx5qwnmjdxdl0lxkkwssx77j3vyws"))))
   (cons "retained-rust-js-sys-0.3.98"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/js-sys/js-sys-0.3.98.crate")
           (file-name "js-sys-0.3.98.crate")
           (sha256
            (base32 "024zjwpxp6fri4j79bh1686q1x4nw4a06fh1a28zv2rzc4973pv7"))))
   (cons "retained-rust-konst-0.4.3"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/konst/konst-0.4.3.crate")
           (file-name "konst-0.4.3.crate")
           (sha256
            (base32 "07fbpslpn69dq3nmskvbsscl0savg644k8glnsd2ymp3hzwdaq7n"))))
   (cons "retained-rust-konst_proc_macros-0.4.1"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/konst_proc_macros/konst_proc_macros-0.4.1.crate")
           (file-name "konst_proc_macros-0.4.1.crate")
           (sha256
            (base32 "0si52sx4v0nk0ffz4pyakvrc20b4bnfs0kkan54vvzfmv3hs4dz0"))))
   (cons "retained-rust-leb128fmt-0.1.0"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/leb128fmt/leb128fmt-0.1.0.crate")
           (file-name "leb128fmt-0.1.0.crate")
           (sha256
            (base32 "1chxm1484a0bly6anh6bd7a99sn355ymlagnwj3yajafnpldkv89"))))
   (cons "retained-rust-libc-0.2.183"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/libc/libc-0.2.183.crate")
           (file-name "libc-0.2.183.crate")
           (sha256
            (base32 "17c9gyia7rrzf9gsssvk3vq9ca2jp6rh32fsw6ciarpn5djlddmm"))))
   (cons "retained-rust-libredox-0.1.14"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/libredox/libredox-0.1.14.crate")
           (file-name "libredox-0.1.14.crate")
           (sha256
            (base32 "02p3pxlqf54znf1jhiyyjs0i4caf8ckrd5l8ygs4i6ba3nfy6i0p"))))
   (cons "retained-rust-link-section-0.15.0"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/link-section/link-section-0.15.0.crate")
           (file-name "link-section-0.15.0.crate")
           (sha256
            (base32 "1m46qddkmnp76kwh9zfrppidkmhya8q5xsq73g35kfyy24bvjha6"))))
   (cons "retained-rust-linktime-proc-macro-0.1.0"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/linktime-proc-macro/linktime-proc-macro-0.1.0.crate")
           (file-name "linktime-proc-macro-0.1.0.crate")
           (sha256
            (base32 "108gasagydcdmb9hrqcd4a0y49ya21jicw905gikwl0dzw3dfk54"))))
   (cons "retained-rust-litemap-0.8.1"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/litemap/litemap-0.8.1.crate")
           (file-name "litemap-0.8.1.crate")
           (sha256
            (base32 "0xsy8pfp9s802rsj1bq2ys2kbk1g36w5dr3gkfip7gphb5x60wv3"))))
   (cons "retained-rust-lz4_flex-0.13.0"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/lz4_flex/lz4_flex-0.13.0.crate")
           (file-name "lz4_flex-0.13.0.crate")
           (sha256
            (base32 "12j8vd343l1n3xggh38apg0fdz8ggs3f2v51720zcx185ic0v6nv"))))
   (cons "retained-rust-matchers-0.2.0"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/matchers/matchers-0.2.0.crate")
           (file-name "matchers-0.2.0.crate")
           (sha256
            (base32 "1sasssspdj2vwcwmbq3ra18d3qniapkimfcbr47zmx6750m5llni"))))
   (cons "retained-rust-matchit-0.8.4"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/matchit/matchit-0.8.4.crate")
           (file-name "matchit-0.8.4.crate")
           (sha256
            (base32 "1hzl48fwq1cn5dvshfly6vzkzqhfihya65zpj7nz7lfx82mgzqa7"))))
   (cons "retained-rust-memchr-2.8.0"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/memchr/memchr-2.8.0.crate")
           (file-name "memchr-2.8.0.crate")
           (sha256
            (base32 "0y9zzxcqxvdqg6wyag7vc3h0blhdn7hkq164bxyx2vph8zs5ijpq"))))
   (cons "retained-rust-memmap2-0.9.10"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/memmap2/memmap2-0.9.10.crate")
           (file-name "memmap2-0.9.10.crate")
           (sha256
            (base32 "1qz0n4ch68pz2mp07sdwnk27imdjjqy6aqir3hp9j4g0iw19hh3i"))))
   (cons "retained-rust-mime-0.3.17"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/mime/mime-0.3.17.crate")
           (file-name "mime-0.3.17.crate")
           (sha256
            (base32 "16hkibgvb9klh0w0jk5crr5xv90l3wlf77ggymzjmvl1818vnxv8"))))
   (cons "retained-rust-mio-1.1.1"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/mio/mio-1.1.1.crate")
           (file-name "mio-1.1.1.crate")
           (sha256
            (base32 "1z2phpalqbdgihrcjp8y09l3kgq6309jnhnr6h11l9s7mnqcm6x6"))))
   (cons "retained-rust-more-asserts-0.3.1"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/more-asserts/more-asserts-0.3.1.crate")
           (file-name "more-asserts-0.3.1.crate")
           (sha256
            (base32 "0zj0f9z73nsn1zxk2y21f0mmafvz7dz5v93prlxwdndb3jbadbqz"))))
   (cons "retained-rust-native-tls-0.2.18"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/native-tls/native-tls-0.2.18.crate")
           (file-name "native-tls-0.2.18.crate")
           (sha256
            (base32 "1wmv0g5p6jwyyslyw88w5fv9kc9qvjd1hi2d4sfl4qm19vhh0ma6"))))
   (cons "retained-rust-nix-0.26.4"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/nix/nix-0.26.4.crate")
           (file-name "nix-0.26.4.crate")
           (sha256
            (base32 "06xgl4ybb8pvjrbmc3xggbgk3kbs1j0c4c0nzdfrmpbgrkrym2sr"))))
   (cons "retained-rust-ntapi-0.4.3"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/ntapi/ntapi-0.4.3.crate")
           (file-name "ntapi-0.4.3.crate")
           (sha256
            (base32 "1bl0d73avwla7laa4pkqvzvifjbs0avg65w01zxjydgx3likbcy3"))))
   (cons "retained-rust-num-conv-0.2.0"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/num-conv/num-conv-0.2.0.crate")
           (file-name "num-conv-0.2.0.crate")
           (sha256
            (base32 "0l4hj7lp8zbb9am4j3p7vlcv47y9bbazinvnxx9zjhiwkibyr5yg"))))
   (cons "retained-rust-num-format-0.4.4"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/num-format/num-format-0.4.4.crate")
           (file-name "num-format-0.4.4.crate")
           (sha256
            (base32 "1hvjmib117jspyixfr76f900mhz5zfn71dnyqg9iywb339vxjlm6"))))
   (cons "retained-rust-objc2-core-foundation-0.3.2"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/objc2-core-foundation/objc2-core-foundation-0.3.2.crate")
           (file-name "objc2-core-foundation-0.3.2.crate")
           (sha256
            (base32 "0dnmg7606n4zifyjw4ff554xvjmi256cs8fpgpdmr91gckc0s61a"))))
   (cons "retained-rust-objc2-io-kit-0.3.2"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/objc2-io-kit/objc2-io-kit-0.3.2.crate")
           (file-name "objc2-io-kit-0.3.2.crate")
           (sha256
            (base32 "05dvfcf97w39daaj5qsbfc399lw9hbx3s4h9nwgxrmlpjnizpyik"))))
   (cons "retained-rust-objc2-system-configuration-0.3.2"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/objc2-system-configuration/objc2-system-configuration-0.3.2.crate")
           (file-name "objc2-system-configuration-0.3.2.crate")
           (sha256
            (base32 "15m39m325yhkjpcagcygbv3qx19vr4ym4kdqramwqm6src8vs5kj"))))
   (cons "retained-rust-object-0.37.3"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/object/object-0.37.3.crate")
           (file-name "object-0.37.3.crate")
           (sha256
            (base32 "1zikiy9xhk6lfx1dn2gn2pxbnfpmlkn0byd7ib1n720x0cgj0xpz"))))
   (cons "retained-rust-oneshot-0.1.13"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/oneshot/oneshot-0.1.13.crate")
           (file-name "oneshot-0.1.13.crate")
           (sha256
            (base32 "01x1rp6s5hxx87n2pc5101lxgdrj0gnxj45zss2qb8li4m6cm6r6"))))
   (cons "retained-rust-openssl-0.10.79"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/openssl/openssl-0.10.79.crate")
           (file-name "openssl-0.10.79.crate")
           (sha256
            (base32 "0hpma19c8qrjwgi6jb4iwv5iifyaw4vh3wdsy3s34a7f8r3l62xz"))))
   (cons "retained-rust-openssl-probe-0.2.1"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/openssl-probe/openssl-probe-0.2.1.crate")
           (file-name "openssl-probe-0.2.1.crate")
           (sha256
            (base32 "1gpwpb7smfhkscwvbri8xzbab39wcnby1jgz1s49vf1aqgsdx1vw"))))
   (cons "retained-rust-openssl-src-300.5.5+3.5.5"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/openssl-src/openssl-src-300.5.5+3.5.5.crate")
           (file-name "openssl-src-300.5.5+3.5.5.crate")
           (sha256
            (base32 "02gpasd6j7iv0pw8jxzvqpn993njy1jsgl2gjfkrfdg06gaqf5rz"))))
   (cons "retained-rust-openssl-sys-0.9.115"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/openssl-sys/openssl-sys-0.9.115.crate")
           (file-name "openssl-sys-0.9.115.crate")
           (sha256
            (base32 "10cpkh7aswv97k108a2ya10jvdxfal76jzksdsm40r3ljarfb3qm"))))
   (cons "retained-rust-option-ext-0.2.0"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/option-ext/option-ext-0.2.0.crate")
           (file-name "option-ext-0.2.0.crate")
           (sha256
            (base32 "0zbf7cx8ib99frnlanpyikm1bx8qn8x602sw1n7bg6p9x94lyx04"))))
   (cons "retained-rust-os_str_bytes-6.6.1"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/os_str_bytes/os_str_bytes-6.6.1.crate")
           (file-name "os_str_bytes-6.6.1.crate")
           (sha256
            (base32 "1885z1x4sm86v5p41ggrl49m58rbzzhd1kj72x46yy53p62msdg2"))))
   (cons "retained-rust-percent-encoding-2.3.2"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/percent-encoding/percent-encoding-2.3.2.crate")
           (file-name "percent-encoding-2.3.2.crate")
           (sha256
            (base32 "083jv1ai930azvawz2khv7w73xh8mnylk7i578cifndjn5y64kwv"))))
   (cons "retained-rust-pin-project-1.1.11"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/pin-project/pin-project-1.1.11.crate")
           (file-name "pin-project-1.1.11.crate")
           (sha256
            (base32 "05zm3y3bl83ypsr6favxvny2kys4i19jiz1y18ylrbxwsiz9qx7i"))))
   (cons "retained-rust-pin-project-internal-1.1.11"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/pin-project-internal/pin-project-internal-1.1.11.crate")
           (file-name "pin-project-internal-1.1.11.crate")
           (sha256
            (base32 "1ik4mpb92da75inmjvxf2qm61vrnwml3x24wddvrjlqh1z9hxcnr"))))
   (cons "retained-rust-portable-atomic-1.13.1"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/portable-atomic/portable-atomic-1.13.1.crate")
           (file-name "portable-atomic-1.13.1.crate")
           (sha256
            (base32 "0j8vlar3n5acyigq8q6f4wjx3k3s5yz0rlpqrv76j73gi5qr8fn3"))))
   (cons "retained-rust-potential_utf-0.1.4"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/potential_utf/potential_utf-0.1.4.crate")
           (file-name "potential_utf-0.1.4.crate")
           (sha256
            (base32 "0xxg0pkfpq299wvwln409z4fk80rbv55phh3f1jhjajy5x1ljfdp"))))
   (cons "retained-rust-pprof-0.14.1"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/pprof/pprof-0.14.1.crate")
           (file-name "pprof-0.14.1.crate")
           (sha256
            (base32 "17v8fwz6aisydxrhabc2pcm3w23mlpam5wa5h81804mkyx6lvbdg"))))
   (cons "retained-rust-prettyplease-0.2.37"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/prettyplease/prettyplease-0.2.37.crate")
           (file-name "prettyplease-0.2.37.crate")
           (sha256
            (base32 "0azn11i1kh0byabhsgab6kqs74zyrg69xkirzgqyhz6xmjnsi727"))))
   (cons "retained-rust-proc-macro2-1.0.106"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/proc-macro2/proc-macro2-1.0.106.crate")
           (file-name "proc-macro2-1.0.106.crate")
           (sha256
            (base32 "0d09nczyaj67x4ihqr5p7gxbkz38gxhk4asc0k8q23g9n85hzl4g"))))
   (cons "retained-rust-prost-0.12.6"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/prost/prost-0.12.6.crate")
           (file-name "prost-0.12.6.crate")
           (sha256
            (base32 "0a8z87ir8yqjgl1kxbdj30a7pzsjs9ka85szll6i6xlb31f47cfy"))))
   (cons "retained-rust-prost-0.14.3"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/prost/prost-0.14.3.crate")
           (file-name "prost-0.14.3.crate")
           (sha256
            (base32 "0s057z9nzggzy7x4bbsiar852hg7zb81f4z4phcdb0ig99971snj"))))
   (cons "retained-rust-prost-derive-0.12.6"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/prost-derive/prost-derive-0.12.6.crate")
           (file-name "prost-derive-0.12.6.crate")
           (sha256
            (base32 "1waaq9d2f114bvvpw957s7vsx268licnfawr20b51ydb43dxrgc1"))))
   (cons "retained-rust-prost-derive-0.14.3"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/prost-derive/prost-derive-0.14.3.crate")
           (file-name "prost-derive-0.14.3.crate")
           (sha256
            (base32 "02zvva6kb0pfvlyc4nac6gd37ncjrs8jq5scxcq4nbqkc8wh5ii7"))))
   (cons "retained-rust-prost-types-0.14.3"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/prost-types/prost-types-0.14.3.crate")
           (file-name "prost-types-0.14.3.crate")
           (sha256
            (base32 "1mrxrciryfgi6a0vmrgyj3g27r9hdhlgwkq71cgv3icbvg5w94c9"))))
   (cons "retained-rust-protobuf-2.28.0"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/protobuf/protobuf-2.28.0.crate")
           (file-name "protobuf-2.28.0.crate")
           (sha256
            (base32 "154dfzjvxlpx37ha3cmp7fkhcsnyzbnfv7aisvz34x23k2gdjv8h"))))
   (cons "retained-rust-protobuf-codegen-2.28.0"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/protobuf-codegen/protobuf-codegen-2.28.0.crate")
           (file-name "protobuf-codegen-2.28.0.crate")
           (sha256
            (base32 "1mhpl2cs1d2sqddf097ala180il61g9axpqnzky5bxswnypn0d03"))))
   (cons "retained-rust-protobuf-codegen-pure-2.28.0"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/protobuf-codegen-pure/protobuf-codegen-pure-2.28.0.crate")
           (file-name "protobuf-codegen-pure-2.28.0.crate")
           (sha256
            (base32 "0rfqvpbbqh4pa406nda54jdl0sgagdgp274mmbpd7g4lzjcr78lm"))))
   (cons "retained-rust-quick-xml-0.26.0"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/quick-xml/quick-xml-0.26.0.crate")
           (file-name "quick-xml-0.26.0.crate")
           (sha256
            (base32 "1kckgj8qscpi23y62zrfmni73k6h78nvhs3z9myiwq9q7g3b2l3z"))))
   (cons "retained-rust-quinn-0.11.9"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/quinn/quinn-0.11.9.crate")
           (file-name "quinn-0.11.9.crate")
           (sha256
            (base32 "086gzj666dr3slmlynkvxlndy28hahgl361d6bf93hk3i6ahmqmr"))))
   (cons "retained-rust-quinn-proto-0.11.15"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/quinn-proto/quinn-proto-0.11.15.crate")
           (file-name "quinn-proto-0.11.15.crate")
           (sha256
            (base32 "0gknq1m2b9g3fsndka2gn7f2k45vb0zdssrh1qpkql7cbdf97jsg"))))
   (cons "retained-rust-quinn-udp-0.5.14"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/quinn-udp/quinn-udp-0.5.14.crate")
           (file-name "quinn-udp-0.5.14.crate")
           (sha256
            (base32 "1gacawr17a2zkyri0r3m0lc9spzmxbq1by3ilyb8v2mdvjhcdpmd"))))
   (cons "retained-rust-quote-1.0.45"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/quote/quote-1.0.45.crate")
           (file-name "quote-1.0.45.crate")
           (sha256
            (base32 "095rb5rg7pbnwdp6v8w5jw93wndwyijgci1b5lw8j1h5cscn3wj1"))))
   (cons "retained-rust-rand-0.10.1"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/rand/rand-0.10.1.crate")
           (file-name "rand-0.10.1.crate")
           (sha256
            (base32 "01r22vdpw6z69jzy6khnyr0ljq9im337h4j0mkyz26lnqyyfis6j"))))
   (cons "retained-rust-rand_core-0.9.5"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/rand_core/rand_core-0.9.5.crate")
           (file-name "rand_core-0.9.5.crate")
           (sha256
            (base32 "0g6qc5r3f0hdmz9b11nripyp9qqrzb0xqk9piip8w8qlvqkcibvn"))))
   (cons "retained-rust-redb-3.1.1"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/redb/redb-3.1.1.crate")
           (file-name "redb-3.1.1.crate")
           (sha256
            (base32 "04c6k2fngjr4y66rpsbl53hr1fy3cimk0fmd753am0n734ikd6gg"))))
   (cons "retained-rust-redox_users-0.5.2"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/redox_users/redox_users-0.5.2.crate")
           (file-name "redox_users-0.5.2.crate")
           (sha256
            (base32 "1b17q7gf7w8b1vvl53bxna24xl983yn7bd00gfbii74bcg30irm4"))))
   (cons "retained-rust-regex-1.12.3"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/regex/regex-1.12.3.crate")
           (file-name "regex-1.12.3.crate")
           (sha256
            (base32 "0xp2q0x7ybmpa5zlgaz00p8zswcirj9h8nry3rxxsdwi9fhm81z1"))))
   (cons "retained-rust-regex-automata-0.4.14"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/regex-automata/regex-automata-0.4.14.crate")
           (file-name "regex-automata-0.4.14.crate")
           (sha256
            (base32 "13xf7hhn4qmgfh784llcp2kzrvljd13lb2b1ca0mwnf15w9d87bf"))))
   (cons "retained-rust-regex-syntax-0.8.10"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/regex-syntax/regex-syntax-0.8.10.crate")
           (file-name "regex-syntax-0.8.10.crate")
           (sha256
            (base32 "02jx311ka0daxxc7v45ikzhcl3iydjbbb0mdrpc1xgg8v7c7v2fw"))))
   (cons "retained-rust-reqwest-0.13.2"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/reqwest/reqwest-0.13.2.crate")
           (file-name "reqwest-0.13.2.crate")
           (sha256
            (base32 "00d8xyrbcp0519rr9rhl685ymb6hi3lv0i2bca5lic9s53il6gxb"))))
   (cons "retained-rust-reqwest-middleware-0.5.1"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/reqwest-middleware/reqwest-middleware-0.5.1.crate")
           (file-name "reqwest-middleware-0.5.1.crate")
           (sha256
            (base32 "0vq5jq5w0sbh043ibycvfkm67ixi76g9gmq4rk835d9nll2dm78r"))))
   (cons "retained-rust-rgb-0.8.53"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/rgb/rgb-0.8.53.crate")
           (file-name "rgb-0.8.53.crate")
           (sha256
            (base32 "1i0c55whln68zs6f5qqrkbg1mzai0p3qk1mwkwzdgr9i3dw4pcs7"))))
   (cons "retained-rust-rustc-demangle-0.1.27"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/rustc-demangle/rustc-demangle-0.1.27.crate")
           (file-name "rustc-demangle-0.1.27.crate")
           (sha256
            (base32 "17f0jl6lgsy8kwxdzxp3s2wmipvlpna03kkc4vkqr1gwv5lqh2xm"))))
   (cons "retained-rust-rustls-0.23.37"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/rustls/rustls-0.23.37.crate")
           (file-name "rustls-0.23.37.crate")
           (sha256
            (base32 "193k5h0wcih6ghvkrxyzwncivr1bd3a8yw3lzp13pzfcbz5jb03m"))))
   (cons "retained-rust-rustls-native-certs-0.8.3"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/rustls-native-certs/rustls-native-certs-0.8.3.crate")
           (file-name "rustls-native-certs-0.8.3.crate")
           (sha256
            (base32 "0qrajg2n90bcr3bcq6j95gjm7a9lirfkkdmjj32419dyyzan0931"))))
   (cons "retained-rust-rustls-pki-types-1.14.0"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/rustls-pki-types/rustls-pki-types-1.14.0.crate")
           (file-name "rustls-pki-types-1.14.0.crate")
           (sha256
            (base32 "1p9zsgslvwzzkzhm6bqicffqndr4jpx67992b0vl0pi21a5hy15y"))))
   (cons "retained-rust-rustls-platform-verifier-0.6.2"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/rustls-platform-verifier/rustls-platform-verifier-0.6.2.crate")
           (file-name "rustls-platform-verifier-0.6.2.crate")
           (sha256
            (base32 "110pqkn3px9115pb6h6a23cq738v29gbp559dfvpmbibqzmzx68x"))))
   (cons "retained-rust-rustls-platform-verifier-android-0.1.1"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/rustls-platform-verifier-android/rustls-platform-verifier-android-0.1.1.crate")
           (file-name "rustls-platform-verifier-android-0.1.1.crate")
           (sha256
            (base32 "13vq6sxsgz9547xm2zbdxiw8x7ad1g8n8ax6xvxsjqszk7q6awgq"))))
   (cons "retained-rust-rustls-webpki-0.103.13"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/rustls-webpki/rustls-webpki-0.103.13.crate")
           (file-name "rustls-webpki-0.103.13.crate")
           (sha256
            (base32 "0vkm7z9pnxz5qz66p2kmyy2pwx0g4jnsbqk5xzfhs4czcjl2ki31"))))
   (cons "retained-rust-safe-transmute-0.11.3"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/safe-transmute/safe-transmute-0.11.3.crate")
           (file-name "safe-transmute-0.11.3.crate")
           (sha256
            (base32 "0zdb839pfgxgfi7bzwqnkalld52byi7cnfmsk849707sz1pq4i1r"))))
   (cons "retained-rust-schannel-0.1.29"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/schannel/schannel-0.1.29.crate")
           (file-name "schannel-0.1.29.crate")
           (sha256
            (base32 "0ffrzz5vf2s3gnzvphgb5gg8fqifvryl07qcf7q3x1scj3jbghci"))))
   (cons "retained-rust-security-framework-3.7.0"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/security-framework/security-framework-3.7.0.crate")
           (file-name "security-framework-3.7.0.crate")
           (sha256
            (base32 "07fd0j29j8yczb3hd430vwz784lx9knb5xwbvqna1nbkbivvrx5p"))))
   (cons "retained-rust-security-framework-sys-2.17.0"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/security-framework-sys/security-framework-sys-2.17.0.crate")
           (file-name "security-framework-sys-2.17.0.crate")
           (sha256
            (base32 "1qr0w0y9iwvmv3hwg653q1igngnc5b74xcf0679cbv23z0fnkqkc"))))
   (cons "retained-rust-serde_repr-0.1.20"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/serde_repr/serde_repr-0.1.20.crate")
           (file-name "serde_repr-0.1.20.crate")
           (sha256
            (base32 "1755gss3f6lwvv23pk7fhnjdkjw7609rcgjlr8vjg6791blf6php"))))
   (cons "retained-rust-sha2-asm-0.6.4"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/sha2-asm/sha2-asm-0.6.4.crate")
           (file-name "sha2-asm-0.6.4.crate")
           (sha256
            (base32 "1ay1vai08d802avl41r0s6r1nrcnzv7jnj5xna34d03mc56j2idq"))))
   (cons "retained-rust-shellexpand-3.1.2"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/shellexpand/shellexpand-3.1.2.crate")
           (file-name "shellexpand-3.1.2.crate")
           (sha256
            (base32 "1n3y55yvh2s8cqmqb6bnz4wrlhchjd489fn1dpcc9rhnbsmlz0ij"))))
   (cons "retained-rust-signal-hook-0.3.18"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/signal-hook/signal-hook-0.3.18.crate")
           (file-name "signal-hook-0.3.18.crate")
           (sha256
            (base32 "1qnnbq4g2vixfmlv28i1whkr0hikrf1bsc4xjy2aasj2yina30fq"))))
   (cons "retained-rust-signal-hook-registry-1.4.8"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/signal-hook-registry/signal-hook-registry-1.4.8.crate")
           (file-name "signal-hook-registry-1.4.8.crate")
           (sha256
            (base32 "06vc7pmnki6lmxar3z31gkyg9cw7py5x9g7px70gy2hil75nkny4"))))
   (cons "retained-rust-simd-adler32-0.3.8"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/simd-adler32/simd-adler32-0.3.8.crate")
           (file-name "simd-adler32-0.3.8.crate")
           (sha256
            (base32 "18lx2gdgislabbvlgw5q3j5ssrr77v8kmkrxaanp3liimp2sc873"))))
   (cons "retained-rust-socket2-0.6.3"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/socket2/socket2-0.6.3.crate")
           (file-name "socket2-0.6.3.crate")
           (sha256
            (base32 "0gkjjcyn69hqhhlh5kl8byk5m0d7hyrp2aqwzbs3d33q208nwxis"))))
   (cons "retained-rust-spin-0.10.0"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/spin/spin-0.10.0.crate")
           (file-name "spin-0.10.0.crate")
           (sha256
            (base32 "14g5sdsjf4wk2ys5dq8ivkq4rz57gphab2gcdzar5hnrk35lrznm"))))
   (cons "retained-rust-stable_deref_trait-1.2.1"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/stable_deref_trait/stable_deref_trait-1.2.1.crate")
           (file-name "stable_deref_trait-1.2.1.crate")
           (sha256
            (base32 "15h5h73ppqyhdhx6ywxfj88azmrpml9gl6zp3pwy2malqa6vxqkc"))))
   (cons "retained-rust-statrs-0.18.0"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/statrs/statrs-0.18.0.crate")
           (file-name "statrs-0.18.0.crate")
           (sha256
            (base32 "0pikgp74gg9a3jp2hhh5z6wdfjn96gdkahw7n1kff4k5ik1ffgra"))))
   (cons "retained-rust-str_stack-0.1.0"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/str_stack/str_stack-0.1.0.crate")
           (file-name "str_stack-0.1.0.crate")
           (sha256
            (base32 "1sxl8xd8kiaffsryqpfwcb02lnd3djfin7gf38ag5980908vd4ch"))))
   (cons "retained-rust-symbolic-common-12.17.3"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/symbolic-common/symbolic-common-12.17.3.crate")
           (file-name "symbolic-common-12.17.3.crate")
           (sha256
            (base32 "1mb8krigcn1zdyw93ncaq3w36pbx93387fjin5sfxixm3rn0ijjj"))))
   (cons "retained-rust-symbolic-demangle-12.17.3"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/symbolic-demangle/symbolic-demangle-12.17.3.crate")
           (file-name "symbolic-demangle-12.17.3.crate")
           (sha256
            (base32 "032wzw4a3d0jbf7wq9nrs1lyx8wj4hhp9q625jpkm0k2iai13ads"))))
   (cons "retained-rust-syn-2.0.117"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/syn/syn-2.0.117.crate")
           (file-name "syn-2.0.117.crate")
           (sha256
            (base32 "16cv7c0wbn8amxc54n4w15kxlx5ypdmla8s0gxr2l7bv7s0bhrg6"))))
   (cons "retained-rust-sysinfo-0.38.4"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/sysinfo/sysinfo-0.38.4.crate")
           (file-name "sysinfo-0.38.4.crate")
           (sha256
            (base32 "0bx5wjp16cyckr9c0fxzrfcx54g4aa15f1k47kmqsl7yicpnmawj"))))
   (cons "retained-rust-system-configuration-0.7.0"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/system-configuration/system-configuration-0.7.0.crate")
           (file-name "system-configuration-0.7.0.crate")
           (sha256
            (base32 "12rwilylzc625qnxl30h5kf8wj5ka61zjrwpmb034cd0mc6ksgx1"))))
   (cons "retained-rust-system-configuration-sys-0.6.0"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/system-configuration-sys/system-configuration-sys-0.6.0.crate")
           (file-name "system-configuration-sys-0.6.0.crate")
           (sha256
            (base32 "1i5sqrmgy58l4704hibjbl36hclddglh73fb3wx95jnmrq81n7cf"))))
   (cons "retained-rust-thiserror-2.0.18"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/thiserror/thiserror-2.0.18.crate")
           (file-name "thiserror-2.0.18.crate")
           (sha256
            (base32 "1i7vcmw9900bvsmay7mww04ahahab7wmr8s925xc083rpjybb222"))))
   (cons "retained-rust-thiserror-impl-2.0.18"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/thiserror-impl/thiserror-impl-2.0.18.crate")
           (file-name "thiserror-impl-2.0.18.crate")
           (sha256
            (base32 "1mf1vrbbimj1g6dvhdgzjmn6q09yflz2b92zs1j9n3k7cxzyxi7b"))))
   (cons "retained-rust-time-0.3.47"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/time/time-0.3.47.crate")
           (file-name "time-0.3.47.crate")
           (sha256
            (base32 "0b7g9ly2iabrlgizliz6v5x23yq5d6bpp0mqz6407z1s526d8fvl"))))
   (cons "retained-rust-time-core-0.1.8"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/time-core/time-core-0.1.8.crate")
           (file-name "time-core-0.1.8.crate")
           (sha256
            (base32 "1jidl426mw48i7hjj4hs9vxgd9lwqq4vyalm4q8d7y4iwz7y353n"))))
   (cons "retained-rust-time-macros-0.2.27"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/time-macros/time-macros-0.2.27.crate")
           (file-name "time-macros-0.2.27.crate")
           (sha256
            (base32 "058ja265waq275wxvnfwavbz9r1hd4dgwpfn7a1a9a70l32y8w1f"))))
   (cons "retained-rust-tinystr-0.8.2"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/tinystr/tinystr-0.8.2.crate")
           (file-name "tinystr-0.8.2.crate")
           (sha256
            (base32 "0sa8z88axdsf088hgw5p4xcyi6g3w3sgbb6qdp81bph9bk2fkls2"))))
   (cons "retained-rust-tinyvec-1.11.0"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/tinyvec/tinyvec-1.11.0.crate")
           (file-name "tinyvec-1.11.0.crate")
           (sha256
            (base32 "1wvycrghzmaysnw34kzwnf0mfx6r75045s24r214wnnjadqfcq9y"))))
   (cons "retained-rust-tokio-1.50.0"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/tokio/tokio-1.50.0.crate")
           (file-name "tokio-1.50.0.crate")
           (sha256
            (base32 "0bc2c5kd57p2xd4l6hagb0bkrp798k5vw0f3xzzwy0sf6ws5xb97"))))
   (cons "retained-rust-tokio-macros-2.6.1"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/tokio-macros/tokio-macros-2.6.1.crate")
           (file-name "tokio-macros-2.6.1.crate")
           (sha256
            (base32 "172nwz3s7mmh266hb8l5xdnc7v9kqahisppqhinfd75nz3ps4maw"))))
   (cons "retained-rust-tokio-native-tls-0.3.1"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/tokio-native-tls/tokio-native-tls-0.3.1.crate")
           (file-name "tokio-native-tls-0.3.1.crate")
           (sha256
            (base32 "1wkfg6zn85zckmv4im7mv20ca6b1vmlib5xwz9p7g19wjfmpdbmv"))))
   (cons "retained-rust-tokio-retry-0.3.1"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/tokio-retry/tokio-retry-0.3.1.crate")
           (file-name "tokio-retry-0.3.1.crate")
           (sha256
            (base32 "0h463h66srhgmnz29s9j8n67a3abjmf97y723a1rdlz9cb3l9xj0"))))
   (cons "retained-rust-tokio-rustls-0.26.4"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/tokio-rustls/tokio-rustls-0.26.4.crate")
           (file-name "tokio-rustls-0.26.4.crate")
           (sha256
            (base32 "0qggwknz9w4bbsv1z158hlnpkm97j3w8v31586jipn99byaala8p"))))
   (cons "retained-rust-tokio-stream-0.1.18"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/tokio-stream/tokio-stream-0.1.18.crate")
           (file-name "tokio-stream-0.1.18.crate")
           (sha256
            (base32 "0w3cj33605ab58wqd382gnla5pnd9hnr00xgg333np5bka04knij"))))
   (cons "retained-rust-tokio-util-0.7.18"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/tokio-util/tokio-util-0.7.18.crate")
           (file-name "tokio-util-0.7.18.crate")
           (sha256
            (base32 "1600rd47pylwn7cap1k7s5nvdaa9j7w8kqigzp1qy7mh0p4cxscs"))))
   (cons "retained-rust-tokio_with_wasm-0.8.8"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/tokio_with_wasm/tokio_with_wasm-0.8.8.crate")
           (file-name "tokio_with_wasm-0.8.8.crate")
           (sha256
            (base32 "19kak9sjipgjv3mn8qb3vhkgvnqmvcigb0wlzqri2i4mpnxhzr1l"))))
   (cons "retained-rust-tokio_with_wasm_proc-0.8.8"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/tokio_with_wasm_proc/tokio_with_wasm_proc-0.8.8.crate")
           (file-name "tokio_with_wasm_proc-0.8.8.crate")
           (sha256
            (base32 "14p9im1f9bzwrsbiil43szbk899kx30zwfk5rpjamml8qyi4a4fh"))))
   (cons "retained-rust-tonic-0.14.5"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/tonic/tonic-0.14.5.crate")
           (file-name "tonic-0.14.5.crate")
           (sha256
            (base32 "1v4k7aa28m7722gz9qak2jiy7lis1ycm4fdmq63iip4m0qdcdizy"))))
   (cons "retained-rust-tonic-prost-0.14.5"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/tonic-prost/tonic-prost-0.14.5.crate")
           (file-name "tonic-prost-0.14.5.crate")
           (sha256
            (base32 "02fkg2bv87q0yds2wz3w0s7i1x6qcgbrl00dy6ipajdapfh7clx5"))))
   (cons "retained-rust-tower-0.5.3"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/tower/tower-0.5.3.crate")
           (file-name "tower-0.5.3.crate")
           (sha256
            (base32 "1m5i3a2z1sgs8nnz1hgfq2nr4clpdmizlp1d9qsg358ma5iyzrgb"))))
   (cons "retained-rust-tower-http-0.6.8"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/tower-http/tower-http-0.6.8.crate")
           (file-name "tower-http-0.6.8.crate")
           (sha256
            (base32 "1y514jwzbyrmrkbaajpwmss4rg0mak82k16d6588w9ncaffmbrnl"))))
   (cons "retained-rust-tracing-appender-0.2.4"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/tracing-appender/tracing-appender-0.2.4.crate")
           (file-name "tracing-appender-0.2.4.crate")
           (sha256
            (base32 "1bxf7xvsr89glbq174cx0b9pinaacbhlmc85y1ssniv2rq5lhvbq"))))
   (cons "retained-rust-tracing-serde-0.2.0"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/tracing-serde/tracing-serde-0.2.0.crate")
           (file-name "tracing-serde-0.2.0.crate")
           (sha256
            (base32 "1wbgzi364vzfswfkvy48a3p0z5xmv98sx342r57sil70ggmiljvh"))))
   (cons "retained-rust-tracing-subscriber-0.3.23"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/tracing-subscriber/tracing-subscriber-0.3.23.crate")
           (file-name "tracing-subscriber-0.3.23.crate")
           (sha256
            (base32 "06fkr0qhggvrs861d7f74pn3i3a10h5jsp4n70jj9ys5b675fzyb"))))
   (cons "retained-rust-twox-hash-2.1.2"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/twox-hash/twox-hash-2.1.2.crate")
           (file-name "twox-hash-2.1.2.crate")
           (sha256
            (base32 "1721278f1yc5zvkpdb8gsb1x6nlfjdmwm5fk9ff3fismcxmi78wy"))))
   (cons "retained-rust-typewit-1.14.2"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/typewit/typewit-1.14.2.crate")
           (file-name "typewit-1.14.2.crate")
           (sha256
            (base32 "0wag2gf66s4qlb3x2x4v4hmhsjsph6wpq4jxsr1bif7xq1yaxhgq"))))
   (cons "retained-rust-unicode-xid-0.2.6"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/unicode-xid/unicode-xid-0.2.6.crate")
           (file-name "unicode-xid-0.2.6.crate")
           (sha256
            (base32 "0lzqaky89fq0bcrh6jj6bhlz37scfd8c7dsj5dq7y32if56c1hgb"))))
   (cons "retained-rust-url-2.5.8"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/url/url-2.5.8.crate")
           (file-name "url-2.5.8.crate")
           (sha256
            (base32 "1v8f7nx3hpr1qh76if0a04sj08k86amsq4h8cvpw6wvk76jahrzz"))))
   (cons "retained-rust-urlencoding-2.1.3"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/urlencoding/urlencoding-2.1.3.crate")
           (file-name "urlencoding-2.1.3.crate")
           (sha256
            (base32 "1nj99jp37k47n0hvaz5fvz7z6jd0sb4ppvfy3nphr1zbnyixpy6s"))))
   (cons "retained-rust-uuid-1.22.0"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/uuid/uuid-1.22.0.crate")
           (file-name "uuid-1.22.0.crate")
           (sha256
            (base32 "0dvsfn44sddhyhlhk7m3i559wyb125h86799fm5abky0067kr3d6"))))
   (cons "retained-rust-wasi-0.14.7+wasi-0.2.4"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/wasi/wasi-0.14.7+wasi-0.2.4.crate")
           (file-name "wasi-0.14.7+wasi-0.2.4.crate")
           (sha256
            (base32 "133fq3mq7h65mzrsphcm7bbbx1gsz7srrbwh01624zin43g7hd48"))))
   (cons "retained-rust-wasip2-1.0.2+wasi-0.2.9"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/wasip2/wasip2-1.0.2+wasi-0.2.9.crate")
           (file-name "wasip2-1.0.2+wasi-0.2.9.crate")
           (sha256
            (base32 "1xdw7v08jpfjdg94sp4lbdgzwa587m5ifpz6fpdnkh02kwizj5wm"))))
   (cons "retained-rust-wasip3-0.4.0+wasi-0.3.0-rc-2026-01-06"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/wasip3/wasip3-0.4.0+wasi-0.3.0-rc-2026-01-06.crate")
           (file-name "wasip3-0.4.0+wasi-0.3.0-rc-2026-01-06.crate")
           (sha256
            (base32 "19dc8p0y2mfrvgk3qw3c3240nfbylv22mvyxz84dqpgai2zzha2l"))))
   (cons "retained-rust-wasite-1.0.2"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/wasite/wasite-1.0.2.crate")
           (file-name "wasite-1.0.2.crate")
           (sha256
            (base32 "0hhsyylwsnbyz6dsr7i0gadzgk34nw4ljhnmafkji03b98mr1zk6"))))
   (cons "retained-rust-wasm-bindgen-0.2.121"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/wasm-bindgen/wasm-bindgen-0.2.121.crate")
           (file-name "wasm-bindgen-0.2.121.crate")
           (sha256
            (base32 "14375vc40l67lk9rxp59my4r6s64h2an3vjfh9j0hnqngk8f3b29"))))
   (cons "retained-rust-wasm-bindgen-futures-0.4.71"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/wasm-bindgen-futures/wasm-bindgen-futures-0.4.71.crate")
           (file-name "wasm-bindgen-futures-0.4.71.crate")
           (sha256
            (base32 "1f3k8r13nqshrlxwq0naxpbh250b4l6p526wlw2m78pv7w6jsjcn"))))
   (cons "retained-rust-wasm-bindgen-macro-0.2.121"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/wasm-bindgen-macro/wasm-bindgen-macro-0.2.121.crate")
           (file-name "wasm-bindgen-macro-0.2.121.crate")
           (sha256
            (base32 "0y45ghbkvs5rmxvdyhqrx8nzyy45rdx6619c01iaarykmzsfcs4f"))))
   (cons "retained-rust-wasm-bindgen-macro-support-0.2.121"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/wasm-bindgen-macro-support/wasm-bindgen-macro-support-0.2.121.crate")
           (file-name "wasm-bindgen-macro-support-0.2.121.crate")
           (sha256
            (base32 "1wjr69qa8rwmk4v7243dr100k393qi0avznk6p5sgck4bk1rwnnr"))))
   (cons "retained-rust-wasm-bindgen-shared-0.2.121"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/wasm-bindgen-shared/wasm-bindgen-shared-0.2.121.crate")
           (file-name "wasm-bindgen-shared-0.2.121.crate")
           (sha256
            (base32 "0h9la4176j5bvgbr64cqkmirif8z59vrcax9i4qx1w79045i1q64"))))
   (cons "retained-rust-wasm-encoder-0.244.0"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/wasm-encoder/wasm-encoder-0.244.0.crate")
           (file-name "wasm-encoder-0.244.0.crate")
           (sha256
            (base32 "06c35kv4h42vk3k51xjz1x6hn3mqwfswycmr6ziky033zvr6a04r"))))
   (cons "retained-rust-wasm-metadata-0.244.0"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/wasm-metadata/wasm-metadata-0.244.0.crate")
           (file-name "wasm-metadata-0.244.0.crate")
           (sha256
            (base32 "02f9dhlnryd2l7zf03whlxai5sv26x4spfibjdvc3g9gd8z3a3mv"))))
   (cons "retained-rust-wasm-streams-0.5.0"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/wasm-streams/wasm-streams-0.5.0.crate")
           (file-name "wasm-streams-0.5.0.crate")
           (sha256
            (base32 "1fqbcx33w8ys5i5dv3p28a82g4yiclmhn80fcfp137kwa7vc87lx"))))
   (cons "retained-rust-wasmparser-0.244.0"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/wasmparser/wasmparser-0.244.0.crate")
           (file-name "wasmparser-0.244.0.crate")
           (sha256
            (base32 "1zi821hrlsxfhn39nqpmgzc0wk7ax3dv6vrs5cw6kb0v5v3hgf27"))))
   (cons "retained-rust-web-sys-0.3.98"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/web-sys/web-sys-0.3.98.crate")
           (file-name "web-sys-0.3.98.crate")
           (sha256
            (base32 "1aijiwx7wsfzj37p1gnqn6wv4j2ppf4rqwhrzb8blf6gigzjsmsb"))))
   (cons "retained-rust-webpki-root-certs-1.0.6"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/webpki-root-certs/webpki-root-certs-1.0.6.crate")
           (file-name "webpki-root-certs-1.0.6.crate")
           (sha256
            (base32 "1jm844z3caldlsb4ycb2h7q6vw4awfdgmddmx2sgyxi6mjj1hkw0"))))
   (cons "retained-rust-whoami-2.1.1"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/whoami/whoami-2.1.1.crate")
           (file-name "whoami-2.1.1.crate")
           (sha256
            (base32 "0pglq0a1qnjzqblpwb9ljd1z8cr4qnxd66yvrz97iyglklpv39fn"))))
   (cons "retained-rust-winapi-util-0.1.11"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/winapi-util/winapi-util-0.1.11.crate")
           (file-name "winapi-util-0.1.11.crate")
           (sha256
            (base32 "08hdl7mkll7pz8whg869h58c1r9y7in0w0pk8fm24qc77k0b39y2"))))
   (cons "retained-rust-windows-0.62.2"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/windows/windows-0.62.2.crate")
           (file-name "windows-0.62.2.crate")
           (sha256
            (base32 "10457l9ihrbw8j79z2v4plyjxkf6xvb5npd0lqwmkh702gpaszsj"))))
   (cons "retained-rust-windows-collections-0.3.2"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/windows-collections/windows-collections-0.3.2.crate")
           (file-name "windows-collections-0.3.2.crate")
           (sha256
            (base32 "0436rjbkqn3j9m2v2lcmwwk0l3n2r57yvqb7fcy4m8d8y5ddkci3"))))
   (cons "retained-rust-windows-future-0.3.2"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/windows-future/windows-future-0.3.2.crate")
           (file-name "windows-future-0.3.2.crate")
           (sha256
            (base32 "1jq5qs2dwzf6rl60f8gr49z2mifxsrdh4y4yfdws467ya41gkmp1"))))
   (cons "retained-rust-windows-numerics-0.3.1"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/windows-numerics/windows-numerics-0.3.1.crate")
           (file-name "windows-numerics-0.3.1.crate")
           (sha256
            (base32 "09hgbg8pf89r4090yyhh9q29ppi7yyxkgmga9ascshy19a240bkf"))))
   (cons "retained-rust-windows-registry-0.6.1"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/windows-registry/windows-registry-0.6.1.crate")
           (file-name "windows-registry-0.6.1.crate")
           (sha256
            (base32 "082p7l615qk8a4g8g15yipc5lghga6cgfhm74wm7zknwzgvjnx82"))))
   (cons "retained-rust-windows-sys-0.45.0"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/windows-sys/windows-sys-0.45.0.crate")
           (file-name "windows-sys-0.45.0.crate")
           (sha256
            (base32 "1l36bcqm4g89pknfp8r9rl1w4bn017q6a8qlx8viv0xjxzjkna3m"))))
   (cons "retained-rust-windows-targets-0.42.2"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/windows-targets/windows-targets-0.42.2.crate")
           (file-name "windows-targets-0.42.2.crate")
           (sha256
            (base32 "0wfhnib2fisxlx8c507dbmh97kgij4r6kcxdi0f9nk6l1k080lcf"))))
   (cons "retained-rust-windows-targets-0.53.5"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/windows-targets/windows-targets-0.53.5.crate")
           (file-name "windows-targets-0.53.5.crate")
           (sha256
            (base32 "1wv9j2gv3l6wj3gkw5j1kr6ymb5q6dfc42yvydjhv3mqa7szjia9"))))
   (cons "retained-rust-windows-threading-0.2.1"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/windows-threading/windows-threading-0.2.1.crate")
           (file-name "windows-threading-0.2.1.crate")
           (sha256
            (base32 "0dsvsy33vxs0153z4n39sqkzx382cjjkrd46rb3z3zfak5dvsj9r"))))
   (cons "retained-rust-windows_aarch64_gnullvm-0.42.2"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/windows_aarch64_gnullvm/windows_aarch64_gnullvm-0.42.2.crate")
           (file-name "windows_aarch64_gnullvm-0.42.2.crate")
           (sha256
            (base32 "1y4q0qmvl0lvp7syxvfykafvmwal5hrjb4fmv04bqs0bawc52yjr"))))
   (cons "retained-rust-windows_aarch64_gnullvm-0.53.1"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/windows_aarch64_gnullvm/windows_aarch64_gnullvm-0.53.1.crate")
           (file-name "windows_aarch64_gnullvm-0.53.1.crate")
           (sha256
            (base32 "0lqvdm510mka9w26vmga7hbkmrw9glzc90l4gya5qbxlm1pl3n59"))))
   (cons "retained-rust-windows_aarch64_msvc-0.42.2"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/windows_aarch64_msvc/windows_aarch64_msvc-0.42.2.crate")
           (file-name "windows_aarch64_msvc-0.42.2.crate")
           (sha256
            (base32 "0hsdikjl5sa1fva5qskpwlxzpc5q9l909fpl1w6yy1hglrj8i3p0"))))
   (cons "retained-rust-windows_aarch64_msvc-0.53.1"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/windows_aarch64_msvc/windows_aarch64_msvc-0.53.1.crate")
           (file-name "windows_aarch64_msvc-0.53.1.crate")
           (sha256
            (base32 "01jh2adlwx043rji888b22whx4bm8alrk3khjpik5xn20kl85mxr"))))
   (cons "retained-rust-windows_i686_gnu-0.42.2"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/windows_i686_gnu/windows_i686_gnu-0.42.2.crate")
           (file-name "windows_i686_gnu-0.42.2.crate")
           (sha256
            (base32 "0kx866dfrby88lqs9v1vgmrkk1z6af9lhaghh5maj7d4imyr47f6"))))
   (cons "retained-rust-windows_i686_gnu-0.53.1"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/windows_i686_gnu/windows_i686_gnu-0.53.1.crate")
           (file-name "windows_i686_gnu-0.53.1.crate")
           (sha256
            (base32 "18wkcm82ldyg4figcsidzwbg1pqd49jpm98crfz0j7nqd6h6s3ln"))))
   (cons "retained-rust-windows_i686_gnullvm-0.53.1"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/windows_i686_gnullvm/windows_i686_gnullvm-0.53.1.crate")
           (file-name "windows_i686_gnullvm-0.53.1.crate")
           (sha256
            (base32 "030qaxqc4salz6l4immfb6sykc6gmhyir9wzn2w8mxj8038mjwzs"))))
   (cons "retained-rust-windows_i686_msvc-0.42.2"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/windows_i686_msvc/windows_i686_msvc-0.42.2.crate")
           (file-name "windows_i686_msvc-0.42.2.crate")
           (sha256
            (base32 "0q0h9m2aq1pygc199pa5jgc952qhcnf0zn688454i7v4xjv41n24"))))
   (cons "retained-rust-windows_i686_msvc-0.53.1"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/windows_i686_msvc/windows_i686_msvc-0.53.1.crate")
           (file-name "windows_i686_msvc-0.53.1.crate")
           (sha256
            (base32 "1hi6scw3mn2pbdl30ji5i4y8vvspb9b66l98kkz350pig58wfyhy"))))
   (cons "retained-rust-windows_x86_64_gnu-0.42.2"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/windows_x86_64_gnu/windows_x86_64_gnu-0.42.2.crate")
           (file-name "windows_x86_64_gnu-0.42.2.crate")
           (sha256
            (base32 "0dnbf2xnp3xrvy8v9mgs3var4zq9v9yh9kv79035rdgyp2w15scd"))))
   (cons "retained-rust-windows_x86_64_gnu-0.53.1"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/windows_x86_64_gnu/windows_x86_64_gnu-0.53.1.crate")
           (file-name "windows_x86_64_gnu-0.53.1.crate")
           (sha256
            (base32 "16d4yiysmfdlsrghndr97y57gh3kljkwhfdbcs05m1jasz6l4f4w"))))
   (cons "retained-rust-windows_x86_64_gnullvm-0.42.2"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/windows_x86_64_gnullvm/windows_x86_64_gnullvm-0.42.2.crate")
           (file-name "windows_x86_64_gnullvm-0.42.2.crate")
           (sha256
            (base32 "18wl9r8qbsl475j39zvawlidp1bsbinliwfymr43fibdld31pm16"))))
   (cons "retained-rust-windows_x86_64_gnullvm-0.53.1"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/windows_x86_64_gnullvm/windows_x86_64_gnullvm-0.53.1.crate")
           (file-name "windows_x86_64_gnullvm-0.53.1.crate")
           (sha256
            (base32 "1qbspgv4g3q0vygkg8rnql5c6z3caqv38japiynyivh75ng1gyhg"))))
   (cons "retained-rust-windows_x86_64_msvc-0.42.2"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/windows_x86_64_msvc/windows_x86_64_msvc-0.42.2.crate")
           (file-name "windows_x86_64_msvc-0.42.2.crate")
           (sha256
            (base32 "1w5r0q0yzx827d10dpjza2ww0j8iajqhmb54s735hhaj66imvv4s"))))
   (cons "retained-rust-windows_x86_64_msvc-0.53.1"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/windows_x86_64_msvc/windows_x86_64_msvc-0.53.1.crate")
           (file-name "windows_x86_64_msvc-0.53.1.crate")
           (sha256
            (base32 "0l6npq76vlq4ksn4bwsncpr8508mk0gmznm6wnhjg95d19gzzfyn"))))
   (cons "retained-rust-wit-bindgen-0.51.0"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/wit-bindgen/wit-bindgen-0.51.0.crate")
           (file-name "wit-bindgen-0.51.0.crate")
           (sha256
            (base32 "19fazgch8sq5cvjv3ynhhfh5d5x08jq2pkw8jfb05vbcyqcr496p"))))
   (cons "retained-rust-wit-bindgen-core-0.51.0"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/wit-bindgen-core/wit-bindgen-core-0.51.0.crate")
           (file-name "wit-bindgen-core-0.51.0.crate")
           (sha256
            (base32 "1p2jszqsqbx8k7y8nwvxg65wqzxjm048ba5phaq8r9iy9ildwqga"))))
   (cons "retained-rust-wit-bindgen-rust-0.51.0"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/wit-bindgen-rust/wit-bindgen-rust-0.51.0.crate")
           (file-name "wit-bindgen-rust-0.51.0.crate")
           (sha256
            (base32 "08bzn5fsvkb9x9wyvyx98qglknj2075xk1n7c5jxv15jykh6didp"))))
   (cons "retained-rust-wit-bindgen-rust-macro-0.51.0"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/wit-bindgen-rust-macro/wit-bindgen-rust-macro-0.51.0.crate")
           (file-name "wit-bindgen-rust-macro-0.51.0.crate")
           (sha256
            (base32 "0ymizapzv2id89igxsz2n587y2hlfypf6n8kyp68x976fzyrn3qc"))))
   (cons "retained-rust-wit-component-0.244.0"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/wit-component/wit-component-0.244.0.crate")
           (file-name "wit-component-0.244.0.crate")
           (sha256
            (base32 "1clwxgsgdns3zj2fqnrjcp8y5gazwfa1k0sy5cbk0fsmx4hflrlx"))))
   (cons "retained-rust-wit-parser-0.244.0"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/wit-parser/wit-parser-0.244.0.crate")
           (file-name "wit-parser-0.244.0.crate")
           (sha256
            (base32 "0dm7avvdxryxd5b02l0g5h6933z1cw5z0d4wynvq2cywq55srj7c"))))
   (cons "retained-rust-writeable-0.6.2"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/writeable/writeable-0.6.2.crate")
           (file-name "writeable-0.6.2.crate")
           (sha256
            (base32 "1fg08y97n6vk7l0rnjggw3xyrii6dcqg54wqaxldrlk98zdy1pcy"))))
   (cons "retained-rust-yoke-0.8.1"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/yoke/yoke-0.8.1.crate")
           (file-name "yoke-0.8.1.crate")
           (sha256
            (base32 "0m29dm0bf5iakxgma0bj6dbmc3b8qi9b1vaw9sa76kdqmz3fbmkj"))))
   (cons "retained-rust-yoke-derive-0.8.1"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/yoke-derive/yoke-derive-0.8.1.crate")
           (file-name "yoke-derive-0.8.1.crate")
           (sha256
            (base32 "0pbyja133jnng4mrhimzdq4a0y26421g734ybgz8wsgbfhl0andn"))))
   (cons "retained-rust-zerocopy-0.8.47"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/zerocopy/zerocopy-0.8.47.crate")
           (file-name "zerocopy-0.8.47.crate")
           (sha256
            (base32 "11zdl3708210fsiax93qbvw8kiadg9lnzriw26xg44g35c32mfzg"))))
   (cons "retained-rust-zerocopy-derive-0.8.47"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/zerocopy-derive/zerocopy-derive-0.8.47.crate")
           (file-name "zerocopy-derive-0.8.47.crate")
           (sha256
            (base32 "12dbrk2w8mszdq9v01ls930bi446iyk4llggxrx8whalkckcg2qf"))))
   (cons "retained-rust-zerotrie-0.2.3"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/zerotrie/zerotrie-0.2.3.crate")
           (file-name "zerotrie-0.2.3.crate")
           (sha256
            (base32 "0lbqznlqazmrwwzslw0ci7p3pqxykrbfhq29npj0gmb2amxc2n9a"))))
   (cons "retained-rust-zerovec-0.11.5"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/zerovec/zerovec-0.11.5.crate")
           (file-name "zerovec-0.11.5.crate")
           (sha256
            (base32 "00m0p47k2g9mkv505hky5xh3r6ps7v8qc0dy4pspg542jj972a3c"))))
   (cons "retained-rust-zerovec-derive-0.11.2"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/zerovec-derive/zerovec-derive-0.11.2.crate")
           (file-name "zerovec-derive-0.11.2.crate")
           (sha256
            (base32 "1wsig4h5j7a1scd5hrlnragnazjny9qjc44hancb6p6a76ay7p7a"))))
   (cons "retained-rust-zmij-1.0.21"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/zmij/zmij-1.0.21.crate")
           (file-name "zmij-1.0.21.crate")
           (sha256
            (base32 "1amb5i6gz7yjb0dnmz5y669674pqmwbj44p4yfxfv2ncgvk8x15q"))))
   (cons "retained-rust-anes-0.1.6"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/anes/anes-0.1.6.crate")
           (file-name "anes-0.1.6.crate")
           (sha256
            (base32 "16bj1ww1xkwzbckk32j2pnbn5vk6wgsl3q4p3j9551xbcarwnijb"))))
   (cons "retained-rust-arbitrary-1.4.2"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/arbitrary/arbitrary-1.4.2.crate")
           (file-name "arbitrary-1.4.2.crate")
           (sha256
            (base32 "1wcbi4x7i3lzcrkjda4810nqv03lpmvfhb0a85xrq1mbqjikdl63"))))
   (cons "retained-rust-bitvec-1.0.1"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/bitvec/bitvec-1.0.1.crate")
           (file-name "bitvec-1.0.1.crate")
           (sha256
            (base32 "173ydyj2q5vwj88k6xgjnfsshs4x9wbvjjv7sm0h36r34hn87hhv"))))
   (cons "retained-rust-cast-0.3.0"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/cast/cast-0.3.0.crate")
           (file-name "cast-0.3.0.crate")
           (sha256
            (base32 "1dbyngbyz2qkk0jn2sxil8vrz3rnpcj142y184p9l4nbl9radcip"))))
   (cons "retained-rust-cc-1.2.55"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/cc/cc-1.2.55.crate")
           (file-name "cc-1.2.55.crate")
           (sha256
            (base32 "0adx36r84c7rscv853a71nd3d5gsb1jf438gnl4syd5fah4nmcj7"))))
   (cons "retained-rust-ciborium-0.2.2"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/ciborium/ciborium-0.2.2.crate")
           (file-name "ciborium-0.2.2.crate")
           (sha256
            (base32 "03hgfw4674im1pdqblcp77m7rc8x2v828si5570ga5q9dzyrzrj2"))))
   (cons "retained-rust-ciborium-io-0.2.2"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/ciborium-io/ciborium-io-0.2.2.crate")
           (file-name "ciborium-io-0.2.2.crate")
           (sha256
            (base32 "0my7s5g24hvp1rs1zd1cxapz94inrvqpdf1rslrvxj8618gfmbq5"))))
   (cons "retained-rust-ciborium-ll-0.2.2"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/ciborium-ll/ciborium-ll-0.2.2.crate")
           (file-name "ciborium-ll-0.2.2.crate")
           (sha256
            (base32 "1n8g4j5rwkfs3rzfi6g1p7ngmz6m5yxsksryzf5k72ll7mjknrjp"))))
   (cons "retained-rust-clap-4.5.56"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/clap/clap-4.5.56.crate")
           (file-name "clap-4.5.56.crate")
           (sha256
            (base32 "03mynk7b90qcl6rv9cji84vpsgjhgc3wa96cgaai8fp361jacp57"))))
   (cons "retained-rust-clap_builder-4.5.56"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/clap_builder/clap_builder-4.5.56.crate")
           (file-name "clap_builder-4.5.56.crate")
           (sha256
            (base32 "1w1xwq9qlzbp2zxvk38wvhy73gpxwmcbi00himha0033zb3hfckr"))))
   (cons "retained-rust-clap_lex-0.7.7"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/clap_lex/clap_lex-0.7.7.crate")
           (file-name "clap_lex-0.7.7.crate")
           (sha256
            (base32 "0cibsbziyzw2ywar2yh6zllsamhwkblfly565zgi56s3q064prn3"))))
   (cons "retained-rust-codspeed-2.10.1"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/codspeed/codspeed-2.10.1.crate")
           (file-name "codspeed-2.10.1.crate")
           (sha256
            (base32 "0v3cg65nbh4m9p6vg63l5vgsjhbghaqypzpz07qw8jbwqblwrx4k"))))
   (cons "retained-rust-codspeed-criterion-compat-2.10.1"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/codspeed-criterion-compat/codspeed-criterion-compat-2.10.1.crate")
           (file-name "codspeed-criterion-compat-2.10.1.crate")
           (sha256
            (base32 "09cp974b67fvnsb2358aglaqfcbsvn0q9jiq5nssm8i81a43vhn3"))))
   (cons "retained-rust-codspeed-criterion-compat-walltime-2.10.1"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/codspeed-criterion-compat-walltime/codspeed-criterion-compat-walltime-2.10.1.crate")
           (file-name "codspeed-criterion-compat-walltime-2.10.1.crate")
           (sha256
            (base32 "1fwg5jj339gqdki24kim1a88kg7pkdlfmsb75brg8iz3cmrjy2kv"))))
   (cons "retained-rust-colored-2.2.0"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/colored/colored-2.2.0.crate")
           (file-name "colored-2.2.0.crate")
           (sha256
            (base32 "0g6s7j2qayjd7i3sivmwiawfdg8c8ldy0g2kl4vwk1yk16hjaxqi"))))
   (cons "retained-rust-criterion-plot-0.5.0"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/criterion-plot/criterion-plot-0.5.0.crate")
           (file-name "criterion-plot-0.5.0.crate")
           (sha256
            (base32 "1c866xkjqqhzg4cjvg01f8w6xc1j3j7s58rdksl52skq89iq4l3b"))))
   (cons "retained-rust-funty-2.0.0"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/funty/funty-2.0.0.crate")
           (file-name "funty-2.0.0.crate")
           (sha256
            (base32 "177w048bm0046qlzvp33ag3ghqkqw4ncpzcm5lq36gxf2lla7mg6"))))
   (cons "retained-rust-half-2.7.1"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/half/half-2.7.1.crate")
           (file-name "half-2.7.1.crate")
           (sha256
            (base32 "0jyq42xfa6sghc397mx84av7fayd4xfxr4jahsqv90lmjr5xi8kf"))))
   (cons "retained-rust-itertools-0.10.5"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/itertools/itertools-0.10.5.crate")
           (file-name "itertools-0.10.5.crate")
           (sha256
            (base32 "0ww45h7nxx5kj6z2y6chlskxd1igvs4j507anr6dzg99x1h25zdh"))))
   (cons "retained-rust-js-sys-0.3.85"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/js-sys/js-sys-0.3.85.crate")
           (file-name "js-sys-0.3.85.crate")
           (sha256
            (base32 "1csmb42fxjmzjdgc790bgw77sf1cb9ydm5rdsnh5qj4miszjx54c"))))
   (cons "retained-rust-lexical-parse-float-1.0.6"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/lexical-parse-float/lexical-parse-float-1.0.6.crate")
           (file-name "lexical-parse-float-1.0.6.crate")
           (sha256
            (base32 "0mpapd5cp4s5f1lsr46nq8d0fx5nkbwvbp1p06y51xfnzcrg5aaj"))))
   (cons "retained-rust-lexical-parse-integer-1.0.6"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/lexical-parse-integer/lexical-parse-integer-1.0.6.crate")
           (file-name "lexical-parse-integer-1.0.6.crate")
           (sha256
            (base32 "0d4v93wabi45vi759jhszrs2h6rw637grcnpdjcrrhdriygh6yls"))))
   (cons "retained-rust-lexical-util-1.0.7"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/lexical-util/lexical-util-1.0.7.crate")
           (file-name "lexical-util-1.0.7.crate")
           (sha256
            (base32 "05zdvc2wfhm7ndszhdsvcpxbk707amhsdmhvbpxi6kxidc9ds116"))))
   (cons "retained-rust-libfuzzer-sys-0.4.10"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/libfuzzer-sys/libfuzzer-sys-0.4.10.crate")
           (file-name "libfuzzer-sys-0.4.10.crate")
           (sha256
            (base32 "0124z86582vyzl8gbadqscjgf9i94jcpa9mxcpsyxjvh3w71jdsh"))))
   (cons "retained-rust-oorandom-11.1.5"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/oorandom/oorandom-11.1.5.crate")
           (file-name "oorandom-11.1.5.crate")
           (sha256
            (base32 "07mlf13z453fq01qff38big1lh83j8l6aaglf63ksqzzqxc0yyfn"))))
   (cons "retained-rust-plotters-0.3.7"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/plotters/plotters-0.3.7.crate")
           (file-name "plotters-0.3.7.crate")
           (sha256
            (base32 "0ixpy9svpmr2rkzkxvvdpysjjky4gw104d73n7pi2jbs7m06zsss"))))
   (cons "retained-rust-plotters-backend-0.3.7"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/plotters-backend/plotters-backend-0.3.7.crate")
           (file-name "plotters-backend-0.3.7.crate")
           (sha256
            (base32 "0ahpliim4hrrf7d4ispc2hwr7rzkn6d6nf7lyyrid2lm28yf2hnz"))))
   (cons "retained-rust-plotters-svg-0.3.7"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/plotters-svg/plotters-svg-0.3.7.crate")
           (file-name "plotters-svg-0.3.7.crate")
           (sha256
            (base32 "0w56sxaa2crpasa1zj0bhxzihlapqfkncggavyngg0w86anf5fji"))))
   (cons "retained-rust-pyo3-0.28.0"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/pyo3/pyo3-0.28.0.crate")
           (file-name "pyo3-0.28.0.crate")
           (sha256
            (base32 "0vgcbjnfac6d0wb22mshbxhscyzpfb9qd85392z51h2lvypwrwzw"))))
   (cons "retained-rust-pyo3-build-config-0.28.0"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/pyo3-build-config/pyo3-build-config-0.28.0.crate")
           (file-name "pyo3-build-config-0.28.0.crate")
           (sha256
            (base32 "1j0img6dgyqyqmk8vg0y4cxq1qy6fhnisai1kz2dj7y986j209wp"))))
   (cons "retained-rust-pyo3-ffi-0.28.0"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/pyo3-ffi/pyo3-ffi-0.28.0.crate")
           (file-name "pyo3-ffi-0.28.0.crate")
           (sha256
            (base32 "16w5akmk6rrmasnp0980svxj83s1nrqpb1nk03b392dbkmnlb52r"))))
   (cons "retained-rust-pyo3-macros-0.28.0"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/pyo3-macros/pyo3-macros-0.28.0.crate")
           (file-name "pyo3-macros-0.28.0.crate")
           (sha256
            (base32 "061s17qwckmkpnhv30mvqmiz7vmlj96n01w8filljg0vv349rkhi"))))
   (cons "retained-rust-pyo3-macros-backend-0.28.0"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/pyo3-macros-backend/pyo3-macros-backend-0.28.0.crate")
           (file-name "pyo3-macros-backend-0.28.0.crate")
           (sha256
            (base32 "160v5qnj6pvq4hwb8h4sihxqvn677j76b6v7h8rd4m516q0bdx7a"))))
   (cons "retained-rust-python3-dll-a-0.2.14"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/python3-dll-a/python3-dll-a-0.2.14.crate")
           (file-name "python3-dll-a-0.2.14.crate")
           (sha256
            (base32 "1n40cyv71pri995yrbbkiz95ran6fgklv2jzz6jls2z778qyz0fk"))))
   (cons "retained-rust-quote-1.0.44"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/quote/quote-1.0.44.crate")
           (file-name "quote-1.0.44.crate")
           (sha256
            (base32 "1r7c7hxl66vz3q9qizgjhy77pdrrypqgk4ghc7260xvvfb7ypci1"))))
   (cons "retained-rust-radium-0.7.0"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/radium/radium-0.7.0.crate")
           (file-name "radium-0.7.0.crate")
           (sha256
            (base32 "02cxfi3ky3c4yhyqx9axqwhyaca804ws46nn4gc1imbk94nzycyw"))))
   (cons "retained-rust-tap-1.0.1"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/tap/tap-1.0.1.crate")
           (file-name "tap-1.0.1.crate")
           (sha256
            (base32 "0sc3gl4nldqpvyhqi3bbd0l9k7fngrcl4zs47n314nqqk4bpx4sm"))))
   (cons "retained-rust-tinytemplate-1.2.1"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/tinytemplate/tinytemplate-1.2.1.crate")
           (file-name "tinytemplate-1.2.1.crate")
           (sha256
            (base32 "1g5n77cqkdh9hy75zdb01adxn45mkh9y40wdr7l68xpz35gnnkdy"))))
   (cons "retained-rust-uuid-1.20.0"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/uuid/uuid-1.20.0.crate")
           (file-name "uuid-1.20.0.crate")
           (sha256
            (base32 "0vwpi7vnwjsfcx58nfks9sgmsz4wpbsk06qlwhgxf34v265x6j7f"))))
   (cons "retained-rust-wasm-bindgen-0.2.108"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/wasm-bindgen/wasm-bindgen-0.2.108.crate")
           (file-name "wasm-bindgen-0.2.108.crate")
           (sha256
            (base32 "0rl5pn80sdhj2p2r28lp3k50a8mpppzgwzssz2f3jdqyxhq4l0k4"))))
   (cons "retained-rust-wasm-bindgen-macro-0.2.108"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/wasm-bindgen-macro/wasm-bindgen-macro-0.2.108.crate")
           (file-name "wasm-bindgen-macro-0.2.108.crate")
           (sha256
            (base32 "026nnvakp0w6j3ghpcxn31shj9wx8bv8x7nk3gkk40klkjfj72q0"))))
   (cons "retained-rust-wasm-bindgen-macro-support-0.2.108"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/wasm-bindgen-macro-support/wasm-bindgen-macro-support-0.2.108.crate")
           (file-name "wasm-bindgen-macro-support-0.2.108.crate")
           (sha256
            (base32 "0m9sj475ypgifbkvksjsqs2gy3bq96f87ychch784m4gspiblmjj"))))
   (cons "retained-rust-wasm-bindgen-shared-0.2.108"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/wasm-bindgen-shared/wasm-bindgen-shared-0.2.108.crate")
           (file-name "wasm-bindgen-shared-0.2.108.crate")
           (sha256
            (base32 "04ix7v99rvj5730553j58pqsrwpf9sqazr60y3cchx5cr60ba08z"))))
   (cons "retained-rust-web-sys-0.3.85"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/web-sys/web-sys-0.3.85.crate")
           (file-name "web-sys-0.3.85.crate")
           (sha256
            (base32 "1645c202gyw21m6kxw4ya81vrapl40hlb8m9iqhjj8fra7jk4bii"))))
   (cons "retained-rust-wyz-0.5.1"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/wyz/wyz-0.5.1.crate")
           (file-name "wyz-0.5.1.crate")
           (sha256
            (base32 "1vdrfy7i2bznnzjdl9vvrzljvs4s3qm8bnlgqwln6a941gy61wq5"))))
   (cons "retained-rust-zerocopy-0.8.37"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/zerocopy/zerocopy-0.8.37.crate")
           (file-name "zerocopy-0.8.37.crate")
           (sha256
            (base32 "1b4n76hghgg0qhphh7clbqsay3k538lkysdiqlcx6nk8y00cymkl"))))
   (cons "retained-rust-zerocopy-derive-0.8.37"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/zerocopy-derive/zerocopy-derive-0.8.37.crate")
           (file-name "zerocopy-derive-0.8.37.crate")
           (sha256
            (base32 "181pbqv1g8b9d9y84q3bsvi1jmvrbv0vr7nn35zdn591pwmp4a0k"))))
   (cons "retained-rust-zmij-1.0.19"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/zmij/zmij-1.0.19.crate")
           (file-name "zmij-1.0.19.crate")
           (sha256
            (base32 "0i9lpsfa4sgq52dnrli9z3sc2rllwawyc6jp6x38jf4hma65zw1z"))))
   (cons "retained-rust-allocator-api2-0.2.21"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/allocator-api2/allocator-api2-0.2.21.crate")
           (file-name "allocator-api2-0.2.21.crate")
           (sha256
            (base32 "08zrzs022xwndihvzdn78yqarv2b9696y67i6h78nla3ww87jgb8"))))
   (cons "retained-rust-anyhow-1.0.104"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/anyhow/anyhow-1.0.104.crate")
           (file-name "anyhow-1.0.104.crate")
           (sha256
            (base32 "0w34jjcm02p5g9kvsjr1dvpw0zs2fi7igi6nr414fkm5gz85w2ik"))))
   (cons "retained-rust-arc-swap-1.9.1"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/arc-swap/arc-swap-1.9.1.crate")
           (file-name "arc-swap-1.9.1.crate")
           (sha256
            (base32 "01xjlahcya8igdalxmda375lnlhjqwjz0cdqhy0bc1jkyzb1yfka"))))
   (cons "retained-rust-arcstr-1.2.0"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/arcstr/arcstr-1.2.0.crate")
           (file-name "arcstr-1.2.0.crate")
           (sha256
            (base32 "0vbyslhqr5fh84w5dd2hqck5y5r154p771wqddfah0bpplyqr483"))))
   (cons "retained-rust-async-lock-3.4.2"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/async-lock/async-lock-3.4.2.crate")
           (file-name "async-lock-3.4.2.crate")
           (sha256
            (base32 "04c3xrrdrfrvh9v0ajxrangpy38qi76qq268zslphnxxjqjpy3r9"))))
   (cons "retained-rust-async-stream-0.3.6"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/async-stream/async-stream-0.3.6.crate")
           (file-name "async-stream-0.3.6.crate")
           (sha256
            (base32 "0xl4zqncrdmw2g6241wgr11dxdg4h7byy6bz3l6si03qyfk72nhb"))))
   (cons "retained-rust-async-stream-impl-0.3.6"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/async-stream-impl/async-stream-impl-0.3.6.crate")
           (file-name "async-stream-impl-0.3.6.crate")
           (sha256
            (base32 "0kaplfb5axsvf1gfs2gk6c4zx6zcsns0yf3ssk7iwni7bphlvhn7"))))
   (cons "retained-rust-atomic-0.6.1"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/atomic/atomic-0.6.1.crate")
           (file-name "atomic-0.6.1.crate")
           (sha256
            (base32 "0h43ljcgbl6vk62hs6yk7zg7qn3myzvpw8k7isb9nzhkbdvvz758"))))
   (cons "retained-rust-aws-lc-rs-1.17.3"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/aws-lc-rs/aws-lc-rs-1.17.3.crate")
           (file-name "aws-lc-rs-1.17.3.crate")
           (sha256
            (base32 "1wbj1n78iqsf38xd2q93isjkb1iyaf7akm3wrji8ri6s33dbbg80"))))
   (cons "retained-rust-aws-lc-sys-0.43.0"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/aws-lc-sys/aws-lc-sys-0.43.0.crate")
           (file-name "aws-lc-sys-0.43.0.crate")
           (sha256
            (base32 "0k12q9axgpzhqj5q5ics2m302fnbr4pp4pipi9kn5zknril32423"))))
   (cons "retained-rust-axum-0.8.9"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/axum/axum-0.8.9.crate")
           (file-name "axum-0.8.9.crate")
           (sha256
            (base32 "146df5x8dhczm1sp939gr3839220wl6rxc1k65bzc450z72ridii"))))
   (cons "retained-rust-backon-1.6.0"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/backon/backon-1.6.0.crate")
           (file-name "backon-1.6.0.crate")
           (sha256
            (base32 "1vzphngmym91xh29x7px6vw1xgcv5vjzw86b9zy6ddkm329hxyyg"))))
   (cons "retained-rust-bit-set-0.8.0"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/bit-set/bit-set-0.8.0.crate")
           (file-name "bit-set-0.8.0.crate")
           (sha256
            (base32 "18riaa10s6n59n39vix0cr7l2dgwdhcpbcm97x1xbyfp1q47x008"))))
   (cons "retained-rust-bit-vec-0.8.0"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/bit-vec/bit-vec-0.8.0.crate")
           (file-name "bit-vec-0.8.0.crate")
           (sha256
            (base32 "1xxa1s2cj291r7k1whbxq840jxvmdsq9xgh7bvrxl46m80fllxjy"))))
   (cons "retained-rust-block-buffer-0.12.0"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/block-buffer/block-buffer-0.12.0.crate")
           (file-name "block-buffer-0.12.0.crate")
           (sha256
            (base32 "1glh8w49a7cj0wlkalyn9j605jzf2ss0lg8dqq5xh8cr2q451lyd"))))
   (cons "retained-rust-borrow-or-share-0.2.4"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/borrow-or-share/borrow-or-share-0.2.4.crate")
           (file-name "borrow-or-share-0.2.4.crate")
           (sha256
            (base32 "0v0nygw2hbzpbzj7lgk5fnvzxssnh1asnm98ii652x0qmm73c2yw"))))
   (cons "retained-rust-bytemuck-1.25.1"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/bytemuck/bytemuck-1.25.1.crate")
           (file-name "bytemuck-1.25.1.crate")
           (sha256
            (base32 "094lrzwibbmazpqr1vlbs8vwrsgm3ksb8g6g09sk8ri7wy5dzbnn"))))
   (cons "retained-rust-bytemuck_derive-1.11.0"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/bytemuck_derive/bytemuck_derive-1.11.0.crate")
           (file-name "bytemuck_derive-1.11.0.crate")
           (sha256
            (base32 "1r9xdwcdxw385lbflmqlcc2via7hvg7d3zk2ky5mi73bkc2r6mpn"))))
   (cons "retained-rust-cbindgen-0.29.2"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/cbindgen/cbindgen-0.29.2.crate")
           (file-name "cbindgen-0.29.2.crate")
           (sha256
            (base32 "168pl7jrz6zw7yi4hggqa78fgr8z8g7fyyjhihpw10cf583zvyxy"))))
   (cons "retained-rust-cc-1.2.60"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/cc/cc-1.2.60.crate")
           (file-name "cc-1.2.60.crate")
           (sha256
            (base32 "084a8ziprdlyrj865f3303qr0b7aaggilkl18slncss6m4yp1ia3"))))
   (cons "retained-rust-chacha20-0.10.2"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/chacha20/chacha20-0.10.2.crate")
           (file-name "chacha20-0.10.2.crate")
           (sha256
            (base32 "01hvvbgdmqkcgs2s4f12s9wa5h2gbq05rqvypv61azlwd55mxhv5"))))
   (cons "retained-rust-clap-4.6.0"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/clap/clap-4.6.0.crate")
           (file-name "clap-4.6.0.crate")
           (sha256
            (base32 "0l8k0ja5rf4hpn2g98bqv5m6lkh2q6b6likjpmm6fjw3cxdsz4xi"))))
   (cons "retained-rust-clap_builder-4.6.0"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/clap_builder/clap_builder-4.6.0.crate")
           (file-name "clap_builder-4.6.0.crate")
           (sha256
            (base32 "17q6np22yxhh5y5v53y4l31ps3hlaz45mvz2n2nicr7n3c056jki"))))
   (cons "retained-rust-clap_complete-4.6.5"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/clap_complete/clap_complete-4.6.5.crate")
           (file-name "clap_complete-4.6.5.crate")
           (sha256
            (base32 "0wnp1w338vwf20sbaps13cjx452ijw2hybw3b6g1z09mvfzsk9z0"))))
   (cons "retained-rust-clap_derive-4.6.0"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/clap_derive/clap_derive-4.6.0.crate")
           (file-name "clap_derive-4.6.0.crate")
           (sha256
            (base32 "0snapc468s7n3avr33dky4y7rmb7ha3qsp9l0k5vh6jacf5bs40i"))))
   (cons "retained-rust-clap_lex-1.1.0"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/clap_lex/clap_lex-1.1.0.crate")
           (file-name "clap_lex-1.1.0.crate")
           (sha256
            (base32 "1ycqkpygnlqnndghhcxjb44lzl0nmgsia64x9581030yifxs7m68"))))
   (cons "retained-rust-cmake-0.1.58"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/cmake/cmake-0.1.58.crate")
           (file-name "cmake-0.1.58.crate")
           (sha256
            (base32 "0y06zxw5sv1p5vvpp5rz1qwbrq7ccawrl09nqy5ahx1a5418mxy0"))))
   (cons "retained-rust-console-0.15.11"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/console/console-0.15.11.crate")
           (file-name "console-0.15.11.crate")
           (sha256
            (base32 "1n5gmsjk6isbnw6qss043377kln20lfwlmdk3vswpwpr21dwnk05"))))
   (cons "retained-rust-console-0.16.3"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/console/console-0.16.3.crate")
           (file-name "console-0.16.3.crate")
           (sha256
            (base32 "11zwz1vnfr0nx6dyjx0gjymp8864y5hxwf01ynfd2s8kapsqlknn"))))
   (cons "retained-rust-convert_case-0.6.0"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/convert_case/convert_case-0.6.0.crate")
           (file-name "convert_case-0.6.0.crate")
           (sha256
            (base32 "1jn1pq6fp3rri88zyw6jlhwwgf6qiyc08d6gjv0qypgkl862n67c"))))
   (cons "retained-rust-crc-fast-1.10.0"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/crc-fast/crc-fast-1.10.0.crate")
           (file-name "crc-fast-1.10.0.crate")
           (sha256
            (base32 "19fv025y2yb0hrvirvfqb3zkrigr56v0b2n67akpsnksx61j8nz7"))))
   (cons "retained-rust-crossbeam-0.8.4"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/crossbeam/crossbeam-0.8.4.crate")
           (file-name "crossbeam-0.8.4.crate")
           (sha256
            (base32 "1a5c7yacnk723x0hfycdbl91ks2nxhwbwy46b8y5vyy0gxzcsdqi"))))
   (cons "retained-rust-crossbeam-channel-0.5.16"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/crossbeam-channel/crossbeam-channel-0.5.16.crate")
           (file-name "crossbeam-channel-0.5.16.crate")
           (sha256
            (base32 "17k72dh5qqkh0xvqzr27wny7gl1l7fgzlvh2xxx71jmfgz1n6lyq"))))
   (cons "retained-rust-crossbeam-queue-0.3.13"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/crossbeam-queue/crossbeam-queue-0.3.13.crate")
           (file-name "crossbeam-queue-0.3.13.crate")
           (sha256
            (base32 "09ksdjzqk1iadmsfnz46f1qvy6bbqri91hnvyklqpn097gxi6gc0"))))
   (cons "retained-rust-crypto-common-0.2.1"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/crypto-common/crypto-common-0.2.1.crate")
           (file-name "crypto-common-0.2.1.crate")
           (sha256
            (base32 "041p8bs680hrg6rhicfifn19cfvybq9aya5i4i0k08d9byqpnwkp"))))
   (cons "retained-rust-ctor-0.2.9"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/ctor/ctor-0.2.9.crate")
           (file-name "ctor-0.2.9.crate")
           (sha256
            (base32 "00b5vprqi4a2cr29xhqijg800b4dwkhrr5wj2kf3s7vnambpi8ij"))))
   (cons "retained-rust-data-encoding-2.11.0"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/data-encoding/data-encoding-2.11.0.crate")
           (file-name "data-encoding-2.11.0.crate")
           (sha256
            (base32 "1j00wfmk4dzn4bnib07qlhylmd6a3kizwjz8mp00iix3vlamzbm4"))))
   (cons "retained-rust-dialoguer-0.11.0"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/dialoguer/dialoguer-0.11.0.crate")
           (file-name "dialoguer-0.11.0.crate")
           (sha256
            (base32 "1pl0744wwr97kp8qnaybzgrfwk66qakzq0i1qrxl03vpbn0cx2v5"))))
   (cons "retained-rust-digest-0.11.2"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/digest/digest-0.11.2.crate")
           (file-name "digest-0.11.2.crate")
           (sha256
            (base32 "0g0m77q7zfafm4jgy6i70wwimy9f41ywidbz9w467rh8px4xnl28"))))
   (cons "retained-rust-dyn-clone-1.0.20"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/dyn-clone/dyn-clone-1.0.20.crate")
           (file-name "dyn-clone-1.0.20.crate")
           (sha256
            (base32 "0m956cxcg8v2n8kmz6xs5zl13k2fak3zkapzfzzp7pxih6hix26h"))))
   (cons "retained-rust-email_address-0.2.9"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/email_address/email_address-0.2.9.crate")
           (file-name "email_address-0.2.9.crate")
           (sha256
            (base32 "0jf4v3npa524c7npy7w3jl0a6gng26f51a4bgzs3jqna12dz2yg0"))))
   (cons "retained-rust-erased-serde-0.4.10"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/erased-serde/erased-serde-0.4.10.crate")
           (file-name "erased-serde-0.4.10.crate")
           (sha256
            (base32 "1v1dy16ff8mck2rfqdmwdxl14phlvr8rq0i7yqzxka6ngnhdibfj"))))
   (cons "retained-rust-event-listener-5.4.2"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/event-listener/event-listener-5.4.2.crate")
           (file-name "event-listener-5.4.2.crate")
           (sha256
            (base32 "1lk9sv7r07l58jk263s18896l55mx9jv0g1rm4hj2mpi3paas8ss"))))
   (cons "retained-rust-event-listener-strategy-0.5.4"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/event-listener-strategy/event-listener-strategy-0.5.4.crate")
           (file-name "event-listener-strategy-0.5.4.crate")
           (sha256
            (base32 "14rv18av8s7n8yixg38bxp5vg2qs394rl1w052by5npzmbgz7scb"))))
   (cons "retained-rust-fancy-regex-0.18.0"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/fancy-regex/fancy-regex-0.18.0.crate")
           (file-name "fancy-regex-0.18.0.crate")
           (sha256
            (base32 "0xvjlhqf3waq02ss4d9j4qmrms5vcvavvi2i2g7xz0i01p6xmqg1"))))
   (cons "retained-rust-fastrand-2.4.1"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/fastrand/fastrand-2.4.1.crate")
           (file-name "fastrand-2.4.1.crate")
           (sha256
            (base32 "1mnqxxnxvd69ma9mczabpbbsgwlhd6l78yv3vd681453a9s247wz"))))
   (cons "retained-rust-fixedbitset-0.5.7"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/fixedbitset/fixedbitset-0.5.7.crate")
           (file-name "fixedbitset-0.5.7.crate")
           (sha256
            (base32 "16fd3v9d2cms2vddf9xhlm56sz4j0zgrk3d2h6v1l7hx760lwrqx"))))
   (cons "retained-rust-fluent-uri-0.4.1"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/fluent-uri/fluent-uri-0.4.1.crate")
           (file-name "fluent-uri-0.4.1.crate")
           (sha256
            (base32 "13ij9dqj3hnv8029293i6j7wzr8rjqh15m866mi71bjrhd6sqx5w"))))
   (cons "retained-rust-foldhash-0.2.0"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/foldhash/foldhash-0.2.0.crate")
           (file-name "foldhash-0.2.0.crate")
           (sha256
            (base32 "1nvgylb099s11xpfm1kn2wcsql080nqmnhj1l25bp3r2b35j9kkp"))))
   (cons "retained-rust-fraction-0.15.4"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/fraction/fraction-0.15.4.crate")
           (file-name "fraction-0.15.4.crate")
           (sha256
            (base32 "0wmqlp84vn9q4vmjvbhd3min6x2wyg508pzd6d9l7b1xnidh8xp0"))))
   (cons "retained-rust-fs2-0.4.3"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/fs2/fs2-0.4.3.crate")
           (file-name "fs2-0.4.3.crate")
           (sha256
            (base32 "04v2hwk7035c088f19mfl5b1lz84gnvv2hv6m935n0hmirszqr4m"))))
   (cons "retained-rust-h2-0.4.16"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/h2/h2-0.4.16.crate")
           (file-name "h2-0.4.16.crate")
           (sha256
            (base32 "09syqqhvh36b3rwyn8vjhiz597hfki1hcz3hwagb3cs1ifapmwx9"))))
   (cons "retained-rust-hashbrown-0.17.0"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/hashbrown/hashbrown-0.17.0.crate")
           (file-name "hashbrown-0.17.0.crate")
           (sha256
            (base32 "0l8gvcz80lvinb7x22h53cqbi2y1fm603y2jhhh9qwygvkb7sijg"))))
   (cons "retained-rust-hybrid-array-0.4.10"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/hybrid-array/hybrid-array-0.4.10.crate")
           (file-name "hybrid-array-0.4.10.crate")
           (sha256
            (base32 "055jvmp7rsb44z5aimj9zbam9y33nplyagik38m0xd36yy6cyi1r"))))
   (cons "retained-rust-hyper-1.9.0"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/hyper/hyper-1.9.0.crate")
           (file-name "hyper-1.9.0.crate")
           (sha256
            (base32 "1jmwbwqcaficskg76kq402gbymbnh2z4v99xwq3l5aa6n8bg16b2"))))
   (cons "retained-rust-hyper-rustls-0.27.9"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/hyper-rustls/hyper-rustls-0.27.9.crate")
           (file-name "hyper-rustls-0.27.9.crate")
           (sha256
            (base32 "03vfnsm873wsp1dk0q85nxvk7w6syp8c2m5bcdjcyfgg4786ijik"))))
   (cons "retained-rust-icu_collections-2.2.0"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/icu_collections/icu_collections-2.2.0.crate")
           (file-name "icu_collections-2.2.0.crate")
           (sha256
            (base32 "070r7xd0pynm0hnc1v2jzlbxka6wf50f81wybf9xg0y82v6x3119"))))
   (cons "retained-rust-icu_locale_core-2.2.0"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/icu_locale_core/icu_locale_core-2.2.0.crate")
           (file-name "icu_locale_core-2.2.0.crate")
           (sha256
            (base32 "0a9cmin5w1x3bg941dlmgszn33qgq428k7qiqn5did72ndi9n8cj"))))
   (cons "retained-rust-icu_normalizer-2.2.0"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/icu_normalizer/icu_normalizer-2.2.0.crate")
           (file-name "icu_normalizer-2.2.0.crate")
           (sha256
            (base32 "1d7krxr0xpc4x9635k1100a24nh0nrc59n65j6yk6gbfkplmwvn5"))))
   (cons "retained-rust-icu_normalizer_data-2.2.0"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/icu_normalizer_data/icu_normalizer_data-2.2.0.crate")
           (file-name "icu_normalizer_data-2.2.0.crate")
           (sha256
            (base32 "0f5d5d5fhhr9937m2z6z38fzh6agf14z24kwlr6lyczafypf0fys"))))
   (cons "retained-rust-icu_properties-2.2.0"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/icu_properties/icu_properties-2.2.0.crate")
           (file-name "icu_properties-2.2.0.crate")
           (sha256
            (base32 "1pkh3s837808cbwxvfagwc28cvwrz2d9h5rl02jwrhm51ryvdqxy"))))
   (cons "retained-rust-icu_properties_data-2.2.0"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/icu_properties_data/icu_properties_data-2.2.0.crate")
           (file-name "icu_properties_data-2.2.0.crate")
           (sha256
            (base32 "052awny0qwkbcbpd5jg2cd7vl5ry26pq4hz1nfsgf10c3qhbnawf"))))
   (cons "retained-rust-icu_provider-2.2.0"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/icu_provider/icu_provider-2.2.0.crate")
           (file-name "icu_provider-2.2.0.crate")
           (sha256
            (base32 "08dl8pxbwr8zsz4c5vphqb7xw0hykkznwi4rw7bk6pwb3krlr70k"))))
   (cons "retained-rust-iri-string-0.7.12"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/iri-string/iri-string-0.7.12.crate")
           (file-name "iri-string-0.7.12.crate")
           (sha256
            (base32 "082fpx6c5ghvmqpwxaf2b268m47z2ic3prajqbmi1s1qpfj5kri5"))))
   (cons "retained-rust-itertools-0.15.0"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/itertools/itertools-0.15.0.crate")
           (file-name "itertools-0.15.0.crate")
           (sha256
            (base32 "1p412hriqm4kxn7x1539vz2p5c5s1v2m36m4kis2ai4dyn9syjwb"))))
   (cons "retained-rust-jni-0.22.4"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/jni/jni-0.22.4.crate")
           (file-name "jni-0.22.4.crate")
           (sha256
            (base32 "161lza8gz071h22pgyqyx4n91ixd691z2dbb1pq2g97k5i49mzay"))))
   (cons "retained-rust-jni-macros-0.22.4"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/jni-macros/jni-macros-0.22.4.crate")
           (file-name "jni-macros-0.22.4.crate")
           (sha256
            (base32 "18v02mcn5c7mb2yw6r930xg6ynsn7hwkxv8z2kdhn3qprjn0j0d0"))))
   (cons "retained-rust-jobserver-0.1.35"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/jobserver/jobserver-0.1.35.crate")
           (file-name "jobserver-0.1.35.crate")
           (sha256
            (base32 "1crwgbb0wjph42ni4hqryjxlv4vlr0hyk81g76id9fpa56ysq00w"))))
   (cons "retained-rust-js-sys-0.3.95"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/js-sys/js-sys-0.3.95.crate")
           (file-name "js-sys-0.3.95.crate")
           (sha256
            (base32 "1jhj3kgxxgwm0cpdjiz7i2qapqr7ya9qswadmr63dhwx3lnyjr19"))))
   (cons "retained-rust-jsonschema-0.46.8"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/jsonschema/jsonschema-0.46.8.crate")
           (file-name "jsonschema-0.46.8.crate")
           (sha256
            (base32 "16zlgbdmbrzkjm6j1r7b12nk2fsfny20margdm7rjyrlv8sqbz14"))))
   (cons "retained-rust-libc-0.2.185"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/libc/libc-0.2.185.crate")
           (file-name "libc-0.2.185.crate")
           (sha256
            (base32 "13rbdaa59l3w92q7kfcxx8zbikm99zzw54h59aqvcv5wx47jrzsj"))))
   (cons "retained-rust-libloading-0.8.9"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/libloading/libloading-0.8.9.crate")
           (file-name "libloading-0.8.9.crate")
           (sha256
            (base32 "0mfwxwjwi2cf0plxcd685yxzavlslz7xirss3b9cbrzyk4hv1i6p"))))
   (cons "retained-rust-listeners-0.4.0"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/listeners/listeners-0.4.0.crate")
           (file-name "listeners-0.4.0.crate")
           (sha256
            (base32 "14z8avy093p3qgxz9drbarw55dmv9hpj1v381swa94nl8gr3h6wb"))))
   (cons "retained-rust-litemap-0.8.2"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/litemap/litemap-0.8.2.crate")
           (file-name "litemap-0.8.2.crate")
           (sha256
            (base32 "1w7628bc7wwcxc4n4s5kw0610xk06710nh2hn5kwwk2wa91z9nlj"))))
   (cons "retained-rust-md-5-0.11.0"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/md-5/md-5-0.11.0.crate")
           (file-name "md-5-0.11.0.crate")
           (sha256
            (base32 "166yqj8b11pawpys7knnn77cr618cby2iywpp0dq4dh3b4gl9dk9"))))
   (cons "retained-rust-micromap-0.3.0"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/micromap/micromap-0.3.0.crate")
           (file-name "micromap-0.3.0.crate")
           (sha256
            (base32 "0x4xsjpl9fzhchp7h83k8lbrcjrlcik4yh9wj6srafgd8qqnva62"))))
   (cons "retained-rust-mio-1.2.0"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/mio/mio-1.2.0.crate")
           (file-name "mio-1.2.0.crate")
           (sha256
            (base32 "1hanrh4fwsfkdqdaqfidz48zz1wdix23zwn3r2x78am0garfbdsh"))))
   (cons "retained-rust-multimap-0.10.1"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/multimap/multimap-0.10.1.crate")
           (file-name "multimap-0.10.1.crate")
           (sha256
            (base32 "1150lf0hjfjj4ksb8s3y0hl7a2nqzqlbh0is7vdym2iyjfrfr1qx"))))
   (cons "retained-rust-napi-2.16.17"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/napi/napi-2.16.17.crate")
           (file-name "napi-2.16.17.crate")
           (sha256
            (base32 "1ww4j4x42p5sjfj7n7073fgvrsaz1rfzvnlgqxrnfsfqw550qx2m"))))
   (cons "retained-rust-napi-derive-2.16.13"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/napi-derive/napi-derive-2.16.13.crate")
           (file-name "napi-derive-2.16.13.crate")
           (sha256
            (base32 "035bp25a2zp5vvlcrk1jqfwlwpwx9d1h2dzi6iyky8mcv22jbgkw"))))
   (cons "retained-rust-napi-derive-backend-1.0.75"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/napi-derive-backend/napi-derive-backend-1.0.75.crate")
           (file-name "napi-derive-backend-1.0.75.crate")
           (sha256
            (base32 "1gwiziraxb5byj2yr6ayi39ir4lyx3iqrnk6mv392vmpxslslf8n"))))
   (cons "retained-rust-napi-sys-2.4.0"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/napi-sys/napi-sys-2.4.0.crate")
           (file-name "napi-sys-2.4.0.crate")
           (sha256
            (base32 "18sfjqbvf2lj602rbhavvks1zkhhlaa5a0y1zqql6wrsxkl04y22"))))
   (cons "retained-rust-num-cmp-0.1.0"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/num-cmp/num-cmp-0.1.0.crate")
           (file-name "num-cmp-0.1.0.crate")
           (sha256
            (base32 "1alavi36shn32b3cwbmkncj1wal3y3cwzkm21bxy5yil5hp5ncv3"))))
   (cons "retained-rust-objc2-core-foundation-0.3.1"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/objc2-core-foundation/objc2-core-foundation-0.3.1.crate")
           (file-name "objc2-core-foundation-0.3.1.crate")
           (sha256
            (base32 "0rn19d70mwxyv74kx7aqm5in6x320vavq9v0vrm81vbg9a4w440w"))))
   (cons "retained-rust-objc2-io-kit-0.3.1"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/objc2-io-kit/objc2-io-kit-0.3.1.crate")
           (file-name "objc2-io-kit-0.3.1.crate")
           (sha256
            (base32 "02iwv7pppxvna72xwd7y5q67hrnbn5v73xikc3c1rr90c56wdhbi"))))
   (cons "retained-rust-object_store-0.14.1"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/object_store/object_store-0.14.1.crate")
           (file-name "object_store-0.14.1.crate")
           (sha256
            (base32 "0l7a9z48mqkzh5pmr99gcndbz6dh2n5wy8vnwh4h0pzs74p7jm6k"))))
   (cons "retained-rust-opentelemetry-0.32.0"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/opentelemetry/opentelemetry-0.32.0.crate")
           (file-name "opentelemetry-0.32.0.crate")
           (sha256
            (base32 "10ln14d1jgc8rvw97mblc9blzcgpg1bimim4d170b7ia4mijq55h"))))
   (cons "retained-rust-opentelemetry-http-0.32.0"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/opentelemetry-http/opentelemetry-http-0.32.0.crate")
           (file-name "opentelemetry-http-0.32.0.crate")
           (sha256
            (base32 "0ca3drvm4fx5nskl7yn42dimy3bg35ppzc85y1p27pz215fh30sn"))))
   (cons "retained-rust-opentelemetry-otlp-0.32.0"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/opentelemetry-otlp/opentelemetry-otlp-0.32.0.crate")
           (file-name "opentelemetry-otlp-0.32.0.crate")
           (sha256
            (base32 "0d9cys2flpidfxbr6h1103hjc633cax47ihnqgbj0xnicscr4rlr"))))
   (cons "retained-rust-opentelemetry-proto-0.32.0"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/opentelemetry-proto/opentelemetry-proto-0.32.0.crate")
           (file-name "opentelemetry-proto-0.32.0.crate")
           (sha256
            (base32 "0f5ny4rpnpq6q5q34b8k2q548rf31rpbxkwjqjwzfqxg3yx5imjn"))))
   (cons "retained-rust-opentelemetry-semantic-conventions-0.32.1"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/opentelemetry-semantic-conventions/opentelemetry-semantic-conventions-0.32.1.crate")
           (file-name "opentelemetry-semantic-conventions-0.32.1.crate")
           (sha256
            (base32 "0izyyi148774fndrdgcfwxx68l9y2ifn5x2mw8g6clf4lqbsq4y9"))))
   (cons "retained-rust-opentelemetry_sdk-0.32.1"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/opentelemetry_sdk/opentelemetry_sdk-0.32.1.crate")
           (file-name "opentelemetry_sdk-0.32.1.crate")
           (sha256
            (base32 "1ycl11syranrinhgn4c2hlzhyzyvpa06ryxq5mxgzmf4387ghncv"))))
   (cons "retained-rust-ordered-float-2.10.1"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/ordered-float/ordered-float-2.10.1.crate")
           (file-name "ordered-float-2.10.1.crate")
           (sha256
            (base32 "075i108hr95pr7hy4fgxivib5pky3b6b22rywya5qyd2wmkrvwb8"))))
   (cons "retained-rust-outref-0.5.2"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/outref/outref-0.5.2.crate")
           (file-name "outref-0.5.2.crate")
           (sha256
            (base32 "03pzw9aj4qskqhh0fkagy2mkgfwgj5a1m67ajlba5hw80h68100s"))))
   (cons "retained-rust-parking-2.2.1"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/parking/parking-2.2.1.crate")
           (file-name "parking-2.2.1.crate")
           (sha256
            (base32 "1fnfgmzkfpjd69v4j9x737b1k8pnn054bvzcn5dm3pkgq595d3gk"))))
   (cons "retained-rust-parking_lot-0.12.5"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/parking_lot/parking_lot-0.12.5.crate")
           (file-name "parking_lot-0.12.5.crate")
           (sha256
            (base32 "06jsqh9aqmc94j2rlm8gpccilqm6bskbd67zf6ypfc0f4m9p91ck"))))
   (cons "retained-rust-parking_lot_core-0.9.12"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/parking_lot_core/parking_lot_core-0.9.12.crate")
           (file-name "parking_lot_core-0.9.12.crate")
           (sha256
            (base32 "1hb4rggy70fwa1w9nb0svbyflzdc69h047482v2z3sx2hmcnh896"))))
   (cons "retained-rust-pem-3.0.6"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/pem/pem-3.0.6.crate")
           (file-name "pem-3.0.6.crate")
           (sha256
            (base32 "1glia9vv51wx79cysqxgdha6g1bwbbr20bfhijlk2nxw4qycac0x"))))
   (cons "retained-rust-petgraph-0.8.3"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/petgraph/petgraph-0.8.3.crate")
           (file-name "petgraph-0.8.3.crate")
           (sha256
            (base32 "0mblnaqbx1y20h5y7pz6y11hk9jjk6k87lsmn7jxaq3hm67ba0c7"))))
   (cons "retained-rust-potential_utf-0.1.5"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/potential_utf/potential_utf-0.1.5.crate")
           (file-name "potential_utf-0.1.5.crate")
           (sha256
            (base32 "0r0518fr32xbkgzqap509s3r60cr0iancsg9j1jgf37cyz7b20q1"))))
   (cons "retained-rust-prost-build-0.14.3"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/prost-build/prost-build-0.14.3.crate")
           (file-name "prost-build-0.14.3.crate")
           (sha256
            (base32 "1rrf4rs74schd38jyaxglymi66vxzzg6hki00fdq7nkf0pbkng9l"))))
   (cons "retained-rust-protoc-bin-vendored-3.2.0"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/protoc-bin-vendored/protoc-bin-vendored-3.2.0.crate")
           (file-name "protoc-bin-vendored-3.2.0.crate")
           (sha256
            (base32 "1yk7b9j5y5syk9z6rrw913x4y2h9c0v5i1l1y2snd0n96ggq3hyi"))))
   (cons "retained-rust-protoc-bin-vendored-linux-aarch_64-3.2.0"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/protoc-bin-vendored-linux-aarch_64/protoc-bin-vendored-linux-aarch_64-3.2.0.crate")
           (file-name "protoc-bin-vendored-linux-aarch_64-3.2.0.crate")
           (sha256
            (base32 "0k0sgvry35w360h77a6g2fg1jyrpwbyldrppg75f7fdm956xyl63"))))
   (cons "retained-rust-protoc-bin-vendored-linux-ppcle_64-3.2.0"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/protoc-bin-vendored-linux-ppcle_64/protoc-bin-vendored-linux-ppcle_64-3.2.0.crate")
           (file-name "protoc-bin-vendored-linux-ppcle_64-3.2.0.crate")
           (sha256
            (base32 "03244917l2klk6h26y26slzpjpgb2x804grrqssijkr4qzk66nm5"))))
   (cons "retained-rust-protoc-bin-vendored-linux-s390_64-3.2.0"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/protoc-bin-vendored-linux-s390_64/protoc-bin-vendored-linux-s390_64-3.2.0.crate")
           (file-name "protoc-bin-vendored-linux-s390_64-3.2.0.crate")
           (sha256
            (base32 "1c7k6b629n7shd76ykjabd58xvm4ck10f2ikslsyk222vdjmbfhx"))))
   (cons "retained-rust-protoc-bin-vendored-linux-x86_32-3.2.0"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/protoc-bin-vendored-linux-x86_32/protoc-bin-vendored-linux-x86_32-3.2.0.crate")
           (file-name "protoc-bin-vendored-linux-x86_32-3.2.0.crate")
           (sha256
            (base32 "1xcwvzdnrvhirnk8fjkswrjj6ap0x2mcq7fpij3bfa7f4i5pfm48"))))
   (cons "retained-rust-protoc-bin-vendored-linux-x86_64-3.2.0"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/protoc-bin-vendored-linux-x86_64/protoc-bin-vendored-linux-x86_64-3.2.0.crate")
           (file-name "protoc-bin-vendored-linux-x86_64-3.2.0.crate")
           (sha256
            (base32 "0y2xgvgl38m2zqvc619yp1phlqq39d615kk4lh7p5pw0cma0g2xk"))))
   (cons "retained-rust-protoc-bin-vendored-macos-aarch_64-3.2.0"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/protoc-bin-vendored-macos-aarch_64/protoc-bin-vendored-macos-aarch_64-3.2.0.crate")
           (file-name "protoc-bin-vendored-macos-aarch_64-3.2.0.crate")
           (sha256
            (base32 "14l03ngh1akdf2d4ld0k69h4scjxhblgx6fry58jwcff4scql9w9"))))
   (cons "retained-rust-protoc-bin-vendored-macos-x86_64-3.2.0"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/protoc-bin-vendored-macos-x86_64/protoc-bin-vendored-macos-x86_64-3.2.0.crate")
           (file-name "protoc-bin-vendored-macos-x86_64-3.2.0.crate")
           (sha256
            (base32 "0mlp55v3356l0l34hqavg7ahds2j0s7qipm4sxqr9yyclznmyx41"))))
   (cons "retained-rust-protoc-bin-vendored-win32-3.2.0"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/protoc-bin-vendored-win32/protoc-bin-vendored-win32-3.2.0.crate")
           (file-name "protoc-bin-vendored-win32-3.2.0.crate")
           (sha256
            (base32 "18wairb735zfw3g7m5sbmjdj8r9yka9ww7s97r91lhm6miv7j1lm"))))
   (cons "retained-rust-pulldown-cmark-0.13.4"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/pulldown-cmark/pulldown-cmark-0.13.4.crate")
           (file-name "pulldown-cmark-0.13.4.crate")
           (sha256
            (base32 "0kii5zdm7nvdjh7rjkjpvxd0sx1cyd21p0qijmgiq1z7m3mniw79"))))
   (cons "retained-rust-pulldown-cmark-to-cmark-22.0.0"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/pulldown-cmark-to-cmark/pulldown-cmark-to-cmark-22.0.0.crate")
           (file-name "pulldown-cmark-to-cmark-22.0.0.crate")
           (sha256
            (base32 "141fi1gc7amzh415iv56qdfll8448d03k53h99i5c0lh3gpksyah"))))
   (cons "retained-rust-pyo3-async-runtimes-0.29.0"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/pyo3-async-runtimes/pyo3-async-runtimes-0.29.0.crate")
           (file-name "pyo3-async-runtimes-0.29.0.crate")
           (sha256
            (base32 "0imh79kj89hsh5b39if1w5nk847h0ci8pqg5cnn3ysiilzd6ivxk"))))
   (cons "retained-rust-pythonize-0.29.0"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/pythonize/pythonize-0.29.0.crate")
           (file-name "pythonize-0.29.0.crate")
           (sha256
            (base32 "12gvlyg228c7d2m7h3nq6ags788j001f4k4nfjd9433f47hpdhvf"))))
   (cons "retained-rust-quinn-0.11.11"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/quinn/quinn-0.11.11.crate")
           (file-name "quinn-0.11.11.crate")
           (sha256
            (base32 "1a60yxn03zr07ll7zianby2mrs18w4frgm1c6y4x9fxn6zj426hc"))))
   (cons "retained-rust-rand-0.9.3"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/rand/rand-0.9.3.crate")
           (file-name "rand-0.9.3.crate")
           (sha256
            (base32 "0rkim3hc792p968nqm9rr7yvzp8bjcx3kqz94hhiq5r599jrbh3y"))))
   (cons "retained-rust-rcgen-0.13.2"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/rcgen/rcgen-0.13.2.crate")
           (file-name "rcgen-0.13.2.crate")
           (sha256
            (base32 "18l0rz228pvnc44bjmvq8cchhh5d2rrkk98y9lqvan9243jnkrkm"))))
   (cons "retained-rust-redis-1.2.0"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/redis/redis-1.2.0.crate")
           (file-name "redis-1.2.0.crate")
           (sha256
            (base32 "16p4sc4ibsfx7hscn0szf30bz330vlzxxqwcv23s6w48dp4r8kpl"))))
   (cons "retained-rust-redox_syscall-0.5.18"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/redox_syscall/redox_syscall-0.5.18.crate")
           (file-name "redox_syscall-0.5.18.crate")
           (sha256
            (base32 "0b9n38zsxylql36vybw18if68yc9jczxmbyzdwyhb9sifmag4azd"))))
   (cons "retained-rust-ref-cast-1.0.25"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/ref-cast/ref-cast-1.0.25.crate")
           (file-name "ref-cast-1.0.25.crate")
           (sha256
            (base32 "0zdzc34qjva9xxgs889z5iz787g81hznk12zbk4g2xkgwq530m7k"))))
   (cons "retained-rust-ref-cast-impl-1.0.25"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/ref-cast-impl/ref-cast-impl-1.0.25.crate")
           (file-name "ref-cast-impl-1.0.25.crate")
           (sha256
            (base32 "1nkhn1fklmn342z5c4mzfzlxddv3x8yhxwwk02cj06djvh36065p"))))
   (cons "retained-rust-referencing-0.46.8"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/referencing/referencing-0.46.8.crate")
           (file-name "referencing-0.46.8.crate")
           (sha256
            (base32 "03shzjj8y2fnmc61bw57hzc9md38ahrwlj5y0v8fqvxlfarwx38w"))))
   (cons "retained-rust-reqwest-0.12.28"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/reqwest/reqwest-0.12.28.crate")
           (file-name "reqwest-0.12.28.crate")
           (sha256
            (base32 "0iqidijghgqbzl3bjg5hb4zmigwa4r612bgi0yiq0c90b6jkrpgd"))))
   (cons "retained-rust-reqwest-0.13.4"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/reqwest/reqwest-0.13.4.crate")
           (file-name "reqwest-0.13.4.crate")
           (sha256
            (base32 "1hy1plns9krbh3h1dy2sdjygsfkdcnxm6pbxdi0ya9b5vq8mi711"))))
   (cons "retained-rust-rustc-hash-2.1.2"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/rustc-hash/rustc-hash-2.1.2.crate")
           (file-name "rustc-hash-2.1.2.crate")
           (sha256
            (base32 "1gjdc5bw9982cj176jvgz9rrqf9xvr1q1ddpzywf5qhs7yzhlc4l"))))
   (cons "retained-rust-rustls-0.23.40"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/rustls/rustls-0.23.40.crate")
           (file-name "rustls-0.23.40.crate")
           (sha256
            (base32 "12qnv3ag4wrw7aj8jng74kgrilpjm2b1rfcjaac8h691frccv1pg"))))
   (cons "retained-rust-rustls-pki-types-1.14.1"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/rustls-pki-types/rustls-pki-types-1.14.1.crate")
           (file-name "rustls-pki-types-1.14.1.crate")
           (sha256
            (base32 "1a9pr54y0f3qr97bxpd3ahjldq0gqdld0h799xbnwdzbwxx1k9rh"))))
   (cons "retained-rust-rustls-platform-verifier-0.7.0"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/rustls-platform-verifier/rustls-platform-verifier-0.7.0.crate")
           (file-name "rustls-platform-verifier-0.7.0.crate")
           (sha256
            (base32 "181v4d0vl53vdh2wq56vghal1zyhdgqvy4xa8r45zwz4di9y5l96"))))
   (cons "retained-rust-ryu-js-1.0.2"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/ryu-js/ryu-js-1.0.2.crate")
           (file-name "ryu-js-1.0.2.crate")
           (sha256
            (base32 "05gaq3mraijpinin02cxanpfjcic28z6f8wjnq1hkyyng0b66afx"))))
   (cons "retained-rust-schemars-0.8.22"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/schemars/schemars-0.8.22.crate")
           (file-name "schemars-0.8.22.crate")
           (sha256
            (base32 "05an9nbi18ynyxv1rjmwbg6j08j0496hd64mjggh53mwp3hjmgrz"))))
   (cons "retained-rust-schemars_derive-0.8.22"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/schemars_derive/schemars_derive-0.8.22.crate")
           (file-name "schemars_derive-0.8.22.crate")
           (sha256
            (base32 "0kakyzrp5801s4i043l4ilv96lzimnlh01pap958h66n99w6bqij"))))
   (cons "retained-rust-serde_buf-0.1.2"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/serde_buf/serde_buf-0.1.2.crate")
           (file-name "serde_buf-0.1.2.crate")
           (sha256
            (base32 "1rg402lynfgw0jbpnmx2khis0gk06qk1hcqbprhqmlgapghqv57w"))))
   (cons "retained-rust-serde_derive_internals-0.29.1"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/serde_derive_internals/serde_derive_internals-0.29.1.crate")
           (file-name "serde_derive_internals-0.29.1.crate")
           (sha256
            (base32 "04g7macx819vbnxhi52cx0nhxi56xlhrybgwybyy7fb9m4h6mlhq"))))
   (cons "retained-rust-serde_fmt-1.1.0"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/serde_fmt/serde_fmt-1.1.0.crate")
           (file-name "serde_fmt-1.1.0.crate")
           (sha256
            (base32 "1va5qd0a1k8d65wq6v9grgzj24c6y94zg913g835vfdki3r7ljbf"))))
   (cons "retained-rust-serde_json_canonicalizer-0.3.2"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/serde_json_canonicalizer/serde_json_canonicalizer-0.3.2.crate")
           (file-name "serde_json_canonicalizer-0.3.2.crate")
           (sha256
            (base32 "1wj9ar6g9zn7b2aly9cc7vyysrw1rmbm230qlnzsynbjjad32lpy"))))
   (cons "retained-rust-serde_path_to_error-0.1.20"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/serde_path_to_error/serde_path_to_error-0.1.20.crate")
           (file-name "serde_path_to_error-0.1.20.crate")
           (sha256
            (base32 "0mxls44p2ycmnxh03zpnlxxygq42w61ws7ir7r0ba6rp5s1gza8h"))))
   (cons "retained-rust-serde_spanned-1.1.1"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/serde_spanned/serde_spanned-1.1.1.crate")
           (file-name "serde_spanned-1.1.1.crate")
           (sha256
            (base32 "09jzk7i6wihn3d8i3wi4j4n98ghi93c3b8m8k64nxq0ijn3vaqk6"))))
   (cons "retained-rust-serde_yaml-0.9.34+deprecated"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/serde_yaml/serde_yaml-0.9.34+deprecated.crate")
           (file-name "serde_yaml-0.9.34+deprecated.crate")
           (sha256
            (base32 "0isba1fjyg3l6rxk156k600ilzr8fp7crv82rhal0rxz5qd1m2va"))))
   (cons "retained-rust-sha1-0.10.6"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/sha1/sha1-0.10.6.crate")
           (file-name "sha1-0.10.6.crate")
           (sha256
            (base32 "1fnnxlfg08xhkmwf2ahv634as30l1i3xhlhkvxflmasi5nd85gz3"))))
   (cons "retained-rust-sha1_smol-1.0.1"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/sha1_smol/sha1_smol-1.0.1.crate")
           (file-name "sha1_smol-1.0.1.crate")
           (sha256
            (base32 "0pbh2xjfnzgblws3hims0ib5bphv7r5rfdpizyh51vnzvnribymv"))))
   (cons "retained-rust-shell-words-1.1.1"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/shell-words/shell-words-1.1.1.crate")
           (file-name "shell-words-1.1.1.crate")
           (sha256
            (base32 "0xzd5p53xl0ndnk63r0by52rhdrh6pd37szfxszkg73zb6ffcvyw"))))
   (cons "retained-rust-simd_cesu8-1.2.0"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/simd_cesu8/simd_cesu8-1.2.0.crate")
           (file-name "simd_cesu8-1.2.0.crate")
           (sha256
            (base32 "0865mv3nmd35f1dccjcfj7dncjmmvvdij3j61z4131mz38jiw0qi"))))
   (cons "retained-rust-spdlog-internal-0.2.1"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/spdlog-internal/spdlog-internal-0.2.1.crate")
           (file-name "spdlog-internal-0.2.1.crate")
           (sha256
            (base32 "0xmjgski0kdfx1bvswx43fxn0w45dj10gfkq1n2bv4v3znx8ifbf"))))
   (cons "retained-rust-spdlog-macros-0.3.1"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/spdlog-macros/spdlog-macros-0.3.1.crate")
           (file-name "spdlog-macros-0.3.1.crate")
           (sha256
            (base32 "1ak298cc0mvqjh0bq68zrxr1hmm33v8dshr0bm8w3s3yns9kd8mr"))))
   (cons "retained-rust-spdlog-rs-0.5.3"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/spdlog-rs/spdlog-rs-0.5.3.crate")
           (file-name "spdlog-rs-0.5.3.crate")
           (sha256
            (base32 "0v8bhf5sz2ayqjrc1xldvkfry6jfnk8abyyrqn91vamwdrkfq5bl"))))
   (cons "retained-rust-spin-0.10.1"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/spin/spin-0.10.1.crate")
           (file-name "spin-0.10.1.crate")
           (sha256
            (base32 "1lvxq2sdaissp7dzij94fsbrkxl9mmh2bcw0hr1vr38kncf22fh2"))))
   (cons "retained-rust-strum-0.27.2"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/strum/strum-0.27.2.crate")
           (file-name "strum-0.27.2.crate")
           (sha256
            (base32 "1ksb9jssw4bg9kmv9nlgp2jqa4vnsa3y4q9zkppvl952q7vdc8xg"))))
   (cons "retained-rust-strum_macros-0.27.2"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/strum_macros/strum_macros-0.27.2.crate")
           (file-name "strum_macros-0.27.2.crate")
           (sha256
            (base32 "19xwikxma0yi70fxkcy1yxcv0ica8gf3jnh5gj936jza8lwcx5bn"))))
   (cons "retained-rust-sval-2.20.0"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/sval/sval-2.20.0.crate")
           (file-name "sval-2.20.0.crate")
           (sha256
            (base32 "0z9fkdj0v5pcaa52526hz5x6p7frvxivxwr59lgk15qgx6xfzfaz"))))
   (cons "retained-rust-sval_buffer-2.20.0"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/sval_buffer/sval_buffer-2.20.0.crate")
           (file-name "sval_buffer-2.20.0.crate")
           (sha256
            (base32 "16mlaacisjy0dvk2whc1zcplhrsh1dl35dfh3wx0px0axa004p7z"))))
   (cons "retained-rust-sval_dynamic-2.20.0"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/sval_dynamic/sval_dynamic-2.20.0.crate")
           (file-name "sval_dynamic-2.20.0.crate")
           (sha256
            (base32 "1rj49w84jvkw7hdxn3sbywf7kqsph0k9l0gq1h8qxxb85rzhdfar"))))
   (cons "retained-rust-sval_fmt-2.20.0"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/sval_fmt/sval_fmt-2.20.0.crate")
           (file-name "sval_fmt-2.20.0.crate")
           (sha256
            (base32 "0npd4w5idgfbv2yml8q4x92y5avdq58zbz47lm58hxdiwkqdpswn"))))
   (cons "retained-rust-sval_json-2.20.0"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/sval_json/sval_json-2.20.0.crate")
           (file-name "sval_json-2.20.0.crate")
           (sha256
            (base32 "04ialzzj44p0a9ybv1xi3vj08p6gpd7n53djf1kc39hnlagqsi0y"))))
   (cons "retained-rust-sval_nested-2.20.0"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/sval_nested/sval_nested-2.20.0.crate")
           (file-name "sval_nested-2.20.0.crate")
           (sha256
            (base32 "14dj304792m18nhixgpk3d4371myka59pvscd5659zbfqasya782"))))
   (cons "retained-rust-sval_ref-2.20.0"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/sval_ref/sval_ref-2.20.0.crate")
           (file-name "sval_ref-2.20.0.crate")
           (sha256
            (base32 "1fy14kl1r6gq45ns2j0asi7yc9cyjn6sn9749v8dwlmwr3z5zvsl"))))
   (cons "retained-rust-sval_serde-2.20.0"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/sval_serde/sval_serde-2.20.0.crate")
           (file-name "sval_serde-2.20.0.crate")
           (sha256
            (base32 "1x9r422yd78civi2xmzznha700c3d38arfgrpjggi413i8x870xr"))))
   (cons "retained-rust-sysinfo-0.38.1"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/sysinfo/sysinfo-0.38.1.crate")
           (file-name "sysinfo-0.38.1.crate")
           (sha256
            (base32 "1qsg9m668hijpzwqqm5gafs7s53jkxn1cjhcdi105jgaq84x54jp"))))
   (cons "retained-rust-tdigest-0.2.3"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/tdigest/tdigest-0.2.3.crate")
           (file-name "tdigest-0.2.3.crate")
           (sha256
            (base32 "1j7kifbpa5jgl30yql1pknr0bax8dq3b8vflqzhg1k7b11d24pf4"))))
   (cons "retained-rust-time-0.3.53"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/time/time-0.3.53.crate")
           (file-name "time-0.3.53.crate")
           (sha256
            (base32 "0l4aans0kv47y53736cjs0pnvdz91iyywrkqbrxk6cmrvknsmpqq"))))
   (cons "retained-rust-tinystr-0.8.3"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/tinystr/tinystr-0.8.3.crate")
           (file-name "tinystr-0.8.3.crate")
           (sha256
            (base32 "0vfr8x285w6zsqhna0a9jyhylwiafb2kc8pj2qaqaahw48236cn8"))))
   (cons "retained-rust-tokio-1.51.1"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/tokio/tokio-1.51.1.crate")
           (file-name "tokio-1.51.1.crate")
           (sha256
            (base32 "131vl4p3hdn8kpvgv6qv06lspfxj7yvk9avq7r6p4jysbicgjszn"))))
   (cons "retained-rust-tokio-macros-2.7.0"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/tokio-macros/tokio-macros-2.7.0.crate")
           (file-name "tokio-macros-2.7.0.crate")
           (sha256
            (base32 "15m4f37mdafs0gg36sh0rskm1i768lb7zmp8bw67kaxr3avnqniq"))))
   (cons "retained-rust-tokio-tungstenite-0.27.0"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/tokio-tungstenite/tokio-tungstenite-0.27.0.crate")
           (file-name "tokio-tungstenite-0.27.0.crate")
           (sha256
            (base32 "1h9nnwzbmxy56p54b1msbjry5gpl46qsizgwf40ipnhfffv5k6j8"))))
   (cons "retained-rust-toml-0.9.12+spec-1.1.0"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/toml/toml-0.9.12+spec-1.1.0.crate")
           (file-name "toml-0.9.12+spec-1.1.0.crate")
           (sha256
            (base32 "0qwqbrymqn88mg2yqyq3rj52z6p20448z0jxdbpjsbpwg5g894ng"))))
   (cons "retained-rust-toml_datetime-0.7.5+spec-1.1.0"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/toml_datetime/toml_datetime-0.7.5+spec-1.1.0.crate")
           (file-name "toml_datetime-0.7.5+spec-1.1.0.crate")
           (sha256
            (base32 "0iqkgvgsxmszpai53dbip7sf2igic39s4dby29dbqf1h9bnwzqcj"))))
   (cons "retained-rust-toml_edit-0.23.10+spec-1.0.0"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/toml_edit/toml_edit-0.23.10+spec-1.0.0.crate")
           (file-name "toml_edit-0.23.10+spec-1.0.0.crate")
           (sha256
            (base32 "0saj5c676j8a3sqaj9akkp09wambg8aflji4zblwwa70azvvkj44"))))
   (cons "retained-rust-toml_parser-1.1.2+spec-1.1.0"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/toml_parser/toml_parser-1.1.2+spec-1.1.0.crate")
           (file-name "toml_parser-1.1.2+spec-1.1.0.crate")
           (sha256
            (base32 "09kmzc55a0j21whm290wlf5a8b18a0qc87a1s8sncrckc6wfkax2"))))
   (cons "retained-rust-toml_writer-1.1.1+spec-1.1.0"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/toml_writer/toml_writer-1.1.1+spec-1.1.0.crate")
           (file-name "toml_writer-1.1.1+spec-1.1.0.crate")
           (sha256
            (base32 "1nwjhvvrxz8f4ck1qi4xcz2x9qhpci37nrknhxxf9sqk22dsyvbm"))))
   (cons "retained-rust-tonic-build-0.14.6"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/tonic-build/tonic-build-0.14.6.crate")
           (file-name "tonic-build-0.14.6.crate")
           (sha256
            (base32 "08h3ddqg2y08hj6fjabjqf18qhl6h0az133c5vvkqaf5ba3n33y6"))))
   (cons "retained-rust-tonic-prost-build-0.14.6"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/tonic-prost-build/tonic-prost-build-0.14.6.crate")
           (file-name "tonic-prost-build-0.14.6.crate")
           (sha256
            (base32 "09xfzp5b5264p8mw2x6sx9s396ni1r2f2z0rk667ypgpxx1mckk5"))))
   (cons "retained-rust-tonic-types-0.14.5"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/tonic-types/tonic-types-0.14.5.crate")
           (file-name "tonic-types-0.14.5.crate")
           (sha256
            (base32 "16bk1cxi2m0xgaabf98nnj7dn9j16ymkh27jq4s3shjm4a85m1ra"))))
   (cons "retained-rust-tungstenite-0.27.0"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/tungstenite/tungstenite-0.27.0.crate")
           (file-name "tungstenite-0.27.0.crate")
           (sha256
            (base32 "03gb91kpmz837sp9s2xz7qpynz4an8bjw4s195bcq7y9d3b2kp7a"))))
   (cons "retained-rust-typed-builder-0.23.2"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/typed-builder/typed-builder-0.23.2.crate")
           (file-name "typed-builder-0.23.2.crate")
           (sha256
            (base32 "1npzaxvjhwkyfjwrx6dniqygka6a1v68r10xa0149ybh3d983aii"))))
   (cons "retained-rust-typed-builder-macro-0.23.2"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/typed-builder-macro/typed-builder-macro-0.23.2.crate")
           (file-name "typed-builder-macro-0.23.2.crate")
           (sha256
            (base32 "09pvj20y47cs73lmv5byfhi1xyxw83nq50lw5rf7jinxakf04sh7"))))
   (cons "retained-rust-typeid-1.0.3"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/typeid/typeid-1.0.3.crate")
           (file-name "typeid-1.0.3.crate")
           (sha256
            (base32 "0727ypay2p6mlw72gz3yxkqayzdmjckw46sxqpaj08v0b0r64zdw"))))
   (cons "retained-rust-unicase-2.9.0"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/unicase/unicase-2.9.0.crate")
           (file-name "unicase-2.9.0.crate")
           (sha256
            (base32 "0hh1wrfd7807mfph2q67jsxqgw8hm82xg2fb8ln8cvblkwxbri6v"))))
   (cons "retained-rust-unicode-general-category-1.1.0"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/unicode-general-category/unicode-general-category-1.1.0.crate")
           (file-name "unicode-general-category-1.1.0.crate")
           (sha256
            (base32 "0zv7q4fdnlawjxd75bpxfll33sf3db09xd13sv85pblkq7fkp68b"))))
   (cons "retained-rust-unicode-segmentation-1.13.2"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/unicode-segmentation/unicode-segmentation-1.13.2.crate")
           (file-name "unicode-segmentation-1.13.2.crate")
           (sha256
            (base32 "135a26m4a0wj319gcw28j6a5aqvz00jmgwgmcs6szgxjf942facn"))))
   (cons "retained-rust-unsafe-libyaml-0.2.11"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/unsafe-libyaml/unsafe-libyaml-0.2.11.crate")
           (file-name "unsafe-libyaml-0.2.11.crate")
           (sha256
            (base32 "0qdq69ffl3v5pzx9kzxbghzn0fzn266i1xn70y88maybz9csqfk7"))))
   (cons "retained-rust-utf-8-0.7.6"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/utf-8/utf-8-0.7.6.crate")
           (file-name "utf-8-0.7.6.crate")
           (sha256
            (base32 "1a9ns3fvgird0snjkd3wbdhwd3zdpc2h5gpyybrfr6ra5pkqxk09"))))
   (cons "retained-rust-uuid-1.18.1"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/uuid/uuid-1.18.1.crate")
           (file-name "uuid-1.18.1.crate")
           (sha256
            (base32 "18kh01qmfayn4psap52x8xdjkzw2q8bcbpnhhxjs05dr22mbi1rg"))))
   (cons "retained-rust-uuid-simd-0.8.0"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/uuid-simd/uuid-simd-0.8.0.crate")
           (file-name "uuid-simd-0.8.0.crate")
           (sha256
            (base32 "1n0b40m988h52xj03dkcp4plrzvz56r7xha1d681jrjg5ci85c13"))))
   (cons "retained-rust-value-bag-1.13.0"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/value-bag/value-bag-1.13.0.crate")
           (file-name "value-bag-1.13.0.crate")
           (sha256
            (base32 "1i5mfksrsinkv7b9nkcs2r3p1czw3l512c2a6mp66h6jn4gfrm2x"))))
   (cons "retained-rust-value-bag-serde1-1.13.0"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/value-bag-serde1/value-bag-serde1-1.13.0.crate")
           (file-name "value-bag-serde1-1.13.0.crate")
           (sha256
            (base32 "13g8apj5krrimhycpy8xmqsj8arzv395db9d3s587kz9gkyl93ia"))))
   (cons "retained-rust-value-bag-sval2-1.13.0"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/value-bag-sval2/value-bag-sval2-1.13.0.crate")
           (file-name "value-bag-sval2-1.13.0.crate")
           (sha256
            (base32 "038kbarn4dgxxpl5a5cr2gjfw9h6xm21z9fpm038nybvp02ig7rz"))))
   (cons "retained-rust-vsimd-0.8.0"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/vsimd/vsimd-0.8.0.crate")
           (file-name "vsimd-0.8.0.crate")
           (sha256
            (base32 "0r4wn54jxb12r0x023r5yxcrqk785akmbddqkcafz9fm03584c2w"))))
   (cons "retained-rust-wasm-bindgen-0.2.118"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/wasm-bindgen/wasm-bindgen-0.2.118.crate")
           (file-name "wasm-bindgen-0.2.118.crate")
           (sha256
            (base32 "129s5r14fx4v4xrzpx2c6l860nkxpl48j50y7kl6j16bpah3iy8b"))))
   (cons "retained-rust-wasm-bindgen-futures-0.4.68"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/wasm-bindgen-futures/wasm-bindgen-futures-0.4.68.crate")
           (file-name "wasm-bindgen-futures-0.4.68.crate")
           (sha256
            (base32 "1y7bq5d9fk7s9xaayx38bgs9ns35na0kpb5zw19944zvya1x6wgk"))))
   (cons "retained-rust-wasm-bindgen-macro-0.2.118"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/wasm-bindgen-macro/wasm-bindgen-macro-0.2.118.crate")
           (file-name "wasm-bindgen-macro-0.2.118.crate")
           (sha256
            (base32 "1v98r8vs17cj8918qsg0xx4nlg4nxk1g0jd4nwnyrh1687w29zzf"))))
   (cons "retained-rust-wasm-bindgen-macro-support-0.2.118"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/wasm-bindgen-macro-support/wasm-bindgen-macro-support-0.2.118.crate")
           (file-name "wasm-bindgen-macro-support-0.2.118.crate")
           (sha256
            (base32 "0169jr0q469hfx5zqxfyywf2h2f4aj17vn4zly02nfwqmxghc24x"))))
   (cons "retained-rust-wasm-bindgen-shared-0.2.118"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/wasm-bindgen-shared/wasm-bindgen-shared-0.2.118.crate")
           (file-name "wasm-bindgen-shared-0.2.118.crate")
           (sha256
            (base32 "0ag1vvdzi4334jlzilsy14y3nyzwddf1ndn62fyhf6bg62g4vl2z"))))
   (cons "retained-rust-web-sys-0.3.95"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/web-sys/web-sys-0.3.95.crate")
           (file-name "web-sys-0.3.95.crate")
           (sha256
            (base32 "0zfr2jy5bpkkggl88i43yy37p538hg20i56kwn421yj9g6qznbag"))))
   (cons "retained-rust-webpki-root-certs-1.0.9"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/webpki-root-certs/webpki-root-certs-1.0.9.crate")
           (file-name "webpki-root-certs-1.0.9.crate")
           (sha256
            (base32 "16qw59hxn1lln1615kb9rjy16pfxd1x8m9f9w6vwv36c5am58rdr"))))
   (cons "retained-rust-winnow-0.7.15"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/winnow/winnow-0.7.15.crate")
           (file-name "winnow-0.7.15.crate")
           (sha256
            (base32 "0i9rkl2rqpbnnxlgs20gmkj3nd0b2k8q55mjmpc2ybb84xwxjyfz"))))
   (cons "retained-rust-winnow-1.0.1"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/winnow/winnow-1.0.1.crate")
           (file-name "winnow-1.0.1.crate")
           (sha256
            (base32 "1dbji1bwviy08pl74f2qw2m4w9hc4p3vyl3lfj05jdydy59w1nh9"))))
   (cons "retained-rust-writeable-0.6.3"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/writeable/writeable-0.6.3.crate")
           (file-name "writeable-0.6.3.crate")
           (sha256
            (base32 "1i54d13h9bpap2hf13xcry1s4lxh7ap3923g8f3c0grd7c9fbyhz"))))
   (cons "retained-rust-xxhash-rust-0.8.15"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/xxhash-rust/xxhash-rust-0.8.15.crate")
           (file-name "xxhash-rust-0.8.15.crate")
           (sha256
            (base32 "1lrmffpn45d967afw7f1p300rsx7ill66irrskxpcm1p41a0rlpx"))))
   (cons "retained-rust-yasna-0.5.2"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/yasna/yasna-0.5.2.crate")
           (file-name "yasna-0.5.2.crate")
           (sha256
            (base32 "1ka4ixrplnrfqyl1kymdj8cwpdp2k0kdr73b57hilcn1kiab6yz1"))))
   (cons "retained-rust-yoke-0.8.2"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/yoke/yoke-0.8.2.crate")
           (file-name "yoke-0.8.2.crate")
           (sha256
            (base32 "1jprcs7a98a5whvfs6r3jvfh1nnfp6zyijl7y4ywmn88lzywbs5b"))))
   (cons "retained-rust-yoke-derive-0.8.2"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/yoke-derive/yoke-derive-0.8.2.crate")
           (file-name "yoke-derive-0.8.2.crate")
           (sha256
            (base32 "13l5y5sz4lqm7rmyakjbh6vwgikxiql51xfff9hq2j485hk4r16y"))))
   (cons "retained-rust-zerocopy-0.8.48"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/zerocopy/zerocopy-0.8.48.crate")
           (file-name "zerocopy-0.8.48.crate")
           (sha256
            (base32 "1sb8plax8jbrsng1jdval7bdhk7hhrx40dz3hwh074k6knzkgm7f"))))
   (cons "retained-rust-zerocopy-derive-0.8.48"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/zerocopy-derive/zerocopy-derive-0.8.48.crate")
           (file-name "zerocopy-derive-0.8.48.crate")
           (sha256
            (base32 "1m5s0g92cxggqc74j83k1priz24k3z93sj5gadppd20p9c4cvqvh"))))
   (cons "retained-rust-zerofrom-0.1.7"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/zerofrom/zerofrom-0.1.7.crate")
           (file-name "zerofrom-0.1.7.crate")
           (sha256
            (base32 "1py40in4rirc9q8w36q67pld0zk8ssg024xhh0cncxgal7ra3yk9"))))
   (cons "retained-rust-zerofrom-derive-0.1.7"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/zerofrom-derive/zerofrom-derive-0.1.7.crate")
           (file-name "zerofrom-derive-0.1.7.crate")
           (sha256
            (base32 "18c4wsnznhdxx6m80piil1lbyszdiwsshgjrybqcm4b6qic22lqi"))))
   (cons "retained-rust-zerotrie-0.2.4"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/zerotrie/zerotrie-0.2.4.crate")
           (file-name "zerotrie-0.2.4.crate")
           (sha256
            (base32 "1gr0pkcn3qsr6in6iixqyp0vbzwf2j1jzyvh7yl2yydh3p9m548g"))))
   (cons "retained-rust-zerovec-0.11.6"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/zerovec/zerovec-0.11.6.crate")
           (file-name "zerovec-0.11.6.crate")
           (sha256
            (base32 "0fdjsy6b31q9i0d73sl7xjd12xadbwi45lkpfgqnmasrqg5i3ych"))))
   (cons "retained-rust-zerovec-derive-0.11.3"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/zerovec-derive/zerovec-derive-0.11.3.crate")
           (file-name "zerovec-derive-0.11.3.crate")
           (sha256
            (base32 "0m85qj92mmfvhjra6ziqky5b1p4kcmp5069k7kfadp5hr8jw8pb2"))))
   (cons "retained-rust-zstd-0.13.3"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/zstd/zstd-0.13.3.crate")
           (file-name "zstd-0.13.3.crate")
           (sha256
            (base32 "12n0h4w9l526li7jl972rxpyf012jw3nwmji2qbjghv9ll8y67p9"))))
   (cons "retained-rust-zstd-safe-7.2.4"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/zstd-safe/zstd-safe-7.2.4.crate")
           (file-name "zstd-safe-7.2.4.crate")
           (sha256
            (base32 "179vxmkzhpz6cq6mfzvgwc99bpgllkr6lwxq7ylh5dmby3aw8jcg"))))
   (cons "retained-rust-zstd-sys-2.0.16+zstd.1.5.7"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/zstd-sys/zstd-sys-2.0.16+zstd.1.5.7.crate")
           (file-name "zstd-sys-2.0.16+zstd.1.5.7.crate")
           (sha256
            (base32 "0j1pd2iaqpvaxlgqmmijj68wma7xwdv9grrr63j873yw5ay9xqci"))))
   (cons "retained-rust-autocfg-1.3.0"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/autocfg/autocfg-1.3.0.crate")
           (file-name "autocfg-1.3.0.crate")
           (sha256
            (base32 "1c3njkfzpil03k92q0mij5y1pkhhfr4j3bf0h53bgl2vs85lsjqc"))))
   (cons "retained-rust-cc-1.0.101"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/cc/cc-1.0.101.crate")
           (file-name "cc-1.0.101.crate")
           (sha256
            (base32 "0bap96rkhgbvvglr938a437ks68w9v977z7aqxkmbm0nwmr7jdmc"))))
   (cons "retained-rust-cfg-if-1.0.0"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/cfg-if/cfg-if-1.0.0.crate")
           (file-name "cfg-if-1.0.0.crate")
           (sha256
            (base32 "1za0vb97n4brpzpv8lsbnzmq5r8f2b0cpqqr0sy8h5bn751xxwds"))))
   (cons "retained-rust-enum_dispatch-0.3.13"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/enum_dispatch/enum_dispatch-0.3.13.crate")
           (file-name "enum_dispatch-0.3.13.crate")
           (sha256
            (base32 "1kby2jz173ggg7wk41vjsskmkdyx7749ll8lhqhv6mb5qqmww65a"))))
   (cons "retained-rust-hex-0.4.3"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/hex/hex-0.4.3.crate")
           (file-name "hex-0.4.3.crate")
           (sha256
            (base32 "0w1a4davm1lgzpamwnba907aysmlrnygbqmfis2mqjx5m552a93z"))))
   (cons "retained-rust-icu_collections-1.5.0"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/icu_collections/icu_collections-1.5.0.crate")
           (file-name "icu_collections-1.5.0.crate")
           (sha256
            (base32 "09j5kskirl59mvqc8kabhy7005yyy7dp88jw9f6f3gkf419a8byv"))))
   (cons "retained-rust-icu_locid-1.5.0"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/icu_locid/icu_locid-1.5.0.crate")
           (file-name "icu_locid-1.5.0.crate")
           (sha256
            (base32 "0dznvd1c5b02iilqm044q4hvar0sqibq1z46prqwjzwif61vpb0k"))))
   (cons "retained-rust-icu_locid_transform-1.5.0"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/icu_locid_transform/icu_locid_transform-1.5.0.crate")
           (file-name "icu_locid_transform-1.5.0.crate")
           (sha256
            (base32 "0kmmi1kmj9yph6mdgkc7v3wz6995v7ly3n80vbg0zr78bp1iml81"))))
   (cons "retained-rust-icu_locid_transform_data-1.5.0"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/icu_locid_transform_data/icu_locid_transform_data-1.5.0.crate")
           (file-name "icu_locid_transform_data-1.5.0.crate")
           (sha256
            (base32 "0vkgjixm0wzp2n3v5mw4j89ly05bg3lx96jpdggbwlpqi0rzzj7x"))))
   (cons "retained-rust-icu_normalizer-1.5.0"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/icu_normalizer/icu_normalizer-1.5.0.crate")
           (file-name "icu_normalizer-1.5.0.crate")
           (sha256
            (base32 "0kx8qryp8ma8fw1vijbgbnf7zz9f2j4d14rw36fmjs7cl86kxkhr"))))
   (cons "retained-rust-icu_normalizer_data-1.5.0"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/icu_normalizer_data/icu_normalizer_data-1.5.0.crate")
           (file-name "icu_normalizer_data-1.5.0.crate")
           (sha256
            (base32 "05lmk0zf0q7nzjnj5kbmsigj3qgr0rwicnn5pqi9n7krmbvzpjpq"))))
   (cons "retained-rust-icu_properties-1.5.1"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/icu_properties/icu_properties-1.5.1.crate")
           (file-name "icu_properties-1.5.1.crate")
           (sha256
            (base32 "1xgf584rx10xc1p7zjr78k0n4zn3g23rrg6v2ln31ingcq3h5mlk"))))
   (cons "retained-rust-icu_properties_data-1.5.0"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/icu_properties_data/icu_properties_data-1.5.0.crate")
           (file-name "icu_properties_data-1.5.0.crate")
           (sha256
            (base32 "0scms7pd5a7yxx9hfl167f5qdf44as6r3bd8myhlngnxqgxyza37"))))
   (cons "retained-rust-icu_provider-1.5.0"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/icu_provider/icu_provider-1.5.0.crate")
           (file-name "icu_provider-1.5.0.crate")
           (sha256
            (base32 "1nb8vvgw8dv2inqklvk05fs0qxzkw8xrg2n9vgid6y7gm3423m3f"))))
   (cons "retained-rust-icu_provider_macros-1.5.0"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/icu_provider_macros/icu_provider_macros-1.5.0.crate")
           (file-name "icu_provider_macros-1.5.0.crate")
           (sha256
            (base32 "1mjs0w7fcm2lcqmbakhninzrjwqs485lkps4hz0cv3k36y9rxj0y"))))
   (cons "retained-rust-idna_adapter-1.2.0"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/idna_adapter/idna_adapter-1.2.0.crate")
           (file-name "idna_adapter-1.2.0.crate")
           (sha256
            (base32 "0wggnkiivaj5lw0g0384ql2d7zk4ppkn3b1ry4n0ncjpr7qivjns"))))
   (cons "retained-rust-itoa-1.0.11"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/itoa/itoa-1.0.11.crate")
           (file-name "itoa-1.0.11.crate")
           (sha256
            (base32 "0nv9cqjwzr3q58qz84dcz63ggc54yhf1yqar1m858m1kfd4g3wa9"))))
   (cons "retained-rust-jiter-0.14.0"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/jiter/jiter-0.14.0.crate")
           (file-name "jiter-0.14.0.crate")
           (sha256
            (base32 "079irqyz9282vmw6amc6mahm561xsabah7gx16nz8djbz39vbwxn"))))
   (cons "retained-rust-litemap-0.7.3"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/litemap/litemap-0.7.3.crate")
           (file-name "litemap-0.7.3.crate")
           (sha256
            (base32 "0157lf44c3s2piqiwpppnynzzpv1rxyddl2z9l089hpwsjwb0g34"))))
   (cons "retained-rust-lru-0.16.3"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/lru/lru-0.16.3.crate")
           (file-name "lru-0.16.3.crate")
           (sha256
            (base32 "14z5yxcp3f63lgw8yxr486g9yz7cfqbmkadfwgw36vy0jbslgp51"))))
   (cons "retained-rust-memchr-2.7.4"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/memchr/memchr-2.7.4.crate")
           (file-name "memchr-2.7.4.crate")
           (sha256
            (base32 "18z32bhxrax0fnjikv475z7ii718hq457qwmaryixfxsl2qrmjkq"))))
   (cons "retained-rust-portable-atomic-1.6.0"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/portable-atomic/portable-atomic-1.6.0.crate")
           (file-name "portable-atomic-1.6.0.crate")
           (sha256
            (base32 "1h77x9qx7pns0d66vdrmdbmwpi7586h7ysnkdnhrn5mwi2cyyw3i"))))
   (cons "retained-rust-proc-macro2-1.0.86"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/proc-macro2/proc-macro2-1.0.86.crate")
           (file-name "proc-macro2-1.0.86.crate")
           (sha256
            (base32 "0xrv22p8lqlfdf1w0pj4si8n2ws4aw0kilmziwf0vpv5ys6rwway"))))
   (cons "retained-rust-pyo3-0.28.3"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/pyo3/pyo3-0.28.3.crate")
           (file-name "pyo3-0.28.3.crate")
           (sha256
            (base32 "04hwqcrfx9w3f67pnhjcg28y0iq1srpwv0drgwbd23mmlcw8xzci"))))
   (cons "retained-rust-pyo3-build-config-0.28.3"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/pyo3-build-config/pyo3-build-config-0.28.3.crate")
           (file-name "pyo3-build-config-0.28.3.crate")
           (sha256
            (base32 "07k16mnxn220x4aw0axzcss4mn4gckhknf7qlyyck67bzpfyfs73"))))
   (cons "retained-rust-pyo3-ffi-0.28.3"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/pyo3-ffi/pyo3-ffi-0.28.3.crate")
           (file-name "pyo3-ffi-0.28.3.crate")
           (sha256
            (base32 "07k5bxh8h2ax3v6gmb43x09wsgm003lar7pnyz57q7qbz05f2abz"))))
   (cons "retained-rust-pyo3-macros-0.28.3"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/pyo3-macros/pyo3-macros-0.28.3.crate")
           (file-name "pyo3-macros-0.28.3.crate")
           (sha256
            (base32 "04wqy9knmxkf2m12dfwbj4817p959chxhzgwsabmki27zw754vnz"))))
   (cons "retained-rust-pyo3-macros-backend-0.28.3"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/pyo3-macros-backend/pyo3-macros-backend-0.28.3.crate")
           (file-name "pyo3-macros-backend-0.28.3.crate")
           (sha256
            (base32 "1jrsh65i0vwinp5k6blbvypv8idgg0h853rkqa0qywrmv0cc5kf4"))))
   (cons "retained-rust-r-efi-5.2.0"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/r-efi/r-efi-5.2.0.crate")
           (file-name "r-efi-5.2.0.crate")
           (sha256
            (base32 "1ig93jvpqyi87nc5kb6dri49p56q7r7qxrn8kfizmqkfj5nmyxkl"))))
   (cons "retained-rust-rustversion-1.0.17"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/rustversion/rustversion-1.0.17.crate")
           (file-name "rustversion-1.0.17.crate")
           (sha256
            (base32 "1mm3fckyvb0l2209in1n2k05sws5d9mpkszbnwhq3pkq8apjhpcm"))))
   (cons "retained-rust-speedate-0.17.0"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/speedate/speedate-0.17.0.crate")
           (file-name "speedate-0.17.0.crate")
           (sha256
            (base32 "03h6dl2x5s22817jl41nps9b1v2hxpjvgplll3r17qmmf306k85b"))))
   (cons "retained-rust-syn-2.0.82"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/syn/syn-2.0.82.crate")
           (file-name "syn-2.0.82.crate")
           (sha256
            (base32 "08g0bgizm4j2gwl05r3yjm3gxvx8a9dvkvd84fa03z4aga1hym43"))))
   (cons "retained-rust-synstructure-0.13.1"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/synstructure/synstructure-0.13.1.crate")
           (file-name "synstructure-0.13.1.crate")
           (sha256
            (base32 "0wc9f002ia2zqcbj0q2id5x6n7g1zjqba7qkg2mr0qvvmdk7dby8"))))
   (cons "retained-rust-tinystr-0.7.6"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/tinystr/tinystr-0.7.6.crate")
           (file-name "tinystr-0.7.6.crate")
           (sha256
            (base32 "0bxqaw7z8r2kzngxlzlgvld1r6jbnwyylyvyjbv1q71rvgaga5wi"))))
   (cons "retained-rust-unicode-ident-1.0.12"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/unicode-ident/unicode-ident-1.0.12.crate")
           (file-name "unicode-ident-1.0.12.crate")
           (sha256
            (base32 "0jzf1znfpb2gx8nr8mvmyqs1crnv79l57nxnbiszc7xf7ynbjm1k"))))
   (cons "retained-rust-utf16_iter-1.0.5"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/utf16_iter/utf16_iter-1.0.5.crate")
           (file-name "utf16_iter-1.0.5.crate")
           (sha256
            (base32 "0ik2krdr73hfgsdzw0218fn35fa09dg2hvbi1xp3bmdfrp9js8y8"))))
   (cons "retained-rust-uuid-1.23.0"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/uuid/uuid-1.23.0.crate")
           (file-name "uuid-1.23.0.crate")
           (sha256
            (base32 "1nbrzkdhwr4clshsks7flc2jq6lavjrsx65hyn63c9dd5vsbdj2s"))))
   (cons "retained-rust-write16-1.0.0"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/write16/write16-1.0.0.crate")
           (file-name "write16-1.0.0.crate")
           (sha256
            (base32 "0dnryvrrbrnl7vvf5vb1zkmwldhjkf2n5znliviam7bm4900z2fi"))))
   (cons "retained-rust-writeable-0.5.5"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/writeable/writeable-0.5.5.crate")
           (file-name "writeable-0.5.5.crate")
           (sha256
            (base32 "0lawr6y0bwqfyayf3z8zmqlhpnzhdx0ahs54isacbhyjwa7g778y"))))
   (cons "retained-rust-yoke-0.7.4"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/yoke/yoke-0.7.4.crate")
           (file-name "yoke-0.7.4.crate")
           (sha256
            (base32 "198c4jkh6i3hxijia7mfa4cpnxg1iqym9bz364697c3rn0a16nvc"))))
   (cons "retained-rust-yoke-derive-0.7.4"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/yoke-derive/yoke-derive-0.7.4.crate")
           (file-name "yoke-derive-0.7.4.crate")
           (sha256
            (base32 "15cvhkci2mchfffx3fmva84fpmp34dsmnbzibwfnzjqq3ds33k18"))))
   (cons "retained-rust-zerocopy-0.8.25"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/zerocopy/zerocopy-0.8.25.crate")
           (file-name "zerocopy-0.8.25.crate")
           (sha256
            (base32 "1jx07cd3b3456c9al9zjqqdzpf1abb0vf6z0fj8xnb93hfajsw51"))))
   (cons "retained-rust-zerocopy-derive-0.8.25"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/zerocopy-derive/zerocopy-derive-0.8.25.crate")
           (file-name "zerocopy-derive-0.8.25.crate")
           (sha256
            (base32 "1vsmpq0hp61xpqj9yk8b5jihkqkff05q1wv3l2568mhifl6y59i8"))))
   (cons "retained-rust-zerofrom-0.1.4"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/zerofrom/zerofrom-0.1.4.crate")
           (file-name "zerofrom-0.1.4.crate")
           (sha256
            (base32 "0mdbjd7vmbix2ynxbrbrrli47a5yrpfx05hi99wf1l4pwwf13v4i"))))
   (cons "retained-rust-zerofrom-derive-0.1.4"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/zerofrom-derive/zerofrom-derive-0.1.4.crate")
           (file-name "zerofrom-derive-0.1.4.crate")
           (sha256
            (base32 "19b31rrs2ry1lrq5mpdqjzgg65va51fgvwghxnf6da3ycfiv99qf"))))
   (cons "retained-rust-zerovec-0.10.4"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/zerovec/zerovec-0.10.4.crate")
           (file-name "zerovec-0.10.4.crate")
           (sha256
            (base32 "0yghix7n3fjfdppwghknzvx9v8cf826h2qal5nqvy8yzg4yqjaxa"))))
   (cons "retained-rust-zerovec-derive-0.10.3"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/zerovec-derive/zerovec-derive-0.10.3.crate")
           (file-name "zerovec-derive-0.10.3.crate")
           (sha256
            (base32 "1ik322dys6wnap5d3gcsn09azmssq466xryn5czfm13mn7gsdbvf"))))
   (cons "retained-rust-zmij-1.0.6"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/zmij/zmij-1.0.6.crate")
           (file-name "zmij-1.0.6.crate")
           (sha256
            (base32 "0pvm2w67mkl07wx9dlbsn144zm8rqv7dn76c7cndc83hdwbn1h5a"))))
   (cons "retained-rust-archery-1.2.2"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/archery/archery-1.2.2.crate")
           (file-name "archery-1.2.2.crate")
           (sha256
            (base32 "07a4wn09ad1q7qi1bfdv03hl4668jaxm63rd6jxqgfzykpwsbq3h"))))
   (cons "retained-rust-pyo3-0.27.2"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/pyo3/pyo3-0.27.2.crate")
           (file-name "pyo3-0.27.2.crate")
           (sha256
            (base32 "0zfqwq1nnszqfcxv0374dd9fjsdysq2lzs0ghald58fizi3w0lxb"))))
   (cons "retained-rust-pyo3-build-config-0.27.2"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/pyo3-build-config/pyo3-build-config-0.27.2.crate")
           (file-name "pyo3-build-config-0.27.2.crate")
           (sha256
            (base32 "19hy4vlkpfxkl0a4520lc7n9v29d5j8nvlky92s451ny0wqr6mdl"))))
   (cons "retained-rust-pyo3-ffi-0.27.2"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/pyo3-ffi/pyo3-ffi-0.27.2.crate")
           (file-name "pyo3-ffi-0.27.2.crate")
           (sha256
            (base32 "12d0faw2kmgazv8i2k9wyv7ybsapxnd2150m4aqm3xnxzb5wk18w"))))
   (cons "retained-rust-pyo3-macros-0.27.2"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/pyo3-macros/pyo3-macros-0.27.2.crate")
           (file-name "pyo3-macros-0.27.2.crate")
           (sha256
            (base32 "00iv182px80k6ghm4nmbqyadzj155p5d5d3zj5fi524qpz4i0nqa"))))
   (cons "retained-rust-pyo3-macros-backend-0.27.2"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/pyo3-macros-backend/pyo3-macros-backend-0.27.2.crate")
           (file-name "pyo3-macros-backend-0.27.2.crate")
           (sha256
            (base32 "1ya05hs8cylhf7612jicrhvzpd6gq3a72n3z699nx0qlsch1gd83"))))
   (cons "retained-rust-rpds-1.2.0"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/rpds/rpds-1.2.0.crate")
           (file-name "rpds-1.2.0.crate")
           (sha256
            (base32 "0d7vpyignq837rh9wgcrq53xplsg5b85a3bcbq0x7m0rx22z8xcy"))))
   (cons "retained-rust-triomphe-0.1.15"
         (origin
           (method url-fetch)
           (uri "https://static.crates.io/crates/triomphe/triomphe-0.1.15.crate")
           (file-name "triomphe-0.1.15.crate")
           (sha256
            (base32 "0fazg0zgq2zbjx50vkwg1zxr8nxc9skqj9rpsqcpak4jiymcasfx"))))
   (cons "retained-rust-openssl-4.0.1"
         (origin
           (method url-fetch)
           (uri "https://github.com/openssl/openssl/releases/download/openssl-4.0.1/openssl-4.0.1.tar.gz")
           (file-name "openssl-4.0.1.tar.gz")
           (sha256
            (base32 "02fx6xzny7psb960hffwgjwgyvakrp4f5b4ly3hmjjzasshg7crd"))))
   (cons "ctranslate2-simd-utils-0.2.5"
         (origin
           (method url-fetch)
           (uri "https://codeload.github.com/JishinMaster/simd_utils/tar.gz/4e5fa01a889f0d5f7f1ee4b441df055892c2c620")
           (file-name "simd_utils-4e5fa01a889f0d5f7f1ee4b441df055892c2c620.tar.gz")
           (sha256
            (base32 "1zpf6c6w40v8hsfbrzl1ax7l7qd3h9n5bqz54xa01wy9wl545r99"))))
   (cons "sherpa-onnx-core-ort-abseil_cpp"
         (origin
           (method url-fetch)
           (uri "https://github.com/abseil/abseil-cpp/archive/refs/tags/20250814.0.zip")
           (file-name "20250814.0.zip")
           (sha256
            (base32 "1zys4v00855nzl88m5yr45cfa8la65n5vk2v6vgm7jyqh9kczgdj"))))
   (cons "sherpa-onnx-core-ort-cxxopts"
         (origin
           (method url-fetch)
           (uri "https://github.com/jarro2783/cxxopts/archive/3c73d91c0b04e2b59462f0a741be8c07024c1bc0.zip")
           (file-name "3c73d91c0b04e2b59462f0a741be8c07024c1bc0.zip")
           (sha256
            (base32 "0zlr1xgf0qaslxrjziqgachcsiznk9756bjvjw50wk1d6w9g1dap"))))
   (cons "sherpa-onnx-core-ort-date"
         (origin
           (method url-fetch)
           (uri "https://github.com/HowardHinnant/date/archive/refs/tags/v3.0.1.zip")
           (file-name "v3.0.1.zip")
           (sha256
            (base32 "17yglzds0c70wgfmnq0g5mzry5bjxlyzmq7nkgpx8153yyb0nc7l"))))
   (cons "sherpa-onnx-core-ort-dlpack"
         (origin
           (method url-fetch)
           (uri "https://github.com/dmlc/dlpack/archive/5c210da409e7f1e51ddf445134a4376fdbd70d7d.zip")
           (file-name "5c210da409e7f1e51ddf445134a4376fdbd70d7d.zip")
           (sha256
            (base32 "1ggwk8i5kcna902vbi2xi5gsdrmnrx5gszzsndb1yimp7bqb7s0l"))))
   (cons "sherpa-onnx-core-ort-eigen"
         (origin
           (method url-fetch)
           (uri "https://github.com/eigen-mirror/eigen/archive/1d8b82b0740839c0de7f1242a3585e3390ff5f33/eigen-1d8b82b0740839c0de7f1242a3585e3390ff5f33.zip")
           (file-name "eigen-1d8b82b0740839c0de7f1242a3585e3390ff5f33.zip")
           (sha256
            (base32 "1c0y8rf1q853hzbd4fl8060h0jzidcfp5sxfkmk34wgra5ixfq3a"))))
   (cons "sherpa-onnx-core-ort-flatbuffers"
         (origin
           (method url-fetch)
           (uri "https://github.com/google/flatbuffers/archive/refs/tags/v23.5.26.zip")
           (file-name "v23.5.26.zip")
           (sha256
            (base32 "1qcmxgp1zylai450crf1z72kna95agq8parldir1mzbj0w65igap"))))
   (cons "sherpa-onnx-core-ort-fp16"
         (origin
           (method url-fetch)
           (uri "https://github.com/Maratyszcza/FP16/archive/0a92994d729ff76a58f692d3028ca1b64b145d91.zip")
           (file-name "0a92994d729ff76a58f692d3028ca1b64b145d91.zip")
           (sha256
            (base32 "0w3df6jmaxmwklfd0021cvz5q8g4ig389mfk92rjg6d0bx8navp6"))))
   (cons "sherpa-onnx-core-ort-fxdiv"
         (origin
           (method url-fetch)
           (uri "https://github.com/Maratyszcza/FXdiv/archive/63058eff77e11aa15bf531df5dd34395ec3017c8.zip")
           (file-name "63058eff77e11aa15bf531df5dd34395ec3017c8.zip")
           (sha256
            (base32 "1ns4lhfx2f5cv44y15da7ispz6rgw1mi51hhd8vq92k59jf0wyrx"))))
   (cons "sherpa-onnx-core-ort-google_benchmark"
         (origin
           (method url-fetch)
           (uri "https://github.com/google/benchmark/archive/refs/tags/v1.8.5.zip")
           (file-name "v1.8.5.zip")
           (sha256
            (base32 "1k1xnxph5fdy79dal22rgp26q126a937dslimq16z85zrmjpix9r"))))
   (cons "sherpa-onnx-core-ort-googletest"
         (origin
           (method url-fetch)
           (uri "https://github.com/google/googletest/archive/refs/tags/v1.17.0.zip")
           (file-name "v1.17.0.zip")
           (sha256
            (base32 "1zqqbqffly1jfraqg5gfm0rllzfs99c6hamykr5cip0p4aafrm20"))))
   (cons "sherpa-onnx-core-ort-googlexnnpack"
         (origin
           (method url-fetch)
           (uri "https://github.com/google/XNNPACK/archive/3cf85e705098622d59056dcb8f5f963ea7bb0a00.zip")
           (file-name "3cf85e705098622d59056dcb8f5f963ea7bb0a00.zip")
           (sha256
            (base32 "0i25jyl0857zi8qjjbhw6mqdwaiw7i6g52h9hc7cw2qygz0ppbz4"))))
   (cons "sherpa-onnx-core-ort-json"
         (origin
           (method url-fetch)
           (uri "https://github.com/nlohmann/json/archive/refs/tags/v3.11.3.zip")
           (file-name "v3.11.3.zip")
           (sha256
            (base32 "0sc0az3rx8x1485pl9mpw69jplcphsv81hi363vmzsq6v02jn0h4"))))
   (cons "sherpa-onnx-core-ort-microsoft_gsl"
         (origin
           (method url-fetch)
           (uri "https://github.com/microsoft/GSL/archive/refs/tags/v4.2.1.zip")
           (file-name "v4.2.1.zip")
           (sha256
            (base32 "0xk0ga77il9xfb7g0rpks19yb28xn24sa1hdk5hwbrgnynaisaf9"))))
   (cons "sherpa-onnx-core-ort-mimalloc"
         (origin
           (method url-fetch)
           (uri "https://github.com/microsoft/mimalloc/archive/refs/tags/v2.1.1.zip")
           (file-name "v2.1.1.zip")
           (sha256
            (base32 "0fkpmnyclz8h3qanl8006js2pns8sh899p4frgiv2mzz5vxvzc93"))))
   (cons "sherpa-onnx-core-ort-mp11"
         (origin
           (method url-fetch)
           (uri "https://github.com/boostorg/mp11/archive/refs/tags/boost-1.82.0.zip")
           (file-name "boost-1.82.0.zip")
           (sha256
            (base32 "16f8mbv8smpzhssdiwl6zlcn8mcggw3fs1rcw0ja6ff48kf1nhw1"))))
   (cons "sherpa-onnx-core-ort-onnx"
         (origin
           (method url-fetch)
           (uri "https://github.com/onnx/onnx/archive/refs/tags/v1.21.0.zip")
           (file-name "v1.21.0.zip")
           (sha256
            (base32 "0gj3b69lbmlxbh0ngf92aw1l5fsnnh6kirllxsgy9k2fv5q6bddq"))))
   (cons "sherpa-onnx-core-ort-protobuf"
         (origin
           (method url-fetch)
           (uri "https://github.com/protocolbuffers/protobuf/archive/refs/tags/v21.12.zip")
           (file-name "v21.12.zip")
           (sha256
            (base32 "160289pk8i549n6q5y69wqv9icb96cpxlyr8wqssrc5fvribccba"))))
   (cons "sherpa-onnx-core-ort-psimd"
         (origin
           (method url-fetch)
           (uri "https://github.com/Maratyszcza/psimd/archive/072586a71b55b7f8c584153d223e95687148a900.zip")
           (file-name "072586a71b55b7f8c584153d223e95687148a900.zip")
           (sha256
            (base32 "1drpx3arf0psvccl83yzlygvpn8fp5l1pr93af4clldypi156qfw"))))
   (cons "sherpa-onnx-core-ort-pthreadpool"
         (origin
           (method url-fetch)
           (uri "https://github.com/google/pthreadpool/archive/dcc9f28589066af0dbd4555579281230abbf74dd.zip")
           (file-name "dcc9f28589066af0dbd4555579281230abbf74dd.zip")
           (sha256
            (base32 "1715ddqzp0imfrhil3wvv3l0rbklwbccqs4rk3dmn3dziaqzr4xi"))))
   (cons "sherpa-onnx-core-ort-pybind11"
         (origin
           (method url-fetch)
           (uri "https://github.com/pybind/pybind11/archive/refs/tags/v3.0.2.zip")
           (file-name "v3.0.2.zip")
           (sha256
            (base32 "0k5z5gnpya1xpzciplw1g0hs36714al4yip1ijbdqsskx8b4sxg3"))))
   (cons "sherpa-onnx-core-ort-pytorch_cpuinfo"
         (origin
           (method url-fetch)
           (uri "https://github.com/pytorch/cpuinfo/archive/403d652dca4c1046e8145950b1c0997a9f748b57.zip")
           (file-name "403d652dca4c1046e8145950b1c0997a9f748b57.zip")
           (sha256
            (base32 "1qmmabf479i3xdlbjrvvq8i2960d9rdy91r21dgw1x6kp0j9hz9m"))))
   (cons "sherpa-onnx-core-ort-re2"
         (origin
           (method url-fetch)
           (uri "https://github.com/google/re2/archive/refs/tags/2024-07-02.zip")
           (file-name "2024-07-02.zip")
           (sha256
            (base32 "07n73mjajba0g7b6pczyy9kjqrj010nv4jjq707yin6wzdazwdd8"))))
   (cons "sherpa-onnx-core-ort-safeint"
         (origin
           (method url-fetch)
           (uri "https://github.com/dcleblanc/SafeInt/archive/refs/tags/3.0.28.zip")
           (file-name "3.0.28.zip")
           (sha256
            (base32 "0grc0f50dlgkv27wwf2wxlxs8bjimblnjwiyv9vxligzznidkyrz"))))
   (cons "sherpa-onnx-core-ort-extensions"
         (origin
           (method url-fetch)
           (uri "https://github.com/microsoft/onnxruntime-extensions/archive/c24b7bab0c12f53da76d0c31b03b9f0f8ec8f3b4.zip")
           (file-name "c24b7bab0c12f53da76d0c31b03b9f0f8ec8f3b4.zip")
           (sha256
            (base32 "0r9dd9m9lla0ynpjw3vi1rji5m806g5v460x57vlwd1k7x9r5byh"))))
   (cons "sherpa-onnx-core-ort-duktape"
         (origin
           (method url-fetch)
           (uri "https://github.com/svaarala/duktape/releases/download/v2.7.0/duktape-2.7.0.tar.xz")
           (file-name "duktape-2.7.0.tar.xz")
           (sha256
            (base32 "14187ihsr9vsl4pj5jhsn5h7khpk0cnfzp9hk24wcrsmigxd5y4h"))))
   (cons "sherpa-onnx-core-ort-vendor-build-recipes"
         (origin
           (method url-fetch)
           (uri "https://codeload.github.com/csukuangfj/onnxruntime-libs/tar.gz/05ffc5a560d4e74cf6a80e86dfc5800a1474cce1")
           (file-name "csukuangfj-05ffc5a560d4e74cf6a80e86dfc5800a1474cce1.tar.gz")
           (sha256
            (base32 "06rdy4n5fryk1fdcsw3kzsjdm1ys07qz8iyh8xqxyzjsxmiv8vxh"))))
   (cons "obstore-pyo3-file-apache2-fulltext"
         (origin
           (method url-fetch)
           (uri "https://www.apache.org/licenses/LICENSE-2.0.txt")
           (file-name "LICENSE-2.0.txt")
           (sha256
            (base32 "0c1xaay1fd00xgri0z447q2i8s3mpxqw9da27hfd6fznjsdp9iyg"))))
   (cons "sherpa-onnx-core-ort-strip-script"
         (origin
           (method url-fetch)
           (uri "https://raw.githubusercontent.com/microsoft/onnxruntime/v1.18.1/tools/ci_build/github/linux/copy_strip_binary.sh")
           (file-name "copy_strip_binary.sh")
           (sha256
            (base32 "1dcb2w68bn97gpgnb9s382b7jk2acfq2kk628ckps9lwf95rmacb"))))
   (cons "tflite-runtime-eigen-mpl-covered-source"
         (origin
           (method url-fetch)
           (uri "https://gitlab.com/libeigen/eigen/-/archive/0b51f763cbbd0ed08168f88972724329f0375498/eigen-0b51f763cbbd0ed08168f88972724329f0375498.tar.gz")
           (file-name "eigen-0b51f763cbbd0ed08168f88972724329f0375498.tar.gz")
           (sha256
            (base32 "1z7l4rka0xkgr3czadwdwbfs07msbnhrfl1g0107f0zwaziv18vh"))))
   (cons "tflite-runtime-eigen-source-pin"
         (origin
           (method url-fetch)
           (uri "https://raw.githubusercontent.com/tensorflow/tensorflow/4dacf3f368eb7965e9b5c3bbdd5193986081c3b2/third_party/eigen3/workspace.bzl")
           (file-name "workspace.bzl")
           (sha256
            (base32 "1f3ybs00g0k5y5knss1hr3w561m75kxnv4g9f14zr1pz96dbihy8"))))
   (cons "retained-rust-upstream-64d77b7a5f119d7b"
         (origin
           (method url-fetch)
           (uri "https://codeload.github.com/jni-rs/jni-sys/tar.gz/64d77b7a5f119d7b55b4e2c169a4668067ff59e6")
           (file-name "jni-sys-64d77b7a5f119d7b55b4e2c169a4668067ff59e6.tar.gz")
           (sha256
            (base32 "10mq1863hd5rxjcnqrkid8j771q4fdbf10n044x647h7zz8nad68"))))
   (cons "retained-rust-upstream-7b1abfd750a2caca"
         (origin
           (method url-fetch)
           (uri "https://codeload.github.com/madsmtm/objc2/tar.gz/7b1abfd750a2cacaea71d6a56ecfb83cb7de560b")
           (file-name "objc2-7b1abfd750a2cacaea71d6a56ecfb83cb7de560b.tar.gz")
           (sha256
            (base32 "0kbaz52maxd39ypvgdas3nppsi28f96k9s07v2g2nk6s62dmws56"))))
   (cons "retained-rust-upstream-d42c85e790263f78"
         (origin
           (method url-fetch)
           (uri "https://codeload.github.com/tokio-rs/prost/tar.gz/d42c85e790263f78f6c626ceb0dac5fda0edcb41")
           (file-name "prost-d42c85e790263f78f6c626ceb0dac5fda0edcb41.tar.gz")
           (sha256
            (base32 "1sga28cn5k4gmsmfd7433dqdnqyx9p5ra0ghpd9blcbp6jw526dq"))))
   (cons "retained-rust-upstream-43a612b514553481"
         (origin
           (method url-fetch)
           (uri "https://codeload.github.com/cunarist/tokio-with-wasm/tar.gz/43a612b5145534819e84f7e2da1ba57ed00926a0")
           (file-name "tokio-with-wasm-43a612b5145534819e84f7e2da1ba57ed00926a0.tar.gz")
           (sha256
            (base32 "0fy359hal97k0cfbzv33gkh4nrwsxps3j4lrwr5a2rdqym635ly7"))))
   (cons "retained-rust-upstream-21d24942a5a4a180"
         (origin
           (method url-fetch)
           (uri "https://codeload.github.com/hyperium/tonic/tar.gz/21d24942a5a4a1806344beb331d4157d510a210c")
           (file-name "grpc-rust-21d24942a5a4a1806344beb331d4157d510a210c.tar.gz")
           (sha256
            (base32 "0hvk4201pr9h3npf1s3pvhx1k53n4z2vaf0hgmqfd2qhb1wwmjcc"))))
   (cons "retained-rust-upstream-06ce201370fcde0d"
         (origin
           (method url-fetch)
           (uri "https://codeload.github.com/bytecodealliance/wasi-rs/tar.gz/06ce201370fcde0d1b0d47cac8ecb1b0b312c9f9")
           (file-name "wasi-rs-06ce201370fcde0d1b0d47cac8ecb1b0b312c9f9.tar.gz")
           (sha256
            (base32 "1zskvbqmzpncxfyg1lsvb8h0jgcfkbwm97p787l02ylhrx611822"))))
   (cons "retained-rust-upstream-3f7d6ad926848cd5"
         (origin
           (method url-fetch)
           (uri "https://codeload.github.com/ardaku/wasite/tar.gz/3f7d6ad926848cd52c8d2142fdb2f43ab01ae8ec")
           (file-name "wasite-3f7d6ad926848cd52c8d2142fdb2f43ab01ae8ec.tar.gz")
           (sha256
            (base32 "153chyv3hlcn01mrwmqcj5kfiy44sh9sic0pfar5z8nb0wk6s1yj"))))
   (cons "retained-rust-upstream-d4e317f22c3bace7"
         (origin
           (method url-fetch)
           (uri "https://codeload.github.com/bytecodealliance/wasm-tools/tar.gz/d4e317f22c3bace76cb3205003bcc34b4929037d")
           (file-name "wasm-tools-d4e317f22c3bace76cb3205003bcc34b4929037d.tar.gz")
           (sha256
            (base32 "1wlwxmk11cg6i0m6zi3swc4iay4lqgw4gh5mpgzm8drrn2pzksgg"))))
   (cons "retained-rust-upstream-378ac7461ecac29f"
         (origin
           (method url-fetch)
           (uri "https://codeload.github.com/zrzka/anes-rs/tar.gz/378ac7461ecac29fde9e10df7b08359d1315a9ad")
           (file-name "anes-rs-378ac7461ecac29fde9e10df7b08359d1315a9ad.tar.gz")
           (sha256
            (base32 "08g7f5v9i1g588crxmnlzvrb734wpqnrfarr3xfbzqi292lfba63"))))
   (cons "retained-rust-upstream-071a15cf33fc2662"
         (origin
           (method url-fetch)
           (uri "https://codeload.github.com/CodSpeedHQ/codspeed-rust/tar.gz/071a15cf33fc266221ba444ef0734e5622655556")
           (file-name "codspeed-rust-071a15cf33fc266221ba444ef0734e5622655556.tar.gz")
           (sha256
            (base32 "1sgn9zcfzyxizzrjysbfswhmsq5cmsx8gx5ng4yppn5vcx9b8yrc"))))
   (cons "retained-rust-upstream-5ae9458a4ec44c53"
         (origin
           (method url-fetch)
           (uri "https://codeload.github.com/jni-rs/jni-rs/tar.gz/5ae9458a4ec44c5318f37ddc7569c1d4ae8a69e7")
           (file-name "jni-rs-5ae9458a4ec44c5318f37ddc7569c1d4ae8a69e7.tar.gz")
           (sha256
            (base32 "01dlid5w1v1x7ck5a0il84av6hmxmyjvzp95gj76ij9xg2apyn7z"))))
   (cons "retained-rust-upstream-33045a124105c939"
         (origin
           (method url-fetch)
           (uri "https://codeload.github.com/jni-rs/jni-rs/tar.gz/33045a124105c939d1e2cbdcb5a39e5d868ffa03")
           (file-name "jni-rs-33045a124105c939d1e2cbdcb5a39e5d868ffa03.tar.gz")
           (sha256
            (base32 "0zy35lysyjwynffx0jr9bxgh8bhb03k6l5z760cm4n9dvmy5w9ra"))))
   (cons "retained-rust-upstream-f2178312d0e3e07b"
         (origin
           (method url-fetch)
           (uri "https://codeload.github.com/napi-rs/napi-rs/tar.gz/f2178312d0e3e07beecc19836b91716a229107d3")
           (file-name "napi-rs-f2178312d0e3e07beecc19836b91716a229107d3.tar.gz")
           (sha256
            (base32 "151kn2i4l2vrpm3jxfl0zlbvbv89yr6fa3c0ggrd6cav5wgx9py1"))))
   (cons "retained-rust-upstream-a312b7eb4e12d3e0"
         (origin
           (method url-fetch)
           (uri "https://codeload.github.com/napi-rs/napi-rs/tar.gz/a312b7eb4e12d3e0a3e9770429ee05c333947a39")
           (file-name "napi-rs-a312b7eb4e12d3e0a3e9770429ee05c333947a39.tar.gz")
           (sha256
            (base32 "1alcdwapl8yw5s9k7k4z5qv16fha34y45ikngx5f3vrqdf2da2q7"))))
   (cons "retained-rust-upstream-f1b8ab5e645e674d"
         (origin
           (method url-fetch)
           (uri "https://codeload.github.com/napi-rs/napi-rs/tar.gz/f1b8ab5e645e674df33c796ef75aa278cd1b4a31")
           (file-name "napi-rs-f1b8ab5e645e674df33c796ef75aa278cd1b4a31.tar.gz")
           (sha256
            (base32 "1r6cfp1qbil772zridr66gg7nnz5qq0d2bdz0zw1qjz9z2jk4xq8"))))
   (cons "retained-rust-upstream-e68410e22a2d29d5"
         (origin
           (method url-fetch)
           (uri "https://codeload.github.com/madsmtm/objc2/tar.gz/e68410e22a2d29d5f37a0b4c1b7e8e194808eade")
           (file-name "objc2-e68410e22a2d29d5f37a0b4c1b7e8e194808eade.tar.gz")
           (sha256
            (base32 "0n4s8a02wwmh189nra5x12235dfgddfdjy9kn3qxhj9xwld9px95"))))
   (cons "retained-rust-upstream-ec289cb3c6f82609"
         (origin
           (method url-fetch)
           (uri "https://codeload.github.com/open-telemetry/opentelemetry-rust/tar.gz/ec289cb3c6f8260951699c51df968560943c1451")
           (file-name "opentelemetry-rust-ec289cb3c6f8260951699c51df968560943c1451.tar.gz")
           (sha256
            (base32 "03ijjfph4i6s9ggc59sngd1l729cqp5pkk1rrl38l8wxwdc47974"))))
   (cons "retained-rust-upstream-74cb6f3a4129bf11"
         (origin
           (method url-fetch)
           (uri "https://codeload.github.com/open-telemetry/opentelemetry-rust/tar.gz/74cb6f3a4129bf11fa3191f28d38c518c4ec4ae6")
           (file-name "opentelemetry-rust-74cb6f3a4129bf11fa3191f28d38c518c4ec4ae6.tar.gz")
           (sha256
            (base32 "05d674iaj4wm5mpn5yhyl7cqfjcc090jihdq0yqjlybbqs5hbp11"))))
   (cons "retained-rust-upstream-284a37d93b3856e1"
         (origin
           (method url-fetch)
           (uri "https://codeload.github.com/open-telemetry/opentelemetry-rust/tar.gz/284a37d93b3856e1975c2807ba3af1421ebd9b52")
           (file-name "opentelemetry-rust-284a37d93b3856e1975c2807ba3af1421ebd9b52.tar.gz")
           (sha256
            (base32 "09vq5530s3l2jpqh876r653y1j27kmqc7r60hj369vfbcwf5nbkn"))))
   (cons "retained-rust-upstream-895c0433c3727a55"
         (origin
           (method url-fetch)
           (uri "https://codeload.github.com/stepancheg/rust-protoc-bin-vendored/tar.gz/895c0433c3727a552970ce961e398e20e52d6353")
           (file-name "rust-protoc-bin-vendored-895c0433c3727a552970ce961e398e20e52d6353.tar.gz")
           (sha256
            (base32 "063rj98vdjj4mdn7qggf43xqf09i2wxn0dncqm4pav17r5dcc1ap"))))
   (cons "retained-rust-upstream-551953346b356fa5"
         (origin
           (method url-fetch)
           (uri "https://codeload.github.com/SpriteOvO/spdlog-rs/tar.gz/551953346b356fa55a2fd217c9f37fa5d4d21c52")
           (file-name "spdlog-rs-551953346b356fa55a2fd217c9f37fa5d4d21c52.tar.gz")
           (sha256
            (base32 "1zzpr7jcrdh6b0w8g98h44951krzbmpf8rhchq61in6nww0rl2zd"))))
   (cons "retained-rust-upstream-6cb6056b5a748bc5"
         (origin
           (method url-fetch)
           (uri "https://codeload.github.com/hyperium/tonic/tar.gz/6cb6056b5a748bc5a29bd48f4602dbc4e552bb7d")
           (file-name "grpc-rust-6cb6056b5a748bc5a29bd48f4602dbc4e552bb7d.tar.gz")
           (sha256
            (base32 "0szdqqmzam57942jdpyhsqmjnbd87kywmry1582wl4gxzi20b9zx"))))
   (cons "retained-rust-upstream-d74c030d9dc4f3ca"
         (origin
           (method url-fetch)
           (uri "https://codeload.github.com/Nugine/simd/tar.gz/d74c030d9dc4f3cae02146d1f497ff62726ef09a")
           (file-name "simd-d74c030d9dc4f3cae02146d1f497ff62726ef09a.tar.gz")
           (sha256
            (base32 "0y7hx8b3i0aryx7jxdnws2wws8q43jvnffm657yck0kaay8ckl4i"))))
   (cons "retained-rust-upstream-b7e65f9a4c317494"
         (origin
           (method url-fetch)
           (uri "https://codeload.github.com/qnighy/yasna.rs/tar.gz/b7e65f9a4c317494cce2d18ea02b3d6eaaea7985")
           (file-name "yasna.rs-b7e65f9a4c317494cce2d18ea02b3d6eaaea7985.tar.gz")
           (sha256
            (base32 "0wlgm9njl6zclxx3345z3ad145scflcaq48s1mv74z0wnyaijjyk"))))))
