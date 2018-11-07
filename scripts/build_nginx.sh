#!/bin/bash
# Build NGINX and modules on Heroku.
# This program is designed to run in a web dyno provided by Heroku.
# We would like to build an NGINX binary for the builpack on the
# exact machine in which the binary will run.
# Our motivation for running in a web dyno is that we need a way to
# download the binary once it is built so we can vendor it in the buildpack.
#
# Once the dyno has is 'up' you can open your browser and navigate
# this dyno's directory structure to download the nginx binary.

NGINX_VERSION=${NGINX_VERSION-1.15.6}
PCRE_VERSION=${PCRE_VERSION-8.42}
ZLIB_VERSION=${ZLIB_VERSION-1.2.11}
SET_MISC_VERSION=${SET_MISC_VERSION-0.29}
NGX_DEVEL_KIT_VERSION=${NGX_DEVEL_KIT_VERSION-0.2.19}

nginx_tarball_url=http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz
pcre_tarball_url=ftp://ftp.csx.cam.ac.uk/pub/software/programming/pcre/pcre-${PCRE_VERSION}.tar.gz
zlib_url=http://zlib.net/zlib-${ZLIB_VERSION}.tar.gz
set_misc_tarball_url=https://github.com/openresty/set-misc-nginx-module/archive/v${SET_MISC_VERSION}.tar.gz
ngx_devel_kit_url=https://github.com/simpl/ngx_devel_kit/archive/v${NGX_DEVEL_KIT_VERSION}.tar.gz

temp_dir=$(mktemp -d /tmp/nginx.XXXXXXXXXX)

echo "Serving files from /tmp on $PORT"
cd /tmp
python -m SimpleHTTPServer $PORT &

cd $temp_dir
echo "Temp dir: $temp_dir"

echo "Downloading $nginx_tarball_url"
curl -L $nginx_tarball_url | tar xzv

echo "Downloading $pcre_tarball_url"
(cd nginx-${NGINX_VERSION} && curl -L $pcre_tarball_url | tar xvz )

echo "Downloading $zlib_url"
(cd nginx-${NGINX_VERSION} && curl -L $zlib_url | tar xvz )

echo "Downloading $set_misc_tarball_url"
(cd nginx-${NGINX_VERSION} && curl -L $set_misc_tarball_url | tar xvz )

echo "Downloading $ngx_devel_kit_url"
(cd nginx-${NGINX_VERSION} && curl -L $ngx_devel_kit_url | tar xvz )

(
  cd nginx-${NGINX_VERSION}
  ./configure \
    --with-pcre=pcre-${PCRE_VERSION} \
    --with-zlib=zlib-${ZLIB_VERSION} \
    --prefix=/tmp/nginx \
    --with-http_gzip_static_module \
    --with-http_v2_module \
    --with-cc-opt='-g -O2 -fstack-protector --param=ssp-buffer-size=4 -Wformat -Werror=format-security -Wp,-D_FORTIFY_SOURCE=2' \
    --with-ld-opt='-Wl,-Bsymbolic-functions -Wl,-z,relro -Wl,--as-needed' \
    --add-module=ngx_devel_kit-${NGX_DEVEL_KIT_VERSION} \
    --add-module=set-misc-nginx-module-${SET_MISC_VERSION}

  make install
)

while true
do
  sleep 1
  echo "."
done
