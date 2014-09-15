use Test::More 'no_plan';
use URI::XS;

my $uri = URI::XS::set_bad_url_chars(" \\\n\t\@!\$<>");


my $test_bad = 1;

my $i = 0;
while($uri = <DATA>) {
    chomp($uri);

    if ($uri =~ /^#\s*bad/) {
        $test_bad = 1;
        next;
    }
    elsif ($uri =~ /^#\s*good/) {
        $test_bad = 0;
        next;
    }
    elsif ($uri =~ /^#/) {
        next;
    }

    my $isbad = URI::XS->new($uri)->bad_url;

    if ($isbad && $test_bad) {
        ok(1);
    }
    elsif (!$isbad && ! $test_bad) {
        ok(1);
    }
    else {
        print "got wrong result for $uri [$isbad]\n";
        ok(0);
    }

    $i++;
}


__DATA__
# bad
http://www.example.com/what the fuck.html
http://www.example.com/what<the>fuck.html
http://www.ex;ample.com/what_the_fuck.html
http://www.ex!ample.com/what_the_fuck.html
http://***.example.com/what_the_fuck.html
http://%%%.example.com/what_the_fuck.html
http://www.ex<ample.com/what_the_fuck.html
http://www.ex	ample.com/what_the_fuck.html
http://www.ex>ample.com/what_the_fuck.html
http://www.example.com/what     the     fuck_with_tabs.html
http://www.flickr.com/groups/87781234@N00/
http://en.chinabroadcast.cn/349/2005/11/08/Zt44@29442.htm
javascript://www.foobar.com/test/
ftp://www.foobar.com/test/foobar.tar.gz
/nohost/path/index.html
http://www.winer.com:88/nonstandardport.html
http://www.wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww.xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx.zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz.aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb.com/hostname_too_long.html
http://wwwwww.wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww.xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx.zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz.aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb.com/hostname_too_long.html
http://wwwwwwwwwwwwwwwwwwwwwwwwwww.wwwwwwwwwwwwwwwwwwwwwww.xxxxxxxxxxxxxxxxxxxxxxxx.xxxxxxxxxxxxxxxxxxxxxxxxxx.zzzzzzzzzzzzzzzzzzzzzzzzzzz.zzzzzzzzzzzzzzzzzzzzzzz.aaaaaaaaaaaaaaaa.aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.bbbbbbbbbbbbbbbbb.bbbbbbbbbbbbbbbbbbbbbbbbbbbbbb.com/hostname_too_long.html
http://wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww.xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx.zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaabbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb.com/hostname_too_long.html
http://www.abcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyz123456789012.com/lable_length_exceeds_63.html
http://www.abcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyz123456789012.foobar.com/lable_length_exceeds_63.html
http://www.abcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyz123456789012.test.foobar.com/lable_length_exceeds_63.html
# good
http://www.example.com/one/two/three/four/five/six/seven/eight_is_enough.html
http://www.example.com/one/two/three/four/five/six/seven/eight/nine_is_ok.html
http://www.example.com/one/two/three/four/five/six/seven/eight/nine/ten_is_ok.html
http://www.example.com/one/two/three/four/five/six/seven/eight/nine/ten/eleven_is_ok.html
http://www.example.com/one/two/three/four/five/six/seven/eight/nine/ten/eleven_is_ok.html
http://www.abcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyz12345678901.com/lable_length_almost_exceeds_63.html
http://abcdefghijklmnopqrstuvwxyz.ABCDEFGHIJKLMNOPQRSTUVWXYZ-12345678901.com/use_all_valid_hostname_chars.html
http://wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww.xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx.zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz.aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb.com/hostname_is_ALMOST_too_long.html
http://wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww.xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx.zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz.aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb.com/hostname_is_ALMOST_too_long.html
http://www.bottlecount.com/
http://www.westcoastwine.net/index.html
http://www.wineontheweb.com/
http://www.wineanswers.com/
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
http://ralf.faithweb.com/E%2dMAIN.HTM
http://ralf.faithweb.com/E%2DMAIN.HTM
http://www.ursulana.ch/the%20ursulana%20k_p%20project.htm
http://www.yoga.com/ydc/enlighten/enlighten_document.asp?ID=32&;section=8&;cat=0
http://en.wikipedia.org/wiki/Friedrich_H%c3%b6lderlin
http://WWW.ToPiX.Com
http://WWW.ToPiX.Com/
http://WWW.ToPiX.Com/?q=test
http://www.skrenta.com/2008/02/amazon_is_the_google_of_buying.html
http://jewelry.ebay.com/_W0QQ_trksidZp3907Q2em21
http://search.ebay.com/search/search.dll?ht=1&from=R4&satitle=iwc&sacat=281%26catref%3DC6
    http://www.testwhitespace.com/
http://www.cinewiki.cn/w/%E4%B8%8A%E6%b5%B7%E5%BD%B1%E6%88%8F%E5%85%aC%e5%8f%b8
http://WWW.ToPiX.Com?q=test
# bad - all fragments (may want to change this in the future)
http://www.fanciers.com/cat-faqs/behavior.shtml#cats_outside
http://WWW.ToPiX.Com?q=test#testfrag
http://www.skrenta.com/2008/02/amazon_is_the_google_of_buying.html#comments
http://WWW.ToPiX.Com#
http://WWW.ToPiX.Com#testfrag
http://WWW.ToPiX.Com/#
http://WWW.ToPiX.Com/#testfrag
http://WWW.ToPiX.Com/?q=test#
http://WWW.ToPiX.Com/?q=test#testfrag
