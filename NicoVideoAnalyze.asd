;; (require \'asdf)

(in-package :cl-user)
(defpackage NicoVideoAnalyze-asd
  (:use :cl :asdf))
(in-package :NicoVideoAnalyze-asd)

(defsystem :NicoVideoAnalyze
    :version "1.0.0"
    :author "wasu"
    :license "MIT"
    :components ((:file "package")
                 (:module "src" :components ((:file "NicoVideoAnalyze")))))

