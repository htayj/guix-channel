#!/usr/bin/env python2
# SPDX-License-Identifier: GPL-3.0-or-later
"""Exercise the installed Ighalsk Tk UI in an externally isolated home."""

import copy
import hashlib
import json
import os
import pickle
import random
import subprocess
import sys
import time
import traceback
from Tkinter import Tk


def require(condition, message):
    if not condition:
        raise RuntimeError(message)


def snapshot(game):
    model = game.model
    return copy.deepcopy({
        "time_started": model.getTimeStarted(),
        "quest": model.quest.getName(),
        "pc": model.getPC().getCompressed(),
        "level": model.getLevel().getCompressed()})


def summary(state):
    encoded = json.dumps(state, sort_keys=True, separators=(",", ":"))
    return {
        "name": state["pc"]["name"],
        "epithet": state["pc"]["epithet"],
        "position": list(state["pc"]["position"]),
        "quest": state["quest"],
        "dungeon_level": state["level"]["levelNumber"],
        "compressed_state_sha256": hashlib.sha256(encoded).hexdigest()}

def file_digest(filename):
    with open(filename, "rb") as source:
        return hashlib.sha256(source.read()).hexdigest()


def type_text(root, text):
    root.focus_force()
    yield 60
    for character in text:
        keysym = {".": "period", " ": "space"}.get(character, character.lower())
        root.event_generate("<KeyPress>", keysym=keysym,
                            state=1 if character.isupper() else 0, when="now")
        yield 20
    root.event_generate("<KeyPress>", keysym="Return", when="now")
    yield 60


def editor_state_is(editor, expected):
    require(editor.controller.state == expected,
            "Expected editor state %s, got %s" % (expected, editor.controller.state))


def edit_monsters(root, editor, evidence, artifacts, screenshot_program):
    editor_state_is(editor, "selectfiles")
    click(editor, "Load " + evidence["monster_template"])
    yield 60
    editor_state_is(editor, "selectmonsters")
    name = editor.viewer.getCurrentList()[0]
    evidence["monster_name"] = name
    click(editor, "Edit " + name)
    yield 60
    editor_state_is(editor, "editmonster")
    original_hp = editor.controller.monster.getMaxHP()
    evidence["original_monster_hp"] = original_hp
    evidence["edited_monster_hp"] = original_hp + 17
    click(editor, "Edit maxHP")
    yield 60
    editor_state_is(editor, "editvalue")
    for delay in type_text(root, str(evidence["edited_monster_hp"])):
        yield delay
    editor_state_is(editor, "editmonster")
    click(editor, "Save Monster and Return")
    yield 60
    click(editor, "Save Monster Dictionary")
    yield 60
    editor_state_is(editor, "savemonsters")
    for delay in type_text(root, os.path.basename(evidence["monster_saved"])):
        yield delay
    editor_state_is(editor, "selectfiles")
    require(os.path.isfile(evidence["monster_saved"]), "Editor did not save dictionary")


def restore_monsters(root, editor, evidence, artifacts, screenshot_program):
    editor_state_is(editor, "selectfiles")
    require(evidence["monster_saved"] in editor.viewer.getCurrentList(),
            "Fresh editor does not list saved dictionary")
    require(evidence["monster_template"] in editor.viewer.getCurrentList(),
            "Fresh editor lost shipped dictionary")
    click(editor, "Load " + evidence["monster_saved"])
    yield 60
    editor_state_is(editor, "selectmonsters")
    restored = editor.controller.monsterDictionary.createMonster(evidence["monster_name"])
    require(restored.getMaxHP() == evidence["edited_monster_hp"],
            "Saved dictionary did not restore edited monster HP")
    click(editor, "Choose another Monster Dictionary")
    yield 60
    click(editor, "Load " + evidence["monster_template"])
    yield 60
    template = editor.controller.monsterDictionary.createMonster(evidence["monster_name"])
    require(template.getMaxHP() == evidence["original_monster_hp"],
            "Shipped dictionary changed with saved edit")
    evidence["monster_reload_equal"] = True


def level_geometry(editor):
    level = editor.model.getLevel()
    return copy.deepcopy({"size": [level.getXSize(), level.getYSize()],
                          "walls": level.walls,
                          "stairs": level.getCompressedStairs(),
                          "start": level.getStartingPosition().getCompressed()})


def edit_level(root, editor, evidence, artifacts, screenshot_program):
    editor_state_is(editor, "start")
    click(editor, "Load Level")
    yield 60
    editor_state_is(editor, "load")
    click(editor, "Load " + evidence["level_template"])
    yield 60
    editor_state_is(editor, "edit")
    evidence["template_geometry"] = level_geometry(editor)
    wall = editor.model.getLevel().isWallAt(editor.model.position)
    click(editor, "Remove Wall" if wall else "Add Wall")
    yield 60
    evidence["edited_geometry"] = level_geometry(editor)
    require(evidence["edited_geometry"] != evidence["template_geometry"],
            "Editor wall command did not change template geometry")
    # Saving a shipped template's name must make a writable user version,
    # without replacing or hiding the installed template in the load menu.
    click(editor, "Save Level")
    yield 60
    require(os.path.isfile(evidence["level_saved"]), "Editor did not save user level")


def restore_level(root, editor, evidence, artifacts, screenshot_program):
    editor_state_is(editor, "start")
    click(editor, "Load Level")
    yield 60
    files = editor.model.getLoadableFilesList()
    require(evidence["level_saved"] in files, "Fresh editor lost saved level")
    require(evidence["level_template"] in files, "Fresh editor lost TOLD_final template")
    click(editor, "Load " + evidence["level_saved"])
    yield 60
    editor_state_is(editor, "edit")
    require(level_geometry(editor) == evidence["edited_geometry"],
            "Saved level did not restore edited geometry")
    evidence["level_reload_equal"] = True


def restore_template(root, editor, evidence, artifacts, screenshot_program):
    click(editor, "Load Level")
    yield 60
    click(editor, "Load " + evidence["level_template"])
    yield 60
    editor_state_is(editor, "edit")
    require(level_geometry(editor) == evidence["template_geometry"],
            "Shipped template geometry changed after user save")
    evidence["template_preserved"] = True



def state_is(game, expected):
    require(game.controller.stateStack[-1] == expected,
            "Expected UI state %s, got %s" %
            (expected, game.controller.stateStack[-1]))


def click(game, label):
    buttons = [item.button for item in game.controller.listOfButtons.buttons
               if item.text == label]
    require(len(buttons) == 1, "Missing or ambiguous command: " + label)
    require(buttons[0].winfo_ismapped(), "Command is not mapped: " + label)
    buttons[0].invoke()


def continue_messages(game):
    for unused in range(64):
        if game.controller.currentController.state != "waiting":
            return
        click(game, "Continue")
        yield 30
    raise RuntimeError("Message queue did not finish")


def capture(root, filename, artifacts, screenshot_program):
    if artifacts is None or screenshot_program is None:
        return
    root.lift()
    root.update_idletasks()
    require(root.winfo_ismapped(), "Game window is not mapped")
    destination = os.path.join(artifacts, filename)
    process = subprocess.Popen([screenshot_program, "-window",
                                str(root.winfo_id()), destination])
    deadline = time.time() + 10
    try:
        while process.poll() is None:
            require(time.time() < deadline, "Screenshot command timed out")
            yield 50
        require(process.returncode == 0, "Screenshot command failed")
    finally:
        if process.poll() is None:
            process.kill()
            process.wait()
    with open(destination, "rb") as image:
        require(image.read(8) == "\x89PNG\r\n\x1a\n",
                "Screenshot is not a PNG: " + filename)


def play(root, game, evidence, artifacts, screenshot_program):
    state_is(game, "gamechoice")
    click(game, "Create New Hero")
    yield 60
    state_is(game, "epithet")
    click(game, "Mighty")
    yield 60
    state_is(game, "name")
    root.focus_force()
    yield 60
    for character in "GuixHero":
        root.event_generate("<KeyPress>", keysym=character.lower(),
                            state=1 if character.isupper() else 0, when="now")
        yield 30
    root.event_generate("<KeyPress>", keysym="Return", when="now")
    yield 60
    state_is(game, "town")
    require(game.model.getPC().getName() == "GuixHero",
            "Tk name entry did not create GuixHero")
    require(game.model.getPC().getEpithetName() == "Mighty",
            "Epithet selection did not create a Mighty hero")
    for delay in continue_messages(game):
        yield delay
    click(game, "Enter Palace")
    yield 60
    state_is(game, "palace")
    click(game, "Hear More about Quests")
    yield 60
    first_quest = game.model.getQuestNames()[0]
    click(game, "Agree to " + first_quest)
    yield 100
    state_is(game, "level")
    require(game.model.quest.getName() == first_quest,
            "First quest was not selected")
    require(game.model.getLevel().getLevelNumber() == 1,
            "Quest did not enter dungeon level one")
    for delay in continue_messages(game):
        yield delay
    origin = game.model.getPC().getPosition().getCompressed()
    controller = game.controller.currentController
    level = game.model.getLevel()
    position = game.model.getPC().getPosition()
    direction_names = ("North", "East", "South", "West", "Northeast",
                       "Southeast", "Southwest", "Northwest")
    direction_name = None
    for candidate in direction_names:
        destination = position.add(controller.moveDict[candidate])
        if not level.isPositionOutOfBounds(destination) and level.canMoveTo(destination):
            direction_name = candidate
            break
    require(direction_name is not None, "No traversable adjacent dungeon square")
    click(game, "Move " + direction_name)
    yield 100
    state_is(game, "level")
    for delay in continue_messages(game):
        yield delay
    moved = game.model.getPC().getPosition().getCompressed()
    require(origin != moved, "Normal movement command did not change position")
    require(not game.model.isPCDead(), "Hero died during smoke movement")
    evidence["movement"] = {"command": "Move " + direction_name,
                            "from": list(origin), "to": list(moved)}
    evidence["before_state"] = snapshot(game)
    for delay in capture(root, "ighalsk-gameplay.png", artifacts, screenshot_program):
        yield delay
    click(game, "Save Game")
    yield 60
    state_is(game, "save")
    require(os.path.isfile("GuixHero.sav"), "Save command did not create a save")
    with open("GuixHero.sav", "rb") as saved:
        persisted = {"time_started": pickle.load(saved),
                     "quest": pickle.load(saved),
                     "pc": pickle.load(saved), "level": pickle.load(saved)}
        require(saved.read(1) == "", "Unexpected trailing save data")
    require(persisted == evidence["before_state"],
            "Saved compressed state differs from live gameplay")
    evidence["save_observed"] = True
    evidence["saved_bytes"] = os.path.getsize("GuixHero.sav")
    # Saving ends the game.  Close this session at the save confirmation;
    # the next fresh session exercises the ordinary load-game menu.


def restore(root, game, evidence, artifacts, screenshot_program):
    state_is(game, "gamechoice")
    require(game.model.getPC() is None, "Reload must start with a fresh model")
    click(game, "Load Existing Hero")
    yield 60
    state_is(game, "load")
    click(game, "Load GuixHero.sav")
    yield 100
    state_is(game, "level")
    evidence["after_state"] = snapshot(game)
    require(evidence["after_state"] == evidence["before_state"],
            "Reloaded compressed state differs from saved gameplay")
    require(not os.path.exists("GuixHero.sav"), "Load did not consume the save")
    evidence["save_consumed"] = True
    for delay in capture(root, "ighalsk-restored.png", artifacts, screenshot_program):
        yield delay


def run_session(constructor, action, evidence, artifacts, screenshot_program):
    root = Tk()
    iterator = None
    failures = []
    completed = [False]

    def fail(message):
        failures.append(message)
        root.quit()

    def callback_error(kind, value, tb):
        fail("".join(traceback.format_exception(kind, value, tb)))

    root.report_callback_exception = callback_error
    try:
        root.title("Ighalsk: The Labours and Quests of A Hero")
        root.geometry("+20+20")
        game = constructor(root)
        # The upstream command panel is a separate real Tk toplevel.  Keep
        # it clear of the gameplay window captured by ImageMagick.
        game.controller.listOfButtons.topLevelWindow.geometry("+900+20")
        iterator = action(root, game, evidence, artifacts, screenshot_program)

        def advance():
            if failures:
                return
            try:
                delay = next(iterator)
                if not failures:
                    root.after(delay, advance)
            except StopIteration:
                completed[0] = True
                root.quit()
            except Exception:
                fail(traceback.format_exc())

        watchdog = root.after(45000, lambda: fail("Tk smoke session timed out"))
        root.after(100, advance)
        root.mainloop()
        root.after_cancel(watchdog)
        require(not failures, "\n".join(failures))
        require(completed[0], "Tk main loop exited before proof completed")
    finally:
        if iterator is not None:
            iterator.close()
        root.destroy()


def main():
    require(len(sys.argv) == 2, "Usage: ighalsk-smoke.py DATA_PATH")
    data_path = os.path.abspath(sys.argv[1])
    artifacts = os.environ.get("IGHALSK_SMOKE_ARTIFACTS")
    screenshot_program = os.environ.get("IGHALSK_SCREENSHOT_PROGRAM")
    if artifacts is not None:
        require(os.path.isdir(artifacts), "Artifact directory must already exist")
    if screenshot_program is not None:
        require(os.path.isabs(screenshot_program), "Screenshot program must be absolute")
        require(os.path.isfile(screenshot_program), "Screenshot program is missing")
    expected_cwd = os.environ["IGHALSK_STATE_DIR"]
    require(os.path.realpath(os.getcwd()) == os.path.realpath(expected_cwd),
            "Launcher must enter the isolated XDG game directory")
    require(not os.path.exists("GuixHero.sav"), "Smoke home contains an old save")
    sys.path.insert(0, data_path)
    random.seed(698)
    import ighalsk
    evidence = {}
    run_session(ighalsk.Ighalsk, play, evidence, artifacts, screenshot_program)
    run_session(ighalsk.Ighalsk, restore, evidence, artifacts, screenshot_program)
    sys.path.insert(0, os.path.join(data_path, "Editor"))
    import MonsterEditor
    import LevelEditor
    evidence.update({
        "monster_template": os.path.join(data_path, "monsters.txt"),
        "monster_saved": os.path.join(expected_cwd, "GuixHerd.txt"),
        "level_template": os.path.join(data_path, "data", "quests", "TOLD_final.txt"),
        "level_saved": os.path.join(expected_cwd, "data", "quests", "TOLD_final.txt")})
    templates = [evidence["monster_template"], evidence["level_template"]]
    template_digests = [file_digest(path) for path in templates]
    require(not os.path.exists(evidence["monster_saved"]) and
            not os.path.exists(evidence["level_saved"]), "Smoke home contains old editor saves")
    run_session(MonsterEditor.MonsterEditor, edit_monsters, evidence, artifacts, screenshot_program)
    run_session(MonsterEditor.MonsterEditor, restore_monsters, evidence, artifacts, screenshot_program)
    run_session(LevelEditor.LevelEditor, edit_level, evidence, artifacts, screenshot_program)
    run_session(LevelEditor.LevelEditor, restore_level, evidence, artifacts, screenshot_program)
    run_session(LevelEditor.LevelEditor, restore_template, evidence, artifacts, screenshot_program)
    require(template_digests == [file_digest(path) for path in templates],
            "Editor sessions modified installed template bytes")
    proof = {
        "seed": 698,
        "before": summary(evidence["before_state"]),
        "after": summary(evidence["after_state"]),
        "movement": evidence["movement"],
        "save_observed": evidence["save_observed"],
        "save_consumed": evidence["save_consumed"],
        "saved_bytes": evidence["saved_bytes"],
        "compressed_restore_equal": evidence["before_state"] == evidence["after_state"],
        "editors": {"monster_reload_equal": evidence["monster_reload_equal"],
                    "level_reload_equal": evidence["level_reload_equal"],
                    "template_preserved": evidence["template_preserved"],
                    "monster_name": evidence["monster_name"],
                    "original_monster_hp": evidence["original_monster_hp"],
                    "edited_monster_hp": evidence["edited_monster_hp"],
                    "saved_dictionary": os.path.basename(evidence["monster_saved"]),
                    "saved_level": os.path.basename(evidence["level_saved"])},
        "screenshots": (["ighalsk-gameplay.png", "ighalsk-restored.png"]
                        if artifacts is not None and screenshot_program is not None else [])}
    if artifacts is not None and screenshot_program is not None:
        with open(os.path.join(artifacts, "state.json"), "w") as output:
            json.dump(proof, output, sort_keys=True, indent=2)
            output.write("\n")
    print("ighalsk isolated smoke passed")


if __name__ == "__main__":
    main()
