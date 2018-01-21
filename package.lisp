;; (in-package :cl-user)
(defpackage NicoVideoAnalyze
  (:use :cl :clss)
  (:shadowing-import-from :dexador :get)
  (:export nico-json))
