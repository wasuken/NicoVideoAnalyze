(in-package #:NicoVideoAnalyze)
;;; 情報を取るタイミング
(defvar *nico-get-idle-time* (* 60 60))

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

(defun proc-nico-item (item)
  (let ((lst '()))
    (loop for node in item
         do (setf lst ()))))

;;; 
(defun main-loop (&optional (db-name "./nico.sqlite3") (get-times 24))
  (loop repeat get-times
     do (let* ((nico-item-list
                (mapcar #'(lambda (x) (mapcar #'cdr x))
                        (cdadr (nico-json)))))
          (mapcar #'nico-insert nico-item-list
                  (loop repeat 100 collect db-name))
          (sleep *nico-get-idle-time*))))


;;; 上を下に変換する
;; (:DATE "2018/1/22 20:21"
;;; (:TITLE . "【PS4版BF1】ゆっくり逝きたいBF1 Part1【ゆっくり+紲星あかり実況】"
;;   (:CONTENT-ID . "sm32623880") (:VIEW-COUNTER . 96) (:MYLIST-COUNTER . 5)))
;;; ("【PS4版BF1】ゆっくり逝きたいBF1 Part1【ゆっくり+紲星あかり実況】" "sm32623880" 96 5)
;;; 悲しいけどこれが限界なのよね



;;;;;;; ここからデータベース処理

;;; database path
(defvar *db-path* "../nico.sqlite3")

;;; 挿入
;;; 前DB系書いた時マクロつくって楽しようとしたらクッソ時間かかったから
;;; 今回はとりあえず作ること優先する
(defun insert-nico-video-item (id title db-name)
  (dbi:with-connection (conn :sqlite3 :database-name db-name)
  (let* ((query (dbi:prepare conn "insert into nico_video_item(content_id,title) values(?,?)"))
         (result (dbi:execute query id title))
         (fetch result)))))

(defun insert-nico-video-detail (id viewCounter mylistCounter db-name)
  (dbi:with-connection (conn :sqlite3 :database-name db-name)
  (let* ((query (dbi:prepare conn "insert into nico_video_detail(content_id,view_Counter,mylist_Counter) values(?,?,?)"))
         (result (dbi:execute query id viewCounter mylistCounter))
         (fetch result)))))

(defun nico-insert (item &optional (db-name *db-path*))
  (dbi:with-connection (conn :sqlite3 :database-name db-name)
    (let* ((query (dbi:prepare conn "SELECT * FROM nico_video_item where content_id = ?"))
           ;; こんなアホなことするくらいならデータ構造変えたほうがよくね・・・？
           ;; かえることはできませんでした。現実は非常である。
           (id (nth 1 item))
           (result (dbi:execute query id))
           (rows '()))
      ;; 存在しなかったらnilのまま
      (loop for row = (dbi:fetch result)
         while row
         do (setf rows (cons row rows)))
      (print rows)
      (when (not rows)
        (insert-nico-video-item id (nth 0 item) db-name))
      (insert-nico-video-detail id
                                (nth 2 item)
                                (nth 3 item)
                                db-name))))

;;; 作らない(作る)
;;; でも辛い
;; (defun insert-table (table-name &body values)
;;   (let* ((query (dbi:prepare conn
;;                              ;; ここSQLインジェクション事案
;;                              (format nil "insert into (~A) values(~A)" values)))
;;          (result (dbi:execute query name))
;;          (fetch result))))
