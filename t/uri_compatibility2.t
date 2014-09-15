use Test;
use URI::XS;
use URI;

BEGIN { plan tests => 144 }

#
# These are cases where URI is just fucked up with side effects.
# for instance URI->host(undef) calls URI->authority to get, and then set
# the values of the port, changing it's return value from undef to something
# else. None of the cases below matter, because the resulting URIs are
# not valid. I for one choose not to implement such fucked-up-ness.
#
my $ignore_error = {
    "host,undef,host"            => 1,
    "host,undef,host_port"       => 1,
    "host,undef,authority"       => 1,
    "authority,undef,canonical"  => 1,
};

while(my $line = <DATA>) {
    chomp($line);

    my($url,$func,$args) = split(/\s+/,$line,3);

    last if (! defined $func);

    my @args = ();
    @args = split(/\s+/,$args) if (defined $args);
    @args = map { if ($_ eq 'undef') { undef } else {$_}} @args;

    $a = URI::XS->new($url);
    $b = URI->new($url);
    if (scalar(@args) <= 0) {
        $a->$func;
        $b->$func;
    }
    else {
        $a->$func(@args);
        $b->$func(@args);
    }

    my $method;
    for $method (qw(path path_query scheme fragment query)) {
        $am = $a->$method;
        $bm = $b->$method;
        if ((!defined($am) && !defined($bm)) || (defined($am) && defined($bm) && $am eq $bm)) {
            ok(1);
        }
        else {
            if (!my_ok($func,$args,$method,0)) {
                print "for url: $url func=$func args = [". join(',',@args) ."]\n";
                $am = "undef" if (!defined($am));
                $bm = "undef" if (!defined($bm));
                print "NEW: method=[$method] [$am]\n";
                print "OLD: method=[$method] [$bm]\n";
            }
        }
    }

    for $method (qw(host host_port authority)) {
        $am = $a->$method;
        $bm = $b->$method;
        if ((!defined($am) && !defined($bm)) || (defined($am) && defined($bm) && lc($am) eq lc($bm))) {
            ok(1);
        }
        else {
            if (!my_ok($func,$args,$method,0)) {
                if (scalar(@args) <= 0) {
                    print "for url: $url func=$func args = [". join(',',@args) ."]\n";
                }
                else {
                    print "for url: $url func=$func args = undef\n";
                }
                $am = "undef" if (!defined($am));
                $bm = "undef" if (!defined($bm));
                print "NEW: [$method] [$am]\n";
                print "OLD: [$method] [$bm]\n";
            }
        }
    }

    # canonical must be last, for URI it changes its parts
    if ($a->canonical eq $b->canonical) {
        ok(1);
    }
    else {
        if (!my_ok($func,$args,"canonical",0)) {
            if (scalar(@args) <= 0) {
                print "for url: $url func=$func args = [". join(',',@args) ."]\n";
            }
            else {
                print "for url: $url func=$func args = undef\n";
            }
            print "NEW: $a\n";
            print "OLD: $b\n";
        }
    }
}

sub my_ok
{
    my($func,$args,$method,$ok) = @_;

    if ($ok) {
        ok($ok);
        return $ok;
    }

    my $k = join(',',$func,$args,$method);
    if ($ignore_error->{"$k"}) {
        # print "Ignoring error: $k\n";
        ok(1);
        return 1;
    }
    else {
        # print "Still an error: $k\n";
        ok(0);
        return 0;
    }

}


# Need to fix?
#   http://ralf.faithweb.com/E%2DMAIN.HTM


__DATA__
http://www.bottlecount.com/ authority undef
http://www.westcoastwine.net/index.html host undef
http://www.wineontheweb.com/ host www.yahoo.com
http://www.wineanswers.com/ port 8080
http://www.cellarnotes.net:8080/ port undef
http://www.warpa.com/ path undef
http://www.sbwines.com/usenet_winefaq/ path undef
http://www.yumyuk.com/path/ host
http://www.enemyvessel.com/ scheme
http://www.damngoodwine.com:8080/ port
http://user:password@www.foobar.com/index.html?q=wtf#orly  host undef
http://user:password@www.foobar.com:8080/index.html?q=wtf#orly host www.example.com
http://user:password@www.foobar.com/index.html?q=wtf#orly host
http://user:password@www.foobar.com:8080/index.html?q=wtf#orly authority
http://user:password@www.foobar.com/index.html?q=wtf#orly authority undef
http://user:password@www.foobar.com:8080/index.html?q=wtf#orly authority www.example.com
http://WWW.ToPiX.Com?q=test#testfrag
http://WWW.ToPiX.Com?q=test
http://www.foobar.com/?
http://www.foobar.com?
http://www.foobar.com/?#frag
http://www.foobar.com?#frag
http://www.iswn.org/
http://www.vino.com/
http://www.bpdr.com/
http://www.boisset.com/
http://www.lafite.com/
http://gallo.com/
http://www.wineeducation.com/
http://www.novusvinum.com/
http://www.wineintro.com/
http://www.allexperts.com/browse.cgi?catLvl=3&catID=1615
http://www.diageowines.com/
http://www.delongwine.com/
http://www.osborne.es/
http://fosters.com.au/enjoy/wine.htm
http://www.fapes.com.ar/
http://www.tapiz.com
http://www.flichman.com.ar/ing/index.html
http://www.bodegacicchitti.com/
http://www.salnet.com.ar/cafayate/VinosyBodegas.htm
http://www.wineanorak.com/targent.htm
http://www.luigibosca.com.ar/
http://www.altavistawines.com/
http://www.bodegahcanale.com/
http://www.lagarde.com.ar/
http://www.bodegaslopez.com.ar/
http://www.terrazasdelosandes.com.ar/
http://www.bodegasalentein.com/cas/bodegas/default.asp
http://www.jeanrivier.com/
http://www.bodegasha.com/home_i.htm
http://www.micheltorino.com.ar
http://www.familiacassone.com.ar/
http://www.odres.com.ar/
http://www.norton.com.ar/?winesofargentina
http://www.geocities.com/bscats/
http://www.jorenecattery.com/
http://home.earthlink.net/~sarsenstone/
http://www.geocities.com/gimsincattery/
http://home.comcast.net/~siamese/
http://www.allexperts.com/browse.cgi?catLvl=3&catID=1606
http://www.fanciers.com/cat-faqs/behavior.shtml#cats_outside
http://www.flickr.com/groups/87781234@N00/
http://www.ursulana.ch/the%20ursulana%20k_p%20project.htm
http://www.yoga.com/ydc/enlighten/enlighten_document.asp?ID=32&;section=8&;cat=0
http://en.wikipedia.org/wiki/Friedrich_H%C3%B6lderlin
http://en.chinabroadcast.cn/349/2005/11/08/Zt44@29442.htm
http://WWW.ToPiX.Com
http://WWW.ToPiX.Com/
http://WWW.ToPiX.Com/?q=test
http://WWW.ToPiX.Com#testfrag
http://WWW.ToPiX.Com/#testfrag
http://WWW.ToPiX.Com/?q=test#testfrag
http://www.skrenta.com/2008/02/amazon_is_the_google_of_buying.html
http://www.skrenta.com/2008/02/amazon_is_the_google_of_buying.html#comments
http://jewelry.ebay.com/_W0QQ_trksidZp3907Q2em21
http://search.ebay.com/search/search.dll?ht=1&from=R4&satitle=iwc&sacat=281%26catref%3DC6
http://www.example.com/what the fuck.html
http://www.example.com/what     the     fuck_with_tabs.html
    http://www.testwhitespace.com/
https://www.bank.com/login.cgi?u=you
http://www.cinewiki.cn/w/%E4%B8%8A%E6%B5%B7%E5%BD%B1%E6%88%8F%E5%85%AC%E5%8F%B8
