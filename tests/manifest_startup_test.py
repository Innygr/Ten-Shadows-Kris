import json
from pathlib import Path

root = Path(__file__).resolve().parents[1]
manifest = json.loads((root / "mod.json").read_text(encoding="utf-8"))

assert manifest.get("map") == "test_room", "new files must load the known test-room map"
encounter_id = manifest.get("encounter")
assert encounter_id == "knight_titan_preview", (
    "new files must start the Knight + Titan playtest, not the diagnostic smoke test"
)

encounter_path = root / "scripts" / "battle" / "encounters" / f"{encounter_id}.lua"
assert encounter_path.is_file(), f"manifest encounter is missing: {encounter_path}"
encounter = encounter_path.read_text(encoding="utf-8")
assert 'self:addEnemy("roaring_knight_titan")' in encounter, (
    "the manifest encounter must add the shared Knight + Titan enemy"
)

enemy_path = root / "scripts" / "battle" / "enemies" / "roaring_knight_titan.lua"
enemy = enemy_path.read_text(encoding="utf-8")
assert 'self.waves = {"knight_titan_assault"}' in enemy, (
    "the boss must select the dedicated Knight + Titan assault wave"
)
assert "self.max_health = 260" in enemy and "self.health = 260" in enemy
assert "self.disable_mercy = true" in enemy
assert "self.can_freeze = false" in enemy

wave_path = root / "scripts" / "battle" / "waves" / "knight_titan_assault.lua"
wave = wave_path.read_text(encoding="utf-8")
assert 'modRequire("scripts/ten_shadows/attack_wave_patterns")' in wave
assert '"shadow_projectile"' in wave

bullet_path = root / "scripts" / "battle" / "bullets" / "shadow_projectile.lua"
assert bullet_path.is_file(), "the boss wave projectile class must exist"

assert manifest.get("party") == [
    "kris", "susie", "ralsei", "noelle", "berdly", "vessel"
], "the new-file route must keep the six-member party"

print("New-file manifest route starts the Knight + Titan playtest encounter.")
