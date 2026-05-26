## Description
<!-- What does this PR do? -->

## Type of change
- [ ] Bug fix
- [ ] New feature (requires prior approval)
- [ ] Documentation
- [ ] Test addition / improvement
- [ ] Script or tooling
- [ ] Testnet preparation

## Protocol Change Checklist
<!-- Only if this PR modifies protocol behaviour -->
- [ ] All existing tests pass locally
- [ ] New tests added for changed behaviour
- [ ] Docs updated (module docs, design docs, LIMITATIONS.md)
- [ ] Security impact assessed (bank transfers, invariants, permissions)
- [ ] Live flags remain default false (if adding new flag)
- [ ] No new module accounts without security review
- [ ] No mainnet-only changes — testnet compatible

## Verification
<!-- Commands run to verify -->
```
go mod tidy && go mod verify
go build ./...
go vet ./...
go test ./...
```

## Additional notes
<!-- Any context for reviewers -->
