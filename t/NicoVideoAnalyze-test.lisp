(in-package :cl-user)
(defpackage NicoVideoAnalyze-test
  (:use :cl :prove :NicoVideoAnalyze))
(in-package #:NicoVideoAnalyze-test)

(plan 2)

(let* ((nico-item-list
        (mapcar #'(lambda (x) (mapcar #'cdr x)) (cdadr (NicoVideoAnalyze:nico-json))))
       (item-length (length nico-item-list)))
  (format t "１００個取れてる？")
  (is 100 (length nico-item-list))
  (format t "各Itemは４つある？")
  (is 4 (length (car nico-item-list))))
