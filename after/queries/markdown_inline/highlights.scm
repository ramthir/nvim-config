; extends

; Override conceal on ** delimiters inside bold — show them in gray
(strong_emphasis
  (emphasis_delimiter) @markup.strong.delimiter
  (#set! priority 200))

; Override conceal on * or _ delimiters inside italic — show them in gray
(emphasis
  (emphasis_delimiter) @markup.italic.delimiter
  (#set! priority 200))
