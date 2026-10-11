#!/bin/bash
# Shots for the product demo (section P of ../video-narration.md) from the four screen recordings in ~/pipon-out
# (not in the repository). Writes web2a.mp4 … web3e.mp4 into the current directory; pass that directory to
# build-video.mjs as DEMO=<dir>. Each shot is the whole screen (Mac page left, iPhone right) or a close-up.
set -e
P=~/pipon-out; BG="color=c=0xf6f5f2:size=1920x1080:rate=30"
X="-an -r 30 -c:v libx264 -crf 16 -pix_fmt yuv420p"
BLUR="boxblur=luma_radius=10:luma_power=3:chroma_radius=5:chroma_power=3"
# close-up of a Mac recording: file, time, crop w:h:x:y (16:9), out   (web2: pseudonymous ID blurred first)
close() { ffmpeg -v error -y -ss $2 -i $P/$1 -filter_complex "[0:v:0]split[a][b];[b]crop=134:28:918:862,${BLUR}[bb];[a][bb]overlay=918:862:enable='$5',crop=$3,scale=1920:1080:flags=lanczos,trim=end_frame=1,loop=loop=-1:size=1,fps=30,trim=duration=2[v]" -map "[v]" $X $4.mp4; }
# wide: Mac (from..to, then held) on the left, phone (from..to, delayed, then held) on the right, fitted to a length
wide() { # macfile m0 m1 phonefile p0 p1 delay length out idblur
  ffmpeg -v error -y -i $P/$1 -i $P/$4 -filter_complex "
  ${BG}:d=30[bg];
  [0:v:0]fps=30,split[a][b];[b]crop=134:28:918:862,${BLUR}[bb];[a][bb]overlay=918:862:enable='${10}',crop=1280:1080:320:0,trim=start=$2:end=$3,setpts=PTS-STARTPTS,tpad=stop_mode=clone:stop_duration=30[mac];
  [1:v:0]fps=30,crop=500:1080:710:0,split[c][d];[d]crop=80:80:27:972,boxblur=luma_radius=20:luma_power=3:chroma_radius=10:chroma_power=3[dd];[c][dd]overlay=27:972:enable='${11}',scale=472:1020,trim=start=$5:end=$6,setpts=PTS-STARTPTS,tpad=start_mode=clone:start_duration=$7:stop_mode=clone:stop_duration=30[ph];
  [bg][mac]overlay=40:0:shortest=1[x];[x][ph]overlay=1392:30:shortest=1,trim=duration=$8,setpts=PTS-STARTPTS[v]" -map "[v]" $X $9.mp4; }
W2M=pipon_web2_mac.mp4; W2I=pipon-web2_iphone.mp4; W3M=pipon_web3_mac.mp4; W3I=pipon_web3_iphone.mp4
# web2a: the whole page, not a close-up (the first look at the product), where the wide shots put it; no phone yet
ffmpeg -v error -y -ss 0.10 -i $P/$W2M -filter_complex "${BG}:d=2[bg];[0:v:0]crop=1280:1080:320:0,trim=end_frame=1,loop=loop=-1:size=1,fps=30[m];[bg][m]overlay=40:0:shortest=1[v]" -map "[v]" $X web2a.mp4
wide  $W2M 0 0.9   $W2I 0 0.05 0 2.0 web2b 0 1
wide  $W2M 0.7 0.75 $W2I 0 3.6 0 4.0 web2c 0 'lt(t,1.4)'
wide  $W2M 0.7 0.75 $W2I 3.6 6.6 0 3.2 web2d 0 0
wide  $W2M 0.7 0.75 $W2I 6.6 10.44 0 4.2 web2e 0 0
close $W2M 1.45 800:450:800:400 web2f 1
close $W2M 1.45 768:432:802:590 web2g 1
close $W3M 0.60 800:450:790:160 web3a 0
wide  $W3M 1.0 10.0 $W3I 0 6.5 1.0 9.0 web3b 0 0
close $W3M 11.0 800:450:790:285 web3c 0
close $W3M 11.0 720:405:800:335 web3d 0
close $W2M 1.45 640:360:820:458 web3e 1
# web3b carries the whole request-to-mint sequence: fit it to its sentence (about 6.5 s in the recording of 10-11)
ffmpeg -v error -y -i web3b.mp4 -vf "setpts=PTS*6.3/9.0" $X web3b-fit.mp4 && mv web3b-fit.mp4 web3b.mp4
