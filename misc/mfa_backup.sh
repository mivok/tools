#!/bin/bash
# Dependencies:
#   brew install zbar pngpaste qrencode

# Generates a pdf file to print from an MFA QR Code
# The QR code should be on the clipboard (e.g. taken from a screenshot)

if [[ -z $1 ]]; then
    OTPURL=$(pngpaste - | zbarimg -q --raw -- -)
else
    OTPURL=$(zbarimg -q --raw -- $1)
fi
LABEL=$(echo "$OTPURL" |
    perl -a -F[/?] \
    -e '@F[3] =~ s/\%([A-Fa-f0-9]{2})/pack("C", hex($1))/seg; print @F[3]')

QRCODE="$(qrencode -l M -t EPS -o - "$OTPURL")"
QRSIZE="$(echo "$QRCODE" | grep -o 'BoundingBox: 0 0 [0-9]*' | awk '{ print $NF }')"

pstopdf -i -o out.pdf <<EOF
% 3" x 5" in points
/w 3 72 mul def
/h 5 72 mul def
/qrsize $QRSIZE def
/qrmargin 30 def
/qrscale w qrmargin 2 mul sub qrsize div def
<< /PageSize [w h] >> setpagedevice

/Helvetica findfont 10 scalefont setfont

w 2 div h 60 sub moveto
($LABEL) dup stringwidth pop 2 div neg 0 rmoveto show

w qrsize qrscale mul sub 2 div h 80 qrsize qrscale mul add sub translate
qrscale qrscale scale

%% BeginDocument: qrcode.eps
$QRCODE
%% EndDocument

showpage
EOF

open out.pdf
