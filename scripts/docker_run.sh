#!/usr/bin/env bash
# Script to manage Docker containers for AuthVault backend and database
set -e
# Detect compose file location
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$SCRIPT_DIR/docker-compose.yml" ]; then
    COMPOSE_FILE="$SCRIPT_DIR/docker-compose.yml"
elif [ -f "$SCRIPT_DIR/../docker-compose.yml" ]; then
    COMPOSE_FILE="$SCRIPT_DIR/../docker-compose.yml"
else
    COMPOSE_FILE="docker-compose.yml"
fi
# State variables
DETACH_FLAG=false
BUILD_FLAG=false
REMOVE_VOLUMES=false
ACTION="up"
COMPOSE_CMD=""
# Display usage instructions
show_help() {
    echo "[USAGE] $0 [OPTIONS|COMMAND]"
    echo "Commands:"
    echo "  up              Start BE and DB containers"
    echo "  down            Stop and remove containers and network"
    echo "  stop            Stop running containers"
    echo "  restart         Restart containers"
    echo "  logs            Stream container logs"
    echo "  ps              List container status"
    echo "Options / Flags:"
    echo "  -d, --detach    Run containers in background"
    echo "  -b, --build     Rebuild images before starting"
    echo "  -s, --stop      Stop all containers"
    echo "  --down          Stop and remove containers"
    echo "  -v, --volumes   Remove named volumes when used with --down"
    echo "  -r, --restart   Restart all containers"
    echo "  -l, --logs      Follow container logs"
    echo "  -p, --ps        Show container status"
    echo "  -h, --help      Display help guide"
}
# Resolve available docker compose command
resolve_compose_cmd() {
    if docker compose version >/dev/null 2>&1; then
        COMPOSE_CMD="docker compose"
    elif command -v docker-compose >/dev/null 2>&1; then
        COMPOSE_CMD="docker-compose"
    else
        echo "[ERROR] Docker Compose not found"
        exit 1
    fi
}
# Start containers
start_services() {
    local args=()
    if [ "$BUILD_FLAG" = true ]; then
        args+=("--build")
    fi
    if [ "$DETACH_FLAG" = true ]; then
        args+=("-d")
    fi
    echo "[INFO] Starting AuthVault BE and DB containers..."
    $COMPOSE_CMD -f "$COMPOSE_FILE" up "${args[@]}"
}
# Stop containers
stop_services() {
    echo "[INFO] Stopping containers..."
    $COMPOSE_CMD -f "$COMPOSE_FILE" stop
}
# Tear down containers
down_services() {
    local args=()
    if [ "$REMOVE_VOLUMES" = true ]; then
        args+=("-v")
    fi
    echo "[INFO] Stopping and removing containers..."
    $COMPOSE_CMD -f "$COMPOSE_FILE" down "${args[@]}"
}
# Restart containers
restart_services() {
    echo "[INFO] Restarting containers..."
    $COMPOSE_CMD -f "$COMPOSE_FILE" restart
}
# Tail logs
show_logs() {
    echo "[INFO] Streaming container logs..."
    $COMPOSE_CMD -f "$COMPOSE_FILE" logs -f
}
# Check container status
show_status() {
    echo "[INFO] Checking container status..."
    $COMPOSE_CMD -f "$COMPOSE_FILE" ps
}
# Parse command line flags
parse_arguments() {
    while [ $# -gt 0 ]; do
        case "$1" in
            -d|--detach)
                DETACH_FLAG=true
                shift
                ;;
            -b|--build)
                BUILD_FLAG=true
                shift
                ;;
            -s|--stop|stop)
                ACTION="stop"
                shift
                ;;
            --down|down)
                ACTION="down"
                shift
                ;;
            -v|--volumes)
                REMOVE_VOLUMES=true
                shift
                ;;
            -r|--restart|restart)
                ACTION="restart"
                shift
                ;;
            -l|--logs|logs)
                ACTION="logs"
                shift
                ;;
            -p|--ps|--status|ps|status)
                ACTION="status"
                shift
                ;;
            up)
                ACTION="up"
                shift
                ;;
            -h|--help|help)
                ACTION="help"
                shift
                ;;
            *)
                echo "[WARN] Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
}
# Execute target action
execute_action() {
    case "$ACTION" in
        up)
            start_services
            ;;
        stop)
            stop_services
            ;;
        down)
            down_services
            ;;
        restart)
            restart_services
            ;;
        logs)
            show_logs
            ;;
        status)
            show_status
            ;;
        help)
            show_help
            ;;
        *)
            start_services
            ;;
    esac
}
# Main execution workflow
resolve_compose_cmd
parse_arguments "$@"
execute_action
