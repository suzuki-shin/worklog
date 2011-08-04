(defvar worklog-prg-path "~/projects/worklog/worklog.pl")
(require 'my-worklog-conf)
(defun worklog-action (action type content project term start end)
  "worklogを実行するperlのプログラムを呼ぶ"
  (shell-command
   (concat "perl " worklog-prg-path
		   (if (< 0 (length action)) (concat " --action=" action))
		   (if (< 0 (length type)) (concat " --type=" type))
		   (if (< 0 (length content)) (concat " --content=" content))
		   (if (< 0 (length project)) (concat " --project=" project))
		   (if (< 0 (length term)) (concat " --term=" term))
		   (if (< 0 (length start)) (concat " --start=" start))
		   (if (< 0 (length end)) (concat " --end=" end)))))
;;; interactive関数
(defun worklog-summary (start end)
  "作業ログDBのデータのサマリを表示する関数"
  (interactive "sstart: \nsend: ")
  (let ((action "summary"))
	(worklog-action action nil nil nil nil start end)))
(defun worklog-list ()
  "作業ログDBのデータの一覧を表示する関数"
  (interactive)
  (let ((action "list")
		(type (completing-read "type: " type-alist nil t))
		(project (completing-read "project: " project-alist nil t))
		(term (completing-read "term: " term-alist nil t)))
	(worklog-action action type nil project term nil nil)))
(defun worklog-insert-interactive3 ()
  "作業ログDBにデータをインサートする関数（contentの引数補完有りで、contentを決めるとtask, projectも対応したものが設定される。対応するものが設定されていなければ補完付きで入力する）"
  (let* ((action "insert")
		 (content-list (mapcar 'car task-list))
		 (content (completing-read "content: " content-list nil t))
		 (type (if (string= "" (cadr (assoc content task-list)))
				 (completing-read "type: " type-alist nil t)
				 (cadr (assoc content task-list))))
		 (project (if (string= "" (caddr (assoc content task-list)))
					(completing-read "project: " project-alist nil t)
					(caddr (assoc content task-list)))))
	(worklog-action action type content project nil nil nil)))
(defun worklog-insert-interactive2 ()
  "作業ログDBにデータをインサートする関数（引数補完有り）"
  (let* ((action "insert")
		 (content-alist (mapcar 'car task-alist))
		 (content (completing-read "content: " content-alist nil t))
		 (type (completing-read "type: " type-alist nil t))
		 (project (completing-read "project: " project-alist nil t)))
	(worklog-action action type content project nil nil nil)))
(defun worklog-insert-interactive (content)
  "作業ログDBにデータをインサートする関数（content以外の引数補完有り）"
  (interactive "scontent: ")
  (let ((action "insert")
		(type (completing-read "type: " type-alist nil t))
		(project (completing-read "project: " project-alist nil t)))
	(worklog-action action type content project nil nil nil)))
(defun worklog-insert-nocomp (type content project)
  "作業ログDBにデータをインサートする関数（引数補完無し）"
  (interactive "stype: \nscontent: \nsproject: ")
  (let ((action "insert"))
	(worklog-action action type content project nil nil nil)))
(defun worklog-list-today ()
  "本日の作業ログDBのデータの一覧を表示する関数"
  (interactive)
  (let ((action "list"))
	(worklog-action action nil nil nil nil nil nil)))
(defun worklog-insert-at-line ()
  "ポイントのある行の内容を良い感じにINSERTする"
  (interactive)
  (message (thing-at-point 'line)))

(provide 'my-worklog)
