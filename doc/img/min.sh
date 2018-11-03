#!/bin/sh
echo '' > urlimgs.list
for f in *.png
do
    convert "${f}" -resize "256x"  "min/min_${f}"
    echo "[url=http://archlinux.antavr.ru/aai/${f}][img]http://archlinux.antavr.ru/aai/min/min_${f}[/img][/url]" >> urlimgs.list
    echo '-' >> urlimgs.list
done