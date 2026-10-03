#!/usr/bin/env python3
"""Exercise installed tokenizer/query/data and real backend error paths offline."""
import importlib
import os
from pathlib import Path
import sys
import warnings

out = Path(os.environ["EMIGO_SMOKE_OUTPUT"]).resolve()
backend = out / "share/emigo/backend"
root = Path(os.environ["EMIGO_SMOKE_WORKSPACE"])
# Imported code must be the installed package, never the checkout/scratch cwd.
for name in ("emigo", "session", "tools", "repomapper", "llm_worker", "agent"):
    module = importlib.import_module(name)
    assert Path(module.__file__).resolve().parent == backend, (name, module.__file__)

from repomapper import RepoMapper, get_scm_fname
from tools import _resolve_path, _parse_search_replace_blocks
import tiktoken

encoding = tiktoken.get_encoding("cl100k_base")
text = "A local function π with Unicode and whitespace.\n"
assert encoding.decode(encoding.encode(text)) == text
assert Path(get_scm_fname("python")).resolve() == (
    backend / "queries/tree-sitter-languages/python-tags.scm"
).resolve()

with warnings.catch_warnings():
    # A fallback on broken query ABI or missing parser must not pass silently.
    warnings.simplefilter("error")
    mapper = RepoMapper(str(root), force_refresh=True)
    sample = root / "sample.py"
    tags = list(mapper.repo_mapper.get_tags_raw(str(sample), "sample.py"))
    definitions = {tag.name for tag in tags if tag.kind == "def"}
    assert {"NativeWidget", "native_total"} <= definitions, definitions
    rendered = mapper.generate_map()
    assert "sample.py" in rendered and "native_total" in rendered, rendered

assert _resolve_path(str(root), "sample.py") == str((root / "sample.py").resolve())
for path in ("../outside.py", "escape.py"):
    try:
        _resolve_path(str(root), path)
    except ValueError:
        pass
    else:
        raise AssertionError(f"backend tool path accepted escape: {path}")

blocks, error = _parse_search_replace_blocks(
    "<<<<<<< SEARCH\nold value\n=======\nnew value\n>>>>>>> REPLACE"
)
assert blocks == [("old value", "new value")] and error is None, (blocks, error)
blocks, error = _parse_search_replace_blocks("```python\nold value\n```")
assert blocks == [] and error, (blocks, error)
assert "litellm" not in sys.modules, "local operations loaded the provider client"
print("EMIGO_LOCAL_OK: installed modules/tokenizer/query definitions/map/path errors/diff parser")
