;; (in-package :cl-user)
(defpackage NicoVideoAnalyze
  (:use :cl)
  (:shadowing-import-from :dexador :get)
  (:export :nico-json :nico-insert :insert-nico-video-item
           :main-loop))
