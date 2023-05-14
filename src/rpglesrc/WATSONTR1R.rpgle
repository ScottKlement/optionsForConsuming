**free
//  WATSONTR1R:  This is a demo of Watson's Language Translator V3
//               using input/output with JSON documents.
//
//               Requires HTTPAPI and YAJL.
//               This version uses DATA-INTO and DATA-GEN
//
ctl-opt option(*srcstmt) bnddir('HTTPAPI');

/copy version.rpgleinc
/copy httpapi_h

dcl-f WATSONTR1D workstn indds(dspf);

dcl-Ds dspf qualified;
   F3Exit ind pos(3);
end-Ds;

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

   dcl-s url      varchar(2000);
   dcl-s request  varchar(2000);
   dcl-s response varchar(5000);
   dcl-s httpstatus int(10);

   dcl-ds reqds qualified;          // {
     source varchar(2);             //   "source": "{string}",
     target varchar(2);             //   "target": "{string}",
     text   varchar(1000) dim(1);   //   "text": [ "{string}" ]
   end-ds;                          // }

   dcl-ds result qualified;         // {
     dcl-ds translations dim(1);    //   "translations": [{
        translation varchar(1000);  //      "translation": "{string}"
     end-ds;                        //   },
     word_count int(10);            //   "word_count": {number},
     character_count int(10);       //   "character_count": {number}
   end-ds;                          // }

   // Generate the JSON document to send

   reqds.source  = fromLang;
   reqds.target  = toLang;
   reqds.text(1) = fromText;

   data-gen reqds %data(request) %gen('YAJLDTAGEN');

   // Set options to control how HTTPAPI communicates with Watson

   http_debug(*on: '/tmp/watson-diagnostic-log.txt');
   http_setOption('local-ccsid': '0');
   http_setOption('network-ccsid': '1208');

   http_setAuth( HTTP_AUTH_BASIC
               : 'apikey'
               : 'YOUR IBM CLOUD KEY HERE');

   url = 'https://api.us-south.language-translator.watson.cloud.ibm.com'
       + '/instances/f7b6e575-01c4-4b1b-916a-3a79652d0f52'
       + '/v3/translate?version=2018-05-01';

   monitor;
      response = http_string('POST': url: request: 'application/json');
      http_error(*omit: httpstatus);
      httpcode = %char(httpstatus);
   on-error;
      httpcode = http_error();
   endmon;

   data-into result %DATA(response) %PARSER('YAJLINTO');
   return result.translations(1).translation;

end-Proc;

