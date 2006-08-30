package enc2;
use Inline C => Config => ENABLE => AUTOWRAP;       
use Inline C;

BEGIN {eval{main::_log("<={LIB} ".__PACKAGE__);};}

1;
__DATA__
__C__
	char *base="BCDEFGHIJKLMNPQRSTUVWXYZacdefghijklmnoprstuvwxyz0123456789";
	char *expans="AObq";

	SV *enc(SV *sv_s,SV *sv_key)
	{
		char *s;
		char *res;
		char *key;
		int s_size;
		int base_size;
		int key_size;
		
		int key_p=0;
		int res_p=0;
		int s_p=0;
		
		char val;
		int exp;
		
		SV *sv_res;
		
		// Get sizes
		key = SvPV (sv_key,key_size);
		s = SvPV (sv_s,s_size);

		// Test		
		if (!SvOK(sv_s) || !SvOK(sv_key) || key_size*s_size==0) return(&PL_sv_undef);
		
		base_size=strlen(base);
		res = (char *) New(0, res, (size_t)s_size, char);
		sv_res = newSVpv("",0);
		
		// Encode string
		for (s_p=0;s_p<s_size;s_p++)
		{
			// flush buffer
			if (res_p+2>s_size)
			{
				sv_catpvn(sv_res, res, res_p);
				res_p=0;
			}
			
			val=s[s_p]^key[key_p++%key_size];
			exp=val/base_size;
			val=val%base_size;
			
			// Encode Char
			if (exp!=0) res[res_p++]=expans[exp-1];
			res[res_p++]=base[val];
		}
		// flush results
		sv_catpvn(sv_res, res, res_p);
		Safefree (res);
		return sv_res;
	}
	
	SV *dec(SV *sv_s,SV *sv_key)
	{
		char *s;
		char *res;
		char *key;
		int s_size;
		int base_size;
		int key_size;
		
		int key_p=0;
		int res_p=0;
		int s_p=0;
		
		char val;
		int exp;

		SV *sv_res;
		
		// Get sizes
		key = SvPV (sv_key,key_size);
		s = SvPV (sv_s,s_size);
		
		// Test		
		if (!SvOK(sv_s) || !SvOK(sv_key) || key_size*s_size==0) return(&PL_sv_undef);
		
		base_size=strlen(base);
		res = (char *) New(0, res, (size_t)s_size, char);
	
		// Decode string
		for (s_p=0;s_p<s_size;s_p++)
		{
			val=s[s_p];
			exp=(int)strchr(expans,val);
			
			if (exp!=0) 
			{ 
				exp=exp-(int)expans+1; 
				val=s[++s_p]; 
			}
			val = (int)strchr(base,val)-(int)base;
			val += base_size*exp; 
			
			res[res_p++]=val^key[key_p++%key_size];
		}
		sv_res = newSVpv(res,res_p);
		Safefree (res);
		return sv_res;
	}
