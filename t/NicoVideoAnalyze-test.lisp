(in-package :cl-user)
(defpackage NicoVideoAnalyze-test
  (:use :cl :prove :NicoVideoAnalyze))
(in-package #:NicoVideoAnalyze-test)

(defvar *test-db-name*
  (concatenate 'string
               (namestring (truename "./"))
               "nico_test.sqlite3"))

(plan 2)

(format t "基本的なテスト")
(let* ((nico-item-list
        (mapcar #'(lambda (x) (mapcar #'cdr x))
                (cdadr (NicoVideoAnalyze:make-nico-json (quri:url-encode "VOICEROID実況プレイPart1リンク")))))
       (item-length (length nico-item-list)))
  (format t "１００個取れてる？")
  (is 100 (length nico-item-list))
  (format t "各Itemは４つある？")
  (is 4 (length (car nico-item-list))))
