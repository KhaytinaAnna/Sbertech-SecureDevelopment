#!/bin/bash

CHECKSUM_FILE="dlib_checksums.sha256"

# Использование find и sha256sum для создания контрольных сумм
find ./dlib -type f -print0 | while IFS= read -r -d $'\0' file; do
    sha256sum "$file" >> "$CHECKSUM_FILE"
done

echo "Контрольные суммы SHA256 сохранены в: $CHECKSUM_FILE"
