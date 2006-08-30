package iconv;
use Inline C => Config => ENABLE => AUTOWRAP;
use Inline C;
use Inline C => Config => LIBS => '-liconv'; # 4 BSD only

BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}

1;
__DATA__
__C__

#include <iconv.h>

SV *convert(SV *string, SV *fromcodes, SV *tocodes)
{
	char    *ibuf;
	char    *obuf;
	size_t  inbytesleft;
	size_t  outbytesleft;
	size_t  l_obuf;
	char    *icursor;
	char    *ocursor;
	size_t  ret;
	SV      *perl_str;

	char *	fromcode = (char *)SvPV_nolen(fromcodes);
	char *	tocode = (char *)SvPV_nolen(tocodes);
	iconv_t	iconv_handle;

	if((iconv_handle = iconv_open(tocode, fromcode)) == (iconv_t)-1)
	{
		switch(errno)
		{
			case ENOMEM:
				croak("Insufficient memory to initialize conversion: %s",
				strerror(errno));
			case EINVAL:
				croak("Unsupported conversion: %s", strerror(errno));
			default:
				croak("Couldn't initialize conversion: %s", strerror(errno));
		}
	}

	if (! SvOK(string))
		return(&PL_sv_undef);

	perl_str = newSVpv("", 0);

	inbytesleft = SvCUR(string);
	ibuf        = SvPV(string, inbytesleft);


	if(inbytesleft <= MB_LEN_MAX)
	{
		outbytesleft = MB_LEN_MAX + 1;
	}
	else
	{
		outbytesleft = 2 * inbytesleft;
	}

	l_obuf = outbytesleft;
	obuf   = (char *) New(0, obuf, outbytesleft, char); /* Perl malloc */

	icursor = ibuf;
	ocursor = obuf;

	while(inbytesleft != 0)
	{
		while (1)
		{
			#ifdef __hpux
			/* Even in HP-UX 11.00, documentation and header files do not agree */
			ret = iconv(iconv_handle, &icursor, &inbytesleft,&ocursor, &outbytesleft);
			#else
			ret = iconv(iconv_handle, (const char **)&icursor, &inbytesleft,&ocursor, &outbytesleft);
			#endif
			if ((ret == (size_t) -1) && ((errno==EILSEQ) || (errno=EINVAL)))
				{
					icursor++;
					inbytesleft--;
				}
			else break;
		}

		if(ret == (size_t) -1 )
		{
			switch(errno)
			{
				case E2BIG:
					sv_catpvn(perl_str, obuf, l_obuf - outbytesleft);
					ocursor = obuf;
					outbytesleft = l_obuf;
					break;
				default:
					Safefree(obuf);
					return(&PL_sv_undef);
			}
		}
	}
	sv_catpvn(perl_str, obuf, l_obuf - outbytesleft);
	Safefree(obuf); /* Perl malloc */
	return perl_str;
}
