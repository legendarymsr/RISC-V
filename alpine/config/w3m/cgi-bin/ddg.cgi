#!/bin/sh
# ddg: scheme → DuckDuckGo Lite (wired up in ../urimethodmap). w3m runs this as
# a local CGI with QUERY_STRING="ddg:<query>" and obeys the W3m-control lines.
q=$(printf '%s' "${QUERY_STRING#ddg:}" | tr -d '\r\n' | sed 's/&/%26/g; s/ /+/g')
printf 'W3m-control: GOTO https://lite.duckduckgo.com/lite/?q=%s\n' "$q"
printf 'W3m-control: DELETE_PREVBUF\n\n'
