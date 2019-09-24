#!/bin/bash
###########################################################################
#
#  This script will install GNU Radio 3.8 and a number of my most common
#  modules from source.
#
###########################################################################

# Set INSTALLDIR if you'd like the files installed somewhere other than /usr/local
INSTALLDIR="$HOME/gnuradio"
BUILDROOT="$INSTALLDIR/src"
BUILDPREFIX="-DCMAKE_INSTALL_PREFIX=$INSTALLDIR"

# prerequisites 
HASPYBOMBS=`which pybombs | wc -l`

sudo apt install -y python-pip python3-pip python3-dev git libgps-dev libudev-dev python3-lxml libcanberra-gtk-module \
python3-distutils-extra zlib1g-dev libsdl2-dev libpcap-dev libcppunit-dev flex python3-twisted \
libgmp3-dev libgsl-dev libqt5svg5-dev autogen

# UHD requires some python2 modules as well
sudo pip2 install mako python-apt ruamel.yaml numpy requests
sudo pip3 install mako python-apt ruamel.yaml requests numpy scipy matplotlib

if [ $HASPYBOMBS -eq 0 ]; then
	# use this if you already have pybombs installed:
	# sudo pip install --upgrade git+https://github.com/gnuradio/pybombs.git

	sudo pip3 install git+https://github.com/gnuradio/pybombs.git

	# Add recipes
	pybombs recipes add gr-recipes git+https://github.com/gnuradio/gr-recipes.git
	pybombs recipes add gr-etcetera git+https://github.com/gnuradio/gr-etcetera.git
fi

if [ ! -e /usr/local/bin/pybombs ]; then
	echo "ERROR: Unable to find pybombs."
	exit 1
fi

# This starts the install:  (remember ~ doesn't work in bash scripts so using $HOME instead)
echo "[`date`] Installing gnuradio from pybombs..."
pybombs prefix init $INSTALLDIR -a gnuradio38 -R gnuradio-default

if [ $? -gt 0 ]; then
	echo "ERROR: Could not install gnuradio from pybombs"
	exit 1
fi

#################################################################################

if [ -e $INSTALLDIR/setup_env.sh ]; then
	source $INSTALLDIR/setup_env.sh
else
	echo "ERROR: Unable to find $INSTALLDIR/setup_env.sh"
	exit 1
fi

cd $BUILDROOT

# Trigger sudo password if needed
sudo ls >/dev/null

# Install airspy, rtl-sdr, and hackrf first, then libosmosdr
# Install the common/default packages
echo "[`date`] Installing pybombs-compatible modules..."
# Don't think you need libosmocore, so not in the list.
pybombs install airspy rtl-sdr hackrf libosmo-dsp gr-correctiq gr-filerepeater gr-grnet gr-lfast
pybombs install  gr-mesa 

# Reload new udev rules files
sudo udevadm control --reload-rules
sudo udevadm trigger

# gr-osmosdr
echo "[`date`] Installing exp 3.8-converted gr-osmosdr..."
cd $BUILDROOT
git clone --branch=exp https://github.com/ilya-epifanov/gr-osmosdr.git gr-osmosdr
cd gr-osmosdr
mkdir build
cd build
cmake $BUILDPREFIX ..
make -j6
make -j6 install

# SoapySDR
echo "[`date`] Building SoapySDR..."
cd $BUILDROOT
git clone https://github.com/pothosware/SoapySDR.git
cd SoapySDR
mkdir build
cd build
cmake $BUILDPREFIX ..
make -j6
make -j6 install

# SoapyUHD
echo "[`date`] Building SoapyUHD..."
cd $BUILDROOT
git clone https://github.com/pothosware/SoapyUHD.git
cd SoapyUHD
mkdir build
cd build
cmake $BUILDPREFIX ..
make -j6
make -j6 install

# SoapyRTLSDR
echo "[`date`] Building SoapyRTLSDR..."
cd $BUILDROOT
git clone https://github.com/pothosware/SoapyRTLSDR.git
cd SoapyRTLSDR
mkdir build
cd build
cmake $BUILDPREFIX ..
make -j6
make -j6 install

# SoapyAirspy
echo "[`date`] Building SoapyAirspy..."
cd $BUILDROOT
git clone https://github.com/pothosware/SoapyAirspy.git
cd SoapyAirspy
mkdir build
cd build
cmake $BUILDPREFIX ..
make -j6
make -j6 install

# SoapyHackRF
echo "[`date`] Building SoapyHackrf..."
cd $BUILDROOT
git clone https://github.com/pothosware/SoapyHackRF.git
cd SoapyHackRF
mkdir build
cd build
cmake $BUILDPREFIX ..
make -j6
make -j6 install

# SoapyRemote
echo "[`date`] Building SoapyRemote..."
cd $BUILDROOT
git clone https://github.com/pothosware/SoapyRemote.git
cd SoapyRemote
mkdir build
cd build
cmake $BUILDPREFIX ..
make -j6
make -j6 install

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
#git clone https://github.com/csete/gqrx.git
cd $BUILDROOT
git clone --branch maint-3.8 https://github.com/argilo/gqrx.git
cd gqrx
mkdir build
cd build
cmake $BUILDPREFIX ..
make -j6
make -j6 install

# GPredict
echo "[`date`] Building gpredict..."
cd $BUILDROOT
git clone https://github.com/csete/gpredict.git
cd gpredict
sudo apt -y install libtool intltool autoconf automake libcurl4-openssl-dev pkg-config libglib2.0-dev libgtk-3-dev libgoocanvas-2.0-dev
./autogen.sh
make -j6
sudo make -j6 install

# Inspectrum
echo "[`date`] Building inspectrum..."
# sudo apt -y install qt5-default libfftw3-dev cmake pkg-config libliquid-dev
sudo apt -y install qt5-default libliquid-dev
cd $BUILDROOT
git clone https://github.com/miek/inspectrum.git
cd inspectrum
mkdir build
cd build
cmake $BUILDPREFIX ..
make -j6
sudo make -j6 install

# QSpectrumAnalyzer
echo "[`date`] Installing qspectrumanalyzer..."
sudo pip3 install qspectrumanalyzer

cat $HOME/.bashrc | grep -q "setup_env\.sh"

if [ $? -gt 0 ]; then
	# Add it 
	echo "source $HOME/gnuradio/setup_env.sh" >> $HOME/.bashrc
	echo "export Gnuradio_DIR=\"$HOME/gnuradio\"" >> $HOME/.bashrc
fi

echo "[`date`] Done."

