#!/bin/bash
set -euo pipefail

#ANSI Escape Codes for colors to increase contrast of errors
RED="\033[0;31m"
GREEN="\033[0;32m"
BLUE="\033[0;34m"
NC="\033[0m" # No Color

echo -e "${BLUE}Re-running grep checks, but looking in modular_metacorps/...${NC}"

# Run the linters again, but modular metacorps code (features).
sed 's/code\/\*\*\/\*\*.dm/modular_metacorps\/features\/\*\*\/\*\*.dm/g' <tools/ci/check_grep.sh | bash

echo -e "${BLUE}Re-running grep checks, but looking in modular_metacorps/master_files/...${NC}"

# Run the linters again, but modular metacorps code (tweaks).
sed 's/code\/\*\*\/\*\*.dm/modular_metacorps\/tweaks\/\*\*\/\*\*.dm/g' <tools/ci/check_grep.sh | bash

# Run the linters again, but modular metacorps code (reverts).
sed 's/code\/\*\*\/\*\*.dm/modular_metacorps\/reverts\/\*\*\/\*\*.dm/g' <tools/ci/check_grep.sh | bash
