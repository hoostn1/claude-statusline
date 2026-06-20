#!/usr/bin/env bash
# Claude Code status line — context window + session + weekly rate limits

input=$(cat)
BAR_WIDTH=10

make_bar() {
  local pct="${1:-0}"
  local filled=$(( (pct * BAR_WIDTH + 50) / 100 ))
  [ "$filled" -gt "$BAR_WIDTH" ] && filled=$BAR_WIDTH
  local empty=$(( BAR_WIDTH - filled ))
  local bar="" i=0
  while [ $i -lt $filled ]; do bar="${bar}█"; i=$(( i + 1 )); done
  i=0
  while [ $i -lt $empty ]; do bar="${bar}░"; i=$(( i + 1 )); done
  echo "$bar"
}

format_reset() {
  local resets_at="$1"
  [ -z "$resets_at" ] || [ "$resets_at" = "null" ] && return
  local now diff mins secs
  now=$(date +%s)
  diff=$(( resets_at - now ))
  [ "$diff" -le 0 ] && echo "reset imminent" && return
  mins=$(( diff / 60 ))
  secs=$(( diff % 60 ))
  if [ "$mins" -ge 60 ]; then
    hours=$(( mins / 60 ))
    mins=$(( mins % 60 ))
    echo "reset ${hours}h${mins}m"
  else
    echo "reset ${mins}m${secs}s"
  fi
}

parts=()

# --- Contexte utilisé ---
used=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
if [ -n "$used" ]; then
  used_int=$(printf "%.0f" "$used")
  bar=$(make_bar "$used_int")
  parts+=("Ctx: ${bar} ${used_int}%")
fi

# --- Limite de session (5h) ---
five_pct=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
five_resets=$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at // empty')
if [ -n "$five_pct" ]; then
  five_int=$(printf "%.0f" "$five_pct")
  bar=$(make_bar "$five_int")
  reset_str=$(format_reset "$five_resets")
  entry="Session: ${bar} ${five_int}%"
  [ -n "$reset_str" ] && entry="${entry} (${reset_str})"
  parts+=("$entry")
fi

# --- Limite hebdomadaire (7j) ---
week_pct=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')
week_resets=$(echo "$input" | jq -r '.rate_limits.seven_day.resets_at // empty')
if [ -n "$week_pct" ]; then
  week_int=$(printf "%.0f" "$week_pct")
  bar=$(make_bar "$week_int")
  reset_str=$(format_reset "$week_resets")
  entry="7j: ${bar} ${week_int}%"
  [ -n "$reset_str" ] && entry="${entry} (${reset_str})"
  parts+=("$entry")
fi

[ ${#parts[@]} -eq 0 ] && exit 0

output=""
for part in "${parts[@]}"; do
  [ -n "$output" ] && output="${output}  │  "
  output="${output}${part}"
done

printf "\033[2m%s\033[0m" "$output"
