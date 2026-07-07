#!/usr/bin/env bash
for t in gcc cmake make valgrind; do
  if command -v "$t" >/dev/null 2>&1; then
    echo "$t: $(command -v "$t")"
  else
    echo "$t: MISSING"
  fi
done
echo "---cunit---"
if ls /usr/include/CUnit >/dev/null 2>&1; then
  echo "CUnit headers present"
else
  echo "CUnit: MISSING"
fi
