package TOM::Logger;
# constants for logger
require Exporter;
our @ISA    = qw{Exporter};
our @EXPORT = qw{
	LOG_INFO
	LOG_ERROR
	LOG_INFO_FORCE
	LOG_INFO_FORCE_NODEPTH
	LOG_ERROR_FORCE_NODEPTH
	LOG_WARNING
};
use constant LOG_INFO => 0;
use constant LOG_ERROR  => 1;
use constant LOG_INFO_FORCE => 2;
use constant LOG_INFO_FORCE_NODEPTH => 3;
use constant LOG_ERROR_FORCE_NODEPTH => 4;
use constant LOG_WARNING  => 5;
1;
