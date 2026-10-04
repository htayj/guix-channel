"""Exact source-font pixel decoder for real X captures, never a proof renderer.

Nuklear's Allegro backend uses al_load_font(file, -28, 0) and al_draw_text at
integer coordinates. This module makes transient memory glyph templates with
that same API, then requires full RGB byte equality in captured X11 pixels.
No template is saved as a screenshot, or presented as gameplay evidence.
"""
import ctypes
from pathlib import Path


class Color(ctypes.Structure):
    _fields_ = [(name, ctypes.c_float) for name in ('r', 'g', 'b', 'a')]


class GlyphDecoder:
    def __init__(self, library_root, font_file):
        library_root = Path(library_root)
        self.al = ctypes.CDLL(str(library_root / 'lib/liballegro.so.5.2'), mode=ctypes.RTLD_GLOBAL)
        self.font_addon = ctypes.CDLL(str(library_root / 'lib/liballegro_font.so.5.2'), mode=ctypes.RTLD_GLOBAL)
        self.ttf = ctypes.CDLL(str(library_root / 'lib/liballegro_ttf.so.5.2'), mode=ctypes.RTLD_GLOBAL)
        al = self.al
        al.al_get_allegro_version.restype = ctypes.c_uint
        al.al_install_system.argtypes = [ctypes.c_int, ctypes.c_void_p]
        al.al_install_system.restype = ctypes.c_bool
        al.al_set_new_bitmap_flags.argtypes = [ctypes.c_int]
        al.al_create_bitmap.argtypes = [ctypes.c_int, ctypes.c_int]
        al.al_create_bitmap.restype = ctypes.c_void_p
        al.al_set_target_bitmap.argtypes = [ctypes.c_void_p]
        al.al_clear_to_color.argtypes = [Color]
        al.al_get_pixel.argtypes = [ctypes.c_void_p, ctypes.c_int, ctypes.c_int]
        al.al_get_pixel.restype = Color
        al.al_destroy_bitmap.argtypes = [ctypes.c_void_p]
        self.font_addon.al_init_font_addon.restype = None
        self.ttf.al_init_ttf_addon.restype = ctypes.c_bool
        self.ttf.al_load_ttf_font.argtypes = [ctypes.c_char_p, ctypes.c_int, ctypes.c_int]
        self.ttf.al_load_ttf_font.restype = ctypes.c_void_p
        self.font_addon.al_get_text_width.argtypes = [ctypes.c_void_p, ctypes.c_char_p]
        self.font_addon.al_get_text_width.restype = ctypes.c_int
        self.font_addon.al_get_font_line_height.argtypes = [ctypes.c_void_p]
        self.font_addon.al_get_font_line_height.restype = ctypes.c_int
        self.font_addon.al_draw_text.argtypes = [ctypes.c_void_p, Color, ctypes.c_float,
                                                ctypes.c_float, ctypes.c_int, ctypes.c_char_p]
        self.font_addon.al_destroy_font.argtypes = [ctypes.c_void_p]
        self.font_addon.al_destroy_font.restype = None
        self.ttf.al_shutdown_ttf_addon.restype = None
        self.font_addon.al_shutdown_font_addon.restype = None
        al.al_uninstall_system.restype = None
        if not al.al_install_system(al.al_get_allegro_version(), None):
            raise RuntimeError('cannot initialize source font decoder Allegro')
        self.font = None
        try:
            self.font_addon.al_init_font_addon()
            if not self.ttf.al_init_ttf_addon():
                raise RuntimeError('cannot initialize TTF decoder')
            self.font = self.ttf.al_load_ttf_font(str(font_file).encode(), -28, 0)
            if not self.font:
                raise RuntimeError('cannot load installed source UI font')
        except Exception:
            self.close()
            raise
        self.cache = {}

    def close(self):
        if self.font:
            self.font_addon.al_destroy_font(self.font)
        self.font = None
        self.ttf.al_shutdown_ttf_addon()
        self.font_addon.al_shutdown_font_addon()
        self.al.al_uninstall_system()

    def template(self, text):
        if text in self.cache:
            return self.cache[text]
        encoded = text.encode('ascii')
        width = self.font_addon.al_get_text_width(self.font, encoded) + 8
        height = self.font_addon.al_get_font_line_height(self.font) + 8
        self.al.al_set_new_bitmap_flags(1)  # ALLEGRO_MEMORY_BITMAP
        bitmap = self.al.al_create_bitmap(width, height)
        if not bitmap:
            raise RuntimeError('cannot create memory glyph template')
        try:
            self.al.al_set_target_bitmap(bitmap)
            self.al.al_clear_to_color(Color(0, 0, 0, 1))
            # Pinned Allegro 5.2.7 ttf.c stores premultiplied glyph coverage
            # c,c,c,c in the atlas. White on black preserves the source byte c.
            # Native OpenGL framebuffer rounds tint175*c/255, whereas Allegro's
            # memory pixel writer truncates. Model GL exactly, not with tolerance.
            self.font_addon.al_draw_text(self.font, Color(1, 1, 1, 1),
                                          4, 4, 0, encoded)
            coverage = [[round(self.al.al_get_pixel(bitmap, x, y).r * 255)
                         for x in range(width)] for y in range(height)]
            pixels = [[(value, value, value)
                       for c in row for value in [(175 * c + 127) // 255]]
                      for row in coverage]
            points = [(x, y) for y, row in enumerate(pixels)
                      for x, value in enumerate(row) if value != (0, 0, 0)]
            if not points:
                raise RuntimeError('empty glyph template')
            x0, x1 = min(x for x, y in points), max(x for x, y in points)
            y0, y1 = min(y for x, y in points), max(y for x, y in points)
            rows = [bytes(channel for pixel in pixels[y][x0:x1 + 1] for channel in pixel)
                    for y in range(y0, y1 + 1)]
            self.cache[text] = rows
            return rows
        finally:
            self.al.al_destroy_bitmap(bitmap)

    def match(self, rgb, width, height, text):
        """Require every foreground AND background RGB byte of the whole phrase."""
        if len(rgb) != width * height * 3:
            raise RuntimeError('truncated captured native RGB pixels')
        template = self.template(text)
        tw, th = len(template[0]) // 3, len(template)
        rows = [rgb[y * width * 3:(y + 1) * width * 3] for y in range(height)]
        matches = []
        for y in range(height - th + 1):
            start = 0
            while True:
                byte_x = rows[y].find(template[0], start)
                if byte_x < 0:
                    break
                x = byte_x // 3
                if byte_x % 3 == 0 and x + tw <= width and all(
                        rows[y + dy][byte_x:byte_x + tw * 3] == expected
                        for dy, expected in enumerate(template)):
                    matches.append({'x': x, 'y': y, 'width': tw, 'height': th})
                start = byte_x + 1
        return matches
