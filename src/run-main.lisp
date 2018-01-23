(in-package :cl-user)
(defpackage run-main
  (:use :cl :prove :NicoVideoAnalyze))
(in-package #:run-main)

;;; 実際にループ動かす用
;;; もっといい方法探して
(NicoVideoAnalyze:main-loop "./nico.sqlite3"
                            24
                            "VOICEROID実況プレイPart1リンク")
