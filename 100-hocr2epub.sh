#!/usr/bin/env bash

set -eu

# dst=$(basename "$0" .sh).epub
dst=.

doc_title="$(head -n1 readme.md | sed 's/^#\s*//')"

if false; then
  scan_resolution=600
else
  source 030-measure-page-size.txt
fi

if [ "$dst" != "." ] && [ -e "$dst" ]; then
  echo "error: output exists: $dst"
  exit 1
fi

# downscale to 300 dpi
scale=$(python -c "print(300 / $scan_resolution)")
scale=1 # dont scale. scaling gives poor quality

args=(
  hocr-to-epub-fxl
  --output "$dst"
)
if [ "$dst" = "." ]; then
  args+=(
    --output-unpacked
  )
fi

doc_modified=$(
  {
    git show -s --format=%cI HEAD
    stat -c%y 090-ocr | sed -E 's/^([0-9-]+) ([0-9:]+)\.[0-9]+ ([+-][0-9]{2})([0-9]{2})$/\1T\2\3:\4/'
  } |
  LANG=C sort |
  tail -n1
)

args+=(
  --scale "$scale"
  # --image-format avif
  --text-format html
  # --doc-title "$doc_title"
  --doc-modified "$doc_modified"
  --doc-title "Endgame, Teil 1"
  --doc-subtitle "Zivilisation als Problem"
  --doc-description ""
  --doc-subject ""
  --doc-date 2008
  --doc-edition 1
  --doc-extent "540 pages"
  --doc-author "Derrick Jensen"
  # --doc-introducer ""
  # --doc-contributor ""
  --doc-translator "Marion Schweizer"
  --doc-translator "Thomas Pfeiffer"
  # --doc-publisher ""
  --doc-language de
  --doc-isbn 9783866121928
  --doc-cover-image 070-deskew/0541.tiff
  --canonical-url-base https://milahu.github.io/endgame-1-zivilisation-als-problem-2008/
  --doc-contents-file contents.md
  --color-image-pages 541,542
)

 printf '>'
for a in "${args[@]}" "$@"; do printf ' %q' "$a"; done
echo ' *-ocr/*.hocr'

"${args[@]}" "$@" *-ocr/*.hocr

if [ "$dst" = "." ]; then
  echo "done ./index.xhtml"
  exit
fi

echo "done $dst"

rm -rf $dst.unzip
mkdir $dst.unzip
cd $dst.unzip
unzip -q ../$dst
cd ..

echo "done $dst.unzip/index.html"
