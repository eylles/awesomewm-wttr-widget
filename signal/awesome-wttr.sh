#!/bin/sh

export LANG=C

configdir="${XDG_CONFIG_HOME:-${HOME}/.config}/awesome/wttr-daemon"
config="${configdir}/configrc"

#arguments
cache_path="$1"
shift

if [ ! -d "$cache_path" ]; then
    mkdir -p "$cache_path"
fi

cache_timeout="600"
location=""
textbox_format="%c%t/%f+%m"
tooltip_format="%c%C+🌡️%t/%f+💦%p/%h+💨%w+〽%P+%m"
language="en"

if [ -f "$config" ]; then
    . "$config"
else
    if [ ! -d "$configdir" ]; then
        mkdir -p "$configdir"
    fi
    {
        printf '%s=%s\n' "cache_timeout" "$cache_timeout"
        printf '%s=%s\n' "location" "$location"
        printf '%s=%s\n' "textbox_format" "$textbox_format"
        printf '%s=%s\n' "tooltip_format" "$tooltip_format"
        printf '%s=%s\n' "language" "$language"
    } > "$config"
fi

textbox_fetch="${location}?format=${textbox_format}&lang=${language}"
tooltip_fetch="${location}?format=${tooltip_format}&lang=${language}"
fullcast_fetch="${location}?lang=${language}"

textbox_cache="${cache_path}/textbox"
tooltip_cache="${cache_path}/tooltip"
fullcast_cache="${cache_path}/fullcast"

url="https://wttr.in"

textbox=""
textboxold="$textbox"

tooltip=""
tooltipold="$tooltip"

textboxsig="wttr::textbox"
tooltipsig="wttr::tooltip"

sig_handler () {
    cont=1
}

cont=0

# usage: get_weather "cache_file" "format"
get_weather () {
    format=""
    cache_file="$1"
    shift
    tmp="${cache_file}_tmp"
    if [ -n "$1" ]; then
        format="$1"
        shift
    fi
    curl \
        --silent --show-error --fail --get --compressed \
        -o "$tmp" \
        -X GET "${url}/${format}" && mv "$tmp" "$cache_file"
}

shell_true=0
shell_false=1

is_older_than_timeout () {
    result=$shell_false
    now="$(date '+%s')"
    file="$1"
    shift
    timeout="$cache_timeout"
    file_age="$(stat -c '%Y' "$file")"
    seconds_delta=$(( now - file_age ))
    if [ "$seconds_delta" -ge "$timeout" ]; then
        result=$shell_true
    fi
    return $result
}

main () {
    while [ "$cont" -eq 0 ]; do
        until [ -f "$textbox_cache" ]; do
            get_weather "$textbox_cache" "$textbox_fetch"
        done
        until [ -f "$tooltip_cache" ]; do
            get_weather "$tooltip_cache" "$tooltip_fetch"
        done
        until [ -f "$fullcast_cache" ]; do
            get_weather "$fullcast_cache" "$fullcast_fetch"
        done
        textbox=$(head "$textbox_cache")
        tooltip=$(head "$tooltip_cache")
        if [ "$textbox" != "$textboxold" ]; then
            awesome-client "awesome.emit_signal('$textboxsig','$textbox')"
            textboxold="$textbox"
        fi
        if [ "$tooltip" != "$tooltipold" ]; then
            awesome-client "awesome.emit_signal('$tooltipsig','$tooltip')"
            tooltipold="$tooltip"
        fi
        while is_older_than_timeout "$textbox_cache"; do
            get_weather "$textbox_cache" "$textbox_fetch"
        done
        while is_older_than_timeout "$tooltip_cache"; do
            get_weather "$tooltip_cache" "$tooltip_fetch"
        done
        while is_older_than_timeout "$fullcast_cache"; do
            get_weather "$fullcast_cache" "$fullcast_fetch"
        done
        sleep 1
    done
}

trap 'sig_handler' INT TERM HUP

main > /dev/null 2>&1
