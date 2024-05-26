#!/bin/bash

# 执行 sui client call 命令并捕获输出
out=$(sui client publish --skip-dependency-verification --skip-fetch-latest-git-deps)

if [ $? -eq 0 ]; then
    # 打印命令输出
    echo "$out"
else
    # 打印命令输出
    echo "$out"
    # 命令执行失败，输出错误信息并退出脚本
    echo "Error: sui client publish failed."
    exit 1
fi

# 使用 sed 来提取 PackageID
package_id=$(echo "$out"| sed -n '/Published Objects/,/Version/ s/.*PackageID: //p' )

echo ""
echo "──────────────────────────────────────────────────────────────────────────────────────────────────────────────────"
echo ""

echo "PackageID:"
echo "$package_id"

echo ""
echo "──────────────────────────────────────────────────────────────────────────────────────────────────────────────────"
echo ""