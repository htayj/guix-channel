# SPDX-License-Identifier: GPL-3.0-or-later
# Only fresh proof-local settings; no user settings are read or modified.
# Gui/GuiAppInstance.cpp:304-317 otherwise asks an updates question on first run;
# Settings.cpp:3247-3299 asks to fetch an optional OCIO config. Do not fetch one.
import NatronEngine
from PySide6 import QtCore

settings = NatronEngine.natron.getSettings()
settings.getParam("checkForUpdates").setValue(False)
settings.getParam("startupCheckOCIO").setValue(False)
preferences = QtCore.QSettings("INRIA", "Natron")
preferences.setValue("checkForUpdates", False)
preferences.sync()
