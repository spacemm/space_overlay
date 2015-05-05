# Copyright 1999-2014 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-video/ffmpeg/ffmpeg-0.10.7.ebuild,v 1.10 2013/04/13 07:42:54 ago Exp $

EAPI="4"

inherit eutils flag-o-matic multilib toolchain-funcs

DESCRIPTION="Old ffmpeg libs for use with AceStream, does not conflict with ffmpeg"
HOMEPAGE="http://ffmpeg.org/"
MY_PN="ffmpeg"
if [ "${PV%_p*}" != "${PV}" ] ; then # Snapshot
	SRC_URI="mirror://gentoo/${MY_PN}-${PV}.tar.bz2"
else # Release
	SRC_URI="http://ffmpeg.org/releases/${MY_PN}-${PV/_/-}.tar.bz2"
fi
FFMPEG_REVISION="${PV#*_p}"

LICENSE="GPL-2 amr? ( GPL-3 ) encode? ( aac? ( GPL-3 ) )"
SLOT="0"
KEYWORDS="~x86 ~amd64"
IUSE="
	aac aacplus alsa amr bindist +bzip2 cdio celt cpudetection debug
	dirac doc +encode faac frei0r gnutls gsm +hardcoded-tables ieee1394 jack
	jpeg2k libass libv4l modplug mp3 network openal openssl oss pic pulseaudio
	rtmp schroedinger sdl speex static-libs test theora threads
	truetype v4l vaapi vdpau vorbis vpx X xvid +zlib
	"

# String for CPU features in the useflag[:configure_option] form
# if :configure_option isn't set, it will use 'useflag' as configure option
CPU_FEATURES="3dnow:amd3dnow 3dnowext:amd3dnowext altivec avx mmx mmxext:mmx2 ssse3 vis neon"

for i in ${CPU_FEATURES}; do
	IUSE="${IUSE} ${i%:*}"
done

RDEPEND="
	alsa? ( media-libs/alsa-lib )
	amr? ( media-libs/opencore-amr )
	bzip2? ( app-arch/bzip2 )
	cdio? ( || ( dev-libs/libcdio-paranoia <dev-libs/libcdio-0.90[-minimal] ) )
	celt? ( >=media-libs/celt-0.11.1 )
	dirac? ( media-video/dirac )
	>=media-libs/x264-0.0.20111017
	encode? (
		aac? ( media-libs/vo-aacenc )
		aacplus? ( media-libs/libaacplus )
		amr? ( media-libs/vo-amrwbenc )
		faac? ( media-libs/faac )
		mp3? ( >=media-sound/lame-3.98.3 )
		theora? ( >=media-libs/libtheora-1.1.1[encode] media-libs/libogg )
		vorbis? ( media-libs/libvorbis media-libs/libogg )
		xvid? ( >=media-libs/xvid-1.1.0 )
	)
	frei0r? ( media-plugins/frei0r-plugins )
	gnutls? ( >=net-libs/gnutls-2.12.16 )
	gsm? ( >=media-sound/gsm-1.0.12-r1 )
	ieee1394? ( media-libs/libdc1394 sys-libs/libraw1394 )
	jack? ( media-sound/jack-audio-connection-kit )
	jpeg2k? ( >=media-libs/openjpeg-1.3-r2 )
	libass? ( media-libs/libass )
	libv4l? ( media-libs/libv4l )
	modplug? ( media-libs/libmodplug )
	openal? ( >=media-libs/openal-1.1 )
	pulseaudio? ( media-sound/pulseaudio )
	rtmp? ( >=media-video/rtmpdump-2.2f )
	sdl? ( >=media-libs/libsdl-1.2.13-r1[sound,video] )
	schroedinger? ( media-libs/schroedinger )
	speex? ( >=media-libs/speex-1.2_beta3 )
	truetype? ( media-libs/freetype:2 )
	vaapi? ( >=x11-libs/libva-0.32 )
	vdpau? ( x11-libs/libvdpau )
	vpx? ( >=media-libs/libvpx-0.9.6 )
	X? ( x11-libs/libX11 x11-libs/libXext x11-libs/libXfixes )
	zlib? ( sys-libs/zlib )
	!media-video/qt-faststart
	!media-libs/libpostproc
	!media-video/ffmpeg:0.10
	!<media-video/ffmpeg-1.2:0"

DEPEND="${RDEPEND}
	>=sys-devel/make-3.81
	dirac? ( virtual/pkgconfig )
	doc? ( app-text/texi2html )
	gnutls? ( virtual/pkgconfig )
	ieee1394? ( virtual/pkgconfig )
	libv4l? ( virtual/pkgconfig )
	mmx? ( dev-lang/yasm )
	rtmp? ( virtual/pkgconfig )
	schroedinger? ( virtual/pkgconfig )
	test? ( net-misc/wget )
	truetype? ( virtual/pkgconfig )
	v4l? ( sys-kernel/linux-headers )
"
# faac is license-incompatible with ffmpeg
REQUIRED_USE="bindist? ( encode? ( !faac !aacplus ) !openssl )
	libv4l? ( v4l )
	test? ( encode zlib )"

S=${WORKDIR}/${MY_PN}-${PV/_/-}

QA_TEXTRELS="usr/lib/libavcodec.so.53.61.100
usr/lib/libavformat.so.53.32.100
usr/lib/libavutil.so.51.35.100"

src_prepare() {
	if [ "${PV%_p*}" != "${PV}" ] ; then # Snapshot
		export revision=git-N-${FFMPEG_REVISION}
	fi
	epatch "${FILESDIR}/freiordl.patch"
	epatch "${FILESDIR}/flashtest.patch"

	if has_version dev-libs/libcdio-paranoia; then
		sed -i \
			-e 's:cdio/cdda.h:cdio/paranoia/cdda.h:' \
			-e 's:cdio/paranoia.h:cdio/paranoia/paranoia.h:' \
			configure libavdevice/libcdio.c || die
	fi

	if has_version '>=media-libs/freetype-2.5.1';then
		sed 's|freetype/freetype.h|freetype2/freetype.h|' -i configure
		sed 's|freetype/config/ftheader.h|freetype2/config/ftheader.h|' -i libavfilter/vf_drawtext.c
	fi
}

src_configure() {
	local myconf="${EXTRA_FFMPEG_CONF}"
	# Set to --enable-version3 if (L)GPL-3 is required
	local version3=""

	# enabled by default
	for i in debug doc network vaapi vdpau zlib; do
		use ${i} || myconf="${myconf} --disable-${i}"
	done
	use bzip2 || myconf="${myconf} --disable-bzlib"
	use sdl || myconf="${myconf} --disable-ffplay"

	use cpudetection && myconf="${myconf} --enable-runtime-cpudetect"
	use openssl && myconf="${myconf} --enable-openssl --enable-nonfree"
	for i in gnutls ; do
		use $i && myconf="${myconf} --enable-$i"
	done

	# Encoders
	if use encode
	then
		use mp3 && myconf="${myconf} --enable-libmp3lame"
		use aac && { myconf="${myconf} --enable-libvo-aacenc" ; version3=" --enable-version3" ; }
		use amr && { myconf="${myconf} --enable-libvo-amrwbenc" ; version3=" --enable-version3" ; }
		myconf="${myconf} --enable-libx264"
		for i in theora vorbis xvid; do
			use ${i} && myconf="${myconf} --enable-lib${i}"
		done
		use aacplus && myconf="${myconf} --enable-libaacplus --enable-nonfree"
		use faac && myconf="${myconf} --enable-libfaac --enable-nonfree"
	else
		myconf="${myconf} --disable-encoders"
	fi

	# libavdevice options
	use cdio && myconf="${myconf} --enable-libcdio"
	use ieee1394 && myconf="${myconf} --enable-libdc1394"
	use openal && myconf="${myconf} --enable-openal"
	# Indevs
	# v4l1 is gone since linux-headers-2.6.38
	myconf="${myconf} --disable-indev=v4l"
	use v4l || myconf="${myconf} --disable-indev=v4l2"
	for i in alsa oss jack ; do
		use ${i} || myconf="${myconf} --disable-indev=${i}"
	done
	use X && myconf="${myconf} --enable-x11grab"
	use pulseaudio && myconf="${myconf} --enable-libpulse"
	use libv4l && myconf="${myconf} --enable-libv4l2"
	# Outdevs
	for i in alsa oss sdl ; do
		use ${i} || myconf="${myconf} --disable-outdev=${i}"
	done
	# libavfilter options
	use frei0r && myconf="${myconf} --enable-frei0r"
	use truetype && myconf="${myconf} --enable-libfreetype"
	use libass && myconf="${myconf} --enable-libass"

	# Threads; we only support pthread for now but ffmpeg supports more
	use threads && myconf="${myconf} --enable-pthreads"

	# Decoders
	use amr && { myconf="${myconf} --enable-libopencore-amrwb --enable-libopencore-amrnb" ; version3=" --enable-version3" ; }
	for i in celt gsm dirac modplug rtmp schroedinger speex vpx; do
		use ${i} && myconf="${myconf} --enable-lib${i}"
	done
	use jpeg2k && myconf="${myconf} --enable-libopenjpeg"

	# CPU features
	for i in ${CPU_FEATURES}; do
		use ${i%:*} || myconf="${myconf} --disable-${i#*:}"
	done
	if use pic ; then
		myconf="${myconf} --enable-pic"
		# disable asm code if PIC is required
		# as the provided asm decidedly is not PIC for x86.
		use x86 && myconf="${myconf} --disable-asm"
	fi
	[[ ${ABI} == "x32" ]] && myconf+=" --disable-asm" #427004

	# Try to get cpu type based on CFLAGS.
	# Bug #172723
	# We need to do this so that features of that CPU will be better used
	# If they contain an unknown CPU it will not hurt since ffmpeg's configure
	# will just ignore it.
	for i in $(get-flag march) $(get-flag mcpu) $(get-flag mtune) ; do
		[ "${i}" = "native" ] && i="host" # bug #273421
		myconf="${myconf} --cpu=${i}"
		break
	done

	# Mandatory configuration
	myconf="
		--enable-gpl
		${version3}
		--enable-postproc
		--enable-avfilter
		--disable-stripping
		${myconf}"

	# Misc stuff
	use hardcoded-tables && myconf="${myconf} --enable-hardcoded-tables"

	cd "${S}"
	./configure \
		--prefix="${EPREFIX}/usr" \
		--libdir="${EPREFIX}/usr/$(get_libdir)" \
		--shlibdir="${EPREFIX}/usr/$(get_libdir)" \
		--mandir="${EPREFIX}/usr/share/man" \
		--enable-shared \
		--cc="$(tc-getCC)" \
		--cxx="$(tc-getCXX)" \
		--ar="$(tc-getAR)" \
		--optflags="${CFLAGS}" \
		--extra-cflags="${CFLAGS}" \
		--extra-cxxflags="${CXXFLAGS}" \
		$(use_enable static-libs static) \
		${myconf} || die
}

src_install() {
	emake DESTDIR="${D}" install
	rm -r "${D}"/usr/{bin,include,share}
	rm -r "${D}"/usr/lib*/pkgconfig
	rm "${D}"/usr/lib*/{libavcodec.so,libavformat.so,libavutil.so}
	rm "${D}"/usr/lib*/{libavdevice.*,libavfilter.*,libpostproc.*,libswresample.*,libswscale.*}
}
