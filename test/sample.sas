/*
# 利用方法
SAS単体(+ネット接続)でjupyter notebook風の出力を作成します。

コメント行は複数行をコメントアウトする記法で
コメントアウト用の記号の行は他の文字を含まないようにすると
コメントでmarkdown記法が利用可能です。

TeX記法も使えるかと思います。
ライブラリにMathJaxでなくKaTeXを使っているため、若干の表示の違いがあるかもしれません。
$$
f(x) = \frac{1}{\sqrt{2\pi\sigma^2}}\exp{-\frac{(x-\mu)^2}{2\sigma^2}}
$$

## 処理の概要
基本的にコメントでブロックに分割を行い、実行結果・ログをhtmlに埋め込んでいます。  
配列で埋め込み、テンプレート処置にはvue.jsを使用しています。

## プログラムについて
SASの処理で少し特殊なものとしては、以下のようなエスケープ処理があります。  
htmlでは特定の文字をSASのマクロのクォートと同様の処理を行う必要があります。 
SASでは`htmlencode`関数で処理できます。   
[リファレンス](https://support.sas.com/documentation/cdl_alternate/ja/lefunctionsref/67960/HTML/default/n0cm3nfzxlg3iwn1myjzv3t8rt8j.htm)
jsのテンプレートリテラルに使われるバッククォート(`)は対象外なので、これについては別途置換します。  
*/ 
data work.encode ;
  text = 'M&M' ;
  e_text = htmlencode(text) ;
run ;

proc print data = work.encode ;
run ;

/*
## デコード処理

htmlencode関数と反対の処理を行います
*/ 
data work.decode ;
  set work.encode ;
  d_text = htmldecode(text) ;
run ;