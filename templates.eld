fundamental-mode :when IS-PERSONAL

(copyright "")

fundamental-mode

(auto-insert (i copyright))
(today (format-time-string "%Y-%m-%d"))

(fixme (if (derived-mode-p 'emacs-lisp-mode) ";; " comment-start) "FIXME ")
(todo (if (derived-mode-p 'emacs-lisp-mode) ";; " comment-start) "TODO ")
(bug (if (derived-mode-p 'emacs-lisp-mode) ";; " comment-start) "BUG ")
(hack (if (derived-mode-p 'emacs-lisp-mode) ";; " comment-start) "HACK ")

lisp-mode emacs-lisp-mode

(lambda "(lambda (" p ")" n> r> ")")

emacs-lisp-mode

(var "(defvar " p "\n  \"" p "\")")
(local "(defvar-local " p "\n  \"" p "\")")
(const "(defconst " p "\n  \"" p "\")")
(custom "(defcustom " p "\n  \"" p "\"" n> ":type '" p ")")
(fun "(defun " p " (" p ")\n  \"" p "\"" n> r> ")")
(iflet "(if-let (" p ")" n> r> ")")
(whenlet "(when-let (" p ")" n> r> ")")
(cond "(cond" n "(" q "))" >)
(pcase "(pcase " (p "scrutinee") n "(" q "))" >)
(let "(let (" p ")" n> r> ")")
(lett "(let* (" p ")" n> r> ")")
(loop "(cl-loop for " p " in " p " do" n> r> ")")
(command "(defun " p " (" p ")\n  \"" p "\"" n> "(interactive" p ")" n> r> ")")
(advice "(defun " (p "adv" name) " (&rest app)" n> p n> "(apply app))" n>
        "(advice-add #'" (p "fun") " " (p ":around") " #'" (s name) ")")
(header ";;; " (file-name-nondirectory (or (buffer-file-name) (buffer-name)))
        " --- " p " -*- lexical-binding: t -*-" n
        ";;; Commentary:" n ";;; Code:" n n)
(provide "(provide '" (file-name-base (or (buffer-file-name) (buffer-name))) ")" n
         ";;; " (file-name-nondirectory (or (buffer-file-name) (buffer-name)))
         " ends here" n)
(package (i header) (i copyright) r n n (i provide))
(auto-insert (i package))

eshell-mode

(for "for " (p "i") " in " p " { " q " }")
(while "while { " p " } { " q " }")
(until "until { " p " } { " q " }")
(if "if { " p " } { " q " }")
(ife "if { " p " } { " p " } { " q " }")
(unl "unless { " p " } { " q " }")
(unle "unless { " p " } { " p " } { " q " }")

java-mode

(class "public class " (p (file-name-base (or (buffer-file-name) (buffer-name)))) " {" n> r> n "}")
(auto-insert (i copyright) (i class))

c-mode c++-mode c-ts-mode c++-ts-mode
(inc "#include <" (p (concat (file-name-base (or (buffer-file-name) (buffer-name))) ".h")) ">")
(incc "#include \"" (p (concat (file-name-base (or (buffer-file-name) (buffer-name))) ".h")) "\"")
(main "int main(int argc, char **argv) {" n>
      "return 0;" n
      "}")
(guard-h "#ifndef "
   (upcase (file-name-nondirectory (file-name-sans-extension buffer-file-name)))
   "_H" n
   "#define "
   (upcase (file-name-nondirectory (file-name-sans-extension buffer-file-name)))
   "_H" n n p q n n
   "#endif /* "
   (upcase (file-name-nondirectory (file-name-sans-extension buffer-file-name)))
   "_H */")
(guard-hpp "#pragma once" n n)
(auto-insert
 (i copyright)
 (let* ((file-name (or (buffer-file-name) (buffer-name)))
       (extension (file-name-extension file-name)))
   (when (string-prefix-p "h" extension t)
     (tempel-insert (if (derived-mode-p 'c++-mode) 'guard-hpp 'guard-h)))))

org-mode

(caption "#+caption: ")
(drawer ":" p ":" n r ":end:")
(begin "#+begin_" (s name) n> r> n "#+end_" name)
(q "#+begin_quote" n> r> n "#+end_quote")
(sidenote "#+begin_sidenote" n> r> n "#+end_sidenote")
(marginnote "#+begin_marginnote" n> r> n "#+end_marginnote")
(e "#+begin_example" n> r> n "#+end_example")
(c "#+begin_center" n> r> n "#+end_center")
(ea "#+begin_export ascii" n> r> n "#+end_export")
(eh "#+begin_export html" n> r> n "#+end_export")
(el "#+begin_export latex" n> r> n "#+end_export")
(et "#+begin_export typst" n> r> n "#+end_export")
(c "#+begin_comment" n> r> n "#+end_comment")
(v "#+begin_verse" n> r> n "#+end_verse")
(gnuplot "#+begin_src gnuplot :var data=" (p "table") " :file " (p "plot.png") n r n "#+end_src" :post (org-edit-src-code))
(si "src_" p "{" q "}")
(s "#+begin_src " q n r n "#+end_src" :post (org-edit-src-code))
(sp "#+begin_src python" n r n "#+end_src" :post (org-edit-src-code))
(sl "#+begin_src log" n r n "#+end_src" :post (org-edit-src-code))
(sel "#+begin_src emacs-lisp" n r n "#+end_src" :post (org-edit-src-code))
(babel
 "#+LaTeX_HEADER: \\usepackage[english]{babel}" n
 "#+LaTeX_HEADER: \\babelprovide[onchar=ids fonts]{greek}" n
 "#+LaTeX_HEADER: \\babelfont[greek]{rm}{Noto Serif}" n
 "#+LaTeX_HEADER: \\babelfont[greek]{sf}{Noto Sans}" n
 "#+LaTeX_HEADER: \\babelfont[greek]{tt}{Noto Sans}" n
 "#+LaTeX_HEADER: \\babelprovide[onchar=ids fonts]{coptic}" n
 "#+LaTeX_HEADER: \\babelfont[coptic]{rm}{Free Serif Avva Shenouda}" n
 "#+LaTeX_HEADER: \\babelfont[coptic]{sf}{Free Serif Avva Shenouda}" n
 "#+LaTeX_HEADER: \\babelfont[coptic]{tt}{Free Serif Avva Shenouda}" n
 n)
(auto-insert
 "#+TITLE: " (file-name-base (or (buffer-file-name) (buffer-name))) n
 "#+AUTHOR: " user-full-name n
 "#+EMAIL: " user-mail-address n
 "#+OPTIONS: " "toc:nil ^:t _:t {}:t author:nil title:nil timestamp:nil html-postamble:nil float:nil" n
 n n p q)

;; Local Variables:
;; mode: lisp-data
;; outline-regexp: "[a-z]"
;; End:
