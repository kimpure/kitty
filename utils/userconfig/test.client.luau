local test = require'utils/userconfig/test'

test().setting1 = "changed"
test:saveChangesToServer()
