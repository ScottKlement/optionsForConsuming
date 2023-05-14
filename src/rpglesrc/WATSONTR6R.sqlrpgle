**free

//  WATSONTR6R:  This is a demo of Watson's Language Translator V3
//               using input/output with JSON documents.
//
//               Utilizes the QSYS2 SQL HTTP (HTTP_POST)
//               with Db2 JSON functions (JSON_OBJECT, JSON_TABLE)
//

ctl-opt option(*srcstmt);
/include version.rpgleinc

dcl-f WATSONTR3D workstn indds(dspf);


dcl-Ds dspf qualified;
   F3Exit ind pos(3);
end-Ds;

setJobCcsid();

fromLang = 'en';
toLang   = 'es';

dou dspf.F3Exit = *on;

   exfmt screen1;
   if dspf.F3exit = *on;
      leave;
   endif;

   fromLang = %lower(fromLang);
   toLang   = %lower(toLang);
   toText = translate( fromLang: toLang: %trim(fromText) );

enddo;

*inlr = *on;
return;

/// +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//  translate:
//   Use IBM Watson's Language Translator API to translate text between
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

   dcl-s userid   varchar(10);
   dcl-s password varchar(200);
   dcl-s url      varchar(2000);
   dcl-s request  varchar(2000);
   dcl-s response varchar(5000);
   dcl-s retval   varchar(1000);
   dcl-s options  varchar(400);

   exec sql select json_object(
                     'source' value :fromLang,
                     'target' value :toLang,
                     'text' value json_array(:fromText)
                   )
              into :request
              from SYSIBM.SYSDUMMY1;
   if %subst(sqlstt:1:2) <> '00' and %subst(sqlstt:1:2) <> '01';
      retval = '**ERROR CREATING: SQLSTT=' + sqlstt;
      return retval;
   endif;

   userid = 'apikey';
   password = 'YOUR IBM CLOUD KEY HERE';

   exec sql values json_object(
                     'basicAuth' value :userid || ',' || :password,
                     'header' value 'Content-Type,application/json'
                   )
              into :options;
   if %subst(sqlstt:1:2) <> '00' and %subst(sqlstt:1:2) <> '01';
      retval = '**ERROR WITH OPTIONS: SQLSTT=' + sqlstt;
      return retval;
   endif;

   url = 'https://'
       + 'api.us-south.language-translator.watson.cloud.ibm.com'
       + '/instances/f7b6e575-01c4-4b1b-916a-3a79652d0f52'
       + '/v3/translate?version=2018-05-01';

   exec SQL
     values QSYS2.HTTP_POST(:url, :request, :options)
       into :response;

   if %subst(sqlstt:1:2) <> '00' and %subst(sqlstt:1:2) <> '01';
      retval = '**ERROR IN HTTP_POST: SQLSTT=' + sqlstt;
      return retval;
   endif;

   exec SQL SELECT J."translation"
            into :retval
            from JSON_TABLE(:response, 'lax $'
                   COLUMNS(
                     "translation" VARCHAR(1000)
                       PATH 'lax $.translations[0].translation'
                   )
                  ) as J;

   if %subst(sqlstt:1:2) <> '00' and %subst(sqlstt:1:2) <> '01';
      retval = '** ERROR READING: SQLSTT=' + sqlstt;
      return retval;
   endif;

   return retval;

end-proc;



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
