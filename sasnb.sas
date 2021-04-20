/*
SASNB Notebook Style Output 
==============================================

Param
----------------------------------------------
prg: 
  Program path  
out: 
  Output html path
template:
  Template html path 
encode:
  Program file encoding 
run: 
  Run code flag(default:Y)

Note  
----------------------------------------------
version 0.2 For sample.  
*/

%macro sasnb(prg = , out = , template = , encode = , run = Y)  ;

filename prg "&prg." %if %length(&encode.) > 0 %then encoding = "&encode." ;;
filename out "&out." ;
filename tmpl "&template." ;
filename code temp ;
filename result temp ;
filename codelog temp ;
filename json temp ;

data work._FILE ;
  infile prg ;
  length text $2000  ;
  retain comfl 0 codeid 0 ;

  input ;
  text = _infile_ ;

  if prxmatch("/^\s*\/\*\s*$/", text) > 0 then do ;
   comfl = 1 ;
   chunk + 1 ; 
  end ;

  if _n_ = 1 and comfl = 0 then codeid + 1;

  output ;

  if prxmatch("/^\s*\*\/\s*$/", text) > 0 then do ;
   comfl = 0 ;
   chunk + 1 ; 
   codeid + 1 ;
  end ;
run ;

proc sql noprint ;
 select count(distinct chunk) into: chunk
 from work._FILE ;
quit ;


%do i = 1 %to &chunk. ; 
data _null_ ;
  set work._FILE end = eof ;
  file json %if &i. > 1 %then mod ; ;
  where chunk = &i. ;

  if _n_ = 1 then do ;
    call symputx("comfl", comfl) ;  

    if comfl = 1 then put "{'md':`" ;
    else do ;
      put "{'n':" codeid "," ;
      put "'code':`" @ ;
    end ;
  end ;

  e_text = htmlencode(text) ;
  if comfl = 1 then do ;
    e_text = prxchange('s/\\/\\\\/', -1, e_text ) ;
    e_text = prxchange('s/(?<!\\)`/\\`/', -1, e_text ) ;
  end ;    
  else e_text = transtrn(e_text, '`', '&#096;') ;
  
  len = lengthn(e_text) ;
  if comfl = 0 or prxmatch("/^\s*(\/\*|\*\/)\s*$/", text) = 0 then put e_text $varying. len @ ;

  if eof = 0 then put " " ;
  else do ;
   if comfl = 1 then put "`}," ;
   else put "`," ;
  end ;

run ;

  %if &comfl. = 0 %then %do ;

    %if &run. = Y %then %do ;
    data _null_ ;
      set work._FILE end = eof ;
      file code ;
      where chunk = &i. ;
      len = lengthn(text) ;
      put text $varying. len ;
    run ;

    ods html file = result ;
    proc printto log = codelog new ;
    run ;

    %include code / source2 ;
    proc printto ;
    run ;

    ods html close ;

    data _null_ ;
      infile codelog end = eof ;
      file json mod ;
      retain outfl 0 ;
 
      input ;
      e_text = transtrn(_infile_, '`', '&#096;') ;

      if _n_ = 1 then do ;
          put "'log':`" ;
      end ;
      
      if prxmatch("/^\d+\s+/", e_text) > 0 then outfl = 1 ;

      if eof = 1 then do ;
       put "`," ;
      end ;
      else if outfl = 1 then put e_text ;
    run ;

    data _null_ ;

      infile result end = eof ;
      file json mod ;
      retain outfl 0 ;

      input ;
      if _n_ = 1 then do ;
          put "'result':`" ;
      end ;

      e_text = transtrn(_infile_, '`', '&#096;') ;

      if prxmatch("/<div/", e_text) > 0 then outfl = 1 ; 

      if prxmatch("/<\/body>/", e_text) > 0 then do ;
       put "`}," ;
       stop ;
      end ;

      if outfl = 1 then put e_text ;
      if eof = 1 then put "`}," ;
    run ;
    %end ;
    %else %do ;
     data _null_ ;
      file json mod ; 
      put "}," ;
    run ;
    %end ;
  %end ;
%end ;

data work._json ;
  infile json ;
  length text $2000  ;
  retain _ord 2 ;
  input ;
  text = _infile_ ;
run ;

data work._template ;
  infile tmpl ;
  length text $2000 ;
  retain _ord 1 ;
  input ;
  text = _infile_ ;
  output ;
  if find(text, "Insert") > 0 then _ord = 3 ;
run ;

data _null_ ;
  set work._template
      work._json
      ;
  by _ord ;
  file out encoding = "utf-8" ;
  len = lengthn(text) ;
  put text $varying. len ;
run ;

%mend ;