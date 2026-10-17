#!/bin/bash
#
# Script starts an rstp stream from KD110 doorbell
# provide login details

# Default values
DEFAULT_ID="admin"
DEFAULT_LOGIN="admin"
DEFAULT_STREAMFILE="/mnt/pve-sata-ssd/ssd-data/nvr/tplink/doorbell/kd110.mp4"
DEFAULT_IP="192.168.4.19"
DEFAULT_PORT="19443"

# Initialize variables with defaults
ID="${DEFAULT_ID}"
LOGIN="${DEFAULT_LOGIN}"
STREAMFILE="${DEFAULT_STREAMFILE}"
IP="${DEFAULT_IP}"
PORT="${DEFAULT_PORT}"

# Usage function
usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Options:
    -i, --id USERNAME        Username for authentication (default: ${DEFAULT_ID})
    -l, --login PASSWORD    Password for authentication (default: ${DEFAULT_LOGIN})
    -f, --file PATH         Output file path (default: ${DEFAULT_STREAMFILE})
    -a, --address IP        Doorbell IP address (default: ${DEFAULT_IP})
    -p, --port PORT         Doorbell port (default: ${DEFAULT_PORT})
    -h, --help             Show this help message

Examples:
    $0                                    # Use all defaults
    $0 -a 192.168.1.100 -p 8080           # Override IP and port
    $0 -f /tmp/stream.mp4 -i user -l pass # Override file, username, and password
EOF
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -i|--id)
            ID="$2"
            shift 2
            ;;
        -l|--login)
            LOGIN="$2"
            shift 2
            ;;
        -f|--file)
            STREAMFILE="$2"
            shift 2
            ;;
        -a|--address)
            IP="$2"
            shift 2
            ;;
        -p|--port)
            PORT="$2"
            shift 2
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            usage
            exit 1
            ;;
    esac
done

# Validate required parameters
if [[ -z "$ID" || -z "$LOGIN" || -z "$STREAMFILE" || -z "$IP" || -z "$PORT" ]]; then
    echo "Error: All parameters must be provided"
    usage
    exit 1
fi

# Create output directory if it doesn't exist
output_dir=$(dirname "$STREAMFILE")
if [[ ! -d "$output_dir" ]]; then
    echo "Creating output directory: $output_dir"
    mkdir -p "$output_dir"
fi

echo "Starting KD110 stream with parameters:"
echo "  Username: $ID"
echo "  IP Address: $IP"
echo "  Port: $PORT"
echo "  Output File: $STREAMFILE"
echo ""

curl -vv -k -u "${ID}":"${LOGIN}" "https://${IP}:${PORT}/https/stream/mixed?video=h264&audio=g711&resolution=hd&deviceId=CAFEDEADBEAFCAFEDEADBEAFCAFEDEADBEAFCAFE" --ignore-content-length --output - | ffmpeg -y -i - "${STREAMFILE}"
