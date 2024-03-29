#!/bin/bash

#################################################################################
#                   __ _                 _        _                             #
#                  / _| | __ _  ___     | |_ _ __(_)_ __ ___                    #
#                 | |_| |/ _` |/ __|____| __| '__| | '_ ` _ \                   #
#                 |  _| | (_| | (_|_____| |_| |  | | | | | | |                  #
#                 |_| |_|\__,_|\___|     \__|_|  |_|_| |_| |_|                  #
#                                                                               #
#                                                                               #
# MIT License                                                                   #
# Copyright (c) 2019-2022 Massimo Pissarello                                    #
# Permission is hereby granted, free of charge, to any person obtaining a copy  #
# of this software and associated documentation files (the "Software"), to deal #
# in the Software without restriction, including without limitation the rights  #
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell     #
# copies of the Software, and to permit persons to whom the Software is         #
# furnished to do so, subject to the following conditions:                      #
# The above copyright notice and this permission notice shall be included in    #
# all copies or substantial portions of the Software.                           #
#                                                                               #
#################################################################################


FT=flac-trim
EXT=.flac
M3EXT=.mp3
M4EXT=.m4a
OPUSEXT=.opus
ID=tag
IMG=folder
PLF=00-flac_playlist.m3u
PL3=00-mp3_playlist.m3u
PL4=00-m4a_playlist.m3u
PLOP=00-opus_playlist.m3u
SILENCE="silenceremove=1:0:-60dB"
DELAY="adelay=250|250|250|250|250|250"


ffmpeg_flac_norm() {
	echo "RMS Normalization to 0 dB..."
	ffmpeg -i "${FILE}" -af "volume=${DBLEVEL}dB","${SILENCE}","${DELAY}" \
		-metadata:s:v comment="" -metadata:s:v comment="Cover (front)" \
		-sample_fmt s16 $PATHSAVE/"${FILE}" -loglevel error
}

ffmpeg_flac() {
	ffmpeg -i "${FILE}" -af "${SILENCE}","${DELAY}" \
		-metadata:s:v comment="" -metadata:s:v comment="Cover (front)" \
		-sample_fmt s16 $PATHSAVE/"${FILE}" -loglevel error
}

ffmpeg_mp3() {
	ffmpeg -i "${FILE}" -af "volume=${DBLEVEL}dB","${SILENCE}","${DELAY}" \
		-metadata:s:v comment="" -metadata:s:v comment="Cover (front)" \
		-c:a libmp3lame -q:a $mp3vbr $PATHSAVE/"${FILE}"$M3EXT -loglevel error
}

ffmpeg_m4a() {
	ffmpeg -i "${FILE}" -af "volume=${DBLEVEL}dB","${SILENCE}","${DELAY}" \
		-c:v copy -c:a $LIB4 $M4AQ $PATHSAVE/"${FILE}"$M4EXT -loglevel error
}

ffmpeg_opus() {
	ffmpeg -i "${FILE}" -af "volume=${DBLEVEL}dB","${SILENCE}","${DELAY}" \
		-metadata:s:v comment="" -metadata:s:v comment="Cover (front)" $PATHSAVE/"${FILE}" -loglevel error
}

list_song() {
	rm -f *.m3u
	ls -1 | grep $EXT | sed -e 's/.flac//g' > plf
	ls -1 | grep $M3EXT | sed -e 's/.mp3//g' > pl3
	ls -1 | grep $M4EXT | sed -e 's/.m4a//g' > pl4
	ls -1 | grep $OPUSEXT | sed -e 's/.opus//g' > plop
}

bitrate_flac() {
	echo "`ffprobe -i $PATHSAVE/"${FILE}" -v quiet -print_format json -show_format -hide_banner`" > $ID
	BITRATE=`grep bit_rate $ID | awk -F': "' '{print $2}' | cut -d'"' -f1`
	SIZE=`grep size $ID | awk -F': "' '{print $2}' | cut -d'"' -f1`
	echo && echo "Average bitrate of output file is $(($BITRATE/1024)) kBit/s"
	echo $SIZE | awk '{abc=$1/1024/1024; print "Size of output file is " abc " MB"}'
}

script_restart() {
	tput clear
	echo && echo -e '\e[91m'"Something wrong: please check your file(s) or your choose!"
	for i in {4..1}; do
		tput cup 2 $l
		echo -e '\e[0m'"Restarting script in $i seconds..." && echo
		sleep 1
	done
	exec $0
}

export_cover() {
	metaflac --export-picture-to="${PATHIMG}"/"${IMG}" "${FILE}"
	IMGEXT=`file "${PATHIMG}"/"${IMG}" | awk -F': ' '{print $2}' | cut -d' ' -f1 | sed -e 's/\(.*\)/\L\1/'`
	mv "${PATHIMG}"/"${IMG}" "${PATHIMG}"/"${ARTIST} - ${ALBUM} ($YEAR).${IMGEXT}"
}

file_check() {
	echo && echo && echo -e '\e[95m'"Please check if your $EXT file(s) are in $PATHLOAD" && echo
	read -rsn1 -p "................. after press any key to continue ................."
	echo && echo -e '\e[96m'
	if [[ `ls -1 $PATHLOAD | grep $EXT | wc -l` = 0 ]]; then
		script_restart; fi
}

lossy_data() {
	BITRATE=`grep bit_rate $ID | awk -F': "' '{print $2}' | cut -d'"' -f1`
	SIZE=`grep size $ID | awk -F': "' '{print $2}' | cut -d'"' -f1`
	echo && echo "Average bitrate of output file is $(($BITRATE/1024)) kBit/s"
	echo $SIZE | awk '{abc=$1/1024/1024; print "Size of output file is " abc " MB"}'
	echo "Max volume of encoded file is $DBLEVEL dB"
}

compile_ffmpeg() {
	echo && echo && echo -e '\e[95m'"Starting compile ffmpeg... If fails, enable non-free repository" && echo && echo -e '\e[0m' && sleep 3
	sudo apt-get install autoconf automake build-essential ccache libass-dev libfreetype6-dev libgpac-dev libvpx-dev \
		libgnutls28-dev wget libsdl1.2-dev libtheora-dev libtool libva-dev libvdpau-dev libvorbis-dev libx11-dev \
		libfdk-aac-dev libssl-dev libopus-dev libxext-dev libxfixes-dev pkg-config texi2html zlib1g-dev \
		libcrypto++-dev yasm libx264-dev libx265-dev libmp3lame-dev libavcodec-extra -y
	LATEST=`lynx -dump https://www.ffmpeg.org/download.html | grep -m 1 "57. https" | awk -F' ' '{print $2}'`
	cpu=`echo $(grep -c processor /proc/cpuinfo)`
	wget $LATEST
	tar xvf ffmpeg-*.tar.xz && rm ffmpeg-*.tar.xz && cd ffmpeg-*
	./configure --prefix="/usr/local" --enable-gnutls --enable-gpl --enable-libass --enable-libfdk-aac --enable-libfreetype --enable-libmp3lame \
		--enable-libopus --enable-libtheora --enable-libvorbis --enable-libvpx --enable-libx264 --enable-libx265 --enable-nonfree
	sudo make -j$cpu && sudo make install && sudo ldconfig
	cd .. && sudo rm -rf ffmpeg-*
}


if [ ! -f $FT.conf ]; then
	tput clear
	echo && echo -e '\e[91m' "*************	MISSING FILE *************" && echo
	echo && echo && echo "Sorry but without $FT.conf I can't execute $FT" && echo && echo -e '\e[0m' && sleep 1 && exit 1
fi
chmod +x $FT.conf
source $FT.conf

if [ ! -f /usr/bin/bc ] || [ ! -f /usr/bin/file ] || [ ! -f /usr/bin/flac ] || [ ! -f /usr/bin/opusenc ] || [ ! -f /usr/bin/lynx ]; then
	tput clear
	echo && echo -e '\e[91m' "*************	MISSING DEPENDENCIES *************" && echo
	read -p "Do you want to install missing package(s)? (Y/n) " -n 1 -r -s
	if [[ $REPLY =~ ^[Nn]$ ]]; then
		echo && echo && echo "Sorry but without these package I can't execute $FT" && echo && echo -e '\e[0m' && sleep 1 && exit 1
	else
		echo && echo && echo -e '\e[95m'"Starting install dependencies..." && echo && echo -e '\e[0m' && sleep 1
		sudo apt-get update && sudo apt-get upgrade -y && sudo apt-get install bc file flac opus-tools lynx -y
	fi
fi
if [ ! -f /usr/local/bin/ffmpeg ]; then
	tput clear
	echo && echo -e '\e[91m' "*************	MISSING DEPENDENCIES *************" && echo
	echo && read -p "Do you want to compile latest ffpmeg? [Y/n] " -n 1 -r -s
	if [[ $REPLY =~ ^[Nn]$ ]]; then
		echo && echo && echo "Sorry but without ffmpeg I can't execute $FT" && echo && echo -e '\e[0m' && sleep 1 && exit 1
	else
		compile_ffmpeg
	fi
fi

tput clear

echo -e '\e[95m'"          __ _                 _        _ "
echo "         / _| | __ _  ___     | |_ _ __(_)_ __ ___ "
echo "        | |_| |/ _\` |/ __|____| __| '__| | '_ \` _ \ "
echo "        |  _| | (_| | (_|_____| |_| |  | | | | | | | "
echo "        |_| |_|\__,_|\___|     \__|_|  |_|_| |_| |_| "
echo -e '\e[92m'

INSTALLED=`ffmpeg -version | awk -F' ' '{print $3}' | head -1`
echo "             ffmpeg version $INSTALLED is installed"
echo "           Checking for new version of ffmpeg..."
LATEST=`lynx -dump https://www.ffmpeg.org/download.html | grep -m 1 "57. https" | awk -F' ' '{print $2}' | \
	sed 's/.tar.xz//g' | sed 's/https:\/\/www.ffmpeg.org\/releases\/ffmpeg-//g'`
if [[ $INSTALLED == $LATEST ]]; then
	echo -n "           " && echo -e '\e[46m'"   +++ You have latest version +++   " && echo -e '\e[49m'
else
	echo -n "           " && echo -e '\e[44m'"   *** FOUND NEW VERSION $LATEST ***   " && echo -e '\e[49m'
	echo -e '\e[91m' && read -p "   Do you want to upgrade ffpmeg to version $LATEST? [Y/n] " -n 1 -r -s
	if ! [[ $REPLY =~ ^[Nn]$ ]]; then
		echo -e '\e[0m'
		compile_ffmpeg
	fi
	echo && echo
fi

echo -e '\e[96m'"In order for $FT to work properly, your $EXT file(s) must have the tags:"
echo "ALBUM, ARTIST, TITLE, TRACK, YEAR and cover inside in .jpg or .png format" && echo

echo && echo -e '\e[93m'"Please choose the directory where you want to put your $EXT file(s):" && echo
echo "1) $PN1 -----> $PATH1" && echo "2) $PN2 -----> $PATH2" && echo "3) $PN3 -----> $PATH3" && echo
read number
if [ "$number" -ne 1 ] && [ "$number" -ne 2 ] && [ "$number" -ne 3 ]; then
	script_restart
elif [ $number -eq 1 ]; then
	mkdir -p $PATH1/$OR $PATH1/$TR $PATH1/$CO
	PATHLOAD=$PATH1/$OR
	PATHSAVE=$PATH1/$TR
	PATHIMG=$PATH1/$CO
elif [ $number -eq 2 ]; then
	mkdir -p $PATH2/$OR $PATH2/$TR $PATH2/$CO
	PATHLOAD=$PATH2/$OR
	PATHSAVE=$PATH2/$TR
	PATHIMG=$PATH2/$CO
elif [ $number -eq 3 ]; then
	mkdir -p $PATH3/$OR $PATH3/$TR $PATH3/$CO
	PATHLOAD=$PATH3/$OR
	PATHSAVE=$PATH3/$TR
	PATHIMG=$PATH3/$CO
fi
echo && echo
echo "Please choose extension for your trimmed file(s):" && echo
echo "1) FLAC" && echo "2) MP3" && echo "3) M4A" && echo "4) OPUS"
echo "5) I want only to save all covers of $EXT file(s) in $PATHIMG" && echo
read number2
if [ "$number2" -ne 1 ] && [ "$number2" -ne 2 ] && [ "$number2" -ne 3 ] && [ "$number2" -ne 4 ] && [ "$number2" -ne 5 ]; then
	script_restart; fi

n=0
if [ $number2 -eq 5 ]; then
	cd $PATHLOAD
	file_check
	echo -e '\e[96m' && echo "Found" `ls -1 | grep $EXT | wc -l` "file(s) with" $EXT "extension in" $PATHLOAD
	echo -e '\e[0m' && echo && sleep 1
	for FILE in *${EXT}; do
		let n=n+1
		echo "`ffprobe -i "${FILE}" -v quiet -print_format json -show_format -hide_banner`" > $ID
		sed -i -e 's/\\\"//g' -e 's/ \/ / /g' -e 's/\///g' -e "s/''//g" -e 's/\"album\"/\"ALBUM\"/g' -e 's/\"date\"/\"DATE\"/g' $ID
		ARTIST=`grep album_artist $ID | awk -F': "' '{print $2}' | cut -d'"' -f1`
		ALBUM=`grep ALBUM $ID | awk -F': "' '{print $2}' | cut -d'"' -f1`
		YEAR=`grep DATE $ID | awk -F': "' '{print $2}' | cut -d'"' -f1`
		echo "Processing cover file" $n "of" `ls -1 | grep $EXT | wc -l`": ${ARTIST} - ${ALBUM} ($YEAR)"
		export_cover
	done
	rm -f $ID
	echo && echo -e '\e[92m'"********************* ALL DONE! *********************"
	echo -e '\e[0m' && echo
	exit 1
fi
if [ $number2 -eq 3 ]; then
	echo && echo && echo "Please choose AAC encoder:" && echo
	echo "1) AAC (good quality)" && echo "2) AAC (medium quality)"
	echo "3) LIBFDK_AAC (highest quality without cut frequencies)" && echo
	read number5
	if [ "$number5" -ne 1 ] && [ "$number5" -ne 2 ] && [ "$number5" -ne 3 ]; then
		script_restart; fi
	if [ $number5 -eq 3 ]; then
		LIB4=libfdk_aac
		M4AQ="-vbr 5"
	elif [ $number5 -eq 2 ]; then
		LIB4=aac
		M4AQ="-q:a 1.2"
	else
		LIB4=aac
		M4AQ="-q:a 1.5"
	fi
fi
if [ $number2 -eq 1 ]; then
	echo && echo &&	echo "Please choose volume output of your trimmed file(s):" && echo
	echo "1) RMS Normalization to 0 dB" && echo "2) ReplayGain as single track" && echo "3) ReplayGain as album"
	echo && read number3
	if [ "$number3" -ne 1 ] && [ "$number3" -ne 2 ] && [ "$number3" -ne 3 ]; then
		script_restart; fi
else
	number3=0
fi

echo && echo && echo "Do you want to create playlist.m3u?" && echo
echo "1) No" && echo "2) Yes" && echo
read number4
if [ "$number4" -ne 1 ] && [ "$number4" -ne 2 ]; then
	script_restart; fi
file_check
cd $PATHLOAD
echo && echo "Found" `ls -1 | grep $EXT | wc -l` "file(s) with" $EXT "extension in" $PATHLOAD
echo -e '\e[0m' && echo && sleep 1

n=0
for FILE in *${EXT}; do
	let n=n+1
	echo "Processing file" $n "of" `ls -1 | grep $EXT | wc -l`...
	echo "`ffprobe -i "${FILE}" -v quiet -print_format json -show_format -hide_banner`" > $ID
	sed -i -e 's/\\\"//g' -e 's/ \/ / /g' -e 's/\///g' -e "s/''//g" -e 's/\?//g' -e 's/\"title\"/\"TITLE\"/g' -e 's/\"album\"/\"ALBUM\"/g' -e 's/\"date\"/\"DATE\"/g' $ID
	ARTIST=`grep album_artist $ID | awk -F': "' '{print $2}' | cut -d'"' -f1`
	TITLE=`grep TITLE $ID | awk -F': "' '{print $2}' | cut -d'"' -f1`
	ALBUM=`grep ALBUM $ID | awk -F': "' '{print $2}' | cut -d'"' -f1`
	YEAR=`grep DATE $ID | awk -F': "' '{print $2}' | cut -d'"' -f1`
	DURATION=`grep duration $ID | awk -F': "' '{print $2}' | cut -d'.' -f1`
	BITRATE=`grep bit_rate $ID | awk -F': "' '{print $2}' | cut -d'"' -f1`
	SIZE=`grep size $ID | awk -F': "' '{print $2}' | cut -d'"' -f1`
	DBLEVEL=`ffmpeg -i "${FILE}" -af "volumedetect" -f null /dev/null 2>&1 | \
		grep max_volume | awk -F': ' '{print $2}' | cut -d' ' -f1`
	COMPRESULT=`echo ${DBLEVEL}'<'0 | bc -l`
	DBLEVEL=`echo "-(${DBLEVEL})" | bc -l`

	export_cover
	echo "ARTIST:" $ARTIST
	echo "ALBUM:" $ALBUM
	echo "SONG TITLE:" $TITLE
	echo "FILE NAME:" "${FILE}"
	echo "YEAR:" $YEAR
	echo "DURATION:" `printf '%dm:%ds\n' $(($DURATION%3600/60)) $(($DURATION%60))`
	echo "BITRATE: $(($BITRATE/1024)) kBit/s"
	echo $SIZE | awk '{abc=$1/1024/1024; print "SIZE: " abc " MB"}'
	echo "SONG LEVEL: -$DBLEVEL dB"

	if [ $number2 -eq 1 ]; then
		if [ $number3 -eq 2 ]; then
			ffmpeg_flac
			bitrate_flac
			mv -f $PATHSAVE/"${FILE}" $PATHSAVE/"${ARTIST} - ${TITLE}${EXT}"
			echo "Scanning for ReplayGain as track..."
			metaflac --add-replay-gain $PATHSAVE/"${ARTIST} - ${TITLE}${EXT}"
		elif [ $number3 -eq 1 ]; then
			ffmpeg_flac_norm
			bitrate_flac
			mv -f $PATHSAVE/"${FILE}" $PATHSAVE/"${ARTIST} - ${TITLE}${EXT}"
		elif [ $number3 -eq 3 ]; then
			ffmpeg_flac
			bitrate_flac
			mv -f $PATHSAVE/"${FILE}" $PATHSAVE/"${ARTIST} - ${TITLE}${EXT}"
		fi
	else
		if [ $number2 -eq 2 ]; then
			DBLEVEL=`echo "$DBLEVEL -0.9" | bc`
			echo "To avoid possible clipping, RMS Normalization will be -0.9 dB (adds "$DBLEVEL" dB)"
			echo && echo "Encoding to MP3 with VBR "$mp3vbr": it will take time..."
			ffmpeg_mp3
			echo "`ffprobe -i $PATHSAVE/"${FILE}"$M3EXT -v quiet -print_format json -show_format -hide_banner`" > $ID
			DBLEVEL=`ffmpeg -i $PATHSAVE/"${FILE}"$M3EXT -af "volumedetect" -f null /dev/null 2>&1 | \
				grep max_volume | awk -F': ' '{print $2}' | cut -d' ' -f1`
			lossy_data
			mv -f $PATHSAVE/"${FILE}"$M3EXT $PATHSAVE/"${ARTIST} - ${TITLE}"$M3EXT
		elif [ $number2 -eq 3 ]; then
			if [ $number5 -eq 3 ]; then
				DBLEVEL=`echo "$DBLEVEL -0.4" | bc`
				echo "To avoid possible clipping, RMS Normalization will be -0.4 dB (adds "$DBLEVEL" dB)"
			else
				DBLEVEL=`echo "$DBLEVEL -0.8" | bc`
				echo "To avoid possible clipping, RMS Normalization will be -0.8 dB (adds "$DBLEVEL" dB)"
			fi
			echo && echo "Encoding to M4A with library "$LIB4" and "$M4AQ": it will take time..."
			ffmpeg_m4a
			echo "`ffprobe -i $PATHSAVE/"${FILE}"$M4EXT -v quiet -print_format json -show_format -hide_banner`" > $ID
			DBLEVEL=`ffmpeg -i $PATHSAVE/"${FILE}"$M4EXT -af "volumedetect" -f null /dev/null 2>&1 | \
				grep max_volume | awk -F': ' '{print $2}' | cut -d' ' -f1`
			lossy_data
			mv -f $PATHSAVE/"${FILE}"$M4EXT $PATHSAVE/"${ARTIST} - ${TITLE}"$M4EXT
		elif [ $number2 -eq 4 ]; then
			DBLEVEL=`echo "$DBLEVEL -1.1" | bc`
			echo "To avoid possible clipping, RMS Normalization will be -1.1 dB (adds "$DBLEVEL" dB)"
			ffmpeg_opus
			echo && echo "Encoding to OPUS: it will take time..."
			opusenc $PATHSAVE/"${FILE}" $PATHSAVE/"${FILE}"$OPUSEXT --quiet
			rm $PATHSAVE/"${FILE}"
			echo "`ffprobe -i $PATHSAVE/"${FILE}"$OPUSEXT -v quiet -print_format json -show_format -hide_banner`" > $ID
			DBLEVEL=`ffmpeg -i $PATHSAVE/"${FILE}"$OPUSEXT -af "volumedetect" -f null /dev/null 2>&1 | \
				grep max_volume | awk -F': ' '{print $2}' | cut -d' ' -f1`
			lossy_data
			mv -f $PATHSAVE/"${FILE}"$OPUSEXT $PATHSAVE/"${ARTIST} - ${TITLE}"$OPUSEXT
		fi
	fi
	echo "****************** DONE! *******************"
	echo
done
if [ $number3 -eq 3 ]; then
	echo && echo "Scanning for ReplayGain as album..."
	metaflac --add-replay-gain $PATHSAVE/*$EXT
fi
echo
echo -e '\e[93m'"*** All songs have been trimmed and/or converted! ***"
echo -e '\e[0m'

cd $PATHSAVE
if [[ $number4 -eq 2 ]]; then
	echo -e '\e[96m'"****** Creating playlist in alphabetical order ******"
	echo -e '\e[0m'
	list_song
	echo "#EXTM3U" > $PLF
	while read line; do
		echo "#EXTINF:`ffprobe "${line}${EXT}" -v quiet -print_format json -show_format -hide_banner | \
			grep duration | awk -F'\": \"' '{print $2}' | cut -d'.' -f1`,${line}" >> $PLF
		echo "${line}${EXT}" >> $PLF
	done < plf
	echo "#EXTM3U" > $PL3
	while read line; do
		echo "#EXTINF:`ffprobe "${line}${M3EXT}" -v quiet -print_format json -show_format -hide_banner | \
			grep duration | awk -F'\": \"' '{print $2}' | cut -d'.' -f1`,${line}" >> $PL3
		echo "${line}${M3EXT}" >> $PL3
	done < pl3
	echo "#EXTM3U" > $PL4
	while read line; do
		echo "#EXTINF:`ffprobe "${line}${M4EXT}" -v quiet -print_format json -show_format -hide_banner | \
			grep duration | awk -F'\": \"' '{print $2}' | cut -d'.' -f1`,${line}" >> $PL4
		echo "${line}${M4EXT}" >> $PL4
	done < pl4
	echo "#EXTM3U" > $PLOP
	while read line; do
		echo "#EXTINF:`ffprobe "${line}${OPUSEXT}" -v quiet -print_format json -show_format -hide_banner | \
			grep duration | awk -F'\": \"' '{print $2}' | cut -d'.' -f1`,${line}" >> $PLOP
		echo "${line}${OPUSEXT}" >> $PLOP
	done < plop

	if [[ -f $PLF && `cat $PLF | wc -c` = 8 ]]; then
		rm $PLF; fi
	if [[ -f $PL3 && `cat $PL3 | wc -c` = 8 ]]; then
		rm $PL3; fi
	if [[ -f $PL4 && `cat $PL4 | wc -c` = 8 ]]; then
		rm $PL4; fi
	if [[ -f $PLOP && `cat $PLOP | wc -c` = 8 ]]; then
		rm $PLOP; fi
fi

echo -e '\e[92m'"********************* ALL DONE! *********************"
echo -e '\e[0m'
echo

rm -f plf pl3 pl4 plop
rm -f $PATHLOAD/$ID

exit 0
