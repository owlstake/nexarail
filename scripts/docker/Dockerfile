FROM golang:1.22-alpine AS builder

RUN apk add --no-cache git make gcc musl-dev

WORKDIR /workspace
COPY go.mod go.sum ./
RUN go mod download

COPY . .
# Build natively for the current architecture (no cross-compile)
RUN CGO_ENABLED=0 go build -mod=readonly \
    -ldflags '-X github.com/cosmos/cosmos-sdk/version.Name=nexarail -X github.com/cosmos/cosmos-sdk/version.AppName=nexaraild -X github.com/cosmos/cosmos-sdk/version.Version=0.1.0-dev -X github.com/cosmos/cosmos-sdk/version.Commit=dev' \
    -o /workspace/build/nexaraild ./cmd/nexaraild

FROM alpine:3.19

RUN apk add --no-cache ca-certificates curl jq

COPY --from=builder /workspace/build/nexaraild /usr/local/bin/nexaraild

EXPOSE 26656 26657 1317 9090

ENTRYPOINT ["nexaraild"]
CMD ["start"]
