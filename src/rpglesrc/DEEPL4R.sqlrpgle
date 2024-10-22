**free
//  DEEPL4R:  This is a demo of using DeepL's Language Translator V2
//            using input/output with JSON documents.
//
//            This version uses the (new) SYSTOOLS SQL HTTP interface
//            with all SQL combined into a single statement
//
ctl-opt option(*srcstmt);

/copy version.rpgleinc

dcl-f DEEPL1D workstn indds(dspf);

dcl-Ds dspf qualified;
   F3Exit ind pos(3);
end-Ds;

setJobCcsid();

fromLang = 'EN';
toLang   = 'ES';

dou dspf.F3Exit = *on;

   exfmt screen1;
   if dspf.F3exit = *on;
      leave;
   endif;

   fromLang = %upper(fromLang);
   toLang   = %upper(toLang);
   toText = translate( fromLang: toLang: %trim(fromText) );
enddo;

*inlr = *on;
return;


/// +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//  translate:
//   Use DeepL's Language Translator API to translate text between
//   two human languages.
//
//   @param char(2) 2-char language to translate from (en=english)
//   @param char(2) 2-char language to translate to (fr=french,en=spanish)
//   @param varchar(1000) text to translate
//
//   @return varchar(1000) the translated text.
/// +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

dcl-proc translate;

   dcl-pi *n varchar(1000);
      fromLang char(2)       const;
      tolang   char(2)       const;
      fromText varchar(1000) const;
   end-pi;

   dcl-s apiKey   varchar(200);
   dcl-s url      varchar(2000);
   dcl-s retval   varchar(1000);
   dcl-s split    char(1) inz('0');

   url = 'https://api-free.deepl.com/v2/translate';
   apiKey = '** your API key here **';

   exec SQL SELECT J."text"
          into :retval
          from JSON_TABLE(
                  HTTP_POST(
                    :url,
                    json_object(
                      'source_lang' value upper(:fromLang),
                      'target_lang' value upper(:toLang),
                      'split_sentences' value :split,
                      'text' value json_array(:fromText)
                    ),
                    json_object(
                      'header' value 'Authorization,DeepL-Auth-Key ' || :apiKey,
                      'header' value 'Content-Type,application/json'
                    )
                  ),
                  'lax $' COLUMNS(
                    "text" VARCHAR(1000)
                      PATH 'lax $.translations[0].text'
                  )
                ) as J;

   if %subst(sqlstt:1:2) <> '00' and %subst(sqlstt:1:2) <> '01';
     retval = '** ERROR CALLING API: SQLSTT=' + sqlstt;
     return retval;
   endif;

   return retval;
end-Proc;


/// +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//  setJobCCSID:
//   SQL needs the job CCSID set to a 'real' value (not 65535!) so
//   this will set the job ccsid to it's default ccsid if it is 65535.
/// +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

dcl-proc setJobCCSID;

  dcl-pr QCMDEXC extpgm;
    command char(200) const;
    length  packed(15: 5) const;
    igc char(3) const options(*nopass);
  end-pr;

  dcl-pr QUSRJOBI extpgm('QSYS/QUSRJOBI');
    rcvvar     char(65535) options(*varsize);
    rcvvarlen  int(10)     const;
    format     char(8)     const;
    qualJob    char(26)    const;
    intJobId   char(16)    const;
    errorCode  char(32767) options(*varsize:*nopass);
    resetStats char(1)     const options(*nopass);
  end-pr;

  dcl-ds JOBI0400 len(574) qualified;
    ccsid    int(10) pos(301);
    dftCcsid int(10) pos(373);
  end-ds;

  dcl-ds errorCode qualified;
    bytesProv  int(10) inz(0);
    bytesAvail int(10) inz(0);
  end-ds;

  dcl-s cmd varchar(200);

  QUSRJOBI( JOBI0400
          : %size(JOBI0400)
          : 'JOBI0400'
          : '*'
          : *blanks
          : errorCode
          : *off );

  if JOBI0400.Ccsid = 65535;
    cmd = 'CHGJOB CCSID(CCCCC)';
    cmd = %scanrpl('CCCCC': %char(JOBI0400.DftCcsid): cmd);
    QCMDEXC(cmd: %len(cmd));
  endif;

end-proc;

