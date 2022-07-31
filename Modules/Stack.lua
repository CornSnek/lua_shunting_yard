local Stack={};
local StackMT={__index=Stack};
Stack.new=function()
  return setmetatable({},StackMT);
end
function Stack:Push(value)
  self[#self+1]=value;
end
function Stack:Pop()
  local v=self[#self];
  self[#self]=nil;
  return v;
end
function Stack:IsEmpty()
  return #self==0;
end

function Stack:ChangeHead(to_value)
  assert(#self>0,"Stack is empty. Can't change head.");
  self[#self]=to_value;
end
function Stack:Peek() --Don't pop.
  return self[#self];
end
function Stack:Length()
  return #self;
end
return Stack;