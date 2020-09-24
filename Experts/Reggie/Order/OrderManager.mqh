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

class ReggieOrderManager {
 private:
 	double m_PipValue, m_LotSize;
 	
 	int m_OrderTicketPointer;
 	
 	CList m_ReggieOrders;
 	CTrade m_Trade;
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
 				const double _EnterPrice = iHigh(_Symbol, PERIOD_M5, iHighest(_Symbol, PERIOD_M5, MODE_HIGH, 5, 1)) + 3 * m_PipValue /*+ (m_PipValue*MarketInfo(_Symbol, MODE_SPREAD))*/;
 				const double _StopLossPrice = Bid - 3 * m_PipValue;
 				
 				const double _Move = MathAbs(_StopLossPrice - _EnterPrice);
 				
 				ulong _R1Ticket = -1, _R2Ticket = -1; 
 				
 				if(m_Trade.BuyStop(m_LotSize, _EnterPrice, _Symbol, _StopLossPrice, _EnterPrice + 1 * _Move)) {
 				   _R1Ticket = m_Trade.ResultOrder();
 				} else {
 				   Print("Order failed with error #", GetLastError());
 				}
 				if(m_Trade.SellStop(m_LotSize, _EnterPrice, _Symbol, _StopLossPrice, _EnterPrice + 2 * _Move)) {
 				   _R2Ticket = m_Trade.ResultOrder();
 				} else {
 				   Print("Order failed with error #", GetLastError());
 				}
 				
 				if(_R1Ticket != -1 && _R2Ticket != -1) {
 				   m_ReggieOrders.Add(new ReggieOrder(ReggieOrder::OrderType::BUY, _R1Ticket, _R2Ticket, _EnterPrice, _EnterPrice, m_LotSize));
 				} else {
 				   PrintFormat("Reggie place order failed R1: %lu; R2: %lu", _R1Ticket, _R2Ticket);
 				
 				   return(false);
 				}
 				
 				break;
 			}
 			case ReggieOrder::OrderType::SELL: {
 				const double _EnterPrice = iLow(_Symbol, PERIOD_M5, iLowest(_Symbol, PERIOD_M5, MODE_LOW, 5, 1)) - 3 * m_PipValue;
 				const double _StopLossPrice = Bid + 3 * m_PipValue;
 				
 				const double _Move = MathAbs(_StopLossPrice - _EnterPrice);
 				
 				ulong _R1Ticket = -1, _R2Ticket = -1; 
 				
 				if(m_Trade.SellStop(m_LotSize, _EnterPrice, _Symbol, _StopLossPrice, _EnterPrice - 1 * _Move)) {
 				   _R1Ticket = m_Trade.ResultOrder();
 				} else {
 				   Print("Order failed with error #", GetLastError());
 				}
 				if(m_Trade.SellStop(m_LotSize, _EnterPrice, _Symbol, _StopLossPrice, _EnterPrice - 2 * _Move)) {
 				   _R2Ticket = m_Trade.ResultOrder();
 				} else {
 				   Print("Order failed with error #", GetLastError());
 				}
 				
 				if(_R1Ticket != -1 && _R2Ticket != -1) {
 				   m_ReggieOrders.Add(new ReggieOrder(ReggieOrder::OrderType::SELL, _R1Ticket, _R2Ticket, _EnterPrice, _EnterPrice, m_LotSize));
 				} else {
 				   PrintFormat("Reggie place order failed R1: %lu; R2: %lu", _R1Ticket, _R2Ticket);
 				
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
			if(OrderSelect(_R1Order.GetTicket())) {
				_R1Order.SetState(Order::State::ABORTED);
				
				if(!OrderSelect(_R2Order.GetTicket())) {
					Print("OrderSelect failed with error #", GetLastError());
				}
				
				MqlTradeRequest _Request;
			   MqlTradeResult _Result;
			   
			   _Request.action = TRADE_ACTION_SLTP;
			   _Request.sl = _R2Order.GetPrice();
			   
			   if(!OrderSend(_Request, _Result)) {
			      Print("OrderModify failed with error #", GetLastError());
			   }
			}
		}
		
		if(_R2OrderState == Order::State::PLACED) {
			if(OrderSelect(_R2Order.GetTicket())) {
				_R2Order.SetState(Order::State::ABORTED);
			}
		}
			
		if(_R1OrderState == Order::State::PENDING &&
			((OrderType == ReggieOrder::OrderType::BUY && Ask > _R1Order.GetPrice()) ||
			(OrderType == ReggieOrder::OrderType::SELL && Bid < _R1Order.GetPrice())))  {
			_R1Order.SetState(Order::State::PLACED);
		}

		if(_R2OrderState == Order::State::PENDING &&
			((OrderType == ReggieOrder::OrderType::BUY && Ask > _R2Order.GetPrice()) ||
			(OrderType == ReggieOrder::OrderType::SELL && Bid < _R2Order.GetPrice()))) {
			_R2Order.SetState(Order::State::PLACED);
		}
		
		if((OrderType == ReggieOrder::OrderType::BUY && p_CriticalValue > Close[1]) ||
			(OrderType == ReggieOrder::OrderType::SELL && p_CriticalValue < Close[1])) {
			MqlTradeRequest _Request;
			MqlTradeResult _Result;
			
			_Request.action = TRADE_ACTION_REMOVE;
			
			if(_R1OrderState == Order::State::PENDING) {
			   _Request.order = _R1Order.GetTicket();
			
				if(OrderSend(_Request, _Result)) {
				   _R1Order.SetState(Order::State::ABORTED);
				} else {
					Print("Order failed with error #", GetLastError());
				}
			}
			if(_R2OrderState == Order::State::PENDING) {
			   _Request.order = _R2Order.GetTicket();
			   
				if(OrderSend(_Request, _Result)) {
				   _R2Order.SetState(Order::State::ABORTED);
				} else {
					Print("Order failed with error #", GetLastError());
				}
			}
		}
		
		if(_R1OrderState == Order::State::ABORTED && _R2OrderState == Order::State::ABORTED) {
		   m_ReggieOrders.DeleteCurrent();
		}
	};

	m_OrderTicketPointer = m_ReggieOrders.Total();
}