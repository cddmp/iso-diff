#!/bin/bash

iso_orig="$1"
device="/dev/sr0"
iso_copy=$(mktemp)

function print_and_exit
{
  msg="$1"
  code=$2

  echo "$msg"
  rm -f "$iso_copy"
  exit $code
}

[[ $# < 1 ]] && print_and_exit "Usage: $0 file [device]" 1
[[ -n "$2" && "$2" =~ ^/dev/ ]] && device="$2"

if [[ ! -f "$iso_orig" ]]; then
  print_and_exit "$iso_orig does not exist. Exiting." 1
fi

echo "Creating temporary ISO image from $device (this might take a while)."
if ! dd if="$device" of="$iso_copy" bs=2M; then
  print_and_exit "Trying to create an image of $device failed. Exiting." 1
fi

size_iso_orig=$(stat -c %s "$iso_orig")
size_iso_copy=$(stat -c %s "$iso_copy")
size_diff=$(( "$size_iso_copy" - "$size_iso_orig" ))

echo "Comparing ISO images now..."
if [[ "$size_diff" == "0" ]]; then
  diff "$iso_orig" "$iso_copy" &> /dev/null && print_and_exit "The files are identical." 0
  print_and_exit "The files differ." 1
fi
echo "Found different size."
echo "Calculating hash sums (this might take a while)..."
hash_orig=$(sha256sum "$iso_orig" | cut -d ' ' -f1)
hash_copy_head=$(head -c $(stat -c %s "$iso_orig") "$iso_copy" | sha256sum | cut -d ' ' -f1)
if [[ "$hash_orig" == "$hash_copy_head" ]]; then
  echo "Found matching head."
  hash_tail=$(tail -c "$size_diff" "$iso_copy" | sha256sum | cut -d " " -f 1)
  hash_tail_expected=$(printf '\0%.0s' $(seq "$size_diff") | sha256sum | cut -d " " -f 1)
  [[ "$hash_tail" == "$hash_tail_expected" ]] && print_and_exit "Padding looks right, the files match." 0
  print_and_exit "Padding doesn't look right, the files differ." 1
fi 
print_and_exit "The head doesn't match, the files differ." 1
