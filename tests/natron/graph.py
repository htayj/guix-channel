# SPDX-License-Identifier: GPL-3.0-or-later
# Source contract: Engine/PyAppInstance.{h,cpp}, Engine/Project.cpp,
# Documentation/source/devel/PythonReference/NatronEngine/{App,Effect,ChoiceParam}.rst.
import json
import os

app.addFormat("NatronProof 2x2 1")
formats = app.getProjectParam("outputFormat")
options = list(formats.getOptions())
indices = [i for i, option in enumerate(options) if "NatronProof" in str(option)]
assert len(indices) == 1, repr(options)
formats.setValue(indices[0])
frame_range = app.getProjectParam("frameRange")
frame_range.setValue(1, 0)
frame_range.setValue(1, 1)
generator = app.createNode("org.guix.NatronProofGenerator", 1)
writer = app.createNode("org.guix.NatronProofWriter", 1)
assert generator is not None and writer is not None
assert generator.setScriptName("NatronProofGenerator")
assert writer.setScriptName("NatronProofWriter")
assert writer.connectInput(0, generator)
writer.getParam("filename").setValue(os.environ["NATRON_PROOF_OUTPUT"])
with open(os.environ["NATRON_PROOF_GRAPH"], "w") as receipt:
    json.dump({"generator": generator.getPluginID(), "writer": writer.getPluginID(),
               "format": str(options[indices[0]]), "frames": [1, 1],
               "output": os.environ["NATRON_PROOF_OUTPUT"]}, receipt, indent=2)
