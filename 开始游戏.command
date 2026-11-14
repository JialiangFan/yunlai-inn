#!/bin/bash
# Mac：双击直接开始游戏（需要先把 Godot 4.7 放进「应用程序」文件夹）
cd "$(dirname "$0")"
GODOT="/Applications/Godot.app/Contents/MacOS/Godot"
if [ ! -x "$GODOT" ]; then
  echo "没找到 Godot。请从 https://godotengine.org/download/macos/ 下载 Godot 4.7，"
  echo "解压后把 Godot.app 拖进「应用程序」文件夹，再双击本文件。"
  read -n 1 -s -r -p "按任意键关闭…"
  exit 1
fi
"$GODOT" --path . &
