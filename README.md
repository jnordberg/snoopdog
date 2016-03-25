# snoopdog

Super simple tracking pixels backed by leveldb.

## Usage

Embed in your emails somehow, you probably want something that generates id's for you.

```html
<img src="http://snooplion/t.gif?id=foobar123" width="0" height="0">
```

## API

### Track request

```
GET /t.gif?id=<tracking_id>
```

*tracking_id* required, string /[a-z0-9_]+/i

--

### Lookup a tracking id

```
GET /tracked?id=<tracking_id>
```

Response is JSON

```json
{
    "hits": [
        {
            "remoteAddr": "1.2.3.4",
            "time": 1458918462442,
            "userAgent": "Thunderman/1.2.3 (Amiga OS; 2) DogKit/1123.22"
        }
    ],
    "id": "foobar"
}
```

### Nuke a tracking id

```
DELETE /tracked?id=<tracking_id>
```

Responds with 200 (even if the id didn't exist)


## License

MIT
