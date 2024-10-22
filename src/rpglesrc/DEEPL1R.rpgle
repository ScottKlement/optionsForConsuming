**free
//  DEEPL1R:  This is a demo of using DeepL's Language Translator V2
//            using input/output with JSON documents.
//
//            Requires HTTPAPI and YAJL.
//            This version uses DATA-INTO and DATA-GEN
//
ctl-opt option(*srcstmt) bnddir('HTTPAPI');

/copy version.rpgleinc
/copy httpapi_h

dcl-f DEEPL1D workstn indds(dspf);

dcl-Ds dspf qualified;
   F3Exit ind pos(3);
end-Ds;

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

   dcl-s url      varchar(2000);
   dcl-s request  varchar(2000);
   dcl-s response varchar(5000);
   dcl-s httpstatus int(10);

   dcl-ds reqds qualified;                  // {
     source_lang      varchar(2);           //   "source_lang": "{string}",
     target_lang      varchar(2);           //   "target_lang": "{string}",
     split_sentences  char(1) inz('0');     //   "split_sentences": "0",
     text             varchar(1000) dim(1); //   "text": [ "{string}" ]
   end-ds;                                  // }

   dcl-ds result qualified;                     // {
     dcl-ds translations dim(1);                //   "translations": [{
        detected_source_language varchar(2);    //     "detected_source_language": "EN",
        text                     varchar(1000); //      "text": "{string}"
     end-ds;                                    //   }]
   end-ds;                                      // }

   // Generate the JSON document to send

   reqds.source_lang  = fromLang;
   reqds.target_lang  = toLang;
   reqds.text(1)      = fromText;

   data-gen reqds %data(request) %gen('YAJLDTAGEN');

   // Set options to control how HTTPAPI communicates with DeepL

   http_debug(*on: '/tmp/deepl-diagnostic-log.txt');
   http_setOption('local-ccsid': '0');
   http_setOption('network-ccsid': '1208');

   http_setAuth( HTTP_AUTH_USRDFN
               : 'DeepL-Auth-Key'
               : '** your API key here **');

   url = 'https://api-free.deepl.com/v2/translate';

   monitor;
      response = http_string('POST': url: request: 'application/json');
      http_error(*omit: httpstatus);
      httpcode = %char(httpstatus);
   on-error;
      httpcode = http_error();
   endmon;

   data-into result %DATA(response) %PARSER('YAJLINTO');
   return result.translations(1).text;

end-Proc;


