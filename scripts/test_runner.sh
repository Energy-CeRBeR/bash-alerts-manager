#!/bin/bash

# Alert Manager Test Runner
# ========================
# Comprehensive testing script for Alert Manager

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

print_test_header() {
    echo -e "${BLUE}[TEST]${NC} $1"
}

print_test_pass() {
    echo -e "${GREEN}[PASS]${NC} $1"
    ((TESTS_PASSED++))
}

print_test_fail() {
    echo -e "${RED}[FAIL]${NC} $1"
    ((TESTS_FAILED++))
}

run_test() {
    local test_name="$1"
    local test_command="$2"
    
    ((TESTS_RUN++))
    print_test_header "$test_name"
    
    if eval "$test_command" &>/dev/null; then
        print_test_pass "$test_name"
        return 0
    else
        print_test_fail "$test_name"
        return 1
    fi
}

# Test configuration file
test_config_file() {
    run_test "Configuration file exists" "[[ -f '$PROJECT_DIR/alert-manager.conf' ]]"
    run_test "Configuration file is readable" "[[ -r '$PROJECT_DIR/alert-manager.conf' ]]"
    run_test "Configuration loads without errors" "source '$PROJECT_DIR/alert-manager.conf'"
}

# Test script files
test_script_files() {
    local scripts=(
        "alert-manager.sh"
        "scripts/alert-manager.sh"
        "scripts/utils/logger.sh"
        "scripts/utils/config_parser.sh"
        "scripts/observability/cpu_monitor.sh"
        "scripts/observability/ram_monitor.sh"
        "scripts/observability/disk_monitor.sh"
        "scripts/observability/process_monitor.sh"
        "scripts/alerts/file_alert.sh"
    )
    
    for script in "${scripts[@]}"; do
        run_test "Script exists: $script" "[[ -f '$PROJECT_DIR/$script' ]]"
        run_test "Script is executable: $script" "[[ -x '$PROJECT_DIR/$script' ]]"
    done
}

# Test dependencies
test_dependencies() {
    local deps=(bc ps free df top uptime)
    
    for dep in "${deps[@]}"; do
        run_test "Dependency available: $dep" "command -v $dep"
    done
}

# Test monitoring functions
test_monitoring() {
    # Source required files
    source "$PROJECT_DIR/alert-manager.conf"
    source "$SCRIPT_DIR/utils/logger.sh"
    
    # Initialize logger for testing
    init_logger "/tmp/test_alerts.log"
    
    run_test "CPU monitoring script runs" "$SCRIPT_DIR/observability/cpu_monitor.sh 99"
    run_test "RAM monitoring script runs" "$SCRIPT_DIR/observability/ram_monitor.sh 99"
    run_test "Disk monitoring script runs" "$SCRIPT_DIR/observability/disk_monitor.sh 99 /"
    run_test "Process monitoring script runs" "$SCRIPT_DIR/observability/process_monitor.sh 9999"
}

# Test alert system
test_alert_system() {
    local test_log="/tmp/test_alert_system.log"
    
    # Initialize logger
    source "$SCRIPT_DIR/utils/logger.sh"
    init_logger "$test_log"
    
    # Test alert generation
    log_alert "TEST_ALERT" "50%" "40%" "This is a test alert"
    
    run_test "Alert written to log file" "[[ -f '$test_log' ]]"
    run_test "Alert contains correct format" "grep -q '🚨 ALERT TRIGGERED 🚨' '$test_log'"
    run_test "Alert contains test data" "grep -q 'TEST_ALERT' '$test_log'"
    
    # Cleanup
    rm -f "$test_log"
}

# Test main script functionality
test_main_script() {
    run_test "Main script shows help" "$PROJECT_DIR/alert-manager.sh help"
    run_test "Main script shows status" "$PROJECT_DIR/alert-manager.sh status"
}

# Performance test
test_performance() {
    print_test_header "Performance test - measuring execution time"
    
    local start_time=$(date +%s.%N)
    "$PROJECT_DIR/alert-manager.sh" run &>/dev/null || true
    local end_time=$(date +%s.%N)
    
    local execution_time=$(echo "$end_time - $start_time" | bc)
    local max_time=30.0  # 30 seconds max
    
    if (( $(echo "$execution_time < $max_time" | bc -l) )); then
        print_test_pass "Performance test (${execution_time}s < ${max_time}s)"
        ((TESTS_PASSED++))
    else
        print_test_fail "Performance test (${execution_time}s >= ${max_time}s)"
        ((TESTS_FAILED++))
    fi
    
    ((TESTS_RUN++))
}

# Generate test report
generate_report() {
    echo ""
    echo "Test Report"
    echo "==========="
    echo "Tests Run: $TESTS_RUN"
    echo "Tests Passed: $TESTS_PASSED"
    echo "Tests Failed: $TESTS_FAILED"
    echo ""
    
    if [[ $TESTS_FAILED -eq 0 ]]; then
        echo -e "${GREEN}All tests passed! ✅${NC}"
        return 0
    else
        echo -e "${RED}Some tests failed! ❌${NC}"
        return 1
    fi
}

# Main test function
main() {
    echo "Alert Manager Test Suite"
    echo "======================="
    echo ""
    
    # Run test suites
    test_config_file
    test_script_files
    test_dependencies
    test_monitoring
    test_alert_system
    test_main_script
    test_performance
    
    # Generate report
    generate_report
}

main "$@"
