**free
//  WATSONTR2R:  This is a demo of Watson's Language Translator V3
//               using input/output with JSON documents.
//
//               Requires HTTPAPI and YAJL
//
//               This example uses YAJL's tree API to read the
//               response. For a DATA-INTO example, see WATSONTR3R
//
ctl-opt option(*srcstmt) bnddir('HTTPAPI':'YAJL');

/copy version.rpgleinc
/copy httpapi_h
/copy yajl_h

dcl-f WATSONTR2D workstn indds(dspf);

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
   dcl-s output   varchar(1000);
   dcl-s errMsg   varchar(500);
   dcl-s docNode  like(yajl_val);
   dcl-s node     like(yajl_val);

   yajl_genOpen(*off);
   yajl_beginObj();                     // {
     yajl_addChar('source': fromLang);  //   "source": "en",
     yajl_addChar('target': toLang);    //   "target": "fr",
     yajl_beginArray('text');           //   "text": [
       yajl_addChar(fromText );         //     "String here"
     yajl_endArray();                   //   ]
   yajl_endObj();                       // }

   request = yajl_copyBufStr();
   yajl_genClose();

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
   on-error;
      httpcode = http_error();
   endmon;

   docNode = yajl_string_load_tree(response: errMsg);
   if errMsg = '';
      node = yajl_object_find(docNode: 'translations');
      node = yajl_array_elem(node: 1);
      node = yajl_object_find(node: 'translation');
      output = yajl_get_string(node);
      yajl_tree_free(docNode);
   endif;

   return output;

end-Proc;

