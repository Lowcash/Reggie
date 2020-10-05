//+------------------------------------------------------------------+
//|                                                 OrderManager.mqh |
//|                                         Copyright 2020, Lowcash. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, Lowcash."
#property link      "https://www.mql5.com"
#property version   "1.00"

#include <Arrays/List.mqh>
#include <Trade/Trade.mqh>

#include "../../../Include/Internal/MQL4Helper.mqh"
#include "../../../Include/Internal/Common.mqh"

#include "Order.mqh"

class TradeManager {
 protected:
   double PipValue, LotSize;
   
   CTrade TradeFunc;
 public:
   TradeManager(const double p_LotSize);
};

TradeManager::TradeManager(const double p_LotSize) 
   : LotSize(p_LotSize) {
	PipValue = GetForexPipValue();
}

class ReggieTradeManager : public TradeManager {
 private:
 	CList m_ReggieTrades;
 public:
 	ReggieTradeManager(const double p_LotSize);
 	
 	void HandleOrderSend(const ulong p_Ticket);
 	void HandleOrderDelete(const ulong p_Ticket);
 	void HandleMakeDeal(const ulong p_Ticket);
	void AnalyzeTrades(const double p_CriticalValue);
	
	string GetOrdersStateInfo();
	
	bool TryOpenOrder(const ReggieTrade::TradeType p_TradeType, const ENUM_TIMEFRAMES p_PullBackTimeFrame);
};

ReggieTradeManager::ReggieTradeManager(const double p_LotSize) 
   : TradeManager(p_LotSize) {}

bool ReggieTradeManager::TryOpenOrder(const ReggieTrade::TradeType p_OrderTradeType, const ENUM_TIMEFRAMES p_PullBackTimeFrame) {
   ulong _R1Ticket = -1, _R2Ticket = -1;
   
   switch(p_OrderTradeType) {
		case ReggieTrade::TradeType::BUY: {
			const double _EnterPrice = iHigh(_Symbol, p_PullBackTimeFrame, iHighest(_Symbol, p_PullBackTimeFrame, MODE_HIGH, 5, 1)) + 3 * PipValue /*+ (m_PipValue*MarketInfo(_Symbol, MODE_SPREAD))*/;
			const double _StopLossPrice = iLow(_Symbol, p_PullBackTimeFrame, 1) - 3 * PipValue;
			
			const double _Move = MathAbs(_StopLossPrice - _EnterPrice);
         
			if(TradeFunc.BuyStop(LotSize, _EnterPrice, _Symbol, _StopLossPrice, _EnterPrice + 1 * _Move, ORDER_TIME_GTC, 0, "R1")) {
			   if(TradeFunc.ResultRetcode() == TRADE_RETCODE_DONE) {
			      _R1Ticket = TradeFunc.ResultOrder();
			   }
			} else {
			   Print("Order failed with error #", GetLastError());
			}
			if(TradeFunc.BuyStop(LotSize, _EnterPrice, _Symbol, _StopLossPrice, _EnterPrice + 2 * _Move, ORDER_TIME_GTC, 0, "R2")) {
			   if(TradeFunc.ResultRetcode() == TRADE_RETCODE_DONE) {
			      _R2Ticket = TradeFunc.ResultOrder();
			   }
			} else {
			   Print("Order failed with error #", GetLastError());
			}
			
			break;
		}
		case ReggieTrade::TradeType::SELL: {
			const double _EnterPrice = iLow(_Symbol, p_PullBackTimeFrame, iLowest(_Symbol, p_PullBackTimeFrame, MODE_LOW, 5, 1)) - 3 * PipValue;
			const double _StopLossPrice = iHigh(_Symbol, p_PullBackTimeFrame, 1) + 3 * PipValue;
			
			const double _Move = MathAbs(_StopLossPrice - _EnterPrice);
			
			if(TradeFunc.SellStop(LotSize, _EnterPrice, _Symbol, _StopLossPrice, _EnterPrice - 1 * _Move, ORDER_TIME_GTC, 0, "R1")) {
			   if(TradeFunc.ResultRetcode() == TRADE_RETCODE_DONE) {
			      _R1Ticket = TradeFunc.ResultOrder();
			   }
			} else {
			   Print("Order failed with error #", GetLastError());
			}
			if(TradeFunc.SellStop(LotSize, _EnterPrice, _Symbol, _StopLossPrice, _EnterPrice - 2 * _Move, ORDER_TIME_GTC, 0, "R2")) {
			   if(TradeFunc.ResultRetcode() == TRADE_RETCODE_DONE) {
			      _R2Ticket = TradeFunc.ResultOrder();
			   }
			} else {
			   Print("Order failed with error #", GetLastError());
			}
			
			break;
		}
	}
	
	if(_R1Ticket != -1 && _R2Ticket != -1) {
	   m_ReggieTrades.Add(new ReggieTrade(p_OrderTradeType, _R1Ticket, _R2Ticket));
	}

	return(_R1Ticket != -1 && _R2Ticket != -1);
}

void ReggieTradeManager::HandleOrderSend(const ulong p_Ticket) {
   ForEachCObject(_ReggieTrade, m_ReggieTrades) {
	   if(((ReggieTrade*)_ReggieTrade).GetReggieR1Trade().GetTicket() == p_Ticket) {
	      ((ReggieTrade*)_ReggieTrade).SetR1TradeState(Trade::State::ORDER);
	   }
	   if(((ReggieTrade*)_ReggieTrade).GetReggieR2Trade().GetTicket() == p_Ticket) {
	      ((ReggieTrade*)_ReggieTrade).SetR2TradeState(Trade::State::ORDER);
	   }
   }
}

void ReggieTradeManager::HandleOrderDelete(const ulong p_Ticket) {
   ForEachCObject(_ReggieTrade, m_ReggieTrades) {
	   if(((ReggieTrade*)_ReggieTrade).GetReggieR1Trade().GetTicket() == p_Ticket) {
	      ((ReggieTrade*)_ReggieTrade).SetR1TradeState(Trade::State::ABORTED);
	   }
	   if(((ReggieTrade*)_ReggieTrade).GetReggieR2Trade().GetTicket() == p_Ticket) {
	      ((ReggieTrade*)_ReggieTrade).SetR2TradeState(Trade::State::ABORTED);
	   }
   }
}

void ReggieTradeManager::HandleMakeDeal(const ulong p_Ticket) {
   ForEachCObject(_ReggieTrade, m_ReggieTrades) {
      Trade* _R1Trade = ((ReggieTrade*)_ReggieTrade).GetReggieR1Trade();
      Trade* _R2Trade = ((ReggieTrade*)_ReggieTrade).GetReggieR2Trade();
      
	   if(_R1Trade.GetTicket() == p_Ticket) {
	      if(_R1Trade.GetState() == Trade::State::POSITION) {
	         ((ReggieTrade*)_ReggieTrade).SetR1TradeState(Trade::State::ABORTED);
	         
	         // Modify R2 position, because R1 is done (takeprofit)
	         if(PositionSelectByTicket(_R2Trade.GetTicket())) {
   	         if(TradeFunc.PositionModify(_R2Trade.GetTicket(), PositionGetDouble(POSITION_PRICE_OPEN), PositionGetDouble(POSITION_TP))) {
   				   const uint _R2ResultCode = TradeFunc.ResultRetcode();
   				} else {
   				   Print("PositionModify failed with error #", GetLastError());
   				} 
	         }
	      } else {
	         ((ReggieTrade*)_ReggieTrade).SetR1TradeState(Trade::State::POSITION);
	      }
	   }
	   if(_R2Trade.GetTicket() == p_Ticket) {
	      if(_R2Trade.GetState() == Trade::State::POSITION) {
	         ((ReggieTrade*)_ReggieTrade).SetR2TradeState(Trade::State::ABORTED);
	      } else {
	         ((ReggieTrade*)_ReggieTrade).SetR2TradeState(Trade::State::POSITION);
	      }
	   }
   }
}

string ReggieTradeManager::GetOrdersStateInfo() {
   string _Info = m_ReggieTrades.Total() > 0 ? "" : "NO_TRADES";
   
   ForEachCObject(_ReggieTrade, m_ReggieTrades) {
      Trade* _R1Trade = ((ReggieTrade*)_ReggieTrade).GetReggieR1Trade();
	   Trade* _R2Trade = ((ReggieTrade*)_ReggieTrade).GetReggieR2Trade();
	   
	   _Info += StringFormat("R1: %s; R2: %s\n", EnumToString(_R1Trade.GetState()), EnumToString(_R2Trade.GetState()));
   }
	
	return(_Info);
}

void ReggieTradeManager::AnalyzeTrades(const double p_CriticalValue) {
	ForEachCObject(_ReggieTrade, m_ReggieTrades) {
	   Trade* _R1Trade = ((ReggieTrade*)_ReggieTrade).GetReggieR1Trade();
	   Trade* _R2Trade = ((ReggieTrade*)_ReggieTrade).GetReggieR2Trade();
	   
	   // Remove them from list
		if(_R1Trade.GetState() == Trade::State::ABORTED && _R2Trade.GetState() == Trade::State::ABORTED) {
		   m_ReggieTrades.DeleteCurrent();
		   
		   continue;
		}
		
		const ReggieTrade::TradeType TradeType = ((ReggieTrade*)_ReggieTrade).GetTradeType();
		
		// Remove aborted orders first
		if((TradeType == ReggieTrade::TradeType::BUY && p_CriticalValue > Close[1]) ||
		   (TradeType == ReggieTrade::TradeType::BUY && p_CriticalValue > Open[1]) ||
			(TradeType == ReggieTrade::TradeType::SELL && p_CriticalValue < Open[1]) ||
			(TradeType == ReggieTrade::TradeType::SELL && p_CriticalValue < Close[1])) {
			
			uint _R1ResultCode, _R2ResultCode;
			
			// Remove them from market
			if(_R1Trade.GetState() == Trade::State::ORDER) {
				if(TradeFunc.OrderDelete(_R1Trade.GetTicket())) {
				   _R1ResultCode = TradeFunc.ResultRetcode();
				} else {
					Print("Order failed with error #", GetLastError());
				}
			}
			if(_R2Trade.GetState() == Trade::State::ORDER) {
				if(TradeFunc.OrderDelete(_R2Trade.GetTicket())) {
				   _R2ResultCode = TradeFunc.ResultRetcode();
				} else {
					Print("Order failed with error #", GetLastError());
				}
			}
		}
	};
}