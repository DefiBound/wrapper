#!/bin/bash

if [[ "$@" =~ "-h" ]]; then
    sui client call -h  | sed 's/sui client call/test.sh/g'
    exit
fi

out=$(sui client call $@)

if [ $? -eq 0 ]; then
    echo "$out"
else
    echo "$out"
    echo "Error: sui client call failed."
    exit 1
fi

object_ids=$(echo "$out" | sed -n '/Created Objects/,/Mutated Objects/ { /ObjectID:/ {s/ObjectID: //p} }'| awk '{print $3}')

echo ""
echo "──────────────────────────────────────────────────────────────────────────────────────────────────────────────────"
echo ""


echo "Package Created Objects:"
echo "$object_ids"

echo ""
echo "──────────────────────────────────────────────────────────────────────────────────────────────────────────────────"
echo ""

owner_addresses=$(echo "$out" | sed -n '/Balance Changes/,/Owner: Account Address/ {s/.*(\(.*\) )/\1/p}'|awk '{print $1}')
echo "Package Caller Addresses:"
echo "$owner_addresses"

echo ""
echo "──────────────────────────────────────────────────────────────────────────────────────────────────────────────────"
echo ""
