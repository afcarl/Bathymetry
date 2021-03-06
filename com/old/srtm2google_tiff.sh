#!/bin/sh
#       $Id: img2google,v 1.20 2009/04/27 18:10:05 guru Exp $
# Shell script that will generate a Google Earth png tile from
# Sandwell/Smith's 1x1 min Mercator topo.11.1img grid and add
# a basic KML wrapper for use in any Google Earth version.
# David Sandwell and Paul Wessel, March 2009
# Credit to Joaquim Luis for adding KML output from ps2raster

# Change these only if you know what you are doing!  Note this script
# is hardwired to do bathymetry.  You must change many things to have
# it plot crustal ages or gravity.
#------------------
TOPO=topo.15.1.img
SRTM=../topo30.grd
INC=1
DPI=360
#------------------

if [ $# -eq 0 ]; then
cat << EOF >&2
        img2google - Create Google Earth KML tiles from the $TOPO bathymetry grid
        
        Usage: img2google -Rwest/east/south/north [imgfile] [-A<mode>[<altitude>]] [-C] [-F<fademin/fademax>]
                [-Gprefix] [-L<LODmin/LODmax] [-N<name] [-T<title>] [U<url>] [-V] [-Z[+]]
        
                -R Specify the region of interest
        OPTIONAL ARGUMENTS:
                imgfile is the 1x1 min topo img to use [topo.11.1.img]
                -A Altitude mode [S].  Append altitude in m if mode = g|A|s.
                -C clip data above sealevel [No clipping]
                -F sets distances over which we fade from opaque to transparent [no fading]
                -G Set output file prefix [Default is topoN|S<north>E|W<west>]
                -L Set level of detail (LOD) in pixels.  Image goes inactive in GE when there are fewer
                   than minLOD pixels or more than maxLOD pixels visible.  -1 means never invisible.
                -N Append KML document layer name ["topoN|S<north>E|W<west>"]
                -T Append KML document title name ["Predicted bathymetry"]
                -V Optionally run in verbose mode
                -U Specify a remote URL for the image [local]
                -Z Create a zipped *.kmz file; append + to remove original KML/PNG files [no zipping]
EOF
        exit
fi

# Process the command line arguments

A=""
C=""
F=""
G=""
L=""
N=""
R=""
T=""
U=""
V=""
Z=""
while [ ! x"$1" = x ]; do
        case $1
        in
                -R*)    R=$1;           # Got the region
                        shift;;
                -A*)    A=$1;           # use clipping
                        shift;;
                -C)     C=$1;           # use clipping
                        shift;;
                -F*)    F=$1;           # Got fade settings
                        shift;;
                -G*)    G=$1;           # Got the output namestem
                        shift;;
                -L*)    L=$1;           # Got level of detail settings
                        shift;;
                -N*)    N=$1;           # Got the KML layername string
                        shift;;
                -T*)    T=$1;           # Got the KML title string
                        shift;;
                -V)     V=$1;           # Verbose run
                        shift;;
                -U*)    U=$1;           # Got a URL prefix
                        shift;;
                -Z*)    Z=$1;           # Make KMZ file
                        shift;;
                -*)             echo "$0: Unrecognized option $1" 1>&2; # Bad option argument
                        exit 1;;
                *)              TOPO=$1;        # The input file name
                        shift;;
        esac
done
if [ X"$R" = "X" ]; then
        echo "$0: ERROR: Must specify the region:" 1>&2
fi

# 1. Make sure we have the img file either locally or via $GMT_IMGDIR

if [ ! -f $TOPO ]; then
        if [ "X$GMT_IMGDIR" = "X" ] || [ ! -f $GMT_IMGDIR/$TOPO ]; then
                echo "img2google: Cannot find $TOPO - exiting"
                exit 1
        fi
fi

# Compute dimension of plot in inches and use that as our papersize
w=`echo $R | awk -F/ '{print substr($1,3)}'`
e=`echo $R | awk -F/ '{print $2}'`
s=`echo $R | awk -F/ '{print $3}'`
n=`echo $R | awk -F/ '{print $4}'`
W=`gmtmath -Q -fg $e $w SUB =`
H=`gmtmath -Q -fg $n $s SUB =`

# 2. Extract the (x,y,z) of constrained nodes by extracting a grid with
#    NaNs were unconstrained, exclude NaNs, and capture points whose z < 0

img2grd $TOPO $R -T2 -S1 -m${INC} -D $V -G$$.tile.nc
grd2xyz $$.tile.nc -S -bod | gmtselect -Z-15000/-2.0 -bi3d > $$.track.xyz

# 3. get the topo data, this time including unconstrained estimates
#    use the SRTM grid

#img2grd $TOPO $R -T1 -S1 -m${INC} -E -D $V -G$$.tile.nc
grdcut $SRTM $R -V -G$$.tile.nc

#  4. make the image

# Create list of desired, irregular contours
cat << EOF > $$.intervals
-10000 C
-9000 C
-8000 C
-7000 C
-6000 C
-5000 C
-4000 C
-3000 C
-2000 C
-1000 C
-5500 C
-4500 C
-3500 C
-2500 C
-1500 C
-500 C
EOF
# -2000 contour drawn separately with black, heavier line
echo "-2000 C" > $$.int2000
makecpt -Ctopo -Z > $$.cpt
grdgradient $$.tile.nc $V -A340 -G$$.nc
#grdmath $$.nc 12000 DIV = $$.tile_grad.nc
grdmath $$.nc 16000 DIV = $$.tile_grad.nc
if [ X"$C" = "X" ]; then        # No clipping, just lay down image
        grdimage $$.tile.nc -I$$.tile_grad.nc -C$$.cpt -Jx1id -Y0 -X0 -K -P $V --DOTS_PR_INCH=${DPI} --ELLIPSOID=WGS-84 --PAPER_MEDIA=Custom_${W}ix${H}i > $$.ps
else    # Use GSHHS high clip path to only show ocean areas
        pscoast $R -Jx1id -Y0 -X0 -K -P $V --DOTS_PR_INCH=${DPI} --ELLIPSOID=WGS-84 --PAPER_MEDIA=Custom_${W}ix${H}i -Dh -Sc > $$.ps
        grdimage $$.tile.nc -I$$.tile_grad.nc -C$$.cpt -J -O -K $V --DOTS_PR_INCH=${DPI} --ELLIPSOID=WGS-84 >> $$.ps
fi
psxy $$.track.xyz -J $R -Sc.005i -G80 $V -O -K --DOTS_PR_INCH=${DPI} --ELLIPSOID=WGS-84 >> $$.ps
grdcontour $$.tile.nc -J -C$$.intervals -W1,80 -O -K $V --DOTS_PR_INCH=${DPI} --ELLIPSOID=WGS-84 >> $$.ps
grdcontour $$.tile.nc -J -C$$.int2000 -W1p,black -O -K $V --DOTS_PR_INCH=${DPI} --ELLIPSOID=WGS-84 >> $$.ps
if [ X"$C" = "X" ]; then
        psxy -R -J -O /dev/null >> $$.ps
else
        pscoast -O -Q >> $$.ps
fi
#
#  5. make the geotiff file
#
if [ X"$G" = "X" ]; then
        xtag=`echo $w | awk '{if ($1 < 0.0) {printf "W%g\n", -$1} else if ($1 > 180.0) {printf ("W%g\n", 360-$1)} else {printf "E%g\n", $1}}'`
        ytag=`echo $n | awk '{if ($1 < 0.0) {printf "S%g\n", -$1} else {printf "N%g\n", $1}}'`
        name="topo${ytag}${xtag}"
else
        name=`echo $G | awk '{print substr($1,3)}'`
fi
if [ X"$A" = "X" ]; then
        A=+aS
else
        A=+a`echo $A | awk '{print substr($1,3)}'`
fi
if [ ! X"$F" = "X" ]; then
        F=+f`echo $F | awk '{print substr($1,3)}'`
fi
if [ ! X"$L" = "X" ]; then
        L=+l`echo $L | awk '{print substr($1,3)}'`
fi
if [ ! X"$U" = "X" ]; then
        U=+u`echo $U | awk '{print substr($1,3)}'`
fi
if [ X"$N" = "X" ]; then
        N="+n$name"
else
        N=+n`echo $N | awk '{print substr($0,3)}'`
fi
if [ X"$T" = "X" ]; then
        T="+tPredicted bathymetry"
else
        T=+t`echo $T | awk '{print substr($0,3)}'`
fi
mv -f $$.ps $name.ps
#ps2raster $name.ps -E${DPI} -A- -TG -W+k${A}${F}${L}"${N}${T}"${U} $V
ps2raster $name.ps -E${DPI} -W+g -P -S -V
if [ ! "X$Z" = "X" ]; then      # zip up as one archive
        zip -rq9 $name.kmz $name.kml $name.png
        if [ "X$Z" = "X-Z+" ]; then
                rm -f $name.kml $name.png
        fi
fi
#  6. clean up
rm -f $$.* $name.ps
exit 0
seasat [55]% 
