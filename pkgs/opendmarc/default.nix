{ stdenv
, fetchFromGitHub
, autoreconfHook
, makeWrapper
, file
, pkgconfig
, libbsd
, libmilter
, libspf2
, perl
, perlPackages
, publicsuffix-list
}:

stdenv.mkDerivation rec {
  pname = "opendmarc";
  version = "1.4.0";

  src = fetchFromGitHub {
    owner = "trusteddomainproject";
    repo = "OpenDMARC";
    rev = "rel-opendmarc-${builtins.replaceStrings [ "." ] [ "-" ] version}";
    sha256 = "1xw8igfj86l151v0iybhsb2nikl37saww5g2fyv9xgpiq59rx2xf";
  };

  nativeBuildInputs = [ autoreconfHook makeWrapper file pkgconfig ];

  patches = [ ./fix-res_ndestroy-detecting.patch ./fix-docs-references.patch ./fix-mysql-schema.patch ];

  preConfigure = "sed -i 's,/usr/bin/file,${file}/bin/file,g' ./configure";

  configureFlags = [
    "--with-wall"
    "--with-milter=${libmilter}"
    "--with-spf"
    "--with-spf2-include=${libspf2}/include"
    "--with-spf2-lib=${libspf2}/lib"
  ];

  buildInputs = [ libbsd libmilter libspf2 perl publicsuffix-list ];

  outputs = [ "bin" "dev" "out" "doc" ];

  postFixup = ''
    for b in $bin/bin/opendmarc-{expire,import,params,reports}; do
      wrapProgram $b --set PERL5LIB ${perlPackages.makeFullPerlPath (with perlPackages; [ Switch DBI DBDmysql HTTPMessage ])}
    done
  '';

  meta = with stdenv.lib; {
    description = "Free open source software implementation of the DMARC specification";
    homepage = "http://www.trusteddomain.org/opendmarc/";
    maintainers = [{
      email = "zagarin@gmail.com";
      github = "leshik";
      name = "Alexey Zagarin";
    }];
    license = {
      fullName = "The Trusted Domain Project License";
      url = "http://www.opendkim.org/license.html";
    };
    platforms = platforms.unix;
  };
}
