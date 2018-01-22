(in-package :cl-user)
(defpackage run-main
  (:use :cl :prove :NicoVideoAnalyze))
(in-package #:run-main)

(NicoVideoAnalyze:main-loop "./nico.sqlite3")
