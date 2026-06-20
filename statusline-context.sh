#!/usr/bin/env bash
# Claude Code status line — context window + rate limits

input=$(cat)

used=$(echo "$input" | jq -r '.context_window.used_percentage // empty')

BAR_WIDTH=12

make_bar() {
  local pct="${1:-0}"
  local filled=$(( (pct * BAR_WIDTH + 50) / 100 ))
  [ "$filled" -gt "$BAR_WIDTH" ] && filled=$BAR_WIDTH
  local empty=$(( BAR_WIDTH - filled ))
  local bar=""
  local i=0
  while [ $i -lt $filled ]; do bar="${bar}█"; i=$(( i + 1 )); done
  i=0
  while [ $i -lt $empty ]; do bar="${bar}░"; i=$(( i + 1 )); done
  echo "$bar"
}

# --- Barre de contexte utilisé ---
ctx_part=""
if [ -n "$used" ]; then
  used_int=$(printf "%.0f" "$used")
  used_bar=$(make_bar "$used_int")
  ctx_part="Ctx: ${used_bar} ${used_int}%"
fi

# --- Rate limits 5h ---
rate_part=""
five_pct=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
five_resets=$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at // empty')

if [ -n "$five_pct" ]; then
  five_int=$(printf "%.0f" "$five_pct")
  rate_bar=$(make_bar "$five_int")
  rate_part="5h: ${rate_bar} ${five_int}%"

  # Calcul du temps restant avant reset
  if [ -n "$five_resets" ] && [ "$five_resets" != "null" ]; then
    now=$(date +%s)
    diff=$(( five_resets - now ))
    if [ "$diff" -gt 0 ]; then
      mins=$(( diff / 60 ))
      secs=$(( diff % 60 ))
      rate_part="${rate_part} (reset dans ${mins}m ${secs}s)"
    fi
  fi
fi

# --- 7 jours ---
week_part=""
week_pct=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')
if [ -n "$week_pct" ]; then
  week_int=$(printf "%.0f" "$week_pct")
  week_part="7j: ${week_int}%"
fi

# --- Assemblage ---
output=""
[ -n "$ctx_part" ]  && output="${output}${ctx_part}"
[ -n "$rate_part" ] && output="${output}  ${rate_part}"
[ -n "$week_part" ] && output="${output}  ${week_part}"

if [ -z "$output" ]; then
  exit 0
fi

printf "\033[2m%s\033[0m" "$output"
