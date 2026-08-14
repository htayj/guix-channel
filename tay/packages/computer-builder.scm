;;; Computer Builder -- offline-built PC component catalog web application.
;;;
;;; SPDX-License-Identifier: AGPL-3.0-or-later

(define-module (tay packages computer-builder)
  #:use-module (guix build-system gnu)
  #:use-module (guix download)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages bash)
  #:use-module (gnu packages node)
  #:use-module (gnu packages python)
  #:use-module (tay packages projects))

;; The upstream project is an application rather than an npm package.  Its
;; package-lock.json records the complete npm graph, but Guix cannot obtain
;; dependencies during a build.  Keep each immutable registry tarball here,
;; with a Guix-computed hash, and populate npm's cache before the offline
;; install.  This also retains all platform-conditional packages in the lock
;; graph, so the derivation can be built on supported Guix architectures.
(define %computer-builder-npm-sources
  (map (lambda (entry)
         (origin
           (method url-fetch)
           (uri (car entry))
           (file-name "computer-builder-npm-dependency.tgz")
           (sha256
            (base32 (cadr entry)))))
       '(
    ("https://registry.npmjs.org/@emnapi/core/-/core-1.10.0.tgz" "08575269hy74mc0kgfilsr49gw6fj80zmrdacwx707r3fch62d38")
    ("https://registry.npmjs.org/@emnapi/runtime/-/runtime-1.10.0.tgz" "1s000zngg031kfjw0m7p39p2zcwf9w4jvi2f24ss1pj722198blc")
    ("https://registry.npmjs.org/@emnapi/wasi-threads/-/wasi-threads-1.2.1.tgz" "1fcbx8f56gmnzngg864an4yk6n8y9f9ck7jpayixnbnijszf7r1h")
    ("https://registry.npmjs.org/@jridgewell/sourcemap-codec/-/sourcemap-codec-1.5.5.tgz" "11b5h4hihb2n8203znalqm53s7pv82a84jahsqgf7rd2406kpba7")
    ("https://registry.npmjs.org/@napi-rs/wasm-runtime/-/wasm-runtime-1.1.4.tgz" "020blrp8ci6k73r89v44r2b982igqrs4si0rk8pqv3zx6frq314n")
    ("https://registry.npmjs.org/@oxc-project/types/-/types-0.129.0.tgz" "02qj8hc91dkhlna7z309f2v45bdyql8j94b8a3ckrvjx5ph4x8hd")
    ("https://registry.npmjs.org/@rolldown/binding-android-arm64/-/binding-android-arm64-1.0.0.tgz" "1bg36qkz1mqifbj1pl6xarxj64dvim33n3b12zfkg9f4g9gyjfdm")
    ("https://registry.npmjs.org/@rolldown/binding-darwin-arm64/-/binding-darwin-arm64-1.0.0.tgz" "0y18lqyjj8rvqy4cf5v0am2vjr6xm3dw06cp6ry9crkdfld7sk2w")
    ("https://registry.npmjs.org/@rolldown/binding-darwin-x64/-/binding-darwin-x64-1.0.0.tgz" "1ldqfs5cp76c5qvsbyv1j1b2sxy6b6xa74lpci01pp6cjkgzd4l7")
    ("https://registry.npmjs.org/@rolldown/binding-freebsd-x64/-/binding-freebsd-x64-1.0.0.tgz" "1rislklvw777mygj1nfb0hrbp3l1aqahhhs2lxvgicr7mz0acxgw")
    ("https://registry.npmjs.org/@rolldown/binding-linux-arm-gnueabihf/-/binding-linux-arm-gnueabihf-1.0.0.tgz" "1kysnhzp3sh13v72q58zirrrd2p9l4hg9zgcnwq1lr8s5k69cmkx")
    ("https://registry.npmjs.org/@rolldown/binding-linux-arm64-gnu/-/binding-linux-arm64-gnu-1.0.0.tgz" "15sg29nwxvnc6didwkq16ab5gd2jx3af3cbvrlbjvrarm204l29b")
    ("https://registry.npmjs.org/@rolldown/binding-linux-arm64-musl/-/binding-linux-arm64-musl-1.0.0.tgz" "12j6wfkg7yhmlqwxjz8j357wr3ys963jjvji3dms1ryg8wabhrp1")
    ("https://registry.npmjs.org/@rolldown/binding-linux-ppc64-gnu/-/binding-linux-ppc64-gnu-1.0.0.tgz" "0fn7c1vm8mcxy19yfifdrwyn3w1sgp3g8m7qb2ipgl39kygwv90n")
    ("https://registry.npmjs.org/@rolldown/binding-linux-s390x-gnu/-/binding-linux-s390x-gnu-1.0.0.tgz" "1jiw79wprlx3gzx16xp1dm915fk6a1mhj8chdmdspl23sva5dqlr")
    ("https://registry.npmjs.org/@rolldown/binding-linux-x64-gnu/-/binding-linux-x64-gnu-1.0.0.tgz" "0v6z9j9p192lbl9i855bdb0h8ycvlwk9xnjczbwm4pnl9k0s7aha")
    ("https://registry.npmjs.org/@rolldown/binding-linux-x64-musl/-/binding-linux-x64-musl-1.0.0.tgz" "0lcyinq85km1qg9alilsbqbh1n5xx228nk6ddcgl58f5i9bsn42p")
    ("https://registry.npmjs.org/@rolldown/binding-openharmony-arm64/-/binding-openharmony-arm64-1.0.0.tgz" "0zj9bzg2synsfp65a6l0w2yjgbdynqwbjn6l3j604c2l0gzlycj1")
    ("https://registry.npmjs.org/@rolldown/binding-wasm32-wasi/-/binding-wasm32-wasi-1.0.0.tgz" "15w5ixafh7lq04p5p93nbdh0lzrz5aqcayd5phjb1r6622cc53m4")
    ("https://registry.npmjs.org/@rolldown/binding-win32-arm64-msvc/-/binding-win32-arm64-msvc-1.0.0.tgz" "0mr2cbrgzxfimkp0iw1daf5fgfqx4wwmqxpxvm47i2khv98q88gm")
    ("https://registry.npmjs.org/@rolldown/binding-win32-x64-msvc/-/binding-win32-x64-msvc-1.0.0.tgz" "0h69zf7if76vch4x8k9p9jygggzp2d99sjrslpbf55knydva4w56")
    ("https://registry.npmjs.org/@rolldown/pluginutils/-/pluginutils-1.0.0-rc.7.tgz" "1j3scm70mzb6y8v3fi7d60qkb9lsh7hbzcl0k12rz82ppagap4by")
    ("https://registry.npmjs.org/@standard-schema/spec/-/spec-1.1.0.tgz" "1byfgh3b6ngdj4vba2jw48bk9wl6gjqc7y2hshcba2i8prl75jx7")
    ("https://registry.npmjs.org/@tybys/wasm-util/-/wasm-util-0.10.2.tgz" "04kagp51qh13j0bzm2ddsx16cvk4g0jsh4wsxg61hsnbjnz9r7k8")
    ("https://registry.npmjs.org/@types/chai/-/chai-5.2.3.tgz" "153zvpnbwgi62h75w9jzcjpayr87af2rnvidk8npvq9q8bim432z")
    ("https://registry.npmjs.org/@types/deep-eql/-/deep-eql-4.0.2.tgz" "01rnbz1kbwyrs8bh1ljzqajcbx1d6h82pcb2d6yj68ndy9gihgdn")
    ("https://registry.npmjs.org/@types/estree/-/estree-1.0.9.tgz" "0n5k5ff2mvz30d6ymcipng9ii6vgryk4a328lfspsj91zc6kr3zc")
    ("https://registry.npmjs.org/@types/react/-/react-19.2.14.tgz" "1lmrdnw8vpymmvmxpcar92y5bmi1cwqxai5kdi6wkla0id9wy3gf")
    ("https://registry.npmjs.org/@types/react-dom/-/react-dom-19.2.3.tgz" "0jqdpwav9lmsxiq5s9218vgx1s3972idzbnxb4fyc5pnwwqnjxh1")
    ("https://registry.npmjs.org/@vitejs/plugin-react/-/plugin-react-6.0.1.tgz" "0lv1i452fbnrb6f23dfz3037jj3ir5yaii8p0k14wcwcnidjhrjd")
    ("https://registry.npmjs.org/@vitest/expect/-/expect-4.1.6.tgz" "19kavll4z230dv5ci1b992dm13cd7bq8i1807mh1jb1kb8vxflj4")
    ("https://registry.npmjs.org/@vitest/mocker/-/mocker-4.1.6.tgz" "1qdz5n7znbniw66mpizrigyq4nzp5f9wr65pgblwmpdf86q8pwf8")
    ("https://registry.npmjs.org/@vitest/pretty-format/-/pretty-format-4.1.6.tgz" "0xwx1xl1x63hhzzi2qbnqcv9jar8fdazx9crflj10a64x91pyw3r")
    ("https://registry.npmjs.org/@vitest/runner/-/runner-4.1.6.tgz" "0mqhq4avn242q28ql6c6i94hrmhfzkc8dz01r25wp86ljqvsk45b")
    ("https://registry.npmjs.org/@vitest/snapshot/-/snapshot-4.1.6.tgz" "14wr22pisz6nr9nd9ay79p4mbj9k19mgkn6m7v0y2h1jj78r7lk6")
    ("https://registry.npmjs.org/@vitest/spy/-/spy-4.1.6.tgz" "1zcmngl21gh0rxlygzawl0zl68b2c7qqb4kc6007964bx0sqk2kk")
    ("https://registry.npmjs.org/@vitest/utils/-/utils-4.1.6.tgz" "0w5hfkcgihlz0f0dbm24qy28lq0i2306bv31g9hq32ph07nws7s2")
    ("https://registry.npmjs.org/assertion-error/-/assertion-error-2.0.1.tgz" "0mhgq8w0jyw6x02gzy3p5zzfaglkly2lv38q4cqlz3mkr6rsbx3k")
    ("https://registry.npmjs.org/chai/-/chai-6.2.2.tgz" "0n2v0njbnmqdxvwzfb55fg6lbd5ybbsm4sz9k1hwaiak6xsdab3h")
    ("https://registry.npmjs.org/convert-source-map/-/convert-source-map-2.0.0.tgz" "160qzrwfhj8xkc2ya476hp7sahaj5gnzv4hi6xl9zq74qwz2bxqp")
    ("https://registry.npmjs.org/csstype/-/csstype-3.2.3.tgz" "18r7fhq1k5apllflcqljwmkh8b0n649c28nbzrl7agy7w671yl7k")
    ("https://registry.npmjs.org/detect-libc/-/detect-libc-2.1.2.tgz" "09wlldyqvhf2w7q4xcch4xh6pvldy7c2vbx83m48dzvcq07yq397")
    ("https://registry.npmjs.org/effect/-/effect-3.21.2.tgz" "0hf0h65b0r9ijzfs6rbp2pz7bh7byig9ad99d6kf4p6axs3glldh")
    ("https://registry.npmjs.org/es-module-lexer/-/es-module-lexer-2.1.0.tgz" "0dvqhbpmh7wxn7pyfx6ka899pm26llbc8r4hpw9sdcfnvmir4nki")
    ("https://registry.npmjs.org/estree-walker/-/estree-walker-3.0.3.tgz" "1cvj3jfzlrg1dskkcwbjaccc00s16jma8mag8yg0kvyrdk0zvgdv")
    ("https://registry.npmjs.org/expect-type/-/expect-type-1.3.0.tgz" "0fgj240ahldn8wmrkb7f32hxm4nmqvgd51y45ah3d0a2c30mnxrg")
    ("https://registry.npmjs.org/fast-check/-/fast-check-3.23.2.tgz" "0ij66f4g9rad48dkn3zgld29sq0xl80l1iigjvcnp1849s2rmp70")
    ("https://registry.npmjs.org/fdir/-/fdir-6.5.0.tgz" "0pin1ngw51v3z7q8gs4q84bwwcw3pdyh29jk8351yahyygcxq794")
    ("https://registry.npmjs.org/fsevents/-/fsevents-2.3.3.tgz" "0zjqkcinvdl2dk5sh95xmk6jh1ay8nhd8i3wxandf7gkbxfplzn7")
    ("https://registry.npmjs.org/lightningcss/-/lightningcss-1.32.0.tgz" "1s2h2ndakhgsjbm9zam4b0fr7l7hi1khlikpb2f437iw47m82gn8")
    ("https://registry.npmjs.org/lightningcss-android-arm64/-/lightningcss-android-arm64-1.32.0.tgz" "04i48slmfrmf0sa5dpj1z7z5lbkqhla2ggx0w05402adifpbiaxl")
    ("https://registry.npmjs.org/lightningcss-darwin-arm64/-/lightningcss-darwin-arm64-1.32.0.tgz" "1rwyz6wbzbw3lrbclqh635rzw5p90k84md8h2c2gqw1glr1nnlbv")
    ("https://registry.npmjs.org/lightningcss-darwin-x64/-/lightningcss-darwin-x64-1.32.0.tgz" "07d17lb2i5mp65rdnfcn2bla7ca5vxc2jwdic84kmq2qi6j845sz")
    ("https://registry.npmjs.org/lightningcss-freebsd-x64/-/lightningcss-freebsd-x64-1.32.0.tgz" "1bqnmx9hjcpibzi1anb97z2s0g6r3im65m4zjhj5z9s46fd23w6b")
    ("https://registry.npmjs.org/lightningcss-linux-arm-gnueabihf/-/lightningcss-linux-arm-gnueabihf-1.32.0.tgz" "12ic7vhv9kz543c9gh47wwg0pnbddiybzn96r7yza2s38rddjblp")
    ("https://registry.npmjs.org/lightningcss-linux-arm64-gnu/-/lightningcss-linux-arm64-gnu-1.32.0.tgz" "1xa8hrrkz2z7czpk6ybs19jx9iff2ijfy23czp6w69jzdf197m06")
    ("https://registry.npmjs.org/lightningcss-linux-arm64-musl/-/lightningcss-linux-arm64-musl-1.32.0.tgz" "1jfcgb6i7x5j4h7rgfv6zy1x5a060zwayhz8x4h7ffr8siai2zbd")
    ("https://registry.npmjs.org/lightningcss-linux-x64-gnu/-/lightningcss-linux-x64-gnu-1.32.0.tgz" "02ri7hh6c41j3pfvhv9sbpv6pqjqs46mj506nlaa9pfs61i4cvwy")
    ("https://registry.npmjs.org/lightningcss-linux-x64-musl/-/lightningcss-linux-x64-musl-1.32.0.tgz" "11aj18ihs92hg7lg0b7bm3sq8fs70zzpr4yvpzzv82b6di0ay5sj")
    ("https://registry.npmjs.org/lightningcss-win32-arm64-msvc/-/lightningcss-win32-arm64-msvc-1.32.0.tgz" "0vw31al9mfxa24kdkfd3d219psnl6psbvxs2mig4pm2dazr9gbnx")
    ("https://registry.npmjs.org/lightningcss-win32-x64-msvc/-/lightningcss-win32-x64-msvc-1.32.0.tgz" "1dv25109q2mjx9nj7wybz1sln0ijiwnm6mlcxjvlg1ms1n4abjqm")
    ("https://registry.npmjs.org/magic-string/-/magic-string-0.30.21.tgz" "0vv5mh4rnr83gnpd0kkspy1c810f4mfkczrjry64x96wcwjpcjgs")
    ("https://registry.npmjs.org/nanoid/-/nanoid-3.3.12.tgz" "16spkxgz12v8jqrg6xavydygb5bpn2gy5pamwjav6k88lxqmhbcd")
    ("https://registry.npmjs.org/obug/-/obug-2.1.1.tgz" "0hxfqqjcy24n7ibc5rz30iqxxqjjm5jdsjzx407wnj14w2a1g913")
    ("https://registry.npmjs.org/pathe/-/pathe-2.0.3.tgz" "0dnzjq3529b584wj6rich8p0c16s0ydlbn7miw88lzxvbny76fvf")
    ("https://registry.npmjs.org/picocolors/-/picocolors-1.1.1.tgz" "1nc2z3w16wpz2840srcwyxd747khwfvh66yigyrpwywn0wldpbnk")
    ("https://registry.npmjs.org/picomatch/-/picomatch-4.0.4.tgz" "072pg3ji6ib0ns6jv3ypink59pmfj8432fj82yhxk3jmcsv5lnsi")
    ("https://registry.npmjs.org/postcss/-/postcss-8.5.14.tgz" "1yk4f60i81l6mc6bpklb68i11qapyzkd675lkraf4q3kmrvfsp9i")
    ("https://registry.npmjs.org/pure-rand/-/pure-rand-6.1.0.tgz" "1mvgy3vn7y8khfna4fqlb8l18d4i86cs4qrvg45mjrgkp3wmz7nb")
    ("https://registry.npmjs.org/react/-/react-19.2.6.tgz" "10r28ac3d18vfz3k12hd98vh4mvijjska0apx41drsir8ksf2s9q")
    ("https://registry.npmjs.org/react-dom/-/react-dom-19.2.6.tgz" "04av9i5gvm9qsrkh97g42k9cnv86kimpj1n90rfs7acncvhzsh58")
    ("https://registry.npmjs.org/rolldown/-/rolldown-1.0.0.tgz" "0x58nzlmfdv272afj6m8cg5479g2z3pyphgd6z6y7jc4260mfbmb")
    ("https://registry.npmjs.org/@rolldown/pluginutils/-/pluginutils-1.0.0.tgz" "0s4amfg2n3d2w94crih35c2xb4d53878zjn5p2af9734a5by3mqf")
    ("https://registry.npmjs.org/scheduler/-/scheduler-0.27.0.tgz" "15ahpkgc65b3mal36m3szvlmhcz1rysbpifgg15z0cj0rqsww9mb")
    ("https://registry.npmjs.org/siginfo/-/siginfo-2.0.0.tgz" "06vhqyr028bznlnfi0f4inr0526mk10ns5ya9ab4jh2iqi9xh3x2")
    ("https://registry.npmjs.org/source-map-js/-/source-map-js-1.2.1.tgz" "0ls8kncpxm2wxd4da6b1jrx1hyajjlx8rjyq34ra91x4zkwsc9pi")
    ("https://registry.npmjs.org/stackback/-/stackback-0.0.2.tgz" "0n2qll6342m6219skx7cjmc6rpd747n4idj6sj779yfcs613qriy")
    ("https://registry.npmjs.org/std-env/-/std-env-4.1.0.tgz" "1fn70gcvblwc49hgggfgadq1s5lg5wb4gbpc0r0p3x7wws9xvhpd")
    ("https://registry.npmjs.org/tinybench/-/tinybench-2.9.0.tgz" "0f9fb0840qfhz6kbwpv12an1ia6qwbx7w7ml1xkmjqrnq99yjf1s")
    ("https://registry.npmjs.org/tinyexec/-/tinyexec-1.1.2.tgz" "1dlyyhwh394m848d42aapz5r3l93bap8mahrvslvgj5r77lpfjg6")
    ("https://registry.npmjs.org/tinyglobby/-/tinyglobby-0.2.16.tgz" "010lkihfjgsqy47vglzsv7prkwwlmbxhg4sin216wwg85pny1mg7")
    ("https://registry.npmjs.org/tinyrainbow/-/tinyrainbow-3.1.0.tgz" "0hlq2h2knalxmfiapqv6c3nzpk7w7s9pmar114xfw9zwfzly8ww3")
    ("https://registry.npmjs.org/tslib/-/tslib-2.8.1.tgz" "17hiw9pawyczkhsnhlq4k9dn3kq2l49nk5rlfn049bmbxvakbxk6")
    ("https://registry.npmjs.org/typescript/-/typescript-6.0.3.tgz" "0anjcm0xk05wkls2sz1dlhs4rsnxc9n87nm92nfrx35apvhhxk9k")
    ("https://registry.npmjs.org/vite/-/vite-8.0.12.tgz" "0x6xzyb6cfg130i1q87m1bbiq8dw1arl1ipp6rj0rz335jcdk2fv")
    ("https://registry.npmjs.org/vitest/-/vitest-4.1.6.tgz" "1c21bny37w7gmfiqh74xk32j2wd822hk71lw519fx5jg85ppvbkj")
    ("https://registry.npmjs.org/why-is-node-running/-/why-is-node-running-2.3.0.tgz" "0qwrxh3bl4mdf9cb1y4ls57gddgmr5x621ggg409sl2kg7vnixnj")
         ;; npm-source-list-end
         )))

(define-public computer-builder
  (package
    (name "computer-builder")
    (version "0.1.0")
    ;; The channel's public-project snapshot is the audited, fixed source
    ;; identity for this application.
    (source (package-source htayj-computer-builder-source))
    (build-system gnu-build-system)
    (arguments
     (list
      #:tests? #f
      #:phases
      #~(modify-phases %standard-phases
          (delete 'configure)
          (delete 'check)
          (replace 'build
            (lambda _
              (let* ((node-bin #$(file-append node-lts "/bin"))
                     (npm (string-append node-bin "/npm"))
                     (cache (string-append (getcwd) "/npm-cache")))
                (setenv "PATH" (string-append node-bin ":" (getenv "PATH")))
                ;; `npm cache add' verifies these archives against the
                ;; sha512 integrity records in package-lock.json.  `npm ci'
                ;; then refuses all network access.
                (for-each (lambda (tarball)
                            (invoke npm "cache" "add" "--cache" cache tarball))
                          (list #$@%computer-builder-npm-sources))
                (invoke npm "ci" "--offline" "--ignore-scripts"
                        "--cache" cache "--no-audit")
                ;; The dependencies are installed after Guix's normal
                ;; shebang phase, so normalize the entry points used below.
                (for-each patch-shebang
                          (list "node_modules/typescript/bin/tsc"
                                "node_modules/vitest/vitest.mjs"
                                "node_modules/vite/bin/vite.js"))
                (invoke npm "run" "typecheck")
                (invoke npm "test")
                (invoke npm "run" "build"))))
          (replace 'install
            (lambda _
              (let ((site (string-append #$output "/share/computer-builder"))
                    (program (string-append #$output "/bin/computer-builder")))
                (mkdir-p site)
                (copy-recursively "dist" site)
                (mkdir-p (dirname program))
                (call-with-output-file program
                  (lambda (port)
                    (format port "#!~a/bin/sh~%" #$bash-minimal)
                    (format port
                            (string-append
                             "exec ~a/bin/python3 -m http.server --bind 127.0.0.1"
                             " --directory ~a \"$@\"~%")
                            #$python-minimal site)))
                (chmod program #o555)))))))
    (synopsis "Interactive PC component catalog web application")
    (description
     "Computer Builder is a locally hosted web application for exploring PC
component catalogs.  It validates structured GPU, CPU, motherboard, and power
supply data, and presents the GPU catalog with sortable specifications,
resources, capabilities, and performance marks.  The installed launcher serves
the immutable static application on localhost.")
    (home-page "https://github.com/htayj/computer-builder")
    (license license:agpl3+)))
