//+------------------------------------------------------------------+
//|                                               AccountManager.mqh |
//|                                         Copyright 2020, Lowcash. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, Lowcash."
#property link      "https://www.mql5.com"
#property version   "1.00"

class AccountManager {
 private:
   double m_AccountEquity;
   double m_AccountEquityPercentage;
 public:
   AccountManager(){};
   
   void UpdateAccountValues();
   void UpdateAccountBalance();
   
   double GetAccountEquity() const { return(m_AccountEquity); }
   double GetAccountEquityPercentage() const { return(m_AccountEquityPercentage); }
};

void AccountManager::UpdateAccountValues() {
   m_AccountEquity = AccountInfoDouble(ACCOUNT_EQUITY); 
}

void AccountManager::UpdateAccountBalance() {
   // Avoid divide by zero exception
   if(m_AccountEquity == 0) { UpdateAccountValues(); }

   m_AccountEquityPercentage = (AccountInfoDouble(ACCOUNT_EQUITY) - m_AccountEquity) / m_AccountEquity * 100.0;  
}