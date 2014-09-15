use Test::More 'no_plan';
use URI::XS;

my $test_toplevel = 1;

# ok(1); exit(0);

my $i = 0;
while($uri = <DATA>) {
    chomp($uri);


    if ($uri =~ /^#\s*not/) {
        $test_toplevel = 0;
        next;
    }
    elsif ($uri =~ /^#\s*is/) {
        $test_toplevel = 1;
        next;
    }
    elsif ($uri =~ /^#/) {
        next;
    }

    my $toplevel = URI::XS->new($uri)->is_toplevel;

    if ($toplevel && $test_toplevel) {
        ok(1);
    }
    elsif (!$toplevel && !$test_toplevel) {
        ok(1);
    }
    else {
        print "got wrong result for $uri [$toplevel] canonical_uri=" .  URI::XS->new($uri) . "\n";
        ok(0);
    }

    $i++;
}


__DATA__
# is toplevel
http://www.foobar.com/
http://www.foobar.com
http://www.winer.com:88/
http://xbox.net/
http://www.keskiaika.net/
http://192.168.1.10/
http://192.168.1.10
http://www.bottlecount.com/
http://www.wineontheweb.com/
http://www.wineanswers.com/
http://www.cellarnotes.net/
http://www.warpa.com/
http://www.yumyuk.com/
http://www.enemyvessel.com/
http://www.damngoodwine.com/
http://www.iswn.org/
http://www.vino.com/
http://www.bpdr.com/
http://www.boisset.com/
http://www.lafite.com/
http://gallo.com/
http://www.fapes.com.ar/
http://www.tapiz.com
# not toplevel
http://www.google.com?
http://www.google.com#
http://www.google.com?
http://www.google.com/#
http://www.google.com/#test
http://www.google.com?test=1
http://www.google.com/#test
http://www.google.com/?test=1
http://www.google.com/?test=1#test2
http://www.example.com/one/two/three/four/five/six/seven/eight_is_enough.html
http://www.example.com/one/two/three/four/five/six/seven/eight/nine_is_ok.html
http://www.example.com/one/two/three/four/five/six/seven/eight/nine/ten_is_ok.html
http://www.example.com/one/two/three/four/five/six/seven/eight/nine/ten/eleven_is_ok.html
http://www.example.com/one/two/three/four/five/six/seven/eight/nine/ten/eleven/12ok.html
http://www.abcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyz12345678901.com/lable_length_almost_exceeds_63.html
http://wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww.xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx.zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz.aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb.com/hostname_is_ALMOST_too_long.html
http://wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww.xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx.zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz.aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb.com/hostname_is_ALMOST_too_long.html
http://www.keskiaika.net//php//foo//index.html
http://www.westcoastwine.net/index.html
http://www.sbwines.com/usenet_winefaq/
http://www.allexperts.com/browse.cgi?catLvl=3&catID=1615
http://fosters.com.au/enjoy/wine.htm
http://www.flichman.com.ar/ing/index.html
http://www.salnet.com.ar/cafayate/VinosyBodegas.htm
http://www.wineanorak.com/targent.htm
http://www.bodegasalentein.com/cas/bodegas/default.asp
http://www.norton.com.ar/?winesofargentina
http://home.earthlink.net/~sarsenstone/
http://www.geocities.com/gimsincattery/
http://home.comcast.net/~siamese/
http://www.allexperts.com/browse.cgi?catLvl=3&catID=1606
http://www.fanciers.com/cat-faqs/behavior.shtml#cats_outside
http://www.flickr.com/groups/87781234@N00/
http://ralf.faithweb.com/E%2dMAIN.HTM
http://ralf.faithweb.com/E%2DMAIN.HTM
http://www.ursulana.ch/the%20ursulana%20k_p%20project.htm
http://www.yoga.com/ydc/enlighten/enlighten_document.asp?ID=32&;section=8&;cat=0
http://en.wikipedia.org/wiki/Friedrich_H%c3%b6lderlin
http://en.chinabroadcast.cn/349/2005/11/08/Zt44@29442.htm
http://WWW.ToPiX.Com/?q=test
http://WWW.ToPiX.Com#testfrag
http://WWW.ToPiX.Com/#testfrag
http://WWW.ToPiX.Com/?q=test#testfrag
http://www.skrenta.com/2008/02/amazon_is_the_google_of_buying.html
http://www.skrenta.com/2008/02/amazon_is_the_google_of_buying.html#comments
http://jewelry.ebay.com/_W0QQ_trksidZp3907Q2em21
http://search.ebay.com/search/search.dll?ht=1&from=R4&satitle=iwc&sacat=281%26catref%3DC6
http://www.cinewiki.cn/w/%E4%B8%8A%E6%b5%B7%E5%BD%B1%E6%88%8F%E5%85%aC%e5%8f%b8
http://WWW.ToPiX.Com?q=test#testfrag
http://WWW.ToPiX.Com?q=test
