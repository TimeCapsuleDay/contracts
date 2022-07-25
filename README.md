# TimeCapsule Foundry Project

### Build:

```
forge build
```

### Test:

```
forge test
```

### Send TimeCapsule Token to BitTorrent Blockchain:

```
forge create \
    --rpc-url "https://pre-rpc.bt.io" \
    --private-key "PRIVATE_KEY" \
    src/TimeCapsule.sol:TimeToken \
    --legacy
```

### Send TimeCapsule to BitTorrent Blockchain:

```
forge create \
    --rpc-url "https://pre-rpc.bt.io" \
    --private-key "PRIVATE_KEY" \
    src/TimeCapsule.sol:TimeCapsule \
    --legacy
```

### Send Multicall to BitTorrent Blockchain:

```
forge create \
    --rpc-url "https://pre-rpc.bt.io" \
    --private-key "PRIVATE_KEY" \
    src/Multicall.sol:Multicall \
    --legacy
```
