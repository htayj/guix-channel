# SPDX-License-Identifier: GPL-3.0-or-later
# Executed by real Natron before GUI creation; defer until its event loop runs.
# Menu labels: Gui/Gui.cpp:435-452; native palette/QSS: Gui/Gui20.cpp:237-294.
import hashlib
import json
import os
import traceback
from PySide6 import QtCore, QtGui, QtWidgets

EXPECTED_MENUS = ["File", "Edit", "Layout", "Display", "Render", "Cache", "Help"]


def rgba(image):
    image = image.convertToFormat(QtGui.QImage.Format.Format_RGBA8888)
    return bytes(image.constBits())


def capture():
    try:
        application = QtWidgets.QApplication.instance()
        windows = [w for w in application.topLevelWidgets()
                   if isinstance(w, QtWidgets.QMainWindow) and w.isVisible()
                   and isinstance(w.menuBar(), QtWidgets.QMenuBar)]
        assert len(windows) == 1, "expected exactly one real Natron main window"
        window = windows[0]
        menu = window.menuBar()
        labels = [a.text() for a in menu.actions()]
        assert labels == EXPECTED_MENUS, repr(labels)
        nodes = [node.getPluginID() for node in app.getChildren()]
        assert all(node == "fr.inria.built-in.Viewer" for node in nodes), repr(nodes)
        # Capture live X framebuffer pixels, NOT QWidget.render or a reference UI.
        screenshot = window.screen().grabWindow(int(window.winId())).toImage()
        assert not screenshot.isNull()
        directory = os.environ["NATRON_PROOF_EVIDENCE"]
        assert screenshot.save(directory + "/natron-empty-project.png")
        position = menu.mapTo(window, QtCore.QPoint(0, 0))
        action_rect = menu.actionGeometry(menu.actions()[0])
        native_rect = QtCore.QRect(action_rect)
        native_rect.translate(position)
        native = screenshot.copy(native_rect)
        # Independent Qt font/style reference for the source-defined File label.
        # Only reference pixels are synthesized; native pixels above are from X.
        reference = QtWidgets.QMenuBar()
        reference.setFont(menu.font())
        reference.setPalette(menu.palette())
        reference.setLayoutDirection(menu.layoutDirection())
        for label in EXPECTED_MENUS:
            reference.addMenu(label)
        reference.resize(menu.size())
        reference.ensurePolished()
        expected = reference.grab(action_rect).toImage()
        assert native.size() == expected.size()
        assert rgba(native) == rgba(expected), "native File glyph pixels differ from exact Qt reference"
        assert expected.save(directory + "/file-glyph-reference.png")
        blank = QtWidgets.QMenuBar()
        blank.setFont(menu.font())
        blank.setPalette(menu.palette())
        blank.addMenu("    ")
        blank.resize(menu.size())
        blank.ensurePolished()
        background = blank.grab(action_rect).toImage()
        native_bytes, blank_bytes = rgba(native), rgba(background)
        differences = sum(native_bytes[i:i + 4] != blank_bytes[i:i + 4]
                          for i in range(0, len(native_bytes), 4))
        assert differences > 0, "File glyph is blank"
        receipt = {"menus": labels, "nodes": nodes,
                   "screenshot": "natron-empty-project.png",
                   "dimensions": [screenshot.width(), screenshot.height()],
                   "file_rect": [native_rect.x(), native_rect.y(), native_rect.width(), native_rect.height()],
                   "file_rgba_sha256": hashlib.sha256(native_bytes).hexdigest(),
                   "reference_rgba_sha256": hashlib.sha256(rgba(expected)).hexdigest(),
                   "exact_glyph_match": True, "glyph_pixels": differences,
                   "font": menu.font().toString(), "capture": "QScreen.grabWindow: live X framebuffer",
                   "source": {"revision": "3763d805d7d277d10af10025ae41af677682b3e6",
                              "menus": "Gui/Gui.cpp:435-452",
                              "palette_and_stylesheet": "Gui/Gui20.cpp:237-294"},
                   "close": "app.closeProject()"}
        with open(directory + "/gui.json", "w") as file:
            json.dump(receipt, file, indent=2)
        reference.deleteLater()
        blank.deleteLater()
        assert app.closeProject(), "Natron refused clean empty-project close"
    except BaseException:
        with open(os.environ["NATRON_PROOF_EVIDENCE"] + "/gui.failure", "w") as file:
            file.write(traceback.format_exc())
        QtWidgets.QApplication.exit(1)


QtCore.QTimer.singleShot(5000, capture)
