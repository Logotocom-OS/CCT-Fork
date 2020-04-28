local srcFiles = {
"/startup",
"/server",
"/license.txt",
"/public/index.html",
"/public/joe.html",
"/public/mary.html",
"/public/fay.html",
"/public/sub/index.html",
"/public/downloads/myApp"
}
local srcData = {
"--SERVER_ROOT = \"/public\"\
--SERVER_PORT = 80\
--SERVER_NETWORK = \"wide_area_network\"\
--SERVER_WIRELESS = true\
--SERVER_TIMEOUT = 5\
--SERVER_PASSWORD = \"admin\"\
--ACCOUNTS_ROOT = \"/accounts\"\
shell.run(\"/server\")\
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
"{\
  html = {\
    head = { title = \"%s\" },\
    body = { color = \"black\", linkcolor = \"blue\", bgcolor = \"yellow\",\
      { tag = \"p\", align = \"center\", color = \"gray\", bgcolor = \"cyan\",\
        \"\\r%s\\r\\r\"\
      },\
      { tag = \"p\", align = \"left\",\
        \"Welcome to %s, where everyone has loads of fun.\"\
      },\
      { tag = \"p\", align = \"left\",\
        \"Be sure to check out our great departments.\"\
      },\
      { tag = \"p\", align = \"left\",\
        \" \", { tag = \"a\", href = \"joe.html\", \"Joe's Bar & Grill\" }, \"\\r \", { tag = \"a\", href = \"mary.html\", \"Mary's Florist\" }, \"\\r \", { tag = \"a\", href = \"fay.html\", \"Fay's Dating\" }, \"\\r \", { tag = \"a\", href = \"downloads/myApp\", protocol = \"ftp:\", \"Download App\" }\
      },\
      { tag = \"l\", width = \"50\", align = \"center\", color = \"brown\" }\
    },\
  }\
}\
",
"{\
  html = {\
    head = { title = \"Joe's Bar & Grill\" },\
    body = { color = \"light\", linkcolor = \"red\", bgcolor = \"black\",\
      { tag = \"p\", align = \"center\", color = \"light\", bgcolor = \"black\",\
        \"\\r\", { bgcolor = \"red\", \" \" }, \" Joe's Bar & Grill \", { bgcolor = \"red\", \" \" }, \"\\r\", { bgcolor = \"red\", \" \" }, { bgcolor = \"orange\", \" \" }, { bgcolor = \"red\", \" \" }, \"                 \", { bgcolor = \"red\", \" \" }, { bgcolor = \"orange\", \" \" }, { bgcolor = \"red\", \" \" }\
      },\
      { tag = \"p\", align = \"left\",\
        { color = \"blue\", \" Today's Specials:\\r\" }, \"  * Roast Horse Head.\\r  * Toasted Pig's Trotters.\\r  * Pickled Chicken Hearts.\\r  * Gravel Rashed Cow's Rump.\"\
      },\
      { tag = \"p\", color = \"blue\", align = \"center\",\
        { color = \"sky\", \"Eat at Joe's\\r\" }, \"Where every meal tries to run away.\"\
      },\
      { tag = \"p\", align = \"center\",\
        \"Proudly at \", { tag = \"a\", href = \"http:%s\", \"%s\" }\
      }\
    },\
  }\
}\
",
"{\
  html = {\
    head = { title = \"Mary's Florist\" },\
    body = { color = \"blue\", linkcolor = \"red\", bgcolor = \"yellow\",\
      { tag = \"p\", align = \"center\", color = \"pink\", bgcolor = \"green\",\
        \"\\r\", { color = \"yellow\", \"{*}\" }, \" Mary's Florist \", { color = \"yellow\", \"{*}\" }, \"\\r \"\
      },\
      { tag = \"p\", align = \"left\",\
        { color = \"black\", \" Our Extensive Range:\\r\" }, \"  + Snapping Dragons.\\r  + Violent Violets.\\r  + Ivy that Poisoned Ivy.\\r  + Two Lipped Tulips.\"\
      },\
      { tag = \"p\", color = \"brown\", align = \"center\",\
        { color = \"black\", \"Mary's Florist\" }, \"\\rWhere nature comes to life,\\rand tries to kill you.\"\
      },\
      { tag = \"p\", align = \"center\",\
        { color = \"black\", \"Proudly at \" }, { tag = \"a\", href = \"http:%s\", \"%s\" }\
      }\
    },\
  }\
}\
",
"{\
  html = {\
    head = { title = \"Fay's Dating\" },\
    body = { color = \"gray\", linkcolor = \"red\", bgcolor = \"pink\",\
      { tag = \"p\", align = \"center\", color = \"gray\", bgcolor = \"red\",\
        \"\\r\", { color = \"pink\", \"oxo\" }, \" Fay's Dating \", { color = \"pink\", \"oxo\" }, \"\\r \"\
      },\
      { tag = \"p\", align = \"left\",\
        \"Meet your perfect match at Fay's Dating.\"\
      },\
      { tag = \"p\", align = \"left\",\
        \"We use the latest matching technology available. Our matching services use a highly reliable algorithm based on how much you are involved in online dating, and the amount of money you have spent doing it.\"\
      },\
      { tag = \"p\", color = \"purple\", align = \"center\",\
        { color = \"black\", \"Fay's Dating\" }, \"\\rWhere even if you're not happy,\\rwe always are.\"\
      },\
      { tag = \"p\", align = \"center\",\
        { color = \"black\", \"Proudly at \" }, { tag = \"a\", href = \"http:%s\", \"%s\" }\
      }\
    },\
  }\
}\
",
"{\
  html = {\
    head = { title = \"%s\" },\
    body = { color = \"black\", linkcolor = \"blue\", bgcolor = \"yellow\",\
      { tag = \"p\", align = \"center\", color = \"red\", bgcolor = \"cyan\",\
        { tag = \"d\", bgcolor = \"blue\", \"  \" }, { bgcolor = \"blue\", \"  \" }, { bgcolor = \"sky\", \"             \" }, { bgcolor = \"blue\", \"  \" }, \"\\r\", { bgcolor = \"blue\", \"  \" }, { bgcolor = \"sky\", \"   my site   \" }, { bgcolor = \"blue\", \"  \" }, \"\\r\", { bgcolor = \"blue\", \"  \" }, { bgcolor = \"sky\", \"             \" }, { bgcolor = \"blue\", \"  \" }, \"\\r\", { bgcolor = \"blue\", \"                 \" }\
      },\
      { tag = \"p\", align = \"left\",\
        \"Welcome to %s, where everyone has loads of fun.\"\
      },\
      { tag = \"p\", align = \"left\",\
        \"Be sure to check out our great departments.\"\
      },\
      { tag = \"p\", align = \"left\",\
        \" \", { tag = \"a\", href = \"../joe.html\", \"Joe's Bar & Grill\" }, \"\\r \", { tag = \"a\", href = \"../mary.html\", \"Mary's Florist\" }, \"\\r \", { tag = \"a\", href = \"../fay.html\", \"Fay's Dating\" }, \"\\r \", { tag = \"a\", href = \"../downloads/myApp\", protocol = \"ftp\", \"Download App\" }\
      },\
      { tag = \"l\", width = \"50\", align = \"center\", color = \"brown\" }\
    },\
  }\
}\
",
"\
local appArgs = {...}\
local appFrame = win.createAppFrame()\
\
local APP_TITLE      = \"%s\"\
\
function appFrame:onCreate()\
   self:dress(APP_TITLE)\
   self:setActiveTopFrame()\
\
   return true\
end\
\
appFrame:runApp()\
"
}
if string.len(tostring(os.getComputerLabel() or "")) < 1 then
   print("The computer has no label set for the domain name")
   return
end
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
for i = 1, #srcFiles, 1 do
   print("unpacking "..srcFiles[i])
   local hOut = fs.open(srcFiles[i], "w")
   if not hOut then
      print("Could not open "..srcFiles[i])
      return
   end
   if i > 2 then
      hOut.write(string.format(srcData[i], os.getComputerLabel(), os.getComputerLabel(), os.getComputerLabel()))
   else
      hOut.write(srcData[i])
   end
   hOut.close()
end