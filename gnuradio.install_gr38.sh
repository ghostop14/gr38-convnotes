#!/bin/bash
###########################################################################
#
#  This script will install GNU Radio 3.8 and a number of my most common
#  modules from source.
#
###########################################################################

BUILDROOT=/opt/sdr/gnuradio_install
# Set INSTALLDIR if you'd like the files installed somewhere other than /usr/local
INSTALLDIR=""

if [ ${#BUILDPREFIX} -gt 0 ]; then
	BUILDPREFIX="-DCMAKE_INSTALL_PREFIX=$INSTALLDIR"
	if [ ! -e $INSTALLDIR ]; then
		mkdir -p $INSTALLDIR
		if [ $? -gt 0 ]; then
			echo "ERROR: Cannot create $INSTALLDIR.  Try creating it manually or setting parent directory permissions."
			exit 1
		fi
	fi

	export PYTHONPATH="/usr/local/lib/python3.6/dist-packages:$INSTALLDIR/lib/python3.6/dist-packages:$PYTHONPATH"
	export LD_LIBRARY_PATH="/usr/local/lib/:$INSTALLDIR/lib/:$LD_LIBRARY_PATH"
	export LIBRARY_PATH="/usr/local/lib/:$INSTALLDIR/lib/:$LIBRARY_PATH"
	export PKG_CONFIG_PATH="/usr/local/lib/pkgconfig:$INSTALLDIR/lib/pkgconfig:$PKG_CONFIG_PATH"
else
	BUILDPREFIX=""
fi

if [ ! -e $BUILDROOT ]; then
	mkdir -p $BUILDROOT
fi

if [ ! -e $BUILDROOT ]; then
	echo "ERROR: Unable to set up $BUILDROOT".
	exit 1
fi

cd $BUILDROOT

# Trigger sudo password if needed
sudo ls >/dev/null

# Discovered for certain modules along the way.
echo "[`date`] Installing prerequisites..."
sudo apt -y install python3-pip zlib1g-dev libsdl2-dev libcppunit-dev flex python3-twisted libgmp3-dev libgsl-dev libqt5svg5-dev autogen

# Stated prerequisites
sudo apt -y install git cmake g++ libboost-all-dev libgmp-dev swig python3-numpy \
python3-mako python3-sphinx python3-lxml doxygen libfftw3-dev libcomedi-dev \
libsdl1.2-dev libgsl-dev libqwt-qt5-dev libqt5opengl5-dev python3-pyqt5 \
liblog4cpp5-dev libzmq3-dev python3-yaml python3-click python3-click-plugins 

# Update numpy and install scipy and matplotlib
sudo pip3 install numpy scipy matplotlib

echo "[`date`] Building prerequisite components..."
# UHD
cd $BUILDROOT
git clone https://github.com/EttusResearch/uhd.git
cd uhd/host
mkdir build
cd build
cmake $BUILDPREFIX ..
make -j6

if [ $? -gt 0 ]; then
	echo "ERROR building UHD."
	exit 1
fi

sudo make -j6 install

# Apache Thrift (CTLPORT won't work without it)
cd $BUILDROOT
git clone https://github.com/apache/thrift.git
cd thrift
./bootstrap.sh 
./configure --with-c_glib --with-cpp --with-libevent --with-python \
  --without-csharp --without-d --without-erlang --without-go \
  --without-haskell --without-java --without-lua --without-nodejs \
  --without-perl --without-php --without-ruby --without-zlib \
  --without-qt4 --without-qt5 \
  --disable-tests --disable-tutorial CXXFLAGS="-DNDEBUG"
mkdir buildthrift
cd buildthrift
cmake $BUILDPREFIX ..
make -j3

if [ $? -gt 0 ]; then
	echo "ERROR building Apache Thrift."
	exit 1
fi

sudo make install

# GNURADIO 3.8
echo "[`date`] Building gnuradio..."
cd $BUILDROOT
git clone --branch=maint-3.8 https://github.com/gnuradio/gnuradio.git gnuradio38
cd gnuradio38
git pull --recurse-submodules=on
git submodule update --init
mkdir build
cd build
cmake $BUILDPREFIX ..
# -j6 crushes the memory in the VM.  Use -j3 to use less but build a bit slower.
make -j3

if [ $? -gt 0 ]; then
	echo "ERROR building gnuradio."
	exit 1
fi

sudo make -j6 install


# Install airspy, rtl-sdr, and hackrf first, then libosmosdr

# RTL-SDR
echo "[`date`] Building rtl-sdr..."
cd $BUILDROOT
git clone https://git.osmocom.org/rtl-sdr
cd rtl-sdr
mkdir build
cd build
cmake $BUILDPREFIX -DINSTALL_UDEV_RULES=ON ..
make -j6
sudo make -j6 install

# Blacklist conflicting kernel-mode driver
sudo echo "blacklist dvb_usb_rtl28xxu" >> /etc/modprobe.d/blacklist.conf

# AIRSPY
echo "[`date`] Building airspy..."
cd $BUILDROOT
git clone https://github.com/airspy/airspyone_host.git airspy
cd airspy
mkdir build
cd build
cmake $BUILDPREFIX -DINSTALL_UDEV_RULES=ON ..
make -j6
sudo make -j6 install

# HACKRF
echo "[`date`] Building hackrf..."
cd $BUILDROOT
git clone https://github.com/mossmann/hackrf.git
cd hackrf/host
mkdir build
cd build
cmake $BUILDPREFIX -DINSTALL_UDEV_RULES=ON ..
make -j6
sudo make -j6 install

# LIBOSMO-DSP
echo "[`date`] Building gr-osmosdr..."
cd $BUILDROOT
git clone https://git.osmocom.org/libosmo-dsp
cd libosmo-dsp
autoreconf -i -I /usr/share/aclocal && ./configure
make -j6
sudo make -j6 install

# gr-osmosdr
cd $BUILDROOT
git clone --branch=exp https://github.com/ilya-epifanov/gr-osmosdr.git gr-osmosdr
cd gr-osmosdr
mkdir build
cd build
cmake $BUILDPREFIX ..
make -j6
sudo make -j6 install

# Reload new udev rules files
sudo udevadm control --reload-rules
sudo udevadm trigger

# SoapySDR
echo "[`date`] Building SoapySDR..."
cd $BUILDROOT
git clone https://github.com/pothosware/SoapySDR.git
cd SoapySDR
mkdir build
cd build
cmake $BUILDPREFIX ..
make -j6
sudo make -j6 install

# SoapyUHD
echo "[`date`] Building SoapyUHD..."
cd $BUILDROOT
git clone https://github.com/pothosware/SoapyUHD.git
cd SoapyUHD
mkdir build
cd build
cmake $BUILDPREFIX ..
make -j6
sudo make -j6 install

# SoapyRTLSDR
echo "[`date`] Building SoapyRTLSDR..."
cd $BUILDROOT
git clone https://github.com/pothosware/SoapyRTLSDR.git
cd SoapyRTLSDR
mkdir build
cd build
cmake $BUILDPREFIX ..
make -j6
sudo make -j6 install

# SoapyAirspy
echo "[`date`] Building SoapyAirspy..."
cd $BUILDROOT
git clone https://github.com/pothosware/SoapyAirspy.git
cd SoapyAirspy
mkdir build
cd build
cmake $BUILDPREFIX ..
make -j6
sudo make -j6 install

# SoapyHackRF
echo "[`date`] Building SoapyHackrf..."
cd $BUILDROOT
git clone https://github.com/pothosware/SoapyHackRF.git
cd SoapyHackRF
mkdir build
cd build
cmake $BUILDPREFIX ..
make -j6
sudo make -j6 install

# SoapyRemote
echo "[`date`] Building SoapyRemote..."
cd $BUILDROOT
git clone https://github.com/pothosware/SoapyRemote.git
cd SoapyRemote
mkdir build
cd build
cmake $BUILDPREFIX ..
make -j6
sudo make -j6 install

# CSDR
echo "[`date`] Building csdr..."
cd $BUILDROOT
git clone https://github.com/simonyiszk/csdr
cd csdr
make -j6
sudo make -j6 install

sudo ldconfig

# GQRX
echo "[`date`] Building gqrx..."
cd $BUILDROOT
#git clone https://github.com/csete/gqrx.git
git clone --branch maint-3.8 https://github.com/argilo/gqrx.git
cd gqrx
mkdir build
cd build
cmake $BUILDPREFIX ..
make -j6
sudo make -j6 install

# GPredict
echo "[`date`] Building gpredict..."
cd $BUILDROOT
git clone https://github.com/csete/gpredict.git
cd gpredict
sudo apt -y install libtool intltool autoconf automake libcurl4-openssl-dev pkg-config libglib2.0-dev libgtk-3-dev libgoocanvas-2.0-dev
./autogen.sh
make -j6
sudo make -j6 install

############################################################
# OOT Modules
############################################################

# gr-correctiq38
echo "[`date`] Building gr-correctiq38..."
cd $BUILDROOT
git clone https://github.com/ghostop14/gr-correctiq.git
cd gr-correctiq
mkdir build
cd build
cmake $BUILDPREFIX ..
make -j6
sudo make -j6 install

# gr-filerepeater
echo "[`date`] Building gr-filerepeater..."
cd $BUILDROOT
git clone https://github.com/ghostop14/gr-filerepeater.git
cd gr-filerepeater
mkdir build
cd build
cmake $BUILDPREFIX ..
make -j6
sudo make -j6 install

# gr-lfast38
echo "[`date`] Building gr-lfast..."
cd $BUILDROOT
git clone https://github.com/ghostop14/gr-lfast.git
cd gr-grlfast
mkdir build
cd build
cmake $BUILDPREFIX ..
make -j6
sudo make -j6 install

# gr-grnet38
echo "[`date`] Building gr-grnet..."
cd $BUILDROOT
git clone https://github.com/ghostop14/gr-grnet.git
cd gr-grnet
mkdir build
cd build
cmake $BUILDPREFIX ..
make -j6
sudo make -j6 install

# Set up required environment variables if needed.
HASPATH=`cat $HOME/.bashrc | grep LD_LIBRARY_PATH | wc -l`

if [ $HASPATH -eq 0 ]; then
	echo "[`date`] Adding environment variables to $HOME/.bashrc..."

	if [ ${#BUILDPREFIX} -eq 0 ]; then
		echo "export PYTHONPATH=\"/usr/local/lib/python3.6/dist-packages:$PYTHONPATH\"" >> $HOME/.bashrc
		echo "export LD_LIBRARY_PATH=\"/usr/local/lib/:$LD_LIBRARY_PATH\"" >> $HOME/.bashrc
		echo "export LIBRARY_PATH=\"/usr/local/lib/:$LIBRARY_PATH\"" >> $HOME/.bashrc
		echo "export PKG_CONFIG_PATH=\"/usr/local/lib/pkgconfig:$PKG_CONFIG_PATH\"" >> $HOME/.bashrc
	else
		echo "export PYTHONPATH=\"/usr/local/lib/python3.6/dist-packages:$INSTALLDIR/lib/python3.6/dist-packages:$PYTHONPATH\"" >> $HOME/.bashrc
		echo "export LD_LIBRARY_PATH=\"/usr/local/lib/:$INSTALLDIR/lib/:$LD_LIBRARY_PATH\"" >> $HOME/.bashrc
		echo "export LIBRARY_PATH=\"/usr/local/lib/:$INSTALLDIR/lib/:$LIBRARY_PATH\"" >> $HOME/.bashrc
		echo "export PKG_CONFIG_PATH=\"/usr/local/lib/pkgconfig:$INSTALLDIR/lib/pkgconfig:$PKG_CONFIG_PATH\"" >> $HOME/.bashrc
	fi
fi

echo "[`date`] Done.  It is strongly recommended that you reboot to pick up all changes."

