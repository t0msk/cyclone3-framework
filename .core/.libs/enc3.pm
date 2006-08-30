package enc3;
use Inline C => Config => ENABLE => AUTOWRAP;
use Inline C;

BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}

1;
__DATA__
__C__
	SV *xor(SV *sv_s,SV *sv_key)
	{
		SV *sv_res;
		
		char *s;
		char *key;
		char *res;
		
		int s_size;
		int key_size;
		int key_p=0;
		int i;
		
		// Get sizes
		key = SvPV (sv_key,key_size);
		s = SvPV (sv_s,s_size);
		
		res = (char *) New(0, res, (size_t)s_size, char);
		sv_res = newSVpv("",0);
		
		for (i=0;i<s_size;i++)
			res[i] = s[i]^key[key_p++%(key_size-1)];
		
		sv_catpvn(sv_res, res, s_size);
		Safefree (res);
		return sv_res;
	}