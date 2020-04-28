local srcFiles = {
"/startup",
"/server",
"/license.txt",
"/win/win",
"/win/startup.ini",
"/win/apis/cmndlg",
"/win/apis/html",
"/win/apps/notepad",
"/win/apps/notepad.ini",
"/win/apps/fexplore",
"/win/apps/fexplore.asc",
"/win/apps/browse",
"/win/apps/browse.ini",
"/win/apps/chat",
"/win/apps/shutdown",
"/win/apps/manager",
"/win/apps/email",
"/win/apps/email.ini",
"/win/apps/emread",
"/win/apps/emwrite",
"/win/apps/sadmin",
"/win/apps/sadmin.ini",
"/win/apps/cmd",
"/win/term/desktop.ini",
"/win/term/startup.ini",
"/templates/minApp",
"/templates/starter",
"/templates/single",
"/templates/menu",
"/templates/popup"
}
local srcData = {
"--SERVER_ROOT = \"/public\"\
--SERVER_PORT = 80\
--SERVER_NETWORK = \"wide_area_network\"\
--SERVER_WIRELESS = true\
--SERVER_TIMEOUT = 5\
--SERVER_PASSWORD = \"admin\"\
--ACCOUNTS_ROOT = \"/accounts\"\
--shell.run(\"/server\")\
os.loadAPI(\"/win/win\")\
if not win.startWin(shell) then\
   os.unloadAPI(\"/win/win\")\
end\
",
"local function iif(condition,trueValue,falseValue)\
if condition then\
return trueValue\
end\
return falseValue\
end\
local function syslog(entry)\
local file=fs.open(\"/server.log\",iif(fs.exists(\"/server.log\"),\"a\",\"w\"))\
if file then\
file.write(entry..\"\\n\\n\")\
file.close()\
end\
end\
local function printMsg(msg)\
if win then\
if win.syslog then\
syslog(msg)\
return\
end\
end\
print(msg)\
end\
if SERVER_VERSION then\
printMsg(\"Server already running\")\
return\
end\
SERVER_VERSION=1.0\
if not SERVER_ROOT then\
SERVER_ROOT=\"/public\"\
end\
if not SERVER_PORT then\
SERVER_PORT=80\
end\
if not SERVER_NETWORK then\
SERVER_NETWORK=\"wide_area_network\"\
end\
if SERVER_WIRELESS==nil then\
SERVER_WIRELESS=true\
end\
if not SERVER_TIMEOUT then\
SERVER_TIMEOUT=5\
end\
if not SERVER_PASSWORD then\
SERVER_PASSWORD=\"admin\"\
end\
if not ACCOUNTS_ROOT then\
ACCOUNTS_ROOT=\"/accounts\"\
end\
local COMMTIME=0.3\
local commTimer=nil\
local commTime=os.clock()\
local os_pullEventRaw=os.pullEventRaw\
local function asnumber(v,defV)\
return tonumber(v)or(tonumber(defV or 0)or 0)\
end\
local function asstring(v,defV)\
return tostring(v or(tostring(defV or \"\")))..\"\"\
end\
local function findModem(wireless)\
return peripheral.find(\
\"modem\",\
function(name,obj)\
return iif(wireless,obj.isWireless(),\
iif(wireless==false,\
not obj.isWireless(),\
true))\
end)\
end\
local timeStamp=0\
local function startTime()\
timeStamp=os.clock()\
end\
local function checkTime()\
if(os.clock()-timeStamp)>=5 then\
sleep(0.05)\
timeStamp=os.clock()\
return true\
end\
return false\
end\
local function readBinaryFile(path)\
local strFile=\"\"\
local hFile=fs.open(path,\"rb\")\
if not hFile then\
return nil\
end\
startTime()\
local nSrc=hFile.read()\
while nSrc do\
local tChars={}\
while nSrc and #tChars<200 do\
tChars[#tChars+1]=nSrc\
nSrc=hFile.read()\
end\
strFile=strFile..string.char(unpack(tChars))\
checkTime()\
end\
hFile.close()\
return strFile\
end\
local __classBase={}\
function __classBase:constructor(...)\
return self\
end\
function __classBase:new(...)\
local obj={}\
setmetatable(obj,self)\
self.__index=self\
return obj:constructor(...)\
end\
function __classBase:base()\
local obj={}\
setmetatable(obj,self)\
self.__index=self\
return obj\
end\
local comm=__classBase:base()\
function comm:constructor(name,wireless,port,timeout,relay)\
self.comm__name=name\
self.comm__wireless=wireless\
self.comm__port=port or 10\
self.comm__timeout=timeout or 10\
self.comm__relay=relay==true\
self.comm__interests={}\
self.comm__processing={}\
return self\
end\
function comm:getName()\
return self.comm__name\
end\
function comm:setName(name)\
self.comm__name=name\
end\
function comm:getPort()\
return self.comm__port\
end\
function comm:setPort(port)\
self.comm__port=port or 10\
end\
function comm:getTimeout()\
return self.comm__timeout\
end\
function comm:setTimeout(timeout)\
self.comm__timeout=timeout or 10\
end\
function comm:getRelay()\
return self.comm__relay\
end\
function comm:setRelay(relay)\
self.comm__relay=relay==true\
end\
function comm:getWireless()\
return self.comm__wireless\
end\
function comm:setWireless(wireless)\
self.comm__wireless=wireless\
end\
function comm:modem()\
return findModem(self.comm__wireless)\
end\
function comm:connect()\
local modem=self:modem()\
if modem then\
modem.open(self:getPort())\
return true\
end\
return false\
end\
function comm:disconnect()\
local modem=self:modem()\
if modem then\
modem.close(self:getPort())\
end\
end\
function comm:ready()\
local modem=self:modem()\
if modem then\
if modem.isOpen(self:getPort())then\
return modem\
end\
end\
return nil\
end\
function comm:transmit(message)\
local modem=self:ready()\
if modem then\
modem.transmit(self:getPort(),self:getPort(),message)\
return true\
end\
return false\
end\
function comm:register(group,application,receive,sent)\
self.comm__interests[#self.comm__interests+1]=\
{\
application=application,\
receive=receive,\
sent=sent,\
group=group\
}\
end\
function comm:unregister(group,application,receive,sent)\
for i=#self.comm__interests,1,-1 do\
local interest=self.comm__interests[i]\
if interest.group==group and\
(interest.application==application or not application)and\
(interest.receive==receive or not receive)and\
(interest.sent==sent or not sent)then\
table.remove(self.comm__interests,i)\
end\
end\
end\
function comm:copyMsg(msg)\
return textutils.unserialize(textutils.serialize(msg))\
end\
function comm:callSentHandlers(msg,result)\
for i=1,#self.comm__interests,1 do\
if self.comm__interests[i].application==msg.application then\
local success,err=pcall(self.comm__interests[i].sent,msg,result)\
if not success then\
syslog(\"comm \"..self:getName()..\" call to sent handler failed: \"..tostring(err))\
end\
end\
end\
end\
function comm:isDuplicate(msg)\
for i=1,#self.comm__processing,1 do\
local process=self.comm__processing[i]\
if process.msg.messageId==msg.messageId then\
if process.status==\"received\" or\
(process.status==\"relay\" and\
process.msg.sequence==msg.sequence)then\
return true\
end\
end\
end\
return false\
end\
function comm:isConfirmation(msg)\
if msg.context==\"confirm\" then\
for i=#self.comm__processing,1,-1 do\
local process=self.comm__processing[i]\
if process.status==\"send\" then\
if process.msg.messageId==msg.messageId then\
self:callSentHandlers(process.msg,true)\
table.remove(self.comm__processing,i)\
end\
end\
end\
return true\
end\
return false\
end\
function comm:isFromMe(msg)\
return(asnumber(msg.senderId)==os.getComputerID()or\
asstring(msg.senderName)==os.getComputerLabel())\
end\
function comm:isForMe(msg,exclusive)\
if msg.recipientId then\
return asnumber(msg.recipientId)==os.getComputerID()\
elseif msg.recipientName then\
return asstring(msg.recipientName)==os.getComputerLabel()\
elseif exclusive then\
return false\
end\
return(not self:isFromMe(msg))\
end\
function comm:callReceiveHandlers(msg,modemSide,senderChannel,replyChannel,distance)\
local received=false\
local copy=self:copyMsg(msg)\
copy.modemSide=modemSide\
copy.senderChannel=senderChannel\
copy.replyChannel=replyChannel\
copy.distance=distance\
for i=1,#self.comm__interests,1 do\
if self.comm__interests[i].application==msg.application then\
local success,result=pcall(self.comm__interests[i].receive,copy)\
if not success then\
syslog(\"comm \"..self:getName()..\" call to receive handler failed: \"..tostring(result))\
else\
received=result\
end\
end\
end\
return received\
end\
function comm:sendConfirmation(msg)\
if msg.recipientName or msg.recipientId then\
local copy=self:copyMsg(msg)\
copy.context=\"confirm\"\
copy.recipientName=copy.senderName\
copy.recipientId=copy.senderId\
copy.senderName=os.getComputerLabel()\
copy.senderId=os.getComputerID()\
copy.sequence=-1\
if not self:transmit(textutils.serialize(copy))then\
syslog(\"comm \"..self:getName()..\" no modem for confirmation to \"..asstring(msg.senderName))\
end\
end\
end\
function comm:receive(modemSide,senderChannel,replyChannel,message,distance)\
if senderChannel==self:getPort()then\
local success,msg=pcall(textutils.unserialize,message)\
if success and type(msg)==\"table\" then\
if msg.messageId and msg.application and msg.context then\
if self:isForMe(msg)then\
if not self:isConfirmation(msg)then\
if not self:isDuplicate(msg)then\
if self:callReceiveHandlers(msg,modemSide,senderChannel,replyChannel,distance)then\
self.comm__processing[#self.comm__processing+1]=\
{\
timeStamp=os.clock(),\
status=\"received\",\
msg=msg\
}\
self:sendConfirmation(msg)\
end\
end\
end\
end\
if self:getRelay()then\
if not self:isFromMe(msg)and not self:isForMe(msg,true)then\
if not self:isDuplicate(msg)then\
if not self:transmit(message)then\
syslog(\"comm \"..self:getName()..\" no modem to relay message\")\
end\
self.comm__processing[#self.comm__processing+1]=\
{\
timeStamp=os.clock(),\
status=\"relay\",\
msg=msg\
}\
end\
end\
end\
end\
end\
end\
end\
function comm:send(recipient,application,context,data)\
local msg={}\
local method=\"send\"\
if recipient then\
if type(recipient)==\"number\" then\
msg.recipientId=recipient\
if msg.recipientId==os.getComputerID()then\
return\
end\
else\
msg.recipientName=asstring(recipient)\
if msg.recipientName==os.getComputerLabel()then\
return\
end\
end\
else\
method=\"broadcast\"\
end\
msg.context=context\
msg.application=application\
msg.data=data\
msg.senderId=os.getComputerID()\
msg.senderName=os.getComputerLabel()\
msg.messageId=math.random(1,65535)\
msg.sequence=0\
self.comm__processing[#self.comm__processing+1]=\
{\
timeStamp=os.clock(),\
status=method,\
msg=msg\
}\
return msg.messageId\
end\
function comm:process()\
for i=#self.comm__processing,1,-1 do\
local process=self.comm__processing[i]\
if process.status==\"received\" or process.status==\"relay\" then\
if(os.clock()-process.timeStamp)>(self:getTimeout()*2)then\
table.remove(self.comm__processing,i)\
end\
elseif process.status==\"send\" or process.status==\"broadcast\" then\
if(os.clock()-process.timeStamp)>self:getTimeout()then\
if process.status==\"send\" then\
self:callSentHandlers(process.msg,false)\
end\
table.remove(self.comm__processing,i)\
else\
process.msg.sequence=process.msg.sequence+1\
if self:transmit(textutils.serialize(process.msg))then\
if process.status==\"broadcast\" then\
if process.msg.sequence==1 then\
self:callSentHandlers(process.msg,true)\
end\
end\
else\
syslog(\"comm \"..self:getName()..\" no modem to send message\")\
end\
end\
end\
end\
end\
local connection=comm:new(\"server\",SERVER_WIRELESS,SERVER_PORT,SERVER_TIMEOUT,SERVER_WIRELESS)\
if not connection:connect()then\
printMsg(\"Server could not connect\")\
return\
end\
local function fileNotFound(path)\
return string.format(\"\\nFile \\\"%s\\\" not found!\\n\\nEnsure the path is entered correctly.\",path)\
end\
local function accountFolder(account)\
return ACCOUNTS_ROOT..\"/\"..account\
end\
local function readAccount(account)\
local data=nil\
local file=fs.open(accountFolder(account)..\"/account.dat\",\"r\")\
if file then\
data=textutils.unserialize(file.readAll())\
file.close()\
end\
return data\
end\
local function saveAccount(account,data)\
local file=fs.open(accountFolder(account)..\"/account.dat\",\"w\")\
if file then\
file.write(textutils.serialize(data))\
file.close()\
return true\
end\
return false\
end\
local function validatePassword(account,password)\
local data=readAccount(account)\
if data then\
return data.password==password\
end\
return false\
end\
function setAccountPassword(account,password)\
local data=readAccount(account)\
if data then\
data.password=password\
return saveAccount(account,data)\
end\
return false\
end\
function createAccount(account,password)\
if not fs.isDir(accountFolder(account))then\
if(pcall(fs.makeDir,accountFolder(account)))and\
(pcall(fs.makeDir,accountFolder(account)..\"/emails\"))then\
local data={\
password=tostring(password or \"1234\")\
}\
return saveAccount(account,data)\
end\
end\
return false\
end\
function deleteAccount(account)\
if fs.exists(accountFolder(account))and\
fs.isDir(accountFolder(account))then\
pcall(fs.delete,accountFolder(account))\
return not fs.exists(accountFolder(account))\
end\
return false\
end\
local function readEmail(account,name)\
local data=nil\
local file=fs.open(accountFolder(account)..\"/emails/\"..name,\"r\")\
if file then\
data=textutils.unserialize(file.readAll())\
file.close()\
end\
return data\
end\
local function saveEmail(account,email)\
local name=accountFolder(account)..\"/emails/email\"..\
tostring(math.random(1,65535))\
local file=fs.open(name,\"w\")\
if file then\
file.write(textutils.serialize(email))\
file.close()\
return true\
end\
return false\
end\
local function deleteEmail(account,name)\
pcall(fs.delete,accountFolder(account)..\"/emails/\"..name)\
end\
local function listEmails(account)\
local success,files=pcall(fs.list,accountFolder(account)..\"/emails\")\
if success then\
for i=#files,1,-1 do\
if files[i]:sub(1,5)~=\"email\" then\
table.remove(files,i)\
end\
end\
return files\
end\
return nil\
end\
local function requestType(msg)\
if(msg.recipientId or msg.recipientName)and\
type(msg.data)==\"table\" then\
if msg.context==\"http_request\" or\
msg.context==\"ftp_request\" then\
if msg.data.path and msg.data.application then\
return \"file_request\"\
end\
elseif msg.context==\"email_request\" then\
if msg.data.account and msg.data.password and\
msg.data.application and\
fs.isDir(accountFolder(msg.data.account))then\
return msg.context\
end\
elseif msg.context==\"email_delete\" then\
if msg.data.account and msg.data.password and\
msg.data.id and\
fs.isDir(accountFolder(msg.data.account))then\
return msg.context\
end\
elseif msg.context==\"account_password\" then\
if msg.data.account and msg.data.password and\
msg.data.newPassword and\
fs.isDir(accountFolder(msg.data.account))then\
return msg.context\
end\
elseif msg.context==\"email_send\" then\
if msg.data.account and type(msg.data.email)==\"table\" and\
fs.isDir(accountFolder(msg.data.account))then\
if msg.data.email.recipient and msg.data.email.sender and\
msg.data.email.message then\
return msg.context\
end\
end\
elseif msg.context==\"create_account\" then\
if msg.data.account and msg.data.password then\
return msg.context\
end\
elseif msg.context==\"delete_account\" then\
if msg.data.account and msg.data.password then\
return msg.context\
end\
elseif msg.context==\"reset_password\" then\
if msg.data.account and msg.data.password then\
return msg.context\
end\
elseif msg.context==\"file_upload\" then\
if msg.data.path and msg.data.content and msg.data.password then\
return msg.context\
end\
elseif msg.context==\"file_delete\" then\
if msg.data.path and msg.data.password then\
return msg.context\
end\
elseif msg.context==\"listing_request\" then\
if msg.data.path and msg.data.application and\
msg.data.password then\
return msg.context\
end\
elseif msg.context==\"directory_create\" then\
if msg.data.path and msg.data.password then\
return msg.context\
end\
end\
end\
return \"\"\
end\
local function onFileRequest(msg)\
local path=tostring(msg.data.path or \"\")\
local context=\"http_response\"\
if msg.context==\"ftp_request\" then\
context=\"ftp_response\"\
end\
if string.sub(path,1,1)~=\"/\" then\
path=\"/\"..path\
end\
if string.sub(path,-1,-1)~=\"/\" then\
if fs.isDir(SERVER_ROOT..path)then\
path=path..\"/\"\
end\
end\
if string.sub(path,-1,-1)==\"/\" then\
if fs.exists(SERVER_ROOT..path..\"index.html\")then\
path=path..\"index.html\"\
elseif fs.exists(SERVER_ROOT..path..\"index.htm\")then\
path=path..\"index.htm\"\
elseif fs.exists(SERVER_ROOT..path..\"index.txt\")then\
path=path..\"index.txt\"\
end\
end\
local localPath=SERVER_ROOT..path\
local domainPath=asstring(os.getComputerLabel())..path\
local data={path=domainPath}\
data.content=readBinaryFile(localPath)\
if not data.content then\
if context==\"ftp_response\" then\
return false\
end\
data.content=fileNotFound(domainPath)\
end\
connection:send(msg.senderId or msg.senderName,\
msg.data.application,context,data)\
return true\
end\
local function onEmailSend(msg)\
return saveEmail(msg.data.account,msg.data.email)\
end\
local function onAccountPassword(msg)\
if validatePassword(msg.data.account,msg.data.password)then\
return setAccountPassword(msg.data.account,msg.data.newPassword)\
end\
return false\
end\
local function onEmailRequest(msg)\
if validatePassword(msg.data.account,msg.data.password)then\
local files=listEmails(msg.data.account)\
if files then\
for i=1,#files,1 do\
local data={\
account=msg.data.account,\
id=files[i],\
email=readEmail(msg.data.account,files[i])\
}\
connection:send(msg.senderId or msg.senderName,\
msg.data.application,\"email_response\",data)\
end\
return true\
end\
end\
return false\
end\
local function onEmailDelete(msg)\
if validatePassword(msg.data.account,msg.data.password)then\
deleteEmail(msg.data.account,msg.data.id)\
return true\
end\
return false\
end\
local function onCreateAccount(msg)\
if msg.data.password==SERVER_PASSWORD then\
return createAccount(msg.data.account,msg.data.clientPassword)\
end\
return false\
end\
local function onDeleteAccount(msg)\
if msg.data.password==SERVER_PASSWORD then\
return deleteAccount(msg.data.account)\
end\
return false\
end\
local function onResetPassword(msg)\
if msg.data.password==SERVER_PASSWORD then\
return setAccountPassword(msg.data.account,\
tostring(msg.data.clientPassword or \"1234\"))\
end\
return false\
end\
local function onFileUpload(msg)\
if msg.data.password==SERVER_PASSWORD then\
local path=tostring(msg.data.path or \"\")\
if path:sub(1,1)~=\"/\" then\
path=\"/\"..path\
end\
local file=fs.open(SERVER_ROOT..path,\"w\")\
if file then\
file.write(tostring(msg.data.content))\
file.close()\
return true\
end\
end\
return false\
end\
local function onFileDelete(msg)\
if msg.data.password==SERVER_PASSWORD then\
local path=tostring(msg.data.path or \"\")\
if path:sub(1,1)~=\"/\" then\
path=\"/\"..path\
end\
if fs.exists(SERVER_ROOT..path)then\
fs.delete(SERVER_ROOT..path)\
return not fs.exists(SERVER_ROOT..path)\
end\
end\
return false\
end\
local function onListingRequest(msg)\
if msg.data.password==SERVER_PASSWORD then\
local path=tostring(msg.data.path or \"\")\
if path:sub(-1,-1)==\"/\" then\
path=path:sub(1,-2)\
end\
if path:sub(1,1)~=\"/\" then\
path=\"/\"..path\
end\
if fs.exists(SERVER_ROOT..path)and fs.isDir(SERVER_ROOT..path)then\
local success,listing=pcall(fs.list,SERVER_ROOT..path)\
if success then\
if path:sub(-1,-1)~=\"/\" then\
path=path..\"/\"\
end\
local data=\
{\
path=path,\
files={},\
folders={}\
}\
for i=1,#listing,1 do\
if fs.isDir(SERVER_ROOT..path..listing[i])then\
data.folders[#data.folders+1]=listing[i]\
else\
data.files[#data.files+1]=listing[i]\
end\
end\
connection:send(msg.senderId or msg.senderName,\
msg.data.application,\"listing_response\",data)\
return true\
end\
end\
end\
return false\
end\
local function onDirectoryCreate(msg)\
if msg.data.password==SERVER_PASSWORD then\
local path=tostring(msg.data.path or \"\")\
if path:sub(1,1)~=\"/\" then\
path=\"/\"..path\
end\
if not fs.exists(SERVER_ROOT..path)then\
pcall(fs.makeDir,SERVER_ROOT..path)\
return fs.exists(SERVER_ROOT..path)\
end\
end\
return false\
end\
local function receive(msg)\
local request=requestType(msg)\
if request==\"file_request\" then\
return onFileRequest(msg)\
elseif request==\"account_password\" then\
return onAccountPassword(msg)\
elseif request==\"email_request\" then\
return onEmailRequest(msg)\
elseif request==\"email_delete\" then\
return onEmailDelete(msg)\
elseif request==\"email_send\" then\
return onEmailSend(msg)\
elseif request==\"file_upload\" then\
return onFileUpload(msg)\
elseif request==\"file_delete\" then\
return onFileDelete(msg)\
elseif request==\"listing_request\" then\
return onListingRequest(msg)\
elseif request==\"directory_create\" then\
return onDirectoryCreate(msg)\
elseif request==\"create_account\" then\
return onCreateAccount(msg)\
elseif request==\"delete_account\" then\
return onDeleteAccount(msg)\
elseif request==\"reset_password\" then\
return onResetPassword(msg)\
end\
return false\
end\
local function sent(msg,success)\
end\
connection:register(nil,SERVER_NETWORK,receive,sent)\
function os.pullEventRaw(target)\
if not commTimer or(os.clock()-commTime)>=COMMTIME then\
connection:process()\
commTimer=os.startTimer(COMMTIME)\
commTime=os.clock()\
end\
while true do\
local event={os_pullEventRaw()}\
if event[1]==\"timer\" and event[2]==commTimer then\
connection:process()\
commTimer=os.startTimer(COMMTIME)\
commTime=os.clock()\
else\
if event[1]==\"modem_message\" then\
connection:receive(event[2],event[3],event[4],event[5],event[6])\
end\
if not target or event[1]==target or event[1]==\"terminate\" then\
return unpack(event)\
end\
end\
end\
end\
printMsg(\"Server started\")\
",
"This software is covered by the MIT license.\
\
MIT License\
\
Copyright (c) 2015 loosewheel\
\
Permission is hereby granted, free of charge, to any person obtaining a copy\
of this software and associated documentation files (the \"Software\"), to deal\
in the Software without restriction, including without limitation the rights\
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell\
copies of the Software, and to permit persons to whom the Software is\
furnished to do so, subject to the following conditions:\
\
The above copyright notice and this permission notice shall be included in all\
copies or substantial portions of the Software.\
\
THE SOFTWARE IS PROVIDED \"AS IS\", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR\
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,\
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE\
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER\
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,\
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE\
SOFTWARE.\
",
"function version()\
return 0.23\
end\
local _ccversion=nil\
function ccVersion()\
if not _ccversion then\
_ccversion=0\
if _G._HOST then\
for w in string.gmatch(_G._HOST,\"(%d+%p%d+)\")do\
if asnumber(w)>0 then\
_ccversion=asnumber(w)\
break\
end\
end\
elseif _G._CC_VERSION then\
_ccversion=asnumber(_G._CC_VERSION)\
else\
local v=os.version()\
for w in string.gmatch(v,\"(%d+%p%d+)\")do\
if asnumber(w)>0 then\
_ccversion=asnumber(w)\
break\
end\
end\
end\
end\
return _ccversion\
end\
function _G.asnumber(v,defV)\
return tonumber(v)or(tonumber(defV or 0)or 0)\
end\
function _G.asstring(v,defV)\
return tostring(v or(tostring(defV or \"\")))..\"\"\
end\
function _G.iif(condition,trueValue,falseValue)\
if condition then\
return trueValue\
end\
return falseValue\
end\
function string:trimLeft(char)\
str=tostring(self or \"\")\
char=tostring(char or \" \")\
if char:len()>0 then\
while str:sub(1,char:len())==char do\
str=str:sub(char:len()+1)\
end\
end\
return str\
end\
function string:trimRight(char)\
str=tostring(self or \"\")\
char=tostring(char or \" \")\
if char:len()>0 then\
while str:sub(-1,-(char:len()))==char do\
str=str:sub(1,-(char:len()+1))\
end\
end\
return str\
end\
function string:trim(char)\
return string.trimRight(string.trimLeft(self,char),char)\
end\
function string:splice(len)\
str=tostring(self or \"\")\
len=tonumber(len or 0)or 0\
if len>0 then\
local eol=(str:find(\"[\\r\\n]\"))or(str:len()+1)\
local nextLine=eol+1\
if(eol-1)<=len and eol<=str:len()then\
if str:byte(eol)==13 and eol<str:len()then\
if str:byte(eol+1)==10 then\
nextLine=nextLine+1\
end\
end\
return str:sub(1,eol-1),(str:sub(nextLine)or \"\"),true\
end\
if str:len()<=len then\
return str,nil,false\
end\
for pos=len+1,1,-1 do\
if str:byte(pos)==32 then\
return str:sub(1,pos-1),(str:sub(pos+1)or \"\"),true\
end\
end\
return str:sub(1,len),(str:sub(len+1)or \"\"),true\
end\
return str,nil,false\
end\
function string:wrap(maxWidth)\
local wrapped={}\
str=tostring(self or \"\")\
maxWidth=tonumber(maxWidth or 0)or 0\
repeat\
wrapped[#wrapped+1],str=string.splice(str,maxWidth)\
until not str\
return wrapped\
end\
function string.wrapSize(wrapStr)\
local width,height=0,0\
if type(wrapStr)==\"table\" then\
height=#wrapStr\
for i=1,height,1 do\
if type(wrapStr[i])~=\"string\" then\
return 0,0\
end\
if wrapStr[i]:len()>width then\
width=wrapStr[i]:len()\
end\
end\
end\
return width,height\
end\
function textutils.formatTime(timeValue,twentyFourHour,minLength)\
local str;\
local hour,minute=math.modf(asnumber(timeValue))\
minute=minute*60\
if twentyFourHour then\
str=string.format(\"%d:%02d\",hour,minute)\
else\
local ampm=iif(hour<12,\"AM\",\"PM\")\
if hour==0 then\
hour=12\
elseif hour>12 then\
hour=hour-12\
end\
str=string.format(\"%d:%02d %s\",hour,minute,ampm)\
end\
if minLength then\
if minLength>str:len()then\
str=string.rep(\" \",minLength-str:len())..str\
end\
end\
return str\
end\
function fs.getExtension(path)\
local ext=\"\"\
local fileName=fs.getName(path)\
for i=fileName:len(),1,-1 do\
if fileName:sub(i,i)==\".\" then\
ext=fileName:sub(i+1)\
break\
end\
end\
return ext\
end\
function fs.loadIniFile(path)\
local iniFile;\
path=asstring(path)\
if fs.exists(path)and not fs.isDir(path)then\
local hInit=fs.open(path,\"r\")\
if hInit then\
local content=hInit.readAll()\
if content then\
iniFile={}\
for line in content:gmatch(\"([^\\r\\n]*)[\\r\\n]*\")do\
local comment,name,value=line:match(\"(;*)([^=]*)=(.*)\")\
if comment and comment:len()==0 then\
name=string.trim(name)\
if name:len()>0 then\
iniFile[#iniFile+1]=\
{\
name=name,\
value=value\
}\
end\
end\
end\
function iniFile:find(key)\
for i=1,#self,1 do\
if self[i].name==key then\
return self[i].value\
end\
end\
return nil\
end\
function iniFile:next(key)\
local init=1\
return function()\
for i=init,#self,1 do\
if self[i].name==key then\
init=i+1\
return self[i].value\
end\
end\
init=#self+1\
return nil\
end\
end\
end\
hInit.close()\
end\
end\
return iniFile\
end\
function fs.tmpfile(prefix)\
local path;\
local counter=0\
repeat\
path=\"/win/tmp/\"..tostring(prefix or \"tmp\")..tostring(counter)\
counter=counter+1\
until not fs.exists(path)\
return path\
end\
local function getPassword()\
local iniFile=fs.loadIniFile(\"/win/startup.ini\")\
local password=\"\"\
if iniFile then\
password=asstring(iniFile:find(\"password\"),\"\")\
end\
return password\
end\
local function safeRead(mask)\
local entered=\"\"\
mask=asstring(mask):sub(1,1)\
term.setCursorBlink(true)\
while true do\
local event,param=os.pullEventRaw()\
if event==\"key\" then\
if param==keys.enter then\
term.setCursorBlink(false)\
return entered\
elseif param==keys.backspace then\
if entered:len()>0 then\
local x,y=term.getCursorPos()\
entered=entered:sub(1,-2)\
term.setCursorPos(x-1,y)\
term.write(\" \")\
term.setCursorPos(x-1,y)\
end\
end\
elseif event==\"char\" then\
entered=entered..param\
if mask:len()==1 then\
term.write(mask)\
else\
term.write(param)\
end\
end\
end\
end\
function syslog(entry)\
local file=fs.open(\"/win/win.log\",iif(fs.exists(\"/win/win.log\"),\"a\",\"w\"))\
if file then\
file.write(entry..\"\\n\\n\")\
file.close()\
end\
end\
function parseCmdLine(...)\
local line=table.concat({...},\" \")\
local args={}\
local quoted=false\
for match in(line..\"\\\"\"):gmatch(\"(.-)\\\"\")do\
if quoted then\
args[#args+1]=match\
else\
for arg in match:gmatch(\"[^ \\t]+\")do\
args[#args+1]=arg\
end\
end\
quoted=not quoted\
end\
return args\
end\
function loadAPI(path,perm)\
local name=fs.getName(path)\
local refCount=perm and-1 or 1\
if not perm and _G[name]and _G[name].api_refCount then\
refCount=_G[name].api_refCount\
if refCount>=0 then\
refCount=refCount+1\
end\
end\
os.loadAPI(path)\
if _G[name]then\
_G[name].api_refCount=refCount\
return true\
end\
return false\
end\
function unloadAPI(path)\
local name=fs.getName(path)\
if _G[name]and _G[name].api_refCount then\
if _G[name].api_refCount<0 then\
return\
elseif _G[name].api_refCount>1 then\
_G[name].api_refCount=_G[name].api_refCount-1\
return\
end\
end\
os.unloadAPI(path)\
end\
__classBase={}\
function __classBase:constructor(...)\
return self\
end\
function __classBase:new(...)\
local obj={}\
setmetatable(obj,self)\
self.__index=self\
return obj:constructor(...)\
end\
function __classBase:base()\
local obj={}\
setmetatable(obj,self)\
self.__index=self\
return obj\
end\
local GDI_TERM=1\
local GDI_MONITOR=2\
local GDI_PRINTER=4\
WND_TOP=0\
WND_BOTTOM=100000\
HT_NOWHERE=0\
HT_CLIENT=1\
HT_LINEUP=2\
HT_LINEDOWN=3\
HT_PAGEUP=4\
HT_PAGEDOWN=5\
HT_LINELEFT=6\
HT_LINERIGHT=7\
HT_PAGELEFT=8\
HT_PAGERIGHT=9\
local ID_DESKTOP=65536\
local ID_FRAME=65537\
local ID_TASKBAR=65538\
local ID_MENULIST=65539\
local ID_APPLIST=65540\
local ID_MENUFRAME=65539\
local ID_APPFRAME=65540\
local ID_KEYBOARD=65541\
local ID_DIALOG=65542\
local ID_MSGBOX_MSG=65543\
local ID_LOCKSCRN=65544\
local ID_LOCKPW=65545\
local ID_LOCKOK=65546\
local ID_HOMELOCK=65547\
local FRAME_CLASS_WINDOW=70000\
local FRAME_CLASS_SYSTEM=70001\
local FRAME_CLASS_APPLICATION=70002\
local FRAME_CLASS_DIALOG=70003\
ID_TITLEBAR=80000\
ID_CLOSE=80001\
CB_EMPTY=0\
CB_TEXT=1\
KEYINPUT_NONE=0\
KEYINPUT_LINE=1\
KEYINPUT_EDIT=2\
local __ccwin;\
local __shell=nil\
desktopTheme=__classBase:base()\
function desktopTheme:constructor()\
self.doubleClick=0.5\
self.textScale=1.0\
self.keyboardHeight=5\
self.closeBtnChar=\"x\"\
self.color={\
desktopBack=colors.black,\
wndText=colors.black,\
wndBack=colors.white,\
wndFocus=colors.lightBlue,\
frameText=colors.black,\
frameBack=colors.lightGray,\
popupText=colors.black,\
popupBack=colors.yellow,\
buttonText=colors.black,\
buttonBack=colors.blue,\
buttonFocus=colors.cyan,\
inputText=colors.black,\
inputBack=colors.white,\
inputFocus=colors.lightBlue,\
inputError=colors.pink,\
inputBanner=colors.lightGray,\
selectedText=colors.white,\
selectedBack=colors.blue,\
scrollText=colors.lightGray,\
scrollBack=colors.gray,\
scrollTrack=colors.lightGray,\
checkText=colors.green,\
checkBack=colors.white,\
checkFocus=colors.lightBlue,\
taskText=colors.lightGray,\
taskBack=colors.gray,\
homeText=colors.lightGray,\
homeBack=colors.black,\
homeItemText=colors.blue,\
homeItemBack=colors.black,\
homeItemSelectedText=colors.lightBlue,\
homeItemSelectedBack=colors.black,\
titleText=colors.white,\
titleBack=colors.gray,\
closeText=colors.white,\
closeBack=colors.red,\
closeFocus=colors.purple,\
kbText=colors.lightGray,\
kbBack=colors.black,\
kbKey=colors.black,\
kbCmd=colors.blue,\
kbCancel=colors.green,\
kbToggle=colors.lightBlue,\
menuText=colors.black,\
menuBack=colors.lightBlue,\
menuSelectedText=colors.white,\
menuSelectedBack=colors.blue\
}\
return self\
end\
local __defaultTheme=desktopTheme:new()\
function wndToScreen(wnd,x,y)\
local _wnd,rx,ry=wnd,x,y\
while _wnd do\
rx=rx+_wnd.x\
ry=ry+_wnd.y\
_wnd=_wnd.wnd__parent\
end\
return rx,ry\
end\
function screenToWnd(wnd,x,y)\
local _wnd,rx,ry=wnd,x,y\
while _wnd do\
rx=rx-_wnd.x\
ry=ry-_wnd.y\
_wnd=_wnd.wnd__parent\
end\
return rx,ry\
end\
rect=__classBase:base()\
function rect:constructor(x,y,width,height)\
self.x=asnumber(x)\
self.y=asnumber(y)\
self.width=asnumber(width)\
self.height=asnumber(height)\
return self\
end\
function rect:isEmpty()\
if self.x and self.y and self.width and self.height then\
return(self.width==0 or self.height==0)\
end\
return true\
end\
function rect:empty()\
self.x=0\
self.y=0\
self.width=0\
self.height=0\
end\
function rect:copy(rtCopy)\
self.x=asnumber(rtCopy.x)\
self.y=asnumber(rtCopy.y)\
self.width=asnumber(rtCopy.width)\
self.height=asnumber(rtCopy.height)\
end\
function rect:unpack()\
return self.x,self.y,self.width,self.height\
end\
function rect:clip(rtClip)\
if rtClip:isEmpty()or self:isEmpty()then\
self:empty()\
else\
self.width=self.width+self.x\
self.height=self.height+self.y\
if rtClip.x>self.x then\
self.x=rtClip.x\
end\
if rtClip.y>self.y then\
self.y=rtClip.y\
end\
if self.width>(rtClip.x+rtClip.width)then\
self.width=rtClip.x+rtClip.width\
end\
if self.height>(rtClip.y+rtClip.height)then\
self.height=rtClip.y+rtClip.height\
end\
self.width=self.width-self.x\
self.height=self.height-self.y\
if self.width<=0 or self.height<=0 then\
self:empty()\
end\
end\
end\
function rect:bound(rtCombine)\
if self:isEmpty()then\
self:copy(rtCombine)\
elseif not rtCombine:isEmpty()then\
self.width=self.width+self.x\
self.height=self.height+self.y\
if rtCombine.x<self.x then\
self.x=rtCombine.x\
end\
if rtCombine.y<self.y then\
self.y=rtCombine.y\
end\
if self.width<(rtCombine.x+rtCombine.width)then\
self.width=rtCombine.x+rtCombine.width\
end\
if self.height<(rtCombine.y+rtCombine.height)then\
self.height=rtCombine.y+rtCombine.height\
end\
self.width=self.width-self.x\
self.height=self.height-self.y\
end\
end\
function rect:offset(x,y)\
if not self:isEmpty()then\
self.x=self.x+x\
self.y=self.y+y\
end\
end\
function rect:contains(x,y)\
if not self:isEmpty()then\
return((x>=self.x)and(x<(self.x+self.width))and\
(y>=self.y)and(y<(self.y+self.height)))\
end\
return false\
end\
function rect:overlap(rtTest)\
if self:isEmpty()or rtTest:isEmpty()then\
return false\
end\
if self.x>=(rtTest.x+rtTest.width)then\
return false\
end\
if rtTest.x>=(self.x+self.width)then\
return false\
end\
if self.y>=(rtTest.y+rtTest.height)then\
return false\
end\
if rtTest.y>=(self.y+self.height)then\
return false\
end\
return true\
end\
local function displayBuffer(interface)\
local db={}\
db.x=-1\
db.y=-1\
db.draw=true\
db.color=colors.white\
db.bgColor=colors.black\
db.blink=true\
db.scale=1.0\
db.interface=interface\
db.lines={}\
function db.blit()\
local width,height=db.getSize()\
db.interface.setCursorBlink(false)\
for line=1,height,1 do\
if db.lines[line]then\
for i=1,#db.lines[line],1 do\
local b=db.lines[line][i]\
db.interface.setCursorPos(b.first,line)\
if db.interface.isColor()then\
db.interface.setTextColor(b.color)\
db.interface.setBackgroundColor(b.bgColor)\
end\
db.interface.write(b.text)\
end\
end\
end\
db.interface.setCursorPos(db.x,db.y)\
if db.interface.isColor()then\
db.interface.setTextColor(db.color)\
db.interface.setBackgroundColor(db.bgColor)\
end\
db.interface.setCursorBlink(db.blink)\
db.lines={}\
end\
function db.setDraw(draw)\
if draw~=db.draw then\
db.draw=draw\
if draw then\
db.blit()\
end\
end\
end\
function db.write(text)\
if text:len()>0 then\
local first,last=db.x,db.x+text:len()-1\
if not db.lines[db.y]then\
db.lines[db.y]={}\
else\
for i=#db.lines[db.y],1,-1 do\
local part=db.lines[db.y][i]\
if first<=part.first then\
if last>=part.last then\
table.remove(db.lines[db.y],i)\
elseif last>=part.first then\
part.text=part.text:sub(last-part.first+2)\
part.first=last+1\
end\
elseif last>=part.last then\
if first<=part.last then\
part.text=part.text:sub(1,-(part.last-first+2))\
part.last=first-1\
end\
elseif first>part.first and last<part.last then\
db.lines[db.y][#db.lines[db.y]+1]=\
{\
first=last+1,\
last=part.last,\
color=part.color,\
bgColor=part.bgColor,\
text=part.text:sub(last-part.first+2)\
}\
part.text=part.text:sub(1,first-part.first)\
part.last=first-1\
end\
end\
end\
db.lines[db.y][#db.lines[db.y]+1]=\
{\
first=first,\
last=last,\
color=db.color,\
bgColor=db.bgColor,\
text=text\
}\
if db.draw then\
db.interface.setCursorPos(db.x,db.y)\
if db.interface.isColor()then\
db.interface.setTextColor(db.color)\
db.interface.setBackgroundColor(db.bgColor)\
end\
db.interface.write(text)\
end\
db.x=last+1\
end\
end\
function db.getCursorPos()\
return db.interface.getCursorPos()\
end\
function db.setCursorPos(x,y)\
db.x=x\
db.y=y\
db.interface.setCursorPos(x,y)\
end\
function db.setCursorBlink(blink)\
db.blink=blink\
db.interface.setCursorBlink(blink)\
end\
function db.isColor()\
return db.interface.isColor()\
end\
function db.getSize()\
return db.interface.getSize()\
end\
function db.setTextColor(color)\
db.color=color\
db.interface.setTextColor(color)\
end\
function db.setBackgroundColor(color)\
db.bgColor=color\
db.interface.setBackgroundColor(color)\
end\
function db.getTextColor()\
return db.color\
end\
function db.getBackgroundColor()\
return db.bgColor\
end\
function db.setTextScale(scale)\
db.scale=scale\
db.interface.setTextScale(scale)\
end\
return db\
end\
GDI=__classBase:base()\
function GDI:constructor(side,wnd)\
self.gdi__side=\"\"\
self.gdi__device=nil\
self.gdi__type=0\
self.gdi__wnd=wnd\
self.gdi__xOrg=0\
self.gdi__yOrg=0\
self.gdi__shellBuffered=false\
self.gdi__storedCursorX=nil\
self.gdi__storedCursorY=nil\
self.gdi__bounds=rect:new()\
if not self:setSide(side)then\
return nil\
end\
return self\
end\
function GDI:setSide(side)\
side=asstring(side)\
self.gdi__shellBuffered=false\
if side==\"term\" then\
self.gdi__side=\"term\"\
self.gdi__type=GDI_TERM\
if self.gdi__wnd and self.gdi__wnd:getParent()then\
self.gdi__device=self.gdi__wnd:getParent().gdi.gdi__device\
elseif self.gdi__wnd and self.gdi__wnd.dt__bufferDisplay then\
if term.current()and term.current().setVisible then\
self.gdi__device=term\
self.gdi__shellBuffered=true\
else\
self.gdi__device=displayBuffer(term)\
end\
else\
self.gdi__device=term\
end\
else\
local devType=peripheral.getType(side)\
if devType==\"monitor\" then\
self.gdi__side=side\
self.gdi__type=GDI_MONITOR\
if self.gdi__wnd and self.gdi__wnd:getParent()then\
self.gdi__device=self.gdi__wnd:getParent().gdi.gdi__device\
elseif self.gdi__wnd and self.gdi__wnd.dt__bufferDisplay then\
self.gdi__device=displayBuffer(peripheral.wrap(side))\
else\
self.gdi__device=peripheral.wrap(side)\
end\
elseif devType==\"printer\" then\
self.gdi__side=side\
self.gdi__type=GDI_PRINTER\
self.gdi__device=peripheral.wrap(side)\
else\
return false\
end\
end\
return true\
end\
function GDI:getSide()\
return self.gdi__side\
end\
function GDI:setDraw(draw)\
if self.gdi__shellBuffered then\
term.current().setVisible(draw)\
elseif self.gdi__device.setDraw then\
self.gdi__device.setDraw(draw)\
end\
end\
function GDI:getOrg()\
return self.gdi__xOrg,self.gdi__yOrg\
end\
function GDI:setOrg(x,y)\
self.gdi__xOrg=x\
self.gdi__yOrg=y\
end\
function GDI:getBounds(clearBounds)\
local rt=rect:new(self.gdi__bounds:unpack())\
if clearBounds then\
self.gdi__bounds:empty()\
end\
return rt\
end\
function GDI:addBounds(rt)\
self.gdi__bounds:bound(rt)\
end\
function GDI:isPrinter()\
return(self.gdi__type==GDI_PRINTER)\
end\
function GDI:isMonitor()\
return(self.gdi__type==GDI_MONITOR)\
end\
function GDI:isTerm()\
return(self.gdi__type==GDI_TERM)\
end\
function GDI:isColor()\
if self.gdi__device.isColor then\
return self.gdi__device.isColor()\
end\
return false\
end\
function GDI:getSize()\
if self:isTerm()or self:isMonitor()then\
return self.gdi__device.getSize()\
elseif self:isPrinter()then\
return self.gdi__device.getPageSize()\
end\
return 0,0\
end\
function GDI:getCursorPos()\
local x,y=self.gdi__device.getCursorPos();\
return(x-1),(y-1)\
end\
function GDI:setCursorPos(x,y)\
self.gdi__device.setCursorPos(x+1,y+1)\
end\
function GDI:setCursorBlink(blink)\
if self:isTerm()or self:isMonitor()then\
self.gdi__device.setCursorBlink(blink)\
end\
end\
function GDI:hideCursor()\
self:setCursorPos(-1,-1)\
end\
function GDI:store()\
if not self.gdi__storedCursorX or not self.gdi__storedCursorY then\
self.gdi__storedCursorX,self.gdi__storedCursorY=self:getCursorPos()\
end\
end\
function GDI:restore()\
if self.gdi__storedCursorX and self.gdi__storedCursorY then\
self:setCursorPos(self.gdi__storedCursorX,self.gdi__storedCursorY)\
self.gdi__storedCursorX,self.gdi__storedCursorY=nil,nil\
if __ccwin:getDesktop(self:getSide())then\
self:setTextColor(__ccwin:getDesktop(self:getSide()).dt__cursorColor)\
end\
end\
end\
function GDI:setTextColor(color)\
if self:isColor()then\
self.gdi__device.setTextColor(color)\
end\
end\
function GDI:getTextColor()\
if self.gdi__device.getTextColor then\
return self.gdi__device.getTextColor()\
end\
return colors.white\
end\
function GDI:setBackgroundColor(color)\
if self:isColor()then\
self.gdi__device.setBackgroundColor(color)\
end\
end\
function GDI:getBackgroundColor()\
if self.gdi__device.getBackgroundColor then\
return self.gdi__device.getBackgroundColor()\
end\
return colors.black\
end\
function GDI:setTextScale(scale)\
if self:isMonitor()then\
self.gdi__device.setTextScale(scale)\
end\
end\
function GDI:clearWnd(x,y,width,height)\
local rt=rect:new(x,y,width,height)\
if self.gdi__wnd then\
rt:clip(rect:new(0,0,self.gdi__wnd.width,\
self.gdi__wnd.height))\
rt:offset(self.gdi__wnd:wndToScreen(0,0))\
if self.gdi__wnd:getParent()then\
rt:clip(self.gdi__wnd:getParent():getScreenRect())\
end\
end\
rt:offset(self:getOrg())\
rt:clip(rect:new(0,0,self:getSize()))\
if not rt:isEmpty()then\
local blank=string.rep(\" \",rt.width)\
for i=0,rt.height-1,1 do\
self:setCursorPos(rt.x,rt.y+i)\
self.gdi__device.write(blank)\
end\
self:addBounds(rt)\
end\
end\
function GDI:writeWnd(text,x,y)\
local rt,txt=nil,asstring(text)\
if txt:len()then\
if self.gdi__wnd then\
rt=rect:new(x,y,txt:len(),1)\
if rt.x<0 then\
txt=txt:sub((rt.x*-1)+1)\
end\
rt:clip(rect:new(0,0,self.gdi__wnd.width,\
self.gdi__wnd.height))\
rt:offset(self.gdi__wnd:wndToScreen(0,0))\
local screenX=rt.x\
if self.gdi__wnd:getParent()then\
rt:clip(self.gdi__wnd:getParent():getScreenRect())\
end\
if screenX<rt.x then\
txt=txt:sub((rt.x-screenX)+1)\
end\
else\
if x<0 then\
txt=txt:sub((x*-1)+1)\
x=0\
end\
rt=rect:new(x,y,txt:len(),1)\
end\
rt:offset(self:getOrg())\
rt:clip(rect:new(0,0,self:getSize()))\
if not rt:isEmpty()then\
if txt:len()>rt.width then\
txt=txt:sub(1,rt.width)\
end\
self:setCursorPos(rt.x,rt.y)\
self.gdi__device.write(txt)\
self:addBounds(rt)\
end\
end\
end\
function GDI:clear(x,y,width,height)\
local rt;\
if self.gdi__wnd then\
rt=rect:new(x-self.gdi__wnd.wnd__scrollX,\
y-self.gdi__wnd.wnd__scrollY,width,height)\
rt:clip(rect:new(0,0,self.gdi__wnd:getClientSize()))\
rt:offset(self.gdi__wnd:wndToScreen(0,0))\
if self.gdi__wnd:getParent()then\
rt:clip(self.gdi__wnd:getParent():getScreenRect())\
end\
else\
rt=rect:new(x,y,width,height)\
end\
rt:offset(self:getOrg())\
rt:clip(rect:new(0,0,self:getSize()))\
if not rt:isEmpty()then\
local blank=string.rep(\" \",rt.width)\
for i=0,rt.height-1,1 do\
self:setCursorPos(rt.x,rt.y+i)\
self.gdi__device.write(blank)\
end\
self:addBounds(rt)\
end\
end\
function GDI:write(text,x,y)\
local rt,txt=nil,asstring(text)\
if txt:len()then\
if self.gdi__wnd then\
rt=rect:new(x-self.gdi__wnd.wnd__scrollX,\
y-self.gdi__wnd.wnd__scrollY,\
txt:len(),1)\
if rt.x<0 then\
txt=txt:sub((rt.x*-1)+1)\
end\
rt:clip(rect:new(0,0,self.gdi__wnd:getClientSize()))\
rt:offset(self.gdi__wnd:wndToScreen(0,0))\
local screenX=rt.x\
if self.gdi__wnd:getParent()then\
rt:clip(self.gdi__wnd:getParent():getScreenRect())\
end\
if screenX<rt.x then\
txt=txt:sub((rt.x-screenX)+1)\
end\
else\
rt=rect:new(x,y,txt:len(),1)\
if rt.x<0 then\
txt=txt:sub((rt.x*-1)+1)\
end\
end\
rt:offset(self:getOrg())\
rt:clip(rect:new(0,0,self:getSize()))\
if not rt:isEmpty()then\
if txt:len()>rt.width then\
txt=txt:sub(1,rt.width)\
end\
self:setCursorPos(rt.x,rt.y)\
self.gdi__device.write(txt)\
self:addBounds(rt)\
end\
end\
end\
function GDI:setPixelWnd(x,y,color)\
self:setBackgroundColor(color)\
self:writeWnd(\" \",x,y)\
end\
function GDI:setPixel(x,y,color)\
self:setBackgroundColor(color)\
self:write(\" \",x,y)\
end\
function GDI:getPaperLevel()\
if self:isPrinter()then\
return self.gdi__device.getPaperLevel()\
end\
return nil\
end\
function GDI:newPage()\
if self:isPrinter()then\
return self.gdi__device.newPage()\
end\
return false\
end\
function GDI:endPage()\
if self:isPrinter()then\
return self.gdi__device.endPage()\
end\
return false\
end\
function GDI:setPageTitle(title)\
if self:isPrinter()then\
self.gdi__device.setPageTitle(title)\
end\
end\
function GDI:getInkLevel()\
if self:isPrinter()then\
return self.gdi__device.getInkLevel()\
end\
return nil\
end\
function GDI:getPageSize()\
if self:isPrinter()then\
return self.gdi__device.getPageSize()\
end\
return nil,nil\
end\
function findModem(wireless)\
return peripheral.find(\
\"modem\",\
function(name,obj)\
return iif(wireless,obj.isWireless(),\
iif(wireless==false,\
not obj.isWireless(),\
true))\
end)\
end\
comm=__classBase:base()\
function comm:constructor(name,wireless,port,timeout,relay)\
self.comm__name=name\
self.comm__wireless=wireless\
self.comm__port=port or 80\
self.comm__timeout=timeout or 5\
self.comm__relay=relay==true\
self.comm__interests={}\
self.comm__processing={}\
return self\
end\
function comm:getName()\
return self.comm__name\
end\
function comm:setName(name)\
self.comm__name=name\
end\
function comm:getPort()\
return self.comm__port\
end\
function comm:setPort(port)\
self.comm__port=port or 80\
end\
function comm:getTimeout()\
return self.comm__timeout\
end\
function comm:setTimeout(timeout)\
self.comm__timeout=timeout or 5\
end\
function comm:getRelay()\
return self.comm__relay\
end\
function comm:setRelay(relay)\
self.comm__relay=relay==true\
end\
function comm:getWireless()\
return self.comm__wireless\
end\
function comm:setWireless(wireless)\
self.comm__wireless=wireless\
end\
function comm:modem()\
return findModem(self.comm__wireless)\
end\
function comm:connect()\
local modem=self:modem()\
if modem then\
modem.open(self:getPort())\
return true\
end\
return false\
end\
function comm:disconnect()\
local modem=self:modem()\
if modem then\
modem.close(self:getPort())\
end\
end\
function comm:ready()\
local modem=self:modem()\
if modem then\
if modem.isOpen(self:getPort())then\
return modem\
end\
end\
return nil\
end\
function comm:transmit(message)\
local modem=self:ready()\
if modem then\
modem.transmit(self:getPort(),self:getPort(),message)\
return true\
end\
return false\
end\
function comm:register(wnd,application)\
self.comm__interests[#self.comm__interests+1]=\
{\
wnd=wnd,\
application=application\
}\
end\
function comm:unregister(wnd,application)\
for i=#self.comm__interests,1,-1 do\
local interest=self.comm__interests[i]\
if interest.wnd==wnd and\
(interest.application==application or not application)then\
table.remove(self.comm__interests,i)\
end\
end\
end\
function comm:copyMsg(msg)\
return textutils.unserialize(textutils.serialize(msg))\
end\
function comm:callSentHandlers(msg,result)\
for i=1,#self.comm__interests,1 do\
if self.comm__interests[i].application==msg.application then\
__ccwin:pumpEvent(self.comm__interests[i].wnd,\"comm_sent\",self:copyMsg(msg),result)\
end\
end\
end\
function comm:isDuplicate(msg)\
for i=1,#self.comm__processing,1 do\
local process=self.comm__processing[i]\
if process.msg.messageId==msg.messageId then\
if process.status==\"received\" or\
(process.status==\"relay\" and\
process.msg.sequence==msg.sequence)then\
return true\
end\
end\
end\
return false\
end\
function comm:isConfirmation(msg)\
if msg.context==\"confirm\" then\
for i=#self.comm__processing,1,-1 do\
local process=self.comm__processing[i]\
if process.status==\"send\" then\
if process.msg.messageId==msg.messageId then\
self:callSentHandlers(process.msg,true)\
table.remove(self.comm__processing,i)\
end\
end\
end\
return true\
end\
return false\
end\
function comm:isFromMe(msg)\
return(asnumber(msg.senderId)==os.getComputerID()or\
asstring(msg.senderName)==os.getComputerLabel())\
end\
function comm:isForMe(msg,exclusive)\
if msg.recipientId then\
return asnumber(msg.recipientId)==os.getComputerID()\
elseif msg.recipientName then\
return asstring(msg.recipientName)==os.getComputerLabel()\
elseif exclusive then\
return false\
end\
return(not self:isFromMe(msg))\
end\
function comm:callReceiveHandlers(msg,modemSide,senderChannel,replyChannel,distance)\
local received=false\
local copy=self:copyMsg(msg)\
copy.modemSide=modemSide\
copy.senderChannel=senderChannel\
copy.replyChannel=replyChannel\
copy.distance=distance\
for i=1,#self.comm__interests,1 do\
if self.comm__interests[i].application==msg.application then\
if __ccwin:pumpEvent(self.comm__interests[i].wnd,\"comm_receive\",copy)then\
received=true\
end\
end\
end\
return received\
end\
function comm:sendConfirmation(msg)\
if msg.recipientName or msg.recipientId then\
local copy=self:copyMsg(msg)\
copy.context=\"confirm\"\
copy.recipientName=copy.senderName\
copy.recipientId=copy.senderId\
copy.senderName=os.getComputerLabel()\
copy.senderId=os.getComputerID()\
copy.sequence=-1\
if not self:transmit(textutils.serialize(copy))then\
syslog(\"comm \"..self:getName()..\" no modem for confirmation to \"..asstring(msg.senderName))\
end\
end\
end\
function comm:receive(modemSide,senderChannel,replyChannel,message,distance)\
if senderChannel==self:getPort()then\
local success,msg=pcall(textutils.unserialize,message)\
if success and type(msg)==\"table\" then\
if msg.messageId and msg.application and msg.context then\
if self:isForMe(msg)then\
if not self:isConfirmation(msg)then\
if not self:isDuplicate(msg)then\
if self:callReceiveHandlers(msg,modemSide,senderChannel,replyChannel,distance)then\
self.comm__processing[#self.comm__processing+1]=\
{\
timeStamp=os.clock(),\
status=\"received\",\
msg=msg\
}\
self:sendConfirmation(msg)\
end\
end\
end\
end\
if self:getRelay()then\
if not self:isFromMe(msg)and not self:isForMe(msg,true)then\
if not self:isDuplicate(msg)then\
if not self:transmit(message)then\
syslog(\"comm \"..self:getName()..\" no modem to relay message\")\
end\
self.comm__processing[#self.comm__processing+1]=\
{\
timeStamp=os.clock(),\
status=\"relay\",\
msg=msg\
}\
end\
end\
end\
end\
end\
end\
end\
function comm:send(recipient,application,context,data)\
local msg={}\
local method=\"send\"\
if recipient then\
if type(recipient)==\"number\" then\
msg.recipientId=recipient\
if msg.recipientId==os.getComputerID()then\
return\
end\
else\
msg.recipientName=asstring(recipient)\
if msg.recipientName==os.getComputerLabel()then\
return\
end\
end\
else\
method=\"broadcast\"\
end\
msg.context=context\
msg.application=application\
msg.data=data\
msg.senderId=os.getComputerID()\
msg.senderName=os.getComputerLabel()or \"\"\
msg.messageId=math.random(1,65535)\
msg.sequence=0\
self.comm__processing[#self.comm__processing+1]=\
{\
timeStamp=os.clock(),\
status=method,\
msg=msg\
}\
return msg.messageId\
end\
function comm:process()\
for i=#self.comm__processing,1,-1 do\
local process=self.comm__processing[i]\
if process.status==\"received\" or process.status==\"relay\" then\
if(os.clock()-process.timeStamp)>(self:getTimeout()*2)then\
table.remove(self.comm__processing,i)\
end\
elseif process.status==\"send\" or process.status==\"broadcast\" then\
if(os.clock()-process.timeStamp)>self:getTimeout()then\
if process.status==\"send\" then\
self:callSentHandlers(process.msg,false)\
end\
table.remove(self.comm__processing,i)\
else\
process.msg.sequence=process.msg.sequence+1\
if self:transmit(textutils.serialize(process.msg))then\
if process.status==\"broadcast\" then\
if process.msg.sequence==1 then\
self:callSentHandlers(process.msg,true)\
end\
end\
else\
syslog(\"comm \"..self:getName()..\" no modem to send message\")\
end\
end\
end\
end\
end\
window=__classBase:base()\
function window:constructor(parent,id,x,y,width,height)\
self.x=math.floor(asnumber(x))\
self.y=math.floor(asnumber(y))\
self.width=math.floor(asnumber(width))\
self.height=math.floor(asnumber(height))\
self.wnd__parent=nil\
self.wnd__owner=nil\
self.wnd__popup=nil\
self.wnd__frameClass=FRAME_CLASS_WINDOW\
self.wnd__id=asnumber(id)\
self.wnd__color=colors.black\
self.wnd__bgColor=0\
self.wnd__cursorX=0\
self.wnd__cursorY=0\
self.wnd__scrollX=0\
self.wnd__scrollY=0\
self.wnd__scrollWidth=0\
self.wnd__scrollHeight=0\
self.wnd__enabled=true\
self.wnd__hidden=false\
self.wnd__text=\"\"\
self.wnd__wantFocus=true\
self.wnd__alive=true\
self.wnd__wantKeyInput=KEYINPUT_NONE\
self.gdi=nil\
self.wnd__nodes={}\
self.wnd__invalid=rect:new()\
self:setParent(parent)\
return self\
end\
function window:invalidate(x,y,width,height)\
if not x then\
x=0\
end\
if not y then\
y=0\
end\
if not width then\
width=self.width\
end\
if not height then\
height=self.height\
end\
self.wnd__invalid:bound(rect:new(math.floor(x),math.floor(y),\
math.floor(width),math.floor(height)))\
if self:getParent()then\
local px,py=wndToScreen(self,self.wnd__invalid.x,\
self.wnd__invalid.y)\
px,py=screenToWnd(self:getParent(),px,py)\
self:getParent():invalidate(px,py,\
self.wnd__invalid.width,\
self.wnd__invalid.height)\
end\
end\
function window:validate()\
self.wnd__invalid=rect:new(0,0,0,0)\
end\
function window:move(x,y,width,height,z)\
self:invalidate()\
self:validate()\
if x then\
self.x=math.floor(x)\
end\
if y then\
self.y=math.floor(y)\
end\
if width then\
self.width=math.floor(width)\
end\
if height then\
self.height=math.floor(height)\
end\
if z and self:getParent()then\
local pos=self:getParent():childIndex(self)\
local i=pos\
if i>0 then\
if z==WND_TOP then\
pos=1\
elseif z==WND_BOTTOM then\
pos=self:getParent():children()\
else\
pos=pos+z\
end\
if pos<1 then\
pos=1\
elseif pos>self:getParent():children()then\
pos=self:getParent():children()\
end\
table.insert(self:getParent().wnd__nodes,pos,\
table.remove(self:getParent().wnd__nodes,i))\
end\
end\
self:setScrollOrg(self:getScrollOrg())\
self:invalidate()\
local success,msg=pcall(self.onMove,self)\
if not success then\
syslog(\"onMove \"..msg)\
end\
end\
function window:getGDI()\
self.gdi:store()\
return self.gdi\
end\
function window:releaseGDI()\
self.gdi:restore()\
end\
function window:setId(id)\
self.wnd__id=asnumber(id)\
end\
function window:getId()\
return self.wnd__id\
end\
function window:getColor()\
return self.wnd__color\
end\
function window:setColor(color)\
self.wnd__color=asnumber(color,colors.black)\
self:invalidate()\
end\
function window:getBgColor()\
return self.wnd__bgColor\
end\
function window:setBgColor(color)\
self.wnd__bgColor=asnumber(color,colors.white)\
self:invalidate()\
end\
function window:getText()\
return self.wnd__text\
end\
function window:setText(text)\
self.wnd__text=asstring(text)\
self:invalidate()\
end\
function window:getWantFocus()\
return self.wnd__wantFocus\
end\
function window:setWantFocus(want)\
self.wnd__wantFocus=want\
end\
function window:getWantKeyInput()\
return self.wnd__wantKeyInput\
end\
function window:setWantKeyInput(keyInput)\
self.wnd__wantKeyInput=keyInput\
end\
function window:show(show)\
show=show~=false\
if(not show)~=self.wnd__hidden then\
if not show then\
if self:capturedMouse()==self then\
self:releaseMouse()\
end\
if self:getFocus()==self then\
local frame=self:getParentFrame()\
if frame then\
frame:setFocusWnd(nil)\
end\
end\
end\
self.wnd__hidden=not show\
self:invalidate()\
end\
end\
function window:isShown()\
if self.wnd__hidden then\
return false\
end\
if self:getParent()then\
return self:getParent():isShown()\
end\
return true\
end\
function window:enable(enable)\
enable=enable~=false\
if enable~=self.wnd__enabled then\
if not enable then\
if self:capturedMouse()==self then\
self:releaseMouse()\
end\
if self:getFocus()==self then\
local frame=self:getParentFrame()\
if frame then\
frame:setFocusWnd(nil)\
end\
end\
end\
self.wnd__enabled=enable\
self:invalidate()\
end\
end\
function window:isEnabled()\
if not self.wnd__enabled then\
return false\
end\
if self:getParent()then\
return self:getParent():isEnabled()\
end\
return true\
end\
function window:children()\
return #self.wnd__nodes\
end\
function window:addChild(child)\
self.wnd__nodes[self:children()+1]=child\
end\
function window:getChild(i)\
if i>0 and i<=self:children()then\
return self.wnd__nodes[i]\
end\
return nil\
end\
function window:childIndex(child)\
for i=1,self:children(),1 do\
if self.wnd__nodes[i]==child then\
return i\
end\
end\
return 0\
end\
function window:removeChild(child)\
local i=self:childIndex(child)\
if i>0 then\
table.remove(self.wnd__nodes,i)\
return true\
end\
return false\
end\
function window:getParent()\
return self.wnd__parent\
end\
function window:setParent(parent)\
if parent then\
if parent:childIndex(self)==0 then\
if self.wnd__parent then\
self:invalidate()\
self.wnd__parent:removeChild(self)\
end\
self.wnd__parent=parent\
if not self.gdi then\
self.gdi=GDI:new(parent:getSide(),self)\
else\
self.gdi:setSide(parent:getSide())\
end\
parent:addChild(self)\
self:invalidate()\
end\
else\
if self.wnd__parent then\
self:invalidate()\
self.wnd__parent:removeChild(self)\
self.wnd__parent=nil\
end\
end\
end\
function window:destroyWnd()\
if self.wnd__alive then\
self.wnd__alive=false\
local success,msg=pcall(self.onDestroyWnd,self)\
if not success then\
syslog(\"onDestroyWnd \"..msg)\
end\
self:show(false)\
self:unwantMessages()\
if self.wnd__popup then\
self.wnd__popup:destroyWnd()\
end\
if self.wnd__owner then\
self.wnd__owner.wnd__popup=nil\
self.wnd__owner:enable(true)\
end\
if self:capturedMouse()==self then\
self:releaseMouse()\
end\
if self:getDesktop()then\
if self:getDesktop().dt__dragWnd==self then\
self:getDesktop().dt__dragWnd=nil\
end\
end\
if self:getFocus()==self then\
local frame=self:getParentFrame()\
if frame then\
frame:setFocusWnd(nil)\
end\
end\
self:getWorkSpace():unwantEvent(self,nil)\
self:getWorkSpace():killTimers(self)\
for i=self:children(),1,-1 do\
local child=self:getChild(i)\
if child then\
child:destroyWnd()\
end\
end\
self:setParent(nil)\
end\
end\
function window:getWorkSpace()\
return __ccwin\
end\
function window:getDesktop()\
return self:getWorkSpace():getDesktop(self:getSide())\
end\
function window:getParentFrame()\
local parent=self:getParent()\
while parent do\
if parent.wnd__frameClass~=FRAME_CLASS_WINDOW then\
return parent\
end\
parent=parent:getParent()\
end\
return nil\
end\
function window:getAppFrame()\
local parent=self:getParent()\
local desktop=self:getDesktop()\
if(self.wnd__frameClass==FRAME_CLASS_APPLICATION or\
self.wnd__frameClass==FRAME_CLASS_SYSTEM)\
and parent==desktop then\
return self\
end\
if self.wnd__owner then\
parent=self.wnd__owner\
end\
while parent do\
if(parent.wnd__frameClass==FRAME_CLASS_APPLICATION or\
parent.wnd__frameClass==FRAME_CLASS_SYSTEM)\
and parent:getParent()==desktop then\
return parent\
end\
if parent.wnd__owner then\
parent=parent.wnd__owner\
else\
parent=parent:getParent()\
end\
end\
return nil\
end\
function window:getTheme()\
if self:getDesktop()then\
return self:getDesktop():getTheme()\
end\
return __defaultTheme\
end\
function window:getColors()\
return self:getTheme().color\
end\
function window:getSide()\
if self.gdi then\
return self.gdi:getSide()\
end\
return \"\"\
end\
function window:hasScrollBars()\
local vert,horz,width,height=\
false,false,self.width,self.height\
if self.wnd__scrollHeight>self.height then\
vert=true\
width=self.width-1\
end\
if self.wnd__scrollWidth>width then\
horz=true\
height=self.height-1\
end\
vert=(self.wnd__scrollHeight>height)\
return vert,horz\
end\
function window:getClientSize()\
local vert,horz=self:hasScrollBars()\
local width,height=self.width,self.height\
if vert then\
width=self.width-1\
end\
if horz then\
height=self.height-1\
end\
return width,height\
end\
function window:getScrollOrg()\
return self.wnd__scrollX,self.wnd__scrollY\
end\
function window:setScrollOrg(x,y)\
local width,height=self:getClientSize()\
local tx,ty=x,y\
if(tx+width)>self.wnd__scrollWidth then\
tx=self.wnd__scrollWidth-width\
end\
if tx<0 or self.wnd__scrollWidth<=width then\
tx=0\
end\
if(ty+height)>self.wnd__scrollHeight then\
ty=self.wnd__scrollHeight-height\
end\
if ty<0 or self.wnd__scrollHeight<=height then\
ty=0\
end\
if tx~=self.wnd__scrollX or ty~=self.wnd__scrollY then\
self.wnd__scrollX=tx\
self.wnd__scrollY=ty\
self:invalidate()\
local success,msg=pcall(self.onScroll,self)\
if not success then\
syslog(\"onScroll \"..msg)\
end\
end\
end\
function window:setScrollSize(width,height)\
if self.wnd__scrollWidth~=width or\
self.wnd__scrollHeight~=height then\
self.wnd__scrollWidth=width\
self.wnd__scrollHeight=height\
if self.wnd__scrollWidth<0 then\
self.wnd__scrollWidth=0\
end\
if self.wnd__scrollHeight<0 then\
self.wnd__scrollHeight=0\
end\
self:setScrollOrg(self.wnd__scrollX,self.wnd__scrollY)\
self:invalidate()\
end\
end\
function window:getScrollSize()\
return self.wnd__scrollWidth,self.wnd__scrollHeight\
end\
function window:scrollLines(lines)\
self:setScrollOrg(self.wnd__scrollX,\
self.wnd__scrollY+lines)\
end\
function window:scrollCols(cols)\
self:setScrollOrg(self.wnd__scrollX+cols,\
self.wnd__scrollY)\
end\
function window:getWndRect()\
return rect:new(self.x,self.y,self.width,self.height)\
end\
function window:getScreenRect()\
local x,y=self:wndToScreen(0,0)\
return rect:new(x,y,self.width,self.height)\
end\
function window:wndAtPoint(x,y,recurse,disabled,hidden)\
if(self:isShown()or hidden)and(self:isEnabled()or disabled)then\
local sx,sy=self:screenToWnd(math.floor(x),math.floor(y))\
local rt=rect:new(0,0,self.width,self.height)\
if rt:contains(sx,sy)then\
for i=1,self:children(),1 do\
local wnd=self:getChild(i):wndAtPoint(x,y,recurse,disabled,hidden)\
if wnd then\
return wnd\
end\
end\
return self\
end\
end\
return nil\
end\
function window:wndFromPoint(x,y)\
local wnd=self:wndAtPoint(x,y,true,true,false)\
if wnd then\
if wnd:isEnabled()then\
return wnd\
end\
end\
return nil\
end\
function window:getWndById(id,recursive)\
for i=1,self:children(),1 do\
if self:getChild(i):getId()==id then\
return self:getChild(i)\
end\
end\
if recursive~=false then\
for i=1,self:children(),1 do\
local wnd=self:getChild(i):getWndById(id)\
if wnd then\
return wnd\
end\
end\
end\
return nil\
end\
function window:draw(gdi,bounds)\
end\
function window:update(force)\
if self:isShown()then\
if force then\
self:invalidate()\
end\
if not self.wnd__invalid:isEmpty()then\
self.gdi:store()\
local vert,horz=self:hasScrollBars()\
local zx,zy=self:getClientSize()\
if self:getBgColor()>0 then\
local rtErase=rect:new(0,0,zx,zy)\
rtErase:clip(self.wnd__invalid)\
self.gdi:setBackgroundColor(self:getBgColor())\
self.gdi:clearWnd(rtErase:unpack())\
else\
local rtBound=rect:new(self.wnd__invalid:unpack())\
rtBound.x,rtBound.y=self:wndToScreen(rtBound.x,rtBound.y)\
self.gdi:addBounds(rtBound)\
end\
self:draw(self.gdi,rect:new(self.wnd__invalid:unpack()))\
for i=self:children(),1,-1 do\
local child=self:getChild(i)\
if child:getScreenRect():overlap(self.gdi:getBounds())then\
self.gdi:addBounds(child:update(true))\
end\
end\
if vert or horz then\
local vertLeft=self.width-1\
local vertBottom=self.height-iif(horz,2,1)\
local horzTop=self.height-1\
local horzRight=self.width-iif(vert,2,1)\
if vert then\
self.gdi:setTextColor(self:getColors().scrollText)\
self.gdi:setBackgroundColor(self:getColors().scrollBack)\
if ccVersion()>=1.76 then\
self.gdi:writeWnd(string.char(30),vertLeft,0)\
self.gdi:writeWnd(string.char(31),vertLeft,vertBottom)\
else\
self.gdi:writeWnd(\"^\",vertLeft,0)\
self.gdi:writeWnd(\"v\",vertLeft,vertBottom)\
end\
self.gdi:setBackgroundColor(self:getColors().scrollTrack)\
for i=1,vertBottom-1,1 do\
self.gdi:writeWnd(\" \",vertLeft,i)\
end\
if vertBottom>3 then\
self.gdi:setBackgroundColor(self:getColors().scrollBack)\
self.gdi:writeWnd(\" \",vertLeft,\
math.floor((self.wnd__scrollY/(self.wnd__scrollHeight-zy))*(vertBottom-2))+1)\
end\
end\
if horz then\
self.gdi:setTextColor(self:getColors().scrollText)\
self.gdi:setBackgroundColor(self:getColors().scrollBack)\
if ccVersion()>=1.76 then\
self.gdi:writeWnd(string.char(17),0,horzTop)\
self.gdi:writeWnd(string.char(16),horzRight,horzTop)\
else\
self.gdi:writeWnd(\"<\",0,horzTop)\
self.gdi:writeWnd(\">\",horzRight,horzTop)\
end\
if horzRight>1 then\
self.gdi:setBackgroundColor(self:getColors().scrollTrack)\
self.gdi:writeWnd(string.rep(\" \",horzRight-1),1,horzTop)\
end\
if horzRight>3 then\
self.gdi:setBackgroundColor(self:getColors().scrollBack)\
self.gdi:writeWnd(\" \",\
math.floor((self.wnd__scrollX/(self.wnd__scrollWidth-zx))*(horzRight-2))+1,\
horzTop)\
end\
end\
if vert and horz then\
local corner=self:getColors().scrollTrack\
if self:getParent()then\
if self:getParent():getBgColor()~=0 then\
corner=self:getParent():getBgColor()\
end\
end\
self.gdi:setBackgroundColor(corner)\
self.gdi:writeWnd(\" \",vertLeft,horzTop)\
end\
end\
self:validate()\
self.gdi:restore()\
end\
return self.gdi:getBounds(true)\
end\
return rect:new()\
end\
function window:print(gdi,children,hidden)\
if self:isShown()or hidden then\
if self:getBgColor()>0 then\
gdi:setBackgroundColor(self:getBgColor())\
gdi:clear(self:getWndRect())\
end\
self:draw(gdi,self:getWndRect())\
if children then\
for i=self:children(),1,-1 do\
gdi:addBounds(self:getChild(i):print(gdi,children,hidden))\
end\
end\
end\
end\
function window:wndToScreen(x,y)\
return wndToScreen(self,x,y)\
end\
function window:screenToWnd(x,y)\
return screenToWnd(self,x,y)\
end\
function window:wndToScroll(x,y)\
return(x+self.wnd__scrollX),(y+self.wnd__scrollY)\
end\
function window:scrollToWnd(x,y)\
return(x-self.wnd__scrollX),(y-self.wnd__scrollY)\
end\
function window:getCursorPos()\
return self.wnd__cursorX,self.wnd__cursorY\
end\
function window:setCursorPos(x,y)\
local width,height=self:getClientSize()\
self.wnd__cursorX=x\
self.wnd__cursorY=y\
if self:getDesktop()then\
self:getDesktop().dt__cursorColor=self:getColor()\
end\
if(x-self.wnd__scrollX)>=0 and\
(x-self.wnd__scrollX)<width and\
(y-self.wnd__scrollY)>=0 and\
(y-self.wnd__scrollY)<height then\
self.gdi:setCursorPos(self:wndToScreen(x-self.wnd__scrollX,\
y-self.wnd__scrollY))\
self.gdi:setCursorBlink(true)\
else\
self.gdi:hideCursor()\
end\
end\
function window:captureMouse()\
if self:getDesktop()then\
self:getDesktop():captureMouse(self)\
end\
end\
function window:releaseMouse()\
if self:getDesktop()then\
self:getDesktop():captureMouse(nil)\
end\
end\
function window:capturedMouse()\
if self:getDesktop()then\
return self:getDesktop():capturedMouse()\
end\
return nil\
end\
function window:getClipboard()\
if self:getDesktop()then\
return self:getDesktop():getClipboard()\
end\
return CB_EMPTY,nil\
end\
function window:setClipboard(data,cbType)\
if self:getDesktop()then\
self:getDesktop():setClipboard(data,cbType)\
end\
end\
function window:setCursorBlink(blink)\
self.gdi:setCursorBlink(blink)\
end\
function window:hideCursor()\
self.gdi:hideCursor()\
end\
function window:showCursor()\
self:setCursorPos(self.wnd__cursorX,self.wnd__cursorY)\
end\
function window:startTimer(timeout)\
return self:getWorkSpace():startTimer(self,timeout)\
end\
function window:setAlarm(alarmTime)\
return self:getWorkSpace():setAlarm(self,alarmTime)\
end\
function window:getFocus()\
if self:getDesktop()then\
return self:getDesktop():getFocusWnd()\
end\
return nil\
end\
function window:setFocus()\
if self==self:getFocus()then\
return true\
end\
local frame=self:getParentFrame()\
if frame then\
return frame:setFocusWnd(self)\
end\
return false\
end\
function window:comboKeys(ctrl,alt,shift)\
return self:getWorkSpace():comboKeys(ctrl,alt,shift)\
end\
function window:hitTest(x,y)\
x=math.floor(x)\
y=math.floor(y)\
if x>=0 and y>=0 and x<self.width and y<self.height then\
local vert,horz=self:hasScrollBars()\
if vert then\
local height=self.height-1\
if horz then\
height=height-1\
end\
if x==self.width-1 then\
if y==0 then\
return HT_LINEUP\
end\
if y==height then\
return HT_LINEDOWN\
end\
if y<=math.floor(height/2)and y<height then\
return HT_PAGEUP\
end\
if y>math.floor(height/2)and y>0 then\
return HT_PAGEDOWN\
end\
end\
end\
if horz then\
local width=self.width-1\
if vert then\
width=width-1\
end\
if y==self.height-1 then\
if x==0 then\
return HT_LINELEFT\
end\
if x==width then\
return HT_LINERIGHT\
end\
if x<=math.floor(width/2)and x<width then\
return HT_PAGELEFT\
end\
if x>math.floor(width/2)and x>0 then\
return HT_PAGERIGHT\
end\
end\
end\
return HT_CLIENT\
end\
return HT_NOWHERE\
end\
function window:commEnabled()\
return self:getWorkSpace():commEnabled()\
end\
function window:sendMessage(recipient,application,context,data,name,wireless)\
return self:getWorkSpace():commSend(recipient,application,context,data,name,wireless)\
end\
function window:wantMessages(application,name,wireless)\
return self:getWorkSpace():commRegister(self,application,name,wireless)\
end\
function window:unwantMessages(application,name,wireless)\
return self:getWorkSpace():commUnregister(self,application,name,wireless)\
end\
function window:commFind(name,wireless)\
return self:getWorkSpace():commFind(name,wireless)\
end\
function window:commOpen(name,wireless,port,timeout,relay)\
return self:getWorkSpace():commOpen(name,wireless,port,timeout,relay)\
end\
function window:commClose(name)\
return self:getWorkSpace():commClose(name)\
end\
function window:routeChildEvent(wnd,event,p1,p2,p3,p4,p5,...)\
if event==\"timer\" then\
return false\
end\
if event==\"idle\" then\
return false\
end\
if event==\"focus\" then\
return self:onChildFocus(wnd,p1)\
end\
if event==\"blur\" then\
return self:onChildBlur(wnd,p1)\
end\
if event==\"mouse_click\" then\
if p1==2 then\
return self:onChildRightClick(wnd,p2,p3)\
elseif p1==3 then\
return self:onChildMiddleClick(wnd,p2,p3)\
end\
return self:onChildLeftClick(wnd,p2,p3)\
end\
if event==\"mouse_up\" then\
if p1==2 then\
return self:onChildRightUp(wnd,p2,p3)\
elseif p1==3 then\
return self:onChildMiddleUp(wnd,p2,p3)\
end\
return self:onChildLeftUp(wnd,p2,p3)\
end\
if event==\"char\" then\
return self:onChildChar(wnd,p1)\
end\
if event==\"key\" then\
return self:onChildKey(wnd,p1,p2,p3,p4)\
end\
if event==\"key_up\" then\
return self:onChildKeyUp(wnd,p1)\
end\
if event==\"mouse_scroll\" then\
return false\
end\
if event==\"mouse_drag\" then\
if p1==2 then\
return self:onChildRightDrag(wnd,p2,p3)\
elseif p1==3 then\
return self:onChildMiddleDrag(wnd,p2,p3)\
end\
return self:onChildLeftDrag(wnd,p2,p3)\
end\
if event==\"monitor_touch\" then\
return self:onChildTouch(wnd,p2,p3)\
end\
if event==\"monitor_resize\" then\
return false\
end\
if event==\"alarm\" then\
return false\
end\
if event==\"paste\" then\
return self:onChildPaste(wnd,p1)\
end\
if event==\"frame_close\" then\
return false\
end\
return self:onChildEvent(wnd,event,p1,p2,p3,p4,p5,...)\
end\
function window:routeWndEvent(event,p1,p2,p3,p4,p5,...)\
if event==\"timer\" then\
return self:onTimer(p1)\
end\
if event==\"idle\" then\
return self:onIdle(p1)\
end\
if event==\"vbar_scroll\" then\
return self:onVScroll(p1,p2)\
end\
if event==\"hbar_scroll\" then\
return self:onHScroll(p1,p2)\
end\
if event==\"mouse_scroll\" then\
return self:onScrollWheel(p1,self:screenToWnd(p2,p3))\
end\
if event==\"mouse_drag\" then\
if p1==2 then\
return self:onRightDrag(self:screenToWnd(p2,p3))\
elseif p1==3 then\
return self:onMiddleDrag(self:screenToWnd(p2,p3))\
end\
return self:onLeftDrag(self:screenToWnd(p2,p3))\
end\
if event==\"comm_receive\" then\
return self:onReceive(p1)\
end\
if event==\"comm_sent\" then\
return self:onSent(p1,p2)\
end\
if event==\"focus\" then\
return self:onFocus(p1)\
end\
if event==\"blur\" then\
return self:onBlur(p1)\
end\
if event==\"mouse_click\" then\
if p1==2 then\
return self:onRightClick(self:screenToWnd(p2,p3))\
elseif p1==3 then\
return self:onMiddleClick(self:screenToWnd(p2,p3))\
end\
return self:onLeftClick(self:screenToWnd(p2,p3))\
end\
if event==\"mouse_up\" then\
if p1==2 then\
return self:onRightUp(self:screenToWnd(p2,p3))\
elseif p1==3 then\
return self:onMiddleUp(self:screenToWnd(p2,p3))\
end\
return self:onLeftUp(self:screenToWnd(p2,p3))\
end\
if event==\"char\" then\
return self:onChar(p1)\
end\
if event==\"key\" then\
return self:onKey(p1,p2,p3,p4)\
end\
if event==\"key_up\" then\
return self:onKeyUp(p1)\
end\
if event==\"monitor_touch\" then\
return self:onTouch(self:screenToWnd(p2,p3))\
end\
if event==\"monitor_resize\" then\
return self:onResize()\
end\
if event==\"alarm\" then\
return self:onAlarm(p1)\
end\
if event==\"paste\" then\
return self:onPaste(p1)\
end\
if event==\"frame_close\" then\
return self:onFrameClose()\
end\
return self:onEvent(event,p1,p2,p3,p4,p5,...)\
end\
function window:routeEvent(wnd,event,...)\
local success,result;\
if self==wnd then\
success,result=pcall(self.routeWndEvent,self,event,...)\
else\
success,result=pcall(self.routeChildEvent,self,wnd,event,...)\
end\
self:getWorkSpace():startIdleTimer()\
if success then\
return result\
end\
if self:getAppFrame()then\
local title=self:getAppFrame():getText()\
if title:len()>0 then\
result=title..\"\\n\"..asstring(result)\
end\
end\
syslog(result)\
self:getDesktop():msgBox(\"Error\",result,colors.red)\
return false\
end\
function window:sendEvent(event,...)\
return self:routeEvent(self,event,...)\
end\
function window:wantEvent(event)\
return self:getWorkSpace():wantEvent(self,event)\
end\
function window:unwantEvent(event)\
return self:getWorkSpace():unwantEvent(self,event)\
end\
function window:onFocus(blurred)\
self:hideCursor()\
return false\
end\
function window:onBlur(focused)\
self:hideCursor()\
return false\
end\
function window:onIdle(idleCount)\
return false\
end\
function window:onLeftClick(x,y)\
if self:getWantFocus()then\
self:setFocus()\
end\
local htPos=self:hitTest(x,y)\
if htPos>HT_CLIENT then\
if htPos==HT_LINEUP then\
return self:sendEvent(\"vbar_scroll\",-1,false)\
end\
if htPos==HT_LINEDOWN then\
return self:sendEvent(\"vbar_scroll\",1,false)\
end\
if htPos==HT_PAGEUP then\
return self:sendEvent(\"vbar_scroll\",-1,true)\
end\
if htPos==HT_PAGEDOWN then\
return self:sendEvent(\"vbar_scroll\",1,true)\
end\
if htPos==HT_LINELEFT then\
return self:sendEvent(\"hbar_scroll\",-1,false)\
end\
if htPos==HT_LINERIGHT then\
return self:sendEvent(\"hbar_scroll\",1,false)\
end\
if htPos==HT_PAGELEFT then\
return self:sendEvent(\"hbar_scroll\",-1,true)\
end\
if htPos==HT_PAGERIGHT then\
return self:sendEvent(\"hbar_scroll\",1,true)\
end\
end\
return false\
end\
function window:onRightClick(x,y)\
if self:getWantFocus()then\
self:setFocus()\
end\
return false\
end\
function window:onMiddleClick(x,y)\
if self:getWantFocus()then\
self:setFocus()\
end\
return false\
end\
function window:onLeftUp(x,y)\
return false\
end\
function window:onRightUp(x,y)\
return false\
end\
function window:onMiddleUp(x,y)\
return false\
end\
function window:onChar(char)\
return false\
end\
function window:onPaste(text)\
return false\
end\
function window:onKey(key,ctrl,alt,shift)\
return false\
end\
function window:onKeyUp(key)\
return false\
end\
function window:onScrollWheel(direction,x,y)\
local width,height=self:getClientSize()\
if height<self.height and y==height then\
local cols=3\
if width<6 then\
cols=1\
end\
self:scrollCols(cols*direction)\
else\
local lines=3\
if height<6 then\
lines=1\
end\
self:scrollLines(lines*direction)\
end\
return true\
end\
function window:onVScroll(direction,page)\
local lines=1\
local width,height=self:getClientSize()\
if page then\
lines=height-1\
if lines<1 then\
lines=1\
end\
end\
self:scrollLines(lines*direction)\
return true\
end\
function window:onHScroll(direction,page)\
local lines=1\
local width,height=self:getClientSize()\
if page then\
lines=width-1\
if lines<1 then\
lines=1\
end\
end\
self:scrollCols(lines*direction)\
return true\
end\
function window:onLeftDrag(x,y)\
return false\
end\
function window:onRightDrag(x,y)\
return false\
end\
function window:onMiddleDrag(x,y)\
return false\
end\
function window:onTouch(x,y)\
if self:getWantFocus()then\
self:setFocus()\
end\
local htPos=self:hitTest(x,y)\
if htPos>HT_CLIENT then\
if htPos==HT_LINEUP then\
return self:sendEvent(\"vbar_scroll\",-1,false)\
end\
if htPos==HT_LINEDOWN then\
return self:sendEvent(\"vbar_scroll\",1,false)\
end\
if htPos==HT_PAGEUP then\
return self:sendEvent(\"vbar_scroll\",-1,true)\
end\
if htPos==HT_PAGEDOWN then\
return self:sendEvent(\"vbar_scroll\",1,true)\
end\
if htPos==HT_LINELEFT then\
return self:sendEvent(\"hbar_scroll\",-1,false)\
end\
if htPos==HT_LINERIGHT then\
return self:sendEvent(\"hbar_scroll\",1,false)\
end\
if htPos==HT_PAGELEFT then\
return self:sendEvent(\"hbar_scroll\",-1,true)\
end\
if htPos==HT_PAGERIGHT then\
return self:sendEvent(\"hbar_scroll\",1,true)\
end\
end\
if self:getWantKeyInput()~=KEYINPUT_NONE then\
if self.gdi:isMonitor()then\
if self:getDesktop()then\
self:getDesktop():doKeyboard(self)\
end\
end\
end\
return false\
end\
function window:onResize()\
return false\
end\
function window:onAlarm(id)\
return false\
end\
function window:onTimer(id)\
return false\
end\
function window:onMove()\
return false\
end\
function window:onFrameClose()\
return false\
end\
function window:onReceive(msg)\
return false\
end\
function window:onSent(msg,success)\
return false\
end\
function window:onEvent(event,p1,p2,p3,p4,p5,...)\
return false\
end\
function window:onDestroyWnd()\
end\
function window:onScroll()\
end\
function window:onChildFocus(wnd,blurred)\
return false\
end\
function window:onChildBlur(wnd,focused)\
return false\
end\
function window:onChildLeftClick(wnd,x,y)\
return false\
end\
function window:onChildRightClick(wnd,x,y)\
return false\
end\
function window:onChildMiddleClick(wnd,x,y)\
return false\
end\
function window:onChildLeftUp(wnd,x,y)\
return false\
end\
function window:onChildRightUp(wnd,x,y)\
return false\
end\
function window:onChildMiddleUp(wnd,x,y)\
return false\
end\
function window:onChildChar(wnd,char)\
return false\
end\
function window:onChildPaste(wnd,text)\
return false\
end\
function window:onChildKey(wnd,key,ctrl,alt,shift)\
return false\
end\
function window:onChildKeyUp(wnd,key)\
return false\
end\
function window:onChildLeftDrag(wnd,x,y)\
return false\
end\
function window:onChildRightDrag(wnd,x,y)\
return false\
end\
function window:onChildMiddleDrag(wnd,x,y)\
return false\
end\
function window:onChildTouch(wnd,x,y)\
return false\
end\
function window:onChildEvent(wnd,event,p1,p2,p3,p4,p5,...)\
return false\
end\
buttonWindow=window:base()\
function buttonWindow:constructor(parent,id,x,y,label)\
if not window.constructor(self,parent,id,x,y,\
asstring(label):len(),1)then\
return nil\
end\
self.btn__colors={\
text=self:getColors().buttonText,\
back=self:getColors().buttonBack,\
focus=self:getColors().buttonFocus\
}\
self:setText(label)\
self:setColor(self.btn__colors.text)\
self:setBgColor(self.btn__colors.back)\
return self\
end\
function buttonWindow:setColors(text,background,focus)\
self.btn__colors.text=text\
self.btn__colors.back=background\
self.btn__colors.focus=focus\
self:setColor(text)\
self:setBgColor(iif(self:getFocus()==self,focus,background))\
end\
function buttonWindow:draw(gdi,bounds)\
gdi:setBackgroundColor(self:getBgColor())\
gdi:setTextColor(self:getColor())\
gdi:write(self:getText(),0,0)\
end\
function buttonWindow:onFocus(blurred)\
self:hideCursor()\
self:setBgColor(self.btn__colors.focus)\
return false\
end\
function buttonWindow:onBlur(focused)\
self:setBgColor(self.btn__colors.back)\
return false\
end\
function buttonWindow:onKey(key,ctrl,alt,shift)\
if not ctrl and not alt and not shift then\
if key==keys.enter then\
self:onLeftClick(0,0)\
end\
end\
return true\
end\
function buttonWindow:onLeftClick(x,y)\
if window.onLeftClick(self,x,y)then\
return true\
end\
if self:getParent()then\
self:getParent():sendEvent(\"btn_click\",self)\
end\
return false\
end\
function buttonWindow:onTouch(x,y)\
if window.onTouch(self,x,y)then\
return true\
end\
if self:getParent()then\
self:getParent():sendEvent(\"btn_click\",self)\
end\
return false\
end\
inputWindow=window:base()\
function inputWindow:constructor(parent,id,x,y,width,text,banner)\
if not window.constructor(self,parent,id,x,y,width,1)then\
return nil\
end\
self.input__banner=\"\"\
self.input__oldText=\"\"\
self.input__maskChar=\"\"\
self.input__error=false\
self.input__hOrg=0\
self.input__end=0\
self.input__start=0\
self.input__maxLen=0\
self.input__colors={\
text=self:getColors().inputText,\
back=self:getColors().inputBack,\
focus=self:getColors().inputFocus,\
error=self:getColors().inputError,\
banner=self:getColors().inputBanner\
}\
self:setColor(self.input__colors.text)\
self:setBgColor(self.input__colors.back)\
self:setWantKeyInput(KEYINPUT_LINE)\
self:setBanner(banner)\
self:setText(text)\
return self\
end\
function inputWindow:setColors(text,background,focus,banner,errorColor)\
self.input__colors.text=text\
self.input__colors.back=background\
self.input__colors.focus=focus\
self.input__colors.error=errorColor\
self.input__colors.banner=banner\
self:setColor(text)\
self:setBgColor(iif(self:getFocus()==self,focus,background))\
end\
function inputWindow:setBanner(banner)\
self.input__banner=asstring(banner)\
self:invalidate()\
end\
function inputWindow:setMaskChar(char)\
self.input__maskChar=asstring(char)\
self:invalidate()\
end\
function inputWindow:getMaskChar()\
return self.input__maskChar\
end\
function inputWindow:getBanner()\
return self.input__banner\
end\
function inputWindow:getError()\
return self.input__error\
end\
function inputWindow:setError(bError)\
bError=(bError~=false)\
if bError~=self.input__error then\
self.input__error=bError\
self:setBgColor(iif(self.input__error,\
self.input__colors.error,\
iif(self:getFocus()==self,\
self.input__colors.focus,\
self.input__colors.back)))\
end\
end\
function inputWindow:setMaxLength(maxLen)\
self.input__maxLen=asnumber(maxLen)\
if self.input__maxLen<1 then\
self.input__maxLen=0\
end\
end\
function inputWindow:getMaxLength()\
return self.input__maxLen\
end\
function inputWindow:setSel(selStart,selEnd,autoScroll)\
local strLen=self:getText():len()\
selStart=asnumber(selStart)\
if selStart<0 then\
selStart=0\
elseif selStart>strLen then\
selStart=strLen\
end\
if selEnd==nil then\
selEnd=selStart\
elseif selEnd==-1 then\
selEnd=strLen\
elseif selEnd<0 then\
selEnd=0\
elseif selEnd>strLen then\
selEnd=strLen\
end\
self.input__end=selEnd\
self.input__start=selStart\
if autoScroll~=false then\
if(self.input__end-self.input__hOrg)<=0 then\
self.input__hOrg=self.input__end-math.floor(self.width/2)\
if self.input__hOrg<0 then\
self.input__hOrg=0\
end\
end\
if(self.input__end-self.input__hOrg)>=self.width then\
self.input__hOrg=self.input__end-self.width+1\
end\
end\
self:invalidate()\
if self:getFocus()==self then\
self:setCursorPos(self.input__end-self.input__hOrg,0)\
end\
end\
function inputWindow:getSel(normalise)\
if normalise then\
if self.input__end<self.input__start then\
return self.input__end,self.input__start\
end\
end\
return self.input__start,self.input__end\
end\
function inputWindow:replaceSel(replaceText,autoScroll)\
local ss,se=self:getSel(true)\
local str=self:getText():sub(1,ss)..asstring(replaceText)..\
self:getText():sub(se+1)\
if self.input__maxLen>0 then\
if str:len()>self.input__maxLen then\
str=str:sub(1,self.input__maxLen)\
end\
end\
self:setText(str)\
se=ss+asstring(replaceText):len()\
self:setSel(se,se,autoScroll)\
end\
function inputWindow:getSelection()\
local ss,se=self:getSel(true)\
return self:getText():sub((ss+1),se)\
end\
function inputWindow:cut()\
local strSel=self:getSelection()\
if strSel:len()>0 then\
self:setClipboard(strSel,CB_TEXT)\
self:replaceSel(\"\")\
end\
end\
function inputWindow:copy()\
local strSel=self:getSelection()\
if strSel:len()>0 then\
self:setClipboard(strSel,CB_TEXT)\
end\
end\
function inputWindow:paste()\
local cbType,cbData=self:getClipboard()\
if cbType==CB_TEXT then\
self:replaceSel(cbData)\
end\
end\
function inputWindow:draw(gdi,bounds)\
gdi:setBackgroundColor(self:getBgColor())\
if self:getText():len()==0 then\
if self:getBanner():len()>0 then\
gdi:setTextColor(self.input__colors.banner)\
gdi:write(self:getBanner(),0,0)\
end\
else\
local displayText;\
local ss,se=self:getSel(true)\
if self.input__maskChar:len()>0 then\
displayText=string.rep(self.input__maskChar,self:getText():len())\
else\
displayText=self:getText()\
end\
if ss==se then\
gdi:setTextColor(self:getColor())\
gdi:write(displayText,(self.input__hOrg*-1),0)\
else\
local left=(self.input__hOrg*-1)\
local strPre,strSel,strPost=\
displayText:sub(1,ss),\
displayText:sub(ss+1,se),\
displayText:sub(se+1)\
gdi:setTextColor(self:getColor())\
gdi:write(strPre,left,0)\
left=left+strPre:len()\
gdi:setBackgroundColor(self:getColors().selectedBack)\
gdi:setTextColor(self:getColors().selectedText)\
gdi:write(strSel,left,0)\
left=left+strSel:len()\
gdi:setBackgroundColor(self:getBgColor())\
gdi:setTextColor(self:getColor())\
gdi:write(strPost,left,0)\
end\
end\
end\
function inputWindow:setText(text)\
window.setText(self,text)\
local ss,se=self:getSel(false)\
local strLen=self:getText():len()\
if ss>strLen then\
ss=strLen\
end\
if se>strLen then\
se=strLen\
end\
self:setSel(ss,se)\
end\
function inputWindow:onFocus(blurred)\
self:setBgColor(iif(self.input__error,\
self.input__colors.error,\
self.input__colors.focus))\
self:setCursorPos(self.input__end-self.input__hOrg,0)\
self.input__oldText=self:getText()\
return false\
end\
function inputWindow:onBlur(focused)\
self:hideCursor()\
self:setBgColor(iif(self.input__error,\
self.input__colors.error,\
self.input__colors.back))\
if self.input__oldText~=self:getText()then\
if self:getParent()then\
self:getParent():sendEvent(\"input_change\",self)\
end\
end\
return false\
end\
function inputWindow:onKey(key,ctrl,alt,shift)\
if not ctrl and not alt and not shift then\
local ss,se=self:getSel(false)\
if key==keys.backspace then\
if ss==se then\
self:setSel(ss-1,ss,false)\
end\
self:replaceSel(\"\")\
return true\
elseif key==keys.delete then\
if ss==se then\
self:setSel(ss,ss+1,false)\
end\
self:replaceSel(\"\")\
return true\
elseif key==keys.left then\
if se>=1 then\
self:setSel(se-1,se-1)\
end\
return true\
elseif key==keys.right then\
self:setSel(se+1,se+1)\
return true\
elseif key==keys.home then\
self:setSel(0,0)\
return true\
elseif key==207 then \
self:setSel(self:getText():len(),-1)\
return true\
end\
elseif not ctrl and not alt and shift then\
local ss,se=self:getSel(false)\
if key==keys.left then\
if se>=1 then\
self:setSel(ss,se-1)\
end\
return true\
elseif key==keys.right then\
self:setSel(ss,se+1)\
return true\
elseif key==keys.home then\
self:setSel(ss,0)\
return true\
elseif key==207 then \
self:setSel(ss,-1)\
return true\
end\
elseif ctrl and not alt and not shift then\
if key==keys.x then\
self:cut()\
return true\
elseif key==keys.c then\
self:copy()\
return true\
elseif key==keys.b then\
self:paste()\
return true\
elseif key==keys.a then\
self:setSel(0,-1)\
return true\
end\
end\
return false\
end\
function inputWindow:onChar(char)\
self:replaceSel(char)\
return true\
end\
function inputWindow:onLeftClick(x,y)\
if window.onLeftClick(self,x,y)then\
return true\
end\
self:setSel(x+self.input__hOrg,x+self.input__hOrg)\
return true\
end\
function inputWindow:onLeftDrag(x,y)\
local ss,se=self:getSel(false)\
self:setSel(ss,x+self.input__hOrg)\
return true\
end\
function inputWindow:onTouch(x,y)\
if window.onTouch(self,x,y)then\
return true\
end\
self:setSel(x+self.input__hOrg,x+self.input__hOrg)\
return true\
end\
function inputWindow:onMove()\
if self:getFocus()==self then\
self:showCursor()\
end\
return false\
end\
function inputWindow:onPaste(text)\
if asstring(text):len()>0 then\
self:replaceSel(asstring(text))\
end\
return true\
end\
labelWindow=window:base()\
function labelWindow:constructor(parent,id,x,y,label)\
if not window.constructor(self,parent,id,x,y,\
asstring(label):len(),1)then\
return nil\
end\
self:setText(label)\
self:setWantFocus(false)\
self:setColor(self:getColors().frameText)\
self:setBgColor(self:getColors().frameBack)\
return self\
end\
function labelWindow:draw(gdi,bounds)\
gdi:setBackgroundColor(self:getBgColor())\
gdi:setTextColor(self:getColor())\
gdi:write(self:getText(),0,0)\
end\
listWindow=window:base()\
function listWindow:constructor(parent,id,x,y,width,height)\
if not window.constructor(self,parent,id,x,y,width,height)then\
return nil\
end\
self.list__selIndex=0\
self.list__clickTime=-1\
self.list__clickX=-1\
self.list__clickY=-1\
self.list__colors={\
text=self:getColors().wndText,\
back=self:getColors().wndBack,\
focus=self:getColors().wndFocus,\
selectedText=self:getColors().selectedText,\
selectedBack=self:getColors().selectedBack\
}\
self.list__items={}\
self:setColor(self.list__colors.text)\
self:setBgColor(self.list__colors.back)\
return self\
end\
function listWindow:setColors(text,background,focus,selectedText,selectedBack)\
self.list__colors.text=text\
self.list__colors.back=background\
self.list__colors.focus=focus\
self.list__colors.selectedText=selectedText\
self.list__colors.selectedBack=selectedBack\
self:setColor(text)\
self:setBgColor(iif(self:getFocus()==self,focus,background))\
end\
function listWindow:count()\
return #self.list__items\
end\
function listWindow:addString(str,data,index)\
local i=index\
if i==nil then\
i=self:count()+1\
elseif i<1 or i>(self:count()+1)then\
i=self:count()+1\
end\
table.insert(self.list__items,i,{asstring(str),data})\
self:setScrollSize(self.wnd__scrollWidth,self:count())\
end\
function listWindow:removeString(index)\
if index==nil then\
return false\
elseif index<1 or index>self:count()then\
return false\
end\
table.remove(self.list__items,index)\
self:setScrollSize(self.wnd__scrollWidth,self:count())\
return true\
end\
function listWindow:resetContent()\
self.list__items={}\
self.list__selIndex=0\
self:setScrollSize(self.wnd__scrollWidth,0)\
end\
function listWindow:getCurSel()\
if self.list__selIndex>=0 and\
self.list__selIndex<=self:count()then\
return self.list__selIndex\
end\
return 0\
end\
function listWindow:setCurSel(index,makeVisible)\
local i=index\
if i==nil then\
i=0\
end\
if i>self:count()then\
i=self:count()\
end\
if i>=0 and i<=self:count()and\
i~=self.list__selIndex then\
self.list__selIndex=i\
if makeVisible~=false then\
self:ensureVisible()\
end\
self:invalidate()\
if self:getParent()then\
self:getParent():sendEvent(\"selection_change\",self)\
end\
return true\
end\
return false\
end\
function listWindow:getString(index)\
local i=index\
if i==nil then\
i=self:getCurSel()\
end\
if i>0 and i<=self:count()then\
return self.list__items[i][1]\
end\
return nil\
end\
function listWindow:getData(index)\
local i=index\
if i==nil then\
i=self:getCurSel()\
end\
if i>0 and i<=self:count()then\
return self.list__items[i][2]\
end\
return nil\
end\
local function list_sorterAscending(string1,string2)\
return(string1[1]<string2[1])\
end\
local function list_sorterDecending(string1,string2)\
return(string1[1]>string2[1])\
end\
function listWindow:sort(decending)\
if decending then\
table.sort(self.list__items,list_sorterDecending)\
else\
table.sort(self.list__items,list_sorterAscending)\
end\
self:invalidate()\
end\
function listWindow:ensureVisible(index)\
local top=index\
if top==nil then\
top=self:getCurSel()\
end\
if top>=1 and top<=self:count()then\
local width,height=self:getClientSize()\
local orgX,orgY=self:getScrollOrg()\
if top<=orgY then\
self:setScrollOrg(orgX,top-1)\
elseif top>(orgY+height)then\
self:setScrollOrg(orgX,top-height)\
end\
end\
end\
function listWindow:find(str,from,exact)\
str=asstring(str)\
from=asnumber(from)+1\
for i=from,self:count(),1 do\
local item=self:getString(i)\
if not exact then\
item=item:sub(1,str:len())\
end\
if str==item then\
return i\
end\
end\
return 0\
end\
function listWindow:setString(str,index)\
local i=index\
if i==nil then\
i=self:getCurSel()\
end\
if i>0 and i<=self:count()then\
self.list__items[i][1]=asstring(str)\
self:invalidate()\
return true\
end\
return false\
end\
function listWindow:setData(data,index)\
local i=index\
if i==nil then\
i=self:getCurSel()\
end\
if i>0 and i<=self:count()then\
self.list__items[i][2]=data\
return true\
end\
return false\
end\
function listWindow:draw(gdi,bounds)\
local first,last;\
first=self.wnd__scrollY+1\
last=self:count()\
if(last-first+1)>self.height then\
last=first+self.height\
end\
for i=first,last,1 do\
if i==self:getCurSel()then\
gdi:setBackgroundColor(self.list__colors.selectedBack)\
gdi:setTextColor(self.list__colors.selectedText)\
gdi:clear(0,i-1,self.width,1)\
else\
gdi:setBackgroundColor(self:getBgColor())\
gdi:setTextColor(self:getColor())\
end\
gdi:write(self:getString(i),0,i-1)\
end\
end\
function listWindow:onFocus(blurred)\
self:hideCursor()\
self:setBgColor(self.list__colors.focus)\
return false\
end\
function listWindow:onBlur(focused)\
self:setBgColor(self.list__colors.back)\
return false\
end\
function listWindow:onKey(key,ctrl,alt,shift)\
if not ctrl and not alt and not shift then\
if key==keys.enter then\
if self:getParent()then\
if(os.clock()-self.list__clickTime)<=self:getTheme().doubleClick and\
self.list__clickX==-2 and self.list__clickY==-2 then\
self.list__clickX=-1\
self.list__clickY=-1\
self.list__clickTime=-1\
self:getParent():sendEvent(\"list_double_click\",self)\
else\
self.list__clickX=-2\
self.list__clickY=-2\
self.list__clickTime=os.clock()\
self:getParent():sendEvent(\"list_click\",self)\
end\
end\
return true\
elseif key==keys.up then\
if self:getCurSel()>1 then\
self:setCurSel(self:getCurSel()-1)\
end\
return true\
elseif key==keys.down then\
self:setCurSel(self:getCurSel()+1)\
return true\
elseif key==keys.pageUp then\
local width,height=self:getClientSize()\
self:setCurSel(iif((self:getCurSel()-(height-1))<1,\
1,(self:getCurSel()-(height-1))))\
return true\
elseif key==keys.pageDown then\
local width,height=self:getClientSize()\
self:setCurSel(self:getCurSel()+(height-1))\
return true\
elseif key==keys.home then\
self:setCurSel(1)\
return true\
elseif key==207 then \
self:setCurSel(self:count())\
return true\
end\
elseif ctrl and not alt and not shift then\
if key==keys.up then\
self:sendEvent(\"vbar_scroll\",-1,false)\
return true\
elseif key==keys.down then\
self:sendEvent(\"vbar_scroll\",1,false)\
return true\
elseif key==keys.left then\
self:sendEvent(\"hbar_scroll\",-1,false)\
return true\
elseif key==keys.right then\
self:sendEvent(\"hbar_scroll\",1,false)\
return true\
elseif key==keys.pageUp then\
self:sendEvent(\"vbar_scroll\",-1,true)\
return true\
elseif key==keys.pageDown then\
self:sendEvent(\"vbar_scroll\",1,true)\
return true\
elseif key==keys.home then\
self:setScrollOrg(0,0)\
return true\
elseif key==207 then \
self:setScrollOrg(0,self:count())\
return true\
end\
end\
return false\
end\
function listWindow:onLeftClick(x,y)\
if window.onLeftClick(self,x,y)then\
return true\
end\
local sx,sy=self:wndToScroll(x,y)\
local item=sy+1\
if item>=1 and item<=self:count()then\
self:setCurSel(item)\
if self:getParent()then\
if(os.clock()-self.list__clickTime)<=self:getTheme().doubleClick and\
self.list__clickX==sx and self.list__clickY==sy then\
self.list__clickX=-1\
self.list__clickY=-1\
self.list__clickTime=-1\
self:getParent():sendEvent(\"list_double_click\",self)\
else\
self.list__clickX=sx\
self.list__clickY=sy\
self.list__clickTime=os.clock()\
self:getParent():sendEvent(\"list_click\",self)\
end\
end\
end\
return true\
end\
function listWindow:onTouch(x,y)\
if window.onTouch(self,x,y)then\
return true\
end\
local sx,sy=self:wndToScroll(x,y)\
local item=sy+1\
if item>=1 and item<=self:count()then\
self:setCurSel(item)\
if self:getParent()then\
if(os.clock()-self.list__clickTime)<=self:getTheme().doubleClick and\
self.list__clickX==sx and self.list__clickY==sy then\
self.list__clickX=-1\
self.list__clickY=-1\
self.list__clickTime=-1\
self:getParent():sendEvent(\"list_double_click\",self)\
else\
self.list__clickX=sx\
self.list__clickY=sy\
self.list__clickTime=os.clock()\
self:getParent():sendEvent(\"list_click\",self)\
end\
end\
end\
return true\
end\
checkWindow=window:base()\
function checkWindow:constructor(parent,id,x,y,label,checked)\
if not window.constructor(self,parent,id,x,y,\
asstring(label):len()+2,1)then\
return nil\
end\
self.check__checked=(checked==true)\
self.check__colors={\
text=self:getColors().frameText,\
back=self:getColors().frameBack,\
focus=self:getColors().frameBack,\
checkText=self:getColors().checkText,\
checkBack=self:getColors().checkBack,\
checkFocus=self:getColors().checkFocus\
}\
self:setText(label)\
self:setColor(self.check__colors.text)\
self:setBgColor(self.check__colors.back)\
return self\
end\
function checkWindow:setColors(text,background,focus,checkText,checkBack,checkFocus)\
self.check__colors.text=text\
self.check__colors.back=background\
self.check__colors.focus=focus\
self.check__colors.checkText=checkText\
self.check__colors.checkBack=checkBack\
self.check__colors.checkFocus=checkFocus\
self:setColor(text)\
self:setBgColor(iif(self:getFocus()==self,focus,background))\
end\
function checkWindow:getChecked()\
return self.check__checked\
end\
function checkWindow:setChecked(check)\
check=(check~=false)\
if self.check__checked~=check then\
self.check__checked=check\
if self:getParent()then\
self:getParent():sendEvent(\"check_change\",self)\
end\
self:invalidate()\
end\
end\
function checkWindow:draw(gdi,bounds)\
if self==self:getFocus()then\
gdi:setBackgroundColor(self.check__colors.checkFocus)\
else\
gdi:setBackgroundColor(self.check__colors.checkBack)\
end\
gdi:setTextColor(self.check__colors.checkText)\
if self:getChecked()then\
gdi:write(\"x\",0,0)\
else\
gdi:write(\" \",0,0)\
end\
gdi:setBackgroundColor(self:getBgColor())\
gdi:setTextColor(self:getColor())\
gdi:write(\" \",1,0)\
gdi:write(self:getText(),2,0)\
end\
function checkWindow:onFocus(blurred)\
self:hideCursor()\
self:setBgColor(self.check__colors.focus)\
return false\
end\
function checkWindow:onBlur(focused)\
self:setBgColor(self.check__colors.back)\
return false\
end\
function checkWindow:onKey(key,ctrl,alt,shift)\
if not ctrl and not alt and not shift then\
if key==keys.enter then\
self:onLeftClick(0,0)\
end\
return true\
end\
return false\
end\
function checkWindow:onLeftClick(x,y)\
if window.onLeftClick(self,x,y)then\
return true\
end\
self:setChecked(not self:getChecked())\
return true\
end\
function checkWindow:onTouch(x,y)\
if window.onTouch(self,x,y)then\
return true\
end\
self:setChecked(not self:getChecked())\
return true\
end\
textWindow=window:base()\
function textWindow:constructor(parent,id,x,y,width,height,label)\
if not window.constructor(self,parent,id,x,y,width,height)then\
return nil\
end\
self.txtWnd__lines={}\
self:setWantFocus(false)\
self:setColor(self:getColors().frameText)\
self:setBgColor(self:getColors().frameBack)\
self:setText(label)\
return self\
end\
function textWindow:calcSize()\
self.txtWnd__lines=string.wrap(self:getText(),self.width)\
if #self.txtWnd__lines>self.height then\
self.txtWnd__lines=string.wrap(self:getText(),self.width-1)\
self:setScrollSize(0,#self.txtWnd__lines)\
else\
self:setScrollSize(0,0)\
end\
end\
function textWindow:draw(gdi,bounds)\
local first,last;\
first=self.wnd__scrollY+1\
last=#self.txtWnd__lines\
if(last-first+1)>self.height then\
last=first+self.height\
end\
gdi:setBackgroundColor(self:getBgColor())\
gdi:setTextColor(self:getColor())\
for i=first,last,1 do\
gdi:write(self.txtWnd__lines[i],0,i-1)\
end\
end\
function textWindow:onMove()\
self:calcSize()\
return false\
end\
function textWindow:setText(text)\
window.setText(self,text)\
self:calcSize()\
end\
local editUndo=__classBase:base()\
EU_REPLACE=0\
EU_TYPE=1\
EU_DELETE=2\
EU_BACKSPACE=3\
function editUndo:constructor()\
self.eu__cache={}\
self.eu__index=0\
return self\
end\
function editUndo:reset()\
self.eu__cache={}\
self.eu__index=0\
end\
function editUndo:endAction()\
if #self.eu__cache>0 then\
self.eu__cache[#self.eu__cache].action=EU_REPLACE\
end\
end\
function editUndo:record(pos,inserted,removed,action)\
if action~=EU_REPLACE and self.eu__index>0 and\
self.eu__index==#self.eu__cache and\
self.eu__cache[self.eu__index].action==action then\
if action==EU_TYPE then\
local cache=self.eu__cache[self.eu__index].inserted\
cache[#cache]=cache[#cache]..inserted[1]\
for i=2,#inserted,1 do\
cache[#cache+1]=inserted[i]\
end\
return\
elseif action==EU_DELETE then\
local cache=self.eu__cache[self.eu__index].removed\
cache[#cache]=cache[#cache]..removed[1]\
for i=2,#removed,1 do\
cache[#cache+1]=removed[i]\
end\
return\
elseif action==EU_BACKSPACE then\
local cache=self.eu__cache[self.eu__index].removed\
cache[1]=removed[#removed]..cache[1]\
for i=1,#removed-1,1 do\
table.insert(cache,1,removed[i])\
end\
self.eu__cache[self.eu__index].pos=pos\
return\
end\
end\
while #self.eu__cache>self.eu__index do\
table.remove(self.eu__cache,#self.eu__cache)\
end\
self:endAction()\
self.eu__index=#self.eu__cache+1\
self.eu__cache[self.eu__index]=\
{\
pos=pos,\
inserted=inserted,\
removed=removed,\
action=action\
}\
end\
function editUndo:canUndo()\
return self.eu__index>0\
end\
function editUndo:canRedo()\
return self.eu__index<#self.eu__cache\
end\
function editUndo:undo()\
local data;\
if self:canUndo()then\
self:endAction()\
data=self.eu__cache[self.eu__index]\
self.eu__index=self.eu__index-1\
end\
return data\
end\
function editUndo:redo()\
local data;\
if self:canRedo()then\
self:endAction()\
self.eu__index=self.eu__index+1\
data=self.eu__cache[self.eu__index]\
end\
return data\
end\
local function edit_textToTable(text)\
local tabText={}\
local last=1\
local pos=text:find(\"[\\r\\n]\",last)\
while pos do\
tabText[#tabText+1]=text:sub(last,pos-1)\
if text:byte(pos)==13 then\
if text:byte(pos+1)==10 then\
pos=pos+1\
end\
end\
last=pos+1\
pos=text:find(\"[\\r\\n]\",last)\
end\
tabText[#tabText+1]=text:sub(last)\
return tabText\
end\
local function edit_tableToText(tabText,eol)\
local str;\
if type(tabText[1])==\"table\" then\
str=tabText[1].str\
for line=2,#tabText,1 do\
str=str..eol..tabText[line].str\
end\
else\
str=tabText[1]\
for line=2,#tabText,1 do\
str=str..eol..tabText[line]\
end\
end\
return str\
end\
local function edit_countChars(tabText,longEOL)\
local eol=iif(longEOL,2,1)\
local len=0\
if type(tabText[1])==\"table\" then\
len=tabText[1].len\
for line=2,#tabText,1 do\
len=len+tabText[line].len+eol\
end\
else\
len=tabText[1]:len()\
for line=2,#tabText,1 do\
len=len+tabText[line]:len()+eol\
end\
end\
return len\
end\
editWindow=window:base()\
function editWindow:constructor(parent,id,x,y,width,height,text,banner)\
if not window.constructor(self,parent,id,x,y,width,height)then\
return nil\
end\
self.edit__data={{len=0,str=\"\"}}\
self.edit__banner=\"\"\
self.edit__modified=false\
self.edit__error=false\
self.edit__end=0\
self.edit__start=0\
self.edit__tab=0\
self.edit__cursorCol=0\
self.edit__readOnly=false\
self.edit__fireEvents=false\
self.edit__undo=editUndo:new()\
self.edit__colors={\
text=self:getColors().inputText,\
back=self:getColors().inputBack,\
focus=self:getColors().inputFocus,\
error=self:getColors().inputError,\
banner=self:getColors().inputBanner\
}\
self:setColor(self.edit__colors.text)\
self:setBgColor(self.edit__colors.back)\
self:setWantKeyInput(KEYINPUT_EDIT)\
self:setBanner(banner)\
self:setText(text)\
self.edit__fireEvents=true\
return self\
end\
function editWindow:setColors(text,background,focus,banner,errorColor)\
self.edit__colors.text=text\
self.edit__colors.back=background\
self.edit__colors.focus=focus\
self.edit__colors.error=errorColor\
self.edit__colors.banner=banner\
self:setColor(text)\
self:setBgColor(iif(self:getFocus()==self,focus,background))\
end\
function editWindow:setBanner(banner)\
self.edit__banner=asstring(banner)\
self:invalidate()\
end\
function editWindow:getBanner()\
return self.edit__banner\
end\
function editWindow:getError()\
return self.edit__error\
end\
function editWindow:setError(bError)\
bError=(bError~=false)\
if bError~=self.edit__error then\
self.edit__error=bError\
self:setBgColor(iif(self.edit__error,\
self.edit__colors.error,\
iif(self:getFocus()==self,\
self.edit__colors.focus,\
self.edit__colors.back)))\
end\
end\
function editWindow:setModified(modified,fireEvent)\
modified=(modified~=false)\
if(modified and not self.edit__modified)or\
(self.edit__modified and not modified)then\
self.edit__modified=modified\
if fireEvent~=false then\
if self:getParent()and self.edit__fireEvents then\
self:getParent():sendEvent(\"modified\",self)\
end\
end\
end\
end\
function editWindow:getModified()\
return self.edit__modified\
end\
function editWindow:getTabWidth()\
return self.edit__tab\
end\
function editWindow:setTabWidth(chars)\
self.edit__tab=math.floor(asnumber(chars))\
end\
function editWindow:getReadOnly()\
return self.edit__readOnly\
end\
function editWindow:setReadOnly(readOnly)\
self.edit__readOnly=readOnly~=false\
end\
function editWindow:lines()\
return #self.edit__data\
end\
function editWindow:getTextLength(longEOL)\
return edit_countChars(self.edit__data,longEOL)\
end\
function editWindow:lineIndex(line)\
local index=0\
line=iif(line<0,1,line+1)\
if line>(#self.edit__data+1)then\
line=#self.edit__data+1\
end\
for i=1,line-1,1 do\
index=index+self.edit__data[i].len+1\
end\
if line==(#self.edit__data+1)then\
index=index-1\
end\
return index\
end\
function editWindow:lineFromChar(char)\
local index,prior=0,0\
if char<0 then\
char=0\
end\
for line=1,#self.edit__data,1 do\
if char<index then\
return(line-2),(char-prior)\
end\
prior=index\
index=index+self.edit__data[line].len+1\
end\
char=char-prior\
if char>self.edit__data[#self.edit__data].len then\
char=self.edit__data[#self.edit__data].len\
end\
return(#self.edit__data-1),char\
end\
function editWindow:charFromPoint(x,y)\
local char,line=x,y+1\
if line>#self.edit__data then\
line=#self.edit__data\
elseif line<1 then\
line=1\
end\
if char>self.edit__data[line].len then\
char=self.edit__data[line].len\
elseif char<0 then\
char=0\
end\
if line>1 then\
char=char+self:lineIndex(line-1)\
end\
return char\
end\
function editWindow:setSel(selStart,selEnd,autoScroll)\
local strLen=self:getTextLength()\
selStart=asnumber(selStart)\
if selStart==-1 then\
selStart=strLen\
elseif selStart<0 then\
selStart=0\
elseif selStart>strLen then\
selStart=strLen\
end\
if selEnd==nil then\
selEnd=selStart\
elseif selEnd==-1 then\
selEnd=strLen\
elseif selEnd<0 then\
selEnd=0\
elseif selEnd>strLen then\
selEnd=strLen\
end\
self.edit__end=selEnd\
self.edit__start=selStart\
self:invalidate(0,0,self:getClientSize())\
if autoScroll~=false then\
local zx,zy=self:getClientSize()\
local sx,sy=self:getScrollOrg()\
local line,char=self:lineFromChar(selEnd)\
if(char-sx)<0 then\
sx=char-math.floor(zx/4)\
elseif char>=(sx+zx)then\
sx=char-zx+1\
end\
if(line-sy)<0 then\
sy=line\
elseif line>=(sy+zy)then\
sy=line-zy+1\
end\
self:setScrollOrg(sx,sy)\
end\
if self:getFocus()==self then\
local y,x=self:lineFromChar(self.edit__end)\
self:setCursorPos(x,y)\
end\
if self:getParent()and self.edit__fireEvents then\
self:getParent():sendEvent(\"selection_change\",self)\
end\
end\
function editWindow:getSel(normalise)\
if normalise then\
if self.edit__end<self.edit__start then\
return self.edit__end,self.edit__start\
end\
end\
return self.edit__start,self.edit__end\
end\
function editWindow:getSelection()\
local sel={}\
local ss,se=self:getSel(true)\
if ss~=se then\
local sline,schar=self:lineFromChar(ss)\
local eline,echar=self:lineFromChar(se)\
if sline==eline then\
sel[1]=self.edit__data[sline+1].str:sub(schar+1,echar)\
else\
sel[1]=self.edit__data[sline+1].str:sub(schar+1)\
for line=sline+2,eline,1 do\
sel[#sel+1]=self.edit__data[line].str\
end\
sel[#sel+1]=self.edit__data[eline+1].str:sub(1,echar)\
end\
else\
sel[1]=\"\"\
end\
return sel\
end\
function editWindow:getSelectedText(eol)\
return edit_tableToText(self:getSelection(),eol or \"\\n\")\
end\
function editWindow:updateScrollSize()\
local width=0\
for i=1,#self.edit__data,1 do\
if self.edit__data[i].len>=width then\
width=self.edit__data[i].len+1\
end\
end\
self:setScrollSize(width,#self.edit__data)\
end\
function editWindow:replaceSelTabled(insert,autoScroll,undoAction)\
local ss,se=self:getSel(true)\
local sline,schar=self:lineFromChar(ss)\
local removed={}\
local insertChars=edit_countChars(insert,false)\
if ss~=se then\
local eline,echar=self:lineFromChar(se)\
if sline==eline then\
removed[1]=self.edit__data[sline+1].str:sub(schar+1,echar)\
self.edit__data[sline+1].str=\
self.edit__data[sline+1].str:sub(1,schar)..\
self.edit__data[sline+1].str:sub(echar+1)\
self.edit__data[sline+1].len=self.edit__data[sline+1].str:len()\
else\
removed[1]=self.edit__data[sline+1].str:sub(schar+1)\
self.edit__data[sline+1].str=\
self.edit__data[sline+1].str:sub(1,schar)\
for line=sline+2,eline,1 do\
removed[#removed+1]=self.edit__data[sline+2].str\
table.remove(self.edit__data,sline+2)\
end\
removed[#removed+1]=self.edit__data[sline+2].str:sub(1,echar)\
self.edit__data[sline+1].str=\
self.edit__data[sline+1].str..\
self.edit__data[sline+2].str:sub(echar+1)\
table.remove(self.edit__data,sline+2)\
self.edit__data[sline+1].len=self.edit__data[sline+1].str:len()\
end\
else\
removed[1]=\"\"\
end\
if #insert==1 then\
if insert[1]:len()>0 then\
if insert[1]:len()==1 then\
self.edit__data[sline+1].str=\
self.edit__data[sline+1].str:sub(1,schar)..\
insert[1]..\
self.edit__data[sline+1].str:sub(schar+1)\
self.edit__data[sline+1].len=self.edit__data[sline+1].len+1\
else\
self.edit__data[sline+1].str=\
self.edit__data[sline+1].str:sub(1,schar)..\
insert[1]..\
self.edit__data[sline+1].str:sub(schar+1)\
self.edit__data[sline+1].len=self.edit__data[sline+1].len+insert[1]:len()\
end\
end\
else\
table.insert(self.edit__data,sline+2,\
{len=0,str=(insert[#insert]..self.edit__data[sline+1].str:sub(schar+1))})\
self.edit__data[sline+2].len=self.edit__data[sline+2].str:len()\
self.edit__data[sline+1].str=\
self.edit__data[sline+1].str:sub(1,schar)..\
insert[1]\
self.edit__data[sline+1].len=self.edit__data[sline+1].str:len()\
for line=2,#insert-1,1 do\
table.insert(self.edit__data,sline+line,{len=insert[line]:len(),str=insert[line]})\
end\
end\
if undoAction then\
self.edit__undo:record(ss,insert,removed,undoAction)\
end\
self:updateScrollSize()\
self:setSel(ss+insertChars,ss+insertChars,autoScroll)\
self:setModified()\
self.edit__cursorCol=self:getCursorPos()\
end\
function editWindow:replaceSel(replaceText,autoScroll)\
self:replaceSelTabled(edit_textToTable(asstring(replaceText)),autoScroll,EU_REPLACE)\
end\
function editWindow:cut()\
local strSel=self:getSelectedText()\
if strSel:len()>0 then\
self:setClipboard(strSel,CB_TEXT)\
self:replaceSelTabled({\"\"},nil,EU_REPLACE)\
self.edit__cursorCol=self:getCursorPos()\
end\
end\
function editWindow:copy()\
local strSel=self:getSelectedText()\
if strSel:len()>0 then\
self:setClipboard(strSel,CB_TEXT)\
end\
end\
function editWindow:paste()\
local cbType,cbData=self:getClipboard()\
if cbType==CB_TEXT then\
self:replaceSel(cbData)\
self.edit__cursorCol=self:getCursorPos()\
end\
end\
function editWindow:draw(gdi,bounds)\
if #self.edit__data==1 and self.edit__data[1].len==0 then\
if self:getBanner():len()>0 then\
gdi:setBackgroundColor(self:getBgColor())\
gdi:setTextColor(self.edit__colors.banner)\
gdi:write(self:getBanner(),0,0)\
end\
else\
local ss,se=self:getSel(true)\
local lastLine,firstLine=self:wndToScroll(bounds.x,bounds.y)\
lastLine=firstLine+bounds.height-1\
if firstLine<0 then\
firstLine=0\
elseif firstLine>=#self.edit__data then\
firstLine=#self.edit__data-1\
end\
if lastLine<0 then\
lastLine=0\
elseif lastLine>=#self.edit__data then\
lastLine=#self.edit__data-1\
end\
if lastLine>=firstLine then\
if ss==se then\
gdi:setBackgroundColor(self:getBgColor())\
gdi:setTextColor(self:getColor())\
for line=firstLine,lastLine,1 do\
gdi:write(self.edit__data[line+1].str,0,line)\
end\
else\
local sline,schar=self:lineFromChar(ss)\
local eline,echar=self:lineFromChar(se)\
if sline==eline then\
for line=firstLine,lastLine,1 do\
if line==sline then\
gdi:setBackgroundColor(self:getBgColor())\
gdi:setTextColor(self:getColor())\
gdi:write(self.edit__data[line+1].str:sub(1,schar),0,line)\
gdi:setBackgroundColor(self:getColors().selectedBack)\
gdi:setTextColor(self:getColors().selectedText)\
gdi:write(self.edit__data[line+1].str:sub(schar+1,echar),schar,line)\
gdi:setBackgroundColor(self:getBgColor())\
gdi:setTextColor(self:getColor())\
gdi:write(self.edit__data[line+1].str:sub(echar+1),echar,line)\
else\
gdi:setBackgroundColor(self:getBgColor())\
gdi:setTextColor(self:getColor())\
gdi:write(self.edit__data[line+1].str,0,line)\
end\
end\
else\
for line=firstLine,lastLine,1 do\
if line==sline then\
gdi:setBackgroundColor(self:getBgColor())\
gdi:setTextColor(self:getColor())\
gdi:write(self.edit__data[line+1].str:sub(1,schar),0,line)\
gdi:setBackgroundColor(self:getColors().selectedBack)\
gdi:setTextColor(self:getColors().selectedText)\
gdi:write((self.edit__data[line+1].str..\" \"):sub(schar+1),schar,line)\
elseif line==eline then\
gdi:setBackgroundColor(self:getColors().selectedBack)\
gdi:setTextColor(self:getColors().selectedText)\
gdi:write(self.edit__data[line+1].str:sub(1,echar),0,line)\
gdi:setBackgroundColor(self:getBgColor())\
gdi:setTextColor(self:getColor())\
gdi:write(self.edit__data[line+1].str:sub(echar+1),echar,line)\
else\
if line>sline and line<eline then\
gdi:setBackgroundColor(self:getColors().selectedBack)\
gdi:setTextColor(self:getColors().selectedText)\
gdi:write(self.edit__data[line+1].str..\" \",0,line)\
else\
gdi:setBackgroundColor(self:getBgColor())\
gdi:setTextColor(self:getColor())\
gdi:write(self.edit__data[line+1].str,0,line)\
end\
end\
end\
end\
end\
end\
end\
end\
function editWindow:setText(text)\
self:setSel(0,-1,false)\
self:replaceSel(asstring(text))\
self:setSel(-1,-1)\
self:setModified(false)\
self.edit__undo:reset()\
end\
function editWindow:canUndo()\
return self.edit__undo:canUndo()\
end\
function editWindow:canRedo()\
return self.edit__undo:canRedo()\
end\
function editWindow:undo()\
local data=self.edit__undo:undo()\
if data then\
self:setSel(data.pos,data.pos+edit_countChars(data.inserted,false),false)\
self:replaceSelTabled(data.removed)\
self.edit__cursorCol=self:getCursorPos()\
end\
end\
function editWindow:redo()\
local data=self.edit__undo:redo()\
if data then\
self:setSel(data.pos,data.pos+edit_countChars(data.removed,false),false)\
self:replaceSelTabled(data.inserted)\
self.edit__cursorCol=self:getCursorPos()\
end\
end\
function editWindow:getText(eol)\
return edit_tableToText(self.edit__data,eol or \"\\n\")\
end\
function editWindow:onFocus(blurred)\
self:setBgColor(iif(self.edit__error,\
self.edit__colors.error,\
self.edit__colors.focus))\
self:showCursor()\
return false\
end\
function editWindow:onBlur(focused)\
self:hideCursor()\
self:setBgColor(iif(self.edit__error,\
self.edit__colors.error,\
self.edit__colors.back))\
return false\
end\
function editWindow:onKey(key,ctrl,alt,shift)\
if not ctrl and not alt and not shift then\
local ss,se=self:getSel(false)\
if key==keys.backspace then\
if not self:getReadOnly()then\
if ss==se then\
if ss>0 then\
self:setSel(ss-1,ss,false)\
self:replaceSelTabled({\"\"},nil,EU_BACKSPACE)\
end\
else\
self:replaceSelTabled({\"\"},nil,EU_BACKSPACE)\
end\
end\
return true\
elseif key==keys.delete then\
if not self:getReadOnly()then\
if ss==se then\
self:setSel(ss,ss+1,false)\
end\
self:replaceSelTabled({\"\"},nil,EU_DELETE)\
end\
return true\
elseif key==keys.enter then\
if not self:getReadOnly()then\
self:replaceSelTabled({\"\",\"\"},nil,EU_TYPE)\
end\
return true\
elseif key==keys.tab then\
if not self:getReadOnly()and self:getTabWidth()>0 then\
local line,offset=self:lineFromChar((self:getSel(true)))\
offset=self:getTabWidth()-math.fmod(offset,self:getTabWidth())\
self:replaceSelTabled({string.rep(\" \",offset)},nil,EU_TYPE)\
end\
return true\
elseif key==keys.left then\
if se>0 then\
self:setSel(se-1,se-1)\
self.edit__undo:endAction()\
self.edit__cursorCol=self:getCursorPos()\
end\
return true\
elseif key==keys.right then\
self:setSel(se+1,se+1)\
self.edit__undo:endAction()\
self.edit__cursorCol=self:getCursorPos()\
return true\
elseif key==keys.up then\
local y,x=self:lineFromChar(se)\
if y>0 then\
y=self:charFromPoint(self.edit__cursorCol,y-1)\
self:setSel(y,y)\
self.edit__undo:endAction()\
end\
return true\
elseif key==keys.down then\
local y,x=self:lineFromChar(se)\
if y<self:lines()then\
y=self:charFromPoint(self.edit__cursorCol,y+1)\
self:setSel(y,y)\
self.edit__undo:endAction()\
end\
return true\
elseif key==keys.pageUp then\
local y,x=self:lineFromChar(se)\
if y>0 then\
local zx,zy=self:getClientSize()\
y=y-zy+1\
y=self:charFromPoint(self.edit__cursorCol,iif(y<0,0,y))\
self:setSel(y,y)\
self.edit__undo:endAction()\
end\
return true\
elseif key==keys.pageDown then\
local y,x=self:lineFromChar(se)\
if y<self:lines()then\
local zx,zy=self:getClientSize()\
y=y+zy-1\
y=self:charFromPoint(self.edit__cursorCol,iif(y>=self:lines(),self:lines()-1,y))\
self:setSel(y,y)\
self.edit__undo:endAction()\
end\
return true\
elseif key==keys.home then\
se=self:lineIndex((self:lineFromChar(se)))\
self:setSel(se,se)\
self.edit__undo:endAction()\
self.edit__cursorCol=self:getCursorPos()\
return true\
elseif key==207 then \
local line=self:lineFromChar(se)\
se=self:lineIndex(line+1)\
if line<(self:lines()-1)then\
se=se-1\
end\
self:setSel(se,se)\
self.edit__undo:endAction()\
self.edit__cursorCol=self:getCursorPos()\
return true\
end\
elseif not ctrl and not alt and shift then\
local ss,se=self:getSel(false)\
if key==keys.left then\
if se>0 then\
self:setSel(ss,se-1)\
self.edit__undo:endAction()\
self.edit__cursorCol=self:getCursorPos()\
end\
return true\
elseif key==keys.right then\
self:setSel(ss,se+1)\
self.edit__undo:endAction()\
self.edit__cursorCol=self:getCursorPos()\
return true\
elseif key==keys.up then\
local y,x=self:lineFromChar(se)\
if y>0 then\
self:setSel(ss,self:charFromPoint(self.edit__cursorCol,y-1))\
self.edit__undo:endAction()\
end\
return true\
elseif key==keys.down then\
local y,x=self:lineFromChar(se)\
if y<self:lines()then\
self:setSel(ss,self:charFromPoint(self.edit__cursorCol,y+1))\
self.edit__undo:endAction()\
end\
return true\
elseif key==keys.pageUp then\
local y,x=self:lineFromChar(se)\
if y>0 then\
local zx,zy=self:getClientSize()\
y=y-zy+1\
self:setSel(ss,self:charFromPoint(self.edit__cursorCol,iif(y<0,0,y)))\
self.edit__undo:endAction()\
end\
return true\
elseif key==keys.pageDown then\
local y,x=self:lineFromChar(se)\
if y<self:lines()then\
local zx,zy=self:getClientSize()\
y=y+zy-1\
self:setSel(ss,self:charFromPoint(self.edit__cursorCol,iif(y>=self:lines(),self:lines()-1,y)))\
self.edit__undo:endAction()\
end\
return true\
elseif key==keys.home then\
self:setSel(ss,self:lineIndex((self:lineFromChar(se))))\
self.edit__undo:endAction()\
self.edit__cursorCol=self:getCursorPos()\
return true\
elseif key==207 then \
local line=self:lineFromChar(se)\
se=self:lineIndex(line+1)\
if line<(self:lines()-1)then\
se=se-1\
end\
self:setSel(ss,se)\
self.edit__undo:endAction()\
self.edit__cursorCol=self:getCursorPos()\
return true\
end\
elseif ctrl and not alt and not shift then\
if key==keys.x then\
if not self:getReadOnly()then\
self:cut()\
end\
return true\
elseif key==keys.c then\
self:copy()\
return true\
elseif key==keys.b then\
if not self:getReadOnly()then\
self:paste()\
end\
return true\
elseif key==keys.z then\
if not self:getReadOnly()then\
self:undo()\
end\
return true\
elseif key==keys.y then\
if not self:getReadOnly()then\
self:redo()\
end\
return true\
elseif key==keys.a then\
self:setSel(0,-1,false)\
self.edit__undo:endAction()\
self.edit__cursorCol=self:getCursorPos()\
return true\
elseif key==keys.up then\
self:sendEvent(\"vbar_scroll\",-1,false)\
return true\
elseif key==keys.down then\
self:sendEvent(\"vbar_scroll\",1,false)\
return true\
elseif key==keys.left then\
self:sendEvent(\"hbar_scroll\",-1,false)\
return true\
elseif key==keys.right then\
self:sendEvent(\"hbar_scroll\",1,false)\
return true\
elseif key==keys.pageUp then\
self:sendEvent(\"vbar_scroll\",-1,true)\
return true\
elseif key==keys.pageDown then\
self:sendEvent(\"vbar_scroll\",1,true)\
return true\
elseif key==keys.home then\
self:setScrollOrg(0,0)\
return true\
elseif key==207 then \
self:setScrollOrg(0,self:lines())\
return true\
end\
end\
return false\
end\
function editWindow:onChar(char)\
if not self:getReadOnly()then\
self:replaceSelTabled({char},nil,EU_TYPE)\
end\
return true\
end\
function editWindow:onLeftClick(x,y)\
if window.onLeftClick(self,x,y)then\
return true\
end\
local char=self:charFromPoint(self:wndToScroll(x,y))\
self:setSel(char,char)\
self.edit__undo:endAction()\
self.edit__cursorCol=self:getCursorPos()\
return true\
end\
function editWindow:onLeftDrag(x,y)\
local ss,se=self:getSel(false)\
self:setSel(ss,self:charFromPoint(self:wndToScroll(x,y)))\
self.edit__undo:endAction()\
self.edit__cursorCol=self:getCursorPos()\
return true\
end\
function editWindow:onTouch(x,y)\
if window.onTouch(self,x,y)then\
return true\
end\
local char=self:charFromPoint(self:wndToScroll(x,y))\
self:setSel(char,char)\
self.edit__undo:endAction()\
self.edit__cursorCol=self:getCursorPos()\
return true\
end\
function editWindow:onMove()\
if self:getFocus()==self then\
self:showCursor()\
end\
return false\
end\
function editWindow:onPaste(text)\
if asstring(text):len()>0 then\
if not self:getReadOnly()then\
self:replaceSel(asstring(text))\
end\
end\
return true\
end\
function editWindow:onScroll()\
if self:getFocus()==self then\
self:showCursor()\
end\
end\
menuWindow=listWindow:base()\
function menuWindow:constructor(parent)\
if not listWindow.constructor(self,parent,0,0,0,0,0)then\
return nil\
end\
self:setColors(self:getColors().menuText,\
self:getColors().menuBack,\
self:getColors().menuBack,\
self:getColors().menuSelectedText,\
self:getColors().menuSelectedBack)\
self:show(false)\
return self\
end\
function menuWindow:track(x,y)\
local width,height=0,self:count()\
local rt=(self:getParent()and self:getParent():getWndRect())or nil\
for i=1,self:count(),1 do\
local len=self.list__items[i][1]:len()\
if len>width then\
width=len\
end\
end\
if rt then\
if height>rt.height then\
y=0\
height=rt.height\
width=width+1\
elseif(y+height)>rt.height then\
y=rt.height-height\
end\
if width>rt.width then\
x=0\
width=rt.width\
elseif(x+width)>rt.width then\
x=rt.width-width\
end\
end\
self.list__colors.focus=self.list__colors.back\
self:move(x,y,width,height,WND_TOP)\
self:setCurSel(self:nextValidItem(0))\
self:show(true)\
self:setFocus()\
self:captureMouse()\
end\
function menuWindow:addString(str,data,index)\
listWindow.addString(self,str,asnumber(data),index)\
end\
function menuWindow:setCurSel(index,makeVisible)\
local i=index\
if i==nil then\
i=0\
end\
if i>self:count()then\
i=self:count()\
end\
if i>=0 and i<=self:count()and i~=self.list__selIndex then\
self.list__selIndex=i\
if makeVisible~=false then\
self:ensureVisible()\
end\
self:invalidate()\
return true\
end\
return false\
end\
function menuWindow:nextValidItem(from)\
for i=asnumber(from)+1,self:count(),1 do\
if asnumber(self:getData(i))~=0 then\
return i\
end\
end\
return asnumber(from)\
end\
function menuWindow:priorValidItem(from)\
for i=asnumber(from)-1,1,-1 do\
if asnumber(self:getData(i))~=0 then\
return i\
end\
end\
return asnumber(from)\
end\
function menuWindow:onBlur(focused)\
self:destroyWnd()\
return true\
end\
function menuWindow:onKey(key,ctrl,alt,shift)\
if not ctrl and not alt and not shift then\
if key==keys.enter then\
local parent=self:getParent()\
self:destroyWnd()\
if parent then\
parent:sendEvent(\"menu_cmd\",self:getData())\
end\
return true\
end\
if key==keys.up then\
self:setCurSel(self:priorValidItem(self:getCurSel()))\
return true\
end\
if key==keys.down then\
self:setCurSel(self:nextValidItem(self:getCurSel()))\
return true\
end\
if key==keys.home then\
self:setCurSel(self:nextValidItem(0))\
return true\
end\
if key==207 then \
self:setCurSel(self:priorValidItem(self:count()+1))\
return true\
end\
elseif not alt and not shift then\
if key==keys.leftCtrl or key==keys.rightCtrl then\
self:destroyWnd()\
return true\
end\
end\
return false\
end\
function menuWindow:onLeftClick(x,y)\
if window.onLeftClick(self,x,y)then\
return true\
end\
local rtWnd=rect:new(0,0,self.width,self.height)\
if rtWnd:contains(x,y)then\
local sx,sy=self:wndToScroll(x,y)\
if self:getData(sy+1)~=0 then\
local parent=self:getParent()\
self:setCurSel(sy+1)\
self:destroyWnd()\
if parent then\
parent:sendEvent(\"menu_cmd\",self:getData())\
end\
end\
else\
self:destroyWnd()\
end\
return true\
end\
function menuWindow:onTouch(x,y)\
if window.onTouch(self,x,y)then\
return true\
end\
local rtWnd=rect:new(0,0,self.width,self.height)\
if rtWnd:contains(x,y)then\
local sx,sy=self:wndToScroll(x,y)\
if self:getData(sy+1)~=0 then\
local parent=self:getParent()\
self:setCurSel(sy+1)\
self:destroyWnd()\
if parent then\
parent:sendEvent(\"menu_cmd\",self:getData())\
end\
end\
else\
self:destroyWnd()\
end\
return true\
end\
closeButtonWindow=buttonWindow:base()\
function closeButtonWindow:constructor(parent,x,y)\
local label=__defaultTheme.closeBtnChar\
if parent then\
label=parent:getTheme().closeBtnChar\
end\
if not buttonWindow.constructor(self,parent,ID_CLOSE,x,y,label)then\
return nil\
end\
self:setColors(self:getColors().closeText,\
self:getColors().closeBack,\
self:getColors().closeFocus)\
return self\
end\
function closeButtonWindow:onLeftClick(x,y)\
if window.onLeftClick(self,x,y)then\
return true\
end\
if self:getParent()then\
self:getParent():sendEvent(\"frame_close\")\
end\
return false\
end\
function closeButtonWindow:onTouch(x,y)\
if window.onTouch(self,x,y)then\
return true\
end\
if self:getParent()then\
self:getParent():sendEvent(\"frame_close\")\
end\
return false\
end\
local parentFrame=window:base()\
popupFrame=parentFrame:base()\
function popupFrame:constructor(ownerFrame,width,height)\
assert(ownerFrame,\"popupFrame:new() must have an owner frame.\")\
assert(ownerFrame.onFrameActivate,\
\"popupFrame:new() must have an owner frame.\")\
assert(ownerFrame.wnd__popup==nil,\
\"popupFrame:new() owner frame already has popup.\")\
width=asnumber(width)\
height=asnumber(height)\
local desktop=ownerFrame:getDesktop()\
local rtWork=desktop:getWorkArea()\
local popupWidth,popupHeight=width,height\
if width>rtWork.width then\
popupWidth=rtWork.width\
end\
if height>rtWork.height then\
popupHeight=rtWork.height\
end\
if not parentFrame.constructor(self,desktop,ID_DIALOG,\
math.floor((rtWork.width-popupWidth)/2),\
math.floor((rtWork.height-popupHeight)/2),\
popupWidth,popupHeight)then\
return nil\
end\
self.wnd__owner=ownerFrame\
ownerFrame.wnd__popup=self\
self.wnd__frameClass=FRAME_CLASS_DIALOG\
self:setColor(desktop:getColors().popupText)\
self:setBgColor(desktop:getColors().popupBack)\
return self\
end\
function popupFrame:onCreate(...)\
return true\
end\
function popupFrame:onClose()\
return false\
end\
function popupFrame:close(result)\
if self:onClose()then\
return false\
end\
self:endModal(result)\
return true\
end\
function popupFrame:onResize()\
self:move()\
return true\
end\
function popupFrame:move(x,y,width,height)\
local rtWork=self:getDesktop():getWorkArea()\
if not width then\
width=self.width\
end\
if width>rtWork.width then\
width=rtWork.width\
end\
if not height then\
height=self.height\
end\
if height>rtWork.height then\
height=rtWork.height\
end\
if not x then\
x=math.floor((rtWork.width-width)/2)\
end\
if not y then\
y=math.floor((rtWork.height-height)/2)\
end\
if x<rtWork.x then\
x=rtWork.x\
end\
if y<rtWork.y then\
y=rtWork.y\
end\
if(x+width)>(rtWork.x+rtWork.width)then\
x=(rtWork.x+rtWork.width)-width\
end\
if(y+height)>(rtWork.y+rtWork.height)then\
y=(rtWork.y+rtWork.height)-height\
end\
parentFrame.move(self,x,y,width,height)\
end\
function popupFrame:onMove()\
parentFrame.onMove(self)\
local xBtn=self:getWndById(ID_CLOSE)\
if xBtn then\
xBtn:move(self.width-1)\
end\
return false\
end\
function popupFrame:onFrameClose()\
self:close(ID_CLOSE)\
return true\
end\
function popupFrame:dress(titleText)\
self:setText(titleText)\
closeButtonWindow:new(self,self.width-1,0):setFocus()\
local titleBar=labelWindow:new(self,ID_TITLEBAR,1,0,titleText)\
titleBar:setBgColor(titleBar:getColors().titleBack)\
titleBar:setColor(titleBar:getColors().titleText)\
end\
function popupFrame:draw(gdi,bounds)\
if ccVersion()>=1.76 then\
if self:getWndById(ID_TITLEBAR)then\
gdi:setBackgroundColor(self:getColors().titleBack)\
gdi:clear(0,0,self.width,1)\
if self.width>2 and self.height>2 then\
local edge=string.char(149)\
gdi:setBackgroundColor(self:getColors().titleBack)\
gdi:setTextColor(self:getBgColor())\
gdi:writeWnd(string.char(138)..string.rep(string.char(143),self.width-2)..string.char(133),0,self.height-1)\
for l=1,self.height-2,1 do\
gdi:writeWnd(edge,self.width-1,l)\
end\
gdi:setBackgroundColor(self:getBgColor())\
gdi:setTextColor(self:getColors().titleBack)\
for l=1,self.height-2,1 do\
gdi:writeWnd(edge,0,l)\
end\
end\
end\
else\
if bounds.y<1 then\
if self:getWndById(ID_TITLEBAR)then\
gdi:setBackgroundColor(self:getColors().titleBack)\
gdi:clear(0,0,self.width,1)\
end\
end\
end\
end\
function popupFrame:setTitle(titleText)\
local tText=self:getWndById(ID_TITLEBAR)\
self:setText(titleText)\
if tText then\
tText:setText(titleText)\
tText:move(nil,nil,tText:getText():len())\
end\
end\
function popupFrame:doModal(...)\
local result;\
local enabled=true\
local success,result=pcall(self.onCreate,self,...)\
if success then\
if result then\
enabled=self.wnd__owner:isEnabled()\
self.wnd__owner:enable(false)\
self.wnd__owner:setActiveTopFrame()\
result=self:runModal()\
end\
end\
if self.wnd__owner then\
local owner=self.wnd__owner\
while owner do\
owner:invalidate()\
owner=owner.wnd__owner\
end\
self.wnd__owner:enable(enabled)\
self.wnd__owner.wnd__popup=nil\
self.wnd__owner:setActiveTopFrame()\
self.wnd__owner.wnd__popup=self\
end\
self:destroyWnd()\
if not success then\
error(result,0)\
end\
return result\
end\
local msgBoxFrame=popupFrame:base()\
function msgBoxFrame:onCreate(titleText,message)\
title=asstring(title)\
message=asstring(message)\
local desktop=self:getDesktop()\
local rtWork=desktop:getWorkArea()\
local maxWidth,maxHeight=math.floor(rtWork.width*0.8),\
math.floor(rtWork.height*0.8)\
local width,height=string.wrapSize(string.wrap(message,maxWidth-2))\
if width==(maxWidth-2)and height>=(maxHeight-3)then\
width,height=string.wrapSize(string.wrap(message,maxWidth-3))\
end\
width=width+2\
height=height+3\
if width<(title:len()+3)then\
width=title:len()+3\
end\
if height<4 then\
height=4\
elseif height>maxHeight then\
height=maxHeight\
end\
self:dress(titleText)\
textWindow:new(self,ID_MSGBOX_MSG,1,2,width-2,height-3,message)\
self:setBgColor(self:getBgColor())\
self:move(nil,nil,width,height)\
return true\
end\
function msgBoxFrame:onResize()\
popupFrame.onResize(self)\
local msg=self:getWndById(ID_MSGBOX_MSG)\
if msg then\
msg:move(1,2,self.width-2,self.height-3)\
end\
return true\
end\
function msgBoxFrame:setBgColor(color)\
popupFrame.setBgColor(self,color)\
local msg=self:getWndById(ID_MSGBOX_MSG)\
if msg then\
msg:setBgColor(color)\
end\
end\
printData=__classBase:base()\
function printData:constructor(printer,fromPage,toPage,pages,title,userData)\
self.printer=asstring(printer)\
self.fromPage=asnumber(fromPage)\
self.toPage=asnumber(toPage)\
self.pages=asnumber(pages)\
self.title=asstring(title)\
self.data=userData\
return self\
end\
applicationFrame=parentFrame:base()\
function applicationFrame:constructor(side)\
local desktop=__ccwin:getDesktop(side)\
local rtWork=desktop:getWorkArea()\
if not parentFrame.constructor(self,desktop,ID_FRAME,rtWork:unpack())then\
return nil\
end\
self.wnd__frameClass=FRAME_CLASS_APPLICATION\
self.appFrame__appRoutine=nil\
self.appFrame__appPath=nil\
self.appFrame__yieldPoint=\"modal\"\
return self\
end\
function applicationFrame:onCreate()\
return true\
end\
function applicationFrame:getAppPath()\
return self.appFrame__appPath\
end\
function applicationFrame:onResize()\
self:move(self:getDesktop():getWorkArea():unpack())\
local tText=self:getWndById(ID_TITLEBAR)\
if tText then\
tText:move(math.floor((self.width-tText:getText():len())/2))\
end\
local xBtn=self:getWndById(ID_CLOSE)\
if xBtn then\
xBtn:move(self.width-1)\
end\
return true\
end\
function applicationFrame:quitApp()\
if self:onQuit()then\
return\
end\
self:endModal(0)\
end\
function applicationFrame:onQuit()\
return false\
end\
function applicationFrame:onFrameClose()\
self:quitApp()\
return true\
end\
function applicationFrame:dress(titleText)\
self:setText(titleText)\
closeButtonWindow:new(self,self.width-1,0):setFocus()\
local titleBar=labelWindow:new(self,ID_TITLEBAR,\
math.floor((self.width-titleText:len())/2),\
0,titleText)\
titleBar:setBgColor(titleBar:getColors().titleBack)\
titleBar:setColor(titleBar:getColors().titleText)\
end\
function applicationFrame:draw(gdi,bounds)\
if bounds.y<1 then\
if self:getWndById(ID_TITLEBAR)then\
gdi:setBackgroundColor(self:getColors().titleBack)\
gdi:clear(0,0,self.width,1)\
end\
end\
end\
function applicationFrame:setTitle(titleText)\
local tText=self:getWndById(ID_TITLEBAR)\
self:setText(titleText)\
if tText then\
tText:setText(titleText)\
tText:move(nil,nil,tText:getText():len())\
self:onResize()\
end\
end\
function applicationFrame:runApp()\
if self:onCreate()then\
self:runModal()\
end\
self:getDesktop():dropApp(self)\
end\
function applicationFrame:onPrintPage(gdi,page,data)\
return false\
end\
function applicationFrame:printLoop(data)\
if data then\
local continue=true\
local page=math.max(1,data.fromPage)\
local gdi=GDI:new(data.printer)\
assert(gdi,\"Failed to create printer GDI for \"..data.printer)\
while true do\
while not gdi:newPage()do\
if not cmndlg.confirm(self,\"Check Printer\",\
\"Ensure printer \\\"\"..gdi:getSide()..\
\"\\\" has paper and ink.\\nPress Ok to continue.\",\
true)then\
return\
end\
end\
continue=self:onPrintPage(gdi,page,data)\
if page==1 then\
gdi:setPageTitle(data.title)\
else\
gdi:setPageTitle(string.format(\"%s %d\",data.title,page))\
end\
page=page+1\
while not gdi:endPage()do\
if not cmndlg.confirm(self,\"Clear Tray\",\
\"Clear out tray on printer \\\"\"..gdi:getSide()..\
\"\\\".\\nPress Ok to continue.\",true)then\
return\
end\
end\
if not continue or(data.toPage>0 and page>data.toPage)then\
return\
end\
end\
end\
end\
function applicationFrame:onPrintData(title,userData,pages,bgcolor)\
local printer,fromPage,toPage=cmndlg.print(self,pages,bgcolor)\
if printer then\
return printData:new(printer,fromPage,toPage,pages,title,userData)\
end\
return nil\
end\
function applicationFrame:printDoc()\
self:printLoop(self:onPrintData())\
end\
function applicationFrame:status()\
local status=coroutine.status(self.appFrame__appRoutine)\
if status==\"suspended\" then\
return self.appFrame__yieldPoint\
end\
return status\
end\
function applicationFrame:resume(wnd,event,...)\
local status=self:status()\
local result=false\
local success=false\
local yieldPoint;\
if status==\"modal\" then\
success,yieldPoint,result=\
coroutine.resume(self.appFrame__appRoutine,wnd,event,...)\
elseif status==\"event\" then\
success,yieldPoint,result=\
coroutine.resume(self.appFrame__appRoutine,event,...)\
elseif status==\"sleep\" then\
if event==\"sleep\" then\
success,yieldPoint,result=\
coroutine.resume(self.appFrame__appRoutine,event)\
end\
elseif status==\"dead\" then\
self:getDesktop():msgBox(\"Error\",\
self:getText()..\" was not responding.\",colors.red)\
self:getDesktop():dropApp(self)\
end\
if success then\
self.appFrame__yieldPoint=yieldPoint\
if yieldPoint==\"sleep\" then\
self:getWorkSpace():sleepApp(self,result)\
result=true\
elseif yieldPoint==\"event\" then\
result=true\
elseif yieldPoint~=\"modal\" then\
self.appFrame__yieldPoint=\"modal\"\
result=true\
end\
end\
return result\
end\
local lockScrnFrame=popupFrame:base()\
function lockScrnFrame:onCreate(password)\
self:setId(ID_LOCKSCRN)\
self:setColor(self:getColors().homeText)\
self:setBgColor(self:getColors().homeBack)\
self.title=labelWindow:new(self,0,0,0,\"Locked\")\
self.title:setColor(self:getColors().homeText)\
self.title:setBgColor(self:getColors().homeBack)\
self.password=inputWindow:new(self,ID_LOCKPW,0,0,8,\"\",\"Password\")\
self.password:setMaskChar(\"*\")\
self.ok=buttonWindow:new(self,ID_LOCKOK,0,0,\" Ok \")\
self.ls__password=password\
self.password:setFocus()\
self:onResize()\
return true\
end\
function lockScrnFrame:onResize()\
local rtWork=self:getDesktop():getWorkArea()\
local pwWidth=iif(rtWork.width<20,rtWork.width-2,20)\
local pwLeft=math.floor((rtWork.width-pwWidth)/2)\
local pwTop=math.floor(rtWork.height/2)\
self:move(rtWork:unpack())\
self.title:move(math.floor((rtWork.width-6)/2),pwTop-2)\
self.password:move(pwLeft,pwTop,pwWidth)\
self.ok:move(pwLeft+pwWidth-4,pwTop+2)\
return true\
end\
function lockScrnFrame:onFrameClose()\
return true\
end\
function lockScrnFrame:onEvent(event,p1,p2,p3,p4,p5,...)\
if event==\"btn_click\" then\
if p1:getId()==ID_LOCKOK then\
if self.password:getText()==self.ls__password then\
self:close(ID_LOCKOK)\
else\
self.password:setText(\"\")\
self.password:setError(true)\
self.password:invalidate()\
self.password:setFocus()\
end\
return true\
end\
end\
return false\
end\
function lockScrnFrame:onChildKey(wnd,key,ctrl,alt,shift)\
if popupFrame.onChildKey(self,wnd,key,ctrl,alt,shift)then\
return true\
end\
if not ctrl and not alt and not shift then\
if key==keys.enter then\
self:sendEvent(\"btn_click\",self.ok)\
return true\
end\
end\
return false\
end\
function parentFrame:constructor(desktop,id,x,y,width,height)\
if not window.constructor(self,desktop,id,x,y,width,height)then\
return nil\
end\
self.pFrame__focusedWnd=nil\
self.pFrame__continueModal=false\
self.pFrame__modalResult=nil\
self:setWantFocus(false)\
self:setColor(self:getColors().frameText)\
self:setBgColor(self:getColors().frameBack)\
return self\
end\
function parentFrame:getOwner()\
if self.wnd__owner then\
return self.wnd__owner\
end\
return self\
end\
function parentFrame:getPopup()\
return self.wnd__popup\
end\
function parentFrame:getActiveFrame()\
local frame=self\
while frame:getPopup()do\
frame=frame:getPopup()\
end\
return frame\
end\
function parentFrame:setActiveTopFrame()\
if self:getDesktop():setActiveFrame(self)then\
if self:getPopup()then\
return self:getPopup():setActiveTopFrame()\
end\
return true\
end\
return false\
end\
function parentFrame:onFrameActivate(active)\
end\
function parentFrame:setFocusWnd(wnd)\
local desktop=self:getDesktop()\
if wnd then\
if not wnd:isEnabled()or not wnd:isShown()then\
return false\
end\
end\
if desktop then\
if desktop:getActiveFrame()~=self then\
local focusWnd=wnd\
if not focusWnd then\
focusWnd=self:nextWnd(nil,true)\
end\
self.pFrame__focusedWnd=focusWnd\
return true\
else\
local focusWnd=wnd\
if not focusWnd then\
if self.pFrame__focusedWnd then\
focusWnd=self:priorWnd(self.pFrame__focusedWnd,true)\
if focusWnd==self.pFrame__focusedWnd then\
focusWnd=nil\
end\
else\
focusWnd=self:nextWnd(nil,true)\
end\
end\
if self.pFrame__focusedWnd then\
if not self:routeEvent(self.pFrame__focusedWnd,\"blur\",focusWnd)then\
self.pFrame__focusedWnd:sendEvent(\"blur\",focusWnd)\
end\
self.pFrame__focusedWnd:invalidate()\
end\
if focusWnd then\
if not self:routeEvent(focusWnd,\"focus\",self.pFrame__focusedWnd)then\
focusWnd:sendEvent(\"focus\",self.pFrame__focusedWnd)\
end\
focusWnd:invalidate()\
end\
self.pFrame__focusedWnd=focusWnd\
return true\
end\
end\
return false\
end\
function parentFrame:nextWnd(wnd,focusable)\
for i=self:childIndex(wnd)+1,self:children(),1 do\
local nextWnd=self:getChild(i)\
if nextWnd then\
if(nextWnd:getWantFocus()and nextWnd:isShown()\
and nextWnd:isEnabled())\
or(not focusable)then\
return nextWnd\
end\
end\
end\
for i=1,self:children(),1 do\
local nextWnd=self:getChild(i)\
if nextWnd then\
if(nextWnd:getWantFocus()and nextWnd:isShown()\
and nextWnd:isEnabled())\
or(not focusable)then\
return nextWnd\
end\
end\
end\
return nil\
end\
function parentFrame:priorWnd(wnd,focusable)\
for i=self:childIndex(wnd)-1,1,-1 do\
local nextWnd=self:getChild(i)\
if nextWnd then\
if(nextWnd:getWantFocus()and nextWnd:isShown()\
and nextWnd:isEnabled())\
or(not focusable)then\
return nextWnd\
end\
end\
end\
for i=self:children(),1,-1 do\
local nextWnd=self:getChild(i)\
if nextWnd then\
if(nextWnd:getWantFocus()and nextWnd:isShown()\
and nextWnd:isEnabled())\
or(not focusable)then\
return nextWnd\
end\
end\
end\
return nil\
end\
function parentFrame:onChildKey(wnd,key,ctrl,alt,shift)\
if not alt and not ctrl then\
if shift then\
if key==keys.tab then\
local nextWnd=self:priorWnd(self.pFrame__focusedWnd,true)\
if nextWnd and nextWnd~=self.pFrame__focusedWnd then\
nextWnd:setFocus()\
end\
return true\
end\
else\
if key==keys.tab then\
local nextWnd=self:nextWnd(self.pFrame__focusedWnd,true)\
if nextWnd and nextWnd~=self.pFrame__focusedWnd then\
nextWnd:setFocus()\
end\
return true\
end\
end\
end\
return false\
end\
function parentFrame:msgBox(titleText,message,bgColor)\
local msgbox=msgBoxFrame:new(self)\
if asnumber(bgColor)~=0 then\
msgbox:setBgColor(bgColor)\
end\
msgbox:doModal(titleText,message)\
end\
function parentFrame:systemMsgBox(titleText,message,bgColor)\
local msgbox=msgBoxFrame:new(self)\
if asnumber(bgColor)~=0 then\
msgbox:setBgColor(bgColor)\
end\
local enabled=self:getDesktop().dt__taskBar:isEnabled()\
self:getDesktop().dt__taskBar:enable(false)\
msgbox:doModal(titleText,message)\
self:getDesktop().dt__taskBar:enable(enabled)\
end\
function parentFrame:lockScreen()\
local password=getPassword()\
if password:len()>0 then\
self:getDesktop():dismissKeyboard()\
local enabled=self:getDesktop().dt__taskBar:isEnabled()\
self:getDesktop().dt__taskBar:enable(false)\
lockScrnFrame:new(self):doModal(password)\
self:getDesktop().dt__taskBar:enable(enabled)\
end\
end\
function parentFrame:runModal()\
local lastResult=true\
self.pFrame__continueModal=true\
while self.pFrame__continueModal do\
local event={coroutine.yield(\"modal\",lastResult)}\
lastResult=true\
if event[2]==\"system_msgbox\" then\
self:systemMsgBox(event[4],event[5],event[6])\
elseif event[2]==\"lock_screen\" then\
self:lockScreen()\
elseif event[1]then\
local frame=event[1]:getParentFrame()\
if frame and(event[1]~=frame)then\
if frame:routeEvent(unpack(event))then\
event[1]=nil\
end\
end\
if event[1]then\
lastResult=event[1]:routeEvent(unpack(event))\
end\
else\
lastResult=false\
end\
end\
return self.pFrame__modalResult\
end\
function parentFrame:endModal(result)\
self.pFrame__modalResult=result\
self.pFrame__continueModal=false\
end\
function parentFrame:createPopup(width,height)\
if self.wnd__popup then\
return nil\
end\
return popupFrame:new(self,width,height)\
end\
local taskBarFrame=applicationFrame:base()\
function taskBarFrame:constructor(side)\
if not applicationFrame.constructor(self,side)then\
return nil\
end\
local width,height=self:getDesktop().gdi:getSize()\
self.wnd__id=ID_TASKBAR\
self.wnd__frameClass=FRAME_CLASS_SYSTEM\
self:setWantFocus(false)\
self:setBgColor(0)\
self:move(0,height-1,width,1,WND_TOP)\
return self\
end\
function taskBarFrame:draw(gdi,bounds)\
local minWidth=iif(self:commEnabled(),18,15)\
if self.width>minWidth then\
barText=string.format(\"[H] [L]%s%s%s\",\
string.rep(\" \",self.width-minWidth),\
iif(self:commEnabled(),\" @ \",\"\"),\
textutils.formatTime(os.time(),false,8))\
else\
barText=string.format(\"[H] [L]%s%s\",\
iif(self:commEnabled(),\" @ \",\"\"),\
textutils.formatTime(os.time(),false,8))\
end\
gdi:setTextColor(self:getColors().taskText)\
gdi:setBackgroundColor(self:getColors().taskBack)\
gdi:write(barText,0,0)\
end\
function taskBarFrame:onLeftClick(x,y)\
if x>=0 and x<3 then\
self:getDesktop():showHomePage()\
elseif x>=4 and x<7 then\
self:getDesktop():showListPage()\
elseif self.width>iif(self:commEnabled(),18,15)and x>=(self.width-8)then\
self:getDesktop():msgBox(\"Today\",\"Day: \"..tostring(os.day()))\
end\
return true\
end\
function taskBarFrame:onTouch(x,y)\
if x>=0 and x<3 then\
self:getDesktop():showHomePage()\
elseif x>=4 and x<7 then\
self:getDesktop():showListPage()\
elseif self.width>iif(self:commEnabled(),18,15)and x>=(self.width-8)then\
self:getDesktop():msgBox(\"Today\",\"Day: \"..tostring(os.day()))\
end\
return true\
end\
function taskBarFrame:onResize()\
local width,height=self:getDesktop().gdi:getSize()\
self:move(0,height-1,width,1)\
return true\
end\
function taskBarFrame:onIdle(idleCount)\
if self:getDesktop():getTaskBarIndex()==1 and self:isShown()then\
if self.width>iif(self:commEnabled(),17,14)then\
local strTime=textutils.formatTime(os.time(),false,8)\
local gdi=self:getGDI()\
gdi:setTextColor(self:getColors().taskText)\
gdi:setBackgroundColor(self:getColors().taskBack)\
gdi:write(strTime,(self.width-8),0)\
self:releaseGDI()\
end\
end\
return false\
end\
function taskBarFrame:onQuit()\
return true\
end\
local homePageFrame=applicationFrame:base()\
function homePageFrame:constructor(side,title)\
if not applicationFrame.constructor(self,side)then\
return nil\
end\
local rt=self:getDesktop():getWorkArea()\
self.wnd__id=ID_MENUFRAME\
self.wnd__frameClass=FRAME_CLASS_SYSTEM\
self:setColor(self:getColors().homeText)\
self:setBgColor(self:getColors().homeBack)\
title=asstring(title)\
if title:len()<1 then\
title=asstring(os.getComputerLabel())\
if title:len()<1 then\
title=\"Home\"\
end\
end\
self.title=labelWindow:new(self,0,math.floor((rt.width-title:len())/2),\
1,title)\
self.title:setColor(self:getColors().homeText)\
self.title:setBgColor(self:getColors().homeBack)\
self.list=listWindow:new(self,ID_MENULIST,2,3,rt.width-4,\
rt.height-4)\
self.list:setColors(self:getColors().homeItemText,\
self:getColors().homeItemBack,\
self:getColors().homeItemBack,\
self:getColors().homeItemSelectedText,\
self:getColors().homeItemSelectedBack)\
self.lockBtn=buttonWindow:new(self,ID_HOMELOCK,rt.width-4,\
rt.height-1,\"lock\")\
self.lockBtn:setColors(self:getColors().homeText,\
self:getColors().homeBack,\
self:getColors().scrollBack)\
self.lockBtn:show(getPassword():len()>0)\
self.pFrame__focusedWnd=self.list\
return self\
end\
function homePageFrame:loadList()\
self.list:resetContent()\
local lines={}\
local line,lastLine;\
local hFile=fs.open(\"/win/\"..self:getDesktop():getSide()..\
\"/desktop.ini\",\"r\")\
if hFile then\
line=hFile.readLine()\
while line do\
lines[#lines+1]=line\
line=hFile.readLine()\
end\
hFile.close()\
lastLine=math.floor(#lines/5)*5\
for line=1,lastLine,5 do\
local app={\
name=lines[line],\
path=lines[line+1],\
arguments=lines[line+2],\
dummy1=lines[line+3],\
dummy2=lines[line+4]\
}\
self.list:addString(app.name,app)\
end\
end\
if self.list:count()>0 then\
self.list:setCurSel(1)\
end\
end\
function homePageFrame:onResize()\
local rt=self:getDesktop():getWorkArea()\
self:move(rt:unpack())\
self.title:move(math.floor((rt.width-self.title:getText():len())/2))\
self.lockBtn:move(rt.width-4,rt.height-1)\
self.list:move(2,3,rt.width-4,rt.height-4)\
return true\
end\
function homePageFrame:onEvent(event,p1,p2,p3,p4,p5,...)\
if event==\"list_click\" then\
if p1:getId()==ID_MENULIST then\
local app=self.list:getData()\
if app then\
self:getDesktop():runApp(app.path,app.arguments)\
end\
return true\
end\
elseif event==\"btn_click\" then\
if p1:getId()==ID_HOMELOCK then\
self:getDesktop():lockScreen()\
return true\
end\
end\
return false\
end\
function homePageFrame:onQuit()\
return true\
end\
function homePageFrame:onFrameActivate(active)\
if active then\
self:loadList()\
self.list:setFocus()\
self.lockBtn:show(getPassword():len()>0)\
end\
end\
local appListFrame=applicationFrame:base()\
function appListFrame:constructor(side)\
if not applicationFrame.constructor(self,side)then\
return nil\
end\
local rt=self:getDesktop():getWorkArea()\
self.wnd__id=ID_APPFRAME\
self.wnd__frameClass=FRAME_CLASS_SYSTEM\
self:setColor(self:getColors().homeText)\
self:setBgColor(self:getColors().homeBack)\
self.title=labelWindow:new(self,0,math.floor((rt.width-4)/2),1,\"List\")\
self.title:setColor(self:getColors().homeText)\
self.title:setBgColor(self:getColors().homeBack)\
self.list=listWindow:new(self,ID_APPLIST,2,3,rt.width-4,rt.height-4)\
self.list:setColors(self:getColors().homeItemText,\
self:getColors().homeItemBack,\
self:getColors().homeItemBack,\
self:getColors().homeItemSelectedText,\
self:getColors().homeItemSelectedBack)\
self.pFrame__focusedWnd=self.list\
return self\
end\
function appListFrame:loadList()\
self.list:resetContent()\
local iterator,app=self:getDesktop():enumApps()\
while app do\
self.list:addString(app:getText(),app)\
iterator,app=self:getDesktop():enumApps(iterator)\
end\
if self.list:count()>0 then\
self.list:setCurSel(1)\
end\
end\
function appListFrame:onResize()\
local rt=self:getDesktop():getWorkArea()\
self:move(rt:unpack())\
self.title:move(math.floor((rt.width-4)/2))\
self.list:move(2,3,rt.width-4,rt.height-4)\
return true\
end\
function appListFrame:onEvent(event,p1,p2,p3,p4,p5,...)\
if event==\"list_click\" then\
if p1:getId()==ID_APPLIST then\
local app=self.list:getData()\
if app then\
app:setActiveTopFrame()\
end\
return true\
end\
end\
return false\
end\
function appListFrame:onQuit()\
return true\
end\
function appListFrame:onFrameActivate(active)\
if active then\
self:loadList()\
end\
end\
local function kbKeydef(charEvent,code,char,shiftChar,capsChar,shiftCapsChar,colorFunc)\
return{\
charEvent=charEvent,\
code=code,\
char=char,\
shiftChar=shiftChar,\
capsChar=capsChar,\
shiftCapsChar=shiftCapsChar,\
color=colorFunc\
}\
end\
local keyboardFrame=applicationFrame:base()\
function keyboardFrame:constructor(side,targetWnd)\
if not applicationFrame.constructor(self,side)then\
return nil\
end\
self.wnd__id=ID_KEYBOARD\
self.wnd__frameClass=FRAME_CLASS_SYSTEM\
self.keyTextColor=self:getColors().kbText\
self.kbBgColor=self:getColors().kbBack\
self.stdColor=self:getColors().kbKey\
self.cmdColor=self:getColors().kbCmd\
self.cancelColor=self:getColors().kbCancel\
self.toggleColor=self:getColors().kbToggle\
self.capsState=false\
self.shiftState=false\
self.ctrlState=false\
self.altState=false\
self.keysLeft=0\
self.keysTop=0\
self.targetWnd=targetWnd\
self.targetParent=nil\
self.targetRect=nil\
self.targetZ=nil\
if targetWnd then\
self.targetWnd=targetWnd\
self.targetParent=targetWnd:getParent()\
self.targetRect=targetWnd:getWndRect()\
if targetWnd:getParent()then\
self.targetZ=targetWnd:getParent():childIndex(targetWnd)\
end\
self.targetWnd:setParent(self)\
end\
self:setColor(self.kbTextColor)\
self:setBgColor(self.kbBgColor)\
self.mapFull={\
{\
kbKeydef(false,300,\"x\",\"x\",\"x\",\"x\",self.cancelKeyColor),\
kbKeydef(true,41,\"~\",\"~\",\"~\",\"~\",self.stdKeyColor),\
kbKeydef(true,2,\"1\",\"!\",\"1\",\"!\",self.stdKeyColor),\
kbKeydef(true,3,\"2\",\"@\",\"2\",\"@\",self.stdKeyColor),\
kbKeydef(true,4,\"3\",\"#\",\"3\",\"#\",self.stdKeyColor),\
kbKeydef(true,5,\"4\",\"$\",\"4\",\"$\",self.stdKeyColor),\
kbKeydef(true,6,\"5\",\"%\",\"5\",\"%\",self.stdKeyColor),\
kbKeydef(true,7,\"6\",\"^\",\"6\",\"^\",self.stdKeyColor),\
kbKeydef(true,8,\"7\",\"&\",\"7\",\"&\",self.stdKeyColor),\
kbKeydef(true,9,\"8\",\"*\",\"8\",\"*\",self.stdKeyColor),\
kbKeydef(true,10,\"9\",\"(\",\"9\",\"(\",self.stdKeyColor),\
kbKeydef(true,11,\"0\",\")\",\"0\",\")\",self.stdKeyColor),\
kbKeydef(true,12,\"-\",\"_\",\"-\",\"_\",self.stdKeyColor),\
kbKeydef(true,13,\"=\",\"+\",\"=\",\"+\",self.stdKeyColor),\
kbKeydef(false,14,\"b\",\"b\",\"b\",\"b\",self.cmdKeyColor),\
kbKeydef(false,14,\"s\",\"s\",\"s\",\"s\",self.cmdKeyColor),\
kbKeydef(false,0,\" \",\" \",\" \",\" \",self.noKeyColor),\
kbKeydef(false,210,\"I\",\"I\",\"I\",\"I\",self.cmdKeyColor),\
kbKeydef(false,199,\"H\",\"H\",\"H\",\"H\",self.cmdKeyColor),\
kbKeydef(false,201,\"P\",\"P\",\"P\",\"P\",self.cmdKeyColor)\
},\
{\
kbKeydef(false,15,\"t\",\"t\",\"t\",\"t\",self.cmdKeyColor),\
kbKeydef(false,15,\"b\",\"b\",\"b\",\"b\",self.cmdKeyColor),\
kbKeydef(true,16,\"q\",\"Q\",\"Q\",\"q\",self.stdKeyColor),\
kbKeydef(true,17,\"w\",\"W\",\"W\",\"w\",self.stdKeyColor),\
kbKeydef(true,18,\"e\",\"E\",\"E\",\"e\",self.stdKeyColor),\
kbKeydef(true,19,\"r\",\"R\",\"R\",\"r\",self.stdKeyColor),\
kbKeydef(true,20,\"t\",\"T\",\"T\",\"t\",self.stdKeyColor),\
kbKeydef(true,21,\"y\",\"Y\",\"Y\",\"y\",self.stdKeyColor),\
kbKeydef(true,22,\"u\",\"U\",\"U\",\"u\",self.stdKeyColor),\
kbKeydef(true,23,\"i\",\"I\",\"I\",\"i\",self.stdKeyColor),\
kbKeydef(true,24,\"o\",\"O\",\"O\",\"o\",self.stdKeyColor),\
kbKeydef(true,25,\"p\",\"P\",\"P\",\"p\",self.stdKeyColor),\
kbKeydef(true,26,\"[\",\"{\",\"[\",\"{\",self.stdKeyColor),\
kbKeydef(true,27,\"]\",\"}\",\"]\",\"}\",self.stdKeyColor),\
kbKeydef(true,43,\"\\\\\",\"|\",\"\\\\\",\"|\",self.stdKeyColor),\
kbKeydef(false,0,\" \",\" \",\" \",\" \",self.noKeyColor),\
kbKeydef(false,0,\" \",\" \",\" \",\" \",self.noKeyColor),\
kbKeydef(false,211,\"D\",\"D\",\"D\",\"D\",self.cmdKeyColor),\
kbKeydef(false,207,\"E\",\"E\",\"E\",\"E\",self.cmdKeyColor),\
kbKeydef(false,209,\"N\",\"N\",\"N\",\"N\",self.cmdKeyColor)\
},\
{\
kbKeydef(false,58,\"c\",\"c\",\"c\",\"c\",self.capsKeyColor),\
kbKeydef(false,58,\"l\",\"l\",\"l\",\"l\",self.capsKeyColor),\
kbKeydef(true,30,\"a\",\"A\",\"A\",\"a\",self.stdKeyColor),\
kbKeydef(true,31,\"s\",\"S\",\"S\",\"s\",self.stdKeyColor),\
kbKeydef(true,32,\"d\",\"D\",\"D\",\"d\",self.stdKeyColor),\
kbKeydef(true,33,\"f\",\"F\",\"F\",\"f\",self.stdKeyColor),\
kbKeydef(true,34,\"g\",\"G\",\"G\",\"g\",self.stdKeyColor),\
kbKeydef(true,35,\"h\",\"H\",\"H\",\"h\",self.stdKeyColor),\
kbKeydef(true,36,\"j\",\"J\",\"J\",\"j\",self.stdKeyColor),\
kbKeydef(true,37,\"k\",\"K\",\"K\",\"k\",self.stdKeyColor),\
kbKeydef(true,38,\"l\",\"L\",\"L\",\"l\",self.stdKeyColor),\
kbKeydef(true,39,\";\",\":\",\";\",\":\",self.stdKeyColor),\
kbKeydef(true,40,\"'\",\"\\\"\",\"'\",\"\\\"\",self.stdKeyColor),\
kbKeydef(false,28,\"e\",\"e\",\"e\",\"e\",self.cmdKeyColor),\
kbKeydef(false,28,\"n\",\"n\",\"n\",\"n\",self.cmdKeyColor),\
kbKeydef(false,28,\"t\",\"t\",\"t\",\"t\",self.cmdKeyColor),\
kbKeydef(false,0,\" \",\" \",\" \",\" \",self.noKeyColor),\
kbKeydef(false,0,\" \",\" \",\" \",\" \",self.noKeyColor),\
kbKeydef(false,0,\" \",\" \",\" \",\" \",self.noKeyColor),\
kbKeydef(false,0,\" \",\" \",\" \",\" \",self.noKeyColor),\
},\
{\
kbKeydef(false,42,\"s\",\"s\",\"s\",\"s\",self.shiftKeyColor),\
kbKeydef(false,42,\"f\",\"f\",\"f\",\"f\",self.shiftKeyColor),\
kbKeydef(false,42,\"t\",\"t\",\"t\",\"t\",self.shiftKeyColor),\
kbKeydef(true,44,\"z\",\"Z\",\"Z\",\"z\",self.stdKeyColor),\
kbKeydef(true,45,\"x\",\"X\",\"X\",\"x\",self.stdKeyColor),\
kbKeydef(true,46,\"c\",\"C\",\"C\",\"c\",self.stdKeyColor),\
kbKeydef(true,47,\"v\",\"V\",\"V\",\"v\",self.stdKeyColor),\
kbKeydef(true,48,\"b\",\"B\",\"B\",\"b\",self.stdKeyColor),\
kbKeydef(true,49,\"n\",\"N\",\"N\",\"n\",self.stdKeyColor),\
kbKeydef(true,50,\"m\",\"M\",\"M\",\"m\",self.stdKeyColor),\
kbKeydef(true,51,\",\",\"<\",\",\",\"<\",self.stdKeyColor),\
kbKeydef(true,52,\".\",\">\",\".\",\">\",self.stdKeyColor),\
kbKeydef(true,53,\"/\",\"?\",\"/\",\"?\",self.stdKeyColor),\
kbKeydef(false,42,\"s\",\"s\",\"s\",\"s\",self.shiftKeyColor),\
kbKeydef(false,42,\"f\",\"f\",\"f\",\"f\",self.shiftKeyColor),\
kbKeydef(false,42,\"t\",\"t\",\"t\",\"t\",self.shiftKeyColor),\
kbKeydef(false,0,\" \",\" \",\" \",\" \",self.noKeyColor),\
kbKeydef(false,0,\" \",\" \",\" \",\" \",self.noKeyColor),\
kbKeydef(false,200,\"^\",\"^\",\"^\",\"^\",self.cmdKeyColor),\
kbKeydef(false,0,\" \",\" \",\" \",\" \",self.noKeyColor)\
},\
{\
kbKeydef(false,29,\"c\",\"c\",\"c\",\"c\",self.ctrlKeyColor),\
kbKeydef(false,29,\"t\",\"t\",\"t\",\"t\",self.ctrlKeyColor),\
kbKeydef(false,29,\"l\",\"l\",\"l\",\"l\",self.ctrlKeyColor),\
kbKeydef(true,57,\" \",\" \",\" \",\" \",self.stdKeyColor),\
kbKeydef(true,57,\" \",\" \",\" \",\" \",self.stdKeyColor),\
kbKeydef(true,57,\" \",\" \",\" \",\" \",self.stdKeyColor),\
kbKeydef(true,57,\" \",\" \",\" \",\" \",self.stdKeyColor),\
kbKeydef(true,57,\" \",\" \",\" \",\" \",self.stdKeyColor),\
kbKeydef(true,57,\" \",\" \",\" \",\" \",self.stdKeyColor),\
kbKeydef(true,57,\" \",\" \",\" \",\" \",self.stdKeyColor),\
kbKeydef(true,57,\" \",\" \",\" \",\" \",self.stdKeyColor),\
kbKeydef(true,57,\" \",\" \",\" \",\" \",self.stdKeyColor),\
kbKeydef(true,57,\" \",\" \",\" \",\" \",self.stdKeyColor),\
kbKeydef(false,56,\"a\",\"a\",\"a\",\"a\",self.altKeyColor),\
kbKeydef(false,56,\"l\",\"l\",\"l\",\"l\",self.altKeyColor),\
kbKeydef(false,56,\"t\",\"t\",\"t\",\"t\",self.altKeyColor),\
kbKeydef(false,0,\" \",\" \",\" \",\" \",self.noKeyColor),\
kbKeydef(false,203,\"<\",\"<\",\"<\",\"<\",self.cmdKeyColor),\
kbKeydef(false,208,\"v\",\"v\",\"v\",\"v\",self.cmdKeyColor),\
kbKeydef(false,205,\">\",\">\",\">\",\">\",self.cmdKeyColor)\
}\
}\
self.mapBrief={\
{\
kbKeydef(true,41,\"~\",\"~\",\"~\",\"~\",self.stdKeyColor),\
kbKeydef(true,2,\"1\",\"!\",\"1\",\"!\",self.stdKeyColor),\
kbKeydef(true,3,\"2\",\"@\",\"2\",\"@\",self.stdKeyColor),\
kbKeydef(true,4,\"3\",\"#\",\"3\",\"#\",self.stdKeyColor),\
kbKeydef(true,5,\"4\",\"$\",\"4\",\"$\",self.stdKeyColor),\
kbKeydef(true,6,\"5\",\"%\",\"5\",\"%\",self.stdKeyColor),\
kbKeydef(true,7,\"6\",\"^\",\"6\",\"^\",self.stdKeyColor),\
kbKeydef(true,8,\"7\",\"&\",\"7\",\"&\",self.stdKeyColor),\
kbKeydef(true,9,\"8\",\"*\",\"8\",\"*\",self.stdKeyColor),\
kbKeydef(true,10,\"9\",\"(\",\"9\",\"(\",self.stdKeyColor),\
kbKeydef(true,11,\"0\",\")\",\"0\",\")\",self.stdKeyColor),\
kbKeydef(true,12,\"-\",\"_\",\"-\",\"_\",self.stdKeyColor),\
kbKeydef(true,13,\"=\",\"+\",\"=\",\"+\",self.stdKeyColor),\
kbKeydef(false,14,\"b\",\"b\",\"b\",\"b\",self.cmdKeyColor),\
kbKeydef(false,14,\"s\",\"s\",\"s\",\"s\",self.cmdKeyColor)\
},\
{\
kbKeydef(false,300,\"x\",\"x\",\"x\",\"x\",self.cancelKeyColor),\
kbKeydef(false,0,\" \",\" \",\" \",\" \",self.noKeyColor),\
kbKeydef(true,16,\"q\",\"Q\",\"Q\",\"q\",self.stdKeyColor),\
kbKeydef(true,17,\"w\",\"W\",\"W\",\"w\",self.stdKeyColor),\
kbKeydef(true,18,\"e\",\"E\",\"E\",\"e\",self.stdKeyColor),\
kbKeydef(true,19,\"r\",\"R\",\"R\",\"r\",self.stdKeyColor),\
kbKeydef(true,20,\"t\",\"T\",\"T\",\"t\",self.stdKeyColor),\
kbKeydef(true,21,\"y\",\"Y\",\"Y\",\"y\",self.stdKeyColor),\
kbKeydef(true,22,\"u\",\"U\",\"U\",\"u\",self.stdKeyColor),\
kbKeydef(true,23,\"i\",\"I\",\"I\",\"i\",self.stdKeyColor),\
kbKeydef(true,24,\"o\",\"O\",\"O\",\"o\",self.stdKeyColor),\
kbKeydef(true,25,\"p\",\"P\",\"P\",\"p\",self.stdKeyColor),\
kbKeydef(true,26,\"[\",\"{\",\"[\",\"{\",self.stdKeyColor),\
kbKeydef(true,27,\"]\",\"}\",\"]\",\"}\",self.stdKeyColor),\
kbKeydef(true,43,\"\\\\\",\"|\",\"\\\\\",\"|\",self.stdKeyColor)\
},\
{\
kbKeydef(false,58,\"c\",\"c\",\"c\",\"c\",self.capsKeyColor),\
kbKeydef(false,58,\"l\",\"l\",\"l\",\"l\",self.capsKeyColor),\
kbKeydef(true,30,\"a\",\"A\",\"A\",\"a\",self.stdKeyColor),\
kbKeydef(true,31,\"s\",\"S\",\"S\",\"s\",self.stdKeyColor),\
kbKeydef(true,32,\"d\",\"D\",\"D\",\"d\",self.stdKeyColor),\
kbKeydef(true,33,\"f\",\"F\",\"F\",\"f\",self.stdKeyColor),\
kbKeydef(true,34,\"g\",\"G\",\"G\",\"g\",self.stdKeyColor),\
kbKeydef(true,35,\"h\",\"H\",\"H\",\"h\",self.stdKeyColor),\
kbKeydef(true,36,\"j\",\"J\",\"J\",\"j\",self.stdKeyColor),\
kbKeydef(true,37,\"k\",\"K\",\"K\",\"k\",self.stdKeyColor),\
kbKeydef(true,38,\"l\",\"L\",\"L\",\"l\",self.stdKeyColor),\
kbKeydef(true,39,\";\",\":\",\";\",\":\",self.stdKeyColor),\
kbKeydef(true,40,\"'\",\"\\\"\",\"'\",\"\\\"\",self.stdKeyColor),\
kbKeydef(false,28,\"e\",\"e\",\"e\",\"e\",self.cmdKeyColor),\
kbKeydef(false,28,\"n\",\"n\",\"n\",\"n\",self.cmdKeyColor)\
},\
{\
kbKeydef(false,42,\"s\",\"s\",\"s\",\"s\",self.shiftKeyColor),\
kbKeydef(false,42,\"h\",\"h\",\"h\",\"h\",self.shiftKeyColor),\
kbKeydef(true,44,\"z\",\"Z\",\"Z\",\"z\",self.stdKeyColor),\
kbKeydef(true,45,\"x\",\"X\",\"X\",\"x\",self.stdKeyColor),\
kbKeydef(true,46,\"c\",\"C\",\"C\",\"c\",self.stdKeyColor),\
kbKeydef(true,47,\"v\",\"V\",\"V\",\"v\",self.stdKeyColor),\
kbKeydef(true,48,\"b\",\"B\",\"B\",\"b\",self.stdKeyColor),\
kbKeydef(true,49,\"n\",\"N\",\"N\",\"n\",self.stdKeyColor),\
kbKeydef(true,50,\"m\",\"M\",\"M\",\"m\",self.stdKeyColor),\
kbKeydef(true,51,\",\",\"<\",\",\",\"<\",self.stdKeyColor),\
kbKeydef(true,52,\".\",\">\",\".\",\">\",self.stdKeyColor),\
kbKeydef(true,53,\"/\",\"?\",\"/\",\"?\",self.stdKeyColor),\
kbKeydef(false,0,\" \",\" \",\" \",\" \",self.noKeyColor),\
kbKeydef(false,42,\"s\",\"s\",\"s\",\"s\",self.shiftKeyColor),\
kbKeydef(false,42,\"h\",\"h\",\"h\",\"h\",self.shiftKeyColor)\
},\
{\
kbKeydef(false,0,\"[\",\"[\",\"[\",\"[\",self.noKeyColor),\
kbKeydef(true,57,\" \",\" \",\" \",\" \",self.stdKeyColor),\
kbKeydef(true,57,\" \",\" \",\" \",\" \",self.stdKeyColor),\
kbKeydef(true,57,\" \",\" \",\" \",\" \",self.stdKeyColor),\
kbKeydef(true,57,\" \",\" \",\" \",\" \",self.stdKeyColor),\
kbKeydef(true,57,\" \",\" \",\" \",\" \",self.stdKeyColor),\
kbKeydef(true,57,\" \",\" \",\" \",\" \",self.stdKeyColor),\
kbKeydef(true,57,\" \",\" \",\" \",\" \",self.stdKeyColor),\
kbKeydef(true,57,\" \",\" \",\" \",\" \",self.stdKeyColor),\
kbKeydef(true,57,\" \",\" \",\" \",\" \",self.stdKeyColor),\
kbKeydef(true,57,\" \",\" \",\" \",\" \",self.stdKeyColor),\
kbKeydef(true,57,\" \",\" \",\" \",\" \",self.stdKeyColor),\
kbKeydef(true,57,\" \",\" \",\" \",\" \",self.stdKeyColor),\
kbKeydef(true,57,\" \",\" \",\" \",\" \",self.stdKeyColor),\
kbKeydef(false,0,\"]\",\"]\",\"]\",\"]\",self.noKeyColor)\
}\
}\
self.keyMap=self.mapFull\
if self:getDesktop()then\
self:onResize()\
end\
if targetWnd then\
self.targetWnd:setFocus()\
end\
return self\
end\
function keyboardFrame:stdKeyColor()\
return self.stdColor\
end\
function keyboardFrame:noKeyColor()\
return self.kbBgColor\
end\
function keyboardFrame:cmdKeyColor()\
return self.cmdColor\
end\
function keyboardFrame:cancelKeyColor()\
return self.cancelColor\
end\
function keyboardFrame:ctrlKeyColor()\
if self.ctrlState then\
return self.toggleColor\
end\
return self.cmdColor\
end\
function keyboardFrame:shiftKeyColor()\
if self.shiftState then\
return self.toggleColor\
end\
return self.cmdColor\
end\
function keyboardFrame:capsKeyColor()\
if self.capsState then\
return self.toggleColor\
end\
return self.cmdColor\
end\
function keyboardFrame:altKeyColor()\
if self.altState then\
return self.toggleColor\
end\
return self.cmdColor\
end\
function keyboardFrame:getKeyDef(x,y)\
local cx,cy=x-self.keysLeft+1,y-self.keysTop+1\
if cy>0 and cy<=table.maxn(self.keyMap)and\
cx>0 and cx<=table.maxn(self.keyMap[1])then\
return self.keyMap[cy][cx]\
end\
return nil\
end\
function keyboardFrame:dismiss()\
self:endModal(0)\
end\
function keyboardFrame:draw(gdi,bounds)\
gdi:setTextColor(self.keyTextColor)\
for y=1,table.maxn(self.keyMap),1 do\
for x=1,table.maxn(self.keyMap[y]),1 do\
local kd=self.keyMap[y][x]\
gdi:setBackgroundColor(kd.color(self))\
if self.capsState then\
if self.shiftState then\
gdi:write(kd.shiftCapsChar,self.keysLeft+x-1,self.keysTop+y-1)\
else\
gdi:write(kd.capsChar,self.keysLeft+x-1,self.keysTop+y-1)\
end\
else\
if self.shiftState then\
gdi:write(kd.shiftChar,self.keysLeft+x-1,self.keysTop+y-1)\
else\
gdi:write(kd.char,self.keysLeft+x-1,self.keysTop+y-1)\
end\
end\
end\
end\
end\
function keyboardFrame:onTouch(x,y)\
local kd=self:getKeyDef(x,y)\
if kd then\
if kd.code~=0 then\
if kd.code==keys.leftAlt then\
if self.altState then\
self.altState=false\
else\
self.altState=true\
self.targetWnd:sendEvent(\"key\",kd.code,self.ctrlState,self.altState,self.shiftState)\
end\
self:invalidate()\
return true\
elseif kd.code==keys.leftCtrl then\
if self.ctrlState then\
self.ctrlState=false\
else\
self.ctrlState=true\
self.targetWnd:sendEvent(\"key\",kd.code,self.ctrlState,self.altState,self.shiftState)\
end\
self:invalidate()\
return true\
elseif kd.code==keys.leftShift then\
if self.shiftState then\
self.shiftState=false\
else\
self.shiftState=true\
self.targetWnd:sendEvent(\"key\",kd.code,self.ctrlState,self.altState,self.shiftState)\
end\
self:invalidate()\
return true\
elseif kd.code==keys.capsLock then\
if self.capsState then\
self.capsState=false\
else\
self.capsState=true\
self.targetWnd:sendEvent(\"key\",kd.code,self.ctrlState,self.altState,self.shiftState)\
end\
self:invalidate()\
return true\
end\
if kd.code~=300 then\
self.targetWnd:sendEvent(\"key\",kd.code,self.ctrlState,self.altState,self.shiftState)\
if not self.ctrlState and not self.altState and kd.charEvent then\
if self.capsState then\
if self.shiftState then\
self.targetWnd:sendEvent(\"char\",kd.shiftCapsChar)\
else\
self.targetWnd:sendEvent(\"char\",kd.capsChar)\
end\
else\
if self.shiftState then\
self.targetWnd:sendEvent(\"char\",kd.shiftChar)\
else\
self.targetWnd:sendEvent(\"char\",kd.char)\
end\
end\
end\
if kd.charEvent then\
if self.ctrlState or self.altState or self.shiftState then\
self.ctrlState=false\
self.altState=false\
self.shiftState=false\
self:invalidate()\
return true\
end\
end\
end\
if kd.code==300 then\
self:dismiss()\
return true\
elseif kd.code==keys.enter then\
if self.targetWnd:getWantKeyInput()==KEYINPUT_LINE then\
self:dismiss()\
return true\
end\
end\
end\
end\
return true\
end\
function keyboardFrame:onResize()\
local szWidth,szHeight=self.gdi:getSize()\
local tLeft,tTop,tWidth,tHeight=self.targetRect:unpack()\
self.keyMap=iif((szWidth<20),self.mapBrief,self.mapFull)\
self.keysLeft=math.floor((szWidth-iif(szWidth<20,15,20))/2)\
self.keysTop=iif((szHeight-self:getTheme().keyboardHeight)<4,4,\
(szHeight-self:getTheme().keyboardHeight))\
tHeight=iif((tHeight>(self.keysTop-2)),(self.keysTop-2),tHeight)\
tWidth=iif((tWidth>szWidth),szWidth,tWidth)\
tLeft=math.floor((szWidth-tWidth)/2)\
tTop=self.keysTop-tHeight-1\
self:move(0,0,szWidth,szHeight,WND_TOP)\
self.targetWnd:move(tLeft,tTop,tWidth,tHeight)\
return true\
end\
function keyboardFrame:onEvent(event,p1,p2,p3,p4,p5,...)\
if p1==self.targetWnd then\
if self.targetParent then\
self.targetParent:sendEvent(event,p1,p2,p3,p4,p5)\
end\
end\
return true\
end\
function keyboardFrame:runApp()\
local tZ;\
if self:onCreate()then\
self:runModal()\
end\
self.targetWnd:setParent(self.targetParent)\
if self.targetParent and self.targetZ then\
tZ=(self.targetZ-self.targetParent:childIndex(self.targetWnd))\
tZ=iif((tZ==0),nil,tZ)\
end\
self.targetWnd:move(self.targetRect.x,self.targetRect.y,\
self.targetRect.width,self.targetRect.height,tZ)\
self:getDesktop().dt__keyboard=nil\
self:destroyWnd()\
self.targetWnd:setFocus()\
self:getDesktop():update(true)\
end\
local function runAppFrame(frame)\
frame.appFrame__appRoutine=coroutine.create(frame.runApp)\
if not frame.appFrame__appRoutine then\
error(\"Failed to create system frame\",2)\
end\
local success,msg=coroutine.resume(frame.appFrame__appRoutine,frame)\
if not success then\
error(\"Error initialising system frame \"..\"\\n\"..msg,2)\
end\
end\
local desktopWindow=window:base()\
function desktopWindow:constructor(side,buffer)\
if not window.constructor(self,nil,ID_DESKTOP,0,0,0,0)then\
return nil\
end\
self.dt__taskBar=nil\
self.dt__homePage=nil\
self.dt__appList=nil\
self.dt__keyboard=nil\
self.dt__captureMouseWnd=nil\
self.dt__dragWnd=nil\
self.dt__cursorColor=colors.black\
self.dt__bufferDisplay=buffer\
self.dt__clipboardData=nil\
self.dt__clipboardType=CB_EMPTY\
self.gdi=GDI:new(side,self)\
self.dt__theme=self:createTheme()\
self:setBgColor(self:getColors().desktopBack)\
local szWidth,szHeight=self.gdi:getSize()\
self:move(0,0,szWidth,szHeight,nil)\
return self\
end\
function desktopWindow:getTheme()\
return self.dt__theme\
end\
function desktopWindow:getTaskBarIndex()\
for i=1,self:children(),1 do\
if self:getChild(i)==self.dt__taskBar then\
return i\
end\
end\
return 0\
end\
function desktopWindow:getActiveAppFrame()\
if self:children()>0 then\
for i=self:getTaskBarIndex()+1,self:children(),1 do\
local frame=self:getChild(i)\
if frame.wnd__frameClass==FRAME_CLASS_APPLICATION then\
return frame\
end\
end\
end\
return nil\
end\
function desktopWindow:getActiveFrame()\
if self:children()>0 then\
return self:getChild(self:getTaskBarIndex()+1)\
end\
return nil\
end\
function desktopWindow:getNextAppFrame(frame)\
local start=self:childIndex(frame)\
if start>0 then\
for i=start+1,self:children(),1 do\
local top=self:getChild(i)\
if top.wnd__frameClass==FRAME_CLASS_APPLICATION then\
return top\
end\
end\
end\
return nil\
end\
function desktopWindow:getFocusWnd()\
local frame=self:getActiveFrame()\
if frame then\
return frame.pFrame__focusedWnd\
end\
return nil\
end\
function desktopWindow:setActiveFrame(frame)\
local curFrame=self:getActiveFrame()\
if frame and frame~=curFrame then\
self.dt__captureMouseWnd=nil\
self.dt__dragWnd=nil\
local i=self:childIndex(frame)\
if i>0 then\
if not curFrame or curFrame:getId()~=ID_LOCKSCRN then\
if curFrame then\
local success,msg=pcall(curFrame.onFrameActivate,curFrame,false)\
if not success then\
syslog(curFrame:getText()..\" onFrameActivate \"..msg)\
end\
curFrame:invalidate()\
if curFrame.pFrame__focusedWnd then\
curFrame.pFrame__focusedWnd:sendEvent(\"blur\",nil)\
end\
end\
i=self:getTaskBarIndex()-i+1\
if i~=0 then\
window.move(frame,nil,nil,nil,nil,i)\
end\
frame:invalidate()\
local focus=frame.pFrame__focusedWnd\
if not focus then\
focus=frame:nextWnd(nil,true)\
end\
if focus then\
frame.pFrame__focusedWnd=nil\
focus:setFocus()\
end\
local success,msg=pcall(frame.onFrameActivate,frame,true)\
if not success then\
syslog(frame:getText()..\" onFrameActivate \"..msg)\
end\
return true\
end\
end\
end\
return(frame==curFrame)\
end\
function desktopWindow:update(force)\
if force then\
self:invalidate()\
end\
if not self.wnd__invalid:isEmpty()then\
local first=self:children()+1\
local rt=self:getWorkArea()\
rt.width=rt.width-1\
rt.height=rt.height-1\
self.gdi:store()\
self.gdi:setDraw(false)\
self.gdi:addBounds(self.wnd__invalid)\
for i=1,self:children(),1 do\
local frame=self:getChild(i)\
local rtWnd=frame:getScreenRect()\
if rtWnd:contains(rt.x,rt.y)and\
rtWnd:contains(rt.x+rt.width-1,rt.y+rt.height-1)then\
first=i\
break\
end\
end\
if first>self:children()then\
first=self:children()\
if self:getBgColor()>0 then\
self.gdi:setBackgroundColor(self:getBgColor())\
self.gdi:clear(self.wnd__invalid:unpack())\
end\
self:draw(self.gdi,rect:new(self.wnd__invalid:unpack()))\
end\
for i=first,1,-1 do\
local frame=self:getChild(i)\
if frame:getScreenRect():overlap(self.gdi:getBounds())then\
self.gdi:addBounds(frame:update(force or i<first))\
end\
end\
self:validate()\
self.gdi:setDraw(true)\
self.gdi:restore()\
end\
return self.gdi:getBounds(true)\
end\
function desktopWindow:doIdle(count)\
for i=1,self:children(),1 do\
self:getChild(i):sendEvent(\"idle\",count)\
end\
end\
function desktopWindow:loadAppList()\
self.dt__appList:loadList()\
end\
function desktopWindow:runApp(path,...)\
self:getWorkSpace():runApp(self:getSide(),path,unpack(parseCmdLine(...)))\
self:loadAppList()\
end\
function desktopWindow:onResize()\
self:move(0,0,self.gdi:getSize())\
for i=1,self:children(),1 do\
self:getChild(i):sendEvent(\"monitor_resize\")\
end\
return true\
end\
function desktopWindow:getFullscreen()\
if self.dt__taskBar then\
return self.dt__taskBar.wnd__hidden~=false\
end\
return false\
end\
function desktopWindow:setFullscreen(fullscreen)\
if fullscreen==nil then\
fullscreen=not self:getFullscreen()\
end\
if fullscreen~=self:getFullscreen()then\
local focusWnd=self:getFocusWnd()\
self.dt__taskBar:show(not fullscreen)\
self:onResize()\
if focusWnd then\
pcall(focusWnd.onMove,focusWnd)\
end\
end\
end\
function desktopWindow:getWorkArea()\
local rt=rect:new(0,0,self.gdi:getSize())\
if not self:getFullscreen()then\
rt.height=rt.height-1\
end\
return rt\
end\
function desktopWindow:captureMouse(wnd)\
self.dt__captureMouseWnd=wnd\
end\
function desktopWindow:capturedMouse()\
return self.dt__captureMouseWnd\
end\
function desktopWindow:getClipboard()\
return self.dt__clipboardType,self.dt__clipboardData\
end\
function desktopWindow:setClipboard(data,cbType)\
if data==nil then\
self.dt__clipboardType=CB_EMPTY\
self.dt__clipboardData=nil\
else\
self.dt__clipboardData=data\
if cbType==nil then\
self.dt__clipboardType=CB_TEXT\
else\
self.dt__clipboardType=cbType\
end\
end\
end\
function desktopWindow:dropApp(frame)\
local app=self:getActiveFrame()\
if app then\
app=app:getAppFrame()\
end\
if frame==app then\
local nextFrame=self:getNextAppFrame(frame)\
if nextFrame then\
nextFrame:setActiveTopFrame()\
else\
self:showHomePage()\
end\
end\
frame:destroyWnd()\
self:loadAppList()\
end\
function desktopWindow:enumApps(iterator)\
if iterator==nil then\
iterator=self:getTaskBarIndex()+1\
end\
local frame=self:getChild(iterator)\
while frame do\
if frame.wnd__frameClass==FRAME_CLASS_APPLICATION then\
iterator=iterator+1\
return iterator,frame\
end\
iterator=iterator+1\
frame=self:getChild(iterator)\
end\
return iterator,nil\
end\
function desktopWindow:setTextScale(scale)\
if self.gdi:isMonitor()then\
self.gdi:setTextScale(scale)\
self:onResize()\
end\
end\
function desktopWindow:showHomePage()\
self.dt__homePage:setActiveTopFrame()\
end\
function desktopWindow:showListPage()\
self.dt__appList:setActiveTopFrame()\
end\
function desktopWindow:saveTheme(theme)\
local themeFile=\"/win/\"..self:getSide()..\"/theme.ini\"\
local result=false\
local hFile=fs.open(themeFile,\"w\")\
if hFile then\
local data=textutils.serialize(theme)\
if data then\
hFile.write(data)\
result=true\
end\
hFile.close()\
end\
return result\
end\
function desktopWindow:loadTheme()\
local themeFile=\"/win/\"..self:getSide()..\"/theme.ini\"\
local theme=nil\
if fs.exists(themeFile)and not fs.isDir(themeFile)then\
local hFile=fs.open(themeFile,\"r\")\
if hFile then\
local data=hFile.readAll()\
if data then\
theme=textutils.unserialize(data)\
end\
hFile.close()\
end\
end\
return theme\
end\
function desktopWindow:createTheme()\
local theme=self:loadTheme()\
if not theme then\
theme=desktopTheme:new()\
self:saveTheme(theme)\
end\
if theme.keyboardHeight<5 then\
theme.keyboardHeight=5\
end\
theme.closeBtnChar=asstring(theme.closeBtnChar)\
if theme.closeBtnChar:len()>1 then\
theme.closeBtnChar=theme.closeBtnChar:sub(1,1)\
end\
return theme\
end\
function desktopWindow:doKeyboard(targetWnd)\
if not self.dt__keyboard then\
self.dt__keyboard=keyboardFrame:new(self:getSide(),targetWnd)\
runAppFrame(self.dt__keyboard)\
end\
end\
function desktopWindow:dismissKeyboard()\
if self.dt__keyboard then\
self.dt__keyboard:dismiss()\
self.dt__keyboard=nil\
end\
end\
function desktopWindow:createBars()\
local title;\
local iniFile=fs.loadIniFile(\"/win/\"..self:getSide()..\"/startup.ini\")\
if iniFile then\
title=iniFile:find(\"home\")\
end\
self.dt__taskBar=taskBarFrame:new(self:getSide())\
runAppFrame(self.dt__taskBar)\
self.dt__homePage=homePageFrame:new(self:getSide(),title)\
runAppFrame(self.dt__homePage)\
self.dt__appList=appListFrame:new(self:getSide())\
runAppFrame(self.dt__appList)\
self.dt__homePage:loadList()\
self:showHomePage()\
end\
function desktopWindow:msgBox(titleText,message,bgColor)\
os.queueEvent(\"system_msgbox\",self:getSide(),titleText,message,bgColor)\
end\
function desktopWindow:lockScreen()\
if not self:isLocked()then\
os.queueEvent(\"lock_screen\",self:getSide())\
end\
end\
function desktopWindow:isLocked()\
return self:getWndById(ID_LOCKSCRN)~=nil\
end\
function desktopWindow:canLock()\
return getPassword():len()>0\
end\
function desktopWindow:getPassword()\
return getPassword()\
end\
local workSpace=__classBase:base()\
function workSpace:constructor()\
self.ws__desktops={}\
self.ws__doLockScreen=false\
self.ws__keyctrl=-1\
self.ws__keyalt=-1\
self.ws__keyshift=-1\
self.ws__lastEventIdle=true\
self.ws__eventCount=0\
self.ws__lastUpdate=-1\
self.ws__idleCount=1\
self.ws__idleTime=-1\
self.ws__idleTimerId=0\
self.ws__lockEvents=false\
self.ws__appRoutine=nil\
self.ws__appSide=nil\
self.ws__appPath=nil\
self.ws__appFrame=nil\
self.ws__syscomms=0\
self.ws__comms={}\
self.ws__timers={}\
self.ws__wndEvents={}\
return self\
end\
function workSpace:commEnabled()\
return(self.ws__syscomms>0)\
end\
function workSpace:commFind(name,wireless)\
if name then\
for i=1,#self.ws__comms,1 do\
if name==self.ws__comms[i]:getName()then\
return self.ws__comms[i]\
end\
end\
return nil\
end\
if wireless~=nil then\
for i=1,#self.ws__comms,1 do\
if wireless==self.ws__comms[i]:getWireless()then\
return self.ws__comms[i]\
end\
end\
return nil\
end\
return self.ws__comms[1]\
end\
function workSpace:commOpen(name,wireless,port,timeout,relay)\
if not name then\
local count=0\
repeat\
name=\"comm_\"..tostring(count)\
count=count+1\
until not self:commFind(name)\
end\
local com=comm:new(name,wireless,port,timeout,relay)\
if com:connect()then\
self.ws__comms[#self.ws__comms+1]=com\
return com\
end\
return nil\
end\
function workSpace:commClose(name)\
if name then\
local index;\
for i=self.ws__syscomms+1,1,-1 do\
if name==self.ws__comms[i]:getName()then\
index=i\
break\
end\
end\
if index then\
local close=true\
for i=#self.ws__comms,1,-1 do\
if(i~=index)and\
(self.ws__comms[i]:getPort()==\
self.ws__comms[index]:getPort())then\
close=false\
break\
end\
end\
if close then\
self.ws__comms[index]:disconnect()\
end\
table.remove(self.ws__comms,index)\
return true\
end\
end\
return false\
end\
function workSpace:commRegister(wnd,application,name,wireless)\
local com=self:commFind(name,wireless)\
if com then\
com:register(wnd,application)\
return true\
end\
return false\
end\
function workSpace:commUnregister(wnd,application,name,wireless)\
if name or wireless then\
local com=self:commFind(name,wireless)\
if com then\
com:unregister(wnd,application)\
return true\
end\
else\
for i=1,#self.ws__comms,1 do\
self.ws__comms[i]:unregister(wnd,application)\
end\
return true\
end\
return false\
end\
function workSpace:commSend(recipient,application,context,data,name,wireless)\
local com=self:commFind(name,wireless)\
if com then\
return com:send(recipient,application,context,data)\
end\
return nil\
end\
function workSpace:getDesktop(side)\
return self.ws__desktops[asstring(side)]\
end\
function workSpace:desktops()\
local sides={}\
for side,desktop in pairs(self.ws__desktops)do\
sides[#sides+1]=side\
end\
return sides\
end\
function workSpace:getFocusWnd(side)\
if self:getDesktop(side)then\
return self:getDesktop(side):getFocusWnd()\
end\
return nil\
end\
function workSpace:startTimer(wnd,timeout)\
local id=os.startTimer(asnumber(timeout))\
self.ws__timers[#self.ws__timers+1]={id,wnd,\"timer\"}\
return id\
end\
function workSpace:setAlarm(wnd,time)\
local id=os.setAlarm(asnumber(time))\
self.ws__timers[#self.ws__timers+1]={id,wnd,\"alarm\"}\
return id\
end\
function workSpace:sleepApp(wnd,timeout)\
self.ws__timers[#self.ws__timers+1]={os.startTimer(asnumber(timeout)),wnd,\"sleep\"}\
end\
function workSpace:killTimers(wnd)\
for i=#self.ws__timers,1,-1 do\
if self.ws__timers[i][2]==wnd then\
table.remove(self.ws__timers,i)\
end\
end\
end\
function workSpace:wantEvent(wnd,event)\
event=asstring(event)\
for i=1,#self.ws__wndEvents,1 do\
if self.ws__wndEvents[i][1]==wnd and\
(self.ws__wndEvents[i][2]==event or\
self.ws__wndEvents[i][2]==\"*\" or event==\"*\")then\
return false\
end\
end\
self.ws__wndEvents[#self.ws__wndEvents+1]={wnd,event}\
return true\
end\
function workSpace:unwantEvent(wnd,event)\
event=asstring(event)\
if event:len()>0 then\
for i=1,#self.ws__wndEvents,1 do\
if self.ws__wndEvents[i][1]==wnd and\
self.ws__wndEvents[i][2]==event then\
table.remove(self.ws__wndEvents,i)\
return true\
end\
end\
else\
local count=0\
for i=#self.ws__wndEvents,1,-1 do\
if self.ws__wndEvents[i][1]==wnd then\
table.remove(self.ws__wndEvents,i)\
count=count+1\
end\
end\
return(count>0)\
end\
return false\
end\
function workSpace:runApp(side,path,...)\
local result,msg=loadfile(path)\
if not result then\
error(\"Failed to load program \"..path..\"\\n\"..msg,0)\
end\
self.ws__appRoutine=coroutine.create(result)\
if not self.ws__appRoutine then\
error(\"Failed to create application \"..fs.getName(path),0)\
end\
self.ws__appSide=side\
self.ws__appPath=path\
result,msg=coroutine.resume(self.ws__appRoutine,...)\
if not result then\
if self.ws__appFrame then\
msg=self.ws__appFrame:getText()..\"\\n\"..msg\
self:getDesktop(side):dropApp(self.ws__appFrame)\
self.ws__appFrame=nil\
end\
error(msg,0)\
end\
self.ws_appFrame=nil\
end\
function workSpace:assessKey(key,keyup)\
if ccVersion()>=1.74 then\
if key then\
if key==keys.leftCtrl or key==keys.rightCtrl then\
self.ws__keyctrl=os.clock()+100000\
elseif key==keys.leftAlt or key==keys.rightAlt then\
self.ws__keyalt=os.clock()+100000\
elseif key==keys.leftShift or key==keys.rightShift then\
self.ws__keyshift=os.clock()+100000\
end\
else\
if keyup==keys.leftCtrl or keyup==keys.rightCtrl then\
self.ws__keyctrl=-1\
elseif keyup==keys.leftAlt or keyup==keys.rightAlt then\
self.ws__keyalt=-1\
elseif keyup==keys.leftShift or keyup==keys.rightShift then\
self.ws__keyshift=-1\
end\
end\
else\
if key==keys.leftCtrl or key==keys.rightCtrl then\
self.ws__keyctrl=os.clock()\
elseif key==keys.leftAlt or key==keys.rightAlt then\
self.ws__keyalt=os.clock()\
elseif key==keys.leftShift or key==keys.rightShift then\
self.ws__keyshift=os.clock()\
end\
end\
end\
function workSpace:ctrlKey()\
return(os.clock()-self.ws__keyctrl)<=0.75\
end\
function workSpace:altKey()\
return(os.clock()-self.ws__keyalt)<=0.75\
end\
function workSpace:shiftKey()\
return(os.clock()-self.ws__keyshift)<=0.75\
end\
function workSpace:comboKeys(ctrl,alt,shift)\
local bCtrl,bAlt,bShift;\
if ctrl then\
bCtrl=self:ctrlKey()\
else\
bCtrl=not self:ctrlKey()\
end\
if alt then\
bAlt=self:altKey()\
else\
bAlt=not self:altKey()\
end\
if shift then\
bShift=self:shiftKey()\
else\
bShift=not self:shiftKey()\
end\
return(bCtrl and bAlt and bShift)\
end\
function workSpace:getShell()\
return __shell\
end\
function workSpace:createDesktop(side)\
local desktopFile=\"/win/\"..side..\"/desktop.ini\"\
local buffer=false\
local iniFile=fs.loadIniFile(\"/win/\"..side..\"/startup.ini\")\
if iniFile then\
buffer=asstring((iniFile:find(\"buffer\")),\"false\")==\"true\"\
end\
if side==\"term\" and fs.exists(desktopFile)and not fs.isDir(desktopFile)then\
return desktopWindow:new(side,buffer)\
end\
if fs.exists(desktopFile)and not fs.isDir(desktopFile)and peripheral.getType(side)==\"monitor\" then\
local desktop=desktopWindow:new(side,buffer)\
if desktop then\
desktop:setTextScale(desktop:getTheme().textScale)\
end\
return desktop\
end\
return nil\
end\
function workSpace:desktopStartup(side)\
local desktop=self:getDesktop(side)\
if desktop then\
local iniFile=fs.loadIniFile(\"/win/\"..side..\"/startup.ini\")\
if iniFile then\
if asstring(iniFile:find(\"fullscreen\"),\"false\")==\"true\" then\
desktop:setFullscreen(true)\
end\
for path in iniFile:next(\"run\")do\
if path:len()>0 then\
self:runApp(side,unpack(parseCmdLine(path)))\
desktop:loadAppList()\
end\
end\
end\
end\
end\
function workSpace:startIdleTimer()\
if(os.clock()-self.ws__idleTime)>0.3 then\
self.ws__idleTimerId=os.startTimer(0.35)\
self.ws__idleTime=os.clock()\
end\
end\
function workSpace:createDesktops()\
local devices=peripheral.getNames()\
local sides={\"term\"}\
for i=1,#devices,1 do\
if peripheral.getType(devices[i])==\"monitor\" then\
sides[#sides+1]=devices[i]\
end\
end\
for _,side in pairs(sides)do\
self.ws__desktops[side]=self:createDesktop(side)\
if self.ws__desktops[side]then\
self.ws__desktops[side]:createBars()\
end\
end\
for _,side in pairs(sides)do\
self:desktopStartup(side)\
end\
end\
function workSpace:lockScreens()\
if self.ws__doLockScreen then\
for k,desktop in pairs(self.ws__desktops)do\
if desktop then\
desktop:lockScreen()\
end\
end\
self.ws__doLockScreen=false\
end\
end\
function workSpace:pumpEvent(wnd,event,...)\
if wnd then\
local app=wnd:getAppFrame()\
if app then\
return app:resume(wnd,event,...)\
end\
end\
return false\
end\
function workSpace:startup()\
local function safeTermColor(color)\
if term.isColor()then\
term.setTextColor(color)\
end\
end\
local hadKey=false\
local timerID;\
local delayTime=3.5\
local iniFile=fs.loadIniFile(\"/win/startup.ini\")\
if term.isColor()then\
term.setBackgroundColor(colors.black)\
end\
if iniFile then\
local pw=asstring(iniFile:find(\"password\"),\"\")\
local delayKey=iniFile:find(\"delay\")\
if delayKey then\
delayTime=asnumber(delayKey)\
if delayTime<=0 then\
self.ws__doLockScreen=true\
end\
end\
if pw:len()>0 and not self.ws__doLockScreen then\
local pwCount,correct=0,false\
while pwCount<3 and not correct do\
term.clear()\
term.setCursorPos(1,3)\
safeTermColor(colors.white)\
term.write(\"Password:\")\
safeTermColor(colors.red)\
correct=(safeRead(\"*\")==pw)\
pwCount=pwCount+1\
end\
if not correct then\
os.shutdown()\
end\
end\
end\
if delayTime>0 then\
term.clear()\
term.setCursorPos(1,3)\
safeTermColor(colors.white)\
term.write(\"Starting \")\
safeTermColor(colors.yellow)\
term.write(\"CCWindows \"..tostring(version()))\
term.setCursorPos(1,5)\
safeTermColor(colors.lightGray)\
term.write(\"Press key for console ...\")\
timerID=os.startTimer(delayTime)\
while timerID do\
local event=os.pullEventRaw()\
if event==\"key\" then\
term.setCursorPos(1,5)\
term.write(\"Starting console ...     \")\
hadKey=true\
elseif event==\"timer\" then\
timerID=nil\
end\
end\
if hadKey then\
term.clear()\
term.setCursorPos(1,1)\
safeTermColor(colors.yellow)\
term.write(os.version())\
term.setCursorPos(1,2)\
return false\
end\
end\
if iniFile then\
local hadError=false\
term.clear()\
term.setCursorPos(1,1)\
for value in iniFile:next(\"path\")do\
if value:len()>0 then\
__shell.setPath(__shell.path()..\":\"..value)\
end\
end\
for value in iniFile:next(\"pre\")do\
if value:len()>0 then\
local success,func,msg=false,loadfile(value)\
if func then\
success,msg=pcall(func)\
end\
if not success then\
safeTermColor(colors.red)\
print(msg)\
hadError=true\
end\
end\
end\
for value in iniFile:next(\"api\")do\
if value:len()>0 then\
if not loadAPI(value,true)then\
hadError=true\
end\
end\
end\
for value in iniFile:next(\"comm\")do\
local timeout=asnumber(iniFile:find(value..\"timeout\"),5)\
local port=asnumber(iniFile:find(value..\"port\"),80)\
local reply=asstring(iniFile:find(value..\"relay\"),\"false\")==\"true\"\
local wireless=iniFile:find(value..\"wireless\")\
if wireless then\
wireless=wireless==\"true\"\
end\
if self:commOpen(value,wireless,port,timeout,relay)then\
self.ws__syscomms=self.ws__syscomms+1\
else\
safeTermColor(colors.red)\
print(\"Could not open comm \"..value)\
hadError=true\
end\
end\
if hadError then\
safeTermColor(colors.white)\
print(\"Press key...\")\
while(os.pullEventRaw())~=\"key\" do\
end\
end\
end\
local global=getfenv(0)\
local global_os_pullEventRaw=global.os.pullEventRaw\
function global.os.pullEventRaw(target)\
if __ccwin.ws__lockEvents then\
local result;\
repeat\
result={coroutine.yield(\"event\")}\
until not target or result[1]==target\
return unpack(result)\
end\
while true do\
__ccwin:run(global_os_pullEventRaw())\
end\
end\
function global.os.pullEvent(target)\
local result;\
repeat\
result={coroutine.yield(\"event\")}\
if result[1]==\"terminate\" then\
error(\"Terminated\",0)\
end\
until not target or result[1]==target\
return unpack(result)\
end\
function global.sleep(seconds)\
if tostring(coroutine.yield(\"sleep\",seconds))==\"terminate\" then\
error(\"Terminated\",0)\
end\
end\
function global.os.sleep(seconds)\
global.sleep(seconds)\
end\
self:createDesktops()\
if not self.ws__desktops.term then\
term.clear()\
term.setCursorPos(1,3)\
safeTermColor(colors.white)\
term.write(\"Running \")\
safeTermColor(colors.yellow)\
term.write(\"CCWindows \"..tostring(version()))\
end\
term.setCursorPos(-1,-1)\
self.ws__lastEventIdle=true\
self.ws__eventCount=0\
self.ws__lastUpdate=os.clock()-1\
self.ws__idleCount=1\
self.ws__idleTimerId=os.startTimer(0.1)\
self.ws__idleTime=os.clock()-1\
return true\
end\
function workSpace:run(event,p1,p2,p3,p4,p5,...)\
local wnd;\
self.ws__lockEvents=true\
self.ws__eventCount=self.ws__eventCount+1\
if event==\"timer\" and p1==self.ws__idleTimerId then\
self:lockScreens()\
self.ws__eventCount=0\
if self.ws__lastEventIdle then\
for k,desktop in pairs(self.ws__desktops)do\
if desktop then\
desktop:doIdle(self.ws__idleCount)\
end\
end\
self.ws__idleCount=self.ws__idleCount+1\
else\
self.ws__idleCount=1\
end\
for i=1,#self.ws__comms,1 do\
self.ws__comms[i]:process()\
end\
self.ws__lastEventIdle=true\
self:startIdleTimer()\
elseif event==\"timer\" or event==\"alarm\" then\
for i=1,#self.ws__timers,1 do\
if self.ws__timers[i][1]==p1 then\
wnd=self.ws__timers[i][2]\
event=self.ws__timers[i][3]\
table.remove(self.ws__timers,i)\
break\
end\
end\
if not wnd then\
for i=1,#self.ws__wndEvents,1 do\
if self.ws__wndEvents[i][2]==event or self.ws__wndEvents[i][2]==\"*\" then\
self:pumpEvent(self.ws__wndEvents[i][1],event,p1,p2,p3,p4,p5,...)\
end\
end\
end\
self.ws__lastEventIdle=false\
elseif event==\"mouse_click\" then\
if self.ws__desktops.term then\
p2=asnumber(p2)-1\
p3=asnumber(p3)-1\
if self.ws__desktops.term:capturedMouse()then\
wnd=self.ws__desktops.term:capturedMouse()\
else\
wnd=self.ws__desktops.term:wndFromPoint(p2,p3)\
end\
self.ws__desktops.term.dt__dragWnd=wnd\
end\
self.ws__lastEventIdle=false\
elseif event==\"mouse_up\" then\
if self.ws__desktops.term then\
p2=asnumber(p2)-1\
p3=asnumber(p3)-1\
if self.ws__desktops.term:capturedMouse()then\
wnd=self.ws__desktops.term:capturedMouse()\
else\
wnd=self.ws__desktops.term:wndFromPoint(p2,p3)\
end\
self.ws__desktops.term.dt__dragWnd=wnd\
end\
self.ws__lastEventIdle=false\
elseif event==\"mouse_drag\" then\
if self.ws__desktops.term then\
p2=asnumber(p2)-1\
p3=asnumber(p3)-1\
if self.ws__desktops.term:capturedMouse()then\
wnd=self.ws__desktops.term:capturedMouse()\
else\
wnd=self.ws__desktops.term.dt__dragWnd\
end\
end\
self.ws__lastEventIdle=false\
elseif event==\"monitor_touch\" then\
local desktop=self:getDesktop(p1)\
if desktop then\
p2=asnumber(p2)-1\
p3=asnumber(p3)-1\
if desktop:capturedMouse()then\
wnd=desktop:capturedMouse()\
else\
wnd=desktop:wndFromPoint(p2,p3)\
end\
end\
self.ws__lastEventIdle=false\
elseif event==\"char\" or event==\"paste\" then\
if self.ws__desktops.term then\
wnd=self.ws__desktops.term:getFocusWnd()\
end\
self.ws__lastEventIdle=false\
elseif event==\"key\" then\
self:assessKey(p1,nil)\
if self.ws__desktops.term~=nil then\
if p1==keys.x and self:comboKeys(true,true,false)then\
wnd=self.ws__desktops.term:getActiveFrame()\
if wnd then\
event=\"frame_close\"\
p1=nil\
end\
elseif p1==keys.h and self:comboKeys(false,true,false)then\
if self.ws__desktops.term.dt__taskBar:isEnabled()then\
self.ws__desktops.term:showHomePage()\
end\
elseif p1==keys.l and self:comboKeys(false,true,false)then\
if self.ws__desktops.term.dt__taskBar:isEnabled()then\
self.ws__desktops.term:showListPage()\
end\
elseif p1==keys.k and self:comboKeys(true,true,false)then\
if self.ws__desktops.term.dt__taskBar:isEnabled()then\
self.ws__desktops.term:lockScreen()\
end\
elseif p1==keys.f10 and self:comboKeys(false,false,false)then\
self.ws__desktops.term:setFullscreen()\
else\
wnd=self.ws__desktops.term:getFocusWnd()\
p2=self:ctrlKey()\
p3=self:altKey()\
p4=self:shiftKey()\
end\
end\
self.ws__lastEventIdle=false\
elseif event==\"key_up\" then\
self:assessKey(nil,p1)\
wnd=self.ws__desktops.term:getFocusWnd()\
self.ws__lastEventIdle=false\
elseif event==\"mouse_scroll\" then\
if self.ws__desktops.term then\
p2=asnumber(p2)-1\
p3=asnumber(p3)-1\
if self.ws__desktops.term:capturedMouse()then\
wnd=self.ws__desktops.term:capturedMouse()\
else\
wnd=self.ws__desktops.term:wndFromPoint(p2,p3)\
end\
end\
self.ws__lastEventIdle=false\
elseif event==\"monitor_resize\" or event==\"term_resize\" then\
if self:getDesktop(p1)then\
self:getDesktop(p1):sendEvent(event,p1,p2,p3,p4,p5)\
end\
self.ws__lastEventIdle=false\
elseif event==\"system_msgbox\" then\
if self:getDesktop(p1)then\
wnd=self:getDesktop(p1):getActiveFrame()\
end\
self.ws__lastEventIdle=false\
elseif event==\"lock_screen\" then\
if self:getDesktop(p1)then\
wnd=self:getDesktop(p1):getActiveFrame()\
end\
self.ws__lastEventIdle=false\
else\
if event==\"peripheral_detach\" then\
if self.ws__desktops[p1]then\
self.ws__desktops[p1]:destroyWnd()\
self.ws__desktops[p1]=nil\
end\
end\
if event==\"modem_message\" then\
for i=1,#self.ws__comms,1 do\
self.ws__comms[i]:receive(p1,p2,p3,p4,p5)\
end\
end\
for i=1,#self.ws__wndEvents,1 do\
if self.ws__wndEvents[i][2]==event or self.ws__wndEvents[i][2]==\"*\" then\
self:pumpEvent(self.ws__wndEvents[i][1],event,p1,p2,p3,p4,p5,...)\
end\
end\
self.ws__lastEventIdle=false\
end\
self:pumpEvent(wnd,event,p1,p2,p3,p4,p5,...)\
if self.ws__eventCount<5 or(self.ws__lastUpdate+0.2)<os.clock()then\
for k,desktop in pairs(self.ws__desktops)do\
if desktop then\
if not desktop:update(false):isEmpty()then\
self.ws__lastUpdate=os.clock()\
end\
end\
end\
end\
end\
function createAppFrame()\
local appName=fs.getName(__ccwin.ws__appPath)\
__ccwin.ws__appFrame=applicationFrame:new(__ccwin.ws__appSide)\
if not __ccwin.ws__appFrame then\
error(\"Failed to create main frame in \"..appName,0)\
end\
__ccwin.ws__appFrame:setText(appName)\
__ccwin.ws__appFrame.appFrame__appRoutine=__ccwin.ws__appRoutine\
__ccwin.ws__appFrame.appFrame__appPath=__ccwin.ws__appPath\
__ccwin.ws__appRoutine=nil\
__ccwin.ws__appSide=nil\
__ccwin.ws__appPath=nil\
return __ccwin.ws__appFrame\
end\
function startWin(_shell)\
if not __ccwin then\
__shell=_shell\
__ccwin=workSpace:new()\
return __ccwin:startup()\
end\
return true\
end\
",
"; start up delay\
delay=2\
\
; system password\
;password=password\
\
; additional paths\
;path=path\
\
; run before starting win\
;pre=path\
\
; apis to load at startup\
api=/win/apis/cmndlg\
api=/win/apis/html\
\
; comm\
;comm=system\
;systemtime=5\
;systemport=80\
;systemrelay=true\
;systemwireless=true\
",
"local inputClass=win.popupFrame:base()\
function inputClass:onCreate(title,prompt,banner,initialText,\
validate,maxLen,bgColor)\
self:dress(title)\
local width=math.floor(self:getDesktop():getWorkArea().width*0.8)\
if asnumber(bgColor)==0 then\
bgColor=self:getColors().popupBack\
end\
self.prompt=win.labelWindow:new(self,2,1,2,prompt)\
self.entry=win.inputWindow:new(self,3,1,3,width-2,\
initialText,banner)\
self.entry:setMaxLength(maxLen)\
self.entry:setSel(0,-1)\
self.entry:setFocus()\
self.ok=win.buttonWindow:new(self,4,width-5,4,\" Ok \")\
self.validateFunc=validate\
self.resultOk=false\
self.userInput=nil\
self:setBgColor(bgColor)\
self.prompt:setBgColor(bgColor)\
self:move(nil,nil,width,6)\
return true\
end\
function inputClass:onClose()\
if self.validateFunc and self.resultOk then\
if self.validateFunc(self.entry:getText())==false then\
self.resultOk=false\
self.entry:setError(true)\
self.entry:setSel(0,-1)\
self.entry:setFocus()\
return true\
end\
end\
self.userInput=self.entry:getText()\
return false\
end\
function inputClass:onEvent(event,p1,p2,p3,p4,p5,...)\
if event==\"btn_click\" then\
if p1:getId()==4 then\
self.resultOk=true\
self:close(4)\
return true\
end\
end\
return false\
end\
function inputClass:onMove()\
win.popupFrame.onMove(self)\
self.prompt:move(nil,nil,self.width-2)\
self.entry:move(nil,nil,self.width-2)\
self.ok:move(self.width-5)\
end\
function input(ownerFrame,title,prompt,initialText,banner,maxLen,\
validate,bgColor)\
assert(ownerFrame,\"cmndlg.input() must have an owner frame.\")\
assert(ownerFrame.onFrameActivate,\
\"cmndlg.input() must have an owner frame.\")\
assert(ownerFrame.wnd__popup==nil,\
\"cmndlg.input() owner frame already has popup.\")\
local dlg=inputClass:new(ownerFrame)\
if dlg then\
if dlg:doModal(title,prompt,banner,initialText,validate,maxLen,bgColor)==4 then\
return dlg.userInput\
end\
end\
return nil\
end\
local confirmClass=win.popupFrame:base()\
function confirmClass:onCreate(title,message,defaultOk,bgColor)\
title=asstring(title)\
message=asstring(message)\
local rtWork=self:getDesktop():getWorkArea()\
local maxWidth,maxHeight=\
math.floor(rtWork.width*0.8),math.floor(rtWork.height*0.8)\
local width,height=string.wrapSize(string.wrap(message,maxWidth-2))\
if width==(maxWidth-2)and height>=(maxHeight-4)then\
width,height=string.wrapSize(string.wrap(message,maxWidth-3))\
end\
width=width+2\
height=height+4\
if width<(title:len()+3)then\
width=title:len()+3\
end\
if height<5 then\
height=5\
elseif height>maxHeight then\
height=maxHeight\
end\
if asnumber(bgColor)==0 then\
bgColor=self:getColors().popupBack\
end\
self:dress(title)\
self.message=win.textWindow:new(self,2,1,2,width-2,\
height-4,message)\
self.ok=win.buttonWindow:new(self,3,\
math.floor((width-4)/2),height-2,\" Ok \")\
if defaultOk then\
self.ok:setFocus()\
end\
self:setBgColor(bgColor)\
self.message:setBgColor(bgColor)\
self:move(nil,nil,width,height)\
return true\
end\
function confirmClass:onEvent(event,p1,p2,p3,p4,p5,...)\
if event==\"btn_click\" then\
if p1:getId()==3 then\
self:close(3)\
return true\
end\
end\
return false\
end\
function confirmClass:onMove()\
win.popupFrame.onMove(self)\
self.message:move(1,2,self.width-2,self.height-4)\
self.ok:move(math.floor((self.width-4)/2),self.height-2)\
end\
function confirm(ownerFrame,title,message,defaultOk,bgColor)\
assert(ownerFrame,\"cmndlg.confirm() must have an owner frame.\")\
assert(ownerFrame.onFrameActivate,\
\"cmndlg.confirm() must have an owner frame.\")\
assert(ownerFrame.wnd__popup==nil,\
\"cmndlg.confirm() owner frame already has popup.\")\
local dlg=confirmClass:new(ownerFrame)\
if dlg then\
if dlg:doModal(title,message,defaultOk,bgColor)==3 then\
return true\
end\
end\
return false\
end\
local fileDlgClass=win.popupFrame:base()\
function fileDlgClass:onCreate(title,initialPath,promptOverwrite,\
notHidden,notReadonly,hideNewDir,validate,bgColor)\
local rtWork=self:getDesktop():getWorkArea()\
local width,height=math.floor(rtWork.width*0.8),\
math.floor(rtWork.height*0.8)\
initialPath=asstring(initialPath)\
local fileName=\"\"\
self.curDir=\"/\"\
if initialPath:len()>0 then\
fileName=fs.getName(initialPath)\
if fileName:len()>0 then\
self.curDir=initialPath:sub(1,-(fileName:len()+1))\
else\
self.curDir=initialPath\
end\
end\
if self.curDir:sub(-1,-1)~=\"/\" then\
self.curDir=self.curDir..\"/\"\
end\
if asnumber(bgColor)==0 then\
bgColor=self:getColors().popupBack\
end\
self:dress(title)\
self.promptOverwrite=promptOverwrite\
self.notHidden=notHidden\
self.notReadonly=notReadonly\
self.dirLabel=win.labelWindow:new(self,2,1,1,self.curDir)\
self.dirLabel:move(nil,nil,width-7)\
self.dirLabel:setBgColor(bgColor)\
self.fileList=win.listWindow:new(self,3,1,2,width-2,height-5)\
self.fileName=win.inputWindow:new(self,4,1,height-2,\
width-6,fileName,\"File name\")\
self.fileName:setSel(0,-1)\
self.fileName:setFocus()\
self.ok=win.buttonWindow:new(self,5,width-5,height-2,\" Ok \")\
self.mkdir=win.buttonWindow:new(self,6,width-6,1,\" new \")\
self.mkdir:show(hideNewDir~=true)\
self.validateFunc=validate\
self.resultOk=false\
self.fullPath=nil\
self:setBgColor(bgColor)\
self:move(nil,nil,width,height)\
self:loadFileList()\
return true\
end\
function fileDlgClass:newDirectory()\
local bgColor=colors.orange\
if self:getBgColor()==colors.orange then\
bgColor=colors.yellow\
end\
local folder=input(self,\"New Folder\",\"Enter new folder name.\",\
\"Folder\",\"new\",nil,nil,bgColor)\
if folder then\
fs.makeDir(self.curDir..folder)\
self:loadFileList()\
end\
end\
function fileDlgClass:checkOverwrite()\
if self.promptOverwrite and fs.exists(self:getFullPath())then\
local bgColor=colors.orange\
if self:getBgColor()==colors.orange then\
bgColor=colors.yellow\
end\
if not confirm(self,\"Overwrite\",\
\"File \\\"\"..self:getFullPath()..\"\\\" already exists.\\nOverwrite?\",\
false,bgColor)then\
return\
end\
end\
self.resultOk=true\
self:close(5)\
end\
function fileDlgClass:getFullPath()\
return self.curDir..self.fileName:getText()\
end\
function fileDlgClass:loadFileList()\
if not fs.isDir(self.curDir)then\
self.curDir=\"/\"\
end\
local fileList=fs.list(self.curDir)\
table.sort(fileList)\
self.fileList:resetContent()\
if self.curDir:len()>1 then\
self.fileList:addString(\"..\",{id=0,name=\"..\"})\
end\
for i=1,#fileList,1 do\
if fs.isDir(self.curDir..fileList[i])then\
if(not self.notReadonly or not fs.isReadOnly(self.curDir..fileList[i]))then\
self.fileList:addString(\"/\"..fileList[i],{id=1,name=fileList[i]})\
end\
end\
end\
for i=1,#fileList,1 do\
if not fs.isDir(self.curDir..fileList[i])then\
if(not self.notReadonly or not fs.isReadOnly(self.curDir..fileList[i]))and\
(not self.notHidden or fileList[i]:sub(1,1)~=\".\")then\
self.fileList:addString(fileList[i],{id=2,name=fileList[i]})\
end\
end\
end\
self.dirLabel:setText(self.curDir)\
self.dirLabel:invalidate()\
end\
function fileDlgClass:onClose()\
if self.validateFunc and self.resultOk then\
if self.validateFunc(self:getFullPath())==false then\
self.resultOk=false\
self.fileName:setError(true)\
self.fileName:setSel(0,-1)\
self.fileName:setFocus()\
return true\
end\
end\
self.fullPath=self:getFullPath()\
return false\
end\
function fileDlgClass:onEvent(event,p1,p2,p3,p4,p5,...)\
if event==\"btn_click\" then\
if p1:getId()==5 then\
if self.fileName:getText():len()>0 then\
self:checkOverwrite()\
end\
return true\
elseif p1:getId()==6 then\
self:newDirectory()\
return true\
end\
elseif event==\"list_click\" then\
if p1:getId()==3 then\
if self.fileList:getData()then\
if self.fileList:getData().id==2 then\
self.fileName:setText(self.fileList:getData().name)\
self.fileName:setSel(0,-1)\
end\
end\
return true\
end\
elseif event==\"list_double_click\" then\
if p1:getId()==3 then\
if self.fileList:getData()then\
if self.fileList:getData().id==0 then\
if self.curDir:len()>1 then\
self.curDir=self.curDir:sub(1,-2)\
local lastDir=fs.getName(self.curDir)\
self.curDir=self.curDir:sub(1,-(lastDir:len()+1))\
self:loadFileList()\
end\
elseif self.fileList:getData().id==1 then\
self.curDir=self.curDir..self.fileList:getData().name..\"/\"\
self:loadFileList()\
elseif self.fileList:getData().id==2 then\
self.fileName:setText(self.fileList:getData().name)\
self.fileName:setSel(0,-1)\
self:checkOverwrite()\
end\
end\
return true\
end\
end\
return false\
end\
function fileDlgClass:onResize()\
local rtWork=self:getDesktop():getWorkArea()\
self:move(nil,nil,math.floor(rtWork.width*0.8),math.floor(rtWork.height*0.8))\
win.popupFrame.onResize(self)\
self.dirLabel:move(nil,nil,self.width-7)\
self.fileList:move(1,2,self.width-2,self.height-5)\
self.fileName:move(1,self.height-3,self.width-6)\
self.ok:move(self.width-5,self.height-2)\
self.mkdir:move(self.width-6)\
end\
function file(ownerFrame,title,initialPath,promptOverwrite,\
notHidden,notReadonly,hideNewDir,validate,bgColor)\
assert(ownerFrame,\"cmndlg.file() must have an owner frame.\")\
assert(ownerFrame.onFrameActivate,\
\"cmndlg.file() must have an owner frame.\")\
assert(ownerFrame.wnd__popup==nil,\
\"cmndlg.file() owner frame already has popup.\")\
local dlg=fileDlgClass:new(ownerFrame)\
if dlg then\
if dlg:doModal(title,initialPath,promptOverwrite,notHidden,\
notReadonly,hideNewDir,validate,bgColor)==5 then\
return dlg.fullPath\
end\
end\
return nil\
end\
function saveFile(ownerFrame,initialPath,notHidden,validate,bgColor)\
assert(ownerFrame,\"cmndlg.saveFile() must have an owner frame.\")\
assert(ownerFrame.onFrameActivate,\
\"cmndlg.saveFile() must have an owner frame.\")\
assert(ownerFrame.wnd__popup==nil,\
\"cmndlg.saveFile() owner frame already has popup.\")\
return file(ownerFrame,\"Save File\",initialPath,true,\
notHidden,true,false,validate,bgColor)\
end\
function openFile(ownerFrame,initialPath,notHidden,notReadonly,validate,bgColor)\
assert(ownerFrame,\"cmndlg.openFile() must have an owner frame.\")\
assert(ownerFrame.onFrameActivate,\
\"cmndlg.openFile() must have an owner frame.\")\
assert(ownerFrame.wnd__popup==nil,\
\"cmndlg.openFile() owner frame already has popup.\")\
local function validatePath(path)\
if not fs.exists(path)then\
return false\
end\
if validate then\
return validate(result,path)\
end\
return true\
end\
return file(ownerFrame,\"Open File\",initialPath,false,\
notHidden,notReadonly,true,validatePath,bgColor)\
end\
function getPrinters()\
local devices=peripheral.getNames()\
local printers={}\
for i=1,#devices,1 do\
if peripheral.getType(devices[i])==\"printer\" then\
printers[#printers+1]=devices[i]\
end\
end\
return printers\
end\
local printDlgClass=win.popupFrame:base()\
function printDlgClass:onCreate(totalPages,bgColor)\
local width=math.floor(self:getDesktop():getWorkArea().width*0.8)\
if asnumber(bgColor)==0 then\
bgColor=self:getColors().popupBack\
end\
self:dress(\"Print\")\
self.prompt=win.labelWindow:new(self,2,1,1,\"Select printer\")\
self.printers=win.listWindow:new(self,3,1,2,width-2,4)\
self.printers:setFocus()\
local printers=getPrinters()\
for i=1,#printers,1 do\
self.printers:addString(printers[i])\
end\
self.pagesLabel=win.labelWindow:new(self,4,1,6,\"Pages\")\
if totalPages then\
self.totalPages=asnumber(totalPages)\
if self.totalPages>0 then\
self.fromPage=win.inputWindow:new(self,5,1,7,4,\"1\",\"From\")\
self.toPage=win.inputWindow:new(self,6,6,7,4,\
asstring(totalPages),\"To\")\
else\
self.totalPages=0\
self.fromPage=win.inputWindow:new(self,5,1,7,4,\"\",\"From\")\
self.toPage=win.inputWindow:new(self,6,6,7,4,\"\",\"To\")\
end\
else\
self.totalPages=0\
self.fromPage=win.inputWindow:new(self,5,1,7,4,\"\",\"From\")\
self.toPage=win.inputWindow:new(self,6,6,7,4,\"\",\"To\")\
self.fromPage:show(false)\
self.toPage:show(false)\
self.pagesLabel:show(false)\
end\
self.ok=win.buttonWindow:new(self,7,width-5,7,\" Ok \")\
self.resultOk=false\
self.printerName=nil\
self.pageFirst=nil\
self.pageLast=nil\
self:setBgColor(bgColor)\
self.prompt:setBgColor(bgColor)\
self.pagesLabel:setBgColor(bgColor)\
self:move(nil,nil,width,9)\
return true\
end\
function printDlgClass:onClose()\
self.printerName=self.printers:getString()\
self.pageFirst=asnumber(self.fromPage:getText())\
self.pageLast=asnumber(self.toPage:getText())\
return false\
end\
function printDlgClass:onEvent(event,p1,p2,p3,p4,p5,...)\
if event==\"btn_click\" then\
if p1:getId()==7 then\
if self.printers:getCurSel()~=0 then\
self.resultOk=true\
self:close(7)\
else\
self.printers:setFocus()\
end\
return true\
end\
elseif event==\"input_change\" then\
if p1:getId()==5 or p1:getId()==6 then\
local page=asnumber(p1:getText())\
if page<1 then\
p1:setText(\"1\")\
p1:invalidate()\
elseif self.totalPages>0 and page>self.totalPages then\
p1:setText(asstring(self.totalPages))\
p1:invalidate()\
end\
return true\
end\
end\
return false\
end\
function printDlgClass:onMove()\
win.popupFrame.onMove(self)\
self.prompt:move(nil,nil,self.width-2)\
self.printers:move(nil,nil,self.width-2)\
self.ok:move(self.width-5)\
end\
function print(ownerFrame,totalPages,bgColor)\
assert(ownerFrame,\"cmndlg.print() must have an owner frame.\")\
assert(ownerFrame.onFrameActivate,\
\"cmndlg.print() must have an owner frame.\")\
assert(ownerFrame.wnd__popup==nil,\
\"cmndlg.print() owner frame already has popup.\")\
local dlg=printDlgClass:new(ownerFrame)\
if dlg then\
if dlg:doModal(totalPages,bgColor)==7 then\
return dlg.printerName,dlg.pageFirst,dlg.pageLast\
end\
end\
return nil\
end\
local pickColorClass=win.popupFrame:base()\
function pickColorClass:onCreate(initColor,bgColor)\
if asnumber(bgColor)==0 then\
bgColor=self:getColors().popupBack\
end\
self:dress(\"Color\")\
local color=colors.white\
for y=2,3,1 do\
for x=1,8,1 do\
local btn=win.buttonWindow:new(self,color,x,y,\"#\")\
btn:setColors(color,colors.white,self:getColors().buttonFocus)\
color=color*2\
end\
end\
if not initColor then\
initColor=colors.black\
end\
if not self:getWndById(initColor)then\
initColor=colors.black\
end\
self:getWndById(initColor):setFocus()\
self.selected=win.labelWindow:new(self,32770,1,5,\"  \")\
self.selected:setBgColor(initColor)\
self.ok=win.buttonWindow:new(self,32771,5,5,\" Ok \")\
self.resultOk=false\
self.userColor=nil\
self:setBgColor(bgColor)\
self:move(nil,nil,10,7)\
return true\
end\
function pickColorClass:onClose(result)\
self.userColor=self.selected:getBgColor()\
return false\
end\
function pickColorClass:onEvent(event,p1,p2,p3,p4,p5,...)\
if event==\"btn_click\" then\
if p1:getId()==32771 then\
self.resultOk=true\
self:close(32771)\
return true\
elseif p1:getId()>=colors.white and p1:getId()<=colors.black then\
self.selected:setBgColor(p1:getId())\
return true\
end\
end\
return false\
end\
function color(ownerFrame,initColor,bgColor)\
assert(ownerFrame,\"cmndlg.color() must have an owner frame.\")\
assert(ownerFrame.onFrameActivate,\
\"cmndlg.color() must have an owner frame.\")\
assert(ownerFrame.wnd__popup==nil,\
\"cmndlg.color() owner frame already has popup.\")\
local dlg=pickColorClass:new(ownerFrame)\
if dlg then\
if dlg:doModal(initColor,bgColor)==32771 then\
return dlg.userColor\
end\
end\
return nil\
end\
",
"local htmlColors=\
{\
[\"white\"]=1,\
[\"1\"]=1,\
[\"orange\"]=2,\
[\"2\"]=2,\
[\"magenta\"]=4,\
[\"4\"]=4,\
[\"lightBlue\"]=8,\
[\"sky\"]=8,\
[\"8\"]=8,\
[\"yellow\"]=16,\
[\"16\"]=16,\
[\"lime\"]=32,\
[\"32\"]=32,\
[\"pink\"]=64,\
[\"64\"]=64,\
[\"gray\"]=128,\
[\"grey\"]=128,\
[\"128\"]=128,\
[\"lightGray\"]=256,\
[\"lightGrey\"]=256,\
[\"light\"]=256,\
[\"silver\"]=256,\
[\"256\"]=256,\
[\"cyan\"]=512,\
[\"512\"]=512,\
[\"purple\"]=1024,\
[\"1024\"]=1024,\
[\"blue\"]=2048,\
[\"2048\"]=2048,\
[\"brown\"]=4096,\
[\"4096\"]=4096,\
[\"green\"]=8192,\
[\"8192\"]=8192,\
[\"red\"]=16384,\
[\"16384\"]=16384,\
[\"black\"]=32768,\
[\"32768\"]=32768\
}\
local htmlColorNames=\
{\
[\"1\"]=\"white\",\
[\"2\"]=\"orange\",\
[\"4\"]=\"magenta\",\
[\"8\"]=\"sky\",\
[\"16\"]=\"yellow\",\
[\"32\"]=\"lime\",\
[\"64\"]=\"pink\",\
[\"128\"]=\"gray\",\
[\"256\"]=\"silver\",\
[\"512\"]=\"cyan\",\
[\"1024\"]=\"purple\",\
[\"2048\"]=\"blue\",\
[\"4096\"]=\"brown\",\
[\"8192\"]=\"green\",\
[\"16384\"]=\"red\",\
[\"32768\"]=\"black\"\
}\
htmlDoc=win.__classBase:base()\
function htmlDoc:constructor(doc)\
self.html__type=\"text\"\
self:parse(doc)\
return self\
end\
function htmlDoc:color(color)\
return htmlColors[tostring(color or \"none\")]\
end\
function htmlDoc:colorName(color)\
return htmlColorNames[tostring(htmlDoc:color(color)or \"none\")]\
end\
function htmlDoc:type()\
return self.html__type\
end\
function htmlDoc:isHtml(doc)\
if type(doc)==\"table\" then\
if type(doc.html)==\"table\" then\
return doc\
end\
end\
local success,newDoc=pcall(textutils.unserialize,tostring(doc or \"\"))\
if success and type(newDoc)==\"table\" then\
if type(newDoc.html)==\"table\" then\
return newDoc\
end\
end\
return nil\
end\
function htmlDoc:parseNode(node,defTag)\
if type(node)==\"table\" then\
local tag={}\
for k,v in pairs(node)do\
if type(k)==\"string\" then\
if type(v)==\"string\" or type(v)==\"number\" then\
if k==\"color\" or k==\"bgcolor\" or k==\"linkcolor\" then\
tag[k]=htmlDoc:color(v)\
elseif k==\"width\" then\
tag[k]=tonumber(v)\
else\
if k==\"protocol\" then\
v=tostring(v)\
if v:sub(-1,-1)~=\":\" then\
v=v..\":\"\
end\
end\
tag[k]=v\
end\
end\
end\
end\
if defTag and not tag.tag then\
tag.tag=defTag\
end\
for i=1,#node,1 do\
tag[#tag+1]=self:parseNode(node[i])\
end\
for i=1,#tag,1 do\
if type(tag[i])==\"string\" then\
while(i+1)<=#tag and type(tag[i+1])==\"string\" do\
tag[i]=tag[i]..tag[i+1]\
table.remove(tag,i+1)\
end\
end\
end\
return tag\
end\
return tostring(node or \"\")\
end\
function htmlDoc:parse(content)\
local doc=htmlDoc:isHtml(content)\
self.html=\
{\
head={},\
body={tostring(content or \"\")}\
}\
self.html__type=\"text\"\
if doc then\
self.html__type=\"html\"\
if type(doc.html.head)==\"table\" then\
self.html.head=self:parseNode(doc.html.head)\
end\
if type(doc.html.body)==\"table\" then\
self.html.body=self:parseNode(doc.html.body)\
end\
return\
end\
end\
function htmlDoc:serializeNode(node,indent)\
local didBreak=false\
local str=\"{\"\
if node.tag then\
str=string.format(\"%s tag = %q,\",str,tostring(node.tag))\
end\
for k,v in pairs(node)do\
if type(k)==\"string\" and k~=\"tag\"then\
if k==\"color\" or k==\"bgcolor\" or k==\"linkcolor\" then\
v=htmlDoc:colorName(v)\
end\
if type(v)==\"number\" then\
str=string.format(\"%s %s = %s,\",str,k,tostring(v))\
elseif type(v)==\"string\" then\
str=string.format(\"%s %s = %q,\",str,k,v)\
end\
end\
end\
if node.tag==\"p\" and #node>0 then\
str=str..\"\\n \"..indent\
didBreak=true\
end\
for i=1,#node,1 do\
if type(node[i])==\"table\" then\
if node[i].tag==\"p\" then\
str=string.format(\"%s\\n  %s%s\",str,indent,\
self:serializeNode(node[i],indent..\"  \"))\
didBreak=true\
else\
str=str..\" \"..self:serializeNode(node[i],indent..\"  \")\
end\
elseif type(node[i])==\"string\" then\
str=string.format(\"%s %q,\",str,node[i])\
end\
end\
if didBreak then\
return str:sub(1,-2)..\"\\n\"..indent..\"},\"\
end\
return str:sub(1,-2)..\" },\"\
end\
function htmlDoc:getHtml()\
return string.format(\"{\\n  html = {\\n    head = %s\\n    body = %s\\n  }\\n}\",\
self:serializeNode(self.html.head,\"    \"),\
self:serializeNode(self.html.body,\"    \"))\
end\
local function html_nodeToText(node)\
local str=\"\"\
for i=1,#node,1 do\
if type(node[i])==\"table\" then\
str=str..html_nodeToText(node[i])\
elseif type(node[i])==\"string\" then\
str=str..node[i]\
end\
end\
if node.tag==\"p\" then\
str=str..\"\\n\\n\"\
end\
return str\
end\
function htmlDoc:getText()\
if self:type()==\"text\" then\
return self.html.body[1]\
end\
return html_nodeToText(self.html.body)\
end\
function htmlDoc:serialize()\
if self:type()==\"text\" then\
return self:getText()\
end\
return self:getHtml()\
end\
function htmlDoc:getWidth()\
if type(self.html)==\"table\" then\
if type(self.html.body)==\"table\" then\
if self.html.body.width then\
return asnumber(self.html.body.width)\
end\
end\
end\
return 0\
end\
local htmlMap=win.__classBase:base()\
function htmlMap:constructor(width,color,bgcolor)\
self.line=0\
self.column=0\
self.width=width\
self.color=color\
self.bgcolor=bgcolor\
return self\
end\
function htmlMap:add(color,bgcolor,align,erase,node,text)\
local current,newLine;\
text=tostring(text or \"\")\
repeat\
current,text,newLine=string.splice(text,self.width-self.column)\
if current:len()>0 then\
self[#self+1]=\
{\
node=node,\
color=color,\
bgcolor=bgcolor,\
align=align,\
erase=erase,\
line=self.line,\
column=self.column,\
text=current\
}\
self.column=self.column+current:len()\
end\
if newLine then\
self:advance(color,bgcolor,align,erase,node)\
end\
until not text\
end\
function htmlMap:lastLine()\
if #self>0 then\
return self[#self].line\
end\
return-1\
end\
function htmlMap:lines()\
return self:lastLine()+1\
end\
function htmlMap:advance(color,bgcolor,align,erase,node)\
if self:lastLine()<self.line then\
self[#self+1]=\
{\
node=node,\
color=color,\
bgcolor=bgcolor,\
align=align,\
erase=erase,\
line=self.line,\
column=self.column,\
text=\"\"\
}\
end\
self.line=self.line+1\
self.column=0\
end\
function htmlMap:startBlock(color,bgcolor,align,erase,node)\
if self.column>0 then\
self:advance(color,bgcolor,align,erase,node)\
end\
end\
function htmlMap:setAlignment()\
local first=1\
while first<=#self do\
if self[first].align==\"right\" or self[first].align==\"center\" then\
local lead=self.width\
local last=first\
for i=first+1,#self,1 do\
if self[i].line==self[first].line then\
last=i\
else\
break\
end\
end\
for i=first,last,1 do\
lead=lead-self[i].text:len()\
end\
if self[first].align==\"center\" then\
lead=math.modf(lead/2)\
end\
for i=first,last,1 do\
self[i].column=self[i].column+lead\
end\
first=last\
end\
first=first+1\
end\
end\
function htmlMap:getRange(firstLine,lastLine)\
local firstMap,lastMap=nil,nil\
lastLine=lastLine or firstLine\
for i=1,#self,1 do\
if self[i].line>=firstLine then\
firstMap=i\
break\
end\
end\
if firstMap then\
if self[firstMap].line>lastLine then\
firstMap=nil\
else\
for i=firstMap+1,#self,1 do\
if self[i].line>lastLine then\
lastMap=i-1\
break\
end\
end\
if not lastMap then\
lastMap=#self\
end\
end\
end\
return firstMap,lastMap\
end\
function htmlMap:nodeFromPoint(x,y)\
local first,last=self:getRange(y)\
if first then\
for i=first,last,1 do\
if x>=self[i].column and x<(self[i].column+self[i].text:len())then\
return self[i].node\
end\
end\
end\
return nil\
end\
function htmlMap:getWidth()\
return self.width\
end\
browserWindow=win.window:base()\
function browserWindow:constructor(parent,id,x,y,width,height)\
if not win.window.constructor(self,parent,id,x,y,width,height)then\
return nil\
end\
self.brws__doc=nil\
self.brws__map=nil\
self:setWantFocus(false)\
self:setText()\
return self\
end\
function browserWindow:getTitle(title)\
if self.brws__doc.html.head.title then\
return tostring(self.brws__doc.html.head.title)\
end\
return title\
end\
function browserWindow:mapNode(map,node,color,bgcolor,linkcolor,align,erase)\
if node.tag==\"a\" then\
color=node.color or linkcolor\
else\
color=node.color or color\
end\
bgcolor=node.bgcolor or bgcolor\
if node.tag==\"l\" then\
local lwidth=math.max(math.modf((map.width/100)*\
math.min(math.abs(node.width or 100),100)),1)\
local lchar=node.char or \"-\"\
align=node.align or align\
if lchar:len()<1 then\
lchar=\"-\"\
else\
lchar=lchar:sub(1,1)\
end\
map:startBlock(color,bgcolor,align,erase,node)\
map:add(color,bgcolor,align,erase,node,string.rep(lchar,lwidth))\
map:startBlock(color,bgcolor,align,erase,node)\
return\
end\
if node.tag==\"p\" or node.tag==\"d\" then\
align=node.align or align\
if node.bgcolor then\
erase=node.bgcolor\
end\
map:startBlock(color,bgcolor,align,erase,node)\
end\
for i=1,#node,1 do\
if type(node[i])==\"table\" then\
self:mapNode(map,node[i],color,bgcolor,linkcolor,align,erase)\
if node[i].tag==\"p\" then\
map:startBlock(color,bgcolor,align,erase,node)\
map:advance(color,bgcolor,align,erase,node)\
elseif node[i].tag==\"d\" then\
map:startBlock(color,bgcolor,align,erase,node)\
end\
elseif type(node[i])==\"string\" then\
map:add(color,bgcolor,align,erase,node,node[i])\
end\
end\
end\
function browserWindow:map(width,body,color,bgcolor,linkcolor,align)\
local map=htmlMap:new(width,color,bgcolor,align)\
if width>=1 then\
self:mapNode(map,body,color,bgcolor,linkcolor,align)\
end\
map:setAlignment()\
return map\
end\
function browserWindow:getMap(width)\
return self:map(width,self.brws__doc.html.body,\
(self.brws__doc.html.body.color or self:getColors().wndText),\
(self.brws__doc.html.body.bgcolor or self:getColors().wndBack),\
(self.brws__doc.html.body.linkcolor or colors.blue),\
(self.brws__doc.html.body.align or \"left\"))\
end\
function browserWindow:remap()\
local width=self.brws__doc:getWidth()\
if width>=self.width then\
self.brws__map=self:getMap(width)\
self:setScrollSize(width,self.brws__map:lastLine()+1)\
return\
end\
self.brws__map=self:getMap(self.width)\
if self.brws__map:lastLine()>=self.height then\
self.brws__map=self:getMap(self.width-1)\
end\
self:setScrollSize(0,self.brws__map:lastLine()+1)\
end\
function browserWindow:lines()\
return self.brws__map:lines()\
end\
function browserWindow:nodeFromPoint(x,y)\
return self.brws__map:nodeFromPoint(x,y)\
end\
function browserWindow:getHtml()\
return self.brws__doc:getHtml()\
end\
function browserWindow:getText()\
return self.brws__doc:getText()\
end\
function browserWindow:serialize()\
return self.brws__doc:serialize()\
end\
function browserWindow:docType()\
return self.brws__doc:type()\
end\
function browserWindow:mergeAddress(link,ref,protocol)\
local address;\
link=tostring(link)\
ref=tostring(ref)\
if link:find(\":\",1,true)then\
address=link\
else\
local links,current={},{}\
if ref:sub(1,5)==\"file:\" or ref:sub(1,1)==\"/\" then\
address=\"file:\"\
elseif protocol then\
address=protocol\
else\
address=\"http:\"\
end\
if ref:find(\":\",1,true)then\
ref=ref:sub(ref:find(\":\",1,true)+1)\
end\
for part in link:gmatch(\"[^%/]+\")do\
links[#links+1]=part\
end\
if links[1]==\"\" then\
table.remove(links,1)\
end\
for part in ref:gmatch(\"[^%/]+\")do\
current[#current+1]=part\
end\
if current[1]==\"\" then\
table.remove(current,1)\
end\
if #current>0 then\
table.remove(current,#current)\
end\
while links[1]==\"..\" do\
if #current>0 then\
table.remove(current,#current)\
end\
table.remove(links,1)\
end\
if #current>0 then\
if address==\"file:\" then\
address=address..\"/\"\
end\
address=address..current[1]\
for i=2,#current,1 do\
address=address..\"/\"..current[i]\
end\
end\
for i=1,#links,1 do\
address=address..\"/\"..links[i]\
end\
end\
return address\
end\
function browserWindow:splitAddress(address)\
local path,domain,protocol;\
address=tostring(address)..\"\"\
if address:sub(1,1)==\"/\" then\
protocol=\"file\"\
domain=\"\"\
path=address:sub(2)\
else\
local addr=\"\"\
if address:find(\":\",1,true)then\
protocol=address:sub(1,address:find(\":\",1,true)-1)..\"\"\
address=address:sub(address:find(\":\",1,true)+1)..\"\"\
else\
protocol=\"http\"\
end\
if address:find(\"/\",1,true)then\
domain=address:sub(1,address:find(\"/\",1,true)-1)..\"\"\
path=address:sub(address:find(\"/\",1,true)+1)..\"\"\
else\
domain=address\
path=\"\"\
end\
end\
return path,domain,protocol\
end\
function browserWindow:serverNotFound(address)\
local path,domain,protocol=self:splitAddress(address)\
local fmt=\"\\n\\nThe server \\\"%s\\\" was not found. It may be temporarily down or the address was entered incorrectly.\"\
self:setText(string.format(fmt,domain))\
end\
function browserWindow:draw(gdi,bounds)\
local first,last=self.brws__map:getRange(self.wnd__scrollY,\
self.wnd__scrollY+self.height)\
if first then\
local eraseLine=-1\
local erase=\"\"\
if self.width>0 then\
erase=string.rep(\" \",self.brws__map:getWidth())\
end\
for index=first,last,1 do\
local map=self.brws__map[index]\
if map.erase and map.line~=eraseLine then\
gdi:setBackgroundColor(map.erase)\
gdi:write(erase,0,map.line)\
eraseLine=map.line\
end\
if map.text:len()>0 then\
gdi:setBackgroundColor(map.bgcolor)\
gdi:setTextColor(map.color)\
gdi:write(map.text,map.column,map.line)\
end\
end\
end\
end\
function browserWindow:onMove()\
self:remap()\
return false\
end\
function browserWindow:setText(doc)\
self.brws__doc=htmlDoc:new(doc)\
self:remap()\
self:setColor(self.brws__map.color)\
self:setBgColor(self.brws__map.bgcolor)\
self:setScrollOrg(0,0)\
self:invalidate()\
end\
function browserWindow:onLeftClick(x,y)\
if win.window.onLeftClick(self,x,y)then\
return true\
end\
local node=self:nodeFromPoint(self:wndToScroll(x,y))\
if type(node)==\"table\" then\
if node.tag==\"a\" and self:getParent()then\
self:getParent():sendEvent(\"link_click\",self,node.href,node.protocol)\
end\
end\
return true\
end\
function browserWindow:onTouch(x,y)\
if win.window.onTouch(self,x,y)then\
return true\
end\
local node=self:nodeFromPoint(self:wndToScroll(x,y))\
if type(node)==\"table\" then\
if node.tag==\"a\" and self:getParent()then\
self:getParent():sendEvent(\"link_click\",self,node.href,node.protocol)\
end\
end\
return true\
end\
",
"local appArgs={...}\
local appFrame=win.createAppFrame()\
local APP_TITLE=\"notePad\"\
local ID_MENUBTN=100\
local ID_EDITOR=101\
local ID_FINDTEXT=102\
local ID_REPLACETEXT=103\
local ID_FIND=104\
local ID_REPLACE=105\
local ID_REPLACEALL=106\
local IDM_NEW=1001\
local IDM_OPEN=1002\
local IDM_SAVE=1003\
local IDM_SAVEAS=1004\
local IDM_PRINT=1005\
local IDM_UNDO=1006\
local IDM_REDO=1007\
local IDM_CUT=1008\
local IDM_COPY=1009\
local IDM_PASTE=1010\
local IDM_FIND=1011\
local IDM_FINDNEXT=1012\
local IDM_REPLACE=1013\
local IDM_QUITAPP=1014\
local function mergePath(name,path)\
path=asstring(path)\
name=asstring(name)\
if path:len()>1 then\
return path:sub(1,-(fs.getName(path):len()+1))..name\
else\
return \"/\"..name\
end\
end\
local findDlg=win.popupFrame:base()\
function findDlg:onCreate(findText)\
local width=math.floor(self:getOwner().width/2)\
self:dress(\"Find\")\
self.fd_find=win.inputWindow:new(self,ID_FINDTEXT,1,2,\
width-2,findText,\"Find\")\
win.buttonWindow:new(self,ID_FIND,width-5,3,\"Find\")\
self.fd_find:setSel(0,-1)\
self.fd_find:setFocus()\
self:move(self:getOwner().width-width,0,width,5)\
return true\
end\
function findDlg:onEvent(event,p1,p2,p3,p4,p5,...)\
if event==\"btn_click\" then\
if p1:getId()==ID_FIND then\
self:getOwner():sendEvent(\"find_next\",self.fd_find:getText())\
return true\
end\
end\
return false\
end\
function findDlg:onChildKey(wnd,key,ctrl,alt,shift)\
if win.popupFrame.onChildKey(self,wnd,key,ctrl,alt,shift)then\
return true\
end\
if ctrl and not alt and not shift then\
if key==keys.f then\
self:getOwner():sendEvent(\"find_next\",self.fd_find:getText())\
return true\
end\
end\
return false\
end\
local replaceDlg=win.popupFrame:base()\
function replaceDlg:onCreate(findText,replaceText)\
local width=math.floor(self:getOwner().width/2)\
self:dress(\"Replace\")\
self.rd_find=win.inputWindow:new(self,ID_FINDTEXT,1,2,\
width-2,findText,\"Find\")\
self.rd_replace=win.inputWindow:new(self,ID_REPLACETEXT,1,4,\
width-2,replaceText,\"Replace\")\
win.buttonWindow:new(self,ID_FIND,width-17,5,\"Find\")\
win.buttonWindow:new(self,ID_REPLACE,width-12,5,\"Replace\")\
win.buttonWindow:new(self,ID_REPLACEALL,width-4,5,\"All\")\
self.rd_replace:setSel(0,-1)\
self.rd_replace:setFocus()\
self:move(self:getOwner().width-width,0,width,7)\
return true\
end\
function replaceDlg:onEvent(event,p1,p2,p3,p4,p5,...)\
if event==\"btn_click\" then\
if p1:getId()==ID_FIND then\
self:getOwner():sendEvent(\"find_next\",self.rd_find:getText())\
return true\
end\
if p1:getId()==ID_REPLACE then\
self:getOwner():sendEvent(\"replace_one\",self.rd_find:getText(),\
self.rd_replace:getText())\
return true\
end\
if p1:getId()==ID_REPLACEALL then\
self:getOwner():sendEvent(\"replace_all\",self.rd_find:getText(),\
self.rd_replace:getText())\
self:close(win.ID_CLOSE)\
return true\
end\
end\
return false\
end\
function replaceDlg:onChildKey(wnd,key,ctrl,alt,shift)\
if win.popupFrame.onChildKey(self,wnd,key,ctrl,alt,shift)then\
return true\
end\
if ctrl and not alt and not shift then\
if key==keys.f then\
self:getOwner():sendEvent(\"find_next\",self.rd_find:getText())\
return true\
end\
if key==keys.r then\
self:getOwner():sendEvent(\"replace_one\",self.rd_find:getText(),\
self.rd_replace:getText())\
return true\
end\
if key==keys.a then\
self:getOwner():sendEvent(\"replace_all\",self.rd_find:getText(),\
self.rd_replace:getText())\
self:close(win.ID_CLOSE)\
return true\
end\
end\
return false\
end\
function appFrame:onMenu(x,y)\
local menu=win.menuWindow:new(self)\
x=x or 0\
y=y or 1\
menu:addString(\"New     Ctrl+N\",IDM_NEW)\
menu:addString(\"Open    Ctrl+O\",IDM_OPEN)\
if self.app_editor:getModified()then\
menu:addString(\"Save    Ctrl+S\",IDM_SAVE)\
end\
menu:addString(\"Save as\",IDM_SAVEAS)\
menu:addString(\"Print\",IDM_PRINT)\
menu:addString(\"--------------\")\
local doSep=false\
if self.app_editor:canUndo()then\
menu:addString(\"Undo    Ctrl+Z\",IDM_UNDO)\
doSep=true\
end\
if self.app_editor:canRedo()then\
menu:addString(\"Redo    Ctrl+Y\",IDM_REDO)\
doSep=true\
end\
if doSep then\
menu:addString(\"--------------\")\
end\
doSep=false\
local ss,se=self.app_editor:getSel()\
if ss~=se then\
menu:addString(\"Cut     Ctrl+X\",IDM_CUT)\
menu:addString(\"Copy    Ctrl+C\",IDM_COPY)\
doSep=true\
end\
if(self:getClipboard())==win.CB_TEXT then\
menu:addString(\"Paste   Ctrl+B\",IDM_PASTE)\
doSep=true\
end\
if doSep then\
menu:addString(\"--------------\")\
end\
menu:addString(\"Find    Ctrl+F\",IDM_FIND)\
if self.app_findText:len()>0 then\
menu:addString(\"Next        F3\",IDM_FINDNEXT)\
end\
menu:addString(\"Replace Ctrl+H\",IDM_REPLACE)\
menu:addString(\"--------------\")\
menu:addString(\"Quit\",IDM_QUITAPP)\
menu:track(x,y)\
end\
function appFrame:onCommand(cmdId)\
if cmdId==IDM_NEW then\
self:onNewFile()\
return true\
end\
if cmdId==IDM_OPEN then\
self:onOpenFile()\
return true\
end\
if cmdId==IDM_SAVE then\
if self.app_editor:getModified()then\
self:saveFile()\
end\
return true\
end\
if cmdId==IDM_SAVEAS then\
self:onSaveFileAs()\
return true\
end\
if cmdId==IDM_PRINT then\
self:printDoc()\
return true\
end\
if cmdId==IDM_UNDO then\
self.app_editor:undo()\
self.app_editor:setFocus()\
return true\
end\
if cmdId==IDM_REDO then\
self.app_editor:redo()\
self.app_editor:setFocus()\
return true\
end\
if cmdId==IDM_CUT then\
self.app_editor:cut()\
self.app_editor:setFocus()\
return true\
end\
if cmdId==IDM_COPY then\
self.app_editor:copy()\
self.app_editor:setFocus()\
return true\
end\
if cmdId==IDM_PASTE then\
self.app_editor:paste()\
self.app_editor:setFocus()\
return true\
end\
if cmdId==IDM_FIND then\
self:find()\
self.app_editor:setFocus()\
return true\
end\
if cmdId==IDM_FINDNEXT then\
self:findNext()\
self.app_editor:setFocus()\
return true\
end\
if cmdId==IDM_REPLACE then\
self:replace()\
self.app_editor:setFocus()\
return true\
end\
if cmdId==IDM_QUITAPP then\
self:quitApp()\
return true\
end\
return false\
end\
function appFrame:onEvent(event,p1,p2,p3,p4,p5,...)\
if event==\"btn_click\" then\
if p1:getId()==ID_MENUBTN then\
self:onMenu()\
return true\
end\
elseif event==\"menu_cmd\" then\
return self:onCommand(p1)\
elseif event==\"selection_change\" then\
if p1:getId()==ID_EDITOR then\
local ss,se=p1:getSel()\
local ln,cr=p1:lineFromChar(se)\
self.app_curPos:setText(string.format(\"l:%d c:%d\",(ln+1),(cr+1)))\
return true\
end\
elseif event==\"modified\" then\
if p1:getId()==ID_EDITOR then\
self.app_mod:setText(iif(p1:getModified(),\"mod\",\"\"))\
return true\
end\
elseif event==\"find_next\" then\
self:findNext(p1)\
elseif event==\"replace_one\" then\
self:replaceOne(p1,p2)\
elseif event==\"replace_all\" then\
self:replaceAll(p1,p2)\
return true\
end\
return false\
end\
function appFrame:newFile()\
self.app_editor:setText()\
self.app_editor:setFocus()\
self.app_curFile=\"untitled\"\
self.app_curPath=nil\
self:updateTitle()\
end\
function appFrame:onNewFile()\
if self.app_editor:getModified()then\
if not cmndlg.confirm(self,\
\"Modified\",\"\\\"\"..self.app_curFile..\
\"\\\" is not saved.\\nRenew anyway?\")then\
return\
end\
end\
self:newFile()\
end\
function appFrame:openFile(path)\
local hFile=fs.open(path,\"r\")\
if hFile then\
self.app_editor:setText(hFile.readAll())\
hFile.close()\
self.app_editor:setSel(0,0)\
self.app_curPath=path\
self.app_lastPath=path\
self.app_curFile=fs.getName(self.app_curPath)\
self:updateTitle()\
else\
self:msgBox(\"File Error\",\"Could not read file \"..path,colors.red)\
end\
end\
function appFrame:onOpenFile()\
if self.app_editor:getModified()then\
if not cmndlg.confirm(self,\
\"Modified\",\"\\\"\"..self.app_curFile..\
\"\\\" is not saved.\\nOpen file anyway?\")then\
return\
end\
end\
local path=cmndlg.openFile(self,mergePath(self.app_curFile,self.app_lastPath))\
if path then\
self:openFile(path)\
end\
end\
function appFrame:saveFileAs(path)\
local hFile=fs.open(path,\"w\")\
if hFile then\
hFile.write(self.app_editor:getText())\
hFile.close()\
self.app_editor:setModified(false)\
self.app_curPath=path\
self.app_lastPath=path\
self.app_curFile=fs.getName(self.app_curPath)\
self:updateTitle()\
else\
self:msgBox(\"File Error\",\"Could not write file \"..path,colors.red)\
end\
end\
function appFrame:onSaveFileAs()\
local path=cmndlg.saveFile(self,mergePath(self.app_curFile,self.app_lastPath))\
if path then\
self:saveFileAs(path)\
end\
end\
function appFrame:saveFile()\
if self.app_curPath then\
self:saveFileAs(self.app_curPath)\
else\
self:onSaveFileAs()\
end\
end\
function appFrame:find()\
local dlg=findDlg:new(self)\
local findText=self.app_editor:getSelectedText()\
if findText:len()<1 then\
findText=self.app_findText\
end\
dlg:doModal(findText)\
end\
function appFrame:findNext(findText,from)\
findText=tostring(findText or self.app_findText)\
if findText:len()>0 then\
self.app_findText=findText\
local ss,se=self.app_editor:getSel(true)\
local editText=self.app_editor:getText()\
local first,last=editText:find(self.app_findText,from or se,true)\
if first then\
self.app_editor:setSel(first-1,last)\
return first-1,last\
end\
end\
return nil\
end\
function appFrame:replace()\
local dlg=replaceDlg:new(self)\
local findText=self.app_editor:getSelectedText()\
if findText:len()<1 then\
findText=self.app_findText\
end\
dlg:doModal(findText,self.app_replaceText)\
end\
function appFrame:replaceOne(findText,replaceText)\
self.app_replaceText=tostring(replaceText or \"\")\
local first,last=appFrame:findNext(findText,(self.app_editor:getSel(true)))\
if first then\
self.app_editor:setSel(first,last,false)\
self.app_editor:replaceSel(self.app_replaceText,false)\
self.app_editor:setSel(first,first+self.app_replaceText:len())\
appFrame:findNext(findText)\
end\
end\
function appFrame:replaceAll(findText,replaceText)\
self.app_replaceText=tostring(replaceText or \"\")\
findText=tostring(findText or self.app_findText)\
if findText:len()>0 then\
self.app_findText=findText\
local invoked=os.clock()\
local editText=self.app_editor:getText()\
local first,last=editText:find(self.app_findText,(self.app_editor:getSel(true)),true)\
while first do\
if(os.clock()-invoked)>3.0 then\
sleep(0.1)\
invoked=os.clock()\
end\
self.app_editor:setSel(first-1,last,false)\
self.app_editor:replaceSel(self.app_replaceText,false)\
editText=editText:sub(1,first-1)..self.app_replaceText..editText:sub(last+1)\
last=first-1+self.app_replaceText:len()\
self.app_editor:setSel(first-1,last)\
first,last=editText:find(self.app_findText,last,true)\
end\
end\
end\
function appFrame:onPrintPage(gdi,page,data)\
local width,height=gdi:getPageSize()\
if not data.data.lines then\
data.data.lines=string.wrap(data.data.raw,width)\
end\
local topLine=((page-1)*height)+1\
local lastLine=iif((topLine+height)>#data.data.lines,\
#data.data.lines,topLine+height)\
for line=topLine,lastLine,1 do\
gdi:write(data.data.lines[line],0,line-topLine)\
end\
return(lastLine<#data.data.lines)\
end\
function appFrame:onPrintData()\
local pages;\
local title=self.app_curFile\
local data={}\
local ss,se=self.app_editor:getSel(true)\
if ss==se then\
local width,height=string.wrapSize(string.wrap(self.app_editor:getText(),25))\
pages=math.ceil(height/21)\
title=self.app_curFile\
data.raw=self.app_editor:getText()\
else\
pages=nil\
title=self.app_curFile..\" (range)\"\
data.raw=self.app_editor:getSelectedText()\
end\
return win.applicationFrame.onPrintData(self,title,data,pages)\
end\
function appFrame:onQuit()\
if self.app_editor:getModified()then\
if not cmndlg.confirm(self,\
\"Modified\",\"\\\"\"..self.app_curFile..\
\"\\\" is not saved.\\nQuit anyway?\")then\
return true\
end\
end\
return false\
end\
function appFrame:updateTitle()\
self:setTitle(self.app_curFile..\":\"..APP_TITLE)\
end\
function appFrame:onMove()\
self.app_editor:move(1,1,self.width-2,self.height-2)\
self.app_curPos:move(1,self.height-1)\
self.app_mod:move(self.width-4,self.height-1)\
return false\
end\
function appFrame:onChildKey(wnd,key,ctrl,alt,shift)\
if key==keys.tab then\
if not ctrl and not alt and not shift and wnd==self.app_editor then\
return false\
end\
end\
if win.applicationFrame.onChildKey(self,wnd,key,ctrl,alt,shift)then\
return true\
end\
if ctrl and not alt and not shift then\
if key==keys.n then\
return self:onCommand(IDM_NEW)\
end\
if key==keys.o then\
return self:onCommand(IDM_OPEN)\
end\
if key==keys.s then\
return self:onCommand(IDM_SAVE)\
end\
if key==keys.f then\
return self:onCommand(IDM_FIND)\
end\
if key==keys.h then\
return self:onCommand(IDM_REPLACE)\
end\
elseif not ctrl and alt and not shift then\
if key==keys.m then\
self:onMenu()\
return true\
end\
elseif not ctrl and not alt and not shift then\
if key==keys.f3 then\
return self:onCommand(IDM_FINDNEXT)\
end\
end\
return false\
end\
function appFrame:onChildRightClick(child,x,y)\
if child==self.app_editor then\
self.app_editor:setFocus()\
self:onMenu(self:screenToWnd(x,y))\
return true\
end\
return false\
end\
function appFrame:onCreate()\
self:dress(APP_TITLE)\
local menuBtn=win.buttonWindow:new(self,ID_MENUBTN,0,0,\"Menu\")\
menuBtn:setColors(menuBtn:getColors().frameText,\
menuBtn:getColors().titleBack,\
menuBtn:getColors().frameBack)\
menuBtn:move(nil,nil,nil,nil,win.WND_TOP)\
self.app_editor=win.editWindow:new(self,ID_EDITOR,1,1,self.width-2,self.height-2)\
self.app_editor:setColors(self:getColors().inputText,\
self:getColors().inputBack,\
self:getColors().inputBack,\
self:getColors().inputBanner,\
self:getColors().inputError)\
self.app_editor:setFocus()\
self.app_curPos=win.labelWindow:new(self,0,1,self.height-1,\"l:1 c:1        \")\
self.app_mod=win.labelWindow:new(self,0,self.width-4,self.height-1,\"    \")\
self.app_curPath=nil\
self.app_lastPath=nil\
self.app_curFile=\"untitled\"\
self.app_findText=\"\"\
self.app_replaceText=\"\"\
local iniFile=fs.loadIniFile(self:getAppPath()..\".ini\")\
local tabSize=2\
if iniFile then\
tabSize=asnumber(iniFile:find(\"tab\"),2)\
end\
self.app_editor:setTabWidth(tabSize)\
if #appArgs>0 then\
self:openFile(appArgs[1])\
else\
self:newFile()\
end\
self:setActiveTopFrame()\
return true\
end\
appFrame:runApp()",
"tab=2",
"local appArgs={...}\
local appFrame=win.createAppFrame()\
local APP_TITLE=\"explore\"\
local ID_MENUBTN=100\
local ID_FILELIST=101\
local ID_STATUS=102\
local IDM_UPDIR=1000\
local IDM_OPEN=1001\
local IDM_RUN=1002\
local IDM_NEWDIR=1003\
local IDM_RENAME=1004\
local IDM_LABEL=1005\
local IDM_DELETE=1006\
local IDM_COPY=1007\
local IDM_PASTE=1008\
local IDM_QUITAPP=1009\
local TYPE_UP=0\
local TYPE_DIR=1\
local TYPE_FILE=2\
local function pathFolder(path)\
path=asstring(path)\
if path:len()>1 then\
if path:sub(-1,-1)==\"/\" then\
path=path:sub(1,-2)\
end\
local lastName=fs.getName(path)\
path=path:sub(1,-(lastName:len()+1))\
else\
path=\"/\"\
end\
return path\
end\
local function isSubOf(parent,sub)\
if parent:sub(-1,-1)~=\"/\" then\
parent=parent..\"/\"\
end\
if sub:sub(-1,-1)~=\"/\" then\
sub=sub..\"/\"\
end\
while sub~=\"/\" do\
if sub==parent then\
return true\
end\
sub=pathFolder(sub)\
end\
return false\
end\
local function canPaste(itemPath,toDir)\
if fs.exists(itemPath)and not fs.isReadOnly(toDir)then\
if pathFolder(itemPath)~=toDir then\
local copyPath=toDir..fs.getName(itemPath)\
if isSubOf(itemPath,copyPath)and fs.isDir(itemPath)then\
return false\
end\
if isSubOf(copyPath,itemPath)then\
return false\
end\
end\
return true\
end\
return false\
end\
local function getDrive(path)\
path=tostring(path or \"\")\
if fs.getDrive(path)then\
if path:sub(1,1)==\"/\" then\
path=path:sub(2)\
end\
for k,v in pairs(peripheral.getNames())do\
if peripheral.getType(v)==\"drive\" then\
if disk.hasData(v)then\
if path==disk.getMountPath(v)then\
return v\
end\
end\
end\
end\
end\
return nil\
end\
local function getLabel(path)\
local drive=getDrive(path)\
if drive then\
return disk.getLabel(drive)\
end\
return nil\
end\
function appFrame:onMenu(x,y)\
local menu=win.menuWindow:new(self)\
local sep=false\
x=x or 0\
y=y or 1\
if self.app_items:getData(1)then\
if self.app_items:getData(1).type==TYPE_UP then\
if self.app_curDir:len()>1 then\
menu:addString(\"Up      Ctrl+^\",IDM_UPDIR)\
sep=true\
end\
end\
end\
if not fs.isReadOnly(self.app_curDir)then\
menu:addString(\"New     Ctrl+N\",IDM_NEWDIR)\
sep=true\
end\
if self.app_items:getData()then\
menu:addString(\"Open    Ctrl+O\",IDM_OPEN)\
sep=true\
end\
if self.app_items:getData()then\
if self.app_items:getData().type==TYPE_FILE then\
menu:addString(\"Run     Ctrl+P\",IDM_RUN)\
sep=true\
end\
end\
if self:getSelectedPath()then\
if not fs.isReadOnly(self:getSelectedPath())and\
not getDrive(self:getSelectedPath())then\
menu:addString(\"Rename  Ctrl+R\",IDM_RENAME)\
menu:addString(\"Delete  Del\",IDM_DELETE)\
sep=true\
end\
end\
if self:getSelectedPath()then\
if not fs.isReadOnly(self:getSelectedPath())and\
getDrive(self:getSelectedPath())then\
menu:addString(\"Label   Ctrl+L\",IDM_LABEL)\
sep=true\
end\
end\
if sep then\
menu:addString(\"--------------\")\
sep=false\
end\
if self:getSelectedPath()then\
menu:addString(\"Copy    Ctrl+C\",IDM_COPY)\
sep=true\
end\
local cbType,cbPath=self:getClipboard()\
if cbType==win.CB_TEXT then\
if canPaste(cbPath,self.app_curDir)then\
menu:addString(\"Paste   Ctrl+B\",IDM_PASTE)\
sep=true\
end\
end\
if sep then\
menu:addString(\"--------------\")\
end\
menu:addString(\"Quit\",IDM_QUITAPP)\
menu:track(x,y)\
end\
function appFrame:onCommand(cmdId)\
if cmdId==IDM_UPDIR then\
if self.app_items:getData(1)then\
if self.app_items:getData(1).type==TYPE_UP then\
if self.app_curDir:len()>1 then\
self.app_curDir=pathFolder(self.app_curDir)\
self:fillList()\
end\
end\
end\
return true\
end\
if cmdId==IDM_OPEN then\
self:openFile()\
return true\
end\
if cmdId==IDM_RUN then\
self:runFile()\
return true\
end\
if cmdId==IDM_NEWDIR then\
self:onNewDir()\
return true\
end\
if cmdId==IDM_RENAME then\
self:onRename()\
return true\
end\
if cmdId==IDM_LABEL then\
self:onLabelDisk()\
return true\
end\
if cmdId==IDM_DELETE then\
self:onDelete()\
return true\
end\
if cmdId==IDM_COPY then\
self:copy(self:getSelectedPath())\
return true\
end\
if cmdId==IDM_PASTE then\
self:paste()\
return true\
end\
if cmdId==IDM_QUITAPP then\
self:quitApp()\
return true\
end\
return false\
end\
function appFrame:fillList()\
if not fs.isDir(self.app_curDir)then\
self.app_curDir=\"/\"\
end\
local sel=self.app_items:getCurSel()\
local item=self.app_items:getString()\
local items=fs.list(self.app_curDir)\
table.sort(items)\
self.app_items:resetContent()\
if self.app_curDir:len()>1 then\
self.app_items:addString(\"..\",{type=TYPE_UP,name=\"..\"})\
end\
for i=1,#items,1 do\
if fs.isDir(self.app_curDir..items[i])then\
local name=\"/\"..items[i]\
local label=getLabel(self.app_curDir..items[i])\
if label then\
name=name..\" [\"..label..\"]\"\
end\
self.app_items:addString(name,{type=TYPE_DIR,name=items[i]})\
end\
end\
for i=1,#items,1 do\
if not fs.isDir(self.app_curDir..items[i])then\
self.app_items:addString(items[i],{type=TYPE_FILE,name=items[i]})\
end\
end\
if item then\
local index=self.app_items:find(item,0,true)\
if index>0 then\
self.app_items:setCurSel(index)\
sel=0\
end\
end\
if sel>0 then\
self.app_items:setCurSel(sel)\
end\
self:updateTitle()\
self:updateStatus()\
end\
function appFrame:getSelectedPath()\
if self.app_items:getData()then\
if self.app_items:getData().type~=TYPE_UP then\
return(self.app_curDir..self.app_items:getData().name)\
end\
end\
return nil\
end\
function appFrame:doDefaultAction()\
if self.app_items:getData()then\
if self.app_items:getData().type==TYPE_UP then\
if self.app_curDir:len()>1 then\
self.app_curDir=pathFolder(self.app_curDir)\
self.app_items:setCurSel(0)\
self:fillList()\
end\
elseif self.app_items:getData().type==TYPE_DIR then\
self.app_curDir=self:getSelectedPath()..\"/\"\
self.app_items:setCurSel(0)\
self:fillList()\
elseif self.app_items:getData().type==TYPE_FILE then\
self:openFile(self:getSelectedPath())\
end\
end\
end\
function appFrame:onEvent(event,p1,p2,p3,p4,p5,...)\
if event==\"btn_click\" then\
if p1:getId()==ID_MENUBTN then\
self:onMenu()\
return true\
end\
elseif event==\"menu_cmd\" then\
return self:onCommand(p1)\
elseif event==\"selection_change\" then\
if p1:getId()==ID_FILELIST then\
self:updateStatus()\
return true\
end\
elseif event==\"list_click\" then\
if p1:getId()==ID_FILELIST then\
return true\
end\
elseif event==\"list_double_click\" then\
if p1:getId()==ID_FILELIST then\
self:doDefaultAction()\
return true\
end\
elseif event==\"disk_eject\" then\
if self.app_curDir==\"/\" then\
self:fillList()\
elseif not fs.exists(self.app_curDir)then\
self.app_curDir=\"/\"\
self:fillList()\
end\
return true\
elseif event==\"disk\" then\
if self.app_curDir==\"/\" then\
self:fillList()\
end\
return true\
end\
return false\
end\
function appFrame:newDir(path)\
fs.makeDir(path)\
self:fillList()\
end\
local function validateNewDir(name)\
return(not fs.exists(appFrame.app_curDir..name))and\
(not name:find(\"/\",1,true))and\
(not name:find(\" \",1,true))\
end\
function appFrame:onNewDir()\
if not fs.isReadOnly(self.app_curDir)then\
local folder=cmndlg.input(self,\"New Folder\",\"Enter new folder name.\",\
\"new\",\"Name\",nil,validateNewDir)\
if folder then\
self:newDir(self.app_curDir..folder)\
end\
end\
end\
function appFrame:openFile(path)\
if not path then\
if not self.app_items:getData()then\
return\
end\
if self.app_items:getData().type==TYPE_UP then\
path=pathFolder(self.app_curDir)\
else\
path=self:getSelectedPath()\
end\
end\
if fs.isDir(path)then\
self:getDesktop():runApp(appFrame:getAppPath(),path)\
else\
local iniFile=fs.loadIniFile(appFrame:getAppPath()..\".asc\")\
if iniFile then\
local progPath=iniFile:find(fs.getExtension(path))\
if not progPath then\
progPath=iniFile:find(\"<default>\")\
end\
if progPath then\
self:getDesktop():runApp(progPath,\"\\\"\"..path..\"\\\"\")\
end\
end\
end\
end\
function appFrame:runFile(path)\
if not path then\
if not self.app_items:getData()then\
return\
end\
if self.app_items:getData().type==TYPE_UP then\
self:openFile(pathFolder(self.app_curDir))\
return\
elseif self.app_items:getData().type==TYPE_DIR then\
self:openFile(self:getSelectedPath())\
return\
else\
path=self:getSelectedPath()\
end\
end\
local file=fs.open(path,\"r\")\
if not file then\
self:msgBox(\"Error\",\"File error \"..path,colors.red)\
return\
end\
local content=file.readAll()\
local isApp=(content:find(\"win.createAppFrame\",1,true)and\
content:find(\"runApp\",1,true))or\
not fs.exists(\"/win/apps/cmd\")\
file.close()\
if isApp then\
self:getDesktop():runApp(path)\
else\
self:getWorkSpace():runApp(self:getSide(),\"/win/apps/cmd\",\"\\\"\"..path..\"\\\"\")\
self:getDesktop():loadAppList()\
end\
end\
function appFrame:rename(path,newName)\
fs.move(path,pathFolder(path)..newName)\
self:fillList()\
end\
local function validateRename(name)\
return(not fs.exists(pathFolder(appFrame:getSelectedPath())..name))and\
(not name:find(\"/\",1,true))\
end\
function appFrame:onRename()\
local path=self:getSelectedPath()\
if path then\
if not fs.isReadOnly(path)and not getDrive(path)then\
local name=cmndlg.input(self,\"Rename\",\
\"Rename \"..fs.getName(path)..\" to:\",\
fs.getName(path),\
\"Name\",nil,validateRename)\
if name then\
self:rename(path,name)\
end\
end\
end\
end\
function appFrame:labelDisk(drive,label)\
disk.setLabel(drive,label)\
self:fillList()\
end\
function appFrame:onLabelDisk()\
local drive=getDrive(self:getSelectedPath())\
if drive then\
local curLabel=disk.getLabel(drive)or \"\"\
local label=cmndlg.input(self,\"Label\",\
\"Label disk \"..tostring(disk.getID(drive))..\" from \"..curLabel..\" to:\",\
curLabel,\"Label\")\
if label then\
if label:len()<1 then\
label=nil\
end\
self:labelDisk(drive,label)\
end\
end\
end\
function appFrame:delete(path)\
fs.delete(path)\
self:fillList()\
end\
function appFrame:onDelete()\
local path=self:getSelectedPath()\
if path then\
if not fs.isReadOnly(path)then\
if fs.isDir(path)then\
if not cmndlg.confirm(self,\"Delete Folder\",\
\"Delete \"..fs.getName(path)..\" and all of its contents?\",\
false,colors.orange)then\
return\
end\
else\
if not cmndlg.confirm(self,\"Delete File\",\
\"Delete \"..fs.getName(path)..\"?\",\
false,colors.orange)then\
return\
end\
end\
self:delete(path)\
end\
end\
end\
function appFrame:copy(path)\
if path then\
self:setClipboard(path,win.CB_TEXT)\
end\
end\
function appFrame:paste()\
local cbType,cbPath=self:getClipboard()\
if cbType==win.CB_TEXT then\
if canPaste(cbPath,self.app_curDir)then\
local copyPath;\
if pathFolder(cbPath)==self.app_curDir then\
local counter=1\
copyPath=string.format(\"%s_%d\",cbPath,counter)\
while fs.exists(copyPath)do\
counter=counter+1\
copyPath=string.format(\"%s_%d\",cbPath,counter)\
end\
else\
copyPath=self.app_curDir..fs.getName(cbPath)\
if fs.exists(copyPath)then\
if fs.isDir(copyPath)then\
if not cmndlg.confirm(self,\"Overwrite\",\
\"Folder \"..fs.getName(cbPath)..\
\" already exists.\\nOverwrite all of its contents?\",\
false,colors.orange)then\
return\
end\
else\
if not cmndlg.confirm(self,\"Overwrite\",\
\"File \"..fs.getName(cbPath)..\
\" already exists.\\nOverwrite?\",\
false,colors.orange)then\
return\
end\
end\
end\
end\
if fs.exists(copyPath)then\
fs.delete(copyPath)\
end\
fs.copy(cbPath,copyPath)\
self:fillList()\
end\
end\
end\
function appFrame:updateStatus()\
local info;\
if self:getSelectedPath()then\
if fs.isDir(self:getSelectedPath())then\
local freeSize=\
math.floor((fs.getFreeSpace(self:getSelectedPath())+50)/100)/10\
info=string.format(\"%d items %fkb free\",\
table.maxn(fs.list(self:getSelectedPath())),\
freeSize)\
else\
local freeSize=\
math.floor((fs.getFreeSpace(self.app_curDir)+50)/100)/10\
local fileSize=fs.getSize(self:getSelectedPath())\
local fileFlags=iif(fs.isReadOnly(self:getSelectedPath()),\" (r)\",\"\")\
if fileSize>=1024 then\
fileSize=math.floor((fileSize+50)/100)/10\
info=string.format(\"%fkb%s %fkb free\",fileSize,fileFlags,freeSize)\
else\
info=string.format(\"%dbytes%s %fkb free\",fileSize,fileFlags,freeSize)\
end\
end\
end\
if not info then\
local freeSize=math.floor((fs.getFreeSpace(self.app_curDir)+50)/100)/10\
info=string.format(\"%fkb free\",freeSize)\
end\
self.app_status:setText(info)\
end\
function appFrame:updateTitle()\
local curPath=string.trim(self.app_curDir,\"/\")\
if curPath:len()>0 then\
self:setTitle(curPath..\":\"..APP_TITLE)\
else\
self:setTitle(APP_TITLE)\
end\
end\
function appFrame:onMove()\
self.app_items:move(1,1,self.width-2,self.height-2)\
self.app_status:move(1,self.height-1,self.width-2,1)\
return false\
end\
function appFrame:onFrameActivate(active)\
if active then\
local sel=self.app_items:getCurSel()\
self:fillList()\
self.app_items:setCurSel(sel)\
end\
end\
function appFrame:onChildKey(wnd,key,ctrl,alt,shift)\
if win.applicationFrame.onChildKey(self,wnd,key,ctrl,alt,shift)then\
return true\
end\
if self:getFocus()==self.app_items then\
if ctrl and not alt and not shift then\
if key==keys.o then\
return self:onCommand(IDM_OPEN)\
end\
if key==keys.p then\
return self:onCommand(IDM_RUN)\
end\
if key==keys.n then\
return self:onCommand(IDM_NEWDIR)\
end\
if key==keys.r then\
return self:onCommand(IDM_RENAME)\
end\
if key==keys.l then\
return self:onCommand(IDM_LABEL)\
end\
if key==keys.c then\
return self:onCommand(IDM_COPY)\
end\
if key==keys.b then\
return self:onCommand(IDM_PASTE)\
end\
if key==keys.up then\
return self:onCommand(IDM_UPDIR)\
end\
elseif not ctrl and alt and not shift then\
if key==keys.m then\
self:onMenu()\
return true\
end\
elseif not ctrl and not alt and not shift then\
if key==keys.delete then\
return self:onCommand(IDM_DELETE)\
end\
if key==keys.enter then\
self:doDefaultAction()\
return true\
end\
end\
end\
return false\
end\
function appFrame:onChildRightClick(child,x,y)\
if child==self.app_items then\
self.app_items:setFocus()\
self:onMenu(self:screenToWnd(x,y))\
return true\
end\
return false\
end\
function appFrame:onCreate()\
self:dress(APP_TITLE)\
local menuBtn=win.buttonWindow:new(self,ID_MENUBTN,0,0,\"Menu\")\
menuBtn:setColors(menuBtn:getColors().frameText,\
menuBtn:getColors().titleBack,\
menuBtn:getColors().frameBack)\
menuBtn:move(nil,nil,nil,nil,win.WND_TOP)\
self.app_items=win.listWindow:new(self,ID_FILELIST,1,1,self.width-2,self.height-2)\
self.app_items:setColors(self:getColors().wndText,\
self:getColors().wndBack,\
self:getColors().wndBack,\
self:getColors().selectedText,\
self:getColors().selectedBack)\
self.app_items:setFocus()\
self.app_status=win.labelWindow:new(self,ID_STATUS,1,self.height-1,\"\")\
self.app_status:move(1,self.height-1,self.width-2,1)\
self:wantEvent(\"disk\")\
self:wantEvent(\"disk_eject\")\
self.app_curDir=\"/\"\
if #appArgs>0 then\
local initPath=asstring(appArgs[1])\
if initPath:len()>1 then\
if initPath:sub(-2)==\"/\" then\
if fs.isDir(initPath)then\
self.app_curDir=initPath\
end\
elseif fs.exists(initPath)then\
if fs.isDir(initPath)then\
self.app_curDir=initPath..\"/\"\
else\
initPath=initPath:sub(1,-(fs.getName(initPath):len()+1))\
if fs.isDir(initPath)then\
self.app_curDir=initPath\
end\
end\
end\
end\
end\
self:fillList()\
self:setActiveTopFrame()\
return true\
end\
appFrame:runApp()",
"<default>=/win/apps/notepad\
html=/win/apps/browse\
htm=/win/apps/browse\
email=/win/apps/emread\
",
"local appArgs={...}\
local appFrame=win.createAppFrame()\
local APP_TITLE=\"browse\"\
local ID_MENUBTN=100\
local ID_ADDRESS=101\
local ID_REQUEST=102\
local ID_VIEWER=103\
local IDM_OPEN=1001\
local IDM_SAVEAS=1002\
local IDM_PRINT=1003\
local IDM_BACK=1004\
local IDM_FORWARD=1005\
local IDM_SHOWBAR=1006\
local IDM_QUITAPP=1007\
local history=win.__classBase:base()\
function history:constructor(strict)\
self.hist__cache={}\
self.hist__index=0\
self.strict=strict==true\
return self\
end\
function history:cache(address)\
if address:sub(1,4)~=\"ftp:\" then\
if self.strict then\
while #self.hist__cache>self.hist__index do\
table.remove(self.hist__cache,#self.hist__cache)\
end\
self.hist__index=self.hist__index+1\
self.hist__cache[self.hist__index]=address\
else\
for i=#self.hist__cache,1,-1 do\
if self.hist__cache[i]==address then\
table.remove(self.hist__cache,i)\
end\
end\
self.hist__cache[#self.hist__cache+1]=address\
self.hist__index=#self.hist__cache\
end\
end\
end\
function history:canNext()\
return self.hist__index<#self.hist__cache\
end\
function history:canPrior()\
return self.hist__index>1\
end\
function history:next()\
if self:canNext()then\
self.hist__index=self.hist__index+1\
return self.hist__cache[self.hist__index]\
end\
return nil\
end\
function history:prior()\
if self:canPrior()then\
self.hist__index=self.hist__index-1\
return self.hist__cache[self.hist__index]\
end\
return nil\
end\
function history:clear()\
self.hist__cache={}\
self.hist__index=0\
end\
function appFrame:onReceive(msg)\
if(msg.recipientName or msg.recipientId)then\
if msg.data.path and msg.data.content then\
if msg.context==\"http_response\" then\
self.app_viewer:setText(msg.data.content)\
self.app_curAddress=msg.data.path\
self.app_curFile=self.app_viewer:getTitle(fs.getName(msg.data.path))\
self:updateTitle()\
return true\
end\
if msg.context==\"ftp_response\" then\
local path=cmndlg.saveFile(self,fs.getName(msg.data.path),\
nil,nil,self:safePopupColor())\
if path then\
local hFile=fs.open(path,\"w\")\
if hFile then\
hFile.write(msg.data.content)\
hFile.close()\
self.app_curPath=path\
else\
self:msgBox(\"File Error\",\"Could not write file \"..path,colors.red)\
end\
end\
return true\
end\
end\
end\
return false\
end\
function appFrame:onSent(msg,success)\
if not success then\
if msg.context==\"ftp_request\" then\
self:msgBox(\"Error\",\
\"Could not download \"..msg.data.path..\" from \"..msg.recipientName..\
\".\\nThe server may be down or the file does not exist.\",colors.red)\
else\
self.app_viewer:serverNotFound(msg.data.address)\
end\
end\
return true\
end\
function appFrame:onEvent(event,p1,p2,p3,p4,p5,...)\
if event==\"btn_click\" then\
if p1:getId()==ID_MENUBTN then\
self:onMenu()\
return true\
end\
if p1:getId()==ID_REQUEST then\
self:onSendRequest()\
return true\
end\
elseif event==\"menu_cmd\" then\
return self:onCommand(p1)\
elseif event==\"link_click\" then\
self:onSendRequest(self.app_viewer:mergeAddress(p2,self.app_curAddress,p3))\
return true\
end\
return false\
end\
function appFrame:onPrintPage(gdi,page,data)\
local width,height=gdi:getPageSize()\
local map=data.data.map\
local topLine=((page-1)*height)\
local firstMap,lastMap=map:getRange(topLine,topLine+height-1)\
if firstMap then\
for i=firstMap,lastMap,1 do\
if map[i].text:len()>0 then\
gdi:write(map[i].text,map[i].column,(map[i].line-topLine))\
end\
end\
end\
return(lastMap<#map)\
end\
function appFrame:onPrintData()\
local title=self.app_curFile\
local data=\
{\
map=self.app_viewer:getMap(25)\
}\
local pages=math.ceil(data.map:lines()/21)\
if title:sub(-4)==\".htm\" then\
title=title:sub(1,-5)\
elseif title:sub(-5)==\".html\" then\
title=title:sub(1,-6)\
end\
return win.applicationFrame.onPrintData(self,title,data,pages,self:safePopupColor())\
end\
function appFrame:onMove()\
if self:isBarVisible()then\
self.app_address:move(2,1,self.width-5)\
self.app_request:move(self.width-3)\
self.app_viewer:move(0,2,self.width,self.height-2)\
else\
self.app_viewer:move(0,1,self.width,self.height-1)\
end\
return false\
end\
function appFrame:onChildKey(wnd,key,ctrl,alt,shift)\
if win.applicationFrame.onChildKey(self,wnd,key,ctrl,alt,shift)then\
return true\
end\
if not ctrl and not alt and not shift then\
if key==keys.enter then\
if wnd==self.app_address then\
self:onSendRequest()\
return true\
end\
end\
if key==keys.up then\
if wnd==self.app_address then\
self:onPriorAddress()\
return true\
end\
end\
if key==keys.down then\
if wnd==self.app_address then\
self:onNextAddress()\
return true\
end\
end\
elseif ctrl and not alt and not shift then\
if key==keys.left then\
return self:onCommand(IDM_BACK)\
end\
if key==keys.right then\
return self:onCommand(IDM_FORWARD)\
end\
if key==keys.o then\
return self:onCommand(IDM_OPEN)\
end\
if key==keys.n then\
return self:onCommand(IDM_SHOWBAR)\
end\
elseif not ctrl and alt and not shift then\
if key==keys.m then\
self:onMenu()\
return true\
end\
end\
return false\
end\
function appFrame:onQuit()\
if self.connectionName then\
self:commClose(self.connectionName)\
end\
return false\
end\
function appFrame:onCreate()\
self:dress(APP_TITLE)\
local menuBtn=win.buttonWindow:new(self,ID_MENUBTN,0,0,\"Menu\")\
menuBtn:setColors(menuBtn:getColors().frameText,\
menuBtn:getColors().titleBack,\
menuBtn:getColors().frameBack)\
menuBtn:move(nil,nil,nil,nil,win.WND_TOP)\
self.app_address=win.inputWindow:new(self,ID_ADDRESS,2,1,\
self.width-5,\"\",\"Address\")\
self.app_request=win.buttonWindow:new(self,ID_REQUEST,\
self.width-3,1,\">\")\
self.app_viewer=html.browserWindow:new(self,ID_VIEWER,0,2,\
self.width,self.height-2)\
self.app_address:setFocus()\
self.app_curAddress=nil\
self.app_curPath=nil\
self.app_curFile=\"\"\
self.app_networkId=\"wide_area_network\"\
self.app_appId=APP_TITLE..tostring(math.random(1,65535))\
self.app_addressHistory=history:new(false)\
self.app_pageHistory=history:new(true)\
if #appArgs>0 then\
if appArgs[1]==\"-a\" then\
self:showBar(false)\
if #appArgs>1 then\
self:onSendRequest(appArgs[2])\
end\
else\
self:onSendRequest(appArgs[1])\
end\
end\
self:setActiveTopFrame()\
return true\
end\
function appFrame:onMenu()\
local menu=win.menuWindow:new(self)\
menu:addString(\"Open     Ctrl+O\",IDM_OPEN)\
menu:addString(\"Save as\",IDM_SAVEAS)\
menu:addString(\"Print\",IDM_PRINT)\
menu:addString(\"----------------\")\
local sep=false\
if self.app_pageHistory:canPrior()then\
menu:addString(\"Back    Ctrl+<-\",IDM_BACK)\
sep=true\
end\
if self.app_pageHistory:canNext()then\
menu:addString(\"Forward Ctrl+->\",IDM_FORWARD)\
sep=true\
end\
if sep then\
menu:addString(\"----------------\")\
end\
if self:isBarVisible()then\
menu:addString(\"Hide bar Ctrl+N\",IDM_SHOWBAR)\
else\
menu:addString(\"Show bar Ctrl+N\",IDM_SHOWBAR)\
end\
menu:addString(\"----------------\")\
menu:addString(\"Quit\",IDM_QUITAPP)\
menu:track(0,1)\
end\
function appFrame:onCommand(cmdId)\
if cmdId==IDM_OPEN then\
self:onOpenFile()\
return true\
end\
if cmdId==IDM_SAVEAS then\
self:onSaveFileAs()\
return true\
end\
if cmdId==IDM_PRINT then\
self:printDoc()\
return true\
end\
if cmdId==IDM_BACK then\
self:onBack()\
return true\
end\
if cmdId==IDM_FORWARD then\
self:onForward()\
return true\
end\
if cmdId==IDM_SHOWBAR then\
self:showBar()\
return true\
end\
if cmdId==IDM_QUITAPP then\
self:quitApp()\
return true\
end\
return false\
end\
function appFrame:showBar(show)\
show=show or(not self:isBarVisible())\
self.app_address:show(show)\
self.app_request:show(show)\
self:onMove()\
if show then\
self.app_address:setSel(0,-1)\
self.app_address:setFocus()\
end\
end\
function appFrame:isBarVisible()\
return self.app_address:isShown()\
end\
function appFrame:connect()\
if not self.connectionName then\
local port=80\
local wireless=true\
local timeout=5\
local ini=fs.loadIniFile(self:getAppPath()..\".ini\")\
if ini then\
port=asnumber(ini:find(\"port\"),80)\
timeout=asnumber(ini:find(\"timeout\"),5)\
self.app_networkId=(ini:find(\"network\"))or self.app_networkId\
wireless=((ini:find(\"wireless\"))or \"true\")~=\"false\"\
end\
local con=self:commOpen(nil,wireless,port,timeout,false)\
if not con then\
self:msgBox(\"Connection\",\"Could not connect to modem!\",colors.red)\
return false\
end\
self.connectionName=con:getName()\
self:wantMessages(self.app_appId,self.connectionName)\
self:wantMessages(self.app_networkId,self.connectionName)\
end\
return true\
end\
function appFrame:updateTitle()\
if self.app_curFile:len()>0 then\
self:setTitle(self.app_curFile..\":\"..APP_TITLE)\
else\
self:setTitle(APP_TITLE)\
end\
end\
function appFrame:openFile(path)\
path=tostring(path)\
if path:sub(1,5)==\"file:\" then\
path=path:sub(6)\
end\
local hFile=fs.open(path,\"r\")\
if hFile then\
self.app_viewer:setText(hFile.readAll())\
hFile.close()\
self.app_curPath=path\
self.app_curAddress=\"file:\"..path\
self.app_curFile=self.app_viewer:getTitle(fs.getName(self.app_curPath))\
self:updateTitle()\
else\
self:msgBox(\"File Error\",\"Could not read file \"..path,colors.red)\
end\
end\
function appFrame:onOpenFile()\
local path=cmndlg.openFile(self,self.app_curPath,nil,nil,nil,\
self:safePopupColor())\
if path then\
self:onSendRequest(\"file:\"..path)\
end\
end\
function appFrame:saveFileAs(path)\
local hFile=fs.open(path,\"w\")\
if hFile then\
hFile.write(self.app_viewer:serialize())\
hFile.close()\
self.app_curPath=path\
self.app_curFile=fs.getName(self.app_curPath)\
self:updateTitle()\
else\
self:msgBox(\"File Error\",\"Could not write file \"..path,colors.red)\
end\
end\
function appFrame:onSaveFileAs()\
local path=cmndlg.saveFile(self,self.app_curPath,nil,nil,\
self:safePopupColor())\
if path then\
self:saveFileAs(path)\
end\
end\
function appFrame:sendRequest(address)\
if self:connect()then\
local path,domain,protocol=self.app_viewer:splitAddress(address)\
local context=protocol..\"_request\"\
self:sendMessage(domain,self.app_networkId,context,\
{\
application=self.app_appId,\
protocol=protocol,\
domain=domain,\
path=path,\
address=address\
},self.connectionName)\
end\
end\
function appFrame:onSendRequest(address,record)\
address=address or self.app_address:getText()\
if address:len()>0 then\
local path,domain,protocol=self.app_viewer:splitAddress(address)\
address=protocol..\":\"..domain..\"/\"..path\
if protocol==\"file\" then\
self:openFile(\"/\"..path)\
else\
self:sendRequest(address)\
end\
self.app_address:setText(address)\
self.app_address:setSel(0,0)\
self.app_address:setSel(0,-1)\
self.app_address:setFocus()\
self.app_addressHistory:cache(address)\
if record~=false then\
self.app_pageHistory:cache(address)\
end\
end\
end\
function appFrame:onNextAddress()\
local address=self.app_addressHistory:next()\
if address then\
self.app_address:setText(address)\
self.app_address:setSel(0,0)\
self.app_address:setSel(0,-1)\
self.app_address:setFocus()\
end\
end\
function appFrame:onPriorAddress()\
local address=self.app_addressHistory:prior()\
if address then\
self.app_address:setText(address)\
self.app_address:setSel(0,0)\
self.app_address:setSel(0,-1)\
self.app_address:setFocus()\
end\
end\
function appFrame:onForward()\
local address=self.app_pageHistory:next()\
if address then\
self:onSendRequest(address,false)\
end\
end\
function appFrame:onBack()\
local address=self.app_pageHistory:prior()\
if address then\
self:onSendRequest(address,false)\
end\
end\
function appFrame:safePopupColor()\
if self.app_viewer:getBgColor()==self:getColors().popupBack then\
if self:getColors().popupBack==colors.yellow then\
return colors.orange\
end\
return colors.yellow\
end\
return self:getColors().popupBack\
end\
appFrame:runApp()",
"port=80\
wireless=true\
network=wide_area_network\
timeout=5\
",
"local appArgs={...}\
local appFrame=win.createAppFrame()\
local APP_TITLE=\"chat\"\
local ID_MENUBTN=101\
local ID_PARTNER=102\
local ID_EXCLUSIVE=103\
local ID_SAY=104\
local ID_SEND=105\
local ID_RESPONSE=106\
local IDM_CLEARMSGS=1001\
local IDM_QUITAPP=1002\
function appFrame:onReceive(msg)\
if msg.application==APP_TITLE and msg.context==\"message\" then\
local partner=self.app_partner:getText()\
local exclusive=(partner:len()>0 and self.app_exclusive:getChecked())\
if(exclusive and msg.senderName==partner)or not exclusive then\
local name=iif(msg.recipientName,\"[\"..msg.senderName..\"]\",msg.senderName)\
self.app_response:setText(\
string.format(\"%s%s: %s\\n\\n\",self.app_response:getText(),\
name,msg.data))\
local cx,cy=self.app_response:getScrollSize()\
self.app_response:setScrollOrg(0,cy)\
return true\
end\
end\
return false\
end\
function appFrame:onSent(msg,success)\
local result=\"\"\
if not success then\
result=\"<failed> \"\
end\
if msg.recipientName then\
self.app_response:setText(\
string.format(\"%s%s%s [%s]: %s\\n\\n\",self.app_response:getText(),\
result,msg.senderName,\
msg.recipientName,msg.data))\
else\
self.app_response:setText(\
string.format(\"%s%s%s: %s\\n\\n\",self.app_response:getText(),\
result,msg.senderName,msg.data))\
end\
local cx,cy=self.app_response:getScrollSize()\
self.app_response:setScrollOrg(0,cy)\
return true\
end\
function appFrame:onSendMsg()\
if self.app_say:getText():len()>0 then\
local recipient=self.app_partner:getText()\
if recipient:len()<1 then\
recipient=nil\
end\
self:sendMessage(recipient,APP_TITLE,\"message\",self.app_say:getText())\
self.app_say:setSel(0,-1)\
self.app_say:setFocus()\
end\
end\
function appFrame:onEvent(event,p1,p2,p3,p4,p5,...)\
if event==\"btn_click\" then\
if p1:getId()==ID_MENUBTN then\
self:onMenu()\
return true\
end\
if p1:getId()==ID_SEND then\
self:onSendMsg()\
return true\
end\
elseif event==\"menu_cmd\" then\
return self:onCommand(p1)\
end\
return false\
end\
function appFrame:onMove()\
self.app_partner:move(nil,nil,self.width-9)\
self.app_exclusive:move(self.width-7)\
self.app_response:move(nil,nil,self.width-2,self.height-7)\
self.app_say:move(nil,self.height-2,self.width-3)\
self.app_send:move(self.width-2,self.height-2)\
return false\
end\
function appFrame:onChildKey(wnd,key,ctrl,alt,shift)\
if win.applicationFrame.onChildKey(self,wnd,key,ctrl,alt,shift)then\
return true\
end\
if ctrl and not alt and not shift then\
if key==keys.m then\
return self:onCommand(IDM_CLEARMSGS)\
end\
elseif not ctrl and not alt and not shift then\
if key==keys.enter then\
if wnd==self.app_say then\
self:onSendMsg()\
return true\
end\
end\
end\
return false\
end\
function appFrame:onQuit()\
self:unwantMessages()\
return false\
end\
function appFrame:onMenu()\
local menu=win.menuWindow:new(self)\
menu:addString(\"Clear Msgs Ctrl+M\",IDM_CLEARMSGS)\
menu:addString(\"-----------------\")\
menu:addString(\"Quit App\",IDM_QUITAPP)\
menu:track(0,1)\
end\
function appFrame:onCommand(cmdId)\
if cmdId==IDM_CLEARMSGS then\
self.app_response:setText()\
return true\
end\
if cmdId==IDM_QUITAPP then\
self:quitApp()\
return true\
end\
return false\
end\
function appFrame:onCreate()\
self:dress(string.format(\"%s [%s]\",APP_TITLE,asstring(os.getComputerLabel())))\
local menuBtn=win.buttonWindow:new(self,ID_MENUBTN,0,0,\"Menu\")\
menuBtn:setColors(menuBtn:getColors().frameText,\
menuBtn:getColors().titleBack,\
menuBtn:getColors().frameBack)\
menuBtn:move(nil,nil,nil,nil,win.WND_TOP)\
self.app_partner=win.inputWindow:new(self,ID_PARTNER,1,2,\
self.width-9,\"\",\"Recipient\")\
self.app_exclusive=win.checkWindow:new(self,ID_EXCLUSIVE,\
self.width-7,2,\"Only\",true)\
self.app_response=win.textWindow:new(self,ID_RESPONSE,1,4,\
self.width-2,self.height-7,\"\")\
self.app_response:setBgColor(colors.white)\
self.app_say=win.inputWindow:new(self,ID_SAY,1,self.height-2,\
self.width-3,\"\",\"Message\")\
self.app_send=win.buttonWindow:new(self,ID_SEND,self.width-2,\
self.height-2,\">\")\
self.app_say:setFocus()\
self:setActiveTopFrame()\
if not self:commEnabled()then\
self:msgBox(\"Connection\",\"No modem connection found to use!\",colors.red)\
return false\
end\
self:wantMessages(APP_TITLE)\
return true\
end\
appFrame:runApp()\
",
"local appArgs={...}\
local appFrame=win.createAppFrame()\
local APP_TITLE=\"Shutdown\"\
local ID_SHUTDOWN=100\
local ID_RESTART=101\
local ID_CANCEL=102\
local ID_LOCKSCRNS=103\
function appFrame:onEvent(event,p1,p2,p3,p4,p5,...)\
if event==\"btn_click\" then\
if p1:getId()==ID_LOCKSCRNS then\
self:lockScreens()\
self:quitApp()\
return true\
end\
if p1:getId()==ID_RESTART then\
self:clearScreens()\
os.reboot()\
return true\
end\
if p1:getId()==ID_SHUTDOWN then\
self:clearScreens()\
os.shutdown()\
return true\
end\
if p1:getId()==ID_CANCEL then\
self:quitApp()\
return true\
end\
end\
return false\
end\
function appFrame:onFrameActivate(active)\
if not active then\
self:startTimer(0.05)\
end\
end\
function appFrame:onTimer(id)\
self:quitApp()\
return false\
end\
function appFrame:onMove()\
local left,vertMid=math.floor((self.width-10)/2),\
math.floor(self.height/2)\
if self:getDesktop():canLock()==false then\
vertMid=vertMid-2\
end\
local wnd=self:getWndById(ID_LOCKSCRNS)\
if wnd then\
wnd:move(left,vertMid-3)\
end\
wnd=self:getWndById(ID_RESTART)\
if wnd then\
wnd:move(left,vertMid-1)\
end\
wnd=self:getWndById(ID_SHUTDOWN)\
if wnd then\
wnd:move(left,vertMid+1)\
end\
wnd=self:getWndById(ID_CANCEL)\
if wnd then\
wnd:move(left,vertMid+3)\
end\
return false\
end\
function appFrame:onCreate()\
self:setText(APP_TITLE)\
self:setColor(self:getColors().homeText)\
self:setBgColor(self:getColors().homeBack)\
local left,vertMid=math.floor((self.width-10)/2),\
math.floor(self.height/2)\
if self:getDesktop():canLock()==false then\
vertMid=vertMid-2\
end\
win.buttonWindow:new(self,ID_LOCKSCRNS,left,vertMid-3,\
\"   Lock   \"):show(self:getDesktop():canLock())\
win.buttonWindow:new(self,ID_RESTART,left,vertMid-1,\
\"  Restart \")\
win.buttonWindow:new(self,ID_SHUTDOWN,left,vertMid+1,\
\" Shutdown \")\
local can=win.buttonWindow:new(self,ID_CANCEL,left,vertMid+3,\
\"  Cancel  \")\
can:setColors(can:getColors().closeText,\
can:getColors().closeBack,\
can:getColors().closeFocus)\
can:setFocus()\
self:setActiveTopFrame()\
return true\
end\
function appFrame:clearScreens()\
local sides=self:getWorkSpace():desktops()\
for i=1,#sides,1 do\
local gdi=win.GDI:new(sides[i])\
if gdi then\
gdi:setBackgroundColor(colors.black)\
gdi:clear(0,0,gdi:getSize())\
end\
end\
end\
function appFrame:lockScreens()\
local sides=self:getWorkSpace():desktops()\
for i=1,#sides,1 do\
self:getWorkSpace():getDesktop(sides[i]):lockScreen()\
end\
end\
appFrame:runApp()",
"local appArgs={...}\
local appFrame=win.createAppFrame()\
local APP_TITLE=\"Manager\"\
local ID_OK=1\
local ID_DESKTOP=100\
local ID_DTSELECT=101\
local ID_APPLIST=102\
local ID_ADD=103\
local ID_DELETE=104\
local ID_EDIT=105\
local ID_MOVEUP=106\
local ID_MOVEDOWN=107\
local ID_THEME=108\
local ID_STARTUP=109\
local ID_SYSTEM=110\
local ID_LABEL=111\
local ID_LOG=112\
local ID_CLEAN=113\
local ID_VERSION=114\
local ID_NAME=200\
local ID_PATH=201\
local ID_PATHBROWSE=202\
local ID_ARGS=203\
local ID_DTLIST=300\
local ID_DEFTHEME=400\
local ID_COLORDEMO=401\
local ID_COLORLIST=402\
local ID_DTMANAGE_FRAME=34176\
local DT_STARTUP_FILE=\
\"; auto-run at startup\\n;run=fullPath [arguments]\\n\\n; name of desktop\\n;home=Home\\n\\n; buffer display drawing\\nbuffer=true\\n\\n; start in full screen\\n;fullscreen=false\"\
local SYS_STARTUP_FILE=\
\"; start up delay\\ndelay=2\\n\\n; system password\\n;password=password\\n\\n; additional paths\\n;path=path\\n\\n; run before starting win\\n;pre=path\\n\\n; apis to load at startup\\napi=/win/apis/cmndlg\\napi=/win/apis/html\\n\\n; comm\\n;comm=system\\n;systemtime=5\\n;systemport=10\\n;systemrelay=true\\n;systemwireless=true\"\
local function safeColor(color)\
return iif(color==colors.orange,colors.yellow,colors.orange)\
end\
local selectDesktop=win.popupFrame:base()\
function selectDesktop:onCreate(desktop)\
self:dress(\"Desktop\")\
local rt=self:getDesktop():getWorkArea()\
local width=rt.width*0.8\
self.sd_desktops=win.listWindow:new(self,ID_DTLIST,1,2,width-2,5)\
win.buttonWindow:new(self,ID_OK,width-5,7,\" Ok \")\
local sides=self:getWorkSpace():desktops()\
for i=1,#sides,1 do\
self.sd_desktops:addString(sides[i])\
end\
self.sd_desktops:setCurSel(self.sd_desktops:find(desktop,0,true))\
self.sd_desktops:setFocus()\
self:move(nil,nil,width,9)\
return true\
end\
function selectDesktop:onEvent(event,p1,p2,p3,p4,p5,...)\
if event==\"btn_click\" then\
if p1:getId()==ID_OK then\
if self.sd_desktops:getString()then\
self:close(ID_OK)\
end\
return true\
end\
elseif event==\"list_double_click\" then\
if p1:getId()==ID_DTLIST then\
self:sendEvent(\"btn_click\",self:getWndById(ID_OK))\
return true\
end\
end\
return false\
end\
local editItem=win.popupFrame:base()\
function editItem:onCreate(title,name,path,args)\
self:dress(title)\
local rt=self:getDesktop():getWorkArea()\
local width=rt.width*0.8\
self.ei_name=win.inputWindow:new(self,ID_NAME,1,2,width-2,\
asstring(name),\"Name\")\
self.ei_name:setFocus()\
self.ei_path=win.inputWindow:new(self,ID_PATH,1,4,width-3,\
asstring(path),\"Path\")\
win.buttonWindow:new(self,ID_PATHBROWSE,width-2,4,\"@\")\
self.ei_args=win.inputWindow:new(self,ID_ARGS,1,6,width-2,\
asstring(args),\"Arguments\")\
win.buttonWindow:new(self,ID_OK,width-5,7,\" Ok \")\
self:move(nil,nil,width,9)\
return true\
end\
function editItem:onEvent(event,p1,p2,p3,p4,p5,...)\
if event==\"btn_click\" then\
if p1:getId()==ID_OK then\
self:close(ID_OK)\
return true\
end\
if p1:getId()==ID_PATHBROWSE then\
local path=cmndlg.openFile(self,self.ei_path:getText())\
if path then\
self.ei_path:setText(path)\
end\
return true\
end\
end\
return false\
end\
local editTheme=win.popupFrame:base()\
function editTheme:onCreate(desktop)\
self:dress(\"Theme\")\
self.et_desktop=desktop\
self.et_theme=self:loadTheme()\
self.et_colorsTop=0\
local rt=self:getDesktop():getWorkArea()\
self.et_demo=win.labelWindow:new(self,ID_COLORDEMO,1,1,\"     \")\
self.et_default=win.buttonWindow:new(self,ID_DEFTHEME,1,1,\" Default \")\
self.et_ok=win.buttonWindow:new(self,ID_OK,1,1,\" Save \")\
self:buildControls()\
self:move(nil,nil,27,rt.height)\
return true\
end\
function editTheme:buildControls()\
local rt=self:getDesktop():getWorkArea()\
local id=ID_COLORLIST+1\
local keys={}\
self.et_colorsTop=2\
local wnd=self:getWndById(id)\
while wnd do\
wnd:destroyWnd()\
id=id+1\
wnd=self:getWndById(id)\
end\
wnd=self:getWndById(ID_COLORLIST)\
if wnd then\
wnd:destroyWnd()\
end\
wnd=nil\
id=ID_COLORLIST+1\
for k,v in pairs(self.et_theme)do\
if k~=\"color\" then\
keys[#keys+1]=k\
end\
end\
table.sort(keys)\
for i=1,#keys,1 do\
win.labelWindow:new(self,id,1,self.et_colorsTop,\
keys[i]):setBgColor(self:getColors().popupBack)\
win.inputWindow:new(self,id+1,21,self.et_colorsTop,5,\
self.et_theme[keys[i]])\
self.et_colorsTop=self.et_colorsTop+1\
id=id+2\
end\
self.et_colors=win.listWindow:new(self,ID_COLORLIST,1,self.et_colorsTop+1,25,\
rt.height-self.et_colorsTop-3)\
for k,v in pairs(self.et_theme.color)do\
self.et_colors:addString(k,v)\
end\
self.et_colors:sort()\
self.et_demo:move(1,rt.height-2,nil,nil,win.WND_BOTTOM)\
self.et_default:move(10,rt.height-2,nil,nil,win.WND_BOTTOM)\
self.et_ok:move(20,rt.height-2,nil,nil,win.WND_BOTTOM)\
wnd=self:getWndById(ID_COLORLIST+2)\
if wnd then\
wnd:setFocus()\
end\
self.et_colors:setCurSel(1)\
end\
function editTheme:onResize()\
local rt=self:getDesktop():getWorkArea()\
self:move(nil,nil,nil,rt.height)\
self.et_colors:move(nil,nil,nil,rt.height-self.et_colorsTop-3)\
self.et_demo:move(1,rt.height-2,nil,nil,win.WND_BOTTOM)\
self.et_default:move(10,rt.height-2,nil,nil,win.WND_BOTTOM)\
self.et_ok:move(20,rt.height-2,nil,nil,win.WND_BOTTOM)\
return false\
end\
function editTheme:onEvent(event,p1,p2,p3,p4,p5,...)\
if event==\"btn_click\" then\
if p1:getId()==ID_OK then\
if self:saveTheme()then\
self:close(ID_OK)\
else\
self:msgBox(\"Error\",\"Could not save theme.\",colors.red)\
end\
return true\
end\
if p1:getId()==ID_DEFTHEME then\
self.et_theme=win.desktopTheme:new()\
self:buildControls()\
return true\
end\
elseif event==\"selection_change\" then\
if p1:getId()==ID_COLORLIST then\
if self.et_colors:getCurSel()>0 then\
self.et_demo:setBgColor(self.et_colors:getData())\
end\
return true\
end\
elseif event==\"list_double_click\" then\
if p1:getId()==ID_COLORLIST then\
if self.et_colors:getCurSel()>0 then\
local color=cmndlg.color(self,self.et_colors:getData(),safeColor(self:getColors().popupBack))\
if color then\
self.et_colors:setData(color)\
self.et_demo:setBgColor(color)\
self.et_theme.color[self.et_colors:getString()]=color\
end\
end\
return true\
end\
elseif event==\"input_change\" then\
if p1:getId()>ID_COLORLIST then\
local label=self:getWndById(p1:getId()-1)\
if label then\
local key=label:getText()\
if type(self.et_theme[key])==\"number\" then\
self.et_theme[key]=asnumber(p1:getText())\
elseif type(self.et_theme[key])==\"string\" then\
self.et_theme[key]=p1:getText()\
end\
end\
return true\
end\
end\
return false\
end\
function editTheme:loadTheme()\
local path=\"/win/\"..self.et_desktop..\"/theme.ini\"\
local theme=nil\
if fs.exists(path)and not fs.isDir(path)then\
local hFile=fs.open(path,\"r\")\
if hFile then\
local data=hFile.readAll()\
if data then\
theme=textutils.unserialize(data)\
end\
hFile.close()\
end\
end\
if not theme then\
theme=win.desktopTheme:new()\
end\
return theme\
end\
function editTheme:saveTheme()\
local path=\"/win/\"..self.et_desktop..\"/theme.ini\"\
local result=false\
local hFile=fs.open(path,\"w\")\
if hFile then\
local data=textutils.serialize(self.et_theme)\
if data then\
hFile.write(data)\
result=true\
end\
hFile.close()\
end\
return result\
end\
function appFrame:onEvent(event,p1,p2,p3,p4,p5,...)\
if event==\"btn_click\" then\
if p1:getId()==ID_DTSELECT then\
self:selectDesktop()\
return true\
end\
if p1:getId()==ID_ADD then\
self:addItem()\
return true\
end\
if p1:getId()==ID_DELETE then\
self:deleteItem()\
return true\
end\
if p1:getId()==ID_EDIT then\
self:editItem()\
return true\
end\
if p1:getId()==ID_MOVEUP then\
self:moveItemUp()\
return true\
end\
if p1:getId()==ID_MOVEDOWN then\
self:moveItemDown()\
return true\
end\
if p1:getId()==ID_THEME then\
self:editTheme()\
return true\
end\
if p1:getId()==ID_STARTUP then\
self:openStartup()\
return true\
end\
if p1:getId()==ID_SYSTEM then\
self:openSystem()\
return true\
end\
if p1:getId()==ID_LABEL then\
self:setLabel()\
return true\
end\
if p1:getId()==ID_LOG then\
self:openLog()\
return true\
end\
if p1:getId()==ID_CLEAN then\
self:cleansys()\
return true\
end\
elseif event==\"list_double_click\" then\
if p1:getId()==ID_APPLIST then\
self:sendEvent(\"btn_click\",self:getWndById(ID_EDIT))\
return true\
end\
end\
return false\
end\
function appFrame:onQuit()\
self:saveDesktop()\
return false\
end\
function appFrame:onMove()\
local width=self.width-2\
local top=iif(self.height<14,1,2)\
local left=(self.width-width)/2\
self.app_desktop:move(left,top,width-1)\
local wnd=self:getWndById(ID_DTSELECT)\
if wnd then\
wnd:move(left+width-1,top)\
end\
self.app_appList:move(left,top+2,width-8,\
math.max(self.height-top-3,9))\
left=width+left-7\
wnd=self:getWndById(ID_ADD)\
if wnd then\
wnd:move(left,top+2)\
end\
wnd=self:getWndById(ID_DELETE)\
if wnd then\
wnd:move(left,top+3)\
end\
wnd=self:getWndById(ID_EDIT)\
if wnd then\
wnd:move(left,top+4)\
end\
wnd=self:getWndById(ID_MOVEUP)\
if wnd then\
wnd:move(left,top+5)\
end\
wnd=self:getWndById(ID_MOVEDOWN)\
if wnd then\
wnd:move(left,top+6)\
end\
wnd=self:getWndById(ID_THEME)\
if wnd then\
wnd:move(left,top+8)\
end\
wnd=self:getWndById(ID_STARTUP)\
if wnd then\
wnd:move(left,top+9)\
end\
wnd=self:getWndById(ID_SYSTEM)\
if wnd then\
wnd:move(left,top+10)\
end\
wnd=self:getWndById(ID_LABEL)\
if wnd then\
wnd:move(left,top+11)\
end\
wnd=self:getWndById(ID_LOG)\
if wnd then\
wnd:move(left,top+12)\
end\
wnd=self:getWndById(ID_CLEAN)\
if wnd then\
wnd:move(left,top+13)\
end\
wnd=self:getWndById(ID_VERSION)\
if wnd then\
wnd:move(1,self.height-1)\
end\
return false\
end\
function appFrame:onChildKey(wnd,key,ctrl,alt,shift)\
if win.applicationFrame.onChildKey(self,wnd,key,ctrl,alt,shift)then\
return true\
end\
return false\
end\
function appFrame:onCreate()\
local instance=self:getDesktop():getWndById(ID_DTMANAGE_FRAME,false)\
if instance then\
instance:setActiveTopFrame()\
return false\
end\
self:setId(ID_DTMANAGE_FRAME)\
self:dress(APP_TITLE..\":\"..tostring(os.getComputerID()))\
self.app_loadedDesktop=nil\
self.app_modified=false\
local width=self.width-2\
local top=iif(self.height<14,1,2)\
local left=(self.width-width)/2\
self.app_desktop=win.labelWindow:new(self,ID_DESKTOP,left,top,\
self:getSide())\
self.app_desktop:move(nil,nil,width-1)\
self.app_desktop:setColor(self:getColors().wndText)\
self.app_desktop:setBgColor(self:getColors().wndBack)\
win.buttonWindow:new(self,ID_DTSELECT,left+width-1,top,\"@\")\
self.app_appList=win.listWindow:new(self,ID_APPLIST,left,top+2,\
width-8,math.max(self.height-top-3,9))\
self.app_appList:setFocus()\
win.labelWindow:new(self,ID_VERSION,1,self.height-1,\
\"CCWindows \"..tostring(win.version()))\
left=width+left-7\
win.buttonWindow:new(self,ID_ADD,left,top+2,\"  Add  \")\
win.buttonWindow:new(self,ID_DELETE,left,top+3,\" Remove\")\
win.buttonWindow:new(self,ID_EDIT,left,top+4,\"  Edit \")\
win.buttonWindow:new(self,ID_MOVEUP,left,top+5,\"   Up  \")\
win.buttonWindow:new(self,ID_MOVEDOWN,left,top+6,\"  Down \")\
win.buttonWindow:new(self,ID_THEME,left,top+8,\" Theme \")\
win.buttonWindow:new(self,ID_STARTUP,left,top+9,\"Startup\")\
win.buttonWindow:new(self,ID_SYSTEM,left,top+10,\" System\")\
win.buttonWindow:new(self,ID_LABEL,left,top+11,\"  Name \")\
win.buttonWindow:new(self,ID_LOG,left,top+12,\"  Log  \")\
win.buttonWindow:new(self,ID_CLEAN,left,top+13,\" Clean \")\
self:loadAppList()\
self:setActiveTopFrame()\
return true\
end\
function appFrame:loadAppList()\
self:saveDesktop()\
self.app_loadedDesktop=self.app_desktop:getText()\
self.app_appList:resetContent()\
local lines={}\
local line,lastLine;\
local hFile=fs.open(\"/win/\"..self.app_loadedDesktop..\"/desktop.ini\",\"r\")\
if hFile then\
line=hFile.readLine()\
while line do\
lines[#lines+1]=line\
line=hFile.readLine()\
end\
hFile.close()\
lastLine=math.floor(#lines/5)*5\
for line=1,lastLine,5 do\
local app={\
name=lines[line],\
path=lines[line+1],\
arguments=lines[line+2],\
dummy1=lines[line+3],\
dummy2=lines[line+4]\
}\
self.app_appList:addString(app.name,app)\
end\
end\
if self.app_appList:count()>0 then\
self.app_appList:setCurSel(1)\
end\
end\
function appFrame:saveDesktop()\
if self.app_loadedDesktop and self.app_modified then\
if cmndlg.confirm(self:getActiveFrame(),\"Save\",\
\"Save desktop \"..self.app_loadedDesktop..\"?\",true)then\
local path=\"/win/\"..self.app_loadedDesktop..\"/desktop.ini\"\
if fs.exists(path..\".bak\")then\
fs.delete(path..\".bak\")\
end\
fs.copy(path,path..\".bak\")\
local hFile=fs.open(path,\"w\")\
if hFile then\
for i=1,self.app_appList:count(),1 do\
local app=self.app_appList:getData(i)\
hFile.writeLine(app.name)\
hFile.writeLine(app.path)\
hFile.writeLine(app.arguments)\
hFile.writeLine(app.dummy1)\
hFile.writeLine(app.dummy2)\
end\
hFile.close()\
end\
end\
end\
end\
function appFrame:deleteItem()\
local item=self.app_appList:getCurSel()\
if item>0 then\
if cmndlg.confirm(self,\"Remove\",\"Remove \"..self.app_appList:getString()..\"?\")then\
self.app_appList:removeString(item)\
self.app_modified=true\
end\
end\
end\
function appFrame:moveItemUp()\
local item=self.app_appList:getCurSel()\
if item>1 then\
local str,data=self.app_appList:getString(),self.app_appList:getData()\
self.app_appList:removeString(item)\
self.app_appList:addString(str,data,item-1)\
self.app_appList:setCurSel(item-1)\
self.app_modified=true\
end\
end\
function appFrame:moveItemDown()\
local item=self.app_appList:getCurSel()\
if item<self.app_appList:count()then\
local str,data=self.app_appList:getString(),self.app_appList:getData()\
self.app_appList:removeString(item)\
self.app_appList:addString(str,data,item+1)\
self.app_appList:setCurSel(item+1)\
self.app_modified=true\
end\
end\
function appFrame:addItem()\
local dlg=editItem:new(self)\
if dlg:doModal(\"New App\")==ID_OK then\
local data={\
name=dlg.ei_name:getText(),\
path=dlg.ei_path:getText(),\
arguments=dlg.ei_args:getText(),\
dummy1=\"\",\
dummy2=\"\"\
}\
self.app_appList:addString(data.name,data)\
self.app_modified=true\
end\
end\
function appFrame:editItem()\
local item=self.app_appList:getCurSel()\
if item>0 then\
local data=self.app_appList:getData(item)\
local dlg=editItem:new(self)\
if dlg:doModal(\"Edit App\",data.name,data.path,data.arguments)==ID_OK then\
data={\
name=dlg.ei_name:getText(),\
path=dlg.ei_path:getText(),\
arguments=dlg.ei_args:getText(),\
dummy1=\"\",\
dummy2=\"\"\
}\
self.app_appList:removeString(item)\
self.app_appList:addString(data.name,data,item)\
self.app_appList:setCurSel(item)\
self.app_modified=true\
end\
end\
end\
function appFrame:selectDesktop()\
local dlg=selectDesktop:new(self)\
if dlg:doModal(self.app_desktop:getText())==ID_OK then\
self.app_desktop:setText(dlg.sd_desktops:getString())\
self:loadAppList()\
end\
end\
function appFrame:openStartup()\
if self.app_loadedDesktop then\
local path=\"/win/\"..self.app_loadedDesktop..\"/startup.ini\"\
if not fs.exists(path)then\
local file=fs.open(path,\"w\")\
if not file then\
self:msgBox(\"Error\",\"Error creating \"..path,colors.red)\
return\
end\
file.write(DT_STARTUP_FILE)\
file.close()\
end\
self:getDesktop():runApp(\"/win/apps/notepad\",path)\
end\
end\
function appFrame:openSystem()\
local path=\"/win/startup.ini\"\
if not fs.exists(path)then\
local file=fs.open(path,\"w\")\
if not file then\
self:msgBox(\"Error\",\"Error creating \"..path,colors.red)\
return\
end\
file.write(SYS_STARTUP_FILE)\
file.close()\
end\
self:getDesktop():runApp(\"/win/apps/notepad\",path)\
end\
function appFrame:openLog()\
local path=\"/win/win.log\"\
if not fs.exists(path)then\
local file=fs.open(path,\"w\")\
if not file then\
self:msgBox(\"Error\",\"Error creating \"..path,colors.red)\
return\
end\
file.close()\
end\
self:getDesktop():runApp(\"/win/apps/notepad\",path)\
end\
function appFrame:cleansys()\
if cmndlg.confirm(self,\"Clean\",\
\"This action will permanently alter/erase files. Continue?\",\
false,colors.orange)then\
local path=\"/win/win.log\"\
local file=fs.open(path,\"w\")\
if not file then\
self:msgBox(\"Error\",\"Error cleaning \"..path,colors.red)\
return\
end\
file.close()\
path=\"/win/tmp\"\
if fs.exists(path)and fs.isDir(path)then\
pcall(fs.delete,path)\
pcall(fs.makeDir,path)\
end\
end\
end\
function appFrame:editTheme()\
if self.app_loadedDesktop then\
local dlg=editTheme:new(self)\
if dlg:doModal(self.app_loadedDesktop)==ID_OK then\
end\
end\
end\
function appFrame:setLabel()\
local name=cmndlg.input(self,\"Computer Name\",\"Enter the computer's name\",\
os.getComputerLabel()or \"\",\"Name\")\
if name then\
if name:len()<1 then\
os.setComputerLabel()\
else\
os.setComputerLabel(name)\
end\
end\
end\
appFrame:runApp()",
"local appArgs={...}\
local appFrame=win.createAppFrame()\
local APP_TITLE=\"emails\"\
local ID_OK=1\
local ID_MENUBTN=101\
local ID_FOLDER=102\
local ID_EMAILS=103\
local ID_ADDRESS=201\
local ID_PASSWORD=202\
local ID_NETWORK=203\
local ID_PORT=204\
local ID_WIRELESS=205\
local ID_TIMEOUT=206\
local ID_NEWPWD=207\
local ID_CONFIRMPWD=208\
local IDM_DOWNLOAD=1001\
local IDM_NEWMSG=1002\
local IDM_OPEN=1003\
local IDM_DELMSG=1004\
local IDM_ACCOUNT=1005\
local IDM_CHANGEPWD=1006\
local IDM_QUITAPP=1007\
local ID_EMAIL_FRAME=32154\
local accountDlg=win.popupFrame:base()\
function accountDlg:onCreate(address,password,network,port,wireless,timeout)\
self:dress(\"Account\")\
self.acc_address=win.inputWindow:new(self,ID_ADDRESS,1,2,17,\
address,\"Email Address\")\
self.acc_password=win.inputWindow:new(self,ID_PASSWORD,1,4,17,\
password,\"Password\")\
self.acc_network=win.inputWindow:new(self,ID_NETWORK,1,6,17,\
network,\"Network\")\
self.acc_port=win.inputWindow:new(self,ID_PORT,1,8,8,\
port,\"Port\")\
self.acc_timeout=win.inputWindow:new(self,ID_TIMEOUT,10,8,8,\
timeout,\"Timeout\")\
self.acc_wireless=win.checkWindow:new(self,ID_WIRELESS,1,10,\
\"Wireless\",wireless~=false)\
win.buttonWindow:new(self,ID_OK,14,10,\" Ok \")\
self.acc_wireless:setColors(self:getColors().popupText,\
self:getColors().popupBack,\
self:getColors().popupBack,\
self:getColors().checkText,\
self:getColors().checkBack,\
self:getColors().checkFocus)\
self.acc_password:setMaskChar(\"*\")\
self.acc_address:setSel(0,-1)\
self.acc_address:setFocus()\
self:move(nil,nil,19,12)\
return true\
end\
function accountDlg:onEvent(event,p1,p2,p3,p4,p5,...)\
if event==\"btn_click\" then\
if p1:getId()==ID_OK then\
if self.acc_address:getText():len()<3 or\
not self.acc_address:getText():find(\"@\",1,true)then\
self.acc_address:setError(true)\
self.acc_address:setFocus()\
else\
self:close(ID_OK)\
end\
return true\
end\
end\
return false\
end\
function accountDlg:onChildFocus(child,blurred)\
if child.setSel then\
child:setSel(0,-1)\
end\
return win.popupFrame.onChildFocus(self,child,blurred)\
end\
function accountDlg:onChildBlur(child,focused)\
if child.setSel then\
local len=child:getText():len()\
child:setSel(len,len,false)\
end\
return win.popupFrame.onChildBlur(self,child,focused)\
end\
local passwordDlg=win.popupFrame:base()\
function passwordDlg:onCreate(password)\
self:dress(\"Password\")\
self.pw_password=win.inputWindow:new(self,ID_PASSWORD,1,2,17,\
password,\"Password\")\
win.buttonWindow:new(self,ID_OK,14,3,\" Ok \")\
self.pw_password:setMaskChar(\"*\")\
self.pw_password:setSel(0,-1)\
self.pw_password:setFocus()\
self:move(nil,nil,19,5)\
return true\
end\
function passwordDlg:onEvent(event,p1,p2,p3,p4,p5,...)\
if event==\"btn_click\" then\
if p1:getId()==ID_OK then\
self:close(ID_OK)\
return true\
end\
end\
return false\
end\
function passwordDlg:onChildFocus(child,blurred)\
if child.setSel then\
child:setSel(0,-1)\
end\
return win.popupFrame.onChildFocus(self,child,blurred)\
end\
function passwordDlg:onChildBlur(child,focused)\
if child.setSel then\
local len=child:getText():len()\
child:setSel(len,len,false)\
end\
return win.popupFrame.onChildBlur(self,child,focused)\
end\
local newPasswordDlg=win.popupFrame:base()\
function newPasswordDlg:onCreate(password)\
self:dress(\"Password\")\
self.pw_password=win.inputWindow:new(self,ID_PASSWORD,1,2,17,\
password,\"Password\")\
self.pw_password:setMaskChar(\"*\")\
self.pw_newPassword=win.inputWindow:new(self,ID_NEWPWD,1,4,17,\
\"\",\"New\")\
self.pw_newPassword:setMaskChar(\"*\")\
self.pw_confirmPassword=win.inputWindow:new(self,ID_PASSWORD,1,6,17,\
\"\",\"Confirm\")\
self.pw_confirmPassword:setMaskChar(\"*\")\
if asstring(password):len()>0 then\
self.pw_newPassword:setFocus()\
else\
self.pw_password:setFocus()\
end\
win.buttonWindow:new(self,ID_OK,14,7,\" Ok \")\
self:move(nil,nil,19,9)\
return true\
end\
function newPasswordDlg:onEvent(event,p1,p2,p3,p4,p5,...)\
if event==\"btn_click\" then\
if p1:getId()==ID_OK then\
if self.pw_newPassword:getText():len()<1 then\
self.pw_newPassword:setFocus()\
self.pw_newPassword:setError(true)\
return true\
elseif self.pw_newPassword:getText()~=self.pw_confirmPassword:getText()then\
self.pw_confirmPassword:setSel(0,-1)\
self.pw_confirmPassword:setFocus()\
self.pw_confirmPassword:setError(true)\
return true\
end\
self:close(ID_OK)\
return true\
end\
end\
return false\
end\
function newPasswordDlg:onChildBlur(child,focused)\
if child.setError then\
child:setError(false)\
end\
if child.setSel then\
local len=child:getText():len()\
child:setSel(len,len,false)\
end\
return win.popupFrame.onChildBlur(self,child,focused)\
end\
function newPasswordDlg:onChildFocus(child,blurred)\
if child.setSel then\
child:setSel(0,-1)\
end\
return win.popupFrame.onChildFocus(self,child,blurred)\
end\
function appFrame:onReceive(msg)\
if(msg.recipientName or msg.recipientId)then\
if msg.context==\"email_response\" and type(msg.data)==\"table\" then\
if type(msg.data.email)==\"table\" then\
local email=textutils.serialize(msg.data.email)\
if email then\
local path;\
repeat\
path=self.app_dataPath..\"/inbox/r\"..\
tostring(math.random(1,65535))..\".email\"\
until not fs.exists(path)\
local file=fs.open(path,\"w\")\
if file then\
file.write(email)\
file.close()\
local domain=self.app_address:sub(self.app_address:find(\"@\",1,true)+1)\
local account=self.app_address:sub(1,self.app_address:find(\"@\",1,true)-1)\
self:sendMessage(domain,self.app_network,\"email_delete\",\
{\
account=account,\
password=self.app_password,\
id=msg.data.id\
},self.app_connName)\
self:reloadEmails(\"inbox\")\
return true\
end\
end\
end\
end\
end\
return false\
end\
function appFrame:onSent(msg,success)\
if not success then\
if msg.context==\"email_request\" then\
self:msgBox(\"Error\",\"Error getting emails from server!\",colors.red)\
elseif msg.context==\"account_password\" then\
self:msgBox(\"Error\",\"Error changing account password!\",colors.red)\
end\
end\
return true\
end\
function appFrame:onEvent(event,p1,p2,p3,p4,p5,...)\
if event==\"btn_click\" then\
if p1:getId()==ID_MENUBTN then\
self:onMenu()\
return true\
end\
elseif event==\"menu_cmd\" then\
return self:onCommand(p1)\
elseif event==\"list_click\" then\
if p1:getId()==ID_FOLDER then\
if p1:getString()then\
self:loadEmails(p1:getString())\
end\
return true\
end\
elseif event==\"list_double_click\" then\
if p1:getId()==ID_EMAILS then\
return appFrame:onCommand(IDM_OPEN)\
end\
elseif event==\"reload_list\" then\
return self:reloadEmails(asstring(p1))\
end\
return false\
end\
function appFrame:onTimer(timerId)\
if timerId==self.app_connTimer then\
if self.app_connName then\
self:commClose(self.app_connName)\
self.app_connName=nil\
self.app_address=nil\
self.app_password=nil\
self.app_network=nil\
end\
self.app_connTimer=nil\
end\
return false\
end\
function appFrame:onChildKey(wnd,key,ctrl,alt,shift)\
if win.applicationFrame.onChildKey(self,wnd,key,ctrl,alt,shift)then\
return true\
end\
if ctrl and not alt and not shift then\
if key==keys.g then\
return self:onCommand(IDM_DOWNLOAD)\
end\
if key==keys.n then\
return self:onCommand(IDM_NEWMSG)\
end\
if key==keys.o then\
return self:onCommand(IDM_OPEN)\
end\
elseif not ctrl and not alt and not shift then\
if key==keys.delete then\
return self:onCommand(IDM_DELMSG)\
end\
end\
return false\
end\
function appFrame:onFrameActivate(active)\
end\
function appFrame:onQuit()\
if self.app_connName then\
self:commClose(self.app_connName)\
end\
return false\
end\
function appFrame:onMenu()\
local menu=win.menuWindow:new(self)\
menu:addString(\"Get Emails Ctrl+G\",IDM_DOWNLOAD)\
menu:addString(\"New Email  Ctrl+N\",IDM_NEWMSG)\
if self.app_emails:getData()then\
menu:addString(\"Open       Ctrl+O\",IDM_OPEN)\
menu:addString(\"Delete     Del\",IDM_DELMSG)\
end\
menu:addString(\"-----------------\")\
menu:addString(\"Account\",IDM_ACCOUNT)\
menu:addString(\"Change Password\",IDM_CHANGEPWD)\
menu:addString(\"-----------------\")\
menu:addString(\"Quit App\",IDM_QUITAPP)\
menu:track(0,1)\
end\
function appFrame:onCommand(cmdId)\
if cmdId==IDM_DOWNLOAD then\
self:onGetEmails()\
return true\
end\
if cmdId==IDM_NEWMSG then\
self:onNewEmail()\
return true\
end\
if cmdId==IDM_OPEN then\
self:onOpenEmail()\
return true\
end\
if cmdId==IDM_DELMSG then\
self:onDeleteEmail()\
return true\
end\
if cmdId==IDM_ACCOUNT then\
self:onAccount()\
return true\
end\
if cmdId==IDM_CHANGEPWD then\
self:onChangePassword()\
return true\
end\
if cmdId==IDM_QUITAPP then\
self:quitApp()\
return true\
end\
return false\
end\
function appFrame:onMove()\
self.app_folder:move(0,1,7,self.height-1)\
self.app_emails:move(8,1,self.width-8,self.height-1)\
return false\
end\
function appFrame:onCreate()\
local instance=self:getDesktop():getWndById(ID_EMAIL_FRAME,false)\
if instance then\
instance:setActiveTopFrame()\
return false\
end\
self:setId(ID_EMAIL_FRAME)\
self:dress(APP_TITLE)\
local menuBtn=win.buttonWindow:new(self,ID_MENUBTN,0,0,\"Menu\")\
menuBtn:setColors(menuBtn:getColors().frameText,\
menuBtn:getColors().titleBack,\
menuBtn:getColors().frameBack)\
menuBtn:move(nil,nil,nil,nil,win.WND_TOP)\
local panelWidth=7\
self.app_folder=win.listWindow:new(self,ID_FOLDER,0,1,7,self.height-1)\
self.app_emails=win.listWindow:new(self,ID_EMAILS,8,1,\
self.width-8,self.height-1)\
self.app_appFolder=self:getAppPath():sub(1,-(fs.getName(self:getAppPath()):len()+1))\
self.app_dataPath=self.app_appFolder..\"data/email\"\
self.app_connName=nil\
self.app_connTimer=nil\
self.app_address=nil\
self.app_password=nil\
self.app_network=nil\
self:loadFolders()\
self:setActiveTopFrame()\
return true\
end\
function appFrame:loadFolders()\
self.app_folder:resetContent()\
self.app_emails:resetContent()\
if not fs.exists(self.app_dataPath)then\
fs.makeDir(self.app_dataPath)\
end\
if not fs.exists(self.app_dataPath..\"/inbox\")then\
fs.makeDir(self.app_dataPath..\"/inbox\")\
end\
if not fs.exists(self.app_dataPath..\"/sent\")then\
fs.makeDir(self.app_dataPath..\"/sent\")\
end\
local folders=fs.list(self.app_dataPath)\
for i=1,#folders,1 do\
if fs.isDir(self.app_dataPath..\"/\"..folders[i])then\
self.app_folder:addString(folders[i])\
end\
end\
self.app_folder:sort()\
end\
local function email_sorter(email1,email2)\
return(email1.time<email2.time)\
end\
function appFrame:loadEmails(folder)\
local emails={}\
local list=fs.list(self.app_dataPath..\"/\"..folder)\
self.app_emails:resetContent()\
for i=1,#list,1 do\
local file=fs.open(self.app_dataPath..\"/\"..folder..\"/\"..list[i],\"r\")\
if file then\
local email=textutils.unserialize(file.readAll())\
if email then\
emails[#emails+1]={\
recipient=email.recipient,\
sender=email.sender,\
subject=email.subject,\
time=email.time,\
path=self.app_dataPath..\"/\"..folder..\"/\"..list[i]\
}\
end\
file.close()\
end\
end\
table.sort(emails,email_sorter)\
for i=1,#emails,1 do\
local who,subject=\
asstring(iif(folder==\"sent\",emails[i].recipient,emails[i].sender)),\
asstring(emails[i].subject)\
local whoFull=who\
if who:len()>15 then\
who=who:sub(1,15)\
elseif who:len()<15 then\
who=who..string.rep(\" \",15-who:len())\
end\
if subject:len()>15 then\
subject=subject:sub(1,15)\
elseif subject:len()<15 then\
subject=subject..string.rep(\" \",15-subject:len())\
end\
local day,part=math.modf(emails[i].time)\
local hour,minute=math.modf(part*24)\
minute=math.floor(minute*60)\
self.app_emails:addString(\
string.format(\"%s %s %5d,%02d:%02d\",who,subject,day,hour,minute),\
{path=emails[i].path,subject=string.trim(subject),who=whoFull})\
end\
local x,y=self.app_emails:getScrollSize()\
self.app_emails:setScrollSize(iif(self.app_emails:count()>0,43,0),y)\
end\
function appFrame:reloadEmails(folder)\
if folder and self.app_folder:getString()==folder then\
self:loadEmails(folder)\
end\
end\
function appFrame:onOpenEmail()\
if self.app_emails:getData()then\
local path=self.app_appFolder..\"emread\"\
self:getDesktop():runApp(path,self.app_emails:getData().path)\
end\
end\
function appFrame:onDeleteEmail()\
if self.app_emails:getData()then\
if cmndlg.confirm(self,\"Delete\",\"Delete \"..self.app_emails:getData().subject..\"?\",false,colors.orange)then\
fs.delete(self.app_emails:getData().path)\
self:reloadEmails(self.app_folder:getString())\
end\
end\
end\
function appFrame:onNewEmail()\
if self.app_emails:getData()then\
self:getDesktop():runApp(self.app_appFolder..\"emwrite\",self.app_emails:getData().who)\
else\
self:getDesktop():runApp(self.app_appFolder..\"emwrite\")\
end\
end\
function appFrame:onAccount()\
local iniPath=self.app_appFolder..\"email.ini\"\
local dlg=accountDlg:new(self)\
local address=\"\"\
local password=\"\"\
local network=\"wide_area_network\"\
local port=80\
local timeout=5\
local wireless=true\
local ini=fs.loadIniFile(iniPath)\
if ini then\
address=asstring((ini:find(\"address\")))\
password=asstring((ini:find(\"password\")))\
network=asstring(ini:find(\"network\"),\"wide_area_network\")\
port=asnumber(ini:find(\"port\"),80)\
timeout=asnumber(ini:find(\"timeout\"),5)\
wireless=asstring(ini:find(\"wireless\"),\"true\")~=\"false\"\
end\
if dlg:doModal(address,password,network,port,wireless,timeout)==ID_OK then\
address=dlg.acc_address:getText()\
password=dlg.acc_password:getText()\
network=dlg.acc_network:getText()\
if network:len()<1 then\
network=\"wide_area_network\"\
end\
port=asnumber(dlg.acc_port:getText(),80)\
timeout=asnumber(dlg.acc_timeout:getText(),5)\
wireless=iif(dlg.acc_wireless:getChecked(),\"true\",\"false\")\
local file=fs.open(iniPath,\"w\")\
if file then\
file.write(string.format(\
\"address=%s\\npassword=%s\\nnetwork=%s\\nport=%d\\ntimeout=%d\\nwireless=%s\",\
address,password,network,port,timeout,wireless))\
file.close()\
else\
self:msgBox(\"Error\",\"Error saving account settings!\",colors.red)\
end\
end\
end\
function appFrame:onGetEmails()\
local ini=fs.loadIniFile(self.app_appFolder..\"email.ini\")\
if ini then\
self.app_address=asstring(ini:find(\"address\"))\
self.app_password=asstring(ini:find(\"password\"))\
self.app_network=asstring(ini:find(\"network\"),\"wide_area_network\")\
local port=asnumber(ini:find(\"port\"),80)\
local timeout=asnumber(ini:find(\"timeout\"),5)\
local wireless=asstring(ini:find(\"wireless\"),\"true\")~=\"false\"\
if self.app_address:len()>2 and self.app_address:find(\"@\",1,true)then\
if self.app_password:len()<1 then\
local dlg=passwordDlg:new(self)\
if dlg:doModal()~=ID_OK then\
return\
end\
self.app_password=dlg.pw_password:getText()\
end\
if not self.app_connName then\
local con=self:commOpen(nil,wireless,port,timeout,false)\
if not con then\
self:msgBox(\"Connection\",\"Could not connect to modem!\",colors.red)\
return\
end\
self.app_connName=con:getName()\
self:wantMessages(\"email_client\",self.app_connName)\
self:wantMessages(self.app_network,self.app_connName)\
end\
local domain=self.app_address:sub(self.app_address:find(\"@\",1,true)+1)\
local account=self.app_address:sub(1,self.app_address:find(\"@\",1,true)-1)\
self.app_connTimer=self:startTimer(30)\
self:sendMessage(domain,self.app_network,\"email_request\",\
{\
application=\"email_client\",\
account=account,\
password=self.app_password\
},self.app_connName)\
else\
self.app_address=nil\
self.app_password=nil\
self.app_network=nil\
self:msgBox(\"Account\",\"Invalid account settings!\",colors.red)\
end\
else\
self:msgBox(\"Account\",\"No account set up!\",colors.red)\
end\
end\
function appFrame:onChangePassword()\
local ini=fs.loadIniFile(self.app_appFolder..\"email.ini\")\
if ini then\
self.app_address=asstring(ini:find(\"address\"))\
self.app_password=asstring(ini:find(\"password\"))\
self.app_network=asstring(ini:find(\"network\"),\"wide_area_network\")\
local port=asnumber(ini:find(\"port\"),80)\
local timeout=asnumber(ini:find(\"timeout\"),5)\
local wireless=asstring(ini:find(\"wireless\"),\"true\")~=\"false\"\
if self.app_address:len()>2 and self.app_address:find(\"@\",1,true)then\
local dlg=newPasswordDlg:new(self)\
if dlg:doModal(self.app_password)~=ID_OK then\
return\
end\
self.app_password=dlg.pw_password:getText()\
if not self.app_connName then\
local con=self:commOpen(nil,wireless,port,timeout,false)\
if not con then\
self:msgBox(\"Connection\",\"Could not connect to modem!\",colors.red)\
return\
end\
self.app_connName=con:getName()\
self:wantMessages(\"email_client\",self.app_connName)\
self:wantMessages(self.app_network,self.app_connName)\
end\
local domain=self.app_address:sub(self.app_address:find(\"@\",1,true)+1)\
local account=self.app_address:sub(1,self.app_address:find(\"@\",1,true)-1)\
self.app_connTimer=self:startTimer(30)\
self:sendMessage(domain,self.app_network,\"account_password\",\
{\
account=account,\
password=self.app_password,\
newPassword=dlg.pw_newPassword:getText()\
},self.app_connName)\
else\
self.app_address=nil\
self.app_password=nil\
self.app_network=nil\
self:msgBox(\"Account\",\"Invalid account settings!\",colors.red)\
end\
else\
self:msgBox(\"Account\",\"No account set up!\",colors.red)\
end\
end\
appFrame:runApp()",
";address=account@domain\
;password=password\
network=wide_area_network\
port=80\
timeout=5\
wireless=true\
",
"local appArgs={...}\
local appFrame=win.createAppFrame()\
local APP_TITLE=\"email\"\
local ID_MENUBTN=101\
local IDM_OPEN=1001\
local IDM_PRINT=1002\
local IDM_COPY=1003\
local IDM_QUITAPP=1004\
function appFrame:onEvent(event,p1,p2,p3,p4,p5,...)\
if event==\"btn_click\" then\
if p1:getId()==ID_MENUBTN then\
self:onMenu()\
return true\
end\
elseif event==\"menu_cmd\" then\
return self:onCommand(p1)\
end\
return false\
end\
function appFrame:onChildKey(wnd,key,ctrl,alt,shift)\
if win.applicationFrame.onChildKey(self,wnd,key,ctrl,alt,shift)then\
return true\
end\
if ctrl and not alt and not shift then\
if key==keys.o then\
return self:onCommand(IDM_OPEN)\
end\
if key==keys.p then\
return self:onCommand(IDM_PRINT)\
end\
if key==keys.c then\
return self:onCommand(IDM_COPY)\
end\
end\
return false\
end\
function appFrame:onPrintPage(gdi,page,data)\
local width,height=gdi:getPageSize()\
if not data.data.lines then\
data.data.lines=string.wrap(data.data.raw,width)\
end\
local topLine=((page-1)*height)+1\
local lastLine=iif((topLine+height)>#data.data.lines,\
#data.data.lines,topLine+height)\
for line=topLine,lastLine,1 do\
gdi:write(data.data.lines[line],0,line-topLine)\
end\
return(lastLine<#data.data.lines)\
end\
function appFrame:onPrintData()\
local str=self.app_to:getText()..\"\\n\"..\
self.app_from:getText()..\"\\n\"..\
self.app_sent:getText()..\"\\n\"..\
self.app_subject:getText()..\"\\n\\n\"..\
self.app_message:getText()\
local width,height=string.wrapSize(string.wrap(str,25))\
local data={raw=str}\
local pages=math.ceil(height/21)\
return win.applicationFrame.onPrintData(self,self:getText(),data,pages)\
end\
function appFrame:onMenu()\
local menu=win.menuWindow:new(self)\
menu:addString(\"Open  Ctrl+O\",IDM_OPEN)\
menu:addString(\"Print Ctrl+P\",IDM_PRINT)\
menu:addString(\"Copy  Ctrl+C\",IDM_COPY)\
menu:addString(\"------------\")\
menu:addString(\"Quit App\",IDM_QUITAPP)\
menu:track(0,1)\
end\
function appFrame:onCommand(cmdId)\
if cmdId==IDM_OPEN then\
self:onOpenFile()\
return true\
end\
if cmdId==IDM_PRINT then\
self:printDoc()\
return true\
end\
if cmdId==IDM_COPY then\
self:onCopy()\
return true\
end\
if cmdId==IDM_QUITAPP then\
self:quitApp()\
return true\
end\
return false\
end\
function appFrame:onMove()\
self.app_to:move(0,1,self.width)\
self.app_from:move(0,2,self.width)\
self.app_sent:move(0,3,self.width)\
self.app_subject:move(0,4,self.width)\
self.app_message:move(0,5,self.width,self.height-5)\
return false\
end\
function appFrame:onCreate()\
self:dress(APP_TITLE)\
local menuBtn=win.buttonWindow:new(self,ID_MENUBTN,0,0,\"Menu\")\
menuBtn:setColors(menuBtn:getColors().frameText,\
menuBtn:getColors().titleBack,\
menuBtn:getColors().frameBack)\
menuBtn:move(nil,nil,nil,nil,win.WND_TOP)\
self.app_to=win.labelWindow:new(self,0,0,1,\"\")\
self.app_from=win.labelWindow:new(self,0,0,2,\"\")\
self.app_sent=win.labelWindow:new(self,0,0,3,\"\")\
self.app_subject=win.labelWindow:new(self,0,0,4,\"\")\
self.app_message=win.textWindow:new(self,0,0,5,self.width,self.height-5,\"\")\
self.app_message:setColor(self:getColors().wndText)\
self.app_message:setBgColor(self:getColors().wndBack)\
self.app_curPath=nil\
if #appArgs>0 then\
self:openFile(appArgs[1])\
end\
self:setActiveTopFrame()\
return true\
end\
local function emailDateTime(dateTime)\
local str=\"\"\
if dateTime then\
local day,part=math.modf(dateTime)\
local hour,minute=math.modf(part*24)\
minute=math.floor(minute*60)\
str=string.format(\"%d, %02d:%02d\",day,hour,minute)\
end\
return str\
end\
function appFrame:openFile(path)\
local result=false\
local file=fs.open(path,\"r\")\
if file then\
local email=textutils.unserialize(file.readAll())\
if email then\
self.app_to:setText(\"To     : \"..asstring(email.recipient))\
self.app_from:setText(\"From   : \"..asstring(email.sender))\
self.app_sent:setText(\"Sent   : \"..emailDateTime(email.time))\
self.app_subject:setText(\"Subject: \"..asstring(email.subject))\
self.app_message:setText(asstring(email.message))\
if email.subject then\
self:setTitle(asstring(email.subject)..\":\"..APP_TITLE)\
else\
self:setTitle(\"no subject:\"..APP_TITLE)\
end\
result=true\
end\
file.close()\
end\
if not result then\
self:msgBox(\"Error\",\"Could not open email\",colors.red)\
end\
end\
function appFrame:onOpenFile()\
local path=cmndlg.openFile(self,self.app_curPath,true)\
if path then\
self:openFile(path)\
end\
end\
function appFrame:onCopy()\
self:setClipboard(string.format(\
\"%s\\r%s\\r%s\\r%s\\r------------------------\\r%s\",\
self.app_to:getText(),\
self.app_from:getText(),\
self.app_sent:getText(),\
self.app_subject:getText(),\
self.app_message:getText()),\
CB_TEXT)\
end\
appFrame:runApp()\
",
"local appArgs={...}\
local appFrame=win.createAppFrame()\
local APP_TITLE=\"email\"\
local ID_MENUBTN=101\
local ID_TO=102\
local ID_SUBJECT=103\
local ID_MESSAGE=104\
local IDM_SEND=1001\
local IDM_QUITAPP=1002\
local ID_EMAIL_FRAME=32154\
function appFrame:onSent(msg,success)\
if msg.context==\"email_send\" then\
self:commClose(self.app_connName)\
self.app_connName=nil\
if success then\
local path;\
repeat\
path=self.app_dataPath..\"/sent/s\"..\
tostring(math.random(1,65535))..\".email\"\
until not fs.exists(path)\
local file=fs.open(path,\"w\")\
if file then\
file.write(textutils.serialize(msg.data.email))\
file.close()\
else\
self:msgBox(\"Sent\",\"Email was sent but could not save a copy.\",colors.red)\
end\
local instance=self:getDesktop():getWndById(ID_EMAIL_FRAME)\
if instance then\
instance:sendEvent(\"reload_list\",\"sent\")\
end\
self.app_msgSent=true\
self:quitApp()\
else\
self:msgBox(\"Error\",\"Could not send email!\",colors.red)\
end\
end\
return true\
end\
function appFrame:onEvent(event,p1,p2,p3,p4,p5,...)\
if event==\"btn_click\" then\
if p1:getId()==ID_MENUBTN then\
self:onMenu()\
return true\
end\
elseif event==\"menu_cmd\" then\
return self:onCommand(p1)\
elseif event==\"input_change\" then\
if p1:getId()==ID_SUBJECT then\
self:setTitle(iif(p1:getText():len()>0,p1:getText()..\":\",\"\")..APP_TITLE)\
return true\
end\
end\
return false\
end\
function appFrame:onChildKey(wnd,key,ctrl,alt,shift)\
if win.applicationFrame.onChildKey(self,wnd,key,ctrl,alt,shift)then\
return true\
end\
if ctrl and not alt and not shift then\
if key==keys.s then\
return self:onCommand(IDM_SEND)\
end\
end\
return false\
end\
function appFrame:onQuit()\
if self.app_connName then\
self:msgBox(\"Sending\",\"Send in progress.\",colors.orange)\
return true\
end\
if not self.app_msgSent then\
if not cmndlg.confirm(self,\"Unsent\",\"Message not sent. Quit anyway?\")then\
return true\
end\
end\
return false\
end\
function appFrame:onMenu()\
local menu=win.menuWindow:new(self)\
menu:addString(\"Send Ctrl+S\",IDM_SEND)\
menu:addString(\"-----------\")\
menu:addString(\"Quit App\",IDM_QUITAPP)\
menu:track(0,1)\
end\
function appFrame:onCommand(cmdId)\
if cmdId==IDM_SEND then\
self:onSend()\
return true\
end\
if cmdId==IDM_QUITAPP then\
self:quitApp()\
return true\
end\
return false\
end\
function appFrame:onMove()\
self.app_to:move(1,1,self.width-2)\
self.app_subject:move(1,3,self.width-2)\
self.app_message:move(1,5,self.width-2,self.height-6)\
return false\
end\
function appFrame:onCreate()\
self:dress(APP_TITLE)\
local menuBtn=win.buttonWindow:new(self,ID_MENUBTN,0,0,\"Menu\")\
menuBtn:setColors(menuBtn:getColors().frameText,\
menuBtn:getColors().titleBack,\
menuBtn:getColors().frameBack)\
menuBtn:move(nil,nil,nil,nil,win.WND_TOP)\
self.app_to=win.inputWindow:new(self,ID_TO,1,1,self.width-2,\
nil,\"Recipient\")\
self.app_subject=win.inputWindow:new(self,ID_SUBJECT,1,3,\
self.width-2,nil,\"Subject\")\
self.app_message=win.editWindow:new(self,ID_MESSAGE,1,5,\
self.width-2,self.height-6,nil,\"Message\")\
self.app_appFolder=self:getAppPath():sub(1,-(fs.getName(self:getAppPath()):len()+1))\
self.app_dataPath=self.app_appFolder..\"data/email\"\
self.app_connName=nil\
self.app_msgSent=false\
if #appArgs>0 then\
self.app_to:setText(appArgs[1])\
self.app_subject:setFocus()\
else\
self.app_to:setFocus()\
end\
self:setActiveTopFrame()\
return true\
end\
function appFrame:onSend()\
local recipient=self.app_to:getText()\
if recipient:len()>2 and recipient:find(\"@\",1,true)then\
local ini=fs.loadIniFile(self.app_appFolder..\"email.ini\")\
if ini then\
local address=asstring((ini:find(\"address\")))\
local network=asstring(ini:find(\"network\"),\"wide_area_network\")\
local port=asnumber(ini:find(\"port\"),80)\
local timeout=asnumber(ini:find(\"timeout\"),5)\
local wireless=asstring(ini:find(\"wireless\"),\"true\")~=\"false\"\
if address:len()>2 and address:find(\"@\",1,true)then\
local con=self:commOpen(nil,wireless,port,timeout,false)\
if not con then\
self:msgBox(\"Connection\",\"Could not connect to modem!\",colors.red)\
return\
end\
self.app_connName=con:getName()\
self:wantMessages(network,self.app_connName)\
local domain=recipient:sub(recipient:find(\"@\",1,true)+1)\
local account=recipient:sub(1,recipient:find(\"@\",1,true)-1)\
self:sendMessage(domain,network,\"email_send\",\
{\
account=account,\
email=\
{\
recipient=recipient,\
sender=address,\
time=((os.time()/24)+os.day()),\
subject=self.app_subject:getText(),\
message=self.app_message:getText()\
}\
},self.app_connName)\
else\
self:msgBox(\"Account\",\"Invalid account settings!\",colors.red)\
end\
else\
self:msgBox(\"Account\",\"No account set up!\",colors.red)\
end\
else\
self.app_to:setError(true)\
self.app_to:setFocus()\
end\
end\
appFrame:runApp()\
",
"local appArgs={...}\
local appFrame=win.createAppFrame()\
local APP_TITLE=\"admin\"\
local ID_OK=1\
local ID_MENUBTN=101\
local ID_DOMAIN=102\
local ID_NETWORK=103\
local ID_PORT=104\
local ID_TIMEOUT=105\
local ID_WIRELESS=106\
local ID_PASSWORD=107\
local ID_PROGRESS=108\
local ID_ACCOUNT=109\
local ID_SRCPATH=110\
local ID_SRCBROWSE=111\
local ID_DESTPATH=112\
local ID_LISTING=113\
local IDM_CONNECTION=1001\
local IDM_UP=1002\
local IDM_OPEN=1003\
local IDM_NEWDIR=1004\
local IDM_UPLOAD=1005\
local IDM_DOWNLOAD=1006\
local IDM_DELETE=1007\
local IDM_NEWACC=1008\
local IDM_RESETACC=1009\
local IDM_DELACC=1010\
local IDM_QUITAPP=1011\
local TYPE_UP=0\
local TYPE_DIR=1\
local TYPE_FILE=2\
local function pathFolder(path)\
path=asstring(path)\
if path:len()>1 then\
if path:sub(-1,-1)==\"/\" then\
path=path:sub(1,-2)\
end\
local lastName=fs.getName(path)\
path=path:sub(1,-(lastName:len()+1))\
else\
path=\"/\"\
end\
return path\
end\
local connectDlg=win.popupFrame:base()\
function connectDlg:onCreate(domain,password,network,port,timeout,wireless)\
self:dress(\"Connection\")\
self.con_domain=\
win.inputWindow:new(self,ID_DOMAIN,1,2,17,\
asstring(domain),\"Domain\")\
self.con_password=\
win.inputWindow:new(self,ID_PASSWORD,1,4,17,\
asstring(password),\"Password\")\
self.con_password:setMaskChar(\"*\")\
self.con_network=\
win.inputWindow:new(self,ID_NETWORK,1,6,17,\
asstring(network,\"wide_area_network\"),\"Network\")\
self.con_port=\
win.inputWindow:new(self,ID_PORT,1,8,7,\
asstring(port,\"80\"),\"Port\")\
self.con_timeout=\
win.inputWindow:new(self,ID_TIMEOUT,11,8,7,\
asstring(timeout,\"5\"),\"Timeout\")\
self.con_wireless=\
win.checkWindow:new(self,ID_WIRELESS,1,10,\"Wireless\",\
wireless~=false)\
self.con_wireless:setColors(self:getColors().popupText,\
self:getColors().popupBack,\
self:getColors().popupBack,\
self:getColors().checkText,\
self:getColors().checkBack,\
self:getColors().checkFocus)\
win.buttonWindow:new(self,ID_OK,14,10,\" Ok \")\
self.con_domain:setFocus()\
self:move(nil,nil,19,12)\
return true\
end\
function connectDlg:onEvent(event,p1,p2,p3,p4,p5,...)\
if event==\"btn_click\" then\
if p1:getId()==ID_OK then\
if self.con_domain:getText():len()<1 then\
self.con_domain:setFocus()\
self.con_domain:setError(true)\
elseif self.con_password:getText():len()<1 then\
self.con_password:setFocus()\
self.con_password:setError(true)\
else\
self:close(ID_OK)\
end\
return true\
end\
end\
return false\
end\
local accountDlg=win.popupFrame:base()\
function accountDlg:onCreate(title)\
self:dress(title)\
self.acc_account=win.inputWindow:new(self,ID_ACCOUNT,1,2,17,\
nil,\"Account\")\
self.acc_password=win.inputWindow:new(self,ID_PASSWORD,1,4,17,\
nil,\"Password\")\
win.buttonWindow:new(self,ID_OK,14,6,\" Ok \")\
self.acc_password:setMaskChar(\"*\")\
self.acc_account:setFocus()\
self:move(nil,nil,19,8)\
return true\
end\
function accountDlg:onEvent(event,p1,p2,p3,p4,p5,...)\
if event==\"btn_click\" then\
if p1:getId()==ID_OK then\
if self.acc_account:getText():len()<1 then\
self.acc_account:setFocus()\
elseif self.acc_password:getText():len()<1 then\
self.acc_password:setFocus()\
else\
self:close(ID_OK)\
end\
return true\
end\
end\
return false\
end\
function appFrame:onReceive(msg)\
if(msg.recipientId or msg.recipientName)and type(msg.data)==\"table\" then\
if msg.context==\"listing_response\" and type(msg.data.files)==\"table\" and\
type(msg.data.folders)==\"table\" and msg.data.path then\
self.app_list:setCurSel(0)\
self.app_list:resetContent()\
self.app_curPath=msg.data.path\
if msg.data.path~=\"/\" then\
self.app_list:addString(\"..\",{name=\"\",type=TYPE_UP})\
end\
table.sort(msg.data.folders)\
table.sort(msg.data.files)\
for i=1,#msg.data.folders,1 do\
self.app_list:addString(\"/\"..msg.data.folders[i],\
{name=msg.data.folders[i],type=TYPE_DIR})\
end\
for i=1,#msg.data.files,1 do\
self.app_list:addString(msg.data.files[i],\
{name=msg.data.files[i],type=TYPE_FILE})\
end\
self:updateTitle()\
self:startTimer(0.1)\
return true\
elseif msg.context==\"ftp_response\" and\
msg.data.path and msg.data.content then\
local path=cmndlg.saveFile(self,fs.getName(msg.data.path))\
if path then\
self.app_lastFile=path\
local hFile=fs.open(path,\"w\")\
if hFile then\
hFile.write(msg.data.content)\
hFile.close()\
else\
self:msgBox(\"File Error\",\"Could not write file \"..path,colors.red)\
end\
end\
self:startTimer(0.1)\
return true\
end\
end\
return false\
end\
function appFrame:onSent(msg,success)\
if success then\
if msg.context==\"file_delete\" or msg.context==\"file_upload\" or\
msg.context==\"directory_create\" then\
self:closeConnection()\
self:onFileList()\
elseif msg.context==\"create_account\" then\
self:closeConnection()\
self:msgBox(\"Success\",\"Account created.\")\
elseif msg.context==\"delete_account\" then\
self:closeConnection()\
self:msgBox(\"Success\",\"Account deleted.\")\
elseif msg.context==\"reset_password\" then\
self:closeConnection()\
self:msgBox(\"Success\",\"Account reset.\")\
end\
else\
self:closeConnection()\
self:msgBox(\"Fail\",\"Action failed!\",colors.red)\
end\
return true\
end\
function appFrame:onEvent(event,p1,p2,p3,p4,p5,...)\
if event==\"btn_click\" then\
if p1:getId()==ID_MENUBTN then\
self:onMenu()\
return true\
end\
elseif event==\"menu_cmd\" then\
return self:onCommand(p1)\
elseif event==\"list_double_click\" then\
if p1:getId()==ID_LISTING then\
self:doDefaultAction()\
return true\
end\
end\
return false\
end\
function appFrame:onChildKey(wnd,key,ctrl,alt,shift)\
if win.applicationFrame.onChildKey(self,wnd,key,ctrl,alt,shift)then\
return true\
end\
if ctrl and not alt and not shift then\
if key==keys.c then\
return self:onCommand(IDM_CONNECTION)\
end\
if key==keys.up then\
return self:onCommand(IDM_UP)\
end\
if key==keys.o then\
return self:onCommand(IDM_OPEN)\
end\
if key==keys.n then\
return self:onCommand(IDM_NEWDIR)\
end\
if key==keys.u then\
return self:onCommand(IDM_UPLOAD)\
end\
if key==keys.d then\
return self:onCommand(IDM_DOWNLOAD)\
end\
if key==keys.a then\
return self:onCommand(IDM_NEWACC)\
end\
if key==keys.r then\
return self:onCommand(IDM_RESETACC)\
end\
if key==keys.k then\
return self:onCommand(IDM_DELACC)\
end\
elseif not ctrl and not alt and not shift then\
if key==keys.delete then\
return self:onCommand(IDM_DELETE)\
end\
end\
return false\
end\
function appFrame:onFrameActivate(active)\
end\
function appFrame:onTimer(id)\
self:closeConnection()\
return false\
end\
function appFrame:onQuit()\
self:closeConnection()\
return false\
end\
function appFrame:onMenu(x,y)\
local menu=win.menuWindow:new(self)\
x=x or 0\
y=y or 1\
menu:addString(\"Connection  Ctrl+C\",IDM_CONNECTION)\
if self:canConnect()then\
menu:addString(\"------------------\")\
if self:canUp()then\
menu:addString(\"Up          Ctrl+^\",IDM_UP)\
end\
if self:canOpen()then\
menu:addString(\"Open        Ctrl+O\",IDM_OPEN)\
end\
menu:addString(\"New Folder  Ctrl+N\",IDM_NEWDIR)\
menu:addString(\"Upload      Ctrl+U\",IDM_UPLOAD)\
if self:canDownloadFile()then\
menu:addString(\"Download    Ctrl+D\",IDM_DOWNLOAD)\
end\
if self:canDeleteItem()then\
menu:addString(\"Delete         Del\",IDM_DELETE)\
end\
menu:addString(\"------------------\")\
menu:addString(\"New Account Ctrl+A\",IDM_NEWACC)\
menu:addString(\"Reset Acc   Ctrl+R\",IDM_RESETACC)\
menu:addString(\"Delete Acc  Ctrl+K\",IDM_DELACC)\
end\
menu:addString(\"------------------\")\
menu:addString(\"Quit App\",IDM_QUITAPP)\
menu:track(x,y)\
end\
function appFrame:onCommand(cmdId)\
if cmdId==IDM_CONNECTION then\
self:onConnection()\
return true\
end\
if cmdId==IDM_UP then\
self:onUp()\
return true\
end\
if cmdId==IDM_OPEN then\
self:onOpen()\
return true\
end\
if cmdId==IDM_NEWDIR then\
self:onNewFolder()\
return true\
end\
if cmdId==IDM_UPLOAD then\
self:onUploadFile()\
return true\
end\
if cmdId==IDM_DOWNLOAD then\
self:onDownloadFile()\
return true\
end\
if cmdId==IDM_DELETE then\
self:onDeleteItem()\
return true\
end\
if cmdId==IDM_NEWACC then\
self:onCreateAccount()\
return true\
end\
if cmdId==IDM_RESETACC then\
self:onResetAccount()\
return true\
end\
if cmdId==IDM_DELACC then\
self:onDeleteAccount()\
return true\
end\
if cmdId==IDM_QUITAPP then\
self:quitApp()\
return true\
end\
return false\
end\
function appFrame:onMove()\
self.app_list:move(1,1,self.width-2,self.height-2)\
self.app_progress:move(1,self.height-1)\
return false\
end\
function appFrame:onChildRightClick(child,x,y)\
if child==self.app_list then\
self.app_list:setFocus()\
self:onMenu(self:screenToWnd(x,y))\
return true\
end\
return false\
end\
function appFrame:onCreate()\
self:dress(APP_TITLE)\
local menuBtn=win.buttonWindow:new(self,ID_MENUBTN,0,0,\"Menu\")\
menuBtn:setColors(menuBtn:getColors().frameText,\
menuBtn:getColors().titleBack,\
menuBtn:getColors().frameBack)\
menuBtn:move(nil,nil,nil,nil,win.WND_TOP)\
self.app_domain=\"\"\
self.app_password=\"\"\
self.app_network=\"wide_area_network\"\
self.app_port=80\
self.app_timeout=5\
self.app_wireless=true\
self.app_curPath=\"/\"\
self.app_lastFile=nil\
self.app_appId=\"sadmin\"..asstring(math.random(1,65535))\
self.app_list=win.listWindow:new(self,ID_LISTING,1,1,\
self.width-2,self.height-2)\
self.app_list:setColors(self:getColors().wndText,\
self:getColors().wndBack,\
self:getColors().wndBack,\
self:getColors().selectedText,\
self:getColors().selectedBack)\
self.app_list:setFocus()\
self.app_progress=\
win.labelWindow:new(self,ID_PROGRESS,1,self.height-1,\"processing ...\")\
self.app_progress:show(false)\
if #appArgs>0 then\
local ini=fs.loadIniFile(appArgs[1])\
if ini then\
self.app_network=asstring(ini:find(\"network\"),\"wide_area_network\")\
self.app_port=asnumber(ini:find(\"port\"),80)\
self.app_timeout=asnumber(ini:find(\"timeout\"),5)\
self.app_domain=asstring(ini:find(\"domain\"),\"\")\
self.app_password=asstring(ini:find(\"password\"),\"\")\
self.app_wireless=asstring(ini:find(\"wireless\"),\"true\")~=\"false\"\
end\
end\
self.app_connName=nil\
self:setActiveTopFrame()\
if self:canConnect()then\
self:onFileList()\
end\
return true\
end\
function appFrame:updateTitle()\
if self:canConnect()then\
self:setTitle(string.trimRight(self.app_domain..self.app_curPath,\"/\")..\":\"..APP_TITLE)\
else\
self:setTitle(APP_TITLE)\
end\
end\
function appFrame:getSelectedPath()\
if self.app_list:getData()then\
if self.app_list:getData().type~=TYPE_UP then\
return(self.app_curPath..self.app_list:getData().name)\
end\
end\
return nil\
end\
function appFrame:getNetwork()\
return iif(self.app_network:len()<1,\"wide_area_network\",self.app_network)\
end\
function appFrame:canConnect()\
return self.app_domain:len()>0 and self.app_password:len()>0\
end\
function appFrame:openConnection()\
if self.app_connName then\
self:msgBox(\"Connection\",\"Action in progress!\",colors.red)\
return false\
end\
local con=self:commOpen(nil,self.app_wireless,self.app_port,\
self.app_timeout,false)\
if not con then\
self:msgBox(\"Connection\",\"Could not connect to modem!\",colors.red)\
return false\
end\
self.app_connName=con:getName()\
self:wantMessages(self:getNetwork(),self.app_connName)\
self:wantMessages(self.app_appId,self.app_connName)\
self.app_progress:show(true)\
return true\
end\
function appFrame:closeConnection()\
if self.app_connName then\
self:commClose(self.app_connName)\
self.app_connName=nil\
self.app_progress:show(false)\
end\
end\
function appFrame:onConnection()\
local dlg=connectDlg:new(self)\
if dlg:doModal(self.app_domain,self.app_password,self:getNetwork(),\
self.app_port,self.app_timeout,self.app_wireless)==ID_OK then\
self.app_domain=dlg.con_domain:getText()\
self.app_password=dlg.con_password:getText()\
self.app_network=dlg.con_network:getText()\
self.app_port=asnumber(dlg.con_port:getText(),80)\
self.app_timeout=asnumber(dlg.con_timeout:getText(),5)\
self.app_wireless=dlg.con_wireless:getChecked()\
self.app_curPath=\"/\"\
self:onFileList()\
end\
end\
function appFrame:onFileList()\
if self:openConnection()then\
self:sendMessage(self.app_domain,self:getNetwork(),\
\"listing_request\",\
{\
password=self.app_password,\
path=self.app_curPath,\
application=self.app_appId\
},self.app_connName)\
end\
end\
function appFrame:canDownloadFile()\
return self.app_list:getData()and\
self.app_list:getData().type==TYPE_FILE\
end\
function appFrame:onDownloadFile()\
if self:canDownloadFile()then\
if self:openConnection()then\
self:sendMessage(self.app_domain,self:getNetwork(),\
\"ftp_request\",\
{\
path=self:getSelectedPath(),\
application=self.app_appId\
},self.app_connName)\
end\
end\
end\
function appFrame:onUploadFile()\
if self:canConnect()then\
local path=cmndlg.openFile(self,self.app_lastFile)\
if path then\
local name=fs.getName(path)\
self.app_lastFile=path\
for i=1,self.app_list:count(),1 do\
if self.app_list:getData(i)then\
if self.app_list:getData(i).name==name then\
if cmndlg.confirm(self,\"Overwrite\",\
\"Overwrite \"..name..\"?\",\
false,colors.orange)then\
break\
else\
return\
end\
end\
end\
end\
local file=fs.open(path,\"r\")\
if not file then\
self:msgBox(\"Error\",\"Could not read source \"..path,colors.red)\
return\
end\
local content=file.readAll()\
file.close()\
if self:openConnection()then\
self:sendMessage(self.app_domain,self:getNetwork(),\
\"file_upload\",\
{\
password=self.app_password,\
path=self.app_curPath..name,\
content=content\
},self.app_connName)\
end\
end\
end\
end\
function appFrame:canDeleteItem()\
return self.app_list:getData()and\
(self.app_list:getData().type==TYPE_FILE or\
self.app_list:getData().type==TYPE_DIR)\
end\
function appFrame:onDeleteItem()\
if self:canDeleteItem()then\
local title,message;\
if self.app_list:getData().type==TYPE_FILE then\
title=\"Delete File\"\
message=\"Delete file \"..self:getSelectedPath()\
elseif self.app_list:getData().type==TYPE_DIR then\
title=\"Delete Folder\"\
message=\"Delete folder \"..self:getSelectedPath()..\
\" and all its contents\"\
end\
if cmndlg.confirm(self,title,message,false,colors.orange)then\
if self:openConnection()then\
self:sendMessage(self.app_domain,self:getNetwork(),\
\"file_delete\",\
{\
password=self.app_password,\
path=self:getSelectedPath()\
},self.app_connName)\
end\
end\
end\
end\
local function validateNewFolder(name)\
return(not name:find(\"/\",1,true))and\
(not name:find(\" \",1,true))\
end\
function appFrame:onNewFolder()\
if self:canConnect()then\
local folder=cmndlg.input(self,\"New Folder\",\"Enter new folder name.\",\
\"new\",\"Name\",nil,validateNewFolder)\
if folder then\
if self:openConnection()then\
self:sendMessage(self.app_domain,self:getNetwork(),\
\"directory_create\",\
{\
password=self.app_password,\
path=self.app_curPath..folder,\
},self.app_connName)\
end\
end\
end\
end\
function appFrame:canUp()\
return self:canConnect()and\
self.app_curPath:len()>1\
end\
function appFrame:shouldUp()\
return self:canUp()and\
self.app_list:getData()and\
self.app_list:getData().type==TYPE_UP\
end\
function appFrame:onUp()\
if self:canUp()then\
self.app_curPath=pathFolder(self.app_curPath)\
self:onFileList()\
end\
end\
function appFrame:canOpen()\
return self.app_list:getData()and\
self.app_list:getData().type==TYPE_DIR\
end\
function appFrame:onOpen()\
if self:canOpen()then\
self.app_curPath=self:getSelectedPath()..\"/\"\
self:onFileList()\
end\
end\
function appFrame:doDefaultAction()\
if self:shouldUp()then\
self:onUp()\
elseif self:canOpen()then\
self:onOpen()\
elseif self:canDownloadFile()then\
self:onDownloadFile()\
end\
end\
function appFrame:onCreateAccount()\
if self:canConnect()then\
local dlg=accountDlg:new(self)\
if dlg:doModal(\"New Account\")==ID_OK then\
if self:openConnection()then\
self:sendMessage(self.app_domain,self:getNetwork(),\
\"create_account\",\
{\
password=self.app_password,\
account=dlg.acc_account:getText(),\
clientPassword=dlg.acc_password:getText()\
},self.app_connName)\
end\
end\
end\
end\
function appFrame:onDeleteAccount()\
if self:canConnect()then\
local account=cmndlg.input(self,\"Delete Account\",\
\"Account to delete.\",nil,\"Account\")\
if account then\
if self:openConnection()then\
self:sendMessage(self.app_domain,self:getNetwork(),\
\"delete_account\",\
{\
password=self.app_password,\
account=account\
},self.app_connName)\
end\
end\
end\
end\
function appFrame:onResetAccount()\
if self:canConnect()then\
local dlg=accountDlg:new(self)\
if dlg:doModal(\"Reset Account\")==ID_OK then\
if self:openConnection()then\
self:sendMessage(self.app_domain,self:getNetwork(),\
\"reset_password\",\
{\
password=self.app_password,\
account=dlg.acc_account:getText(),\
clientPassword=dlg.acc_password:getText()\
},self.app_connName)\
end\
end\
end\
end\
appFrame:runApp()",
";domain=domain\
;password=admin\
network=wide_area_network\
port=80\
timeout=5\
wireless=true\
",
"local appArgs={...}\
local appFrame=win.createAppFrame()\
local APP_TITLE=\"command\"\
local ID_MENUBTN=101\
local IDM_QUITAPP=1001\
local cmdWnd=win.window:base()\
local hexColors=\
{\
[\"0\"]=colors.white,\
[\"1\"]=colors.orange,\
[\"2\"]=colors.magenta,\
[\"3\"]=colors.lightBlue,\
[\"4\"]=colors.yellow,\
[\"5\"]=colors.lime,\
[\"6\"]=colors.pink,\
[\"7\"]=colors.gray,\
[\"8\"]=colors.lightGray,\
[\"9\"]=colors.cyan,\
[\"a\"]=colors.purple,\
[\"A\"]=colors.purple,\
[\"b\"]=colors.blue,\
[\"B\"]=colors.blue,\
[\"c\"]=colors.brown,\
[\"C\"]=colors.brown,\
[\"d\"]=colors.green,\
[\"D\"]=colors.green,\
[\"e\"]=colors.red,\
[\"E\"]=colors.red,\
[\"f\"]=colors.black,\
[\"F\"]=colors.black\
}\
local function createEnvironment(wnd)\
local global=getfenv(0)\
local data=\
{\
x=1,\
y=1,\
color=colors.white,\
bgColor=colors.black,\
lines={},\
dir=\"\",\
path=\".:/rom/programs\",\
aliases=\
{\
[\"ls\"]=\"list\",\
[\"mv\"]=\"move\",\
[\"rm\"]=\"delete\",\
[\"dir\"]=\"list\",\
[\"sh\"]=\"shell\",\
[\"cp\"]=\"copy\",\
[\"rs\"]=\"redstone\",\
[\"clr\"]=\"clear\"\
},\
stack={},\
term=term.current(),\
device=iif(wnd.gdi:isTerm(),term.current(),wnd.gdi.gdi__device)\
}\
data.buffer=\
{\
setTextColor=function(clr)\
data.color=clr\
end,\
setBackgroundColor=function(clr)\
data.bgColor=clr\
end,\
setTextColour=function(clr)\
data.color=clr\
end,\
setBackgroundColour=function(clr)\
data.bgColor=clr\
end,\
getTextColor=function()\
return data.color\
end,\
getBackgroundColor=function()\
return data.bgColor\
end,\
getTextColour=function()\
return data.color\
end,\
getBackgroundColour=function()\
return data.bgColor\
end,\
isColor=function()\
return data.device.isColor()\
end,\
isColour=function()\
return data.device.isColor()\
end,\
getSize=function()\
return wnd.width,wnd.height\
end,\
getCursorPos=function()\
return data.x,data.y\
end,\
write=function(text)\
text=tostring(text)\
if text:len()>0 then\
local first,last=data.x,data.x+text:len()-1\
if not data.lines[data.y]then\
data.lines[data.y]={}\
else\
for i=#data.lines[data.y],1,-1 do\
local part=data.lines[data.y][i]\
if first<=part.first then\
if last>=part.last then\
table.remove(data.lines[data.y],i)\
elseif last>=part.first then\
part.text=part.text:sub(last-part.first+2)\
part.first=last+1\
end\
elseif last>=part.last then\
if first<=part.last then\
part.text=part.text:sub(1,-(part.last-first+2))\
part.last=first-1\
end\
elseif first>part.first and last<part.last then\
data.lines[data.y][#data.lines[data.y]+1]=\
{\
first=last+1,\
last=part.last,\
color=part.color,\
bgColor=part.bgColor,\
text=part.text:sub(last-part.first+2)\
}\
part.text=part.text:sub(1,first-part.first)\
part.last=first-1\
end\
end\
end\
data.lines[data.y][#data.lines[data.y]+1]=\
{\
first=first,\
last=last,\
color=data.color,\
bgColor=data.bgColor,\
text=text\
}\
data.x=last+1\
term.setCursorPos(data.x,data.y)\
wnd:invalidate()\
end\
end,\
setCursorPos=function(cx,cy)\
data.x=cx\
data.y=cy\
wnd.wnd__cursorX=data.x-1\
wnd.wnd__cursorY=data.y-1\
if wnd:getFocus()==wnd then\
local rt=wnd:getScreenRect()\
cx=cx+rt.x\
cy=cy+rt.y\
if rt:contains(cx-1,cy-1)then\
data.device.setCursorPos(cx,cy)\
else\
data.device.setCursorPos(-1,-1)\
end\
end\
end,\
scroll=function(n)\
n=math.floor(n)\
if n>0 then\
local newLines={}\
for k,v in pairs(data.lines)do\
if(k-n)>0 then\
newLines[k-n]=v\
end\
end\
data.lines=newLines\
end\
end,\
setCursorBlink=function(bool)\
data.device.setCursorBlink(bool)\
end,\
clear=function()\
data.lines={}\
wnd:invalidate()\
term.setCursorPos(1,1)\
end,\
clearLine=function()\
data.lines[data.y]=nil\
wnd:invalidate()\
term.setCursorPos(1,data.y)\
end,\
blit=function(text,fore,back)\
local t=tostring(text)\
local f=tostring(fore)\
local b=tostring(back)\
local l=t:len()\
if f:len()<l then\
l=f:len()\
end\
if b:len()<l then\
l=b:len()\
end\
for c=1,l,1 do\
setTextColor(hexColors[f:sub(c,c)]or colors.white)\
setBackgroundColor(hexColors[b:sub(c,c)]or colors.black)\
write(t:sub(c,c))\
end\
end,\
redirect=data.term.redirect,\
restore=data.term.restore,\
current=data.term.current\
}\
data.blit=function(gdi)\
for line=1,wnd.height,1 do\
if data.lines[line]then\
for i=1,#data.lines[line],1 do\
local b=data.lines[line][i]\
gdi:setTextColor(b.color)\
gdi:setBackgroundColor(b.bgColor)\
gdi:write(b.text,b.first-1,line-1)\
end\
end\
end\
end\
data.resize=function()\
local last=0\
for line,v in pairs(data.lines)do\
if line>last then\
last=line\
end\
end\
if last>wnd.height then\
data.buffer.scroll(last-wnd.height)\
data.buffer.setCursorPos(data.x,data.y-(last-wnd.height))\
end\
end\
data.redirectTerm=function()\
term.redirect(data.buffer)\
end\
data.restoreTerm=function()\
term.redirect(data.term)\
end\
data.env={}\
for k,v in pairs(global)do\
if type(v)==\"table\" then\
data.env[k]={}\
for k1,v1 in pairs(v)do\
data.env[k][k1]=v1\
end\
else\
data.env[k]=v\
end\
end\
if not data.env.shell then\
data.env.shell={}\
end\
data.env.shell.exit=function()\
wnd.cw__continue=false\
end\
data.env.shell.dir=function()\
return data.dir\
end\
data.env.shell.setDir=function(path)\
data.dir=asstring(path)\
end\
data.env.shell.path=function()\
return data.path\
end\
data.env.shell.setPath=function(path)\
data.path=asstring(path)\
end\
data.env.shell.resolve=function(path)\
path=asstring(path)\
if path:sub(1,1)==\"/\" or path:sub(1,1)==\"\\\\\" then\
return fs.combine(\"\",path)\
else\
return fs.combine(data.dir,path)\
end\
end\
data.env.shell.resolveProgram=function(cmd)\
cmd=asstring(cmd)\
if data.aliases[cmd]then\
cmd=data.aliases[cmd]\
end\
if cmd:sub(1,1)==\"/\" or cmd:sub(1,1)==\"\\\\\" then\
local path=fs.combine(\"\",cmd)\
if fs.exists(path)and not fs.isDir(path)then\
return path\
end\
return nil\
end\
for path in data.path:gmatch(\"[^:]+\")do\
path=fs.combine(data.env.shell.resolve(path),cmd)\
if fs.exists(path)and not fs.isDir(path)then\
return path\
end\
end\
return nil\
end\
data.env.shell.aliases=function()\
local copy={}\
for name,cmd in pairs(data.aliases)do\
copy[name]=cmd\
end\
return copy\
end\
data.env.shell.setAlias=function(name,cmd)\
data.aliases[name]=cmd\
end\
data.env.shell.clearAlias=function(name)\
data.aliases[name]=nil\
end\
data.env.shell.programs=function(bHidden)\
local progs={}\
for path in data.path:gmatch(\"[^:]+\")do\
path=data.env.shell.resolve(path)\
if fs.isDir(path)then\
local success,files=pcall(fs.list,path)\
if success then\
for i=1,#files,1 do\
if not fs.isDir(fs.combine(path,files[i]))and\
(bHidden or files[i]:sub(1,1)~=\".\")then\
progs[#progs+1]=files[i]\
end\
end\
end\
end\
end\
table.sort(progs)\
return progs\
end\
data.env.shell.run=function(...)\
local result=false\
local args=win.parseCmdLine(...)\
local path=data.env.shell.resolveProgram(args[1])\
if path then\
data.stack[#data.stack+1]=path\
result=os.run(data.env,path,unpack(args,2))\
data.stack[#data.stack]=nil\
elseif asstring(args[1]):len()>0 then\
error(\"No such program \"..asstring(args[1]),0)\
end\
return result\
end\
data.env.shell.getRunningProgram=function()\
if #data.stack>0 then\
return data.stack[#data.stack]\
end\
return nil\
end\
return data\
end\
function cmdWnd:constructor(parent,id,x,y,width,height)\
if not win.window.constructor(self,parent,id,x,y,width,height)then\
return nil\
end\
self:setColor(colors.white)\
self:setBgColor(colors.black)\
self:setWantKeyInput(win.KEYINPUT_LINE)\
self.cw__promptColor=colors.yellow\
self.cw__errorColor=colors.red\
self:wantEvent(\"*\")\
self.cw__routine=nil\
self.cw__state=\"none\"\
self.cw__ready=false\
self.cw__sleep=nil\
self.cw__awake=os.clock()\
self.cw__continue=true\
self.cw__env=nil\
self:startShell()\
return self\
end\
function cmdWnd:setColors(text,prompt,errorColor,back)\
self:setColor(text)\
self:setBgColor(back)\
self.cw__promptColor=prompt\
self.cw__errorColor=errorColor\
end\
function cmdWnd:resume(...)\
if self.cw__env then\
local success,state,param;\
self.cw__env.redirectTerm()\
if self.cw__state==\"new\" then\
success,state,param=coroutine.resume(self.cw__routine,self,...)\
elseif self.cw__state==\"event\" then\
success,state,param=coroutine.resume(self.cw__routine,...)\
elseif self.cw__state==\"sleep\" then\
local p={...}\
if(p[1]==\"timer\" and p[2]==self.cw__sleep)or\
(os.clock()>self.cw__awake)or p[1]==\"terminate\" then\
self.cw__sleep=nil\
success,state,param=coroutine.resume(self.cw__routine,p[1])\
end\
end\
self.cw__env.restoreTerm()\
if success~=nil then\
if success then\
if self.cw__routine then\
self.cw__state=state\
self.cw__ready=true\
if state==\"sleep\" then\
self.cw__sleep=self:startTimer(param)\
self.cw__awake=os.clock()+asnumber(param)\
end\
else\
self.cw__state=\"none\"\
self.cw__ready=false\
self.cw__sleep=nil\
self.cw__env=nil\
if self:getParent()then\
self:getParent():sendEvent(\"cmd_exit\",self)\
end\
end\
else\
if self:getParent()then\
self:getParent():sendEvent(\"cmd_error\",self,state)\
end\
end\
end\
end\
end\
function cmdWnd:routeWndEvent(event,p1,p2,p3,p4,p5,...)\
win.window.routeWndEvent(self,event,p1,p2,p3,p4,p5,...)\
if self.cw__ready then\
if event==\"terminate\" and self:getFocus()~=self then\
return false\
end\
if event==\"mouse_click\" or event==\"mouse_drag\" or\
event==\"monitor_touch\" or event==\"mouse_scroll\" then\
p2,p3=self:screenToWnd(p2,p3)\
end\
self:resume(event,p1,p2,p3,p4,p5,...)\
end\
return true\
end\
local function getShellLoop()\
return function(wnd,...)\
local args={...}\
wnd.cw__env.redirectTerm()\
if #args>0 then\
local success,msg=pcall(shell.run,...)\
if not success then\
term.setTextColor(wnd.cw__errorColor)\
print(msg)\
term.setTextColor(wnd:getColor())\
term.write(\"Press key ...\")\
repeat until(os.pullEvent())==\"key\"\
end\
else\
local history={}\
term.setBackgroundColor(wnd:getBgColor())\
term.setTextColor(wnd.cw__promptColor)\
print(os.version())\
while wnd.cw__continue do\
local success,msg,line;\
term.setBackgroundColor(wnd:getBgColor())\
term.setTextColor(wnd.cw__promptColor)\
write(shell.dir()..\"> \")\
term.setTextColor(wnd:getColor())\
success,line=pcall(read,nil,history)\
if success then\
for i=#history,1,-1 do\
if history[i]==line then\
table.remove(history,i)\
end\
end\
history[#history+1]=line\
success,msg=pcall(shell.run,line)\
if not success then\
term.setTextColor(wnd.cw__errorColor)\
print(msg)\
end\
else\
term.setTextColor(wnd.cw__errorColor)\
print(line)\
end\
end\
end\
wnd.cw__env.restoreTerm()\
wnd.cw__routine=nil\
end\
end\
function cmdWnd:startShell()\
local f=getShellLoop()\
self.cw__env=createEnvironment(self)\
self.cw__env.path=self:getWorkSpace():getShell().path()\
setfenv(f,self.cw__env.env)\
self.cw__routine=coroutine.create(f)\
if self.cw__routine then\
self.cw__continue=true\
self.cw__state=\"new\"\
return true\
end\
return false\
end\
function cmdWnd:ready()\
return self.cw__state~=\"none\"\
end\
function cmdWnd:draw(gdi,bounds)\
if self.cw__env then\
self.cw__env.blit(gdi)\
end\
end\
function cmdWnd:onMove()\
if self.cw__env then\
self.cw__env.resize()\
end\
if self.cw__ready then\
self:resume(\"term_resize\",self:getSide())\
end\
return false\
end\
function cmdWnd:onFocus(blurred)\
self:showCursor()\
return false\
end\
function appFrame:onEvent(event,p1,p2,p3,p4,p5,...)\
if event==\"btn_click\" then\
if p1:getId()==ID_MENUBTN then\
self:onMenu()\
return true\
end\
elseif event==\"menu_cmd\" then\
return self:onCommand(p1)\
elseif event==\"cmd_exit\" then\
self:startTimer(0.1)\
return true\
elseif event==\"cmd_error\" then\
self:msgBox(\"Error\",p2,colors.red)\
return true\
end\
return false\
end\
function appFrame:onTimer(id)\
self:quitApp()\
return false\
end\
function appFrame:onMenu()\
local menu=win.menuWindow:new(self)\
menu:addString(\"Quit App   \",IDM_QUITAPP)\
menu:track(0,1)\
end\
function appFrame:onCommand(cmdId)\
if cmdId==IDM_QUITAPP then\
self:quitApp()\
return true\
end\
return false\
end\
function appFrame:onMove()\
self.app_cmdWnd:move(0,1,self.width,self.height-1)\
return false\
end\
function appFrame:onChildKey(wnd,key,ctrl,alt,shift)\
if key==keys.tab then\
if not ctrl and not alt and not shift and wnd==self.app_cmdWnd then\
return false\
end\
end\
return win.applicationFrame.onChildKey(self,wnd,key,ctrl,alt,shift)\
end\
function appFrame:onCreate()\
self:dress(APP_TITLE)\
local menuBtn=win.buttonWindow:new(self,ID_MENUBTN,0,0,\"Menu\")\
menuBtn:setColors(menuBtn:getColors().frameText,\
menuBtn:getColors().titleBack,\
menuBtn:getColors().frameBack)\
menuBtn:move(nil,nil,nil,nil,win.WND_TOP)\
self.app_cmdWnd=cmdWnd:new(self,0,0,1,self.width,self.height-1)\
self.app_cmdWnd:setFocus()\
self:setActiveTopFrame()\
self.app_cmdWnd:resume(unpack(appArgs))\
return self.app_cmdWnd:ready()\
end\
appFrame:runApp()\
",
"Explore\
/win/apps/fexplore\
\
\
\
NotePad\
/win/apps/notepad\
\
\
\
Browse\
/win/apps/browse\
\
\
\
Email\
/win/apps/email\
\
\
\
Command\
/win/apps/cmd\
\
\
\
Chat\
/win/apps/chat\
\
\
\
Admin\
/win/apps/sadmin\
/win/apps/sadmin.ini\
\
\
Manager\
/win/apps/manager\
\
\
\
Shutdown\
/win/apps/shutdown\
\
\
 \
",
"; auto-run at startup\
;run=fullPath [arguments]\
\
; name of desktop\
;home=Home\
\
; buffer display drawing\
buffer=true\
\
; start in full screen\
;fullscreen=false\
",
"\
-- collect any program arguments\
local appArgs = {...}\
\
-- create the application's main frame\
local appFrame = win.createAppFrame()\
\
-- run the application's loop\
appFrame:runApp()\
",
"\
-- collect any program arguments\
local appArgs = {...}\
\
-- create the application's main frame\
local appFrame = win.createAppFrame()\
\
\
local APP_TITLE      = \"Starter\"\
\
\
-- handle control, wanted and custom events\
function appFrame:onEvent(event, p1, p2, p3, p4, p5, ...)\
   -- handle events and return true\
\
   return false\
end\
\
\
-- if needed, low priority, called about every 1/3 second\
-- when nothing happening - but keep it brief\
function appFrame:onIdle(idleCount)\
   return false\
end\
\
\
-- if needed\
function appFrame:onAlarm(alarmId)\
   return false\
end\
\
\
-- if needed\
function appFrame:onTimer(timerId)\
   return false\
end\
\
\
-- to reposition control windows, app frames should only\
-- move if monitor device changes size/resolution or\
-- fullscreen mode changes\
function appFrame:onMove()\
   return false\
end\
\
\
-- for clean up, if needed\
function appFrame:onDestroyWnd()\
end\
\
\
-- to implement accelerator keys. best to use with combo keys\
-- to try and avoid char event following to child\
function appFrame:onChildKey(wnd, key, ctrl, alt, shift)\
   -- base implements tab key navigation\
   if win.applicationFrame.onChildKey(self, wnd, key, ctrl, alt, shift) then\
      return true\
   end\
\
   -- return true if handled so child does not receive key event\
\
   return false\
end\
\
\
-- called when app becomes and stops being the active app\
function appFrame:onFrameActivate(active)\
end\
\
\
-- called when app is quitting\
function appFrame:onQuit()\
   -- return true to stop app from quitting\
\
   return false\
end\
\
\
function appFrame:onCreate()\
   -- add title bar and close btn, close btn will have focus\
   -- frame wnd text displays in running app list\
   self:dress(APP_TITLE)\
\
\
   -- create controls, usually setting focus to first\
\
\
   -- app is constructed, bring it to top\
   self:setActiveTopFrame()\
\
   return true\
end\
\
\
-- run application loop after methods are defined\
appFrame:runApp()\
",
"\
-- collect any program arguments\
local appArgs = {...}\
\
-- create the application's main frame\
local appFrame = win.createAppFrame()\
\
\
local APP_TITLE         = \"Single\"\
\
-- ids should be between 1 - 65535\
\
-- control ids\
local ID_MENUBTN        = 101\
\
-- command ids\
local IDM_ONE           = 1001\
local IDM_TWO           = 1002\
local IDM_THREE         = 1003\
local IDM_QUITAPP       = 1004\
\
-- unique id for app frame\
local ID_MYAPP_FRAME    = 12673\
\
\
-- handle control, wanted and custom events\
function appFrame:onEvent(event, p1, p2, p3, p4, p5, ...)\
   -- handle events and return true\
   if event == \"btn_click\" then\
      if p1:getId() == ID_MENUBTN then\
         self:onMenu()\
         return true\
      end\
\
   elseif event == \"menu_cmd\" then\
      return self:onCommand(p1)\
   end\
\
   return false\
end\
\
\
-- if needed, low priority, called about every 1/3 second\
-- when nothing happening - but keep it brief\
function appFrame:onIdle(idleCount)\
   return false\
end\
\
\
-- if needed\
function appFrame:onAlarm(alarmId)\
   return false\
end\
\
\
-- if needed\
function appFrame:onTimer(timerId)\
   return false\
end\
\
\
-- to reposition control windows, app frames should only\
-- move if monitor device changes size/resolution or\
-- fullscreen mode changes\
function appFrame:onMove()\
   return false\
end\
\
\
-- for clean up, if needed\
function appFrame:onDestroyWnd()\
end\
\
\
-- to implement accelerator keys. best to use with combo keys\
-- to try and avoid char event following to child\
function appFrame:onChildKey(wnd, key, ctrl, alt, shift)\
   -- base implements tab key navigation\
   if win.applicationFrame.onChildKey(self, wnd, key, ctrl, alt, shift) then\
      return true\
   end\
\
   -- return true if handled so child does not receive key event\
\
   -- accelerators to menu commands\
   if ctrl and not alt and not shift then\
      if key == keys.one then\
         return self:onCommand(IDM_ONE)\
      end\
\
      if key == keys.two then\
         return self:onCommand(IDM_TWO)\
      end\
\
      if key == keys.three then\
         return self:onCommand(IDM_THREE)\
      end\
   end\
\
   return false\
end\
\
\
-- called when app becomes and stops being the active app\
function appFrame:onFrameActivate(active)\
end\
\
\
-- called when app is quitting\
function appFrame:onQuit()\
   -- return true to stop app from quitting\
\
   return false\
end\
\
\
-- method to create and display menu\
function appFrame:onMenu()\
   local menu = win.menuWindow:new(self)\
\
   menu:addString(\"One   Ctrl+1\",   IDM_ONE)\
   menu:addString(\"Two   Ctrl+2\",   IDM_TWO)\
   menu:addString(\"Three Ctrl+3\",   IDM_THREE)\
   menu:addString(\"------------\")\
   menu:addString(\"Quit App\",       IDM_QUITAPP)\
\
   menu:track(0, 1)\
end\
\
\
-- command handler\
function appFrame:onCommand(cmdId)\
   if cmdId == IDM_ONE then\
      self:msgBox(\"Menu Command\", \"Application message box.\")\
      return true\
   end\
\
   if cmdId == IDM_TWO then\
      self:msgBox(\"Menu Command\",\
                  \"Application message box with custom colour.\",\
                  colours.lightBlue)\
      return true\
   end\
\
   if cmdId == IDM_THREE then\
      self:getDesktop():msgBox(\"Menu Command\",\
                               \"System message box with custom colour.\",\
                               colors.red)\
      return true\
   end\
\
   if cmdId == IDM_QUITAPP then\
      self:quitApp()\
      return true\
   end\
\
   return false\
end\
\
\
\
function appFrame:onCreate()\
   -- single instance, look for existing frame\
   local instance = self:getDesktop():getWndById(ID_MYAPP_FRAME, false)\
\
   -- if found\
   if instance then\
      -- bring running instance to top\
      instance:setActiveTopFrame()\
\
      -- and drop out\
      return false\
   end\
\
   -- not found, change frame id to ID_MYAPP_FRAME\
   self:setId(ID_MYAPP_FRAME)\
\
   -- add title bar and close btn, close btn will have focus\
   -- frame wnd text displays in running app list\
   self:dress(APP_TITLE)\
\
   -- create menu button on title bar\
   local menuBtn = win.buttonWindow:new(self, ID_MENUBTN, 0, 0, \"Menu\")\
   -- customise to blend into title bar\
   menuBtn:setColors(menuBtn:getColors().frameText,\
                     menuBtn:getColors().titleBack,\
                     menuBtn:getColors().frameBack)\
   -- move on top of title bar text so wont get obscured\
   menuBtn:move(nil, nil, nil, nil, win.WND_TOP)\
\
\
   -- create controls, usually setting focus to first\
\
\
   -- app is constructed, bring it to top\
   self:setActiveTopFrame()\
\
   return true\
end\
\
\
-- run application loop after methods are defined\
appFrame:runApp()\
",
"\
-- collect any program arguments\
local appArgs = {...}\
\
-- create the application's main frame\
local appFrame = win.createAppFrame()\
\
\
local APP_TITLE      = \"Menu\"\
\
-- ids should be between 1 - 65535\
\
-- control ids\
local ID_MENUBTN     = 101\
\
-- command ids\
local IDM_ONE        = 1001\
local IDM_TWO        = 1002\
local IDM_THREE      = 1003\
local IDM_QUITAPP    = 1004\
\
\
-- handle control, wanted and custom events\
function appFrame:onEvent(event, p1, p2, p3, p4, p5, ...)\
   -- handle events and return true\
   if event == \"btn_click\" then\
      if p1:getId() == ID_MENUBTN then\
         self:onMenu()\
         return true\
      end\
\
   elseif event == \"menu_cmd\" then\
      return self:onCommand(p1)\
   end\
\
   return false\
end\
\
\
-- if needed, low priority, called about every 1/3 second\
-- when nothing happening - but keep it brief\
function appFrame:onIdle(idleCount)\
   return false\
end\
\
\
-- if needed\
function appFrame:onAlarm(alarmId)\
   return false\
end\
\
\
-- if needed\
function appFrame:onTimer(timerId)\
   return false\
end\
\
\
-- to reposition control windows, app frames should only\
-- move if monitor device changes size/resolution or\
-- fullscreen mode changes\
function appFrame:onMove()\
   return false\
end\
\
\
-- for clean up, if needed\
function appFrame:onDestroyWnd()\
end\
\
\
-- to implement accelerator keys. best to use with combo keys\
-- to try and avoid char event following to child\
function appFrame:onChildKey(wnd, key, ctrl, alt, shift)\
   -- base implements tab key navigation\
   if win.applicationFrame.onChildKey(self, wnd, key, ctrl, alt, shift) then\
      return true\
   end\
\
   -- return true if handled so child does not receive key event\
\
   -- accelerators to menu commands\
   if ctrl and not alt and not shift then\
      if key == keys.one then\
         return self:onCommand(IDM_ONE)\
      end\
\
      if key == keys.two then\
         return self:onCommand(IDM_TWO)\
      end\
\
      if key == keys.three then\
         return self:onCommand(IDM_THREE)\
      end\
   end\
\
   return false\
end\
\
\
-- called when app becomes and stops being the active app\
function appFrame:onFrameActivate(active)\
end\
\
\
-- called when app is quitting\
function appFrame:onQuit()\
   -- return true to stop app from quitting\
\
   return false\
end\
\
\
-- method to create and display menu\
function appFrame:onMenu()\
   local menu = win.menuWindow:new(self)\
\
   menu:addString(\"One   Ctrl+1\",   IDM_ONE)\
   menu:addString(\"Two   Ctrl+2\",   IDM_TWO)\
   menu:addString(\"Three Ctrl+3\",   IDM_THREE)\
   menu:addString(\"------------\")\
   menu:addString(\"Quit App\",       IDM_QUITAPP)\
\
   menu:track(0, 1)\
end\
\
\
-- command handler\
function appFrame:onCommand(cmdId)\
   if cmdId == IDM_ONE then\
      self:msgBox(\"Menu Command\", \"Application message box.\")\
      return true\
   end\
\
   if cmdId == IDM_TWO then\
      self:msgBox(\"Menu Command\",\
                  \"Application message box with custom colour.\",\
                  colours.lightBlue)\
      return true\
   end\
\
   if cmdId == IDM_THREE then\
      self:getDesktop():msgBox(\"Menu Command\",\
                               \"System message box with custom colour.\",\
                               colors.red)\
      return true\
   end\
\
   if cmdId == IDM_QUITAPP then\
      self:quitApp()\
      return true\
   end\
\
   return false\
end\
\
\
\
function appFrame:onCreate()\
   -- add title bar and close btn, close btn will have focus\
   -- frame wnd text displays in running app list\
   self:dress(APP_TITLE)\
\
   -- create menu button on title bar\
   local menuBtn = win.buttonWindow:new(self, ID_MENUBTN, 0, 0, \"Menu\")\
   -- customise to blend into title bar\
   menuBtn:setColors(menuBtn:getColors().frameText,\
                     menuBtn:getColors().titleBack,\
                     menuBtn:getColors().frameBack)\
   -- move on top of title bar text so wont get obscured\
   menuBtn:move(nil, nil, nil, nil, win.WND_TOP)\
\
\
   -- create controls, usually setting focus to first\
\
\
   -- app is constructed, bring it to top\
   self:setActiveTopFrame()\
\
   return true\
end\
\
\
-- run application loop after methods are defined\
appFrame:runApp()\
\
\
\
\
",
"\
-- collect any program arguments\
local appArgs = {...}\
\
-- create the application's main frame\
local appFrame = win.createAppFrame()\
\
\
local APP_TITLE         = \"Popup\"\
\
-- ids should be between 1 - 65535\
\
-- control ids\
local ID_MENUBTN        = 101\
local ID_SETTITLEBTN    = 102\
\
-- popup ids\
local ID_TITLETEXT      = 201\
local ID_OK             = 202\
\
-- command ids\
local IDM_ONE           = 1001\
local IDM_TWO           = 1002\
local IDM_THREE         = 1003\
local IDM_QUITAPP       = 1004\
\
-- unique id for app frame\
local ID_MYAPP_FRAME    = 32174\
\
\
\
-- myPopup class -------------------------------------------------------\
local myPopup = win.popupFrame:base()\
\
\
-- return false on failure\
function myPopup:onCreate()\
   self:dress(\"Set Title\")\
\
   local inputWnd = win.inputWindow:new(self, ID_TITLETEXT, 1, 2, 14,\
                                    self:getOwner():getText(), \"Title\")\
   inputWnd:setSel(0, -1)\
   inputWnd:setFocus()\
\
   win.buttonWindow:new(self, ID_OK, 11, 4, \" Ok \")\
\
   self:move(nil, nil, 16, 6)\
\
   return true\
end\
\
\
-- handles events for myPopup\
function myPopup:onEvent(event, p1, p2, p3, p4, p5, ...)\
   if event == \"btn_click\" then\
      if p1:getId() == ID_OK then\
         local titleText = APP_TITLE\
         local titleWnd = self:getWndById(ID_TITLETEXT)\
\
         if titleWnd then\
            if string.len(titleWnd:getText()) > 0 then\
               titleText = titleWnd:getText()\
            end\
         end\
\
         self:getOwner():setTitle(titleText)\
\
         self:close(ID_OK)\
\
         return true\
      end\
   end\
\
   return false\
end\
-- end myPopup class ---------------------------------------------------\
\
\
-- handle control, wanted and custom events\
function appFrame:onEvent(event, p1, p2, p3, p4, p5, ...)\
   -- handle events and return true\
   if event == \"btn_click\" then\
      if p1:getId() == ID_MENUBTN then\
         self:onMenu()\
         return true\
      end\
\
      if p1:getId() == ID_SETTITLEBTN then\
         myPopup:new(self):doModal()\
         return true\
      end\
\
   elseif event == \"menu_cmd\" then\
      return self:onCommand(p1)\
   end\
\
   return false\
end\
\
\
-- if needed, low priority, called about every 1/3 second\
-- when nothing happening - but keep it brief\
function appFrame:onIdle(idleCount)\
   return false\
end\
\
\
-- if needed\
function appFrame:onAlarm(alarmId)\
   return false\
end\
\
\
-- if needed\
function appFrame:onTimer(timerId)\
   return false\
end\
\
\
-- to reposition control windows, app frames should only\
-- move if monitor device changes size/resolution or\
-- fullscreen mode changes\
function appFrame:onMove()\
   return false\
end\
\
\
-- for clean up, if needed\
function appFrame:onDestroyWnd()\
end\
\
\
-- to implement accelerator keys. best to use with combo keys\
-- to try and avoid char event following to child\
function appFrame:onChildKey(wnd, key, ctrl, alt, shift)\
   -- base implements tab key navigation\
   if win.applicationFrame.onChildKey(self, wnd, key, ctrl, alt, shift) then\
      return true\
   end\
\
   -- return true if handled so child does not receive key event\
\
   -- accelerators to menu commands\
   if ctrl and not alt and not shift then\
      if key == keys.one then\
         return self:onCommand(IDM_ONE)\
      end\
\
      if key == keys.two then\
         return self:onCommand(IDM_TWO)\
      end\
\
      if key == keys.three then\
         return self:onCommand(IDM_THREE)\
      end\
   end\
\
   return false\
end\
\
\
-- called when app becomes and stops being the active app\
function appFrame:onFrameActivate(active)\
end\
\
\
-- called when app is quitting\
function appFrame:onQuit()\
   -- return true to stop app from quitting\
\
   return false\
end\
\
\
-- method to create and display menu\
function appFrame:onMenu()\
   local menu = win.menuWindow:new(self)\
\
   menu:addString(\"One   Ctrl+1\",   IDM_ONE)\
   menu:addString(\"Two   Ctrl+2\",   IDM_TWO)\
   menu:addString(\"Three Ctrl+3\",   IDM_THREE)\
   menu:addString(\"------------\")\
   menu:addString(\"Quit App\",       IDM_QUITAPP)\
\
   menu:track(0, 1)\
end\
\
\
-- command handler\
function appFrame:onCommand(cmdId)\
   if cmdId == IDM_ONE then\
      appFrame:msgBox(\"Menu Command\", \"Application message box.\")\
      return true\
   end\
\
   if cmdId == IDM_TWO then\
      self:msgBox(\"Menu Command\",\
                  \"Application message box with custom colour.\",\
                  colours.lightBlue)\
      return true\
   end\
\
   if cmdId == IDM_THREE then\
      self:getDesktop():msgBox(\"Menu Command\",\
                               \"System message box with custom colour.\",\
                               colors.red)\
      return true\
   end\
\
   if cmdId == IDM_QUITAPP then\
      self:quitApp()\
      return true\
   end\
\
   return false\
end\
\
\
\
function appFrame:onCreate()\
   -- single instance, look for existing frame\
   local instance = self:getDesktop():getWndById(ID_MYAPP_FRAME, false)\
\
   -- if found\
   if instance then\
      -- bring running instance to top\
      instance:setActiveTopFrame()\
\
      -- and drop out\
      return false\
   end\
\
   -- not found, change frame id to ID_MYAPP_FRAME\
   self:setId(ID_MYAPP_FRAME)\
\
   -- add title bar and close btn, close btn will have focus\
   -- frame wnd text displays in running app list\
   self:dress(APP_TITLE)\
\
   -- create menu button on title bar\
   local menuBtn = win.buttonWindow:new(self, ID_MENUBTN, 0, 0, \"Menu\")\
   -- customise to blend into title bar\
   menuBtn:setColors(menuBtn:getColors().frameText,\
                     menuBtn:getColors().titleBack,\
                     menuBtn:getColors().frameBack)\
   -- move on top of title bar text so wont get obscured\
   menuBtn:move(nil, nil, nil, nil, win.WND_TOP)\
\
\
   -- create controls, usually setting focus to first\
   win.buttonWindow:new(self, ID_SETTITLEBTN, 2, 3, \" Set Title \"):setFocus()\
\
\
   -- app is constructed, bring it to top\
   self:setActiveTopFrame()\
\
   return true\
end\
\
\
-- run application loop after methods are defined\
appFrame:runApp()\
"
}
local function backup(path)
   if fs.exists(path) then
      print("backing up "..path)
      if fs.exists("/backup"..path) then
         fs.delete("/backup"..path)
      end
      fs.copy(path, "/backup"..path)
   end
end
backup("/startup")
backup("/win/startup.ini")
backup("/win/apps/notepad.ini")
backup("/win/apps/fexplore.asc")
backup("/win/apps/browse.ini")
backup("/win/apps/email.ini")
backup("/win/apps/sadmin.ini")
backup("/win/term/desktop.ini")
backup("/win/term/startup.ini")
backup("/win/term/theme.ini")
for i = 1, #srcFiles, 1 do
   print("unpacking "..srcFiles[i])
   local hOut = fs.open(srcFiles[i], "w")
   if not hOut then
      print("Could not open "..srcFiles[i])
      return
   end

   hOut.write(srcData[i])
   hOut.close()
end