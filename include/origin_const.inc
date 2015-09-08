#if defined _origin_const_included
  #endinput
#endif
#define _origin_const_included

#define ORIGIN_VERSION_STR_LONG "1.0.0"
#define ORIGIN_VERSION "1.0.0"


stock get_correct_str( integer, one[], some[], many[] ) 
{
	new return_str[100]
	new val = integer % 100;

	if ( val > 10 && val < 20 ) 
	{
		formatex(return_str, charsmax(return_str), "%i %s", integer, many)
		return return_str
	}
	else 
	{
		val = integer % 10;
        	if ( val == 1 ) 
		{
			formatex(return_str, charsmax(return_str), "%i %s", integer, one)
			return return_str;
		}
        	else if ( val > 1 && val < 5 ) 
		{
			formatex(return_str, charsmax(return_str), "%i %s", integer, some)
			return return_str;
		}
	}

	formatex(return_str, charsmax(return_str), "%i %s", integer, many)
	return return_str
}