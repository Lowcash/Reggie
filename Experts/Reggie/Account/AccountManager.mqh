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
   AccountManager();
   
   void UpdateAccountValues();
   void UpdateAccountBalance();
   
   double GetAccountEquity() const { return(m_AccountEquity); }
   double GetAccountEquityPercentage() const { return(m_AccountEquityPercentage); }
   
   double GetAdjustedLotSize(const double p_InitialEquity, const double p_InitialLotSize);
   
   string GetAccountInfo(const double p_LotSize);
};

AccountManager::AccountManager() {
   UpdateAccountValues();
}

void AccountManager::UpdateAccountValues() {
   m_AccountEquity = AccountInfoDouble(ACCOUNT_EQUITY); 
}

void AccountManager::UpdateAccountBalance() {
   m_AccountEquityPercentage = (AccountInfoDouble(ACCOUNT_EQUITY) - m_AccountEquity) / m_AccountEquity * 100.0;  
}

double AccountManager::GetAdjustedLotSize(const double p_InitialEquity, const double p_InitialLotSize) {
   return((AccountInfoDouble(ACCOUNT_EQUITY) / p_InitialEquity) * p_InitialLotSize);
}

string AccountManager::GetAccountInfo(const double p_LotSize) {
   return(StringFormat("Week balance: %s%%; Lot size: %s", DoubleToString(m_AccountEquityPercentage, 2), DoubleToString(p_LotSize, 2)));
}