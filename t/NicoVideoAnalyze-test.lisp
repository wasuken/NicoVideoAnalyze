(in-package :cl-user)
(defpackage NicoVideoAnalyze-test
  (:use :cl :prove :NicoVideoAnalyze))
(in-package #:NicoVideoAnalyze-test)

(defvar *test-db-name*
  (concatenate 'string
               (namestring (truename "./"))
               "nico_test.sqlite3"))
(defvar *nico-item-list*
  (mapcar #'(lambda (x) (mapcar #'cdr x))
          (cdadr (NicoVideoAnalyze:make-nico-json
                  (quri:url-encode "VOICEROID実況プレイPart1リンク")))))

(plan 2)

(subtest "取得したJSONへのテスト"
  (diag "100取れてる？")
  (is 100 (length *nico-item-list*))
  (diag "取得した100のアイテムはすべて各Itemは4ある？")
  (if (= (length (remove-if #'(lambda (x) (= x 4))
                            (mapcar #'length *nico-item-list*)))
         0)
      (pass "OK!")
      (fail "NG!")))

;; (subtest "データベーステスト"
;;   (diag "登録する && 登録できた確認")
;;   (skip 3 "まだできてないよ"))
