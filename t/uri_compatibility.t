use Test::More 'no_plan';
use URI::XS;
use URI;

while($uri = <DATA>) {
    chomp($uri);
    $a = URI::XS->new($uri);
    $b = URI->new($uri);

    # include duplicates of path and path_query to test caching of results
    for my $method (qw(path path_query scheme fragment query path path_query )) {
        $am = $a->$method;
        $bm = $b->$method;
        if ((!defined($am) && !defined($bm)) || (defined($am) && defined($bm) && $am eq $bm)) {
            ok(1);
        }
        else {
            print "for url: $a\n";
            print "for url: $b\n";
            $am = "undef" if (!defined($am));
            $bm = "undef" if (!defined($bm));
            print "NEW: [$method] [$am]\n";
            print "OLD: [$method] [$bm]\n";
            ok(0);
        }
    }

    if (defined($a->scheme)) {
        # URI doesn't know how to deal with these methods without a scheme

        for my $method (qw(host host_port authority)) {
            $am = $a->$method;
            $bm = $b->$method;
            if ((!defined($am) && !defined($bm)) || (defined($am) && defined($bm) && lc($am) eq lc($bm))) {
                ok(1);
            }
            else {
                print "for url: $a\n";
                print "NEW: [$method] [$am]\n";
                print "OLD: [$method] [$bm]\n";
                ok(0);
            }
        }
    }

    # canonical must be last, for URI it changes its parts
    if ($a->canonical eq $b->canonical) {
        ok(1);
    }
    else {
        my $c = URI->new($a);
	$c->path('/');
	if ($a->canonical eq $c->canonical) {
	    # we consider http://www.foobar.com/? the same as http://www.foobar.com?
	    ok(1, "slightly non-standard canonicalization. appending / to the URI");
        }
	else {
	    print "NEW: $a -> " . $a->canonical . "\n";
            print "OLD: $b -> " . $b->canonical . "\n";
            ok(0);
        }
    }
}

# Need to fix?
#   http://ralf.faithweb.com/E%2DMAIN.HTM


__DATA__
http://www.bottlecount.com/
http://www.westcoastwine.net/index.html
http://www.wineontheweb.com/
http://www.cellarnotes.net/
http://www.warpa.com/
http://www.sbwines.com/usenet_winefaq/
http://www.yumyuk.com/
http://www.enemyvessel.com/
http://www.damngoodwine.com/
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
http://WWW.ToPiX.Com?q=test#testfrag
http://WWW.ToPiX.Com?q=test
http://www.foobar.com/?
http://www.foobar.com?
http://www.foobar.com/?#frag
http://www.foobar.com?#frag
http://user:password@www.foobar.com/index.html?q=wtf#orly
http://user:password@www.foobar.com:8080/index.html?q=wtf#orly
path/foobar.html
path/foobar.cgi?q=test
http://www.myrise.com/search/%C3%A4%C2%B8%C2%80%C3%A6%C2%AC%C2%A1%C3%A8%C2%87%C2%AA%C3%A6%C2%88%C2%91%C3%A5%C2%BA%C2%B7%C3%A5-%C2%8D-blogs/
