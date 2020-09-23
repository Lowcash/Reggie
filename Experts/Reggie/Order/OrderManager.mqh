//+------------------------------------------------------------------+
//|                                                 OrderManager.mqh |
//|                                         Copyright 2020, Lowcash. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, Lowcash."
#property link      "https://www.mql5.com"
#property version   "1.00"

#include <Arrays/List.mqh>

#include "../../../Include/Internal/MQL4Helper.mqh"
#include "../../../Include/Internal/Common.mqh"

#include "Order.mqh"

class ReggieOrderManager {
 private:
 	double m_PipValue, m_LotSize;
 	
 	int m_OrderTicketPointer;
 	
 	CList m_ReggieOrders;
 public:
 	ReggieOrderManager(const double p_LotSize);
 		
	void AnalyzeOrders(const double p_CriticalValue);
	
	bool AddOrder(const ReggieOrder::OrderType p_OrderOrderType);
	
	int GetActiveTickets() const { return(OrdersTotal()); }
};

ReggieOrderManager::ReggieOrderManager(const double p_LotSize) 
   : m_LotSize(p_LotSize) {
	m_PipValue = GetForexPipValue();
}

bool ReggieOrderManager::AddOrder(const ReggieOrder::OrderType p_OrderOrderType) {
   switch(p_OrderOrderType) {
 			case ReggieOrder::OrderType::BUY: {
 				const double _EnterPrice = iHigh(_Symbol, PERIOD_M5, iHighest(_Symbol, PERIOD_M5, MODE_HIGH, 5)) + 3 * m_PipValue /*+ (m_PipValue*MarketInfo(_Symbol, MODE_SPREAD))*/;
 				const double _StopLossPrice = Bid - 3 * m_PipValue;
 				
 				const double _Move = MathAbs(_StopLossPrice - _EnterPrice);
 				
 				MqlTradeRequest _R1Request, _R2Request;
 				MqlTradeResult _R1Result, _R2Result;
 				
 				_R1Request.action = TRADE_ACTION_PENDING;
 				_R1Request.type = ORDER_TYPE_BUY_STOP;
 				_R1Request.volume = m_LotSize;
 				_R1Request.stoplimit = _EnterPrice;
 				_R1Request.sl = _StopLossPrice;
 				_R1Request.deviation = 10;
 				_R1Request.tp = _EnterPrice + 1 * _Move;
 				
 				_R2Request.action = TRADE_ACTION_PENDING;
 				_R2Request.type = ORDER_TYPE_BUY_STOP;
 				_R2Request.volume = m_LotSize;
 				_R2Request.stoplimit = _EnterPrice;
 				_R2Request.sl = _StopLossPrice;
 				_R2Request.deviation = 10;
 				_R2Request.tp = _EnterPrice + 2 * _Move;
 				
 				if(OrderSend(_R1Request, _R1Result) && OrderSend(_R2Request, _R2Result)) {
 				   m_ReggieOrders.Add(new ReggieOrder(ReggieOrder::OrderType::BUY, _R1Result.order, _R2Result.order, _EnterPrice, _EnterPrice, m_LotSize));
 				} else {
 				   Print("Order failed with error #", GetLastError());
 				   
 				   return(false);
 				}
 				
 				break;
 			}
 			case ReggieOrder::OrderType::SELL: {
 				const double _EnterPrice = iLow(_Symbol, PERIOD_M5, iLowest(_Symbol, PERIOD_M5, MODE_LOW, 5)) - 3 * m_PipValue;
 				const double _StopLossPrice = Bid + 3 * m_PipValue;
 				
 				const double _Move = MathAbs(_StopLossPrice - _EnterPrice);
 				
 				MqlTradeRequest _R1Request, _R2Request;
 				MqlTradeResult _R1Result, _R2Result;
 				
 				_R1Request.action = _R2Request.action = TRADE_ACTION_PENDING;
 				_R1Request.type = _R2Request.type = ORDER_TYPE_SELL_STOP;
 				_R1Request.volume = _R2Request.volume = m_LotSize;
 				_R1Request.stoplimit = _R2Request.stoplimit = _EnterPrice;
 				_R1Request.sl = _R2Request.sl = _StopLossPrice;
 				_R1Request.deviation = _R2Request.deviation = 10;
 				
 				_R1Request.tp = _EnterPrice - 1 * _Move;
 				_R2Request.tp = _EnterPrice - 2 * _Move;
 				
 				if(OrderSend(_R1Request, _R1Result) && OrderSend(_R2Request, _R2Result)) {
 				   m_ReggieOrders.Add(new ReggieOrder(ReggieOrder::OrderType::SELL, _R1Result.order, _R2Result.order, _EnterPrice, _EnterPrice, m_LotSize));
 				} else {
 				   Print("Order failed with error #", GetLastError());
 				   
 				   return(false);
 				}
 				
 				break;
 			}
 		}
 		
 		m_OrderTicketPointer = m_OrderTicketPointer > m_ReggieOrders.Total() ? 0 : m_OrderTicketPointer + 1;
 		
 		return(true);
}

void ReggieOrderManager::AnalyzeOrders(const double p_CriticalValue) {
	Comment("NO_TRADES");
	
	if(m_ReggieOrders.Total() > 0) {
	   ReggieOrder* _FirstReggieOrder = (ReggieOrder*)m_ReggieOrders.GetFirstNode();
	   
	   Order* _R1Order = _FirstReggieOrder.GetReggieR1Order();
	   Order* _R2Order = _FirstReggieOrder.GetReggieR2Order();
		
		Comment(StringFormat("R1: %s; R2: %s", EnumToString(_R1Order.GetState()), EnumToString(_R2Order.GetState())));
	}
	
	ForEachCObject(_ReggieOrder, m_ReggieOrders) {
	   Order* _R1Order = ((ReggieOrder*)_ReggieOrder).GetReggieR1Order();
	   Order* _R2Order = ((ReggieOrder*)_ReggieOrder).GetReggieR2Order();
	   
	   Order::State _R1OrderState = _R1Order.GetState();
		Order::State _R2OrderState = _R2Order.GetState();
		
		const ReggieOrder::OrderType OrderType = ((ReggieOrder*)_ReggieOrder).GetOrderType();
		
		if(_R1OrderState == Order::State::PLACED) {
			/*if(OrderSelect(_R1Order.m_Ticket, SELECT_BY_TICKET, MODE_HISTORY) && OrderCloseTime() != NULL) {
				_R1Order.SetOrderState(ABORTED);
				
				Print("Modified");
				
				if(!OrderSelect(_R2Order.m_Ticket, SELECT_BY_TICKET)) {
					Print("OrderSelect failed with error #", GetLastError());
				}
				
				if(!OrderModify(OrderTicket(), OrderOpenPrice(), _R2Order.m_Price, OrderTakeProfit(), OrderExpiration())) {
					Print("OrderModify failed with error #", GetLastError());
				}
			}*/
		}
		
		if(_R2OrderState == Order::State::PLACED) {
			/*if(OrderSelect(_R2Order.m_Ticket, SELECT_BY_TICKET, MODE_HISTORY) && OrderCloseTime() != NULL) {
				_R2Order.SetOrderState(Order::State::ABORTED);
			}*/
		}
			
		if(_R1OrderState == Order::State::PENDING &&
			((OrderType == ReggieOrder::OrderType::BUY && Ask > _R1Order.m_Price) ||
			(OrderType == ReggieOrder::OrderType::SELL && Bid < _R1Order.m_Price)))  {
			_R1Order.SetState(Order::State::PLACED);
		}

		if(_R2OrderState == Order::State::PENDING &&
			((OrderType == ReggieOrder::OrderType::BUY && Ask > _R2Order.m_Price) ||
			(OrderType == ReggieOrder::OrderType::SELL && Bid < _R2Order.m_Price))) {
			_R2Order.SetState(Order::State::PLACED);
		}
		
		if((OrderType == ReggieOrder::OrderType::BUY && p_CriticalValue > Close[1]) ||
			(OrderType == ReggieOrder::OrderType::SELL && p_CriticalValue < Close[1])) {
			if(_R1OrderState == Order::State::PENDING) {
				/*if(!OrderDelete(_R1Order.m_Ticket)) {
					Print("Order failed with error #", GetLastError());
				} else {
					_R1Order.SetOrderState(Order::State::ABORTED);
				}*/	
			}
			if(_R2OrderState == Order::State::PENDING) {
				/*if(!OrderDelete(_R2Order.m_Ticket)) {
					Print("Order failed with error #", GetLastError());
				} else {
					_R2Order.SetOrderState(Order::State::ABORTED);
				}*/
			}
		}
		
		if(_R1OrderState == Order::State::ABORTED && _R2OrderState == Order::State::ABORTED) {
		   m_ReggieOrders.DeleteCurrent();
		}
	};

	m_OrderTicketPointer = m_ReggieOrders.Total();
}