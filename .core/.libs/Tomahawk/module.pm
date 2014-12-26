package Tomahawk::module;
use open ':utf8', ':std';
use if $] < 5.018, 'encoding','utf8';
use Fcntl ':flock';
use utf8;

use Exporter 'import';
@EXPORT_OK = qw($TPL %XSGN %XLNG &XSGN_load_hash);


1;
