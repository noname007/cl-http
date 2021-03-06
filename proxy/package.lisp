;;;   -*- Mode: LISP; Package: CL-USER; BASE: 10; Syntax: ANSI-Common-Lisp; Default-Character-Style: (:FIX :ROMAN :NORMAL);-*-
;;;
;;; (c) Copyright 2001, 2006, John C. Mallery
;;;     All Rights Reserved.
;;;
;;;------------------------------------------------------------------- 
;;;
;;; PACKAGE
(in-package :cl-user)

(mapc #'(lambda (x)
	  (export (intern x :http) :http))
      '("*DATABASE-LOG-PROCESS-PRIORITY*"
	"*PROXY-CACHE*"
	"*PROXY-CACHE-CLASS*"
	"*PROXY-CACHE-DEFAULT-EXPIRATION-INTERVAL*"
	"PROXY-ENSURE-VALIDATE-CACHE-ENTRY"
	"*PROXY-CACHE-FULL-GC-FREE-SPACE-RATIO*"
	"*PROXY-CACHE-INCREMENTAL-GC*"
	"*PROXY-CACHE-INCREMENTAL-GC-FREE-SPACE-RATIO*"
	"*PROXY-CACHE-INCREMENTAL-GC-PROCESS-PRIORITY*"
	"*PROXY-CACHE-INCREMENTAL-GC-FREE-SPACE-TRIGGER-RATIO*"
	"*PROXY-CACHE-MAXIMUM-EXPIRATION-TIME*"
	"*PROXY-CACHE-MAXIMUM-RESOURCES*"
	"*PROXY-CACHE-MAXIMUM-SIZE*"
	"*PROXY-CACHE-MINIMUM-EXPIRATION-TIME*"
	"*PROXY-CACHEABLE-REQUEST-HEADERS*"
        "*PROXY-CONNECT-ALLOWED-PORTS*"
	"*PROXY-DATABASE-CLASS*"
	"*PROXY-SERVER-LIFE-TIME*"
	"*REPRESENTATION-CLASS*"
	"*RESOURCE-CLASS*"
	"*STANDARD-PROXY-PORT*"
	"DEBUG-PROXY"
        "DEFINE-PROXY-CONNECT-DISALLOWED-DESTINATION-SUBNETS"
	"DISABLE-PROXY-SERVICE"
	"ENSURE-EXTENDED-PROXY-LOG"
	"ENABLE-PROXY-SERVICE"
	"EXPORT-PROXY-INTERFACES"
	"SET-STANDARD-HTTP-PROXY-PORT"
	"INITIALIZE-PROXY-CACHE"
	"TRACE-PROXY"))
