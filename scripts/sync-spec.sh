#!/bin/sh
# Синхронизация спеки контракта в портал.
#
# Mintlify читает OpenAPI только внутри репы доков, поэтому здесь лежит копия.
# Источник правды — contract/openapi.yaml в приватной репе aggr-contract.
#
#   ./scripts/sync-spec.sh          обновить копию из контракта
#   ./scripts/sync-spec.sh --check  только проверить, разошлись ли (код 1 = разошлись)
#
# Проверка нужна потому, что забытый sync ломает вкладку «Операции» молча:
# страницы соберутся, но покажут вчерашний контракт.

set -eu

PORTAL_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
COPY="$PORTAL_DIR/api-reference/openapi.yaml"
SOURCE="${AGGR_CONTRACT:-$PORTAL_DIR/../aggr-contract/contract/openapi.yaml}"

HEADER_LINES=4
header() {
    cat <<'EOF'
# СГЕНЕРИРОВАННАЯ КОПИЯ — НЕ РЕДАКТИРОВАТЬ.
# Источник правды: contract/openapi.yaml в приватной репе aggr-contract.
# Копия нужна потому, что Mintlify читает спеку только внутри репы доков.
# Обновление: ./scripts/sync-spec.sh (проверка расхождения: --check)
EOF
}

if [ ! -f "$SOURCE" ]; then
    echo "не найден источник: $SOURCE" >&2
    echo "укажи путь явно: AGGR_CONTRACT=/путь/к/openapi.yaml $0 $*" >&2
    exit 2
fi

case "${1:-}" in
--check)
    if [ ! -f "$COPY" ]; then
        echo "РАСХОЖДЕНИЕ: копии нет вообще — вкладка «Операции» не соберётся" >&2
        exit 1
    fi
    if tail -n "+$((HEADER_LINES + 1))" "$COPY" | diff -q - "$SOURCE" >/dev/null 2>&1; then
        echo "спека синхронна с контрактом"
        exit 0
    fi
    echo "РАСХОЖДЕНИЕ: копия отстала от контракта. Строк разницы:" >&2
    tail -n "+$((HEADER_LINES + 1))" "$COPY" | diff - "$SOURCE" | wc -l >&2
    echo "чинится: $0" >&2
    exit 1
    ;;
"")
    { header; cat "$SOURCE"; } > "$COPY.tmp" && mv "$COPY.tmp" "$COPY"
    echo "спека обновлена из $SOURCE"
    ;;
*)
    echo "неизвестный аргумент: $1 (допустимо: пусто или --check)" >&2
    exit 2
    ;;
esac
