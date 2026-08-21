#!/bin/sh
# dev-path — cross-spec contention. A checkpoint: stores nothing, stops nothing,
# and exits 0 unconditionally, on every route: collisions found, no collisions,
# no remote, a failed fetch, not a git repository at all. Every other check in
# dev-path is an exit 1; this one is not, because a contention report that can
# fail is a gate nobody decided to add. Collisions go to stdout, errors to
# stderr, so "prints only collisions" stays true when the fetch fails.
#
# The front matter is the block between the first two --- lines, never the head
# of the file.
#
# The cited-paths check does not run here. An unresolvable touches or depends_on
# value contributes its row like any other: this script reports collisions and
# judges nothing. Slice refuses a dangling value as it writes it, and Build
# records a deviation on an unresolvable touches value at its start.
#
# $2 is the repository's base branch. main is a fallback and not the definition:
# a caller that has resolved the base branch passes it.
REMOTE=${1:-origin}
BASE=${2:-main}

git fetch --prune --quiet "$REMOTE"

T=$(mktemp -d) || exit 0
HERE=$(git branch --show-current)

fm() {            # front matter: the block between the first two --- lines
  awk '/^---$/{n++; next} n==1'
}
listkey() {       # the items of a one-level YAML list under $1
  awk -v k="$1:" '$1==k{t=1;next} /^[a-z_]+:/{t=0} t&&/^[ ]*-[ ]/{sub(/^[ ]*-[ ]+/,"");print}'
}
upstreams() {     # every url: under upstream:
  awk '/^upstream:/{t=1;next} /^[a-z_]+:/{t=0} t&&/url:/{sub(/^.*url:[ ]*/,"");print}'
}
emit() {          # emit <slug> <kind> <value> <ref>
  printf '%s\t%s\t%s\t%s\n' "$1" "$2" "$3" "$4"
}

# --- rule 4: a merged spec is never a neighbour. A spec is merged when its
# directory exists on the base branch, and that is the test — an unmerged branch
# still carries every spec that was on base when it was cut.
git ls-tree -r --name-only "$REMOTE/$BASE" -- dev-path/ \
  | awk -F/ 'NF>1{print $2}' | sort -u > "$T/merged"

# --- the working tree, for the spec being cut right now (it may not be pushed) ---
# This branch's own spec only. Every other spec in the working tree is merged,
# and rule 4 is enumerate by unmerged, not by all.
if [ -n "$HERE" ] && [ -f "dev-path/$HERE/spec.md" ]; then
  fm < "dev-path/$HERE/spec.md" | upstreams \
    | while read -r u; do emit "$HERE" upstream "$u" ""; done >> "$T/rows"
  for sl in "dev-path/$HERE/slices"/*.md; do
    [ -f "$sl" ] || continue
    fm < "$sl" | listkey touches | while read -r p; do emit "$HERE" touches "$p" ""; done >> "$T/rows"
  done
fi

# --- every unmerged spec branch on the remote ---
for b in $(git branch -r --no-merged "$REMOTE/$BASE" --format='%(refname:short)' | grep -v HEAD); do
  [ "$b" = "$REMOTE/$HERE" ] && continue
  for f in $(git ls-tree -r --name-only "$b" -- dev-path/); do
    slug=$(printf '%s' "$f" | awk -F/ '{print $2}')   # rule 5: from the path
    grep -qx "$slug" "$T/merged" && continue
    case "$f" in
      */spec.md)
        git show "$b:$f" | fm | upstreams \
          | while read -r u; do emit "$slug" upstream "$u" "$b"; done >> "$T/rows" ;;
      */slices/*.md)
        git show "$b:$f" | fm | listkey touches \
          | while read -r p; do emit "$slug" touches "$p" "$b"; done >> "$T/rows" ;;
    esac
  done
done

[ -s "$T/rows" ] || { rm -rf "$T"; exit 0; }

# --- a collision is one value under two or more different slugs ---
report() {  # $1 = kind, $2 = heading
  awk -F'\t' -v k="$1" '$2==k{print $3"\t"$1}' "$T/rows" | sort -u > "$T/k"
  cut -f1 "$T/k" | uniq -d > "$T/dupes"
  [ -s "$T/dupes" ] || return 0
  while read -r v; do
    printf '%s %s\n' "$2" "$v"
    awk -F'\t' -v v="$v" '$1==v{print "  "$2}' "$T/k"
    echo
  done < "$T/dupes"
  while read -r v; do awk -F'\t' -v v="$v" '$1==v{print $2}' "$T/k"; done < "$T/dupes" >> "$T/neigh"
}

report touches  "touches:"
report upstream "upstream:"

# --- the neighbours found, with their intents ---
if [ -s "$T/neigh" ]; then
  sort -u "$T/neigh" | grep -vx "$HERE" > "$T/n2"
  if [ -s "$T/n2" ]; then
    echo "in flight:"
    while read -r slug; do
      # rule 5 again: take the ref off a row this slug produced. Never rebuild
      # it from the slug's own name — a renamed branch would silently lose it.
      ref=$(awk -F'\t' -v s="$slug" '$1==s&&$4!=""{print $4; exit}' "$T/rows")
      # the first SENTENCE of ## Intent, which is one hard-wrapped paragraph
      # (section 05) — never the first line, which cuts mid-sentence.
      intent=$(git show "$ref:dev-path/$slug/spec.md" \
        | awk '/^## Intent/{t=1;next} /^## /{if(t)exit} t&&NF{printf "%s ",$0;g=1;next} g{exit}' \
        | sed 's/\. .*$/./; s/  *$//')
      printf '  %s — %s\n' "$slug" "${intent:-(no intent recorded)}"
    done < "$T/n2"
    echo
    echo "A neighbour whose Design has not run holds an intent, not a decision."
  fi
fi

rm -rf "$T"
exit 0
