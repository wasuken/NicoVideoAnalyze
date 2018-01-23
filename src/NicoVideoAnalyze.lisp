(in-package #:NicoVideoAnalyze)
;;; 情報を取るタイミング
(defvar *nico-get-idle-time* (* 60 60))

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
                    (search-query "VOICEROID実況プレイPart1リンク")) ;kusa
  (loop repeat get-times
     do (let* ((nico-item-list
                (mapcar #'(lambda (x) (mapcar #'cdr x))
                        (cdadr (make-nico-json
                                (quri:url-encode search-query))))))
          (mapcar #'nico-insert nico-item-list
                  (loop repeat 100 collect db-name))
          (sleep *nico-get-idle-time*))))

;;;;;;; ここからデータベース処理

;;; database path
(defvar *db-path* "../nico.sqlite3")

;;; 一度でも取得した動画の情報
(defun nico-video-items (db-name)
  (dbi:with-connection (conn :sqlite3 :database-name db-name)
    (let* ((query (dbi:prepare conn "SELECT * FROM nico_video_item order by title"))
           ;; こんなアホなことするくらいならデータ構造変えたほうがよくね・・・？
           ;; かえることはできませんでした。現実は非常である。
           (result (dbi:execute query))
           (rows '()))
      ;; 存在しなかったらnilのまま
      (loop for row = (dbi:fetch result)
         while row
         do (setf rows (cons row rows)))
      rows)))

;;; joinしたレコード
(defun nico-video-detail-items (db-name)
  (dbi:with-connection (conn :sqlite3 :database-name db-name)
    (let* ((query (dbi:prepare conn "SELECT * FROM nico_video_item as ni join nico_video_detail as nd on ni.content_id = nd.content_id order by title"))
           ;; こんなアホなことするくらいならデータ構造変えたほうがよくね・・・？
           ;; かえることはできませんでした。現実は非常である。
           (result (dbi:execute query))
           (rows '()))
      ;; 存在しなかったらnilのまま
      (loop for row = (dbi:fetch result)
         while row
         do (setf rows (cons row rows)))
      rows)))

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
