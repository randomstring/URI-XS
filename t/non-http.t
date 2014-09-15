#!/usr/bin/perl

#  Copied from abs.t to test that non-http (really non-hierarchical type URIs)
#  come out the same as they went in, even in the presence of a base url


print "1..99\n";

use URI::XS;
use URI;
$base = "http://a/b/c/d;p?q";
$testno = 1;

while (<DATA>) {
   #next if 1 .. /^C\.\s+/;
   #last if /^D\.\s+/;
   next if /^\s*$/;
   next if /^\s*\#/;
   next unless /^\s+/;
   s/\s*$//;            # super chomp
   while (s/\s*\\\s*$/\n/) {
       $_ .= readline DATA;
       s/\s*$//;        # super chomp
   }
   my $uref = $_;
   $uref =~ s/^\s+//;
   my $expect = $uref;

   my $bad;
   my $u = URI::XS->new($uref);
   $u->abs($base);
   my $foo = $u->canonical;
   if ($foo ne $expect) {
       $bad++;
       print "Expected: $uref => $expect\n";
       print qq(URI::XS->new("$uref")->abs("$base") ==> "$foo"\n);
   }

   # Let's test another version of the same thing
   $u = URI::XS->new($uref);
   my $b = URI::XS->new($base);
   $u->abs($b);
   $foo = $u->canonical;
   if ($foo ne $expect && $uref !~ /^http:/) {
       $bad++;
       print qq(URI::XS->new("$uref")->abs(URI::XS->new("$base")) => $foo\n);
   }

   print "not " if $bad;
   print "ok ", $testno++, "\n";
}

if (@rel_fail) {
    print "\n\nIn the following cases we did not get back to where we started with rel()\n";
    print @rel_fail;
}



__END__

    about:about
    about:blank
    about:plugins
    about:cache
    about:config
    about:mozilla

    aim:goim?screenname=notarealuser
    aim:goim?screenname=notarealuser&message=This+is+my+message
    aim:goaway?message=Hello, my name is Bill

    data:image/png;base64, \
iVBORw0KGgoAAAANSUhEUgAAAAoAAAAKCAYAAACNMs+9AAAABGdBTUEAALGP \
C/xhBQAAAAlwSFlzAAALEwAACxMBAJqcGAAAAAd0SU1FB9YGARc5KB0XV+IA \
AAAddEVYdENvbW1lbnQAQ3JlYXRlZCB3aXRoIFRoZSBHSU1Q72QlbgAAAF1J \
REFUGNO9zL0NglAAxPEfdLTs4BZM4DIO4C7OwQg2JoQ9LE1exdlYvBBeZ7jq \
ch9//q1uH4TLzw4d6+ErXMMcXuHWxId3KOETnnXXV6MJpcq2MLaI97CER3N0 \
vr4MkhoXe0rZigAAAABJRU5ErkJggg==
    data:image/png;base64, \
iVBORw0KGgoAAAANSUhEUgAAABAAAAAQAQMAAAAlPW0iAAA \
ABlBMVEUAAAD///+l2Z/dAAAAM0lEQVR4nGP4/5/h/1+G/5 \
8ZDrAz3D/McH8yw83NDDeNGe4Ug9C9zwz3gVLMDA/A6P9/A \
FGGFyjOXZtQAAAAAElFTkSuQmCC
    data:text/html;charset=utf-8,%3C!DOCTYPE%20HTML%20PUBLIC%20%22-%2F%2FW3C%2F%2FDTD%20HTML%204.0%2F%2FEN%22%3E%0D%0A%3Chtml%20lang%3D%22en%22%3E%0D%0A%3Chead%3E%3Ctitle%3EEmbedded%20Window%3C%2Ftitle%3E%3C%2Fhead%3E%0D%0A%3Cbody%3E%3Ch1%3E42%3C%2Fh1%3E%3C%2Fbody%3E%0D%0A%3C%2Fhtml%3E%0D%0A

#  Note that these two fail because of % encoding, although I am not sure that
#  is a failure
#
#    ed2k://|file|The_Two_Towers-The_Purist_Edit-Trailer.avi|14997504|965c013e991ee246d63d45ea71954c4d|/
#    ed2k://|file|The_Two_Towers-The_Purist_Edit-Trailer.avi|14997504|965c013e991ee246d63d45ea71954c4d|/|sources,202.89.123.6:4662|/

    feed://example.com/rss.xml
    feed:https://example.com/rss.xml

    geo:48.210182,16.361185
    geo:48.205278,16.356667
    geo:48.209444,16.352778
    geo:48.202778,16.368472

    gg:userid

    iax2:[2001:db8::1]:4569/alice?friends
    iax2:johnQ@example.com/12022561414

    jar:file:///C|/bar/baz.jar!/com/foo/Quux.class
    jar:http://www.foo.com/bar/baz.jar!/com/foo/Quux.class

    jdbc:BorlandBroker://193.174.106.43:1600/sample,user,password

    magnet:?xt=urn:sha1:YNCKHTQCWBTRNJIV4WNAE52SJUQCZO5C
    magnet:?xt=urn:sha1:YNCKHTQCWBTRNJIV4WNAE52SJUQCZO5C&dn=Great+Speeches+-+Martin+Luther+King+Jr.+-+I+Have+A+Dream.mp3
    magnet:?kt=martin+luther+king+mp3
    magnet:?xt.1=urn:sha1:YNCKHTQCWBTRNJIV4WNAE52SJUQCZO5C&xt.2=urn:sha1:TXGCZQTH26NL6OUQAJJPFALHG2LTGBC7

    mailto:
    mailto:?
    mailto:?to=email%40example.com
    mailto:?subject=mailto%20uri%20scheme
    mailto:?body=line1%0D%0Aline2
    mailto:?cc=email%40example.com
    mailto:?bcc=email%40example.com
    mailto:?to=email%40example.com&subject=mailto%20uri%20scheme&body=line1%0D%0Aline2&cc=email%40example.com&bcc=email%40example.com
    mailto:?to=email1%40example.com%2C%20email2%40example.com%2C%20email3%40example.com
    mailto:?cc=email1%40example.com%2C%20email2%40example.com%2C%20email3%40example.com
    mailto:?bcc=email1%40example.com%2C%20email2%40example.com%2C%20email3%40example.com
    mailto:email%40example.com
    mailto:email1%40example.com%2C%20email2%40example.com%2C%20email3%40example.com
    mailto:email%40example.com?subject=mailto%20uri%20scheme&body=line1%0D%0Aline2&cc=email%40example.com&bcc=email%40example.com
    mailto:?body=line1&body=line2&body=line3
    mailto:?body=&body=&body=&body=line1&body=line2
    mailto:?body=&body=&body=&body=line1&body=&body=line3
    mailto:?body=&body=&body=&body=line1&body=&body=line3&body=&body=&body=
    mailto:?subject=not%20used&subject=not%20used&subject=used
    mailto:email1%40example.com?to=email2%40example.com&to=email3%40example.com
    mailto:?cc=email1%40example.com&cc=email2%40example.com&cc=email3%40example.com
    mailto:?bcc=email1%40example.com&bcc=email2%40example.com&bcc=email3%40example.com
    mailto:?%E2%88%9A=%E2%88%9A
    mailto:?subject=1%2B2%3D3
    mailto:?subject=raining%20cats%20%26%20dogs
    mailto:Tim%20%3Ctim%40example.com%3E
    mailto:%22Tim%20Jones%22%20%3Ctim%40example.com%3E
    mailto:%22Timothy%20%5C%22The%20man%5C%22%20Jones%22%20%3Ctim%40example.com%3E
    mailto:%22%5C%5C%20is%20a%20backslash%22%20%3Ctim%40example.com%3E
    mailto:%22That%20%5C%22is%5C%22%20cool%22%20%3Ccool%40example.com%3E%20(not%20really)
    mailto:test%20%3Ctim%40example.com%3E%20(let%20us%20try%20(nested)%20comments)
    mailto:x%2By%40example.com

    msnim:add?contact=nada@nowhere.com
    msnim:chat?contact=nada@nowhere.com
    msnim:voice?contact=nada@nowhere.com
    msnim:video?contact=nada@nowhere.com

    mvn:org.ops4j.pax.web.bundles/service/0.2.0-SNAPSHOT
    mvn:http://user:password@repository.ops4j.org/maven2!org.ops4j.pax.web.bundles/service/0.2.0

    news:comp.lang.java.programmer

    skype:echo123
    skype:echo123?call
    skype:echo123?add

    sms:+41796431851;smsc=+41794999000
    sms:+41796431851,+4116321035;pid=fax
    sms:+41796431851;pid=smtp:erik.wilde@dret.net?body=hello%20there
    sms:+41796431851

    soldat://127.0.0.1:23073/

    urn:isbn:096139210x
    urn:isbn:0451450523
    urn:isan:0000-0000-9E59-0000-O-0000-0000-2
    urn:issn:0167-6423
    urn:ietf:rfc:2648
    urn:mpeg:mpeg7:schema:2001
    urn:oid:2.16.840
    urn:uuid:6e8bc430-9c3a-11d9-9669-0800200c9a66
    urn:uci:I001+SBSi-B10000083052
    urn:www.agxml.org:schemas:all:2:0
    urn:sha1:YNCKHTQCWBTRNJIV4WNAE52SJUQCZO5C
    urn:tree:tiger:BL5OM7M75DWHAXMFZFJ23MU3LVMRXKFO6HTGUTY
    urn:sici:1046-8188(199501)13:1%3C69:FTTHBI%3E2.0.TX;2-4

    webcal://example.com/calendar.ics

    xfire:function
    xfire:function?parameter1=value1
    xfire:function?parameter1=value1&parameter2=value2

    ymsgr:sendim?notarealuser
    ymsgr:sendim?notarealuser&m=This+is+my+message

    javascript:void(0)
    javascript:alert("I'm learning at Tizag.com")
    javascript: void(myNum=10);alert('myNum = '+myNum)
    cid:
    mid:

