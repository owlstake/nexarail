#!/usr/bin/env bash
# ------------------------------------------------------------------
# NexaRail Devnet Start Script
# Launches a local multi-validator devnet.
# ------------------------------------------------------------------
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
BUILD_DIR="$PROJECT_DIR/build"
BINARY="$BUILD_DIR/nexaraild"

HOME_DIR="$HOME/.nexarail"
CHAIN_ID="nexarail-devnet-1"
NUM_VALIDATORS=${1:-3}
START_PORT=${2:-26656}
RPC_PORT=${3:-26657}
API_PORT=${4:-1317}
GRPC_PORT=${5:-9090}

# Check if binary exists
if [[ ! -f "$BINARY" ]]; then
  echo "[ERROR] Binary not found. Run 'make build' first."
  exit 1
fi

# Check if devnet is initialised
if [[ ! -d "${HOME_DIR}/validator0" ]]; then
  echo "[ERROR] Devnet not initialised. Run 'make init-devnet' or 'bash scripts/init-devnet.sh' first."
  exit 1
fi

echo "========================================"
echo " Starting NexaRail Devnet"
echo " Validators: $NUM_VALIDATORS"
echo "========================================"

# Kill any existing nexaraild processes
echo "[cleanup] Killing existing nexaraild processes..."
pkill -f "${BINARY}" 2>/dev/null || true
sleep 1

# Create log directory
mkdir -p "${HOME_DIR}/logs"

# Start each validator
VALIDATOR_PIDS=()
for i in $(seq 0 $((NUM_VALIDATORS - 1))); do
  VAL_HOME="${HOME_DIR}/validator${i}"
  LOG_FILE="${HOME_DIR}/logs/validator${i}.log"

  # Only validator0 runs RPC, API, and gRPC endpoints
  if [[ $i -eq 0 ]]; then
    CMD="$BINARY start \
      --home $VAL_HOME \
      --rpc.laddr tcp://127.0.0.1:${RPC_PORT} \
      --api.address tcp://127.0.0.1:${API_PORT} \
      --grpc.address 127.0.0.1:${GRPC_PORT} \
      --p2p.laddr tcp://127.0.0.1:${START_PORT} \
      --log_format json \
      --minimum-gas-prices 0.025unxrl"
  else
    # Additional validators connect to validator0
    VAL0_NODE_ID=$(HOME=${HOME_DIR}/validator0 $BINARY tendermint show-node-id 2>/dev/null || echo "unknown")
    PEER="tcp://${VAL0_NODE_ID}@127.0.0.1:${START_PORT}"
    CMD="$BINARY start \
      --home $VAL_HOME \
      --rpc.laddr tcp://127.0.0.1:$((RPC_PORT + i)) \
      --p2p.laddr tcp://127.0.0.1:$((START_PORT + i)) \
      --p2p.persistent_peers $PEER \
      --log_format json \
      --minimum-gas-prices 0.025unxrl"
  fi

  echo "[start] Validator $i (PID logging to ${LOG_FILE})"
  eval "$CMD" > "$LOG_FILE" 2>&1 &
  VALIDATOR_PIDS+=($!)
  sleep 1
done

echo ""
echo "========================================"
echo " Devnet is running!"
echo " RPC:      http://127.0.0.1:${RPC_PORT}"
echo " API:      http://127.0.0.1:${API_PORT}"
echo " gRPC:     127.0.0.1:${GRPC_PORT}"
echo " Validator PIDs: ${VALIDATOR_PIDS[*]}"
echo ""
echo " Common commands:"
echo "  Check status:   curl http://127.0.0.1:${RPC_PORT}/status"
echo "  Query balance:  ${BINARY} query bank balances <address>"
echo "  Send tx:        ${BINARY} tx bank send <from> <to> <amount>"
echo "  View logs:      tail -f ${HOME_DIR}/logs/validator0.log"
echo ""
echo " To stop:         pkill -f ${BINARY}"
echo "========================================"

# Wait for any child to exit (if one dies, we stop)
wait -n 2>/dev/null || true
echo "[WARN] A validator process exited. Stopping devnet..."
for pid in "${VALIDATOR_PIDS[@]}"; do
  kill "$pid" 2>/dev/null || true
done
