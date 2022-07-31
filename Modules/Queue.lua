local Queue={};
local QueueMT={__index=Queue};
Queue.new=function()
  local self=setmetatable({},QueueMT);
  self.begin_i=1;
  self.end_i=0;
  return self;
end
function Queue:Push(v)
  self.end_i=self.end_i+1;
  self[self.end_i]=v;
end
function Queue:Pop(v)
  if self.begin_i>self.end_i then return nil; end
  local V=self[self.begin_i];
  self[self.begin_i]=nil; --Remove from queue.
  self.begin_i=self.begin_i+1;
  return V;
end
function Queue:Length()
  return self.end_i-self.begin_i+1;
end
function Queue:IsEmpty()
  return self.begin_i>self.end_i;
end
function Queue:CloneToTable() --To make indexing easier (1 to :Length()).
  local as_table={};
  for i=1,self:Length() do
    as_table[i]=self[self.begin_i+i-1];
  end
  return as_table;
end
return Queue;