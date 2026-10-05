#!/usr/bin/env python3
"""Observe native Medley pixels using its source display fonts, never OCR.

Templates stay in memory; this module neither draws into Medley nor emits an
image. Coordinates refer to the top-left of the unscaled PGM screenshot.

Format evidence: MEDLEYFONTFORMAT WRITE.FONT/READ.CHARSET/WRITE.ITEM;
FILEIO:2862-2876,2910-2925 (big-endian scalar I/O); LLDISPLAY:1522-1539
(bitmap payload), FONT:3170-3188 (advance versus image width). Maiko
src/dsk.c:1999-2015 and src/byteswap.c:31-34 normalize disk pages on
byte-swapped hosts. Raw word blocks and raster words are therefore also
big-endian, not host-endian. src/misc7.c:69-75 places bit 15 at the left
and stores rows top-down. No endian/shape guesses are used.
"""

import hashlib
from pathlib import Path
import struct


class _FontReader:
    def __init__(self, data, path):
        self.data = data
        self.pos = 0
        self.path = path

    def fail(self, message):
        raise ValueError(f'{self.path}: byte {self.pos}: {message}')

    def take(self, count):
        if count < 0 or self.pos + count > len(self.data):
            self.fail('truncated font payload')
        value = self.data[self.pos:self.pos + count]
        self.pos += count
        return value

    def number(self, code):
        return struct.unpack('>' + code, self.take(struct.calcsize('>' + code)))[0]

    def seek(self, position):
        if not 0 <= position < len(self.data):
            self.fail('charset pointer outside file')
        self.pos = position

    def newline(self):
        value = self.take(1)
        if value == b'\r':
            if self.data[self.pos:self.pos + 1] == b'\n':
                self.take(1)
        elif value != b'\n':
            self.fail('missing item newline')

    def printed(self):
        """Read one PRIN2 object, retaining lists rather than interpreting Lisp."""
        start = self.pos
        depth = 0
        quoted = False
        escaped = False
        while self.pos < len(self.data):
            byte = self.data[self.pos]
            if escaped:
                escaped = False
            elif byte == ord('%'):
                escaped = True
            elif byte == ord('"'):
                quoted = not quoted
                if not quoted and depth == 0:
                    self.pos += 1
                    break
            elif not quoted:
                if byte == ord('('):
                    depth += 1
                elif byte == ord(')'):
                    depth -= 1
                    if depth < 0:
                        self.fail('unbalanced printed object')
                    if depth == 0:
                        self.pos += 1
                        break
                elif byte in b' \t\r\n' and depth == 0:
                    break
            self.pos += 1
        if quoted or depth or escaped or self.pos == len(self.data):
            self.fail('unterminated printed object')
        text = self.data[start:self.pos].decode('ascii')
        if text == 'NIL':
            return None
        if text == 'T':
            return True
        if text.startswith('"') and text.endswith('"'):
            return text[1:-1]
        try:
            return int(text)
        except ValueError:
            return text

    def items(self):
        result = {}
        while True:
            label, value = self.item()
            if label == 'STOP':
                return result
            if label in result:
                self.fail(f'duplicate item {label}')
            result[label] = value

    def item(self, expected=None):
        end = self.data.find(b' ', self.pos)
        if end < self.pos or any(c in b'\r\n' for c in self.data[self.pos:end]):
            self.fail('missing item label')
        label = self.take(end - self.pos).decode('ascii')
        self.take(1)
        kind = self.number('B')
        if kind == 0:
            value = self.printed()
        elif kind == 1:
            value = self.number('H')
        elif kind == 5:
            value = self.number('i')
        elif kind == 3:
            count = self.number('i')
            raw = self.take(count * 2)
            value = tuple(word[0] for word in struct.iter_unpack('>H', raw))
        elif kind == 2:
            width, height, bpp = (self.number('H') for _ in range(3))
            if bpp != 1 or width == 0 or height == 0:
                self.fail('expected a nonempty monochrome font bitmap')
            stride = (width + 15) // 16 * 2
            raw = self.take(stride * height)
            rows = tuple(bytes((raw[y * stride + x // 8] >> (7 - x % 8)) & 1
                               for x in range(width)) for y in range(height))
            value = {'width': width, 'height': height, 'rows': rows}
        elif kind in (8, 9, 10):
            value = self.items()
        elif kind == 6:
            count = self.number('i')
            origin, fixed = self.number('B'), self.number('B')
            if count < 0 or fixed not in (0, 1):
                self.fail('invalid pointer array header')
            values = []
            for index in range(origin, origin + count):
                values.append(self.number('i') if fixed else self.item(str(index))[1])
            value = {'origin': origin, 'values': tuple(values)}
        elif kind == 4:
            dimensions = self.printed()
            # Printed dimensions are followed immediately by ELEMENT-TYPE,
            # without a newline (WRITE.ITEM's CLARRAYDATA branch).
            self.item('ELEMENT-TYPE')
            fixed, last = self.number('B'), self.number('i')
            if fixed not in (0, 1) or last < -1:
                self.fail('invalid Common Lisp array header')
            values = tuple(self.number('i') if fixed else self.item(str(index))[1]
                           for index in range(last + 1))
            value = {'dimensions': dimensions, 'values': values}
        else:
            self.fail(f'unsupported font item type {kind} for {label}')
        self.newline()
        if expected is not None and label != expected:
            self.fail(f'expected {expected}, found {label}')
        return label, value


def _load_font(path):
    data = path.read_bytes()
    reader = _FontReader(data, path)
    if reader.take(len(b'Medley font')) != b'Medley font':
        reader.fail('not a Medley font')
    reader.newline()
    if reader.item('VERSION')[1] != '1':
        reader.fail('unsupported font version')
    date = reader.item('DATE')[1]
    reader.item('OTHERFONTPROPS')
    max_charset = reader.item('MAXCHARSET')[1]
    cs_location = reader.number('i')
    properties = reader.items()
    if not isinstance(max_charset, int) or max_charset < 0:
        reader.fail('invalid MAXCHARSET')
    if cs_location < 0:
        reader.seek(-cs_location)
        if reader.number('i') != 0:
            reader.fail('single charset is not charset zero')
        reader.number('B')  # all-other-charsets flag
    else:
        reader.seek(cs_location)
        location = reader.number('i')  # charset zero's vector entry
        if location <= 0:
            reader.fail('charset zero is absent or a slug')
        reader.seek(location)
    if reader.item('CS')[1] != '0':
        reader.fail('charset pointer does not identify charset zero')
    charset = reader.items()
    if 'ICS' in charset:
        reader.fail('indirect charset zero is not a source bitmap')
    for key in ('WIDTHS', 'OFFSETS', 'ASCENT', 'DESCENT', 'BITMAP'):
        if key not in charset:
            reader.fail(f'missing charset geometry {key}')
    widths, offsets = charset['WIDTHS'], charset['OFFSETS']
    image_widths = charset.get('IMAGEWIDTHS', widths)
    bitmap = charset['BITMAP']
    height = charset['ASCENT'] + charset['DESCENT']
    # WRITE.ITEM's default BLOCKNELTS is MAXTHINCHAR + 3 = 258
    # (MEDLEYFONTFORMAT:823-826; LLCHAR:46), not 259.
    if height <= 0 or height > bitmap['height'] or any(len(v) != 258 for v in (widths, offsets, image_widths)):
        reader.fail('inconsistent charset geometry')
    # Native faces here are unkerned. LEFTKERN is a POINTER
    # array (not a raw word vector); FONT:3559-3573 permits pair alists.
    # Fail closed rather than treating those alists as constant offsets.
    if properties.get('FONTHASLEFTKERNS'):
        reader.fail('expected an unkerned native source face')
    glyphs = {}
    for code in range(256):
        offset, width = offsets[code], image_widths[code]
        if offset + width > bitmap['width']:
            reader.fail(f'character {code} extends beyond the bitmap strip')
        # SFFixY blits ASCENT+DESCENT rows from the strip's top, even if
        # the stored strip has additional rows (LLDISPLAY:3133-3160).
        glyphs[code] = tuple(row[offset:offset + width] for row in bitmap['rows'][:height])
    provenance = {'path': str(path), 'sha256': hashlib.sha256(data).hexdigest(),
                  'date': date, 'charset': 0, 'word_order': 'big-endian',
                  'bit_order': 'most-significant-first', 'row_order': 'top-down'}
    return {'name': path.stem, 'provenance': provenance, 'glyphs': glyphs,
            'widths': widths, 'image_widths': image_widths,
            'available': frozenset(code for code in range(256) if offsets[code] != offsets[256]),
            'bitmap_height': bitmap['height'],
            'leftkern': charset.get('LEFTKERN'),
            'ascent': charset['ASCENT'], 'descent': charset['DESCENT'],
            'height': height}


def load_fonts(fonts_dir):
    """Load exact native listener, input and title atlases with provenance.

    FONTPROFILE:190 uses GACHA10 for STANDARD's default/value font;
    WINDOWTITLEFONT inherits MENUFONT (54), HELVETICA10 (214). INPUTFONT
    inherits BOLDFONT (69), HELVETICA10-BRR (198); CMLEXEC:154 selects it
    for user typein. Accept the fonts root or medleydisplayfonts itself.
    Missing faces are skipped; malformed existing faces raise errors.
    """
    directory = Path(fonts_dir)
    if (directory / 'medleydisplayfonts').is_dir():
        directory /= 'medleydisplayfonts'
    names = (tuple(f'GACHA{size}-MRR' for size in ('08', '10', '12'))
             + ('HELVETICA10-MRR', 'HELVETICA10-BRR'))
    return [_load_font(path) for name in names
            if (path := directory / f'{name}.MEDLEYDISPLAYFONT').is_file()]


def read_pgm(path):
    """Read an unscaled 8-bit P2/P5 PGM, preserving every raster byte.

    P5's separator is consumed exactly once (CRLF counts as one), so a first
    pixel equal to whitespace or '#' is not lost as if it were header text.
    """
    data = Path(path).read_bytes()
    position = 0

    def token():
        nonlocal position
        while position < len(data):
            if data[position] in b' \t\r\n\v\f':
                position += 1
            elif data[position] == ord('#'):
                end = data.find(b'\n', position)
                if end < 0:
                    raise ValueError(f'{path}: unterminated PGM comment')
                position = end + 1
            else:
                break
        start = position
        while position < len(data) and data[position] not in b' \t\r\n\v\f#':
            position += 1
        if start == position:
            raise ValueError(f'{path}: truncated PGM header or samples')
        return data[start:position]

    magic = token()
    if magic not in (b'P2', b'P5'):
        raise ValueError(f'{path}: expected a P2 or P5 PGM')
    width, height, maximum = (int(token()) for _ in range(3))
    if width <= 0 or height <= 0 or maximum != 255:
        raise ValueError(f'{path}: expected positive dimensions and maxval 255')
    count = width * height
    if magic == b'P5':
        if position == len(data) or data[position] not in b' \t\r\n\v\f':
            raise ValueError(f'{path}: missing PGM raster separator')
        if data[position:position + 2] == b'\r\n':
            position += 2
        else:
            position += 1
        pixels = data[position:]
        if len(pixels) != count:
            raise ValueError(f'{path}: PGM raster size differs from dimensions')
    else:
        samples = [int(token()) for _ in range(count)]
        if any(not 0 <= value <= 255 for value in samples):
            raise ValueError(f'{path}: PGM sample outside declared range')
        pixels = bytes(samples)
        # No second image or unconsumed sample may silently enter evidence.
        remainder = data[position:].splitlines()
        if any(line.split(b'#', 1)[0].strip() for line in remainder):
            raise ValueError(f'{path}: extra PGM samples')
    return {'width': width, 'height': height,
            'pixels': tuple(pixels[y * width:(y + 1) * width] for y in range(height))}


def _template(font, text):
    codes = [ord(character) for character in text]
    if not codes or any(code >= 256 or code < 32 for code in codes):
        return None
    if any(code not in font['available'] for code in codes):
        return None  # A slug's box cannot identify the requested character.
    positions = []
    advance = 0
    extent = 0
    for code in codes:
        positions.append(advance)
        extent = max(extent, advance + font['image_widths'][code])
        advance += font['widths'][code]
    width = max(advance, extent)
    if width == 0:
        return None
    rows = [bytearray(width) for _ in range(font['height'])]
    # Full imagewidth rectangles overwrite prior rectangles just as REPLACE
    # does. Preserve advance-space and zero/background pixels, not ink masks.
    for code, x in zip(codes, positions):
        for y, source in enumerate(font['glyphs'][code]):
            rows[y][x:x + len(source)] = source
    if not any(any(row) for row in rows):
        return None  # Blank-only queries cannot identify rendered text.
    return tuple(bytes(row) for row in rows)


def find_text(image, fonts, text):
    """Find every exact, full-height source text rectangle in both polarities.

    No scaling, thresholding, antialiasing, cropping, wildcard backgrounds,
    or tolerance is allowed. One differing pixel rejects a candidate. A
    substring can match a longer line; no unrendered word-boundary is assumed.
    Matches retain font identity even when two source atlases are identical.
    """
    matches = []
    pixels = image['pixels']
    for font in fonts:
        template = _template(font, text)
        if template is None:
            continue
        height, width = len(template), len(template[0])
        if width > image['width'] or height > image['height']:
            continue
        anchor = max(range(height), key=lambda y: sum(a != b for a, b in
                     zip(template[y], template[y][1:])))
        for polarity, foreground, background in (('normal', 0, 255), ('inverted', 255, 0)):
            table = bytes(background if value == 0 else foreground for value in range(256))
            expected = tuple(row.translate(table) for row in template)
            for y in range(image['height'] - height + 1):
                row = pixels[y + anchor]
                x = row.find(expected[anchor])
                while x != -1:
                    if x + width <= image['width'] and all(
                            pixels[y + dy][x:x + width] == wanted
                            for dy, wanted in enumerate(expected)):
                        matches.append({'x': x, 'y': y, 'width': width, 'height': height,
                                        'font': font['name'], 'polarity': polarity,
                                        'text': text, 'provenance': font['provenance']})
                    x = row.find(expected[anchor], x + 1)
    return sorted(matches, key=lambda match: (match['y'], match['x'], match['font'], match['polarity']))


def find_repl(image, fonts):
    """Locate the native WINDOW:248-250 Exec title and its existing pane.

    WINDOW:413-414 uses INVERT for titles. Click at the horizontal center of
    that title, 30 screenshot pixels below its top, never at a global guess.
    Return None until such a title and an in-bounds pane click are visible.
    """
    for match in find_text(image, fonts, 'Exec'):
        if match['polarity'] != 'inverted':
            continue
        x, y = match['x'] + match['width'] // 2, match['y'] + 30
        if y >= image['height'] or y <= match['y'] + match['height']:
            continue
        return dict(match, click=[x, y])
    return None
