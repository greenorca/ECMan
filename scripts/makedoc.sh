#!/bin/bash

# script transforms existing wiki files from md into self contained html files
# put this script in your local clone of https://github.com/greenorca/ECMan.wiki

git pull

dir=help

if [ ! -d $dir ]; then
  mkdir $dir
else
  rm $dir/*.html
fi

for f in *.md; do
  target="$dir/${f//md/html}"
  echo "Working on $target"
  # fix stupid img src's
  sed 's,https://github.com/greenorca/ECMan/blob/master/screenshots_doku,https://github.com/greenorca/ECMan/raw/master/screenshots_doku,g' $f > tmp
  # generate actual html
  pandoc -s tmp -o $target --toc --toc-depth 2 -t html5 --self-contained -c style.css

  echo "Replacing URLs now..."
  # handle odd Umlauts in anchor URLs
  sed -i 's/%C3%BC/ü/g' $target
  # update URLs
  sed -r -i 's|https://github.com/greenorca/ECMan/wiki/([äöü,a-zA-Z-]+)">|\1.html">|g' $target
  # add generation date info
  sed -i "s,</body>,<p><i>Hilfe generiert am $(date +%d.%m.%Y)<i></p></body>,g" $target

done

cp -r $dir ../ECMan/
