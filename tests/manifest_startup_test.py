import json
from pathlib import Path
root = Path(__file__).resolve().parents[1]
manifest = json.loads((root / "mod.json").read_text(encoding="utf-8"))
assert manifest.get("map") == "testing-room_001", "new files must start in the testing hub"
assert "encounter" not in manifest, "the game must not launch a battle on startup"
assert manifest.get("party") == ["kris", "susie", "ralsei", "noelle", "berdly", "vessel"]
map_source = (root / "scripts/world/maps/testing-room_001.lua").read_text(encoding="utf-8")
assert 'label="GASTER STATUE"' in map_source, "missing Gaster statue interactable"
assert 'text1_1="* You approach the Gaster statue."' in map_source, "Gaster statue dialogue must use native Interactable text"
assert 'label="FIELD GUIDE"' in map_source, "missing Field Guide interactable"
assert 'text1_1="* FIELD GUIDE"' in map_source, "Field Guide dialogue must use native Interactable text"
assert 'script="gaster_dialogue_test"' not in map_source, "native Interactable text must not start a nested cutscene"
for script_id in ("gaster_fight_test", "final_fight_test", "runtime_test"):
    assert f'script="{script_id}"' in map_source
    assert (root / "scripts/world/scripts" / f"{script_id}.lua").is_file()
assert 'Game:encounter("knight_titan_preview")' in (root / "scripts/world/scripts/final_fight_test.lua").read_text()
assert 'Game:encounter("runtime_smoke_test")' in (root / "scripts/world/scripts/runtime_test.lua").read_text()
assert 'Game:encounter("gaster_secret")' in (root / "scripts/world/scripts/gaster_fight_test.lua").read_text()
gaster = (root / "scripts/battle/encounters/gaster_secret.lua").read_text()
assert 'self:addEnemy("gaster_secret")' in gaster
assert (root / "scripts/battle/enemies/gaster_secret.lua").is_file()
assert (root / "scripts/data/actors/gaster_secret.lua").is_file()
gaster = (root / "scripts/data/actors/gaster_secret.lua").read_text()
assert 'self.path = "enemies/gaster_secret"' in gaster
assert 'self.default = "idle"' in gaster
assert (root / "assets/sprites/enemies/gaster_secret/idle.png").is_file()
party_setup = (root / "mod.lua").read_text()
assert "BattleFormation.partyPosition(i, SCREEN_WIDTH, SCREEN_HEIGHT" in party_setup
assert 'end, {"kris", "vessel"}' in party_setup, "Kris's Idea must consume both Kris and Vessel's turns"
boss_actions = (root / "scripts/ten_shadows/boss_actions.lua").read_text()
assert 'not isStanding(kris_battler) or not isStanding(vessel_battler)' in boss_actions
encounter = (root / "scripts/battle/encounters/knight_titan_preview.lua").read_text()
assert 'self:addEnemy("roaring_knight_titan")' in encounter and 'self:addEnemy("roaring_knight")' in encounter
assert "knight.ten_shadows_state = titan.ten_shadows_state" in encounter
print("New-file startup opens testing-room_001 with three manual test stations.")
