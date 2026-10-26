#!/bin/sh
# Harpoon-style marks for herdr tabs.
#   harpoon.sh add     mark the focused tab (max 10)
#   harpoon.sh go N    jump to mark N
#   harpoon.sh menu    fzf picker: enter = jump, J/K = move mark, ctrl-d = remove mark
file="${XDG_STATE_HOME:-$HOME/.local/state}/herdr/harpoon"
mkdir -p "$(dirname "$file")"
touch "$file"

notify() { herdr notification show "Harpoon" --body "$1" >/dev/null; }

focus() {
  herdr workspace focus "${1%%:*}" >/dev/null && herdr tab focus "$1" >/dev/null
}

# Drop marks whose tab was closed
prune() {
  herdr tab list | jq -r '.result.tabs[]?.tab_id' > "$file.live"
  # Keep marks if herdr didn't answer
  if [ -s "$file.live" ]; then
    grep -Fxf "$file.live" "$file" > "$file.tmp"
    mv "$file.tmp" "$file"
  fi
  rm -f "$file.live" "$file.tmp"
}

# One line per mark: <tab id> TAB <colored "N  workspace / tab  status">
lines() {
  jq -rn --argjson tabs "$(herdr tab list)" --argjson wss "$(herdr workspace list)" --rawfile marks "$file" '
    def c(code): "\u001b[\(code)m";
    def pad(n): (. + (" " * n))[0:n];
    def status: {
      working: c("33") + "● working",
      blocked: c("31") + "! blocked",
      done:    c("32") + "✓ done",
      idle:    c("90") + "○ idle"
    }[.] // c("90") + "· shell";
    ($marks | split("\n") | map(select(length > 0))) as $m
    | range(0; $m | length) as $i
    | ($tabs.result.tabs[] | select(.tab_id == $m[$i])) as $t
    | ($wss.result.workspaces[] | select(.workspace_id == $t.workspace_id)) as $w
    | "\($t.tab_id)\t\(c("1;34"))\($i + 1)\(c("0"))  \($w.label | pad(18)) \(c("90"))\((if ($t.label // "") == "" then "tab \($t.number)" else $t.label end) | pad(18))\(c("0")) \($t.agent_status | status)\(c("0"))"'
}

prune

case "$1" in
  add)
    id=$(herdr workspace list | jq -r '.result.workspaces[] | select(.focused).active_tab_id')
    [ -z "$id" ] && exit 1
    if n=$(grep -Fxn "$id" "$file" | cut -d: -f1) && [ -n "$n" ]; then
      notify "Already mark $n"
    elif [ "$(wc -l < "$file")" -ge 10 ]; then
      notify "Full (10). Remove one with prefix+y, ctrl-d"
    else
      echo "$id" >> "$file"
      notify "Added as mark $(wc -l < "$file")"
    fi
    ;;
  go)
    id=$(sed -n "${2}p" "$file")
    [ -n "$id" ] && focus "$id"
    ;;
  rm)
    # fzf may pass the field with its trailing tab
    id=$(printf '%s' "$2" | tr -d '\t ')
    sed -i "\|^$id\$|d" "$file"
    ;;
  move)
    # Swap mark $2 with the one above (up) or below (down)
    id=$(printf '%s' "$2" | tr -d '\t ')
    n=$(grep -Fxn "$id" "$file" | cut -d: -f1)
    [ -z "$n" ] && exit 0
    if [ "$3" = up ]; then m=$((n - 1)); else m=$((n + 1)); fi
    awk -v a="$n" -v b="$m" '{ l[NR] = $0 }
      END { if (b < 1 || b > NR) b = a; t = l[a]; l[a] = l[b]; l[b] = t; for (i = 1; i <= NR; i++) print l[i] }' \
      "$file" > "$file.tmp" && mv "$file.tmp" "$file"
    ;;
  lines)
    lines
    ;;
  menu)
    [ -s "$file" ] && header='1-0 jump · enter open · J/K move · ctrl-d remove · esc close' \
      || header='No marks yet. Press prefix+a on a tab to add it.'
    # No search box: number keys 1..0 (and AZERTY &é"'(-è_çà) jump straight to marks 1..10
    pick=$(lines | fzf --ansi --no-input --no-sort --layout=reverse \
      --delimiter='\t' --with-nth=2 \
      --info=hidden --no-scrollbar --padding=1,2 \
      --header="$header" --header-first \
      --pointer='' --gutter=' ' --highlight-line \
      --color='fg:-1,bg:-1,fg+:-1:bold,bg+:236,header:8' \
      --bind='j:down,k:up,q:abort' \
      --bind='1:pos(1)+accept,2:pos(2)+accept,3:pos(3)+accept,4:pos(4)+accept,5:pos(5)+accept' \
      --bind='6:pos(6)+accept,7:pos(7)+accept,8:pos(8)+accept,9:pos(9)+accept,0:pos(10)+accept' \
      --bind='&:pos(1)+accept,é:pos(2)+accept,":pos(3)+accept,'"'"':pos(4)+accept,(:pos(5)+accept' \
      --bind='-:pos(6)+accept,è:pos(7)+accept,_:pos(8)+accept,ç:pos(9)+accept,à:pos(10)+accept' \
      --bind="J:execute-silent($0 move {1} down)+reload-sync($0 lines)+down" \
      --bind="K:execute-silent($0 move {1} up)+reload-sync($0 lines)+up" \
      --bind="shift-down:execute-silent($0 move {1} down)+reload-sync($0 lines)+down" \
      --bind="shift-up:execute-silent($0 move {1} up)+reload-sync($0 lines)+up" \
      --bind="ctrl-d:execute-silent($0 rm {1})+reload($0 lines)")
    [ -n "$pick" ] && focus "$(printf '%s' "$pick" | cut -f1)"
    ;;
esac
