#!/usr/bin/env bash
set -euo pipefail

FEEDSTOCK_URL="${FEEDSTOCK_URL:-https://github.com/hobu/openjpeg-feedstock.git}"
BRANCH="${BRANCH:-mco-patch}"
WORKDIR="${WORKDIR:-${PWD}/openjpeg-mco-patch-build}"
FEEDSTOCK_DIR="${WORKDIR}/openjpeg-feedstock"
OUTPUT_DIR="${OUTPUT_DIR:-${WORKDIR}/conda-bld}"
CONDA_BUILD="${CONDA_BUILD:-conda-build}"

usage() {
  cat <<'EOF'
Clone and build hobu/openjpeg-feedstock's mco-patch branch for linux-64.

Environment overrides:
  FEEDSTOCK_URL   Git URL to clone
  BRANCH          Git branch to build
  WORKDIR         Working directory for clone and build output
  OUTPUT_DIR      conda-build output directory
  CONDA_BUILD     conda-build executable name or absolute path

Example:
  ./recipe/build-openjpeg-mco-patch-linux-64.sh
  WORKDIR=/tmp/openjpeg-build ./recipe/build-openjpeg-mco-patch-linux-64.sh
EOF
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

if [[ "$(uname -s)" != "Linux" ]]; then
  echo "error: this script must be run on Linux for a linux-64 build" >&2
  exit 1
fi

case "$(uname -m)" in
  x86_64|amd64)
    ;;
  *)
    echo "error: this script must be run on an x86_64 Linux host" >&2
    exit 1
    ;;
esac

for exe in git "${CONDA_BUILD}"; do
  if ! command -v "${exe}" >/dev/null 2>&1; then
    echo "error: required executable not found: ${exe}" >&2
    exit 1
  fi
done

mkdir -p "${WORKDIR}" "${OUTPUT_DIR}"

if [[ -d "${FEEDSTOCK_DIR}/.git" ]]; then
  echo "Updating existing clone: ${FEEDSTOCK_DIR}"
  if [[ -n "$(git -C "${FEEDSTOCK_DIR}" status --porcelain)" ]]; then
    echo "error: existing clone has local changes: ${FEEDSTOCK_DIR}" >&2
    echo "       set WORKDIR to a new directory or clean the clone before retrying" >&2
    exit 1
  fi
  git -C "${FEEDSTOCK_DIR}" fetch origin "${BRANCH}"
  if git -C "${FEEDSTOCK_DIR}" show-ref --verify --quiet "refs/heads/${BRANCH}"; then
    git -C "${FEEDSTOCK_DIR}" switch "${BRANCH}"
    git -C "${FEEDSTOCK_DIR}" pull --ff-only origin "${BRANCH}"
  else
    git -C "${FEEDSTOCK_DIR}" switch --track "origin/${BRANCH}"
  fi
else
  echo "Cloning ${FEEDSTOCK_URL} branch ${BRANCH} into ${FEEDSTOCK_DIR}"
  git clone --branch "${BRANCH}" --single-branch "${FEEDSTOCK_URL}" "${FEEDSTOCK_DIR}"
fi

cd "${FEEDSTOCK_DIR}"

if [[ ! -f ".ci_support/linux_64_.yaml" ]]; then
  echo "error: expected linux-64 variant file missing: .ci_support/linux_64_.yaml" >&2
  exit 1
fi

echo "Building openjpeg from ${BRANCH} with conda-build"
"${CONDA_BUILD}" recipe \
  --variant-config-files .ci_support/linux_64_.yaml \
  --channel conda-forge \
  --override-channels \
  --no-anaconda-upload \
  --output-folder "${OUTPUT_DIR}"

echo "Build artifacts are in: ${OUTPUT_DIR}"
