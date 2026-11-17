import json
from pathlib import Path
root = Path(__file__).resolve().parents[1]
manifest = json.loads((root / "mod.json").read_text(encoding="utf-8"))
assert manifest.get("map") == "testing-room_001", "new files must start in the testing hub"
assert "encounter" not in manifest, "the game must not launch a battle on startup"
assert manifest.get("party") == ["kris", "susie", "ralsei", "noelle", "berdly", "vessel"]
map_source = (root / "scripts/world/maps/testing-room_001.lua").read_text(encoding="utf-8")
assert 'script="gaster_dialogue_test"' in map_source, "missing Gaster statue dialogue interactable"
assert (root / "scripts/world/scripts/gaster_dialogue_test.lua").is_file()
for script_id in ("gaster_fight_test", "final_fight_test", "runtime_test"):
    assert f'script="{script_id}"' in map_source
    assert (root / "scripts/world/scripts" / f"{script_id}.lua").is_file()
assert 'Game:encounter("knight_titan_preview")' in (root / "scripts/world/scripts/final_fight_test.lua").read_text()
assert 'Game:encounter("runtime_smoke_test")' in (root / "scripts/world/scripts/runtime_test.lua").read_text()
assert "not been implemented yet" in (root / "scripts/world/scripts/gaster_fight_test.lua").read_text()
encounter = (root / "scripts/battle/encounters/knight_titan_preview.lua").read_text()
assert 'self:addEnemy("roaring_knight_titan")' in encounter and 'self:addEnemy("roaring_knight")' in encounter
assert "knight.ten_shadows_state = titan.ten_shadows_state" in encounter
print("New-file startup opens testing-room_001 with three manual test stations.")
