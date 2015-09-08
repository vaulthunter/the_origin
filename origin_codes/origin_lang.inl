new const TIME_SECONS_ONE[] = "SEC_ONE"
new const TIME_SECONS_SOME[] = "SEC_SOME"
new const TIME_SECONS_MANY[] = "SEC_MANY"

//Function will return the mode name based on the mode id and the language of the user
lang_GetTimeName ( const TIME_string[], id, szTIME_string[], len )
{

	new szHelper[64];

	formatex( szHelper, 63, "TIME_%s", TIME_string );
	formatex( szTIME_string, len-1, "%L", id, szHelper );
}
