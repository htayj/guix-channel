"""Verify the installed real OCR result, not a serializer success marker."""
from difflib import SequenceMatcher
import hashlib
from html.parser import HTMLParser
import json
from pathlib import Path
import sys

fixture, work = map(Path, sys.argv[1:])
expected_hashes = {
    "000236.png": "36f1dfbb212e6b82eb15e0c5e1d761a5a1aec6c4d580a7518673fd441dc56a34",
    "000236.gt.txt": "4cf0b6fa0dd3f46039ad5214dc1af87ca5b6b0ae2189f68df83d76d342c09f55",
    "overfit.mlmodel": "90c653eda7fb4cf3795cf9610147a74656b7ad52340d5cebb76e7a13765a645e",
}
for name, digest in expected_hashes.items():
    assert hashlib.sha256((fixture / name).read_bytes()).hexdigest() == digest, name


def normalize(text):
    return " ".join(text.split())


prediction = normalize((work / "recognized.txt").read_text(encoding="utf-8"))
truth = normalize((fixture / "000236.gt.txt").read_text(encoding="utf-8"))
# The pinned upstream test_mm_rpred_bbox_nobidi uses these exact weights/image,
# full-image bbox, padding=16 and bidi_reordering=False.  The CLI is invoked
# explicitly with the same settings.  test_simple_bbox_rpred is NOT equivalent:
# its positional True is padding=1, not bidi_reordering=True.
# Keep ground-truth quality visible; this is an execution fixture, not a useful
# production Syriac recognition model or an accuracy benchmark.
reference = "ܕܗܣܐܕ ܪܝ .ܡܡ ܐܠܠ ܗܠ ܐܘܗ ܟܘܗܢ ܡܡ ܐܠ"
similarity = SequenceMatcher(None, prediction, reference).ratio()
ground_truth_similarity = max(SequenceMatcher(None, prediction, truth).ratio(),
                              SequenceMatcher(None, prediction[::-1], truth).ratio())
assert prediction == reference, (prediction, reference, similarity)


class HOCRConsumer(HTMLParser):
    def __init__(self):
        super().__init__()
        self.pages = 0
        self.words = []
        self.boxes = []
        self.word_depth = 0

    def handle_starttag(self, tag, attrs):
        attributes = dict(attrs)
        classes = attributes.get("class", "").split()
        if "ocr_page" in classes:
            self.pages += 1
            box = attributes.get("title", "").split(";", 1)[0].split()
            assert box == ["bbox", "0", "0", "2544", "156"], box
        if "ocrx_word" in classes:
            box = attributes.get("title", "").split(";", 1)[0].split()
            assert len(box) == 5 and box[0] == "bbox", box
            x0, y0, x1, y1 = map(int, box[1:])
            assert 0 <= x0 <= x1 <= 2544 and 0 <= y0 <= y1 <= 156, box
            self.boxes.append([x0, y0, x1, y1])
            self.word_depth = 1
        elif self.word_depth:
            self.word_depth += 1

    def handle_endtag(self, tag):
        if self.word_depth:
            self.word_depth -= 1

    def handle_data(self, data):
        if self.word_depth:
            self.words.append(data)


hocr = HOCRConsumer()
hocr.feed((work / "output.hocr").read_text(encoding="utf-8"))
assert hocr.pages == 1, hocr.pages
assert normalize(" ".join(hocr.words)) == prediction, (hocr.words, prediction)
help_text = (work / "ketos-help.txt").read_text(encoding="utf-8")
assert all(command in help_text for command in ("train", "test", "segtrain", "compile"))
receipt = {"source_commit": "eff0571e4c8b4930b476ef6af55851c62a938d15",
           "asset_sha256": expected_hashes, "prediction": prediction,
           "ground_truth": truth, "ground_truth_similarity": ground_truth_similarity,
           "upstream_bbox_reference": reference, "reference_similarity": similarity,
           "hocr_pages": hocr.pages, "ketos": "command discovery only",
           "hocr_word_boxes": hocr.boxes,
           "boundary": "CPU fixture recognition, not production model accuracy/training"}
(work / "consumer.json").write_text(json.dumps(receipt, ensure_ascii=False, indent=2) + "\n",
                                    encoding="utf-8")
print(json.dumps(receipt, ensure_ascii=False))
