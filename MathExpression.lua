local Stack=require("Modules/Stack");
local Queue=require("Modules/Queue");
local MathExp={}; --Infix to RPN Expression, and solving the RPN.
local VariablePointer;
local VariableCache=setmetatable(
  {
    ["+"]=function(t1,t2) return t1+t2 end;
    ["-"]=function(t1,t2) return t1-t2 end;
    ["*"]=function(t1,t2) return t1*t2 end;
    ["/"]=function(t1,t2) return t1/t2 end;
    ["%"]=function(t1,t2) return t1%t2 end;
    ["^"]=function(t1,t2) return t1^t2 end;
  },
  {
    __index=function(var_cache,k)
      if VariablePointer[k] then --To point at custom variables/functions.
        return VariablePointer[k];
      end
      if math[k] then --math functions in table to be called later.
        var_cache[k]=math[k];
        return math[k];
      end
      error("Unknown variable: "..tostring(k));
    end
  }
);
local OperatorPrecedence=setmetatable({
  ["^"]={prec=4,is_left=false};
  ["*"]={prec=3,is_left=true};
  ["/"]={prec=3,is_left=true};
  ["%"]={prec=3,is_left=true};
  ["+"]={prec=2,is_left=true};
  ["-"]={prec=2,is_left=true};
  [","]={prec=1,is_left=true};
},{__index=function(op,k) error("Invalid operator token: "..tostring(k)) end});
local MathExpMT={__index=MathExp};
MathExp.new=function(math_str,variables_table)
  local self=setmetatable({},MathExpMT);
  self.Variables=variables_table or {};
  self.MathStr=math_str;
  self.read_i=1;
  --self.OutputRPN=nil;
  --self.OperatorStack=nil;
  print(string.format("Evaluating '%s'",math_str))
  self:ToRPN();
  return self;
end
function MathExp:ToRPN() --Doing Shunting-yard algorithm.
  self.OutputRPN=Queue.new();
  local StrLength=#self.MathStr;
  self.OperatorStack=Stack.new();
  local OperatorStack=self.OperatorStack;
  local IsTokenOperator=false;
  while self.read_i<=StrLength do
    print("--Reading '"..string.sub(self.MathStr,self.read_i,self.read_i).."' at index #"..self.read_i.."--","Going to "..(IsTokenOperator and "_IsOperatorBranch" or "_NotOperatorBranch"));
    if not IsTokenOperator then
      IsTokenOperator=self:_NotOperatorBranch();
    else
      IsTokenOperator=self:_IsOperatorBranch();
    end
    self:_SeeOperatorStackandRPN();
  end
  print("--Finished reading math string. Now popping Operators onto the OutputRPN.--");
  while not OperatorStack:IsEmpty() do --Push remaining operators.
    local operator=OperatorStack:Pop();
    if operator=="(" then
      error("Right parenthesis missing.");
    end
    self.OutputRPN:Push(operator);
  end
  self:_SeeOperatorStackandRPN();
  self.OperatorStack=nil;
end
function MathExp:_AddReadIBy(this_many) --Temporary.
  self.read_i=self.read_i+this_many;
end
function MathExp:_SeeOperatorStackandRPN()
  print("OperatorStack","{"..table.concat(self.OperatorStack,"|").."}");
  print("OutputRPN","{"..table.concat(self.OutputRPN,"|",self.OutputRPN.begin_i,self.OutputRPN.end_i).."}");
end
function MathExp:_NotOperatorBranch()
  local string_number=string.match(self.MathStr,"^%-?%d+%.?%d*",self.read_i);
  if string_number then --Includes decimal points with unary '-'.
    self:_AddReadIBy(#string_number);
    self.OutputRPN:Push(string_number);
    return true; --To _IsOperatorBranch.
  end
  local string_variable=string.match(self.MathStr,"^[%a_][%w_]*",self.read_i);
  
  if string_variable then
    if string.match(self.MathStr,"^[%a_][%w_]*%(",self.read_i) then --If function (Ex: "sin("). Allows lua naming convention (Ex: _This_1_isafunction(1,2,3)).
      self:_AddReadIBy(#string_variable+1); --Include "(" in count.
      self.OperatorStack:Push("(");
      self.OperatorStack:Push(string_variable); --Push variable as function in stack instead.
      return false;
    else
      self:_AddReadIBy(#string_variable);
      self.OutputRPN:Push(string_variable);
      return true;
    end
  end
  local OtherToken=string.sub(self.MathStr,self.read_i,self.read_i);
  if string.match(self.MathStr,"^[%(%)]",self.read_i) then
    return self:_IsParenthesisBranch(OtherToken);
  elseif OtherToken=="-" then --If unary "-", push -1 to output and * to stack.
    self:_AddReadIBy(1);
    self.OutputRPN:Push("-1");
    self:_AddOperatorTokenToStack("*");
    return false;
  end
  error("Operator needed.");
end
function MathExp:_IsParenthesisBranch(other_token) --Shares _NotOperatorBranch and _IsOperatorBranch.
  if other_token=="(" then
    self:_AddReadIBy(1);
    self.OperatorStack:Push("(");
    return false;
  else
    self:_AddReadIBy(1);
    while true do
      local operator_token=self.OperatorStack:Pop();
      if operator_token=="(" then
        break;
      elseif not operator_token then
        error("Left parenthesis missing.");
      end
      self.OutputRPN:Push(operator_token);
    end
    return true; --Expect operator next.
  end
end
function MathExp:_AddOperatorTokenToStack(new_operator)
  local old_operator=self.OperatorStack:Peek();
  if old_operator and string.match(old_operator,"^[%^%+%-%*/%%,]") then --Exclude custom functions and "(".
    local old_operator_p=OperatorPrecedence[old_operator];
    local new_operator_p=OperatorPrecedence[new_operator];
    if new_operator_p.is_left then
      if new_operator_p.prec<=old_operator_p.prec then
        self.OutputRPN:Push(self.OperatorStack:Pop()); --Pop old_operator and push into OutputRPN queue.
      end
    else
      if new_operator_p.prec<old_operator_p.prec then
        self.OutputRPN:Push(self.OperatorStack:Pop());
      end
    end
  end
  self.OperatorStack:Push(new_operator);
end
function MathExp:_IsOperatorBranch()
  local operator=string.match(self.MathStr,"^[%^%+%-%*/%%,]",self.read_i);
  if operator then
    self:_AddReadIBy(1);
    self:_AddOperatorTokenToStack(operator);
  else
    local OtherToken=string.sub(self.MathStr,self.read_i,self.read_i);
    if string.match(self.MathStr,"^[%(%)]",self.read_i) then
      return self:_IsParenthesisBranch(OtherToken);
    else
      error("Operand needed.");
    end
  end
  return false;
end
function MathExp:Evaluate()
  VariablePointer=self.Variables;
  local NumberStack=Stack.new();
  local RPNClone=self.OutputRPN:CloneToTable();
  local CustomArgumentsCount=1;
  for i=1,#RPNClone do
    local Token=RPNClone[i];
    print("Reading","'"..Token.."'");
    if string.match(Token,"%-?%d+%.?%d*") then
      NumberStack:Push(tonumber(Token)); --String to number.
    elseif string.match(Token,"^[%^%+%-%*/%%]") then --Binary functions.
      local n2,n1=NumberStack:Pop(),NumberStack:Pop(); --Popping backwards.
      local Result=VariableCache[Token](n1,n2);
      NumberStack:Push(Result); --Push as it is already number.
    elseif Token=="," then
      CustomArgumentsCount=CustomArgumentsCount+1;
    else
      local CustomVariable=VariableCache[Token];
      if type(CustomVariable)=="number" then
        NumberStack:Push(tonumber(CustomVariable));
      else
        local CustomArgumentsTable={};
        for i=CustomArgumentsCount,1,-1 do --Popping backwards.
          CustomArgumentsTable[i]=NumberStack:Pop();
        end
        NumberStack:Push(CustomVariable(table.unpack(CustomArgumentsTable)));
        CustomArgumentsCount=1; --Reset count.
      end
    end
    print(table.concat(NumberStack,","));
  end
  return NumberStack;
end
local maths=MathExp.new("f(1,f(2,f(3,4*f(8,-9,10),5),6%7),-a)",{f=function(x,y,z) return x+y*z end,a=20});
maths:Evaluate();
