# Usage: markdown2html FILE		(Generate HTML and open browser)
markdown2html() {
	if ! hash markdown2 2> /dev/null; then
		echo "markdown2 not installed"
		return
	fi
	[ -n "$1" ] || return
	local html
	html=$(command mktemp /tmp/markdown_XXXXXX.html)
	cat <<-EOF > $html
	<html>
	<head>
		<link rel="stylesheet" href="http://markdowncss.github.io/modest/css/modest.css">
	</head>
	<body>
	EOF
	markdown2 "$@" >> $html
	cat <<-EOF >> $html
	</body>
	</html>
	EOF
	echo "Wrote $html"
	xdg-open $html
}
