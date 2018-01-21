(in-package #:NicoVideoAnalyze)
;;;当分の間使うやつ。
(defparameter nico-sample-q "voiceroid%E5%AE%9F%E6%B3%81%E3%83%97%E3%83%AC%E3%82%A4Part1%E3%83%AA%E3%83%B3%E3%82%AF")

;;; 基礎URI
;;; これ固定で当分やっていき
(defparameter nico-base-uri-format
  "http://api.search.nicovideo.jp/api/v2/video/contents/search?q=~A&~A")

;;; パラメタぐらい分けたほうがいいと思った。
(defparameter nico-uri-parameter
  "targets=title,tags,tagsExact&_sort=-lastCommentTime&_context=apiguide&fields=title,contentId,viewCounter,mylistCounter&_limit=100")

;;; URI生成はこの関数で出すことにしよう。そう仕様。
(defun getURI (query)
  (format nil nico-base-uri-format query nico-uri-parameter))

;;; 外部からWebページを拾ってくる
;;; JSONテキストをリスト化する。
;;; 拾ってきたJSONをParseする
;;; これは・・・根(をおろしすぎてる、いわゆる分割されてないクソコード)じゃな・・・？
(defun nico-json ()
  (json:decode-json-from-string
   (dex:get (getURI nico-sample-q))))

