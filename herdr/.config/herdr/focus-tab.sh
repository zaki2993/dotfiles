#!/bin/sh
# Focus the Nth tab of the current workspace. Used by the AZERTY prefix+&é"'... keys.
id=$(herdr tab list | jq -r --argjson n "$1" '.result.tabs as $t
  | ($t[] | select(.focused).workspace_id) as $w
  | [$t[] | select(.workspace_id == $w)][$n - 1].tab_id // empty')
[ -n "$id" ] && herdr tab focus "$id"
