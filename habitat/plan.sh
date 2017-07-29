
# much inspiration from https://github.com/habitat-sh/habitat/issues/1514

pkg_name=DistrictBuilder
pkg_origin=codeforphilly
pkg_maintainer="Chris Alfano <chris@codeforphilly.org>"
pkg_description="DistrictBuilder is web-based, open source software for collaborative redistricting."
pkg_upstream_url="https://github.com/PublicMapping/DistrictBuilder"
pkg_license=('Apache-2.0')

# commented out to use local git source instead
#pkg_source="https://github.com/PublicMapping/${pkg_name}/archive/v${pkg_version}.tar.gz"
#pkg_shasum="98127fc80354e7e92aa491643214cac5a29f748cc4a15376a4570e2ce017fcea"

pkg_build_deps=(
  core/virtualenv
  core/git
  core/coreutils
  core/gcc
  core/zlib
  core/libjpeg-turbo
)

pkg_deps=(
  core/glibc
  core/gcc-libs
  core/python2
  core/cacerts
  core/tzdata
  core/libxml2
  core/libxslt
  jarvus/postgresql
)

pkg_bin_dirs=(bin)

# build version string dynamically from git state
pkg_version() {
  echo "${pkg_last_version}+$(git rev-list ${pkg_last_tag}..${pkg_commit} --count)#${pkg_commit}"
}

do_before() {
  do_default_before

  pkg_commit="$(git rev-parse --short HEAD)"
  pkg_last_tag="$(git describe --tags --abbrev=0 ${pkg_commit})"
  pkg_last_version=${pkg_last_tag#v}

  update_pkg_version
}

do_prepare() {
  pip install --upgrade pip virtualenv
  virtualenv "$pkg_prefix"
  source "$pkg_prefix/bin/activate"
}

do_build() {
  return 0
}

do_install() {
  # shove alternative root cert location everywhere python things look for it
  export SSL_CERT_FILE="$(pkg_path_for cacerts)/ssl/certs/cacert.pem"
  export PIP_CERT="$(pkg_path_for cacerts)/ssl/certs/cacert.pem"
  export SYSTEM_CERTIFICATE_PATH="$(pkg_path_for cacerts)/ssl/certs"

  cp -R django "$pkg_prefix/"
  cp -R docs "$pkg_prefix/"

  export LD_LIBRARY_PATH="$LD_RUN_PATH"
  export LIBRARY_PATH="$LD_RUN_PATH"

  # we have to pre-install some modules in a certain order to get around `pip` dep problems
  pip install $(grep numpy /src/requirements.txt)
  pip install $(grep scipy /src/requirements.txt)
  pip install -r requirements.txt

  # patch zoneinfo path
  sed -i "s#/usr/share/zoneinfo#$(pkg_path_for tzdata)/share/zoneinfo#" "$pkg_prefix/lib/python2.7/site-packages/django/conf/__init__.py"

  # create wrapper script for setup
  cat > "$pkg_prefix/bin/districtbuilder-setup" <<- EOM
#!/bin/sh

source "$pkg_prefix/bin/activate"

export LIBRARY_PATH="\$LIBRARY_PATH:${LD_RUN_PATH}"
export LD_LIBRARY_PATH="\$LD_LIBRARY_PATH:${LD_RUN_PATH}"
export LD_RUN_PATH="\$LD_RUN_PATH:${LD_RUN_PATH}"

cd "$pkg_prefix/django/publicmapping"

exec python setup.py "../../docs/config.xsd" "../../config/config.xml"
EOM

    chmod +x "$pkg_prefix/bin/districtbuilder-setup"
}

do_strip() {
  return 0
}
