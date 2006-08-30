package TOM::Debug;
use open ':utf8', ':std';
use encoding 'utf8';
use utf8;
use strict;

BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}

use TOM::Debug::logs;
use TOM::Debug::breakpoints;




1;
