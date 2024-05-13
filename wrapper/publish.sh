s#!/bin/bash

out=$(sui client publish --gas-budget 5000000000)

if [ $? -eq 0 ]; then
    echo "$out"
else
    echo "$out"
    echo "Error: sui client publish failed."
    exit 1
fi

package_id=$(echo "$out"| sed -n '/Published Objects/,/Version/ { /PackageID:/ {s/PackageID: //p} }'|awk '{print $3}')

echo ""
echo "──────────────────────────────────────────────────────────────────────────────────────────────────────────────────"
echo ""

echo "PackageID:"
echo "$package_id"

echo ""
echo "──────────────────────────────────────────────────────────────────────────────────────────────────────────────────"
echo ""