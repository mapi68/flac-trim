# flac-trim

* [Overview](#overview)
* [Installation](#installation)
* [License](#license)

## Overview
<b>FLAC-TRIM is more than a tool to normalize .flac files!</b><br>
1) Normalize to 0dB
2) Preserve all tag of original file
3) Rename file with {ARTIST} - {TITLE}
4) Extract cover
5) Add personalized tag
6) Can convert to .mp3 with LAME

## Installation
```bash
apt update && apt install bc ffmpeg file flac -y
```

Before start script read this and change:


######################## CHANGE ########################
PATH1=/mnt/c/Users/massimo/Desktop/flac ### CHANGE     #
PATH2=/mnt/d/Music/digital/flac ### CHANGE             #
########################################################
#                                                      #
MP3VBR=3 ### CHANGE                                    #
############ MP3 VBR Encoding ############             #
# Average kbit/s | Range kbit/s | OPTION #             #
#       225      |    190-250   |    1   #             #
#       190      |    170-210   |    2   #             #
#       175      |    150-195   |    3   #             #
#       165      |    140-185   |    4   #             #
#       130      |    120-150   |    5   #             #
#       115      |    100-130   |    6   #             #
#       100      |     80-120   |    7   #             #
#        85      |     70-105   |    8   #             #
#        65      |     45-85    |    9   #             #
##########################################             #
#                                                      #
ENCODEDBY="Massimo Bremi DJ" ### CHANGE                #
GENRE="Disco" ### CHANGE                               #
#                                                      #
########################################################


 
## License
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE.md)
