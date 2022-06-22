#!/usr/bin/env bash

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]:-$0}")" &>/dev/null && pwd 2>/dev/null)"

version=${1:-master}
filter=${2:-giantswarm\\|flux}

echo "Deleting ${version} directory..."
rm -rf "${SCRIPT_DIR:?}/${version}"

echo "Recreating ${version} directory..."
mkdir -p "${version}"

echo "Listing CRDs matching grep filter: \"${filter}\""
crds=$(kubectl get crd | grep "${filter}" | cut -d " " -f1)

echo "Syncing json schemas..."
for crd in ${crds}; do
  echo "Syncing: ${crd}..."

  temp_file=$(mktemp)
  kubectl get crd "${crd}" -o yaml >"${temp_file}"

  singular_name=$(yq .spec.names.singular <"${temp_file}")
  group_part_of_kind_suffix=$(yq .spec.group <"${temp_file}" | grep -v null | cut -d "." -f1)

  temp_file_2=$(mktemp)
  yq -o=j -I=0 ".spec.versions[]" <"${temp_file}" >"${temp_file_2}"

  while read -r api_version; do
    version_name=$(echo "${api_version}" | yq .name -)

    target="${SCRIPT_DIR:?}/${version}/${singular_name}-${group_part_of_kind_suffix}-${version_name}.json"

    echo "Saving version ${version_name} into: ${target}"

    echo "${api_version}" | yq .schema.openAPIV3Schema -P -o json - >"${target}"
  done <"${temp_file_2}"

  rm "${temp_file_2}"
  rm "${temp_file}"
done
