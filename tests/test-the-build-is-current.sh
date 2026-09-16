#!/usr/bin/env bash

REPOSITORY="$(cd "$(dirname "$0")/.." && pwd)"
TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

pass=0
fail=0

assert() {
  local label="$1" outcome="$2" detail="$3"
  if [ "$outcome" = "0" ]; then
    printf "  PASS  %s\n" "$label"
    pass=$((pass + 1))
  else
    printf "  FAIL  %s — %s\n" "$label" "$detail"
    fail=$((fail + 1))
  fi
}

printf "Test group: what ships is what the sources build\n"

"$REPOSITORY/build" "$TMPDIR/distributions" "$TMPDIR/INSTALL.md" >/dev/null
assert "the build runs" "$?" "nothing can be shipped from these sources"

diff --recursive --unified "$REPOSITORY/distributions" "$TMPDIR/distributions" > "$TMPDIR/drift"
assert "and every distribution matches it" "$?" \
  "an install would copy something no source says - run ./build"

diff --unified "$REPOSITORY/INSTALL.md" "$TMPDIR/INSTALL.md" > "$TMPDIR/page-drift"
assert "and the install page matches it too" "$?" \
  "the page and the folders say different things - run ./build"

for section in Installing Updating Uninstalling; do
  missing=""
  for folder in "$REPOSITORY"/distributions/*/; do
    grep --quiet --fixed-strings "## $section" "$folder/README.md" || missing="$missing $(basename "$folder")"
  done
  [ -z "$missing" ]
  assert "every distribution has a $section section" "$?" \
    "$missing leaves a reader in that folder with nowhere to go"
done

printf "\nTest group: every folder holds what it declares, and nothing else\n"

DISTRIBUTIONS="$REPOSITORY/distributions.json"

ships() { jq --exit-status --arg product "$1" --arg part "$2" '.[$product].ships | index($part)' "$DISTRIBUTIONS" >/dev/null; }

declared() { jq --raw-output 'to_entries[] | select(.value["same-as"] | not) | .key' "$DISTRIBUTIONS"; }

shares() { jq --raw-output 'to_entries[] | select(.value["same-as"]) | "\(.key) \(.value["same-as"])"' "$DISTRIBUTIONS"; }

for product in $(declared); do
  for part in hooks rules skills commands; do
    case "$part" in
      hooks) file="hooks/load-rules.sh" ;;
      rules) file="rules/reply-shape.md" ;;
      skills) file="skills/reload/SKILL.md" ;;
      commands) file="commands/reload.md" ;;
    esac

    if ships "$product" "$part"; then
      [ -e "$REPOSITORY/distributions/$product/$file" ]
      assert "$product ships $part" "$?" "it declares $part and an install from that folder is missing it"
    else
      [ ! -e "$REPOSITORY/distributions/$product/$part" ]
      assert "$product ships no $part" "$?" \
        "it declares none and the folder holds $part anyway, so an install copies what nothing there reads"
    fi
  done
done

for product in $(declared); do
  [ -d "$REPOSITORY/distributions/$product" ]
  assert "$product has a folder" "$?" "products names it and the build writes nothing"
done

for folder in "$REPOSITORY"/distributions/*/; do
  named="$(basename "$folder")"
  declared | grep --quiet --line-regexp "$named"
  assert "$named is declared in distributions.json" "$?" "the build writes a folder nothing says belongs there"
done

for product in $(declared); do
  grep --quiet --fixed-strings 'Installing' "$REPOSITORY/distributions/$product/README.md"
  assert "$product says how it is installed" "$?" "the folder is there and nothing tells a reader what to do with it"
done

while read -r named shared; do
  [ -n "$named" ] || continue
  [ ! -d "$REPOSITORY/distributions/$named" ]
  assert "$named has no folder of its own" "$?" \
    "it installs from $shared, so a folder of its own is a second copy nothing reads"

  [ -d "$REPOSITORY/distributions/$shared" ]
  assert "and the folder it shares is built" "$?" "$named names $shared and nothing builds it"
done < <(shares)

for folder in $(sed -n 's@.*(distributions/\([a-z-]*\)).*@\1@p' "$REPOSITORY/COMPATIBILITY.md" | sort --unique); do
  [ -d "$REPOSITORY/distributions/$folder" ]
  assert "the compatibility table links a folder that exists: $folder" "$?" \
    "a reader following that row lands nowhere"
done

# A row that says Partial owes the reader the part that is missing.
for folder in $(grep --fixed-strings '| Partial' "$REPOSITORY/COMPATIBILITY.md" \
  | sed -n 's@.*(distributions/\([a-z-]*\)).*@\1@p' | sort --unique); do
  grep --quiet --fixed-strings '## What works' "$REPOSITORY/distributions/$folder/README.md"
  assert "the folder a Partial row links says what works: $folder" "$?" \
    "the table sends a reader there to find out what is missing and the folder never says"
done

for folder in "$REPOSITORY"/distributions/*/; do
  named="$(basename "$folder")"
  [ ! -d "$folder/commands" ] || [ ! -d "$folder/skills" ] || ships "$named" cloud
  assert "$named ships no command that shares a skill name" "$?" \
    "both resolve to unsolicited-text:<name>, the command wins, and it only points back at itself"
done

printf "\nTest group: a client a distribution serves is one it can tell apart\n"

while read -r distribution; do
  while read -r client; do
    [ -s "$REPOSITORY/clients/$client.md" ]
    assert "$distribution can recognise $client" "$?" \
      "the skills branch on a signature that is not written down"

    for folder in installs updates uninstalls reloads settings-steps; do
      [ -s "$REPOSITORY/$folder/$client.md" ]
      assert "and $folder says what $client does" "$?" "the branch for it would be empty"
    done
  done < <(jq --raw-output --arg d "$distribution" '.[$d].serves // [] | .[]' "$DISTRIBUTIONS")
done < <(jq --raw-output 'keys[]' "$DISTRIBUTIONS")

printf "\nTest group: a generated file says so\n"

for generated in "$REPOSITORY"/distributions/*/README.md "$REPOSITORY"/distributions/*/hooks/load-rules.sh \
  "$REPOSITORY"/distributions/*/skills/*/SKILL.md; do
  grep --quiet --fixed-strings 'Generated by' "$generated"
  assert "${generated#$REPOSITORY/} says it is generated" "$?" \
    "a reader edits it, runs the build, and loses the edit"
done

printf "\n%d passed, %d failed\n" "$pass" "$fail"
[ "$fail" -eq 0 ]
