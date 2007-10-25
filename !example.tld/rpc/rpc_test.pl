#!/usr/bin/perl
use XMLRPC::Lite;

#for (1..100)
#{

my $res=XMLRPC::Lite
      -> proxy('http://example.tld/rpc/')
      -> call('test', {state1 => 12, state2 => 28})
      -> result;

#print "output:".$res->{'lowerBound'}."\n";

print "output:".$res->{'header'}->{'generator'}."\n";

#}