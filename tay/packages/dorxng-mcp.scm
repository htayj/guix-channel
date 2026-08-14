;;; Guix package for the DorXNG MCP server.

(define-module (tay packages dorxng-mcp)
  #:use-module (guix build-system pyproject)
  #:use-module (guix download)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (tay packages projects)
  #:use-module (gnu packages check)
  #:use-module (gnu packages python-build)
  #:use-module (gnu packages python-web)
  #:use-module (gnu packages python-xyz))

;; These two libraries are required by python-mcp, but are not provided by
;; Guix 1.5.  Keep them in this module because they solely complete the runtime
;; closure of the DorXNG MCP server.
(define-public python-httpx-sse
  (package
    (name "python-httpx-sse")
    (version "0.4.3")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "https://files.pythonhosted.org/packages/0f/4c/"
             "751061ffa58615a32c31b2d82e8482be8dd4a89154f003147acee90f2be9/"
             "httpx_sse-0.4.3.tar.gz"))
       (sha256
        (base32 "0pbmka4496h3ha08qqdnifyc38rxv7mnpif3mqa619jrfh9d07lv"))))
    (build-system pyproject-build-system)
    (arguments
     (list #:tests? #f)) ;Tests need optional HTTPX test fixtures.
    (native-inputs
     (list python-setuptools python-setuptools-scm python-wheel))
    ;; httpx-sse imports HTTPX but its 0.4.3 release metadata omits it.
    (propagated-inputs
     (list python-httpx))
    (synopsis "Consume Server-Sent Events with HTTPX")
    (description
     "HTTPX-SSE provides a small API for consuming Server-Sent Events with
HTTPX.")
    (home-page "https://github.com/florimondmanca/httpx-sse")
    (license license:expat)))

(define-public python-sse-starlette
  (package
    (name "python-sse-starlette")
    ;; The newer 3.x release requires newer AnyIO and Starlette than Guix 1.5
    ;; provides.  MCP 1.12.4 only requires sse-starlette >= 1.6.1.
    (version "2.1.3")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "https://files.pythonhosted.org/packages/72/fc/"
             "56ab9f116b2133521f532fce8d03194cf04dcac25f583cf3d839be4c0496/"
             "sse_starlette-2.1.3.tar.gz"))
       (sha256
        (base32 "0sbi04713z9l2jrgjg1vrqlrazs82isfwn157m743q8rafrpxllw"))))
    (build-system pyproject-build-system)
    (arguments
     (list #:tests? #f)) ;Tests require unavailable ASGI test dependencies.
    (native-inputs
     (list python-pdm-backend))
    (propagated-inputs
     (list python-anyio python-starlette python-uvicorn))
    (synopsis "Server-Sent Event plugin for Starlette")
    (description
     "SSE-Starlette provides Server-Sent Event responses for Starlette
applications.")
    (home-page "https://github.com/sysid/sse-starlette")
    (license license:bsd-3)))

(define-public python-mcp
  (package
    (name "python-mcp")
    ;; This is the highest MCP SDK release compatible with Guix's Pydantic 2
    ;; package.  The project accepts any MCP SDK >= 1.0.0.
    (version "1.12.4")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "https://files.pythonhosted.org/packages/31/88/"
             "f6cb7e7c260cd4b4ce375f2b1614b33ce401f63af0f49f7141a2e9bf0a45/"
             "mcp-1.12.4.tar.gz"))
       (sha256
        (base32 "19ac0czc986pq8h63jmjv1xxqfj91qrmk1mbqfiicn9sk9g5hr87"))))
    (build-system pyproject-build-system)
    (arguments
     (list
      #:tests? #f ;The SDK's suite requires its full development environment.
      #:phases
      #~(modify-phases %standard-phases
          (add-after 'unpack 'remove-dynamic-versioning
            (lambda _
              ;; Guix builds from a source archive without VCS metadata.
              (substitute* "pyproject.toml"
                (("dynamic = \\[\"version\"\\]")
                 (string-append "version = \"" #$version "\""))))))))
    (native-inputs
     (list python-hatchling))
    (propagated-inputs
     (list python-anyio
           python-httpx
           python-httpx-sse
           python-jsonschema
           python-pydantic
           python-pydantic-settings
           python-multipart
           python-sse-starlette
           python-starlette
           python-uvicorn))
    (synopsis "Python implementation of the Model Context Protocol")
    (description
     "This package provides the Python SDK for the Model Context Protocol,
including the FastMCP server interface used by DorXNG MCP.")
    (home-page "https://github.com/modelcontextprotocol/python-sdk")
    (license license:expat)))

(define-public dorxng-mcp
  (package
    (name "dorxng-mcp")
    (version "0.1.0")
    ;; Reuse the channel's independently verified, commit-pinned source.
    (source (package-source htayj-dorxng-mcp-source))
    (build-system pyproject-build-system)
    (arguments
     (list #:test-backend #~'unittest
           #:test-flags #~(list "discover" "-s" "tests")
           #:phases
           #~(modify-phases %standard-phases
               (add-after 'unpack 'make-fastmcp-annotations-concrete
                 (lambda _
                   ;; MCP 1.12 does not resolve postponed annotations when
                   ;; registering tools.  Python 3.11 supports the project's
                   ;; annotation syntax without this future import.  It also
                   ;; needs concrete parameter classes rather than PEP 604
                   ;; unions; the retained None defaults keep them optional.
                   (substitute* "src/dorxng_mcp/server.py"
                     (("from __future__ import annotations") "")
                     (("server_list_file: str \\| None = None")
                      "server_list_file: str = None")
                     (("file_types: list\\[str\\] \\| None = None")
                      "file_types: list = None")))))))
    (native-inputs
     (list python-hatchling))
    (propagated-inputs
     (list python-mcp python-requests python-urllib3))
    (synopsis "MCP server for private DorXNG and SearXNG searches")
    (description
     "DorXNG MCP is a Model Context Protocol server for authorized searches
against private DorXNG or SearXNG instances.  It can perform read-only
searches, store de-duplicated results in a compatible SQLite database, and
return dorking guidance.")
    (home-page "https://github.com/htayj/dorxng-mcp")
    (license license:expat)))
