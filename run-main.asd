;; (require \'asdf)

(in-package :cl-user)
(defpackage run-main-asd
  (:use :cl :asdf))
(in-package :run-main-asd)

(defsystem :run-main
  :depends-on (:NicoVideoAnalyze)
  :version "1.0.0"
  :author "wasu"
  :license "MIT"
  :components ((:module "src" :components ((:file "run-main")))))

