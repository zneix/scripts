#!/usr/bin/env bash
# TODO: https://github.com/naelstrof/maim/issues/193

maim /tmp/xd.png

#feh -x -F /tmp/xd.png &
sxiv -fb /tmp/xd.png &
id=$!

#maim -ls -c 0.9764,0.4509,0.1568,0.17 -b 0.21 /tmp/xd_crop.png && sharenix -n /tmp/xd_crop.png || rm /tmp/xd.png
maim -s /tmp/xd_crop.png && sharenix -n /tmp/xd_crop.png || rm /tmp/xd.png
kill $id
