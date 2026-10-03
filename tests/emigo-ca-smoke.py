"""Exercise real installed LiteLLM TLS configuration without network I/O."""
import os
import ssl
from pathlib import Path

import litellm
from litellm.llms.custom_httpx.http_handler import get_ssl_configuration

bundle = Path(litellm.__file__).resolve().parents[4] / "share/litellm/ca-certificates.crt"
assert bundle.is_file(), bundle
context = get_ssl_configuration(True)
assert isinstance(context, ssl.SSLContext)
assert context.verify_mode == ssl.CERT_REQUIRED
assert context.check_hostname
assert context.cert_store_stats()["x509_ca"] > 0

# A valid explicit bundle works, but an explicit invalid one must never be
# discarded in favor of the packaged Mozilla fallback.
for variable in ("SSL_CERT_FILE", "REQUESTS_CA_BUNDLE"):
    os.environ[variable] = str(bundle)
    context = get_ssl_configuration(True)
    assert context.verify_mode == ssl.CERT_REQUIRED
    assert context.check_hostname
    os.environ[variable] = "/emigo-smoke-nonexistent-ca-file"
    try:
        get_ssl_configuration(True)
    except FileNotFoundError:
        pass
    else:
        raise AssertionError(f"invalid {variable} silently fell back")
    del os.environ[variable]

try:
    get_ssl_configuration("/emigo-smoke-nonexistent-explicit-ca-file")
except FileNotFoundError:
    pass
else:
    raise AssertionError("invalid explicit ssl_verify path silently fell back")
print("emigo TLS smoke passed: trusted store defaults and fail-closed CA overrides")
