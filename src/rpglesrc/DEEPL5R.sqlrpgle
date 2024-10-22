**free
//  DEEPL5R:  This is a demo of using DeepL's Language Translator V2
//            using input/output with JSON documents.
//
//            This version uses the IBM port of AXISC
//            to implement HTTP.  Db2 JSON_OBJECT to create JSON,
//            and DATA-INTO/YAJLINTO to read JSON.
//
//            Diagnostic info is written in /tmp/axistransport.log
//

ctl-opt option(*srcstmt) bnddir('AXIS');

/copy version.rpgleinc
/include /QIBM/ProdData/OS/WebServices/V1/client/include/Axis.rpgleinc

dcl-f WATSONTR3D workstn indds(dspf);

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

   dcl-s apiKey     varchar(200);
   dcl-s url        varchar(2000);
   dcl-s request    varchar(2000);
   dcl-s response   varchar(5000);
   dcl-s rcvBuf     char(5000);
   dcl-s rc         int(10);
   dcl-s propName   char(200);
   dcl-s propVal    char(300);
   dcl-s transportHandle pointer;
   dcl-s certStore  char(200);
   dcl-s setTrue    char(6);
   dcl-s setNone    char(6);
   dcl-s setDefault char(6);
   dcl-s snihost    char(256);
   dcl-s split      char(1) inz('0');

   dcl-ds result qualified;                     // {
     dcl-ds translations dim(1);                //   "translations": [{
        detected_source_language varchar(2);    //     "detected_source_language": "EN",
        text                     varchar(1000); //      "text": "{string}"
     end-ds;                                    //   }]
   end-ds;                                      // }

   exec sql select json_object(
                     'source_lang' value :fromLang,
                     'target_lang' value :toLang,
                     'split_sentences' value :split,
                     'text' value json_array(:fromText)
                   )
              into :request
              from SYSIBM.SYSDUMMY1;
   if %subst(sqlstt:1:2) <> '00' and %subst(sqlstt:1:2) <> '01';
      return '**ERROR CREATING: SQLSTT=' + sqlstt;
   endif;

   axiscAxisStartTrace('/tmp/axistransport.log': *NULL);

   apiKey = '** your API key here **';

   sniHost = 'api-free.deepl.com' + x'00';

   url = 'https://' + %trimr(sniHost:x'4000') + '/v2/translate';

   transportHandle = axiscTransportCreate(url: AXISC_PROTOCOL_HTTP11);
   if (transportHandle = *null);
     failWithError(transportHandle: 'axiscTransportCreate');
   endif;

   propName = 'POST' + x'00';
   axiscTransportSetProperty( transportHandle
                            : AXISC_PROPERTY_HTTP_METHOD
                            : %addr(propName));

   propName = 'Authorization' + x'00';
   propVal  = 'DeepL-Auth-Key ' + apiKey + x'00';

   axiscTransportSetProperty( transportHandle
                            : AXISC_PROPERTY_HTTP_HEADER
                            : %addr(propName)
                            : %addr(propVal) );

   propName = 'Content-Type' + x'00';
   propVal  = 'application/json' + x'00';

   axiscTransportSetProperty( transportHandle
                            : AXISC_PROPERTY_HTTP_HEADER
                            : %addr(propName)
                            : %addr(propVal) );

   setNone    = 'NONE' + x'00';
   setTrue    = 'true' + x'00';
   certStore  = '/QIBM/USERDATA/ICSS/CERT/SERVER/DEFAULT.KDB' + x'00';
   setDefault = x'00';

   axiscTransportSetProperty( transportHandle
                            : AXISC_PROPERTY_HTTP_SSL
                            : %addr(certStore)  // cert store pathname
                            : %addr(setDefault) // cert store pw
                            : %addr(setDefault) // cert store label
                            : %addr(setNone)    // SSLv2 ciphers
                            : %addr(setNone)    // SSLv3 ciphers
                            : %addr(setDefault) // TLSv1 ciphers
                            : %addr(setDefault) // TLSv1.1 ciphers (enable)
                            : %addr(setDefault) // TLSv1.2 ciphers (enable)
                            : %addr(setTrue)    // tolerate soft validation (true)
                            : %addr(setDefault) // DCM APP ID (none set)
                            : %addr(sniHost)    // Server Name Indication Hostname
                            : *NULL );          // *NULL = end of list

   rc = axiscTransportSend( transportHandle
                          : %addr(request: *data)
                          : %len(request)
                          : 0 );
   if rc = -1;
     failWithError(transportHandle: 'axiscTransportSend');
   endif;

   rc = axiscTransportFlush(transportHandle);
   if rc = -1;
     failWithError(transportHandle: 'axiscTransportFlush');
   endif;

   response = '';

   dou rc < 1;

     rc = axiscTransportReceive( transportHandle
                               : %addr(rcvBuf)
                               : %size(rcvBuf)
                               : 0 );
     if rc >= 1;
       response += %subst(rcvBuf:1:rc);
     endif;

   enddo;

   if rc = -1;
     failWithError(transportHandle: 'axiscTransportReceive');
   else;
     httpCode = getHttpStatus(transportHandle);
   endif;

   axiscTransportDestroy(transportHandle);

   if %len(response) > 0;
     data-into result %DATA(response) %PARSER('YAJLINTO');
   endif;

   return result.translations(1).text;

end-Proc;


dcl-proc getHttpStatus;

  dcl-pi *n varchar(10);
    transportHandle pointer value;
  end-pi;

  dcl-s result varchar(10) inz('');
  dcl-s statusCode pointer;

  if transportHandle <> *null;
     axiscTransportGetProperty( transportHandle
                              : AXISC_PROPERTY_HTTP_STATUS_CODE
                              : %addr(statusCode) );
  endif;

  if statusCode <> *null;
    result = %str(statusCode);
  endif;

  return result;
end-proc;


dcl-proc getLastError;

  dcl-pi *n varchar(5000);
    transportHandle pointer value;
    errorNum int(10) options(*nopass);
    httpStatus varchar(100) options(*nopass);
  end-pi;

  dcl-s lastCode int(10);
  dcl-s lastMsg  varchar(5000);
  dcl-s statusCode varchar(10) inz('');

  // transportHandle should only be null if axiscCreateTransportHandle
  //   failed. Note that since the transport handle is used to retrieve
  //   the error message, there's no way to get the actual message in
  //   this case.

  if transportHandle = *null;

     lastCode = -1;
     lastMsg  = 'Could not create transport handle';

  else;

     lastCode = axiscTransportGetLastErrorCode(transportHandle);
     lastMsg  = %str(axiscTransportGetLastError(transportHandle));

     if lastCode = EXC_TRANSPORT_HTTP_EXCEPTION;
        statusCode = getHttpStatus(transportHandle);
     endif;

  endif;

  if %parms >= 2 and %addr(errorNum) <> *null;
    errorNum = lastCode;
  endif;

  if %parms >= 3 and %addr(httpStatus) <> *null;
    httpStatus = statusCode;
  endif;

  return lastMsg;

end-proc;



dcl-proc failWithError;

  dcl-pi *n;
    transportHandle pointer value;
    location varchar(100) const;
  end-pi;

  dcl-pr QMHSNDPM extpgm;
    msgid      char(7)     const;
    msgf       char(20)    const;
    msgdta     char(32767) const options(*varsize);
    msgdtalen  int(10)     const;
    msgtype    char(10)    const;
    callstack  char(10)    const;
    stackcount int(10)     const;
    msgkey     char(4);
    errorCode  char(32767) options(*varsize);
  end-pr;

  dcl-ds errorEscape qualified;
    bytesProv int(10) inz(0);
    bytesAvail int(10) inz(0);
  end-ds;

  dcl-s axisMsg    varchar(5000);
  dcl-s msg        varchar(5500);
  dcl-s errorNum   int(10);
  dcl-s httpStatus varchar(100);
  dcl-s msgkey     char(4);

  axisMsg = getLastError( transportHandle
                        : errorNum
                        : httpStatus );

  msg = %trimr(location) + ': '
      + %trimr(axisMsg)
      + ' (err=' + %char(errorNum)
      + ', status=' + %trim(httpStatus)
      + ')';

  if %len(axisMsg) > 0;
     QMHSNDPM( 'CPF9897'
             : 'QCPFMSG   QSYS'
             : msg
             : %len(msg)
             : '*ESCAPE'
             : '*'
             : 1
             : msgkey
             : errorEscape );
  endif;

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

