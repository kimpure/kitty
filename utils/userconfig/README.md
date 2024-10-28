# UserConfig
유저 설정을 관리하는 라이브러리

## 특징
- 설정 정보는 데이터스토어와 연동됨
- 변경된 값만 서버에 전송하여 저장함
- 클라이언트 정보를 신뢰함 (서버에서 스키마 검사는 진행함)
- 압축 기능 포함
- 타입 체크, 자동완성을 지원함

## 사용 예시
configs.luau
```luau
local userconfig = require 'path to'
return userconfig.new({ apple='사과', banana='바나나' }, '과일이름')
```

client.luau
```luau
configs.values.apple = '바나나'
configs.values.banana = '오렌지'
configs:saveChangesToServer()
```

server.luau
```luau
configs:getChanges(function(data, player)
	print(`apple: {data.apple}, banana: {data.banana}`)
	userconfig:saveChanges(player)
end)
```

## TODO
- 기초 구현
