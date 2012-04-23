#!/bin/bash
XMPPDIR=`pwd`
BUILDDIR="${XMPPDIR}/build"
DOWNLOADDIR="${XMPPDIR}/downloads"

BUILDBIN="${BUILDDIR}/bin"
BUILDLIB="${BUILDDIR}/lib"
BUILDINCLUDE="${BUILDDIR}/include"
BUILDSRC="$BUILDDIR/src"





OPENSSLFILE="openssl-1.0.0g.tar.gz"
OPENSSLDIR="openssl-1.0.0g"
OPENSSLURL="http://www.openssl.org/source/openssl-1.0.0g.tar.gz"

LIBXML2FILE="libxml2-git-snapshot.tar.gz"
LIBXML2DIR="libxml2-2.7.8"
LIBXML2URL="ftp://xmlsoft.org/libxml2/libxml2-git-snapshot.tar.gz"


###################################################################################################

if [ ! -d ${BUILDDIR} ] ; then
	mkdir ${BUILDDIR}
fi

cd ${BUILDDIR}
if [ ! -d ${BUILDSRC} ] ; then
	mkdir ${BUILDSRC}
fi
cd ${XMPPDIR}

if [ ! -d ${DOWNLOADDIR} ] ; then
	mkdir ${DOWNLOADDIR}
fi
































# linker flags
#   always prefer our install path's lib dir
#   set the sysroot if need be
export LDFLAGS="-L${BUILDLIB}"
echo "LDFLAGS set to: ${LDFLAGS}"

# make
#   how many jobs do we run concurrently?
#   core count + 1
export MAKE="make"
export MAKEJOBS=$((`sysctl -n machdep.cpu.core_count | tr -d " "`+1))
export CONCURRENTMAKE="${MAKE} -j${MAKEJOBS}"

# configure
#   use a common prefix
#   disable static libs by default
export CONFIGURE="./configure"
export CONFIGURECOMMONPREFIX="--prefix=${BUILDDIR}"

# downloader program
#   curl's avail everywhere!
export CURL="curl"
echo "base downloader command: ${CURL} ${CURLOPTS}"

# extract commands
#   currently we only have gzip/bzip2 tar files
export TARGZ="tar -zxf"
export TARBZ2="tar -jxf"

# path
#   pull out fink, macports, gentoo - what about homebrew?
#   set our Wine install dir's bin and X11 bin before everything else
export PATH="${BUILDBIN}:${PATH}"

#
# helpers
#

#
# get_file
#   receives a filename, directory and url
#
function get_file {
	FILE=${1}
	DIRECTORY=${2}
	URL=${3}
	if [ ! -d ${DIRECTORY} ] ; then
		mkdir -p ${DIRECTORY}
	fi
	pushd . >/dev/null 2>&1
	cd ${DIRECTORY}
	if [ ! -f ${FILE} ] ; then
		echo "downloading file ${URL} to ${DIRECTORY}/${FILE}"
		${CURL} ${CURLOPTS} -o ${FILE} ${URL}
	else
		echo "${DIRECTORY}/${FILE} already exists - not fetching"
		popd >/dev/null 2>&1
		return
	fi
	if [ $? != 0 ] ; then
		echo "could not download ${URL}"
	else
		echo "successfully downloaded ${URL} to ${DIRECTORY}/${FILE}"
	fi
	popd >/dev/null 2>&1
}

#
# extract_file
#   receives an extract command, a file and a directory
#
function extract_file {
	EXTRACTCMD=${1}
	EXTRACTFILE=${2}
	EXTRACTDIR=${3}

	echo "extracting ${EXTRACTFILE} to ${EXTRACTDIR} with '${EXTRACTCMD}'"
	if [ ! -d ${EXTRACTDIR} ] ; then
		mkdir -p ${EXTRACTDIR}
	fi
	pushd . >/dev/null 2>&1
	cd ${EXTRACTDIR}
	${EXTRACTCMD} ${EXTRACTFILE}
	echo "successfully extracted ${EXTRACTFILE}"
	popd >/dev/null 2>&1
}

#
# configure_package
#   receives a configure command and a directory in which to run it.
#
function configure_package {
	CONFIGURECMD=${1}
	SOURCEDIR=${2}
	CONFIGUREDFILE="${SOURCEDIR}/.$(basename ${0})-configured"

	echo "running '${CONFIGURECMD}' in ${SOURCEDIR}"
	pushd . >/dev/null 2>&1
	if [ -f ${CONFIGUREDFILE} ] ; then
		echo "${SOURCEDIR} configured"
		popd >/dev/null 2>&1
		return
	fi
	cd ${SOURCEDIR}
	${CONFIGURECMD}
	echo "successfully ran configure in ${SOURCEDIR}"
	touch ${CONFIGUREDFILE}
	popd >/dev/null 2>&1
}

#
# build_package
#   receives a build command line and a directory
#
function build_package {
	BUILDCMD=${1}
	BUILDDIR=${2}

	pushd . >/dev/null 2>&1
	cd ${BUILDDIR}
	${BUILDCMD}
	echo "successfully ran '${BUILDCMD}' in ${BUILDDIR}"
	popd >/dev/null 2>&1
}

#
# install_package
#   receives an install command line and a directory to run it in
#
function install_package {
	INSTALLCMD=${1}
	INSTALLDIR=${2}

	echo "installing with '${INSTALLCMD}' in ${INSTALLDIR}"
	pushd . >/dev/null 2>&1
	cd ${INSTALLDIR}
	${INSTALLCMD}
	if [ $? != 0 ] ; then
		echo "some items may have failed to install! check above for errors."
	else
		echo "succesfully ran '${INSTALLCMD}' in ${INSTALLDIR}'"
	fi
	popd >/dev/null 2>&1
}

#
# package functions
#   common steps for (pretty much) each source build
#     clean
#     get
#     check
#     extract
#     configure
#     build
#     install


###################################################################################################
cd ${XMPPDIR}
if [ ! -d ${DOWNLOADDIR} ] ; then
	mkdir ${DOWNLOADDIR}
fi


# openssl
get_file "${OPENSSLFILE}" "${DOWNLOADDIR}" "${OPENSSLURL}"
extract_file "${TARGZ}" "${DOWNLOADDIR}/${OPENSSLFILE}" "${BUILDSRC}"
#cd ${BUILDSRC}/${OPENSSLDIR}
build_package "./config --prefix=${BUILDDIR}" "${BUILDSRC}/${OPENSSLDIR}"
install_package "make install -s" "${BUILDSRC}/${OPENSSLDIR}"

# xml2
get_file "${LIBXML2FILE}" "${DOWNLOADDIR}" "${LIBXML2URL}"
extract_file "${TARGZ}" "${DOWNLOADDIR}/${LIBXML2FILE}" "${BUILDSRC}"
#cd ${BUILDSRC}/${LIBXML2DIR}
build_package "./configure --prefix=${BUILDDIR}" "${BUILDSRC}/${LIBXML2DIR}"
install_package "${CONCURRENTMAKE} install -s" "${BUILDSRC}/${LIBXML2DIR}"







