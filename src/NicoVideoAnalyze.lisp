(in-package #:NicoVideoAnalyze)
;;; 情報を取るタイミング
(defvar *nico-get-idle-time* (* 3 60 60))

;;;当分の間使うやつ。
(defvar *nico-sample-q* "voiceroid%E5%AE%9F%E6%B3%81%E3%83%97%E3%83%AC%E3%82%A4Part1%E3%83%AA%E3%83%B3%E3%82%AF")

;;; 基礎URI
;;; これ固定で当分やっていき
(defvar *nico-base-uri-format*
  "http://api.search.nicovideo.jp/api/v2/video/contents/search?q=~A&~A")

;;; パラメタぐらい分けたほうがいいと思った。
(defvar *nico-uri-parameter*
  "targets=title,tags,tagsExact&_sort=-lastCommentTime&_context=apiguide&fields=title,contentId,viewCounter,mylistCounter&_limit=100")

;;; データベースとして利用する
(defvar *nico-video-item* '())

;;; URI生成はこの関数で出すことにしよう。そう仕様。
(defun getURI (query)
  (format nil *nico-base-uri-format* query *nico-uri-parameter*))

;;; 外部からWebページを拾ってくる
;;; JSONテキストをリスト化する。
;;; 拾ってきたJSONをParseする
;;; これは・・・根(をおろしすぎてる分割されてないクソコード)じゃな・・・？
(defun nico-json ()
  (json:decode-json-from-string
   (dex:get (getURI *nico-sample-q*))))

;;; 日付出力関数
;;; どこでも使いそう
;;; 使ってない変数あるので警告でてるな
(defun get-date-string (&optional (fmt "~d/~0d/~0d ~0d:~d"))
  (multiple-value-bind
        (second minute hour date month year day daylight-p zone)
      (decode-universal-time (get-universal-time))
    (format nil fmt year month date hour minute)))

;;; 永久に取得していく
(defun main-loop (&optional (is-test nil))
  (let (nico-items '())
    (loop (setf nico-items
                (cons (cons :date (cons (GET-DATE-STRING)
                                        (if is-test
                                            (cadadr (NICO-JSON))
                                            (cdadr (NICO-JSON)))))
                      nico-items))
       (sleep 10))))

