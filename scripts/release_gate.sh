#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LCOV_PATH="${LCOV_PATH:-$ROOT_DIR/coverage/lcov.info}"
RUN_TESTS="${RUN_TESTS:-1}"
RUN_ANALYZE="${RUN_ANALYZE:-1}"

readonly COVERAGE_TARGETS=(
  "lib/utils/secure_storage.dart|98"
  "lib/utils/session_guard.dart|100"
  "lib/network/network_utils.dart|94"
  "lib/api/auth_apis.dart|90"
  "lib/api/core_apis.dart|88"
  "lib/utils/push_notification_service.dart|92"
  "lib/screens/auth/sign_in_sign_up/sign_in_controller.dart|90"
  "lib/screens/auth/password/change_password_controller.dart|92"
  "lib/screens/auth/profile/edit_user_profile_controller.dart|86"
  "lib/screens/splash_controller.dart|90"
  "lib/screens/clinic/clinic_map_controller.dart|90"
  "lib/network/location_service.dart|92"
  "lib/network/map_screen.dart|86"
  "lib/screens/slots/components/appointment_summary_comp.dart|86"
  "lib/screens/incident_management/incident_management_controller.dart|90"
  "lib/screens/home/home_controller.dart|86"
  "lib/screens/booking/appointment_detail_controller.dart|86"
  "lib/utils/local_storage.dart|100"
  "lib/main.dart|82"
)

readonly CRITICAL_BUNDLE=(
  "lib/utils/secure_storage.dart"
  "lib/utils/session_guard.dart"
  "lib/network/network_utils.dart"
  "lib/api/auth_apis.dart"
  "lib/api/core_apis.dart"
  "lib/utils/push_notification_service.dart"
)

LCOV_SUMMARY_FILE=""

fail() {
  echo "[RELEASE GATE] FAIL: $1"
  exit 1
}

cleanup() {
  if [[ -n "$LCOV_SUMMARY_FILE" && -f "$LCOV_SUMMARY_FILE" ]]; then
    rm -f "$LCOV_SUMMARY_FILE"
  fi
}

trap cleanup EXIT

compute_percent() {
  local hit="$1"
  local total="$2"
  awk -v h="$hit" -v t="$total" 'BEGIN { if (t == 0) printf "0.00"; else printf "%.2f", (h * 100) / t }'
}

percentage_at_least() {
  local actual="$1"
  local expected="$2"
  awk -v a="$actual" -v e="$expected" 'BEGIN { exit !(a + 0 >= e + 0) }'
}

lookup_counts() {
  local file="$1"

  awk -F'|' -v target="$file" '
    $1 == target {
      print $2 " " $3
      found = 1
      exit
    }
    END {
      if (!found) print "0 0"
    }
  ' "$LCOV_SUMMARY_FILE"
}

run_flutter_tests() {
  echo "[RELEASE GATE] Running flutter tests with coverage"
  (
    cd "$ROOT_DIR"
    flutter test --coverage
  ) || fail "Test suite pass rate gate failed (flutter test --coverage)."
}

run_flutter_analyze() {
  local analyze_log
  analyze_log="$(mktemp)"

  echo "[RELEASE GATE] Running flutter analyze"
  if ! (
    cd "$ROOT_DIR"
    flutter analyze
  ) >"$analyze_log" 2>&1; then
    cat "$analyze_log"
    rm -f "$analyze_log"
    fail "Static analysis gate failed (flutter analyze returned non-zero)."
  fi

  local warning_count
  warning_count="$( (grep -Ei "warning[[:space:]]+[•-]" "$analyze_log" || true) | wc -l | tr -d ' ' )"
  local error_count
  error_count="$( (grep -Ei "error[[:space:]]+[•-]" "$analyze_log" || true) | wc -l | tr -d ' ' )"

  rm -f "$analyze_log"

  if (( error_count > 0 )); then
    fail "Static analysis gate failed (errors detected: $error_count)."
  fi

  if (( warning_count > 0 )); then
    fail "Static analysis gate failed (high-severity warning policy violated: $warning_count warnings)."
  fi
}

parse_lcov() {
  [[ -f "$LCOV_PATH" ]] || fail "Coverage file not found at $LCOV_PATH"

  LCOV_SUMMARY_FILE="$(mktemp)"

  awk -v root="$ROOT_DIR" '
    function normalize(path, idx) {
      gsub(/\\/, "/", path)

      if (index(path, root "/") == 1) {
        return substr(path, length(root) + 2)
      }

      idx = index(path, "/lib/")
      if (idx > 0) return "lib/" substr(path, idx + 5)

      idx = index(path, "/android/")
      if (idx > 0) return "android/" substr(path, idx + 9)

      idx = index(path, "/ios/")
      if (idx > 0) return "ios/" substr(path, idx + 5)

      return path
    }

    /^SF:/ {
      current_file = normalize(substr($0, 4))
      next
    }

    /^DA:/ && current_file != "" {
      split(substr($0, 4), parts, ",")
      total[current_file] += 1
      if ((parts[2] + 0) > 0) {
        hit[current_file] += 1
      }
      next
    }

    END {
      for (f in total) {
        printf "%s|%d|%d\n", f, (hit[f] + 0), (total[f] + 0)
      }
    }
  ' "$LCOV_PATH" >"$LCOV_SUMMARY_FILE"
}

enforce_per_file_coverage() {
  echo "[RELEASE GATE] Enforcing per-file coverage targets"
  for entry in "${COVERAGE_TARGETS[@]}"; do
    local file="${entry%|*}"
    local target
    target="${entry##*|}"
    local hit
    local total
    read -r hit total <<<"$(lookup_counts "$file")"
    local actual
    actual="$(compute_percent "$hit" "$total")"

    if ! percentage_at_least "$actual" "$target"; then
      fail "Per-file coverage gate failed for $file (actual ${actual}% < target ${target}%)."
    fi

    echo "[RELEASE GATE] PASS $file (${actual}% >= ${target}%)"
  done
}

enforce_critical_bundle_average() {
  local total=0
  local hit=0

  for file in "${CRITICAL_BUNDLE[@]}"; do
    local file_hit
    local file_total
    read -r file_hit file_total <<<"$(lookup_counts "$file")"
    total=$(( total + file_total ))
    hit=$(( hit + file_hit ))
  done

  local avg
  avg="$(compute_percent "$hit" "$total")"

  if ! percentage_at_least "$avg" "90"; then
    fail "Critical bundle weighted average gate failed (actual ${avg}% < target 90%)."
  fi

  echo "[RELEASE GATE] PASS critical weighted average (${avg}% >= 90%)"
}

check_security_regressions() {
  echo "[RELEASE GATE] Running security regression checks"

  local source_scope=()
  source_scope+=("$ROOT_DIR/lib")
  source_scope+=("$ROOT_DIR/android")
  source_scope+=("$ROOT_DIR/ios")

  local hardcoded_keys
  hardcoded_keys="$(
    grep -RInE \
      -e 'AIza[0-9A-Za-z_-]{35}' \
      -e 'sk_live_[0-9A-Za-z]+' \
      -e 'AKIA[0-9A-Z]{16}' \
      -e '-----BEGIN (RSA|EC|OPENSSH|PRIVATE) KEY-----' \
      --exclude-dir=Pods \
      --exclude-dir=build \
      --exclude-dir=.dart_tool \
      --exclude='*.g.dart' \
      "${source_scope[@]}" || true
  )"

  if [[ -n "$hardcoded_keys" ]]; then
    echo "$hardcoded_keys"
    fail "Security regression gate failed (hardcoded key material detected)."
  fi

  local sensitive_logs
  sensitive_logs="$(
    grep -RInE \
      -e '(print|debugPrint|log)[[:space:]]*\(.*(token|password|authorization|bearer|cookie|otp|secret|cvv|pan)' \
      --exclude-dir=build \
      --exclude-dir=.dart_tool \
      --exclude='*.g.dart' \
      "$ROOT_DIR/lib" || true
  )"

  if [[ -n "$sensitive_logs" ]]; then
    echo "$sensitive_logs"
    fail "Security regression gate failed (sensitive payload log usage detected)."
  fi

  echo "[RELEASE GATE] PASS security regression checks"
}

check_native_policy_placeholders() {
  echo "[RELEASE GATE] Running native policy checks"

  local manifest="$ROOT_DIR/android/app/src/main/AndroidManifest.xml"
  local gradle="$ROOT_DIR/android/app/build.gradle"
  local main_activity="$ROOT_DIR/android/app/src/main/kotlin/com/urclinic/patient/MainActivity.kt"
  local app_delegate="$ROOT_DIR/ios/Runner/AppDelegate.swift"
  local info_plist="$ROOT_DIR/ios/Runner/Info.plist"

  [[ -f "$manifest" ]] || fail "Missing AndroidManifest.xml at $manifest"
  [[ -f "$gradle" ]] || fail "Missing build.gradle at $gradle"
  [[ -f "$main_activity" ]] || fail "Missing MainActivity.kt at $main_activity"
  [[ -f "$app_delegate" ]] || fail "Missing AppDelegate.swift at $app_delegate"
  [[ -f "$info_plist" ]] || fail "Missing Info.plist at $info_plist"

  if grep -q "MANAGE_EXTERNAL_STORAGE" "$manifest"; then
    fail "Android policy gate failed (MANAGE_EXTERNAL_STORAGE should not be present)."
  fi

  grep -q '\${GOOGLE_MAPS_API_KEY}' "$manifest" || fail "Android policy gate failed (GOOGLE_MAPS_API_KEY placeholder missing in manifest)."
  grep -q "manifestPlaceholders" "$gradle" || fail "Android policy gate failed (manifestPlaceholders missing in build.gradle)."
  grep -q "GOOGLE_MAPS_API_KEY" "$gradle" || fail "Android policy gate failed (GOOGLE_MAPS_API_KEY missing in build.gradle placeholders)."
  grep -q "FLAG_SECURE" "$main_activity" || fail "Android behavior gate failed (FLAG_SECURE not found in MainActivity)."

  grep -q "capture" "$app_delegate" || fail "iOS behavior gate failed (capture handling not found in AppDelegate)."
  grep -q "blur" "$app_delegate" || fail "iOS behavior gate failed (privacy overlay handling not found in AppDelegate)."
  grep -q "GOOGLE_MAPS_API_KEY" "$info_plist" || fail "iOS policy gate failed (GOOGLE_MAPS_API_KEY placeholder missing in Info.plist)."
  grep -q "NSCameraUsageDescription" "$info_plist" || fail "iOS policy gate failed (NSCameraUsageDescription missing)."

  echo "[RELEASE GATE] PASS native policy checks"
}

main() {
  if [[ "$RUN_TESTS" == "1" ]]; then
    run_flutter_tests
  else
    echo "[RELEASE GATE] Skipping test execution (RUN_TESTS=$RUN_TESTS)"
  fi

  parse_lcov
  enforce_per_file_coverage
  enforce_critical_bundle_average

  if [[ "$RUN_ANALYZE" == "1" ]]; then
    run_flutter_analyze
  else
    echo "[RELEASE GATE] Skipping static analysis (RUN_ANALYZE=$RUN_ANALYZE)"
  fi

  check_security_regressions
  check_native_policy_placeholders

  echo "[RELEASE GATE] PASS all release gates"
}

main "$@"
