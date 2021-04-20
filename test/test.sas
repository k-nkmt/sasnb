%let root =  ;

%sasnb(prg = &root./test/sample.sas , 
       out = &root./test/sample.html,
  template = &root./nb_template.html
)  ;
