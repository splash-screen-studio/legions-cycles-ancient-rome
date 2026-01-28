#!/bin/bash
cd /Users/bedwards/legions-cycles-ancient-rome/bricey

VIDEO_IDS=(
tDaWYkdJZ8k
n4ejoAIGV2I
OKEDROSleb4
CkBpWfpDCQo
SGhTPMS1Wrs
NK8VHcNHJG4
1XJRZ1x2x4g
SVBmZ3yIMRo
FaEMgVDlaNQ
0koUgMbigYs
92acKqS_Jo0
NDgnMeJ4CbM
0H_MTbk2Rk8
kTorYMR31M4
_l00XDXQwwc
b-4YzRv27bg
MmIJ3KIbIow
T2V_NiMP5dk
zl1dfdKk4Vo
BBoJiE4IkSg
tvj_2sWMXGU
7583VEaWPO0
jaitqSU2HIA
eM9Vdtw7JVM
Vmphd-361qk
MyK4o2pIpQw
2Msrw5w5cTs
uzusbTeSKD4
TeMGAqzZrDc
cn25kn9kHwU
XpvoYBZaXvE
T0xqkYODIl0
5bI6l6SHBDU
TmiU5CY6BW0
WOyzapcT-9Y
am-K2Gn2GTg
bCrD7mOzEPU
DaaJsfxinjQ
RYoNhdREi4Y
Sk_mK3Yc53c
VTNlENUFHtU
9MVikdoA0_8
56Iz1FMo6DE
TgZI48DTNqE
lN2I3cks0WU
9iBnJZ08kuE
zbWriOoiZ5I
_63TM15fF1g
X9o2M0B6TTU
hT0Sl5ScR5s
stJtnGGt-1c
Gart69xNY-M
Vi2FckNJv9w
MRI6D4mfwMw
sBdV4mimlYs
cMfPkBnmm3U
JxSCvKAOsMQ
shD2JZqMnnw
KNT-vjqB_qI
ulBM7UdHk_4
njWuPwGEVDM
fsZ4xZgOnq4
mS8I9BGYUgM
mJZWY3G7wa4
YyQi82TzYL4
7BSYIEdo6E4
49BbPONfeMQ
xwaCg7SWUhc
FqWyXoWHJ7c
uO_vDlSmPqg
Tw2pv4baSnY
hRoTJbkEeJg
T85CDReIZyw
6ZgzabMLkKQ
Zh-Jd4xEc2g
UMUqPMDUHrY
VGlP9ATO1eY
UsahcBf18jE
4IBKnzZMcJ8
9uiUkuCS8WE
nmkeuLFn-ZM
PFCCe3pxHQM
BURG3ATTOrs
1_6BvD9sOjs
30EsUOjedqA
RWNHvYdIVI0
4fJBWFz9I-E
5SUxUdnyy7A
R2lGSbq8DuM
u_Du4PI19Go
61uKtDaisz8
DkMeRJIHojM
fjTkDtNs92Q
yTNqXR_HRck
f2xmjcVRd7k
qF_3la-gFbU
dD8G79gfwwQ
Gr4Ldmv51Vc
_FH4SIdNxE8
sIBUdb211AQ
)

count=0
for id in "${VIDEO_IDS[@]}"; do
    count=$((count + 1))
    echo "[$count/100] Downloading: $id"
    yt-dlp --write-auto-sub --sub-lang en --skip-download --convert-subs srt \
           -o "%(title)s_%(id)s" \
           "https://www.youtube.com/watch?v=$id" 2>/dev/null
    sleep 0.5
done

echo "Converting SRT to TXT..."
python3 convert_srt.py *.srt 2>/dev/null
rm -f *.srt 2>/dev/null
echo "Done! Downloaded $(ls *.txt 2>/dev/null | wc -l) transcripts"
