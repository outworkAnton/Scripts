#!/bin/bash

find . -depth -name '*.*' -type f -exec bash -c 'base=${0%.*} ext=${0##*.} a=$base.${ext,,}; [ "$a" != "$0" ] && mv -- "$0" "$a"' {} \;
echo "ИЗМЕНЕНИЕ РАСШИРЕНИЙ ФАЙЛОВ ЗАВЕРШЕНО"
