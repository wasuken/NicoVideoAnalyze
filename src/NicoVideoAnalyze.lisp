(in-package #:NicoVideoAnalyze)

;;; database path
(defvar *db-path* "../nico.sqlite3")

;;; slack
(defun read-file-to-list (filepath)
  (let ((lines '()))
    (with-open-file (in filepath)
      (loop for line = (read-line in nil)
         while line
         do (setf lines (append lines (list line)))))
    lines))
;;; ahokusa
(defun read-file-to-first-line (filepath)
  (car (read-file-to-list filepath)))

(defvar *payload-template* "{
   \"text\":\"~a\"
}")

(defun post (text &optional (hook-url (read-file-to-first-line "../hook-url-text")))
  (dex:post hook-url
            :content `(("payload" . ,(format nil *payload-template* text)))))

;;; 本日の日付をyyyy-MM-dd文字列でかえす
(defun get-format-date (&optional (later-day 0))
  (multiple-value-bind (sec min hour day mon year)
      (decode-universal-time (- (get-universal-time)
                                (* 60 60 24 later-day)))
    (format nil "~D-~2,'0D-~2,'0D ~2,'0D:~2,'0D:~2,'0D" year mon day hour min sec)))

(defun make-nico-aggregate-text (db-name)
  (reduce #'(lambda (x y) (concatenate 'string x y))
          (mapcar #'make-post-text
                  (nico-video-aggr db-name))))

;;; 情報を取るタイミング
(defvar *nico-get-idle-time* (* 60 60))

;;; なぜ標準関数にないのか
(defun take (lst n)
  (if (or (zerop n) (null lst))
      nil
      (cons (car lst) (take (cdr lst) (1- n)))))

(defun make-post-text (lst)
  (let ((content-id (getf lst (intern "content_id" :keyword)))
        (title (getf lst (intern "title" :keyword)))
        (aggr (getf lst (intern "aggr" :keyword))))
    (format nil "url: http://www.nicovideo.jp/watch/~A~%title:~A~%一週間の集計結果:~A~%" content-id title aggr)))

;;; 基礎URI
;;; これ固定で当分やっていき
(defvar *nico-base-uri-format*
  "http://api.search.nicovideo.jp/api/v2/video/contents/search?q=~A&~A")

;;; パラメタぐらい分けたほうがいいと思った。
(defvar *nico-uri-parameter*
  "targets=title,tags,tagsExact&_sort=-lastCommentTime&_context=apiguide&fields=title,contentId,viewCounter,mylistCounter&_limit=100")

;;; URI生成はこの関数で出すことにする。
(defun getURI (query)
  (format nil *nico-base-uri-format*
          query *nico-uri-parameter*))

;;; 外部からWebページを拾ってくる。
;;; JSONテキストをリスト化する。
;;; 拾ってきたJSONをParseする。
(defun make-nico-json (query)
  (json:decode-json-from-string
   (dex:get (getURI query))))

(defun main-loop (&optional
                    (db-name "./nico.sqlite3")
                    (get-times 24)      ;24時間分とったら一旦止めとく。
                    (search-query "VOICEROID実況プレイPart1リンク") ;kusa
                    (send-slackp nil))
  (loop repeat get-times
     do (let* ((nico-item-list
                (mapcar #'(lambda (x) (mapcar #'cdr x))
                        (cdadr (make-nico-json
                                (quri:url-encode search-query)))))

               (counter 0))
          (mapcar #'nico-insert nico-item-list
                  (loop repeat 100 collect db-name))
          (sleep *nico-get-idle-time*)
          (setf counter (1+ counter))
          (if (mod counter 3) (post (make-nico-aggregate-text db-name))))))

;;;;;;; ここからデータベース処理

;;; selectの抽象化
(defun something-select-records (db-name select)
  (dbi:with-connection (conn :sqlite3 :database-name db-name)
    (let* ((query (dbi:prepare conn select))
           ;; こんなアホなことするくらいならデータ構造変えたほうがよくね・・・？
           ;; かえることはできませんでした。現実は非常である。
           (result (dbi:execute query))
           (rows '()))
      ;; 存在しなかったらnilのまま
      (loop for row = (dbi:fetch result)
         while row
         do (setf rows (cons row rows)))
      rows)))
;;; 一度でも取得した動画の情報
(defun nico-video-items (db-name)
  (something-select-records db-name "select * from nico_video_item;"))
;;; joinしたレコード
(defun nico-video-detail-items (db-name)
  (something-select-records db-name "SELECT * FROM nico_video_item as ni join nico_video_detail as nd on ni.content_id = nd.content_id order by title;"))
;;; はいくそー
(defun nico-video-aggr (db-name &optional
                                  (after-date (get-format-date 7))
                                  (rec-cnt 10))
  (something-select-records db-name
                            (format nil "SELECT ni.content_id,title,insert_date,count(*) as aggr
 FROM nico_video_item as ni
 join nico_video_detail as nd on ni.content_id = nd.content_id
 where datetime('~A','localtime') < datetime(insert_date,'localtime')
 group by ni.content_id
 order by aggr limit ~A;" after-date rec-cnt))) ;koreha ikenai...

;; (defun nico-video-aggr (db-name)
;;   (something-select-records db-name "SELECT ni.content_id,title,count(*) as aggr FROM nico_video_item as ni join nico_video_detail as nd on ni.content_id = nd.content_id group by ni.content_id order by aggr;"))

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
      ;; debug point
      (if rows (print rows))
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
