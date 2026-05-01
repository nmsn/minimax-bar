# DeepSeek API Documentation

## Get User Balance

查询用户余额信息。

### Request

```bash
curl -L -X GET 'https://api.deepseek.com/user/balance' \
  -H 'Accept: application/json' \
  -H 'Authorization: Bearer <TOKEN>'
```

### Response

#### Success (200)

```json
{
  "is_available": true,
  "balance_infos": [
    {
      "currency": "CNY",
      "total_balance": "3.77",
      "granted_balance": "0.00",
      "topped_up_balance": "3.77"
    }
  ]
}
```

| Field | Type | Description |
|-------|------|-------------|
| `is_available` | boolean | 账户是否可用 |
| `balance_infos` | array | 余额信息列表 |
| `balance_infos[].currency` | string | 货币类型（如 CNY, USD） |
| `balance_infos[].total_balance` | string | 总余额 |
| `balance_infos[].granted_balance` | string | 赠送余额 |
| `balance_infos[].topped_up_balance` | string | 充值余额 |

#### Unauthorized (401)

```json
{
  "error": {
    "message": "Authentication Fails, Your api key: ****KEN> is invalid",
    "type": "authentication_error",
    "param": null,
    "code": "invalid_request_error"
  }
}
```

### Notes

- Balance values are returned as strings, need to convert to Double for display
- `is_available` indicates whether the account is active
- Multiple currency balances may be returned in `balance_infos` array
