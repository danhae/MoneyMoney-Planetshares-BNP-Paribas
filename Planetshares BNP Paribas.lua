-- Inofficial Planetshares BNP Paribas Extension (https://planetshares.bnpparibas.com/) for MoneyMoney (https://moneymoney-app.com)
--
-- MIT License
--
-- Copyright (c) 2018 Daniel Hähnel
--
-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:
--
-- The above copyright notice and this permission notice shall be included in all
-- copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
-- SOFTWARE.


WebBanking{version = 0.01,
  url = "https://planetshares.bnpparibas.com/ws/root",
  services = {"Planetshares BNP Paribas"}
}



function SupportsBank (protocol, bankCode)
  return protocol == ProtocolWebBanking and bankCode == "Planetshares BNP Paribas"
end

function InitializeSession (protocol, bankCode, username, username2, password)
  connection = Connection()
  content, charset, mimeType = connection:request("POST",url,'{"controllerName":"login","action":"authenticate","language":"de","parameters":{"loginEmet":"'..username..'","loginActi":"'..username2..'","pwd":"'..password..'"},"trads":[]}',"application/json")
  json = JSON(string.sub(content,7)):dictionary()
  if json["authenticated"] ~= true then
    return {LoginFailed}
  end  
end

function ListAccounts (knownAccounts)
  content, charset, mimeType = connection:request("POST",url,'{"controllerName":"information","action":"getContacts","language":"de","parameters":{},"trads":[]}',"application/json")
  json = JSON(string.sub(content,7))

  local account = {
    name = "BNP Paribas Depot",
    owner = json:dictionary()["parameters"]["contact"]["firstName"] .. " " .. json:dictionary()["parameters"]["contact"]["lastName"],
    accountNumber = json:dictionary()["parameters"]["contact"]["accountNumber"],
    portfolio = true,
    bankCode = "",
    currency = "EUR",
    type = AccountTypePortfolio
  }
  return {account}
end

function RefreshAccount (account, since)
  local s = {}  
  content, charset, mimeType = connection:request("POST",url,'{"controllerName":"avoir","action":"getAll","language":"de","parameters":{},"trads":[]}',"application/json")
  json = JSON(string.sub(content,7)):dictionary()
  
  for key, entry in pairs(json["parameters"]["shares"]["pes"]) do
    s[key] = {
      name = entry["columns"][2]["text"] .. " - " .. string.sub(entry["columns"][6]["text"],7),
      isin = entry["columns"][1]["text"],
      currency = nil,
      quantity = entry["columns"][3]["text"],
      amount = entry["columnsDetails"][8]["text"],
      price = entry["columnsDetails"][7]["text"],
      currencyOfPrice = "EUR",
      purchasePrice = entry["columnsDetails"][4]["text"],
      currencyOfPurchaasePrice = entry["columnsDetails"][4]["currency"],
      tradeTimestamp = string.sub(entry["columnsDetails"][6]["date"],0,-4)
    }
  end
  return {securities = s}
end

function EndSession () 
  content, charset, mimeType = connection:request("POST",url,'{"controllerName":"login","action":"quit","language":"de","parameters":{},"trads":[]}',"application/json")
end
