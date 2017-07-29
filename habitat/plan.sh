pkg_name=DistrictBuilder
pkg_origin=codeforphilly
pkg_maintainer="Chris Alfano <chris@codeforphilly.org>"
pkg_description="DistrictBuilder is web-based, open source software for collaborative redistricting."
pkg_upstream_url="https://github.com/PublicMapping/DistrictBuilder"
pkg_license=('Apache-2.0')

# commented out to use local git source instead
#pkg_source="https://github.com/PublicMapping/${pkg_name}/archive/v${pkg_version}.tar.gz"
#pkg_shasum="98127fc80354e7e92aa491643214cac5a29f748cc4a15376a4570e2ce017fcea"

pkg_deps=(
  python2/python
  core/cacerts
  jarvus/postgresql
)

pkg_build_deps=(
  python2/pip
  core/virtualenv
  core/git
  core/coreutils
  core/gcc
  core/zlib
  core/libjpeg-turbo
)

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
  virtualenv "$pkg_prefix"
  # shellcheck source=/dev/null
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

  attach

  pip install -r requirements.txt

  attach

  return $?
}