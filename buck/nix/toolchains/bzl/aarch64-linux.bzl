# SPDX-License-Identifier: MIT OR Apache-2.0

# NOTE: DO NOT EDIT MANUALLY!
# NOTE: This file is @generated by the following command:
#
#    buck run nix//:update -- -t
#
# NOTE: Please run the above command to regenerate this file.

# @nix//toolchains/data.bzl -- nix dependency graph information for buck

# A mapping of all publicly available toolchains for Buck targets to consume,
# keyed by name, with their Nix hash as the value.
toolchains = {
  "bash": "m2pzqajv8wdqf2xby234qyjmjn8a82sh-bash-5.1-p16",
  "lua": "i3mbwpzkqw1ch9wpq6ws00gq2zzvf0mi-lua-5.3.6",
  "nodejs": "fhshz0353jmjg8mfg554czhgxkvy52z3-nodejs-18.12.1",
  "rust-nightly": "nzmhxq56r8fmdszpqm9scn7js5mymm31-rust-default-1.68.0-nightly-2022-12-15",
  "rust-stable": "c59lrbdmbry0fjfb0xa49v2ls4ly5wad-rust-default-1.65.0",
  "tar": "jf1jyi8yb92r099fhji33xymgyp60xlj-coreutils-9.1",
  "zip": "ccrvx330h0nx6q244j2szlvm3ngznlnj-zip-3.0"
}

# The "shallow" dependency graph of all Nix hashes, keyed by Nix hash, with
# the value being a list of Nix hashes that are referenced by the key.
# This graph is used to download dependencies on-demand when building targets,
# but is not publicly exposed; only 'toolchains' is.
depgraph = {
  "05d349nakfzyk7z93lx37qad6xi58fny-zlib-1.2.13": {
    "d": "qhv814dnawzcb8lxndjkvzvaipjh5z1f-zlib-1.2.13.drv",
    "r": [
      "rffjqjvamcclh8s0918a6s6v1171b6z4-glibc-2.35-163"
    ]
  },
  "097ssf36yf1mcj75a3c14j393pfi5r33-libffi-3.4.4": {
    "d": "cx01r379kjb5rmiwsppmcf05awkhiaba-libffi-3.4.4.drv",
    "r": [
      "rffjqjvamcclh8s0918a6s6v1171b6z4-glibc-2.35-163"
    ]
  },
  "171hvl0wrb7kfczdxcp06g3zvv6h1m0k-clippy-preview-1.68.0-nightly-2022-12-15-aarch64-unknown-linux-gnu": {
    "d": "mj67s2bla9hxlsjb1cv3vmj3zi1is62f-clippy-preview-1.68.0-nightly-2022-12-15-aarch64-unknown-linux-gnu.drv",
    "r": [
      "rffjqjvamcclh8s0918a6s6v1171b6z4-glibc-2.35-163",
      "sg8qqz535rn0j0vhacl2x451j8qc89b2-rustc-1.68.0-nightly-2022-12-15-aarch64-unknown-linux-gnu"
    ]
  },
  "1xvxfn17w4dy7ylvcbw7bbqy9y6v4fa6-icu4c-72.1": {
    "d": "c8riwspn399fjlyjwy90vqdpax3vwqkw-icu4c-72.1.drv",
    "r": [
      "8f0fyy8853qiv4y0ms6sd1jaxhiyq9rd-gcc-9.5.0-lib",
      "m2pzqajv8wdqf2xby234qyjmjn8a82sh-bash-5.1-p16",
      "rffjqjvamcclh8s0918a6s6v1171b6z4-glibc-2.35-163"
    ]
  },
  "2l8c14098di8d670xzwcnjjkig0gjpv3-rustfmt-preview-1.65.0-aarch64-unknown-linux-gnu": {
    "d": "04fhzmclnpk5kl6fx7pbyfjxdsm8jgh1-rustfmt-preview-1.65.0-aarch64-unknown-linux-gnu.drv",
    "r": [
      "rffjqjvamcclh8s0918a6s6v1171b6z4-glibc-2.35-163"
    ]
  },
  "5bq5nylsvmic2f89h706q8why5s1px68-rustc-1.65.0-aarch64-unknown-linux-gnu": {
    "d": "yssbbpi3l7pnjdm8inl9rnrssk3c8zd0-rustc-1.65.0-aarch64-unknown-linux-gnu.drv",
    "r": [
      "m2pzqajv8wdqf2xby234qyjmjn8a82sh-bash-5.1-p16",
      "rffjqjvamcclh8s0918a6s6v1171b6z4-glibc-2.35-163"
    ]
  },
  "68k91b9yvqmkkhyhmhcj98ab1lbx06d1-glibc-2.35-163-bin": {
    "d": "55rnrc5xnv3318dfkzmshkcgkw9km176-glibc-2.35-163.drv",
    "r": [
      "rffjqjvamcclh8s0918a6s6v1171b6z4-glibc-2.35-163"
    ]
  },
  "6vmyxrq32ir6i1wazpv6khfx56l153jj-clippy-preview-1.65.0-aarch64-unknown-linux-gnu": {
    "d": "40n9j03wqgxspcdk6p8pn2z8rw5r31m1-clippy-preview-1.65.0-aarch64-unknown-linux-gnu.drv",
    "r": [
      "5bq5nylsvmic2f89h706q8why5s1px68-rustc-1.65.0-aarch64-unknown-linux-gnu",
      "rffjqjvamcclh8s0918a6s6v1171b6z4-glibc-2.35-163"
    ]
  },
  "7bhpcsf1gp0vblmm7pvz3brf4c6l78cx-libidn2-2.3.2": {
    "d": "7x7skx3q08i1pxg1nhi0kd8chhlk0qll-libidn2-2.3.2.drv",
    "r": [
      "lz3vvba0zz9aw2qmlqnr04m502a21jh5-libunistring-1.0"
    ]
  },
  "7hxj9cvwy9bsy6dza4lybzdgr5h146ng-icu4c-72.1-dev": {
    "d": "c8riwspn399fjlyjwy90vqdpax3vwqkw-icu4c-72.1.drv",
    "r": [
      "1xvxfn17w4dy7ylvcbw7bbqy9y6v4fa6-icu4c-72.1",
      "8f0fyy8853qiv4y0ms6sd1jaxhiyq9rd-gcc-9.5.0-lib",
      "jf1jyi8yb92r099fhji33xymgyp60xlj-coreutils-9.1",
      "m2pzqajv8wdqf2xby234qyjmjn8a82sh-bash-5.1-p16",
      "rffjqjvamcclh8s0918a6s6v1171b6z4-glibc-2.35-163"
    ]
  },
  "812h0rhjvd8bvfwqfyzjscgc53wdzvaw-bzip2-1.0.8": {
    "d": "x7xpcgwrjdgdpi4lx748w6ms06l3rkjd-bzip2-1.0.8.drv",
    "r": [
      "rffjqjvamcclh8s0918a6s6v1171b6z4-glibc-2.35-163"
    ]
  },
  "81dvbk3zdlnf7inma5ya6cp33lryshnz-openssl-3.0.7": {
    "d": "9h0lp6mg69z68iwxr4rs345lm85bjjpb-openssl-3.0.7.drv",
    "r": [
      "rffjqjvamcclh8s0918a6s6v1171b6z4-glibc-2.35-163"
    ]
  },
  "8f0fyy8853qiv4y0ms6sd1jaxhiyq9rd-gcc-9.5.0-lib": {
    "d": "585h23xfj8m0qp9y9vmc1gr7prl3fj16-gcc-9.5.0.drv",
    "r": [
      "rffjqjvamcclh8s0918a6s6v1171b6z4-glibc-2.35-163"
    ]
  },
  "9vqhybhahdp7da626ncn5g7xdssh21ni-perl-5.36.0": {
    "d": "12xbk4mbdd4xdsf9p1cgg0giy996b5pn-perl-5.36.0.drv",
    "r": [
      "05d349nakfzyk7z93lx37qad6xi58fny-zlib-1.2.13",
      "cx7pwdl9mq3j3apxbi9v0crljsah8pc1-libxcrypt-4.4.33",
      "jf1jyi8yb92r099fhji33xymgyp60xlj-coreutils-9.1",
      "rffjqjvamcclh8s0918a6s6v1171b6z4-glibc-2.35-163"
    ]
  },
  "a4mxn4700147vkzjs8qv7m045lwy19ln-glibc-2.35-163-dev": {
    "d": "55rnrc5xnv3318dfkzmshkcgkw9km176-glibc-2.35-163.drv",
    "r": [
      "68k91b9yvqmkkhyhmhcj98ab1lbx06d1-glibc-2.35-163-bin",
      "r3mqy4ijlfp8jl4xhgwwzmi6gl1ap4s9-linux-headers-6.0",
      "rffjqjvamcclh8s0918a6s6v1171b6z4-glibc-2.35-163"
    ]
  },
  "a8qm6nb1bhhw0dscllk1ldbdq0qghxl2-rustfmt-preview-1.68.0-nightly-2022-12-15-aarch64-unknown-linux-gnu": {
    "d": "c81zvrkf4lp5hznr8ha1fp6gj25bz997-rustfmt-preview-1.68.0-nightly-2022-12-15-aarch64-unknown-linux-gnu.drv",
    "r": [
      "rffjqjvamcclh8s0918a6s6v1171b6z4-glibc-2.35-163"
    ]
  },
  "am4x4v61lwcvvxw5jx7bmc6awiwry1a6-rust-std-1.68.0-nightly-2022-12-15-aarch64-unknown-linux-gnu": {
    "d": "qcq972m9r4kb4lsx71zr8a42hz56mrwp-rust-std-1.68.0-nightly-2022-12-15-aarch64-unknown-linux-gnu.drv",
    "r": []
  },
  "bda8c620yv01il2fyk0ij5f82wb2qzbq-expat-2.5.0": {
    "d": "v591fx3fwhzpzwfzc6ywk275z9sbf28p-expat-2.5.0.drv",
    "r": [
      "rffjqjvamcclh8s0918a6s6v1171b6z4-glibc-2.35-163"
    ]
  },
  "c59lrbdmbry0fjfb0xa49v2ls4ly5wad-rust-default-1.65.0": {
    "d": "gpsdn1nq18c59vcmbqi51zjxd25ka9dm-rust-default-1.65.0.drv",
    "r": [
      "2l8c14098di8d670xzwcnjjkig0gjpv3-rustfmt-preview-1.65.0-aarch64-unknown-linux-gnu",
      "5bq5nylsvmic2f89h706q8why5s1px68-rustc-1.65.0-aarch64-unknown-linux-gnu",
      "6vmyxrq32ir6i1wazpv6khfx56l153jj-clippy-preview-1.65.0-aarch64-unknown-linux-gnu",
      "j4gkmmn4a6sxfx1bvhsg71bsrik472kn-rust-docs-1.65.0-aarch64-unknown-linux-gnu",
      "rffjqjvamcclh8s0918a6s6v1171b6z4-glibc-2.35-163",
      "vhc8xl6ja9mp9hmmhbd7915wbzalvgxy-gcc-wrapper-9.5.0",
      "xlwc3mkycxbpbrdvndfh64ybih642nxc-rust-std-1.65.0-aarch64-unknown-linux-gnu",
      "y6srrgd8nz1g6055zbh18h9wazjiabsk-cargo-1.65.0-aarch64-unknown-linux-gnu"
    ]
  },
  "ccrvx330h0nx6q244j2szlvm3ngznlnj-zip-3.0": {
    "d": "855s4l8rig9hi9qhxi2z3h6w4c506frd-zip-3.0.drv",
    "r": [
      "rffjqjvamcclh8s0918a6s6v1171b6z4-glibc-2.35-163"
    ]
  },
  "cx7pwdl9mq3j3apxbi9v0crljsah8pc1-libxcrypt-4.4.33": {
    "d": "dff80h8ln9rk0rm7dv278gmhzhmjbml5-libxcrypt-4.4.33.drv",
    "r": [
      "rffjqjvamcclh8s0918a6s6v1171b6z4-glibc-2.35-163"
    ]
  },
  "dfqffscaqaxnr19vwi1pa2yhxsy12lsi-binutils-wrapper-2.39": {
    "d": "dirl8adzvnihk4ky70faf0lrb90fsvdb-binutils-wrapper-2.39.drv",
    "r": [
      "68k91b9yvqmkkhyhmhcj98ab1lbx06d1-glibc-2.35-163-bin",
      "a4mxn4700147vkzjs8qv7m045lwy19ln-glibc-2.35-163-dev",
      "jf1jyi8yb92r099fhji33xymgyp60xlj-coreutils-9.1",
      "m2pzqajv8wdqf2xby234qyjmjn8a82sh-bash-5.1-p16",
      "rffjqjvamcclh8s0918a6s6v1171b6z4-glibc-2.35-163",
      "v5y3dyp58n6rbmkg315hl3mk26vni72c-expand-response-params",
      "zbp2n6crcrs8r2bys001abx2qhpb97y5-binutils-2.39"
    ]
  },
  "drs70q4w5sc0nigib3m7an0lc6asimps-python3-3.10.8": {
    "d": "17jl1dyjy0f4h2a88sz2daw1zyy97728-python3-3.10.8.drv",
    "r": [
      "05d349nakfzyk7z93lx37qad6xi58fny-zlib-1.2.13",
      "097ssf36yf1mcj75a3c14j393pfi5r33-libffi-3.4.4",
      "812h0rhjvd8bvfwqfyzjscgc53wdzvaw-bzip2-1.0.8",
      "81dvbk3zdlnf7inma5ya6cp33lryshnz-openssl-3.0.7",
      "bda8c620yv01il2fyk0ij5f82wb2qzbq-expat-2.5.0",
      "cx7pwdl9mq3j3apxbi9v0crljsah8pc1-libxcrypt-4.4.33",
      "gr2vp9441akswa3nmfm3p7k98cp9qhaz-ncurses-6.3-p20220507",
      "ikf6kr3r0fsg1xsimv50drim5vvgynlm-gdbm-1.23",
      "m2pzqajv8wdqf2xby234qyjmjn8a82sh-bash-5.1-p16",
      "rffjqjvamcclh8s0918a6s6v1171b6z4-glibc-2.35-163",
      "v0rf6ach8mr7l54w41yhxwh9a2iw6vqm-xz-5.2.7",
      "vxvxysgcnh2pcmw9lgf9c4nfzsmaxlkv-readline-6.3p08",
      "wc34gis9i79ss935acni3garnq4kr79g-mailcap-2.1.53",
      "x2dfc8vz0kymvyb8mv3bgjpp6fv8vhfs-tzdata-2022f",
      "xx0nd20rwsqcy752kvlw5i3myr30ymhm-sqlite-3.40.0"
    ]
  },
  "fhshz0353jmjg8mfg554czhgxkvy52z3-nodejs-18.12.1": {
    "d": "703wdw93pqwhybr7brclsncjc8d6vrpx-nodejs-18.12.1.drv",
    "r": [
      "05d349nakfzyk7z93lx37qad6xi58fny-zlib-1.2.13",
      "1xvxfn17w4dy7ylvcbw7bbqy9y6v4fa6-icu4c-72.1",
      "7hxj9cvwy9bsy6dza4lybzdgr5h146ng-icu4c-72.1-dev",
      "8f0fyy8853qiv4y0ms6sd1jaxhiyq9rd-gcc-9.5.0-lib",
      "drs70q4w5sc0nigib3m7an0lc6asimps-python3-3.10.8",
      "jkndyscznif6yj7xl2ws2n6pnjqm3rfq-libuv-1.44.2",
      "m2pzqajv8wdqf2xby234qyjmjn8a82sh-bash-5.1-p16",
      "rcqavjnkfjj0yifi2zph7d6x78l9zps6-openssl-3.0.7",
      "rffjqjvamcclh8s0918a6s6v1171b6z4-glibc-2.35-163",
      "v6b21gx4n7glqbzwhbs42bd8ankizdi1-zlib-1.2.13-dev",
      "wccm7vp6m224k0jwkf24m02ngp407f2f-openssl-3.0.7-dev"
    ]
  },
  "gr2vp9441akswa3nmfm3p7k98cp9qhaz-ncurses-6.3-p20220507": {
    "d": "vynb93452lrd3wmhmx87pvlg5128q3sz-ncurses-6.3-p20220507.drv",
    "r": [
      "rffjqjvamcclh8s0918a6s6v1171b6z4-glibc-2.35-163"
    ]
  },
  "i3mbwpzkqw1ch9wpq6ws00gq2zzvf0mi-lua-5.3.6": {
    "d": "725vgnlgvl72bwx5kj7zvn28d8ywss6a-lua-5.3.6.drv",
    "r": [
      "gr2vp9441akswa3nmfm3p7k98cp9qhaz-ncurses-6.3-p20220507",
      "rffjqjvamcclh8s0918a6s6v1171b6z4-glibc-2.35-163",
      "vxvxysgcnh2pcmw9lgf9c4nfzsmaxlkv-readline-6.3p08"
    ]
  },
  "i8lk3z9dc4y1lk7f8p2n4cq06k93klnr-attr-2.5.1": {
    "d": "2wixxwrsxdarx7y859cz94wihiphskdk-attr-2.5.1.drv",
    "r": [
      "rffjqjvamcclh8s0918a6s6v1171b6z4-glibc-2.35-163"
    ]
  },
  "ikf6kr3r0fsg1xsimv50drim5vvgynlm-gdbm-1.23": {
    "d": "31ckx9k64y30fj3y2d0dsv44kvbj4k8h-gdbm-1.23.drv",
    "r": [
      "rffjqjvamcclh8s0918a6s6v1171b6z4-glibc-2.35-163"
    ]
  },
  "j4gkmmn4a6sxfx1bvhsg71bsrik472kn-rust-docs-1.65.0-aarch64-unknown-linux-gnu": {
    "d": "2ijw96ch52fnxsyxcirl7sw5swgmn5s4-rust-docs-1.65.0-aarch64-unknown-linux-gnu.drv",
    "r": []
  },
  "jf1jyi8yb92r099fhji33xymgyp60xlj-coreutils-9.1": {
    "d": "fwr226d9nklgl8hd5398d4nx3v86ki9h-coreutils-9.1.drv",
    "r": [
      "i8lk3z9dc4y1lk7f8p2n4cq06k93klnr-attr-2.5.1",
      "q14yvyvv6fy7sd8i5a85wlr7nfda2057-gmp-with-cxx-stage4-6.2.1",
      "rffjqjvamcclh8s0918a6s6v1171b6z4-glibc-2.35-163",
      "ywyd7q9ay9frhhfpx1jkz60bzdi6mj2j-acl-2.3.1"
    ]
  },
  "jkndyscznif6yj7xl2ws2n6pnjqm3rfq-libuv-1.44.2": {
    "d": "gp6z1qi26m4zs4w7lii3rqy8bdg950yl-libuv-1.44.2.drv",
    "r": [
      "rffjqjvamcclh8s0918a6s6v1171b6z4-glibc-2.35-163"
    ]
  },
  "kbhp25h17d6xy9yvqbfdnxhlcrgqdxf8-cargo-1.68.0-nightly-2022-12-15-aarch64-unknown-linux-gnu": {
    "d": "mrpaqmi8ji3zd99b66cf74n8pmr27v3v-cargo-1.68.0-nightly-2022-12-15-aarch64-unknown-linux-gnu.drv",
    "r": [
      "rffjqjvamcclh8s0918a6s6v1171b6z4-glibc-2.35-163"
    ]
  },
  "kl3vkw90k84pv17ia8yi95smd6rcd8vf-rust-docs-1.68.0-nightly-2022-12-15-aarch64-unknown-linux-gnu": {
    "d": "0d39rq00bmgk2ppjmmrl0f1gxl8vn1ix-rust-docs-1.68.0-nightly-2022-12-15-aarch64-unknown-linux-gnu.drv",
    "r": []
  },
  "lz3vvba0zz9aw2qmlqnr04m502a21jh5-libunistring-1.0": {
    "d": "bn5h147nqa1437wlprbrl65lava6aj9l-libunistring-1.0.drv",
    "r": []
  },
  "m2pzqajv8wdqf2xby234qyjmjn8a82sh-bash-5.1-p16": {
    "d": "1va5jjmyh9h99fra0m8pmz0yfgfccf28-bash-5.1-p16.drv",
    "r": [
      "rffjqjvamcclh8s0918a6s6v1171b6z4-glibc-2.35-163"
    ]
  },
  "nzmhxq56r8fmdszpqm9scn7js5mymm31-rust-default-1.68.0-nightly-2022-12-15": {
    "d": "q95javrplvim1158f9p72anskiy7hk3b-rust-default-1.68.0-nightly-2022-12-15.drv",
    "r": [
      "171hvl0wrb7kfczdxcp06g3zvv6h1m0k-clippy-preview-1.68.0-nightly-2022-12-15-aarch64-unknown-linux-gnu",
      "a8qm6nb1bhhw0dscllk1ldbdq0qghxl2-rustfmt-preview-1.68.0-nightly-2022-12-15-aarch64-unknown-linux-gnu",
      "am4x4v61lwcvvxw5jx7bmc6awiwry1a6-rust-std-1.68.0-nightly-2022-12-15-aarch64-unknown-linux-gnu",
      "kbhp25h17d6xy9yvqbfdnxhlcrgqdxf8-cargo-1.68.0-nightly-2022-12-15-aarch64-unknown-linux-gnu",
      "kl3vkw90k84pv17ia8yi95smd6rcd8vf-rust-docs-1.68.0-nightly-2022-12-15-aarch64-unknown-linux-gnu",
      "rffjqjvamcclh8s0918a6s6v1171b6z4-glibc-2.35-163",
      "sg8qqz535rn0j0vhacl2x451j8qc89b2-rustc-1.68.0-nightly-2022-12-15-aarch64-unknown-linux-gnu",
      "vhc8xl6ja9mp9hmmhbd7915wbzalvgxy-gcc-wrapper-9.5.0"
    ]
  },
  "q14yvyvv6fy7sd8i5a85wlr7nfda2057-gmp-with-cxx-stage4-6.2.1": {
    "d": "jvn5ywzznsqlra14jk7675k540y55js1-gmp-with-cxx-stage4-6.2.1.drv",
    "r": [
      "8f0fyy8853qiv4y0ms6sd1jaxhiyq9rd-gcc-9.5.0-lib",
      "rffjqjvamcclh8s0918a6s6v1171b6z4-glibc-2.35-163"
    ]
  },
  "qz44cwvslb7fyn8hc4ckvls2d2rw133n-gnugrep-3.7": {
    "d": "1d78zpwm4kphkn2zr2s9m4jm46j9r2kh-gnugrep-3.7.drv",
    "r": [
      "rffjqjvamcclh8s0918a6s6v1171b6z4-glibc-2.35-163",
      "wm43m5dyh89w5b4lnh17ifs0g4jh96b2-pcre-8.45"
    ]
  },
  "r3mqy4ijlfp8jl4xhgwwzmi6gl1ap4s9-linux-headers-6.0": {
    "d": "dkb8ifwj17vr5h84jks0cwbmvgwv4kq2-linux-headers-6.0.drv",
    "r": []
  },
  "rcqavjnkfjj0yifi2zph7d6x78l9zps6-openssl-3.0.7": {
    "d": "yhmlranynb15ryc56j0py2440k6ny8qc-openssl-3.0.7.drv",
    "r": [
      "rffjqjvamcclh8s0918a6s6v1171b6z4-glibc-2.35-163"
    ]
  },
  "rffjqjvamcclh8s0918a6s6v1171b6z4-glibc-2.35-163": {
    "d": "55rnrc5xnv3318dfkzmshkcgkw9km176-glibc-2.35-163.drv",
    "r": [
      "7bhpcsf1gp0vblmm7pvz3brf4c6l78cx-libidn2-2.3.2"
    ]
  },
  "sg8qqz535rn0j0vhacl2x451j8qc89b2-rustc-1.68.0-nightly-2022-12-15-aarch64-unknown-linux-gnu": {
    "d": "a3ljvd82acx7n3pikqnjrqclr74pwwxi-rustc-1.68.0-nightly-2022-12-15-aarch64-unknown-linux-gnu.drv",
    "r": [
      "m2pzqajv8wdqf2xby234qyjmjn8a82sh-bash-5.1-p16",
      "rffjqjvamcclh8s0918a6s6v1171b6z4-glibc-2.35-163"
    ]
  },
  "v0rf6ach8mr7l54w41yhxwh9a2iw6vqm-xz-5.2.7": {
    "d": "irpzyajs63knin2864w2l0b6pi352qlh-xz-5.2.7.drv",
    "r": [
      "rffjqjvamcclh8s0918a6s6v1171b6z4-glibc-2.35-163"
    ]
  },
  "v5y3dyp58n6rbmkg315hl3mk26vni72c-expand-response-params": {
    "d": "airr5w65b6y08lpca595sbma23qghsrf-expand-response-params.drv",
    "r": [
      "rffjqjvamcclh8s0918a6s6v1171b6z4-glibc-2.35-163"
    ]
  },
  "v6b21gx4n7glqbzwhbs42bd8ankizdi1-zlib-1.2.13-dev": {
    "d": "qhv814dnawzcb8lxndjkvzvaipjh5z1f-zlib-1.2.13.drv",
    "r": [
      "05d349nakfzyk7z93lx37qad6xi58fny-zlib-1.2.13"
    ]
  },
  "vhc8xl6ja9mp9hmmhbd7915wbzalvgxy-gcc-wrapper-9.5.0": {
    "d": "j53dz97f866cqz0rkfhjbg18kj2sv67l-gcc-wrapper-9.5.0.drv",
    "r": [
      "68k91b9yvqmkkhyhmhcj98ab1lbx06d1-glibc-2.35-163-bin",
      "8f0fyy8853qiv4y0ms6sd1jaxhiyq9rd-gcc-9.5.0-lib",
      "a4mxn4700147vkzjs8qv7m045lwy19ln-glibc-2.35-163-dev",
      "dfqffscaqaxnr19vwi1pa2yhxsy12lsi-binutils-wrapper-2.39",
      "jf1jyi8yb92r099fhji33xymgyp60xlj-coreutils-9.1",
      "m2pzqajv8wdqf2xby234qyjmjn8a82sh-bash-5.1-p16",
      "qz44cwvslb7fyn8hc4ckvls2d2rw133n-gnugrep-3.7",
      "rffjqjvamcclh8s0918a6s6v1171b6z4-glibc-2.35-163",
      "v5y3dyp58n6rbmkg315hl3mk26vni72c-expand-response-params",
      "vqahla84p6l26vg2wdan1kmfkxddmvsv-gcc-9.5.0"
    ]
  },
  "vqahla84p6l26vg2wdan1kmfkxddmvsv-gcc-9.5.0": {
    "d": "585h23xfj8m0qp9y9vmc1gr7prl3fj16-gcc-9.5.0.drv",
    "r": [
      "05d349nakfzyk7z93lx37qad6xi58fny-zlib-1.2.13",
      "8f0fyy8853qiv4y0ms6sd1jaxhiyq9rd-gcc-9.5.0-lib",
      "a4mxn4700147vkzjs8qv7m045lwy19ln-glibc-2.35-163-dev",
      "rffjqjvamcclh8s0918a6s6v1171b6z4-glibc-2.35-163"
    ]
  },
  "vxvxysgcnh2pcmw9lgf9c4nfzsmaxlkv-readline-6.3p08": {
    "d": "767ghzppx8la4dziprrr495v890aj1cn-readline-6.3p08.drv",
    "r": [
      "gr2vp9441akswa3nmfm3p7k98cp9qhaz-ncurses-6.3-p20220507",
      "rffjqjvamcclh8s0918a6s6v1171b6z4-glibc-2.35-163"
    ]
  },
  "wc34gis9i79ss935acni3garnq4kr79g-mailcap-2.1.53": {
    "d": "qd8jns3lh2xbgdk84p1ml6mx6fhfh3m6-mailcap-2.1.53.drv",
    "r": []
  },
  "wccm7vp6m224k0jwkf24m02ngp407f2f-openssl-3.0.7-dev": {
    "d": "yhmlranynb15ryc56j0py2440k6ny8qc-openssl-3.0.7.drv",
    "r": [
      "rcqavjnkfjj0yifi2zph7d6x78l9zps6-openssl-3.0.7",
      "wmh78j8fssw9jnj0pmgkj1s0jd6sshiy-openssl-3.0.7-bin"
    ]
  },
  "wm43m5dyh89w5b4lnh17ifs0g4jh96b2-pcre-8.45": {
    "d": "x9h8jzzv64rrg628cwidj9s2yp2v4aqi-pcre-8.45.drv",
    "r": [
      "rffjqjvamcclh8s0918a6s6v1171b6z4-glibc-2.35-163"
    ]
  },
  "wmh78j8fssw9jnj0pmgkj1s0jd6sshiy-openssl-3.0.7-bin": {
    "d": "yhmlranynb15ryc56j0py2440k6ny8qc-openssl-3.0.7.drv",
    "r": [
      "9vqhybhahdp7da626ncn5g7xdssh21ni-perl-5.36.0",
      "rcqavjnkfjj0yifi2zph7d6x78l9zps6-openssl-3.0.7",
      "rffjqjvamcclh8s0918a6s6v1171b6z4-glibc-2.35-163"
    ]
  },
  "x2dfc8vz0kymvyb8mv3bgjpp6fv8vhfs-tzdata-2022f": {
    "d": "64gvxri0jh7kabrv0ssmg3j4ckrwh859-tzdata-2022f.drv",
    "r": []
  },
  "xlwc3mkycxbpbrdvndfh64ybih642nxc-rust-std-1.65.0-aarch64-unknown-linux-gnu": {
    "d": "hd0iby4pgbjin9v20xqmsnff0id3fkqw-rust-std-1.65.0-aarch64-unknown-linux-gnu.drv",
    "r": []
  },
  "xx0nd20rwsqcy752kvlw5i3myr30ymhm-sqlite-3.40.0": {
    "d": "6z0v3zxsvcv4604hqbks30j7fyn3r9bj-sqlite-3.40.0.drv",
    "r": [
      "05d349nakfzyk7z93lx37qad6xi58fny-zlib-1.2.13",
      "rffjqjvamcclh8s0918a6s6v1171b6z4-glibc-2.35-163"
    ]
  },
  "y6srrgd8nz1g6055zbh18h9wazjiabsk-cargo-1.65.0-aarch64-unknown-linux-gnu": {
    "d": "1r8q5vpq1i3zvcmnv2mrjbw7lycz9dri-cargo-1.65.0-aarch64-unknown-linux-gnu.drv",
    "r": [
      "rffjqjvamcclh8s0918a6s6v1171b6z4-glibc-2.35-163"
    ]
  },
  "ywyd7q9ay9frhhfpx1jkz60bzdi6mj2j-acl-2.3.1": {
    "d": "9lcs73crf56pbnv6rkyr6xi9flmxzddm-acl-2.3.1.drv",
    "r": [
      "i8lk3z9dc4y1lk7f8p2n4cq06k93klnr-attr-2.5.1",
      "rffjqjvamcclh8s0918a6s6v1171b6z4-glibc-2.35-163"
    ]
  },
  "zbp2n6crcrs8r2bys001abx2qhpb97y5-binutils-2.39": {
    "d": "a3j7yxjsvvng1wr1ws05w1sg44wfcgji-binutils-2.39.drv",
    "r": [
      "05d349nakfzyk7z93lx37qad6xi58fny-zlib-1.2.13",
      "8f0fyy8853qiv4y0ms6sd1jaxhiyq9rd-gcc-9.5.0-lib",
      "rffjqjvamcclh8s0918a6s6v1171b6z4-glibc-2.35-163"
    ]
  }
}
